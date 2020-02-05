import 'dart:io';
import 'package:device_info/device_info.dart';

class DeviceInfo {
  static Future<Map<String, String>> getInfoAsync() async {
    String deviceName;
    String deviceVersion;
    String identifier;
    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        var build = await deviceInfoPlugin.androidInfo;
        deviceName = build.model;
        deviceVersion = build.version.toString();
        identifier = build.androidId; //UUID for Android
      } else if (Platform.isIOS) {
        var data = await deviceInfoPlugin.iosInfo;
        deviceName = data.name;
        deviceVersion = data.systemVersion;
        identifier = data.identifierForVendor; //UUID for iOS
      }
    } on Exception {
      // TODO: check if exception create a send report popup
      print('Failed to get platform version');
    }

    return {'name': deviceName, 'version': deviceVersion, 'id': identifier};
  }

  static Map<String, String> getInfo() {
    String deviceName;
    String deviceVersion;
    String identifier;
    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo deviceInfo; 
        deviceInfoPlugin.androidInfo.then((resultado) => print(resultado));
    // save()
    //     .then((success) => window.alert(success ? 'Saved' : 'Failed'))
    //     .catchError((e) => window.alert(e))
    //     .whenComplete(() { saveButton.enabled = true; });

        deviceName = deviceInfo.model;
        deviceVersion = deviceInfo.version.toString();
        identifier = deviceInfo.androidId; //UUID for Android
      } else if (Platform.isIOS) {
        IosDeviceInfo deviceInfo; 
        deviceInfoPlugin.iosInfo.then((resultado) => deviceInfo = resultado);
        deviceName = deviceInfo.name;
        deviceVersion = deviceInfo.systemVersion;
        identifier = deviceInfo.identifierForVendor; //UUID for iOS
      }
    } on Exception {
      // TODO: check if exception create a send report popup
      print('Failed to get platform version');
    }

    return {'name': deviceName, 'version': deviceVersion, 'id': identifier};
  }
}
