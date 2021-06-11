#import "ZebrautilityPlugin.h"
#import "TcpPrinterConnection.h"
#if __has_include(<zebrautility/zebrautility-Swift.h>)
#import <zebrautility/zebrautility-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "zebrautility-Swift.h"
#endif

@implementation ZebrautilityPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
//    TcpPrinterConnection *con =  [TcpPrinterConnection init];
  [SwiftZebrautilityPlugin registerWithRegistrar:registrar];
}
@end
