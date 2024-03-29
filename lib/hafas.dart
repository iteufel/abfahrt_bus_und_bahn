// import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:dio/dio.dart';

class HafasProduct {
  static HafasProduct ICE = new HafasProduct(
    id: "nationalExpress",
    mode: "train",
    bitmasks: 1,
    name: "ICE",
    short: "ICE",
  );
  static HafasProduct IC = new HafasProduct(
    id: "national",
    mode: "train",
    bitmasks: 2,
    name: "IC/EC",
    short: "IC/EC",
  );
  static HafasProduct RE = new HafasProduct(
    id: "regionalExp",
    mode: "train",
    bitmasks: 4,
    name: "RE/IR",
    short: "RE/IR",
  );
  static HafasProduct RB = new HafasProduct(
    id: "regional",
    mode: "train",
    bitmasks: 8,
    name: "Regio",
    short: "RB",
  );
  static HafasProduct S_BAHN = new HafasProduct(
    id: "suburban",
    mode: "train",
    bitmasks: 16,
    name: "S-Bahn",
    short: "S",
  );
  static HafasProduct BUS = new HafasProduct(
    id: "bus",
    mode: "bus",
    bitmasks: 32,
    name: "Bus",
    short: "B",
  );
  static HafasProduct FERRY = new HafasProduct(
    id: "ferry",
    mode: "watercraft",
    bitmasks: 64,
    name: "Fähre",
    short: "F",
  );
  static HafasProduct U_BAHN = new HafasProduct(
    id: "subway",
    mode: "train",
    bitmasks: 128,
    name: "U-Bahn",
    short: "U",
  );
  static HafasProduct TRAM = new HafasProduct(
    id: "tram",
    mode: "train",
    bitmasks: 256,
    name: "Tram",
    short: "T",
  );
  static HafasProduct TAXI = new HafasProduct(
    id: "taxi",
    mode: "taxi",
    bitmasks: 512,
    name: "Taxi",
    short: "Taxi",
  );

  static var PRODUCTS = [
    HafasProduct.IC,
    HafasProduct.ICE,
    HafasProduct.RB,
    HafasProduct.RE,
    HafasProduct.S_BAHN,
    HafasProduct.TRAM,
    HafasProduct.U_BAHN,
    HafasProduct.BUS,
    HafasProduct.TAXI,
    HafasProduct.FERRY,
  ];

  static HafasProduct getProduct(int id) {
    return HafasProduct.PRODUCTS.firstWhere((e) => e.bitmasks == id);
  }

  String id;
  String mode;
  String name;
  String short;
  int bitmasks;
  bool defaultProduct = true;
  HafasProduct({
    this.id,
    this.bitmasks,
    this.defaultProduct,
    this.mode,
    this.name,
    this.short,
  });
}

class HafasLocation {
  HafasLocation({
    this.lat,
    this.lon,
  });
  double lat;
  double lon;

  double getDistance(HafasLocation location) {
    var p = 0.017453292519943295; // Math.PI / 180
    var a = 0.5 -
        cos((location.lat - lat) * p) / 2 +
        cos(lat * p) *
            cos(location.lat * p) *
            (1 - cos((location.lon - lon) * p)) /
            2;
    return (12742 * asin(sqrt(a))) * 1000; // 2 * R; R = 6371 km
  } // Returns distance in Km
}

class HafasStation {
  HafasStation({
    this.title,
    this.id,
    this.location,
    this.dist,
    this.lid,
    this.instance,
  });
  Hafas instance;
  String title;
  int id;
  String lid;
  int dist = 0;
  HafasLocation location;
  List<HafasLineInfo> lineInfo = [];

