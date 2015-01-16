#import <Security/Security.h>

#import "ScriptLauncher.h"

int runUninstallerScript(NSString* scriptPath,
                         NSString* cocoasudoPath,
                         NSString* overlayIconPath,
                         NSString* prompt,
                         TaskPresentationHandler presentationHandler,
                         TaskPreLaunchHandler prelaunchHandler) {
  NSTask* task = [[NSTask alloc] init];

  if (presentationHandler) {
    NSPipe* pipe = [NSPipe pipe];
    NSFileHandle* readStdOutHandle = [pipe fileHandleForReading];

    [readStdOutHandle setReadabilityHandler:^(NSFileHandle* file) {
      NSData* data = [file availableData];
      NSString* text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      presentationHandler(text);
    }];

    // redirect both stdout and stderr into our pipe
    [task setStandardOutput:pipe];
    [task setStandardError:pipe];
  }
  [task setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
  if (!cocoasudoPath) {
    // in non-interactive mode run the applescript directly using osascript
    [task setLaunchPath:@"/usr/bin/osascript"];
    [task setArguments:@[ scriptPath ]];
  } else {
    // in interactive mode apply cocoasudo wrapper

    // copy icon into /tmp to be sure it will get displayed (the security dialog is picky about correct rights)
    NSString* tempIconPath = @"/tmp/totalfinder-uninstaller-overlay-icon.png";
    if (overlayIconPath) {
      NSFileManager* fileManager = [[NSFileManager alloc] init];
      [fileManager copyItemAtPath:overlayIconPath toPath:tempIconPath error:nil];
      [fileManager setAttributes:@{ NSFilePosixPermissions : @0644 } ofItemAtPath:tempIconPath error:nil];
    }

    // set task arguments
    [task setLaunchPath:cocoasudoPath];
    [task setArguments:@[
      [NSString stringWithFormat:@"--prompt=%@", prompt],
      [NSString stringWithFormat:@"--icon=%@", tempIconPath],
      @"/usr/bin/osascript",
      scriptPath
    ]];
  }
  if (prelaunchHandler) {
    if (!prelaunchHandler(task)) {
      return 0;  // cancelled
    }
  }

  [task launch];
  [task waitUntilExit];
  return [task terminationStatus];
}

int checkAdminPrivileges(AuthorizationFlags flags) {
  int res = 0;
  OSStatus status;
  AuthorizationRef authorizationRef;

  status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizationRef);
  if (status != errAuthorizationSuccess) {
    NSLog(@"unexpected error: AuthorizationCreate returned with status %d", status);
    return 2;
  }

  // kAuthorizationRightExecute == "system.privilege.admin" == running with sudo
  AuthorizationItem right = {kAuthorizationRightExecute, 0, NULL, 0};
  AuthorizationRights rights = {1, &right};

  // call AuthorizationCopyRights to determine current rights
  status = AuthorizationCopyRights(authorizationRef, &rights, NULL, flags, NULL);
  if (status != errAuthorizationSuccess) {
    if (status == errAuthorizationDenied) {
      NSLog(@"you must run this command with admin priviledges: sudo Uninstaller --headless");
      res = 1;
      goto bailout;
    } else {
      NSLog(@"unexpected error: AuthorizationCopyRights returned with status %d", status);
      res = 3;
      goto bailout;
    }
  }

bailout:
  status = AuthorizationFree(authorizationRef, kAuthorizationFlagDefaults);
  if (status != errAuthorizationSuccess) {
    NSLog(@"unexpected error: AuthorizationFree returned with status %d", status);
    res = 4;
  }

  return res;
}
