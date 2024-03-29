import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'hafas.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:card_settings/card_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'type_select.dart';

class Sky extends CustomPainter {
  HafasStop stop;
  Sky(HafasStop _stop) {
    this.stop = _stop;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if ((this.stop.depatureLive != null &&
            this.stop.depatureLive.isAfter(DateTime.now())) ||
        this.stop.depature.isAfter(DateTime.now())) {
      canvas.drawRect(new Rect.fromLTWH(size.width / 2 - 2, 0, 4, size.height),
          Paint()..color = Colors.black26);
    } else {
      canvas.drawRect(new Rect.fromLTWH(size.width / 2 - 2, 0, 4, size.height),
          Paint()..color = Colors.red);
    }

    Offset of = new Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(of, 15, Paint()..color = const Color(0xFF2296F3));

    final ParagraphBuilder paragraphBuilder =
        ParagraphBuilder(ParagraphStyle(fontWeight: FontWeight.w600))
          ..addText('H');
    final Paragraph paragraph = paragraphBuilder.build()
      ..layout(ParagraphConstraints(width: size.width / 2));

    canvas.drawParagraph(paragraph, of.translate(-5, -8));
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder {
    return (Size size) {
      return [];
    };
  }

  @override
  bool shouldRepaint(Sky oldDelegate) => false;
  @override
  bool shouldRebuildSemantics(Sky oldDelegate) => false;
}

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
  List<HafasItem> departures = [];
  Future<dynamic> loading;
  bool loaded = false;
  bool fav = false;
  List<HafasProduct> products = [];
  Timer updateTimer;
  DateTime dateFilter;
  DateFormat timeFormat = new DateFormat('HH:mm');
  @override
  void initState() {
    super.initState();
    if (this.widget.dateFilter != null) {
      this.dateFilter = this.widget.dateFilter;
    } else {
      // this.dateFilter = DateTime.now();
    }
    tabController = new TabController(vsync: this, length: 2);
    this.updateData();
    updateTimer = new Timer.periodic(const Duration(seconds: 30), (timer) {
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
    var ldn = this.widget.station.depatures(
          date: dateFilter ??
              new DateTime.now().subtract(new Duration(minutes: 1)),
          duration: const Duration(hours: 6),
        );
    var _fav = false;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      var tprefs = prefs.getStringList(this.widget.station.lid + '_types');
      this.products = tprefs
          .map((e) => HafasProduct.PRODUCTS.firstWhere((p) => p.id == e))
          .toList();
    } catch (e) {
      this.products = [];
    }

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

  IconData getProductIcon(HafasProduct product) {
    if (product == HafasProduct.BUS) {
      return Icons.directions_bus;
    } else if (product == HafasProduct.U_BAHN) {
      return Icons.directions_subway;
    } else if (product == HafasProduct.TRAM) {
      return Icons.tram;
    } else if (product == HafasProduct.FERRY) {
      return Icons.directions_boat;
    } else if (product == HafasProduct.TAXI) {
      return Icons.local_taxi;
    } else {
      return Icons.train;
    }
  }

  Future<void> showTypeSelect(BuildContext context) async {
    showBottomSheet(
      builder: (BuildContext context) {
        return new ProductSelect(
            products: this.products,
            title: this.widget.station.title,
            dateFilter: this.dateFilter,
            lines: [],
            change: (p, d) async {
              this.dateFilter = d;
              SharedPreferences prefs = await SharedPreferences.getInstance();
              var prds = this.products.map((pr) {
                return pr.id;
              }).toList();
              prefs.setStringList(this.widget.station.lid + '_types', prds);
              this.updateData();
            });
      },
      context: context,
    );
  }

  Future<void> showMetaInfo(HafasItem line, BuildContext context) async {
    showBottomSheet(
      builder: (BuildContext context) {
        List<Widget> stops = line.stops.map((item) {
          var diffMin = 0;
          var row = new Row(
            children: <Widget>[
              new Text(timeFormat.format(item.arivalLive ??
                  item.depatureLive ??
                  item.arival ??
                  item.depature)),
              new Text(' - '),
              new Text(timeFormat.format(item.depatureLive ??
                  item.arivalLive ??
                  item.arival ??
                  item.depature))
            ],
          );
          if (diffMin > 0) {
            row.children.add(new Text(
              ' +' + diffMin.toString(),
              style: new TextStyle(color: Colors.red),
            ));
          }
          return new InkWell(
            onTap: () {
              showLocation(item.station, item.arivalLive);
            },
            child: new Flex(
              children: <Widget>[
                new Container(
                  child: CustomPaint(
                    painter: Sky(item),
                    size: new Size(
                      70,
                      72,
                    ),
                  ),
                ),
                new Expanded(
                  child: new ListTile(
                    selected: item.station.id == this.widget.station.id,
                    contentPadding: EdgeInsets.all(0),
                    title: new Text(item.station.title),
                    subtitle: row,
                  ),
                )
              ],
              direction: Axis.horizontal,
            ),
          );
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
                          child: new Icon(
                            getProductIcon(line.product),
                            size: 32,
                            color: Colors.white,
                          ),
                          margin: const EdgeInsets.only(
                            right: 15,
                          ),
                        ),
                        new Expanded(
                          child: new Text(
                            line.name + ' - ' + line.info + (line.stops.first.platform == null ? '' : line.stops.first.platform),
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
        if (minutesTDep.inMinutes > 240) {
          depString = minutesTDep.toString().substring(0, 1) + ' Std.';
        } else {
          depString = (minutesTDep.inMinutes + 1).toString() + ' Min.';
        }
        return new ListTile(
            contentPadding: EdgeInsets.all(0),
            title: new Text(line.info),
            // key: Key(line),
            leading: new Container(
              child: new Icon(getProductIcon(line.product)),
              height: double.infinity,
              padding: EdgeInsets.only(left: 15),
            ),
            onTap: () {
              showMetaInfo(line, context);
            },
            trailing: new Padding(
              child: new Text(
                depString,
                style: Theme.of(context).textTheme.subhead.copyWith(
                    color:
                        minutesTDep.inMinutes < 0 ? Colors.red : Colors.green),
              ),
              padding: new EdgeInsets.only(right: 15),
            ),
            // isThreeLine: true,
            subtitle: new Row(
              children: <Widget>[
                new Text(
                  stop.platform != null ? 'Gleis ' + stop.platform + ' - ' : '',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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

  buildSettingsTab() {
    return new Container(
      child: CardSettings(
        children: <Widget>[
          CardSettingsHeader(label: 'Favorite Book'),
          CardSettingsMultiselect(
            label: 'Linien',
            initialValues: ["Wiesbaden"],
            options: ["Wiesbaden", "Berlin"],
          ),
          CardSettingsMultiselect(
            label: 'Typen',
            initialValues: this.products.map((p) => p.name).toList(),
            onChanged: (pr) async {
              var prdcs = pr
                  .map((e) =>
                      HafasProduct.PRODUCTS.firstWhere((p) => p.name == e))
                  .toList();
              setState(() {
                this.products = prdcs;
              });
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setStringList(this.widget.station.lid + '_types', pr);
            },
            options: HafasProduct.PRODUCTS.map((p) => p.name).toList(),
          ),
          CardSettingsButton(
            backgroundColor: Colors.red,
            label: "Zurücksetzen",
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        floatingActionButton: new Builder(
          builder: (context) {
            return FloatingActionButton(
              child: const Icon(Icons.filter_list),
              onPressed: () {
                this.showTypeSelect(context);
              },
            );
          },
        ),
        appBar: AppBar(
          title: Text(widget.title),
          actions: <Widget>[],
          bottom: TabBar(
            controller: tabController,
            tabs: [
              Tab(icon: Icon(Icons.departure_board)),
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
                  return new Center(child: new CircularProgressIndicator());
                } else if (snapshot.error != null) {
                  return new Center(child: new Text("ERROR"));
                } else {
                  return buildTimeTableTab();
                }
              },
              future: loading,
            ),
            buildMapTab(),
          ],
        ));
  }
}
