import 'dart:core';

// TODO: Extension methods weren't supported until version 2.6.0, but this code is required to be able to run on earlier versions.
extension MyMap<K, V> on Map<K, V> {
  Map<K, V> topValues([int count = 0]) {
    List<V> velues = this.values.toList(growable: false);
    if (V == int) {
      velues.sort((k1, k2) => (k2 as int) - (k1 as int));
    } else if (V == String) {
      velues.sort((k1, k2) => (k2 as String).length - (k1 as String).length);
    }
    var result = new Map<K, V>();

    if (count > 0) velues = velues.take(count).toList();

    this.removeWhere((k, v) => !velues.contains(v));

    velues.forEach((value) {
      var key = this.keys.firstWhere((k) => this[k] == value);
      result[key] = this.remove(key);
    });

    return result;
  }

  Map<K, V> sortAscending() {
    List<K> keys = this.keys.toList(growable: false);
    if (K == int) {
      keys.sort((k1, k2) => (k1 as int) - (k2 as int));
    } else if (K == String) {
      keys.sort((k1, k2) => (k1 as String).length - (k2 as String).length);
    }
    var result = new Map<K, V>();

    keys.forEach((key) => result[key] = this[key]);

    return result;
  }
}