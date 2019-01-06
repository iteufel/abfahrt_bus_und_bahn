import 'dart:async';
import 'package:abfahrt_gui/style.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'hafas.dart';
import 'package:intl/intl.dart';
import 'favorites.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';

class StopPage extends StatefulWidget {
  StopPage({Key key, this.title, this.station}) : super(key: key);

  final String title;
  final HafasStation station;

  @override
  _StopPageState createState() => _StopPageState();
}

class _StopPageState extends State<StopPage>
    with SingleTickerProviderStateMixin {
  TabController tabController;
  List<dynamic> departures = [];
  Future<dynamic> loading;
  bool loaded = false;
  bool fav = false;
  Timer updateTimer;
  DateFormat timeFormat = new DateFormat('HH:mm');
  @override
  void initState() {
    super.initState();
    tabController = new TabController(vsync: this, length: 2);
    this.updateData();
    updateTimer = new Timer.periodic(const Duration(seconds: 20), (timer) {
      updateData();
    });
  }

  @override
  void dispose() {
    if(updateTimer.isActive) {
      updateTimer.cancel();
    }
    super.dispose();
  }


  Future<void> updateData() async {
    var RMV = new Hafas(config: new HafasConfig());
    var ldn = RMV.departures(widget.station.id);
    var _fav = false;

    if (!loaded) {
      setState(() {
        loading = ldn;
        fav = _fav;
      });
    }

    var res = await ldn;

    res = (res as List<dynamic>).where((r) {
      return r['isRchbl'];
    }).map((r) {
      var dTimeS = r['stbStop']['dTimeS'] as String;
      var date = r['date'] as String;

      var time = new DateTime(
          int.parse(date.substring(0, 4)),
          int.parse(date.substring(4, 6)),
          int.parse(date.substring(6, 8)),
          int.parse(dTimeS.substring(0, 2)),
          int.parse(dTimeS.substring(2, 4)),
          int.parse(dTimeS.substring(4, 6)));
      r['time'] = time;
      return r;
    }).toList();

    setState(() {
      if(!loaded) {
        loading = ldn;
      }
      departures = res;
      loaded = true;
    });
  }

  Future<void> showMetaInfo(info, BuildContext context) async {
    print(info['prod']['prodCtx']['catCode']);

    showBottomSheet(
      builder: (BuildContext context) {
        return new Material(
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25), topRight: Radius.circular(25)),
          child: new Container(
            child: new SafeArea(
              child: new Column(
                children: <Widget>[
                  new Container(
                    child: new Row(
                      children: <Widget>[
                        new Expanded(
                          child: new Text(
                            info['prod']['name'] + ' - ' + info['dirTxt'],
                            style: Theme.of(context).textTheme.title.copyWith(
                                  color: Colors.white,
                                ),
                            maxLines: 2,
                          ),
                        ),
                        new IconButton(
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 36,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        )
                      ],
                    ),
                    padding: new EdgeInsets.all(15),
                    color: Theme.of(context).primaryColor,
                  ),
                  new Container(
                    child: new ListView(
                      children: <Widget>[
                        new ListTile(
                          title: new Text('dfdf'),
                        )
                      ],
                    ),
                    height: 200,
                  )
                ],
                mainAxisSize: MainAxisSize.min,
              ),
            ),
            constraints: const BoxConstraints(
              minWidth: double.infinity,
              minHeight: 425,
            ),
          ),
          color: Colors.white,
          elevation: 10,
        );
      },
      context: context,
    );
  }

  Widget buildMapTab() {
    return new FlutterMap(
      options: new MapOptions(
        center: new LatLng(
          widget.station.location.lat,
          widget.station.location.lon,
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
        new MarkerLayerOptions(
          markers: [
            new Marker(
              width: 80.0,
              height: 80.0,
              point: new LatLng(
                widget.station.location.lat,
                widget.station.location.lon,
              ),
              builder: (ctx) => new Container(
                    child: new Icon(
                      Icons.pin_drop,
                    ),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildTimeTableTab() {
    var now = DateTime.now();
    var list = new ListView.builder(
      itemBuilder: (context, index) {
        var time = departures[index]['time'] as DateTime;
        var minutesTDep = time.difference(now);
        var depString = '';
        if (minutesTDep.inMinutes > 60) {
          depString = minutesTDep.toString().substring(0, 4);
        } else {
          depString = minutesTDep.inMinutes.toString() + ' Min';
        }
        return new ListTile(
          title: new Text(departures[index]['dirTxt']),
          key: Key(departures[index]['jid']),
          leading:
              int.parse(departures[index]['prod']['prodCtx']['catCode']) == 5
                  ? new Icon(Icons.directions_bus)
                  : new Icon(Icons.directions_railway),
          onTap: () {
            showMetaInfo(departures[index], context);
          },
          trailing: new Text(
            depString,
            style: new TextStyle(
              color: minutesTDep.inMinutes < 0 ? Colors.red : Colors.green,
            ),
          ),
          // isThreeLine: true,
          subtitle: new Text(departures[index]['prod']['name'] +
              ' - ' +
              timeFormat.format(time)),
        );
      },
      itemCount: departures.length,
    );

    return new RefreshIndicator(
      child: list,
      onRefresh: () async {
        await updateData();
      },
    );
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
          middle: new Text(widget.title),
          backgroundColor: Colors.transparent,
          border: null,
        ),
        child: new Text('dfdf'),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          // Here we take the value from the StopPage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
          actions: <Widget>[
            new IconButton(
              tooltip: 'Favoriten',
              icon: fav
                  ? const Icon(Icons.favorite)
                  : const Icon(Icons.favorite_border),
              onPressed: () {
                FavManager.current.add(widget.station);
              },
            ),
          ],
          bottom: TabBar(
            controller: tabController,
            tabs: [
              Tab(icon: Icon(Icons.directions_transit)),
              Tab(icon: Icon(Icons.map)),
            ],
          ),
        ),
        body: TabBarView(
          controller: tabController,
          children: [
            new FutureBuilder(
              builder: (constext, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return new Center(
                    child: new Container(
                      child: new CircularProgressIndicator(),
                      height: 48,
                      width: 48,
                    ),
                  );
                } else {
                  return buildTimeTableTab();
                }
              },
              future: loading,
            ),
            buildMapTab(),
          ],
        ),
      );
    }
  }
}
