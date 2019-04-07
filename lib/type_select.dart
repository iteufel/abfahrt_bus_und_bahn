import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'hafas.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_picker/flutter_picker.dart';

class ChipButton extends StatefulWidget {
  ChipButton({Key key, this.text, this.enabled, this.change}) : super(key: key);
  final String text;
  final bool enabled;
  final ChipButtonChange change;

  @override
  ChipButtonState createState() => ChipButtonState();
}

typedef ChipButtonChange<T> = void Function(T bool);

class ChipButtonState extends State<ChipButton> {
  bool enabled = false;

  @override
  void initState() {
    super.initState();
    if (this.widget.enabled != null) {
      this.enabled = this.widget.enabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    /*TextStyle textStyle;
    Color bgColor = Colors.transparent;
    if (this.enabled) {
      textStyle =
          Theme.of(context).textTheme.button.copyWith(color: Colors.white);
      bgColor = Theme.of(context).accentColor;
    } else {
      textStyle = Theme.of(context)
          .textTheme
          .button
          .copyWith(color: Theme.of(context).accentColor);
    }
    return new GestureDetector(
      onTap: () {
        this.setState(() {
          this.enabled = !this.enabled;
        });
        if (this.widget.change != null) {
          this.widget.change(this.enabled);
        }
      },
      child: new AnimatedContainer(
        duration: const Duration(milliseconds: 175),
        child: new Text(
          this.widget.text,
          style: textStyle,
        ),
        decoration: new BoxDecoration(
          color: bgColor,
          border: new Border.all(
            width: 1,
            color: Theme.of(context).accentColor,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.fromLTRB(7, 9, 7, 9),
        margin: const EdgeInsets.all(7),
      ),
    );*/
    return new Padding(
      child: new OutlineButton(
        textColor: this.enabled ? Theme.of(context).accentColor : Colors.black,
        child: new Text(this.widget.text),
        onPressed: () {
          this.setState(() {
            this.enabled = !this.enabled;
          });
          if (this.widget.change != null) {
            this.widget.change(this.enabled);
          }
        },
      ),
      padding: const EdgeInsets.all(4),
    );
  }
}

typedef ChipMultiSelectTextExtractor<T> = String Function(T any);
typedef ChipMultiSelectChange<T> = void Function(List<dynamic>);

class ChipMultiSelect extends StatefulWidget {
  ChipMultiSelect({
    Key key,
    this.selected,
    this.items,
    this.textExtractor,
    this.change,
  }) : super(key: key);
  final List<dynamic> items;
  final List<dynamic> selected;
  final ChipMultiSelectTextExtractor textExtractor;
  final ChipMultiSelectChange change;

  @override
  ChipMultiSelectState createState() => ChipMultiSelectState();
}

class ChipMultiSelectState extends State<ChipMultiSelect> {
  List<dynamic> items = [];
  List<dynamic> selected = [];

  @override
  void initState() {
    super.initState();
    if (this.widget.selected != null) {
      this.selected = this.widget.selected;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = this.widget.items.map((e) {
      var text = this.widget.textExtractor(e);
      return new ChipButton(
        text: text,
        enabled: this.selected.contains(e),
        change: (selected) {
          if (selected) {
            this.selected.add(e);
          } else {
            this.selected.remove(e);
          }
          if (this.widget.change != null) {
            this.widget.change(this.selected);
          }
        },
      );
    }).toList();
    return new Expanded(
      child: new Container(
        child: new Wrap(
          children: children,
        ),
        padding: EdgeInsets.fromLTRB(8, 7, 10, 0),
      ),
    );
  }
}

typedef ProductSelectChange<T> = void Function(List<dynamic>, DateTime);

class ProductSelect extends StatefulWidget {
  ProductSelect({
    Key key,
    this.title,
    this.products,
    this.change,
    this.dateFilter,
    this.lines,
  }) : super(key: key);
  final String title;
  final List<HafasLine> lines;
  final List<HafasProduct> products;

  final ProductSelectChange change;
  final DateTime dateFilter;

  @override
  _ProductSelectState createState() => _ProductSelectState();
}

class _ProductSelectState extends State<ProductSelect> {
  List<dynamic> sitems = [];
  Widget pkw;
  Picker pk;
  DateTime dateFilter;
  Timer _debounce;
  @override
  void initState() {
    super.initState();
    if (this.widget.dateFilter != null) {
      dateFilter = this.widget.dateFilter;
    } else {
      dateFilter = DateTime.now();
    }

    this.pk = new Picker(
        height: 135,
        adapter: DateTimePickerAdapter(
            type: 4,
            months: [
              "Jan",
              "Feb",
              "März",
              "Apr",
              "Mai",
              "Jun",
              "Jul",
              "Aug",
              "Sept",
              "Okt",
              "Nov",
              "Dez"
            ],
            value: this.dateFilter),
        hideHeader: true,
        looping: true,
        onSelect: (
          Picker picker,
          int n,
          List value,
        ) {
          if (_debounce?.isActive ?? false) _debounce.cancel();
          _debounce = Timer(const Duration(milliseconds: 1000), () {
            this.dateFilter = (picker.adapter as DateTimePickerAdapter).value;
            this.widget.change(
                  this.widget.products,
                  this.dateFilter,
                );
          });
        });

    this.pkw = pk.makePicker();
  }

