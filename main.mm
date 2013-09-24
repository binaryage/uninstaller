// this is a minimalist uninstaller app
// by default it runs in GUI mode, but can be run without GUI from command-line with --headless param

#import "UninstallDialog.h"
#import "ScriptLauncher.h"
#import "AppDelegate.h"

// shifting our error codes to distinguish them from wrapped script codes
static int errorCode(int code) {
  const int baseErrorCode = 200;
  return baseErrorCode + code;
}

NSMutableAttributedString* colorizeString(NSString* string, NSColor* color) {
  return [[NSMutableAttributedString alloc] initWithString:string attributes:@{NSForegroundColorAttributeName:color}];
}

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    bool showVersion = argc==2 && strcmp(argv[1], "--version")==0;
    if (showVersion) {
      printf("%s\n", [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] UTF8String]);
      return 0;
    }
    
    bool headless = argc==2 && strcmp(argv[1], "--headless")==0;
    NSString* scriptPath = [[NSBundle mainBundle] pathForResource:@"uninstall" ofType:@"applescript"];
    if (!scriptPath) {
      NSLog(@"unable to locate uninstall script in resources");
      return errorCode(20);
    }
    NSString* cocoasudoPath = [[NSBundle mainBundle] pathForResource:@"cocoasudo" ofType:@""];
    if (!cocoasudoPath) {
      NSLog(@"unable to locate cocoasudo executable in resources");
      return errorCode(21);
    }
    
    if (headless) {
      // headless uninstallation for sysadmins and homebrew-cask scenario:
      // https://github.com/phinze/homebrew-cask/pull/395

      // first check if we run with admin priviledges
      int isntAdmin = checkAdminPrivileges();
      if (isntAdmin) {
        return errorCode(isntAdmin); // no admin priviledges or failed to check them
      }
      
      // ok, we are running with sudo => run the uninstaller script without GUI hooks
      return runUninstallerScript(scriptPath);
    } else {
      // codepath for GUI
      UninstallDialog* dialog = [[UninstallDialog alloc] init];
      
      // setup simple translation service
      auto translator = ^(NSString* original) {
        NSString* translation = NSLocalizedString(original, nil);
        if (![translation length]) {
          return original; // fallback to original if don't have translation at hand
        }
        return translation;
      };
      [dialog setTranslator:translator];
      
      // called when user clicks the "uninstall" button (could be multiple times when script fails)
      auto action = ^() {
        dispatch_async(dispatch_get_main_queue(), ^{ // all UI updates must be performed on the main thread
          [dialog clearConsole];
          [dialog printToConsole:colorizeString(translator(@"Running uninstall script:\n"), [NSColor blueColor])];
        });
        
        // called when uninstall script task finishes
        auto terminationHandler = ^(NSTask* task) {
          dispatch_async(dispatch_get_main_queue(), ^{ // all UI updates must be performed on the main thread
            int status = [task terminationStatus];
            if (status==0) {
              [dialog transitionIntoState:UNINSTALL_DIALOG_SUCCESS];
              [dialog presentSuccessMessage:colorizeString(translator(@"Uninstall script finished successfully.\n"), [NSColor blueColor])];
            } else {
              [dialog transitionIntoState:UNINSTALL_DIALOG_ERROR];
              [dialog showDetails];
              if (status==101) {
                [dialog presentErrorMessage:colorizeString(translator(@"Uninstall script needs admin rights.\n"), [NSColor redColor])];
              } else {
                NSString* failedMessage = [NSString stringWithFormat:translator(@"Uninstall script failed with error [%d].\n"), status];
                [dialog presentErrorMessage:colorizeString(failedMessage, [NSColor redColor])];
              }
            }
          });
        };
        
        // called right before launching the task
        auto prelaunchHandler = ^(NSTask* task) {
          [task setTerminationHandler:terminationHandler];
          [dialog transitionIntoState:UNINSTALL_DIALOG_PROGRESS];
          return true;
        };
        
        // called continuously with stream of task's stdout+stderr output
        auto outputHandler = ^(NSString* chunk) {
          dispatch_async(dispatch_get_main_queue(), ^{ // all UI updates must be performed on the main thread
            [dialog printToConsole:[[NSMutableAttributedString alloc] initWithString:chunk]];
          });
        };
        
        // run uninstaller with our GUI hooks
        NSString* overlayIconPath = [[NSBundle mainBundle] pathForResource:@"OverlayIcon" ofType:@"png"];
        NSString* prompt = translator(@"Uninstaller needs admin privileges to remove *APP* from your system.");
        runUninstallerScript(scriptPath, cocoasudoPath, overlayIconPath, prompt, outputHandler, prelaunchHandler);
      };

      [dialog setUnistallAction:action];
      
      // this is ugly, but quick solution without polluting AppDelegate with main logic
      gAppDidFinishLaunchingEvent = ^() {
        dispatch_async(dispatch_get_main_queue(), ^{ // all UI updates must be performed on the main thread
          [dialog show];
        });
      };
      
      // start GUI run loop
      return NSApplicationMain(argc, argv);
    }
  }
}