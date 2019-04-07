import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:geolocator/geolocator.dart';
import 'stop.dart';
import 'hafas.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  SearchPage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchInputController;

  double bottomSheetSize = 0;
  String locationName = "";
  Position position;

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
    position = await Geolocator().getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    List<Placemark> places = await Geolocator().placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    var rmv = new Hafas(config: new HafasConfig());
    var res = rmv.findStationsByCoordinates(
      new HafasLocation(
        lat: position.latitude,
        lon: position.longitude,
      ),
      1,
    );
    if (mounted) {
      setState(() {
        this.searchInputController.text = '';
        this.locationName = places.first.name;
        this.serachResults = res;
      });
    }
  }

  Future<void> findByQuery(String q) async {
    var RMV = new Hafas(config: new HafasConfig());
    Position position = await Geolocator().getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    var res = RMV.findStationsByQuery(
      q.trim(),
      new HafasLocation(
        lat: position.latitude,
        lon: position.longitude,
      ),
    );
    if (mounted) {
      setState(() {
        this.serachResults = res;
      });
    }
  }

  Future<List<HafasStation>> serachResults;

  Widget buildMap() {
    /*return new FlutterMap(
      options: new MapOptions(
        center: new LatLng(
          position.latitude, position.longitude
        ),
        zoom: 18.0,
      ),
      layers: [
        new TileLayerOptions(
          urlTemplate: "https://a.tile.openstreetmap.org/{z}/{x}/{y}.png",
          additionalOptions: {
            'id': 'mapbox.streets',
          },
        ),
      ],
    );*/
    return new Container(
      height: 0,
      width: double.infinity,
      color: Colors.amber,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body = new Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        new Expanded(
          child: FutureBuilder(
            builder: (context, state) {
              if (state.connectionState == ConnectionState.waiting) {
                return new Center(
                  child: new CircularProgressIndicator(),
                );
              }
              var results = state.data as List<HafasStation>;
              if (results.length == 0) {
                return new Center(
                  child: new Text(
                    "Keine Haltestelle gefunden.",
                    style: Theme.of(context).textTheme.subhead,
                  ),
                );
              }
              return new ListView.builder(
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
                              child: new Text(results[index].title),
                            ),
                            new Text(
                              (results[index].dist / 1000).toStringAsFixed(2) +
                                  ' Km',
                            )
                          ],
                        ),
                        onTap: () {
                          showLocation(results[index]);
                        },
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 18,
                      ),
                    );
                  } else {
                    return new ListTile(
                      title: new Text(results[index].title),
                      trailing: new Text(
                          (results[index].dist / 1000).toStringAsFixed(2) +
                              ' Km'),
                      onTap: () => showLocation(results[index]),
                    );
                  }
                },
                itemCount: results.length,
              );
            },
            future: serachResults,
          ),
        ),
      ],
    );

    return new Scaffold(
      body: body,
      bottomSheet: GestureDetector(
        onVerticalDragUpdate: (dragDetails) {},
        child: new Material(
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: new Container(
            child: new SafeArea(
              child: new Column(
                children: <Widget>[
                  new Container(
                    child: new TextField(
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      controller: this.searchInputController,
                      onSubmitted: (String text) async {
                        findByQuery(text);
                      },
                      decoration: new InputDecoration(
                        labelText: 'Suche',
                        hintText: 'Suche nach deiner Haltestelle',
                        alignLabelWithHint: true,
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
                    ),
                    padding: new EdgeInsets.fromLTRB(15, 15, 15, 15),
                    color: Theme.of(context).primaryColor,
                  ),
                  buildMap(),
                ],
                mainAxisSize: MainAxisSize.min,
              ),
            ),
            constraints: BoxConstraints(
              minWidth: double.infinity,
              maxHeight: 600,
            ),
          ),
          color: Theme.of(context).primaryColor,
          elevation: 10,
        ),
      ),
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[],
      ),
    );
  }
}
