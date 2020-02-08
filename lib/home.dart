// import 'dart:async';
// import 'dart:core';

// import 'package:flutter/material.dart';

// class Home extends StatelessWidget {
//   final bool showPerformanceOverlay;
//   final ValueChanged<bool> onShowPerformanceOverlayChanged;

//   Home({Key key, this.showPerformanceOverlay, this.onShowPerformanceOverlayChanged}) : super(key: key) {
//     assert(onShowPerformanceOverlayChanged != null);
//   }

//   @override
//   Widget build(BuildContext context) {
//     var galleries = <Widget>[];

//     return new Scaffold(
//       appBar: new AppBar(
//         title: new Text('Whatsapp Infographic'), centerTitle: true,
//         // TODO: comment before releasing
//         actions: <Widget>[
//           new IconButton(
//             icon: new Icon(Icons.refresh),
//             onPressed: () async {
//               final String path = 'assets/chat.txt';
//               var asd = await WIP.loadAsset(path, context);
//               var _textProcessor = new TextProcessor(asd);
//               chatStatistics = _textProcessor.generateStatistics();
//               onShowPerformanceOverlayChanged(!showPerformanceOverlay);
//               // setState(() {});
//             },
//           )
//         ],
//         // comment before releasing
//       ),
//       body: new Center(
//           child: chatStatistics == null
//               ? new Text('Para gerar os dados é preciso exportar um chat do WhatsApp')
//               : new ListView.builder(
//                   itemCount: chatStatistics.length,
//                   itemBuilder: (context, index) {
//                     var key = chatStatistics.keys.elementAt(index);
//                     return new Column(
//                       children: <Widget>[
//                         new ListTile(
//                           title: new Text("$key"),
//                           subtitle: new Text("${chatStatistics[key]}"),
//                         ),
//                         new Divider(
//                           height: 2.0,
//                         ),
//                       ],
//                     );
//                   },
//                 )),
//     );
//   }
// }
