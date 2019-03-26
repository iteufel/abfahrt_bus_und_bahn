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
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

class StopPage extends StatefulWidget {
  StopPage({Key key, this.title, this.station, this.dateFilter})
      : super(key: key);

  final String title;
  final HafasStation station;
  final DateTime dateFilter;

  @override
  _StopPageState createState() => _StopPageState();
}

class _StopPageState extends State<StopPage>
    with SingleTickerProviderStateMixin {
  TabController tabController;
  List<HafasLine> departures = [];
  Future<dynamic> loading;
  bool loaded = false;
  bool fav = false;
  Timer updateTimer;
  DateTime dateFilter;
  DateFormat timeFormat = new DateFormat('HH:mm');
  @override
  void initState() {
    super.initState();
    if (this.widget.dateFilter != null) {
      this.dateFilter = this.widget.dateFilter;
    }
    tabController = new TabController(vsync: this, length: 2);
    this.updateData();
    updateTimer = new Timer.periodic(const Duration(seconds: 20), (timer) {
      updateData();
    });
  }

  @override
  void dispose() {
    if (updateTimer.isActive) {
      updateTimer.cancel();
    }
    super.dispose();
  }

  Future<void> updateData() async {
    var ldn = this.widget.station.depatures(date: dateFilter);
    var _fav = false;

    if (!loaded && mounted) {
      setState(() {
        loading = ldn;
        fav = _fav;
      });
    }

    var res = await ldn;
    if (mounted) {
      setState(() {
        if (!loaded) {
          loading = ldn;
        }
        departures = res;
        loaded = true;
      });
    }
  }

  void showLocation(HafasStation station, DateTime date) {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) => new StopPage(
              title: station.title,
              station: station,
              dateFilter: date,
            ),
      ),
    );
  }

  Future<void> showMetaInfo(HafasLine line, BuildContext context) async {
    showBottomSheet(
      builder: (BuildContext context) {
        List<Widget> stops = line.stops.map((item) {
          // var diff = item.arivalLive.difference(item.arival);
          var diffMin = 0; //diff.inMinutes;
          var row = new Row(
            children: <Widget>[
              new Text(timeFormat.format(item.arivalLive ??
                  item.arival ??
                  item.depature ??
                  item.depatureLive)),
              new Text(' - '),
              new Text(timeFormat.format(item.depatureLive ??
                  item.depature ??
                  item.arivalLive ??
                  item.arival))
            ],
          );
          if (diffMin > 0) {
            row.children.add(new Text(
              ' +' + diffMin.toString(),
              style: new TextStyle(color: Colors.red),
            ));
          }
          return new ListTile(
              leading: new ConstrainedBox(
                constraints: BoxConstraints.tightFor(width: 10),
                child: Container(
                  color: Colors.red,
                ),
              ),
              title: new Text(item.station.title),
              onTap: () {
                showLocation(item.station, item.arivalLive);
              },
              subtitle: row);
        }).toList();
        return new Material(
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: new Container(
            height: 575,
            child: new SafeArea(
              child: new Column(
                children: <Widget>[
                  new Container(
                    child: new Row(
                      children: <Widget>[
                        new Container(
                          child: line.type == 'BUS'
                              ? new Icon(
                                  Icons.directions_bus,
                                  size: 32,
                                  color: Colors.white,
                                )
                              : new Icon(
                                  Icons.directions_railway,
                                  size: 32,
                                  color: Colors.white,
                                ),
                          margin: const EdgeInsets.only(right: 15),
                        ),
                        new Expanded(
                          child: new Text(
                            line.name + ' - ' + line.info,
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
                  new Expanded(
                    child: new ListView(
                      children: stops,
                    ),
                    //mmi: 200,
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
        var line = this.departures[index];
        var stop =
            line.getStopByStation(this.widget.station) ?? line.stops.first;
        var minutesTDep = stop.depatureLive.difference(now);
        var depString = '';
        var diffInMinutes = stop.depature == null
            ? 0
            : stop.depatureLive.difference(stop.depature).inMinutes;
        if (minutesTDep.inMinutes > 120) {
          depString = minutesTDep.toString().substring(0, 4) + ' Std.';
        } else {
          depString = (minutesTDep.inMinutes + 1).toString() + ' Min.';
        }
        return new ListTile(
            title: new Text(line.info),
            // key: Key(line),
            leading: line.type == 'BUS'
                ? new Icon(Icons.directions_bus)
                : new Icon(Icons.directions_railway),
            onTap: () {
              showMetaInfo(line, context);
            },
            trailing: new Text(
              depString,
              style: new TextStyle(
                color: minutesTDep.inMinutes < 0 ? Colors.red : Colors.green,
              ),
            ),
            // isThreeLine: true,
            subtitle: new Row(
              children: <Widget>[
                new Text(line.name + ' - ' + timeFormat.format(stop.depature)),
                new Text(
                  diffInMinutes > 0 ? ' +' + diffInMinutes.toString() : '',
                  style: new TextStyle(
                    color: Colors.red,
                  ),
                )
              ],
            ));
      },
      itemCount: departures.length,
    );

    return new LiquidPullToRefresh(
      child: list,
      showChildOpacityTransition: false,
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
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.timer),
          tooltip: dateFilter.toString(),
          onPressed: () {
            DatePicker.showDateTimePicker(context, showTitleActions: true,
                onChanged: (date) {
              /*this.dateFilter = date;
                      this.updateData();*/
            }, onConfirm: (date) {
              this.dateFilter = date;
              this.updateData();
            },
                currentTime: dateFilter != null ? dateFilter : DateTime.now(),
                theme: DatePickerTheme(
                  backgroundColor: Theme.of(context).primaryColor,
                  itemStyle: TextStyle(color: Colors.white),
                  doneStyle: TextStyle(color: Colors.white),
                  cancelStyle: TextStyle(color: Colors.black38),
                ),
                locale: LocaleType.en);
          },
        ),
        appBar: AppBar(
          // Here we take the value from the StopPage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),

          actions: <Widget>[],
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
