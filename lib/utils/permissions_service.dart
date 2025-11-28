import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';
class PermissionsService {
  static Future<bool> requestLocationWhenInUse() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }
  static Future<bool> requestBackgroundLocation() async {
    if (Platform.isIOS) {
      final status = await Permission.locationAlways.request();
      return status.isGranted;
    }
    final fg = await Permission.locationWhenInUse.request();
    if (!fg.isGranted) return false;
    final bg = await Permission.locationAlways.request();
    if (bg.isGranted) return true;
    await openAppSettings();
    return false;
  }
  static Future<bool> requestNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }
  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
  static Future<bool> requestContactsRead() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }
} 
