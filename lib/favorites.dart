import 'dart:async';
import 'package:abfahrt_gui/stop.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:path/path.dart';
import 'hafas.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class FavManager {
  Database database;
  FavManager() {}
  Future<void> initDb() async {
    if (database == null) {
      var databasesPath = await getDatabasesPath();
      String path = join(databasesPath, 'abf.db');
      database = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        // When creating the db, create the table
        await db.execute(
            'CREATE TABLE Favorites (id INTEGER PRIMARY KEY, title TEXT, lat FLOAT, lon FLOAT)');
      });
    }
  }

  Future<void> add(HafasStation station) async {
    await initDb();
    await database.insert('Favorites', {
      'id': station.id,
      'title': station.title,
      'lat': station.location.lat,
      'lon': station.location.lon
    });
  }

  Future<void> remove(HafasStation station) async {
    await initDb();
    await database
        .delete('Favorites', where: 'id = ?', whereArgs: [station.id]);
  }

  Future<List<HafasStation>> get() async {
    await initDb();
    return (await database.rawQuery('SELECT * FROM Favorites')).map((res) {
      // TODO: CALC DIST
      return new HafasStation(
          title: res['title'],
          id: res['id'],
          location: new HafasLocation(
            lat: res['lat'],
            lon: res['lon'],
          ),
          dist: 0);
    }).toList();
  }

  Future<bool> check(int id) async {
    await initDb();
    return (await database.query(
          'Favorites',
          where: 'id',
          whereArgs: [id],
        ))
            .length >
        0;
  }

  static FavManager current = new FavManager();
}

class FavoritesPage extends StatefulWidget {
  FavoritesPage({Key key, this.title, this.station}) : super(key: key);

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
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List favs = [];

  @override
  void initState() {
    super.initState();
    this.load();
  }

  Future<void> load() async {
    //var prefs = await SharedPreferences.getInstance();
    var res = await FavManager.current.get();
    setState(() {
      this.favs = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the FavoritesPage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('Favoriten'),
        actions: <Widget>[],
      ),
      body: new ListView.builder(
        itemBuilder: (
          context,
          index,
        ) {
          return new ListTile(
            title: new Text(favs[index].title),
            onTap: () {
              Navigator.of(context).push(
                new MaterialPageRoute(
                  builder: (context) => new StopPage(
                        title: favs[index].title,
                        station: favs[index],
                      ),
                ),
              );
            },
          );
        },
        itemCount: favs.length,
      ),
    );
  }
}
