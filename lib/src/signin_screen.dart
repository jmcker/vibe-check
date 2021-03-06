import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:http/http.dart';
import 'package:location/location.dart';

import 'genres.dart';
import 'map_screen.dart';

const kAndroidUserAgent =
    'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Mobile Safari/537.36';

final String spotifyUri = Uri.encodeFull(
    'https://accounts.spotify.com/authorize' +
        '?response_type=code' +
        '&client_id=c451eab95a624bfbb8cf67a84b11b985' +
        '&scope=user-read-recently-played' +
        '&redirect_uri=https://vibecheck.tk/auth' +
        '&show_dialog=true');

// ignore: prefer_collection_literals
final Set<JavascriptChannel> jsChannels = [
  JavascriptChannel(
      name: 'Print',
      onMessageReceived: (JavascriptMessage message) {
        print(message.message);
      }),
].toSet();

String code = 'Blank';
String accessToken = '';
String refreshToken = '';

class SignIn extends StatelessWidget {
  final flutterWebViewPlugin = FlutterWebviewPlugin();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.purple,
      title: 'Flutter WebView Demo',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        primaryColor: Colors.purple,
      ),
      routes: {
        '/': (_) => const MyHomePage(title: 'Vibe Check Spotify Sign-in'),
        '/widget': (_) {
          return WebviewScaffold(
            url: spotifyUri,
            javascriptChannels: jsChannels,
            mediaPlaybackRequiresUserGesture: false,
            appBar: AppBar(
              title: const Text('Vibe Check Spotify Sign-in'),
            ),
            withZoom: true,
            withLocalStorage: true,
            hidden: true,
            initialChild: Container(
              color: Colors.white,
              child: const Center(
                child: Text('Loading...'),
              ),
            ),
          );
        },
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Instance of WebView plugin
  final flutterWebViewPlugin = FlutterWebviewPlugin();

  // On destroy stream
  StreamSubscription _onDestroy;
  StreamSubscription<String> _onUrlChanged;
  StreamSubscription<WebViewStateChanged> _onStateChanged;
  StreamSubscription<WebViewHttpError> _onHttpError;
  StreamSubscription<double> _onProgressChanged;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, String> getAuthHeaders() {
    return {
      'Authorization': 'Bearer ' + accessToken,
    };
  }

  Future<bool> getTokens(spotifyCode) async {
    Response resp = await get('https://vibecheck.tk/api/auth?code=' + code);

    if (resp.statusCode == 200) {
      Map<String, dynamic> map = jsonDecode(resp.body);

      accessToken = map['access_token'];
      refreshToken = map['refresh_token'];

      // TODO: Store in secure storage

      print('Got Spotify access token.');

      return true;
    } else {
      return false;
    }
  }

  Future<Map<String, double>> getLocation() async {
    var location = new Location();
    var currentLocation;

    try {
      currentLocation = await location.getLocation();
    } on Exception {
      return {'error': 0.0};
    }

    print("locationLatitude: ${currentLocation.latitude.toString()}");
    print("locationLongitude: ${currentLocation.longitude.toString()}");

    return {
      'latitude': currentLocation.latitude,
      'longitude': currentLocation.longitude
    };
  }

  Future<Map<String, dynamic>> getAndFilterGenres(vibes) async {

    List<dynamic> tracks = vibes['tracks'];

    // Now put all of the artist id's in an array to send to get genre
    String artistCommaString = '';
    for (var i = 0; i < tracks.length - 1; i++) {
      artistCommaString += tracks[i]['artist_id'] + ',';
    }
    artistCommaString += tracks[tracks.length - 1]['artist_id'];

    String requestUri = Uri.encodeFull(
        'https://api.spotify.com/v1/artists?ids=' + artistCommaString);

    Response resp = await get(requestUri, headers: this.getAuthHeaders());

    if (resp.statusCode == 200) {
      Map<String, dynamic> artistMap = jsonDecode(resp.body);
      List<dynamic> artistList = artistMap['artists'];

      for (int i = 0; i < artistList.length; i++) {
        bool foundMatch = false;
        tracks[i]["original_genre"] = artistList[i]['genres'].join(",");

        for (int j = 0; j < artistList[i]["genres"].length; j++) {
          var tempGenre = artistList[i]["genres"][j];

          for (String value in regExMap.keys) {
            if (regExMap[value].hasMatch(tempGenre)) {
              tracks[i]['genre'] = value;
              foundMatch = true;
              break;
            }

          }

          if (foundMatch) {
            break;
          }
        }

        if (foundMatch == false) {
          tracks[i]['genre'] = 'Other';
        }
        print(tracks[i]['original_genre']);
        print(tracks[i]['genre']);
      }

      return vibes;
    } else {
      print(jsonDecode(resp.body));
      return {};
    }
  }

  Future<List<dynamic>> getRecentlyPlayed() async {
    Response resp = await get(
        'https://api.spotify.com/v1/me/player/recently-played',
        headers: this.getAuthHeaders());

    Map<String, dynamic> map2 = jsonDecode(resp.body);
    List<dynamic> items = map2['items'];
    List<dynamic> tracks = new List();

    //Need to change this to size of vibes were getting
    for (var i = 0; i < items.length; i++) {
      Map<String, dynamic> track = new Map();
      track['artist'] = items[i]['track']['artists'][0]['name'];
      track['album'] = items[i]['track']['album']['name'];
      track['artist_id'] = items[i]['track']['artists'][0]['id'];
      track['popularity'] = items[i]['track']['popularity'];
      track['track_id'] = items[i]['track']['id'];
      track['title'] = items[i]['track']['name'];
      tracks.add(track);
    }

    return tracks;
  }

  Future<bool> postVibes(tracks) async {

    print('Posting vibes...');

    Map<String, dynamic> vibes = new Map();
    Map<String, double> locData = await this.getLocation();

    if (locData.containsKey('error')) {
      print('Could not post vibes. getLocation failed.');
      return false;
    }

    vibes['latitude'] = locData['latitude'];
    vibes['longitude'] = locData['longitude'];
    vibes['tracks'] = tracks;

    vibes = await this.getAndFilterGenres(vibes);

    Map<String, String> vibeHeaders = {
      'Content-Type': 'application/json',
    };
    Response vibePost = await post('https://vibecheck.tk/api/vibe',
        headers: vibeHeaders, body: json.encode(vibes));

    if (vibePost.statusCode == 201) {
      print('Vibes have been posted');
      return true;
    } else {
      print(vibePost.body);
      print('Vibes did not work.');
      return false;
    }
  }

  void switchToMap() {
    flutterWebViewPlugin.close();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapScreen()),
    );
  }

  @override
  void initState() {
    super.initState();

    flutterWebViewPlugin.close();

    // Add a listener to on destroy WebView, so you can make came actions.
    _onDestroy = flutterWebViewPlugin.onDestroy.listen((_) {
      if (mounted) {
        // Actions like show a info toast.
        _scaffoldKey.currentState.showSnackBar(
            const SnackBar(content: const Text('Webview Destroyed')));
      }
    });

    // Add a listener to on url changed
    _onUrlChanged =
        flutterWebViewPlugin.onUrlChanged.listen((String url) async {
      if (mounted) {
        int startIndex = url.indexOf('code=');

        if (startIndex != -1) {
          code = url.substring(startIndex + 'code='.length);

          if (!await this.getTokens(code)) {
            // TODO: Update status somewhere to let the user know
            return;
          }

          this.switchToMap();

          // Post the most recent data for now
          List<dynamic> tracks = await this.getRecentlyPlayed();
          bool success = await this.postVibes(tracks);

        }
      }

      setState(() {});
    });

    _onProgressChanged =
        flutterWebViewPlugin.onProgressChanged.listen((double progress) {
      if (mounted) {
        setState(() {});
      }
    });

    _onStateChanged =
        flutterWebViewPlugin.onStateChanged.listen((WebViewStateChanged state) {
      if (mounted) {
        setState(() {});
      }
    });

    _onHttpError =
        flutterWebViewPlugin.onHttpError.listen((WebViewHttpError error) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // Every listener should be canceled, the same should be done with this stream.
    _onDestroy.cancel();
    _onUrlChanged.cancel();
    _onStateChanged.cancel();
    _onHttpError.cancel();
    _onProgressChanged.cancel();

    flutterWebViewPlugin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(''),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              //padding: const EdgeInsets.all(24.0),
              child: Image.asset('Assets/logo.png'),
            ),
            SizedBox(height: 120),
            SizedBox(

              height: 100,
              width: 300,
              child:  RaisedButton(

              onPressed: () {
                Navigator.of(context).pushNamed('/widget');
              },
              child: new Text(
                'Authorize Spotify',
                style: new TextStyle(
                  fontSize: 30.0,
                  color: Colors.white),
                ),

              color: Colors.purple,
              textColor: Colors.white,

            ),
            )

          ],
        ),
      ),
    );
  }
}
