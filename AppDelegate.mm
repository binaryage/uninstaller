#import "AppDelegate.h"

ApplicationDidFinishLaunchingEvent gAppDidFinishLaunchingEvent = NULL;

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  if (gAppDidFinishLaunchingEvent) {
    gAppDidFinishLaunchingEvent();
  }
}

@end
