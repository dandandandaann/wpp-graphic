import 'dart:core';

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

    var format = new DateFormat(_pattern.dateTime);
    var msgList = List<Msg>();
    var users = Map<String, User>();
    var wordCount = Map<String, int>();
    var msgPerHour = Map<int, int>();
    var msgPerWeekDay = Map<String, int>();
    var msgPerMonth = Map<String, int>();
    var totalMsgCount = 0;
    var totalWordCount = 0;
    var totalCharCount = 0;

    // loop through messages
    for (var i = 0; i < dateAndTime.length; i++) {
      // ignore system messages
      if (!userAndText[i].contains(':')) continue;

      var msgText = userAndText[i].split(':');
      var user = msgText.removeAt(0).trim();
      var text = msgText.join(':').trim();
      var dateTime = format.parse(dateAndTime[i]);

      if (!users.containsKey(user)) users[user] = new User(user);

      totalCharCount += text.length;

      // word count
      var wordList = text.split(' ');
      totalWordCount += wordList.length;
      users[user].wordCount += wordList.length;
      for (var word in wordList) {
        word = word.toLowerCase();
        if (_shouldCount(word)) {
          if (!wordCount.containsKey(word)) wordCount[word] = 0;
          wordCount[word]++;
        }
      }

      // message count
      totalMsgCount++;
      users[user].msgCount++;

      if (!msgPerHour.containsKey(dateTime.hour)) msgPerHour[dateTime.hour] = 0;
      msgPerHour[dateTime.hour]++;

      var weekDay = DateFormat('EEEE').format(dateTime);
      if (!msgPerWeekDay.containsKey(weekDay)) msgPerWeekDay[weekDay] = 0;
      msgPerWeekDay[weekDay]++;

      var yearMonth = DateFormat('MM-yy').format(dateTime);
      if (!msgPerMonth.containsKey(yearMonth)) msgPerMonth[yearMonth] = 0;
      msgPerMonth[yearMonth]++;

      msgList.add(Msg(dateTime, user, text));
    }

    // populate result
    result['Usuários'] = users.keys.join(', ');
    result['Total de mensagens'] = totalMsgCount.toString();
    result['Total de palavras'] = totalWordCount.toString();
    result['Total de caracteres'] = totalCharCount.toString();

    for (var user in users.keys) {
      result['Mensagens $user'] = '${users[user].msgCount} (${(users[user].msgCount * 100 / msgList.length).round()}%)';
    }

    for (var user in users.keys) {
      result['Palavras $user'] = users[user].wordCount.toString();
    }

    // TODO: sort ascending (pre populate msgPerWeekDay?)
    result['Mensagens por hora'] = msgPerHour.toString();
    // TODO: sort days (pre populate msgPerWeekDay?)
    result['Mensagens por dia'] = msgPerWeekDay.toString();
    // TODO: sort months (swap year and month while sorting?)
    result['Mensagens por mês'] = msgPerMonth.toString();

    result['Palavras mais faladas'] = wordCount.topValues(15).toString();

    return result;
  }

  bool _shouldCount(String word) {
    var wordsNotCounted = [
      'a',
      'o',
      'e',
      'é',
      'que',
      'isso',
      'isto',
      'pra',
      'ser' 'tem',
      'por',
      'vou',
      'com',
      'vai',
      'mesmo',
      'sei',
      'então',
      'como',
      'meu',
      'foi',
      'nao',
      'para',
      'esse',
      'essa',
      'este',
      'esta',
      'tava',
      'um',
      'uma',
      'de',
      'ser',
      'tem',
    ];
    if (word.length < 3) return false;
    if (wordsNotCounted.contains(word)) return false;

    return true;
  }
}

// TODO: Extension methods weren't supported until version 2.6.0, but this code is required to be able to run on earlier versions.
extension MyMap<K, V> on Map<K, V> {
  Map<K, V> topValues([int count = 0]) {
    List<V> mapValues = this.values.toList(growable: false);
    if (V == int) {
      mapValues.sort((k1, k2) => (k2 as int) - (k1 as int));
    } else if (V == String) {
      mapValues.sort((k1, k2) => (k2 as String).length - (k1 as String).length);
    }
    // TODO: mapReversed might not work well with word with duplicate count
    var mapReversed = this.map((k, v) => MapEntry(v, k));
    var result = new Map<K, V>();

    if (count > 0) mapValues = mapValues.take(count).toList();

    mapValues.forEach((k1) {
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

class User {
  String name;
  int wordCount;
  int msgCount;

  User(String name) {
    this.name = name;
    this.wordCount = 0;
    this.msgCount = 0;
  }
}
