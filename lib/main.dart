import 'package:flutter/material.dart';
import 'search.dart';
import 'intro.dart';
import 'settings.dart';
import 'favorites.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'style.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var routes = {
      'search': (context) {
        return SearchPage(title: 'Abfahrts Monitor');
      },
      'intro': (context) {
        return new IntroPage();
      },
      'settings': (context) {
        return new SettingsPage();
      },
      'favorites': (context) {
        return new FavoritesPage();
      }
    };
    if (AbfahrtStyle.forceIosStyle) {
      return CupertinoApp(
        title: 'Abfahrts Monitor',
        theme: CupertinoThemeData(),
        home: SearchPage(title: 'Abfahrts Monitor'),
        routes: routes,
      );
    } else {
      return MaterialApp(
        title: 'Abfahrts Monitor',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blueGrey,
        ),
        home: SearchPage(title: 'Abfahrts Monitor'),
        routes: routes,
      );
    }
  }
}
