import 'package:flutter/material.dart';
import 'search.dart';
import 'intro.dart';
import 'settings.dart';
import 'favorites.dart';
import 'package:flutter/cupertino.dart';
import 'style.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
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
          primaryColor: Color(0xFF2296F3),
          buttonColor: Color(0xFF720D5D),
        ),
        home: SearchPage(title: 'Abfahrts Monitor'),
        routes: routes,
      );
    }
  }
}
