#import "IrisCameraPlugin.h"
#if __has_include(<iris_camera/iris_camera-Swift.h>)
#import <iris_camera/iris_camera-Swift.h>
#else
#import "iris_camera-Swift.h"
#endif

@implementation IrisCameraPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftIrisCameraPlugin registerWithRegistrar:registrar];
}
@end