  @override
  Widget build(BuildContext context) {
    return new Material(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(25),
        topRight: Radius.circular(25),
      ),
      child: new Container(
        padding: EdgeInsets.only(bottom: 12),
        child: new SafeArea(
          child: new Column(
            children: <Widget>[
              new Container(
                child: new Row(
                  children: <Widget>[
                    new Container(
                      child: new Icon(
                        Icons.place,
                        size: 32,
                        color: Colors.white,
                      ),
                      margin: const EdgeInsets.only(
                        right: 15,
                      ),
                    ),
                    new Expanded(
                      child: new Text(
                        this.widget.title,
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
                child: new SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      new Row(
                        children: <Widget>[
                          new Expanded(
                            child: new Container(
                              margin: EdgeInsets.only(top: 1),
                              // color: Theme.of(context).accentColor,
                              child: new Text(
                                "Abfahrtszeit",
                                style: Theme.of(context)
                                    .textTheme
                                    .body1
                                    .copyWith(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 29),
                              ),
                              padding: EdgeInsets.only(
                                left: 15,
                                top: 8,
                                right: 15,
                                // bottom: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      new Row(
                        children: <Widget>[
                          new Expanded(
                            child: pkw,
                          ),
                        ],
                      ),
                      new Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          new OutlineButton(
                            textTheme: ButtonTextTheme.normal,
                            child: new Text("Jetzt"),
                            onPressed: () {
                              this.dateFilter = DateTime.now();
                              (this.pk.adapter as DateTimePickerAdapter).value =
                                  this.dateFilter;
                              (this.pk.adapter as DateTimePickerAdapter)
                                  .notifyDataChanged();
                            },
                          ),
                          new OutlineButton(
                            child: new Text("In 15 Min"),
                            onPressed: () {
                              this.dateFilter =
                                  DateTime.now().add(new Duration(minutes: 15));
                              (this.pk.adapter as DateTimePickerAdapter).value =
                                  this.dateFilter;
                              (this.pk.adapter as DateTimePickerAdapter)
                                  .notifyDataChanged();
                            },
                          ),
                          new OutlineButton(
                            child: new Text("In 30 Min"),
                            onPressed: () {
                              this.dateFilter =
                                  DateTime.now().add(new Duration(minutes: 30));
                              (this.pk.adapter as DateTimePickerAdapter).value =
                                  this.dateFilter;
                              (this.pk.adapter as DateTimePickerAdapter)
                                  .notifyDataChanged();
                            },
                          ),
                          new OutlineButton(
                            child: new Text("In 60 Min"),
                            onPressed: () {
                              this.dateFilter =
                                  DateTime.now().add(new Duration(minutes: 60));
                              (this.pk.adapter as DateTimePickerAdapter).value =
                                  this.dateFilter;
                              (this.pk.adapter as DateTimePickerAdapter)
                                  .notifyDataChanged();
                            },
                          )
                        ],
                      ),
                      new Row(
                        children: <Widget>[
                          new Expanded(
                            child: new Container(
                              // color: Theme.of(context).accentColor,
                              child: new Text(
                                "Produkte",
                                style: Theme.of(context)
                                    .textTheme
                                    .display1
                                    .copyWith(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 29),
                              ),
                              padding: EdgeInsets.only(
                                left: 15,
                                top: 8,
                                right: 15,
                                bottom: 0,
                              ),
                            ),
                          )
                        ],
                      ),
                      new Row(
                        children: <Widget>[
                          new ChipMultiSelect(
                            items: HafasProduct.PRODUCTS,
                            selected: this.widget.products,
                            textExtractor: (item) {
                              return item.name;
                            },
                            change: (items) {
                              this.widget.change(items, this.dateFilter);
                            },
                          ),
                        ],
                      ),
                      new Row(
                        children: <Widget>[
                          new Expanded(
                            child: new Container(
                              // color: Theme.of(context).accentColor,
                              child: new Text(
                                "Richtung",
                                style: Theme.of(context)
                                    .textTheme
                                    .display1
                                    .copyWith(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 29),
                              ),
                              padding: EdgeInsets.only(
                                left: 15,
                                top: 8,
                                right: 15,
                                bottom: 0,
                              ),
                            ),
                          )
                        ],
                      ),
                      new Row(
                        children: <Widget>[
                          new ChipMultiSelect(
                            items: HafasProduct.PRODUCTS,
                            selected: this.widget.lines,
                            textExtractor: (item) {
                              return (item as HafasLine).;
                            },
                            change: (items) {
                              this.widget.change(items, this.dateFilter);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
            mainAxisSize: MainAxisSize.min,
          ),
        ),
        constraints: const BoxConstraints(
            minWidth: double.infinity, minHeight: 425, maxHeight: 600),
      ),
      color: Colors.white,
      elevation: 10,
    );
  }
}
