import 'dart:async';
import 'package:abfahrt_gui/style.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'hafas.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key, this.title, this.station}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final HafasStation station;

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    if (AbfahrtStyle.forceIosStyle) {
      return CupertinoPageScaffold(
        navigationBar: new CupertinoNavigationBar(
          middle: new Text('Einstellungen'),
        ),
        child: new Center(
          child: new Text('TODO'),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          // Here we take the value from the SettingsPage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text('Einstellungen'),
        ),
        body: new Center(
          child: new MaterialButton(
            child: new Text('Show Intro'),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('intro');
            },
          ),
        ),
      );
    }
  }
}