  Future<List<HafasItem>> getDepArr({
    DateTime date,
    Duration duration,
    String type,
  }) async {
    if (date == null) {
      date = DateTime.now();
    }
    var req = {
      'type': 'DEP',
      'time': new DateFormat("HHmmss").format(date),
      'date': new DateFormat("yyyyMMdd").format(date),
      'stbLoc': {
        'lid': Uri.encodeFull('A=1@L=' + id.toString() + '@'),
      },
      // 'rtMode': 'OFF',
      'getPasslist': true,
      'stbFltrEquiv': true,
      // 'showPassingPoints': true,
      // 'getConGroups': false,
      // 'getPolyline': false,
      //'stbFltrEquiv': false,
      // jnyFltrL: [products],
      'dur': duration != null ? duration.inMinutes : 60 * 12
    };
    try {
      var res = await instance._request(
        {
          'meth': 'StationBoard',
          'req': req,
        },
        {},
      );
      var prodL = res['common']['prodL'];
      var locL = res['common']['locL'];

      var items = new List<HafasItem>();
      res['jnyL'].forEach((dynamic item) {
        var stops = new List<HafasStop>();
        var prod = prodL[item['prodX']];
        var product =
            HafasProduct.PRODUCTS.firstWhere((e) => e.bitmasks == prod['cls']);
        String platform;
        if (item['stopL'].length > 0) {
          platform = item['stopL'][0]["dPlatfS"];
        }
        item['stopL'].forEach((stop) {
          var stopInfo = locL[stop['locX']];
          var stopPlatform = stop["dPlatfS"];
          var dtime =
              Hafas.parseDate(item['date'], stop['dTimeS'] ?? stop['dTimeR']);
          var liveDtime =
              Hafas.parseDate(item['date'], stop['dTimeR'] ?? stop['dTimeS']);
          var atime =
              Hafas.parseDate(item['date'], stop['aTimeS'] ?? stop['aTimeR']);
          var liveAtime =
              Hafas.parseDate(item['date'], stop['aTimeR'] ?? stop['aTimeS']);

          if (liveDtime != null &&
              liveDtime.difference(DateTime.now()).inMinutes < -60) {
            liveDtime = liveDtime.add(const Duration(days: 1));
          }

          if (dtime != null &&
              dtime.difference(DateTime.now()).inMinutes < -60) {
            dtime = dtime.add(const Duration(days: 1));
          }
          if (atime != null &&
              atime.difference(DateTime.now()).inMinutes < -60) {
            atime = atime.add(const Duration(days: 1));
          }
          if (liveAtime != null &&
              liveAtime.difference(DateTime.now()).inMinutes < -60) {
            liveAtime = liveAtime.add(const Duration(days: 1));
          }

          if (product != HafasProduct.BUS) {
           // debugger();
          }

          stops.add(new HafasStop(
            arival: atime ?? dtime,
            depature: dtime ?? atime,
            depatureLive: liveDtime ?? dtime,
            arivalLive: liveAtime ?? atime,
            platform: stopPlatform,
            station: new HafasStation(
              title: stopInfo['name'],
              id: int.parse(stopInfo['extId']),
              dist: stopInfo['dist'],
              lid: stopInfo['lid'],
              location: new HafasLocation(
                lat: stopInfo['crd']['y'] / 1000000,
                lon: stopInfo['crd']['x'] / 1000000,
              ),
              instance: this.instance,
            ),
          ));
        });
        items.add(new HafasItem(
            name: prod['name'],
            product: product,
            info: item['dirTxt'],
            type: int.parse(prod['prodCtx']['catCode']) == 5 ? 'BUS' : 'TRAIN',
            stops: stops));
      });
      return items;
    } catch (e) {
      return [];
    }
  }

  Future<List<HafasItem>> depatures({
    DateTime date,
    Duration duration,
  }) async {
    return this.getDepArr(
      type: 'DEP',
      date: date,
      duration: duration,
    );
  }

  Future<List<HafasItem>> arivals({
    DateTime date,
    Duration duration,
  }) async {
    return this.getDepArr(
      type: 'ARR',
      date: date,
      duration: duration,
    );
  }
}

class HafasStop {
  HafasStop(
      {this.station,
      this.depature,
      this.arival,
      this.arivalLive,
      this.depatureLive,
      this.platform,
      this.info});
  HafasStation station;
  DateTime depature;
  DateTime arival;
  DateTime depatureLive;
  DateTime arivalLive;
  String platform;
  String info;
}

class HafasLineInfo {
  HafasLineInfo({this.id, this.name});
  String name;
  String id;
}

