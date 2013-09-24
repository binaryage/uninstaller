#import <Cocoa/Cocoa.h>

typedef void (^ApplicationDidFinishLaunchingEvent)();
extern ApplicationDidFinishLaunchingEvent gAppDidFinishLaunchingEvent;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@end
