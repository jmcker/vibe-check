import 'package:flutter/material.dart';

final Map<String, RegExp> regExMap = {
  'Classical': RegExp(r'classical|soundtrack', caseSensitive: false),
  'Jazz': RegExp(r'jazz|blues', caseSensitive: false),
  'R&B': RegExp(r'r&b', caseSensitive: false),
  'Country': RegExp(r'country', caseSensitive: false),
  'Pop': RegExp(r'pop|hip hop|dance|latin', caseSensitive: false),
  'Electronic': RegExp(r'electronic|house|electronica|bass|.*step|vapor|chillwave|edm|brostep', caseSensitive: false),
  'Rap': RegExp(r'rap', caseSensitive: false),
  'Rock': RegExp(r'rock|punk|indie|alternative|grunge', caseSensitive: false),
  'Metal': RegExp(r'metal|hard', caseSensitive: false)
};

final Map<String, Color> genreColorMap = {
  'Classical': Color.fromARGB(125, 205, 133, 63),
  'Jazz': Color.fromARGB(125, 232, 195, 7),
  'R&B': Color.fromARGB(125, 65, 12, 255),
  'Country': Color.fromARGB(125, 88, 255, 0),
  'Pop': Color.fromARGB(125, 255, 11, 187),
  'Electronic': Color.fromARGB(125, 12, 232, 224),
  'Rap': Color.fromARGB(125, 232, 26, 7),
  'Rock': Color.fromARGB(125, 255, 141, 20),
  'Metal': Color.fromARGB(125, 140, 140, 140),
  'Other' : Color.fromARGB(125, 220, 220, 220),
};