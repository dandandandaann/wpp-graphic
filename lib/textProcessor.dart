import 'package:intl/intl.dart';

class TextProcessor {
  String _chat;
  ChatPattern _pattern;

  /// Date format reference: https://pub.dev/documentation/intl/latest/intl/DateFormat-class.html
  final _patternList = [
    ChatPattern('android_US', r'\d{1,2}/\d{1,2}/\d{2}, \d{2}:\d{2} - ', 'M/d/y, H:m - '), // '9/31/99, 01:01 - '
    ChatPattern('android_BR', r'\d{2}/\d{2}/\d{2} \d{2}:\d{2} - ', 'd/m/y H:M - '), // '31/01/99 01:01 - '
    ChatPattern('ios_BR', r'\[\d{2}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}\] ', '[d/m/y H:M:s] '), // '[01/08/19 10:37:57] '
  ];

  TextProcessor(String chatText) {
    _chat = chatText;
  }

  Map<String, String> generateStatistics() {
    var result = Map<String, String>();

    // define chat pattern
    _pattern = _patternList.singleWhere((pattern) => new RegExp(pattern.regex).hasMatch(_chat),
        orElse: () => throw new UnimplementedError('pattern do chat não encontrado'));

    // remove whatsapp tags <...>
    _chat = _chat.replaceAll('<Media omitted>', '');
    _chat = _chat.replaceAll('<Arquivo de mídia oculto>', '');

    // separate timestamp and text
    var dateAndTime = RegExp(_pattern.regex).allMatches(_chat).map((match) => match.group(0)).toList();
    var userAndText = _chat.split(RegExp(_pattern.regex, dotAll: true));
    userAndText.removeAt(0); // first position is empty

    // both should have same length
    if (dateAndTime.length != userAndText.length) throw new Exception('quantidade de datas e mensagens estão diferentes');

    var msgList = List<Msg>();
    var users = Set();
    var wordCount = Map<String, int>();

    for (var i = 0; i < dateAndTime.length; i++) {
      // ignore system messages
      if (!userAndText[i].contains(':')) continue;

      var msgText = userAndText[i].split(':');
      var user = msgText.removeAt(0).trim();
      var text = msgText.join(':').trim();
      users.add(user);

      DateFormat format = new DateFormat(_pattern.dateTime);
      var dateTime = format.parse(dateAndTime[i]);

      msgList.add(Msg(dateTime, user, text));

      for (var word in text.split(' ')) {
        word = word.toLowerCase();
        if (_shouldCount(word)) {
          if (!wordCount.containsKey(word)) wordCount[word] = 0;
          wordCount[word]++;
        }
      }
    }

    // populate result
    result['Usuários'] = users.join(', ');
    result['Total de mensagens'] = msgList.length.toString();

    wordCount.topValues(10).forEach((word, count) {
      result[word] = count.toString();
    });

    return result;
  }

  bool _shouldCount(String word) {
    var wordsNotCounted = ['que', 'pra', 'para', 'uma', 'vai', 'com', 'ser', 'por'];

    if (word.length < 3) return false;
    if (wordsNotCounted.contains(word)) return false;

    return true;
  }
}

// TODO: Extension methods weren't supported until version 2.6.0, but this code is required to be able to run on earlier versions.
extension MyMap<K, V> on Map<K, V> {
  Map<K, V> topValues(int count) {
    List<V> mapValues = this.values.toList(growable: false);
    if (V == int) {
      mapValues.sort((k1, k2) => (k2 as int) - (k1 as int));
    } else if (V == String) {
      mapValues.sort((k1, k2) => (k2 as String).length - (k1 as String).length);
    }
    // TODO: mapReversed might not work with word with duplicate count
    var mapReversed = this.map((k, v) => MapEntry(v, k));
    var result = new Map<K, V>();

    mapValues.take(count).forEach((k1) {
      result[mapReversed[k1]] = k1;
    });
    return result;
  }
}

class Msg {
  DateTime dateTime;
  String user;
  String text;
  Msg(DateTime dateTime, String user, String text) {
    this.dateTime = dateTime;
    this.user = user;
    this.text = text;
  }
}

class ChatPattern {
  String id;
  String regex;
  String dateTime;
  ChatPattern(String id, String regex, String dateTime) {
    this.id = id;
    this.regex = regex;
    this.dateTime = dateTime;
  }
}
