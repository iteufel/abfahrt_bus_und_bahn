import 'dart:async';
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

class IosNavigation extends StatefulWidget {
  IosNavigation({Key key, this.title}) : super(key: key);

  // This widget is the home  of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _IosNavigationState createState() => _IosNavigationState();
}

class _IosNavigationState extends State<IosNavigation> {
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

    return new Container(child: new Text('data'),);
  }
}
