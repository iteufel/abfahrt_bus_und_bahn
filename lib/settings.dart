import 'package:abfahrt_gui/style.dart';
import 'package:flutter/material.dart';
import 'hafas.dart';
import 'package:flutter/cupertino.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key, this.title, this.station}) : super(key: key);
  final String title;
  final HafasStation station;

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (AbfahrtStyle.forceIosStyle) {
      return CupertinoPageScaffold(
        navigationBar: new CupertinoNavigationBar(
          middle: new Text('Einstellungen'),
        ),
        child: new Center(
          child: new Text('TODO'),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text('Einstellungen'),
        ),
        body: new Center(
          child: new MaterialButton(
            child: new Text('Show Intro'),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('intro');
            },
          ),
        ),
      );
    }
  }
}
