import 'package:flutter/material.dart';

final light = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
  accentColor: Colors.orange[400],
);

final dark = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.blue[900],
  accentColor: Colors.orange[600],
  toggleableActiveColor: Colors.orange[600],
  textSelectionHandleColor: Colors.orange[800],
);
