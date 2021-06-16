import 'package:flutter/services.dart';

enum EnumMediaType { Label, BlackMark, Journal }
enum Command { calibrate, mediaType, darkness }

class ZebraPrinter {
  late MethodChannel channel;

  Function? onPrinterFound;
  Function? onPrinterDiscoveryDone;
  Function? onDiscoveryError;
  Function? onChangePrinterStatus;
  Function? onPermissionDenied;

  bool isRotated = false;

  ZebraPrinter(
      String id, this.onPrinterFound, this.onPrinterDiscoveryDone, this.onDiscoveryError, this.onChangePrinterStatus,
      {this.onPermissionDenied}) {
    channel = MethodChannel('ZebraPrinterObject' + id);
    channel.setMethodCallHandler(nativeMethodCallHandler);
  }

  discoveryPrinters() {
    channel.invokeMethod("checkPermission").then((isGrantPermission) {
      if (isGrantPermission)
        channel.invokeMethod("discoverPrinters");
      else {
        if (onPermissionDenied != null) onPermissionDenied!();
      }
    });
  }

  _setSettings(Command setting, dynamic values) {
    String command = "";
    switch (setting) {
      case Command.mediaType:
        if (values == EnumMediaType.BlackMark) {
          command = '''
          ! U1 setvar "media.type" "label"
          ! U1 setvar "media.sense_mode" "bar"
          ''';
        } else if (values == EnumMediaType.Journal) {
          command = '''
          ! U1 setvar "media.type" "journal"
          ''';
        } else if (values == EnumMediaType.Label) {
          command = '''
          ! U1 setvar "media.type" "label"
           ! U1 setvar "media.sense_mode" "gap"
          ''';
        }

        break;
      case Command.calibrate:
        command = '''~jc^xa^jus^xz''';
        break;
      case Command.darkness:
        command = '''! U1 setvar "print.tone" "$values"''';
        break;
    }

    if (setting == Command.calibrate) {
      command = '''~jc^xa^jus^xz''';
    }

    try {
      channel.invokeMethod("setSettings", {"SettingCommand": command});
    } on PlatformException catch (e) {}
  }

  setDarkness(int darkness) {
    _setSettings(Command.darkness, darkness.toString());
  }

  setMediaType(EnumMediaType mediaType) {
    _setSettings(Command.mediaType, mediaType);
  }

  connectToPrinter(String address) {
    channel.invokeMethod("connectToPrinter", {"Address": address});
  }

  connectToGenericPrinter(String address) {
    channel.invokeMethod("connectToGenericPrinter", {"Address": address});
  }

  print(String data) {
    if (!data.contains("^PON")) data = data.replaceAll("^XA", "^XA^PON");

    if (isRotated) {
      data = data.replaceAll("^PON", "^POI");
    }
    channel.invokeMethod("print", {"Data": data});
  }

  disconnect() {
    channel.invokeMethod("disconnect", null);
  }

  calibratePrinter() {
    _setSettings(Command.calibrate, null);
  }

  isPrinterConnected() {
    channel.invokeMethod("isPrinterConnected");
  }

  rotate() {
    this.isRotated = !this.isRotated;
  }

  Future<dynamic> nativeMethodCallHandler(MethodCall methodCall) async {
    if (methodCall.method == "printerFound") {
      onPrinterFound!(methodCall.arguments["Name"], methodCall.arguments["Address"],
          methodCall.arguments["IsWifi"].toString() == "true" ? true : false);
    } else if (methodCall.method == "changePrinterStatus") {
      onChangePrinterStatus!(
          methodCall.arguments["Address"], methodCall.arguments["Status"], methodCall.arguments["Color"]);
    } else if (methodCall.method == "onPrinterDiscoveryDone") {
      onPrinterDiscoveryDone!();
    } else if (methodCall.method == "onDiscoveryError") {
      onDiscoveryError!(methodCall.arguments["ErrorCode"], methodCall.arguments["ErrorText"]);
    }
    return null;
  }

  String? id;
}
