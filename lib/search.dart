import 'dart:async';
import 'dart:io';
import 'package:abfahrt_gui/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'stop.dart';
import 'hafas.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

class SearchPage extends StatefulWidget {
  SearchPage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchInputController;

  @override
  void initState() {
    super.initState();
    this.searchInputController = new TextEditingController();
    this.checkFirstStart();
  }

  Future<void> checkFirstStart() async {
    var prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('introShown') == null) {
      Navigator.of(context).pushReplacementNamed('intro');
    } else {
      this.findLoaction();
    }
  }

  void showLocation(HafasStation station) {
    print(station.id);
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) => new StopPage(
              title: station.title,
              station: station,
            ),
      ),
    );
  }

  Future<void> findLoaction() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> places = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    var RMV = new Hafas(config: new HafasConfig());
    var res = await RMV.findStationsByCoordinates(
      new HafasLocation(
        lat: position.latitude,
        lon: position.longitude,
      ),
      1,
    );
    setState(() {
      this.searchInputController.text = places.first.name;
      this.serachResults = res;
    });
  }

  Future<void> findByQuery(String q) async {
    var RMV = new Hafas(config: new HafasConfig());
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    var res = await RMV.findStationsByQuery(q.trim(),
        new HafasLocation(lat: position.latitude, lon: position.longitude));
    setState(() {
      this.serachResults = res;
    });
  }

  List<HafasStation> serachResults = [];

  @override
  Widget build(BuildContext context) {
    Widget body = new Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        new Expanded(
          child: new ListView.builder(
            itemBuilder: (context, index) {
              if (Platform.isIOS) {
                return new Container(
                  decoration: new BoxDecoration(
                    border: new Border(
                      bottom: new BorderSide(
                        color: Colors.black12,
                        width: 1,
                      ),
                    ),
                  ),
                  child: new GestureDetector(
                    child: new Row(
                      children: <Widget>[
                        new Expanded(
                          child: new Text(serachResults[index].title),
                        ),
                        new Text((serachResults[index].dist / 1000)
                                .toStringAsFixed(2) +
                            ' Km')
                      ],
                    ),
                    onTap: () {
                      showLocation(serachResults[index]);
                    },
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 18,
                  ),
                );
              } else {
                return new ListTile(
                  title: new Text(serachResults[index].title),
                  trailing: new Text(
                      (serachResults[index].dist / 1000).toStringAsFixed(2) +
                          ' Km'),
                  onTap: () => showLocation(serachResults[index]),
                );
              }
            },
            itemCount: serachResults.length,
          ),
        ),
        new Container(
          color: Theme.of(context).primaryColor,
          padding: EdgeInsets.all(15),
          child: new SafeArea(child: AbfahrtStyle.forceIosStyle
              ? (new CupertinoTextField(
                  controller: this.searchInputController,
                  placeholder: 'Suche',
                  suffix: new CupertinoButton(
                    child: new Icon(CupertinoIcons.location),
                    onPressed: findLoaction,
                  ),
                  onSubmitted: (String text) {
                    findByQuery(text);
                  },
                ))
              : (new TextField(
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  controller: this.searchInputController,
                  onSubmitted: (String text) async {
                    findByQuery(text);
                  },
                  decoration: new InputDecoration(
                    labelText: 'Suche',
                    labelStyle: TextStyle(
                      color: Colors.white,
                    ),
                    suffixIcon: new IconButton(
                      icon: new Icon(Icons.location_searching,
                          color: Colors.white),
                      onPressed: findLoaction,
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.white,
                      ),
                    ),
                    border: const OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.white,
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.white,
                      ),
                    ),
                  ),
                )),
        ),),
      ],
    );

    if (AbfahrtStyle.forceIosStyle) {
      return new CupertinoPageScaffold(
        navigationBar: new CupertinoNavigationBar(
          middle: new Text('Abfahrts Monitor'),
        ),
        child: body,
      );
    } else {
      return new Scaffold(
        body: body,
        appBar: AppBar(
          title: Text(widget.title),
          actions: <Widget>[
            new IconButton(
              tooltip: 'Favoriten',
              icon: new Icon(Icons.favorite),
              onPressed: () {
                Navigator.of(context).pushNamed('favorites');
              },
            ),
            new IconButton(
              tooltip: 'Einstellungen',
              icon: new Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).pushNamed('settings');
              },
            )
          ],
        ),
      );
    }
  }
}
