import 'dart:core';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class TextProcessor {
  String _chat;
  ChatPattern _pattern;

  /// Date format reference: https://pub.dev/documentation/intl/latest/intl/DateFormat-class.html
  final _patternList = [
    ChatPattern('android_BR-24h', r'\d{2}/\d{2}/\d{2} \d{2}:\d{2} - ', 'd/M/y H:m - '), // '31/01/99 01:01 - '
    ChatPattern(
        'android_BR-da', r'\d{2}/\d{2}/\d{4} \d{1,2}:\d{2} \w+?.*? - ', 'd/M/y h:m a - '), // '31/01/2099 1:01 da noite - '
    ChatPattern('android_US-24h', r'\d{1,2}/\d{1,2}/\d{2}, \d{2}:\d{2} - ', 'M/d/y, H:m - '), // '1/31/99, 01:01 - '
    ChatPattern(
        'android_US-AM/PM', r'\d{1,2}/\d{1,2}/\d{2}, \d{1,2}:\d{2} (AM|PM) - ', 'M/d/y, h:m a - '), // '1/31/99, 1:01 AM - '
    ChatPattern('ios_BR-24h', r'\[\d{2}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}\] ', '[d/M/y H:m:s] '), // '[31/01/99 01:01:01] '
  ];

  TextProcessor(String chatText) {
    _chat = chatText;
  }

  Map<String, String> generateStatistics() {
    var result = Map<String, String>();

    // define chat pattern
    if ((_chat ?? '').length < 50) throw new Exception('Erro ao tentar analisar o chat');
    var chatStart = _chat.substring(0, 50);
    _pattern = _patternList.singleWhere((pattern) => new RegExp(pattern.regex).hasMatch(chatStart),
        orElse: () => throw new UnimplementedError('pattern "${chatStart.substring(0, 50)}" não reconhecido'));

    // remove whatsapp tags <...>
    _chat = _chat.replaceAll(RegExp(r'(\<Media omitted\>|\<Arquivo de mídia oculto\>)'), '');

    // fix this shitty date format
    if (_pattern.id == 'android_BR-da') {
      _chat = _chat.replaceAll(RegExp(r'(meia-noite|da madrugada|da manhã)'), 'AM');
      _chat = _chat.replaceAll(RegExp(r'(meio-dia|da tarde|da noite)'), 'PM');
    }
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
    // var msgPerWeekDay = Map<String, int>();
    var msgPerMonth = Map<String, int>();
    var totalMsgCount = 0;
    var totalWordCount = 0;
    var totalCharCount = 0;

    String localeName = "pt_BR"; // "en_US" etc.
    initializeDateFormatting(localeName);

    DateFormat weedDayFormatter = DateFormat(DateFormat.WEEKDAY, localeName);
    var msgPerWeekDay = Map<String, int>.fromIterable([
      DateTime(2000, 1, 3), // Monday
      DateTime(2000, 1, 4), // Tuesday
      DateTime(2000, 1, 5), // Wednesday
      DateTime(2000, 1, 6), // Thrusday
      DateTime(2000, 1, 7), // Friday
      DateTime(2000, 1, 8), // Saturday
      DateTime(2000, 1, 9), // Sunday
    ], key: (k) => weedDayFormatter.format(k), value: (v) => 0);

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

      var weekDay = weedDayFormatter.format(dateTime);
      if (!msgPerWeekDay.containsKey(weekDay)) msgPerWeekDay[weekDay] = 0;
      msgPerWeekDay[weekDay]++;

      var yearMonth = DateFormat('MM/yy').format(dateTime);
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
      result['Mensagens de $user'] = '${users[user].msgCount} (${(users[user].msgCount * 100 / msgList.length).round()}%)';
    }

    for (var user in users.keys) {
      result['Palavras $user'] = '${users[user].wordCount} (${(users[user].wordCount * 100 / totalWordCount).round()}%)';
    }

    // TODO: sort ascending (pre populate msgPerWeekDay?)
    result['Mensagens por hora'] = msgPerHour.entries.fold('', (join, item) => join + '${item.key}h: ${item.value}\n');
    result['Mensagens por dia'] = msgPerWeekDay.entries.fold('', (join, item) => join + '${item.key}: ${item.value}\n');
    // TODO: sort months (swap year and month while sorting?)
    result['Mensagens por mês'] = msgPerMonth.entries.fold('', (join, item) => join + '${item.key}: ${item.value}\n');

    result['Palavras mais faladas'] =
        wordCount.topValues(15).entries.fold('', (join, item) => join + '${item.key}: ${item.value}\n');

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
      'mas',
      'mais',
      'aqui',
      'ainda',
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
    var result = new Map<K, V>();

    if (count > 0) mapValues = mapValues.take(count).toList();

    this.removeWhere((k, v) => !mapValues.contains(v));

    for (var value in mapValues) {
      var key = this.keys.firstWhere((k) => this[k] == value);
      result[key] = this.remove(key);
    }

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
