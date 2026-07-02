import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';

class DeviceUUID {
  static final _storage = FlutterSecureStorage();

  static Future<String> getDeviceUUID() async {
    String? uuid = await _storage.read(key: 'device_uuid');
    if (uuid != null) {
      return uuid; // Return the UUID if it already exists
    }

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      // For Android: Use ANDROID_ID hashed with SHA-1
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      String androidId = androidInfo.id; // ANDROID_ID
      uuid = _generateSHA1(androidId);
    } else if (Platform.isIOS) {
      // For iOS: Generate a unique string and store it in Keychain
      uuid = _generateUUID();
    } else {
      // Default fallback for other platforms
      uuid = _generateUUID();
    }

    // Save the generated UUID in secure storage
    await _storage.write(key: 'device_uuid', value: uuid);

    return uuid;
  }

  // Generate a SHA-1 hash
  static String _generateSHA1(String input) {
    final bytes = utf8.encode(input);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  // Generate a random UUID
  static String _generateUUID() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        '-' +
        _randomString(8);
  }

  // Helper function to generate a random string
  static String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(length, (index) => chars[DateTime.now().millisecondsSinceEpoch % chars.length]).join();
  }
}
