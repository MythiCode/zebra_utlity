import Flutter
import UIKit

public class SwiftZebrautilityPlugin: NSObject, FlutterPlugin {
    
    var printers = [Printer]()
    var binaryMessenger: FlutterBinaryMessenger?
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "zebrautility", binaryMessenger: registrar.messenger())

    let instance = SwiftZebrautilityPlugin()
    instance.binaryMessenger = registrar.messenger()
    registrar.addMethodCallDelegate(instance, channel: channel)
    
    
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

    if(call.method == "getInstance"){
        var printer = Printer.getInstance(binaryMessenger: self.binaryMessenger!)
        printers.append(printer)
        result(printer.toString())
        
        
    }
   
  }
}
