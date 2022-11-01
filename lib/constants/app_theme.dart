import 'package:flutter/material.dart';

// This is  where the theme of the entire application resides

ThemeData appTheme = ThemeData(
  primarySwatch: Colors.teal,
  fontFamily: 'Quicksand',
  appBarTheme: const AppBarTheme(
    centerTitle: true,
  ),
  pageTransitionsTheme: const PageTransitionsTheme(builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
  }),
);