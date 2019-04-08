import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intro_views_flutter/Models/page_view_model.dart';
import 'package:intro_views_flutter/intro_views_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hafas.dart';

class IntroPage extends StatefulWidget {
  IntroPage({Key key, this.title, this.station}) : super(key: key);
  final String title;
  final HafasStation station;

  @override
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  List<PageViewModel> pages = [];

  @override
  void initState() {
    super.initState();
    var page1 = new PageViewModel(
      pageColor: Colors.blueGrey,
      iconImageAssetPath: null,
      iconColor: null,
      bubbleBackgroundColor: Colors.greenAccent,
      body: Text(
        'Sofort Haltestellen basierend auf deinem Standpunkt finden',
      ),
      title: Text('Bus & Bahn'),
      mainImage: Icon(
        Icons.train,
        size: 180,
        color: Colors.white,
      ),
      textStyle: TextStyle(color: Colors.white),
    );

    var page2 = new PageViewModel(
      pageColor: Colors.amber,
      iconImageAssetPath: null,
      iconColor: null,
      bubbleBackgroundColor: Colors.greenAccent,
      body: Text(
        'Alle Haltestellen finden',
      ),
      title: Text('Deutschlandweit'),
      mainImage: Icon(
        Icons.directions_bus,
        size: 180,
        color: Colors.white,
      ),
      textStyle: TextStyle(color: Colors.white),
    );

    var page3 = new PageViewModel(
      pageColor: Colors.blue,
      iconImageAssetPath: null,
      iconColor: null,
      bubbleBackgroundColor: Colors.greenAccent,
      body: Text(
        'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor',
      ),
      title: Text('Schnell'),
      mainImage: Icon(
        Icons.timer,
        size: 180,
        color: Colors.white,
      ),
      textStyle: TextStyle(color: Colors.white),
    );
    pages = [page1, page2, page3];
  }

  @override
  Widget build(BuildContext context) {
    final Widget introViews = new IntroViewsFlutter(
      pages,
      onTapDoneButton: () async {
        var prefs = await SharedPreferences.getInstance();
        prefs.setBool('introShown', true);
        Navigator.of(context).pushReplacementNamed('search');
      },
      showSkipButton: true,
      skipText: new Text('Überspringen'),
      doneText: new Text('Fertig'),
      pageButtonTextStyles: new TextStyle(
        color: Colors.white,
        fontSize: 18.0,
        fontFamily: "Regular",
      ),
    );
    return Scaffold(
      body: introViews,
    );
  }
}
