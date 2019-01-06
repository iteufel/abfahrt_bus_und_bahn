import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:intl/intl.dart';
import 'dart:math';

class HafasProduct {}

class HafasLine {}

class HafasLocation {
  HafasLocation({this.lat, this.lon});
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
  HafasStation({this.title, this.id, this.location, this.dist, this.lid});
  String title;
  int id;
  String lid;
  int dist = 0;
  HafasLocation location;
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
    body['ext'] = 'DB.R15.12.a';
    body['ver'] = '1.16';
    body['auth'] = {'type': 'AID', 'aid': 'n91dB8Z77MLdoR0K'};
  }

  void transformReq(Options req, Map<String, String> query) {}
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
  HafasConfig config = null;
  Dio _dio = null;
  Hafas({this.config}) {
    _dio = new Dio();
    _dio.options.baseUrl = config.endpoint;
    _dio.options.connectTimeout = 5000; //5s
    _dio.options.receiveTimeout = 3000;
    _dio.options.headers['user-agent'] = config.userAgent;
    _dio.options.responseType = ResponseType.JSON;
    _dio.options.contentType = ContentType.json;
    _dio.options.method = 'POST';
  }

  String buildQueryString(Map<String, String> query) {
    return query.entries.map((entry) {
      return Uri.encodeQueryComponent(entry.key) +
          '=' +
          Uri.encodeQueryComponent(entry.value);
    }).join('&');
  }

  String formatLocationIdentifier(Map<String, String> query) {
    return query.entries.map((entry) {
          return Uri.encodeQueryComponent(entry.key) +
              '@' +
              Uri.encodeQueryComponent(entry.value);
        }).join('&') +
        '@';
  }

  Future<dynamic> _request(inputData, opt) async {
    var body = {
      'lang': 'en', // todo: is it `eng` actually?
      'svcReqL': [inputData]
    };
    config.transformReqBody(body);
    var bodyString = jsonEncode(body);
    var mopts = _dio.options.merge(data: bodyString);
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
    // return res.data;
  }

  Future<dynamic> departures(int station) async {
    var req = {
      'type': 'DEP',
      'time': new DateFormat("HHmmss").format(DateTime.now()),
      'date': new DateFormat("yyyyMMdd").format(DateTime.now()),
      'stbLoc': {'lid': Uri.encodeFull('A=1@L=' + station.toString() + '@')},
      //dirLoc: dir,
      //jnyFltrL: [products],
      'dur': 120
    };
    try {
      var res = await _request({'meth': 'StationBoard', 'req': req}, {});
      var prodL = res['common']['prodL'];
      return res['jnyL'].map((item) {
        item['prod'] = prodL[item['prodX']];
        return item;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<HafasStation> station(int station) async {
    return new HafasStation();
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
    return (res['locL'] as List).map((value) {
      return new HafasStation(
          title: value['name'],
          id: int.parse(value['extId']),
          dist: value['dist'],
          lid: value['lid'],
          location: new HafasLocation(
              lat: value['crd']['y'] / 1000000,
              lon: value['crd']['x'] / 1000000));
    }).toList();
  }

  Future<List<HafasStation>> findStationsByQuery(
      String query, HafasLocation location) async {
    var res = await _request({
      'cfg': {'polyEnc': 'GPA'},
      'meth': 'LocMatch',
      'req': {
        'input': {
          'loc': {
            // 'type': ,
            'name': query + '?'
          },
          'maxLoc': 25,
          'field': 'S'
        },
      }
    }, {});
    var list = (res['match']['locL'] as List).map((value) {
      var loc = new HafasLocation(
          lat: value['crd']['y'] / 1000000, lon: value['crd']['x'] / 1000000);
      return new HafasStation(
          title: value['name'],
          id: int.parse(value['extId'] ?? 0),
          dist: location != null ? loc.getDistance(location).toInt() : 0,
          lid: value['lid'],
          location: loc);
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
  var RMV = new Hafas(config: new HafasConfig());
  var res = await RMV.departures(106907);
  print(res);
  var res = await RMV.findStationsByQuery('wiesbaden');
  print(res);
}
*/
