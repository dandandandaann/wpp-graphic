import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hello_world/rollbar/flutter_rollbar.dart';
import 'package:hello_world/rollbar/rollbar_types.dart';
// import 'package:flutter_rollbar/flutter_rollbar.dart';
import 'package:hello_world/textProcessor.dart';

// import 'deviceInfo.dart';

void main() => runZoned<Future<void>>(() async {
      runApp(new HelloWorldApp());
    }, onError: (error, stackTrace) async {
      Rollbar().publishReport(message: '$error.\n$stackTrace');
      // TODO: show dialog when errors are caught
      // _reportError(error, stackTrace);
    });

class HelloWorldApp extends StatefulWidget {
  State<StatefulWidget> createState() {
    return new HelloWorldState();
  }
}

class HelloWorldState extends State<HelloWorldApp> {
  Map<String, String> chatStatistics;

  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('Whatsapp Infographic'), centerTitle: true,
          // TODO: comment before releasing
          actions: <Widget>[
            new IconButton(
              icon: new Icon(Icons.refresh),
              onPressed: () async {
                final String path = 'assets/chat.txt';
                var asd = await WIP.loadAsset(path, context);
                var _textProcessor = new TextProcessor(asd);
                chatStatistics = _textProcessor.generateStatistics();
                setState(() {});
              },
            )
          ],
          // comment before releasing
        ),
        body: new Center(
            child: chatStatistics == null
                ? new Text('Para gerar os dados é preciso exportar um chat do WhatsApp')
                : new ListView.builder(
                    itemCount: chatStatistics.length,
                    itemBuilder: (context, index) {
                      var key = chatStatistics.keys.elementAt(index);
                      return new Column(
                        children: <Widget>[
                          new ListTile(
                            title: new Text("$key"),
                            subtitle: new Text("${chatStatistics[key]}"),
                          ),
                          new Divider(
                            height: 2.0,
                          ),
                        ],
                      );
                    },
                  )),
      ),
    );
  }

  static const platform = const MethodChannel('app.channel.shared.data');
  Map<dynamic, dynamic> sharedData = Map();

  @override
  void initState() {
    // DeviceInfo.getInfoAsync().then((deviceInfo) => new Rollbar()
    //   ..accessToken = '831f70defad74c3092a50b2e0012102e'
    //   ..environment = 'development'
    //   ..person = new RollbarPerson(id: deviceInfo['id']));

    Rollbar()
      ..accessToken = '831f70defad74c3092a50b2e0012102e'
      ..environment = 'development'
      ..person = new RollbarPerson(id: 'anon');
    super.initState();
    _init();
  }

  _init() async {
    // Case 1: App is already running in background:
    // Listen to lifecycle changes to subsequently call Java MethodHandler to check for shared data
    SystemChannels.lifecycle.setMessageHandler((msg) {
      if (msg.contains('resumed')) {
        _getSharedData().then((data) {
          if (data.containsKey('text')) {
            setState(() => chatStatistics = TextProcessor(data['text']).generateStatistics());
          }
        });
      }
      return;
    });

    // Case 2: App is started by the intent:
    // Call Java MethodHandler on application start up to check for shared data
    var sharedData = await _getSharedData();
    if (sharedData.containsKey('text')) {
      setState(() => chatStatistics = TextProcessor(sharedData['text']).generateStatistics());
    }
  }

  Future<Map> _getSharedData() async => await platform.invokeMethod('getSharedData');
}

class WIP {
  /// Assumes the given path is a text-file-asset.
  static Future<String> loadAsset(String path, BuildContext context) async {
    return await DefaultAssetBundle.of(context).loadString(path);
  }
}