class HafasItem {
  HafasItem({this.name, this.info, this.type, this.stops, this.product});
  HafasProduct product;
  String name;
  String info;
  dynamic data;

  List<HafasStop> stops;
  String type;

  HafasStop getStopByStation(HafasStation station) {
    try {
      return stops.firstWhere((s) => s.station.id == station.id);
    } catch (e) {
      return null;
    }
  }

  DateTime getEstimatedDepatureForStation(HafasStation station) {
    var stop = this.getStopByStation(station);
    return stop == null ? stop.depature : null;
  }

  DateTime getLiveDepatureForStation(HafasStation station) {
    var stop = this.getStopByStation(station);
    return stop == null ? stop.depature : null;
  }

  DateTime getEstimatedArivalForStation(HafasStation station) {
    var stop = this.getStopByStation(station);
    return stop == null ? stop.arival : null;
  }

  DateTime getLiveArivalForStation(HafasStation station) {
    var stop = this.getStopByStation(station);
    return stop == null ? stop.arival : null;
  }

  HafasStop getNextStop() {
    return null;
  }

  HafasLocation getLocation() {
    return null;
  }
}

class HafasConfig {
  HafasConfig({this.userAgent, this.products});
  String userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0.2 Safari/605.1.15';
  String endpoint = 'https://reiseauskunft.bahn.de/bin/mgate.exe';
  String timezone = 'Europe/Berlin';
  String locale = 'de-DE';
  String salt = 'bdI8UVj40K5fvxwf';
  bool addChecksum = true;
  bool addMicMac = false;
  List<HafasProduct> products = [];
  dynamic parseDeparture(data) {}
  dynamic parseArrival(data) {}
  dynamic formatProductsFilter(List<HafasProduct> products) {}
  dynamic parseHint(data) {}

  dynamic parseOperator(data) {
    return data;
  }

  String formatDate(DateTime date) {
    return date.toIso8601String();
  }

  String formatTime(DateTime date) {
    return date.toIso8601String();
  }

  void transformReqBody(dynamic body) {
    body['client'] = {
      'id': 'DB',
      'v': '16040000',
      'type': 'IPH',
      'name': 'DB Navigator'
    };
    body['ext'] = 'DB.R18.06.a';
    body['ver'] = '1.16';
    body['auth'] = {
      'type': 'AID',
      'aid': 'n91dB8Z77MLdoR0K',
    };
  }

  void transformReq(
    Options req,
    Map<String, String> query,
  ) {}
  String formatCoord(double cord) {
    return (cord * 1000000).round().toString();
  }
}

abstract class DeparturesOptions {
  String direction;
  int duration;
  bool stationLines;
  bool remarks;
  bool stopovers;
  bool includeRelatedStations;
  DateTime when;
}

abstract class ArrivalOptions {
  String direction;
  int duration;
  bool stationLines;
  bool remarks;
  bool stopovers;
  bool includeRelatedStations;
  DateTime when;
}

class Hafas {
  HafasConfig config;
  Dio _dio;
  Hafas({
    this.config,
  }) {
    _dio = new Dio();
    _dio.options.baseUrl = config.endpoint;
    _dio.options.connectTimeout = 5000; //5s
    _dio.options.receiveTimeout = 3000;
    _dio.options.headers['user-agent'] = config.userAgent;
    _dio.options.responseType = ResponseType.json;
    _dio.options.contentType = ContentType.json;
    _dio.options.method = 'POST';
  }

  String buildQueryString(
    Map<String, String> query,
  ) {
    return query.entries.map((entry) {
      return Uri.encodeQueryComponent(entry.key) +
          '=' +
          Uri.encodeQueryComponent(entry.value);
    }).join('&');
  }

  String formatLocationIdentifier(
    Map<String, String> query,
  ) {
    return query.entries.map((entry) {
          return Uri.encodeQueryComponent(entry.key) +
              '@' +
              Uri.encodeQueryComponent(entry.value);
        }).join('&') +
        '@';
  }

