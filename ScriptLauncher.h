typedef void (^TaskPresentationHandler)(NSString* chunk);
typedef bool (^TaskPreLaunchHandler)(NSTask* task);

int checkAdminPrivileges(AuthorizationFlags flags = kAuthorizationFlagDefaults);
int runUninstallerScript(NSString* scriptPath,
                         NSString* cocoasudoPath = nil,
                         NSString* overlayIconPath = nil,
                         NSString* prompt = nil,
                         TaskPresentationHandler presentationHandler = nil,
                         TaskPreLaunchHandler prelaunchHandler = nil);
