# Flutter ZebraUtility



Zebra utility is a plugin for working easily with zebra printers in your flutter project.

  - Discovery bluetooth and wifi printers in android and bluetooth printers in iOS.
  - Connect and disconnect to printers
  - Set mediatype, darkness, calibrate command without writing any ZPL code for ZPL printers.
  - Rotate ZPL without changing your zpl.


# Installation

## Android

Add this code to android block in `build.gradle` (Module level).

```sh
android {
    packagingOptions {
        exclude 'META-INF/LICENSE.txt'
        exclude 'META-INF/NOTICE.txt'
        exclude 'META-INF/NOTICE'
        exclude 'META-INF/LICENSE'
        exclude 'META-INF/DEPENDENCIES'
    }
}
```
## iOS
Add `Supported external accessory protocols` in your `info.plist` and then add `com.zebra.rawport`to its.

# Example
## Getting Started
for initial new object of printer use this.
```sh
     ZebraPrinter zebraPrinter = await Zebrautility.getPrinterInstance(
  onPrinterFound, onPrinterDiscoveryDone, onChangePrinterStatus,
  onPermissionDenied: onPermissionDenied);
```

You must pass 3 functions `onPrinterFound`, `onPrinterDiscoveryDone` and `onChangePrinterStatus`.
`onPrinterFound` is called, when a new printer found. you can implement like this:
```sh
  Function onPrinterFound = (name, ipAddress) {
      print("PrinterFound :" + name + ipAddress);
    };
```
`onPrinterDiscoveryDone` is called, when discovery printers is done and finished. You can implement like this:
```sh
 Function onPrinterDiscoveryDone = () {
      print("Discovery Done");
    };
```
`onChangePrinterStatus` when the Status of printer changes, You can implement like this:
```sh
   Function onChangePrinterStatus = (status, color) {
      print("change printer status: " + status + color);
    };
```
`onPermissionDenied` is called, when android user deny location permission. You can implement like this:
```sh
  Function onPermissionDenied = () {
      print("Permission Deny.");
    };
```
## Methods
For start Discovery bluetooth and wifi printres, use this method:
```sh
  zebraPrinter.discoveryPrinters();
```
For connecting to printer, pass ipAddreess for wifi printer or macAddress for bluetooth printer to `connectToPrinter` method.
```sh
 zebraPrinter.connectToPrinter("192.168.47.50");
```
You can set media type between `Lable`, `Journal` and `BlackMark`. You can choose media type by `EnumMediaType`.
```sh
  zebraPrinter.setMediaType(EnumMediaType.BlackMark);
```
You may callibrate printer after set media type. You can use this method.
```sh
zebraPrinter.calibratePrinter();
```
You can set darkness. the valid darkness value are -99,-75,-50,-25,0,25,50,75,100,125,150,175,200.
```sh
  zebraPrinter.setDarkness(25);
```
For print ZPL, you pass ZPL to `print` method.
```sh
  zebraPrinter.print("Your ZPL");
```
For rotate your ZPL without changing your ZPL, you can use this method. You can call this again for normal printing.
```sh
  zebraPrinter.rotate();
```
For disconnect from printer, use `disconnect` method. For battery saver, disconnect from printer when you not need printer.
```sh
  zebraPrinter.disconnect();
```
