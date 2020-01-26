import 'package:flutter/material.dart';
import 'map_screen.dart';
import '../main.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:http/http.dart';
import 'package:spotify/spotify_io.dart';

const kAndroidUserAgent =
    'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Mobile Safari/537.36';

String spotify = 'https://accounts.spotify.com/authorize' +
  '?response_type=code' +
  '&client_id=' + "c451eab95a624bfbb8cf67a84b11b985" +
  ('&scope=user-read-recently-played') +
  '&redirect_uri=' + "https://vibecheck.tk/auth" +
  "&show_dialog=true";


String spotify_uri = Uri.encodeFull(spotify);

String selectedUrl = spotify_uri;

// ignore: prefer_collection_literals
final Set<JavascriptChannel> jsChannels = [
  JavascriptChannel(
      name: 'Print',
      onMessageReceived: (JavascriptMessage message) {
        print(message.message);
      }),
].toSet();

String code = 'Blank';
String access_token = "";
String refresh_token = "";

class SignIn extends StatelessWidget {

  final flutterWebViewPlugin = FlutterWebviewPlugin();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WebView Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        '/': (_) => const MyHomePage(title: 'Flutter WebView Demo'),
        '/widget': (_) {
          return WebviewScaffold(
            url: selectedUrl,
            javascriptChannels: jsChannels,
            mediaPlaybackRequiresUserGesture: false,
            appBar: AppBar(
              title: const Text('Widget WebView'),
            ),
            withZoom: true,
            withLocalStorage: true,
            hidden: true,
            initialChild: Container(
              color: Colors.white,
              child: const Center(
                child: Text('Waiting.....'),
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

  // On urlChanged stream
  StreamSubscription<String> _onUrlChanged;

  // On urlChanged stream
  StreamSubscription<WebViewStateChanged> _onStateChanged;

  StreamSubscription<WebViewHttpError> _onHttpError;

  StreamSubscription<double> _onProgressChanged;

  StreamSubscription<double> _onScrollYChanged;

  StreamSubscription<double> _onScrollXChanged;

  final _urlCtrl = TextEditingController(text: selectedUrl);

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    flutterWebViewPlugin.close();

    _urlCtrl.addListener(() {
      selectedUrl = _urlCtrl.text;
    });

    // Add a listener to on destroy WebView, so you can make came actions.
    _onDestroy = flutterWebViewPlugin.onDestroy.listen((_) {
      if (mounted) {
        // Actions like show a info toast.
        _scaffoldKey.currentState.showSnackBar(
            const SnackBar(content: const Text('Webview Destroyed')));
      }
    });

    // Add a listener to on url changed
    _onUrlChanged = flutterWebViewPlugin.onUrlChanged.listen((String url) async {
      if (mounted) {
          int startIndex = url.indexOf('code=');
          if (startIndex != -1) {
            code = url.substring(startIndex+5);
            Response res = await get("https://vibecheck.tk/api/auth?code=" + code);
            if (res.statusCode == 200) {
              Map<String, dynamic> map = jsonDecode(res.body);
              access_token = map["access_token"];
              print(access_token);
              Map<String, String> requestHeaders = {
                'Authorization': 'Bearer ' + access_token,
              };
              Response res2 = await get("https://api.spotify.com/v1/me/player/recently-played", headers:requestHeaders);
              Map<String, dynamic> map2 = jsonDecode(res2.body);

              List <dynamic> items = map2["items"];

              Map<String, dynamic> vibes = new Map();
              vibes["latitude"] = "40.4285323";
              vibes["longitude"] = "-86.9240971";

              List<dynamic> tracks = new List();

              //Need to change this to size of vibes were getting
              for (var i = 0; i < items.length; i++) {
                Map<String, dynamic> track = new Map();
                track["artist"] = items[i]["track"]["artists"][0]["name"];
                track["album"] = items[i]["track"]["album"]["name"];
                track["artist_id"] = items[i]["track"]["artists"][0]["id"];
                track["popularity"] = items[i]["track"]["popularity"];
                track["track_id"] = items[i]["track"]["id"];
                track["title"] = items[i]["track"]["name"];
                tracks.add(track);
              }

              //Now put all of the artist id's in an array to send to get genre
              String artistCommaString = "";
              for (var i = 0; i < items.length - 1; i++) {
                artistCommaString += tracks[i]["artist_id"] + ',';
              }

              artistCommaString += tracks[items.length-1]["artist_id"];

              Response artistResponse = await get(Uri.encodeFull("https://api.spotify.com/v1/artists?ids=" + artistCommaString), headers:requestHeaders);
              if (res.statusCode == 200) {
                Map<String, dynamic> artistMap = jsonDecode(artistResponse.body);
                List <dynamic> artistList = artistMap["artists"];

                for (int i  = 0; i < artistList.length; i++) {
                  if (artistList[i]["genres"].length == 0) {
                    tracks[i]["genre"] = "Other";
                  }
                  else {
                    tracks[i]["genre"] = artistList[i]["genres"][0];
                  }
                  print(tracks[i]["genre"]);
                }

                vibes["tracks"] = tracks;
                Map<String, String> vibeHeaders = {
                  'Content-Type': 'application/json',
                };
                Response vibePost = await post("https://vibecheck.tk/api/vibe", headers:vibeHeaders ,body:json.encode(vibes));
                if (vibePost.statusCode == 201) {
                  print("Vibes have been posted");
                  flutterWebViewPlugin.close();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MapScreen()),
                    );
                }
                else {
                  print(vibePost.body + "did not work");
                }
              }
              else {
                print(jsonDecode(artistResponse.body));
              }
            }
          }
      }
      setState((){
      });
    });

    _onProgressChanged =
        flutterWebViewPlugin.onProgressChanged.listen((double progress) {
      if (mounted) {
        setState(() {
        });
      }
    });

    _onStateChanged =
        flutterWebViewPlugin.onStateChanged.listen((WebViewStateChanged state) {
      if (mounted) {
        setState(() {
        });
      }
    });

    _onHttpError =
        flutterWebViewPlugin.onHttpError.listen((WebViewHttpError error) {
      if (mounted) {
        setState(() {
        });
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
        title: const Text('Plugin example app'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              child: TextField(controller: _urlCtrl),
            ),
            RaisedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/widget');
              },
              child: const Text('Open widget webview'),
            ),
            Text(
              '$code',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
    );
  }
}
