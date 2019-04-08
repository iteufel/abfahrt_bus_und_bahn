import 'dart:async';
import 'package:abfahrt_gui/stop.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'hafas.dart';
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
    var res = await FavManager.current.get();
    setState(() {
      this.favs = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
