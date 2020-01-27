import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hello_world/textProcessor.dart';

void main() => runApp(new HelloWorldApp());

class HelloWorldApp extends StatefulWidget {
  State<StatefulWidget> createState() {
    return new HelloWorldState();
  }
}

class HelloWorldState extends State<HelloWorldApp> {
  String _chatText;
  Map<String, String> chatStatistics;

  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('Whatsapp Infographic'),
          actions: <Widget>[
            new IconButton(
              icon: new Icon(Icons.refresh),
              onPressed: () async {
                print('carregando...');
                final String path = 'assets/chat.txt';
                _chatText = await WIP.loadAsset(path, context);

                var _textProcessor = new TextProcessor(_chatText);
                chatStatistics = _textProcessor.generateStatistics();

                setState(() {});
              },
            )
          ],
        ),
        body: new Center(
            child: chatStatistics == null
                ? new Text('Lista vazia')
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
}

class WIP {
  /// Assumes the given path is a text-file-asset.
  static Future<String> loadAsset(String path, BuildContext context) async {
    return await DefaultAssetBundle.of(context).loadString(path);
  }
}
