import 'package:flutter/services.dart';
import 'package:zebrautility/ZebraPrinter.dart';

class Zebrautility {
  static const MethodChannel _channel = const MethodChannel('zebrautility');

  static Future<ZebraPrinter> getPrinterInstance(
      {Function(String name, String ipAddress, bool isWifi)? onPrinterFound,
      onPrinterDiscoveryDone,
      Function(int errorCode, String errorText)? onDiscoveryError,
      Function(String address, String status, String color)? onChangePrinterStatus,
      onPermissionDenied}) async {
    String id = await (_channel.invokeMethod("getInstance"));
    ZebraPrinter printer = ZebraPrinter(
        id, onPrinterFound, onPrinterDiscoveryDone, onDiscoveryError, onChangePrinterStatus,
        onPermissionDenied: onPermissionDenied);
    return printer;
  }
}
