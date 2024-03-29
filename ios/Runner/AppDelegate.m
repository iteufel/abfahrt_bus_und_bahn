#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import "GoogleMaps/GoogleMaps.h"
@import AppCenter;
@import AppCenterAnalytics;
@import AppCenterCrashes;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  [GMSServices provideAPIKey:@"AIzaSyBlEiGcjk31hE5OBkLd8zlRGzgDgWoM3bE"];
  [MSAppCenter start:@"1cdd05fd-1d26-45d7-8d5e-7020938d3e7e" withServices:@[
  [MSAnalytics class],
  [MSCrashes class]
]];
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