  static DateTime parseDate(
    String date,
    String time,
  ) {
    if (date == null || time == null) {
      return null;
    }
    return new DateTime(
      int.parse(date.substring(0, 4)),
      int.parse(date.substring(4, 6)),
      int.parse(date.substring(6, 8)),
      int.parse(time.substring(0, 2)),
      int.parse(time.substring(2, 4)),
      int.parse(time.substring(4, 6)),
    );
  }

  Future<dynamic> _request(inputData, opt) async {
    var body = {
      'lang': 'en', // todo: is it `eng` actually?
      'svcReqL': [inputData]
    };
    config.transformReqBody(body);
    var bodyString = jsonEncode(body);
    var mopts = new RequestOptions(
      data: bodyString,
      baseUrl: config.endpoint,
      connectTimeout: 5000,
      receiveTimeout: 10000,
      headers: {
        "user-agent": config.userAgent,
      },
      responseType: ResponseType.json,
      contentType: ContentType.json,
      method: 'POST',
    );

    Map<String, String> query = {};
    config.transformReq(mopts, query);
    if (config.addChecksum) {
      var bytes = utf8.encode(bodyString + config.salt); // data being hashed
      var digest = crypto.md5.convert(bytes);
      query['checksum'] = digest.toString();
    }
    Response<Map<String, dynamic>> res =
        await _dio.request('?' + buildQueryString(query), options: mopts);
    if (res.data.containsKey('error')) {
      throw new Error();
    }
    if (!res.data.containsKey('svcResL')) {
      throw new Error();
    }
    return res.data['svcResL'][0]['res'];
  }

  Future<HafasStation> station(int station) async {
    return null;
  }

  Future<List<HafasStation>> findStationsByCoordinates(
    HafasLocation location,
    double scale,
  ) async {
    var res = await _request({
      'cfg': {'polyEnc': 'GPA'},
      'meth': 'LocGeoPos',
      'req': {
        'ring': {
          'cCrd': {
            'x': config.formatCoord(location.lon),
            'y': config.formatCoord(location.lat)
          },
          'maxDist': -1,
          'minDist': 0
        },
        'getPOIs': false,
        'getStops': true
      }
    }, {});

  if(res['locL'] == null) {
    return [];
  }

    return (res['locL'] as List).map((value) {
      return new HafasStation(
        title: value['name'],
        id: int.parse(value['extId']),
        dist: value['dist'],
        lid: value['lid'],
        location: new HafasLocation(
          lat: value['crd']['y'] / 1000000,
          lon: value['crd']['x'] / 1000000,
        ),
        instance: this,
      );
    }).toList();
  }

  Future<List<HafasStation>> findStationsByQuery(
    String query,
    HafasLocation location,
  ) async {
    var res = await _request({
      'cfg': {
        'polyEnc': 'GPA',
      },
      'meth': 'LocMatch',
      'req': {
        'input': {
          'loc': {
            // 'type': ,
            'name': query + '?',
          },
          'maxLoc': 25,
          'field': 'S'
        },
      }
    }, {});
    var list = (res['match']['locL'] as List).map((value) {
      var loc = new HafasLocation(
        lat: value['crd']['y'] / 1000000,
        lon: value['crd']['x'] / 1000000,
      );
      return new HafasStation(
        title: value['name'],
        id: int.parse(value['extId'] ?? '0'),
        dist: location != null ? loc.getDistance(location).toInt() : 0,
        lid: value['lid'],
        location: loc,
        instance: this,
      );
    }).toList();
    if (location != null) {
      list.sort((a, b) {
        return a.dist - b.dist;
      });
    }
    return list;
  }
}

/*main(List<String> args) async {
  var bahn = new Hafas(config: new HafasConfig());
  List<HafasStation> res =
      await bahn.findStationsByQuery('gneisenaustraße wiesbaden', null);
  //print(res.first.title);
  //print('-------------');
  var deps = await res.first.depatures();
  deps.forEach((line) {
    print(line.name + ' - ' + line.info);
    line.stops.forEach((stop) {
      print('\t' +
          stop.station.title +
          ' - ' +
          stop.arival.toString() +
          '/' +
          stop.depature.toString() +
          '');
    });
    exit(0);
  });
}*/
