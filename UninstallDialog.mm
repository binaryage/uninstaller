#import "UninstallDialog.h"

@implementation UninstallDialog

-(UninstallDialog*)init {
  if (self = [super init]) {
    state_ = UNINSTALL_DIALOG_UNDEFINED;
    consoleFont_ = [NSFont fontWithName:@"Courier New" size:10];
    [self setTranslator:nil];
  }
  return self;
}

- (void)awakeFromNib
{
	[showDetails_ setHidden:YES];
	[detailsLabel_ setHidden:YES];
}

-(void)setTranslator:(StringTranslationHandler)translator {
  translator_ = translator;
  if (!translator_) {
    translator_ = ^(NSString* original) { // default pass through translator
      return original;
    };
  }
}

-(void)setUnistallAction:(UninstallActionHandler)handler {
  uninstallAction_ = handler;
}

-(void)show {

  NSArray* objects;
  BOOL nibOk = [[NSBundle mainBundle] loadNibNamed:@"UninstallDialog" owner:self topLevelObjects:&objects];
  if (!nibOk) {
    NSLog(@"unexpected error: loadNibNamed UninstallDialog failed");
    return;
  }

  [self setup];
  
  [NSApp activateIgnoringOtherApps:YES];

  [window_ setDelegate:self];
  [window_ center];
  [window_ makeKeyAndOrderFront:self];
}

-(void)setup {
  [self toggleDetails:showDetails_];
  
  // translate buttons
  [quitButton_ setTitle:translator_(@"Quit")];
  [uninstallButton_ setTitle:translator_(@"Uninstall")];
  [cancelButton_ setTitle:translator_(@"Cancel")];

  // translate static texts
  [detailsLabel_ setStringValue:translator_(@"Details")];
  [showDetails_ setToolTip:translator_(@"Show detailed transcript")];
  [detailsLabel_ setToolTip:translator_(@"Show detailed transcript")];

  [self transitionIntoState:UNINSTALL_DIALOG_NORMAL];
}

-(bool)transitionIntoState:(TUninstallDialogState)state {
  if (state_ == state) {
    return false;
  }
  state_ = state;
  if (state == UNINSTALL_DIALOG_NORMAL) {
    [self showCancelAndUninstallButtons:self];
    [dialogTitle_ setStringValue:translator_(@"You are about uninstall *APP*")];
    [dialogText_ setStringValue:translator_(@"This program will uninstall all *APP* components from this computer.")];
  } else if (state == UNINSTALL_DIALOG_PROGRESS) {
    [self showProgressIndicator:self];
  } else if (state == UNINSTALL_DIALOG_SUCCESS) {
    [self showQuitButton:self];
    [dialogTitle_ setStringValue:translator_(@"*APP* has been uninstalled")];
    [dialogText_ setStringValue:translator_(@"Have a nice day.")];
  } else if (state == UNINSTALL_DIALOG_ERROR) {
    [self showCancelAndUninstallButtons:self];
    [dialogTitle_ setStringValue:translator_(@"*APP* uninstallation failed")];
    [dialogText_ setStringValue:translator_(@"The uninstall script encountered problems. Please see the details. Please report bugs to support@binaryage.com.")];
  }
  [window_ display];
  return true;
}

-(IBAction)showCancelAndUninstallButtons:(id)sender {
  [quitButton_ setHidden:YES];
  [progressIndicator_ setHidden:YES];
  [cancelButton_ setHidden:NO];
  [uninstallButton_ setHidden:NO];
}

-(IBAction)showQuitButton:(id)sender {
  [progressIndicator_ setHidden:YES];
  [cancelButton_ setHidden:YES];
  [uninstallButton_ setHidden:YES];
  [quitButton_ setHidden:NO];
  [progressIndicator_ stopAnimation:self];
}

-(IBAction)showProgressIndicator:(id)sender {
  [quitButton_ setHidden:YES];
  [cancelButton_ setHidden:YES];
  [uninstallButton_ setHidden:YES];
  [progressIndicator_ startAnimation:self];
  [progressIndicator_ setHidden:NO];
}

-(IBAction) cancel:(id)sender {
  [NSApp stop:sender];
}

-(IBAction)quit:(id)sender{
  [NSApp stop:sender];
}

-(IBAction) uninstall:(id)sender {
  uninstallAction_();
  [showDetails_ setHidden:NO];
  [detailsLabel_ setHidden:NO];
}

- (IBAction)toggleDetails:(id)sender {
  NSRect windowFrame = [window_ frame];
  CGFloat consoleHeight = 240 + 22; // 20px is bottom margin
  if ([sender state] == NSOffState) {
    windowFrame.origin.y += consoleHeight;
    windowFrame.size.height -= consoleHeight;
    [window_ setFrame:windowFrame display:YES animate:YES];
  } else {
    windowFrame.origin.y -= consoleHeight;
    windowFrame.size.height += consoleHeight;
    [window_ setFrame:windowFrame display:YES animate:YES];
  }
}

-(void)showDetails {
  if ([showDetails_ state] == NSOffState) {
    [showDetails_ setState:NSOnState];
    [self toggleDetails:showDetails_];
  }
}

-(void)presentErrorMessage:(NSMutableAttributedString*)consoleText {
  [self printToConsole:consoleText];
}

-(void)presentSuccessMessage:(NSMutableAttributedString*)consoleText {
  [self printToConsole:consoleText];
}

- (void)windowWillClose:(NSNotification *)notification {
  [self cancel:notification];
}

-(void)printToConsole:(NSMutableAttributedString*)text {
  [text addAttribute:NSFontAttributeName value:consoleFont_ range:NSMakeRange(0, [text length])];
  [[console_ textStorage] appendAttributedString:text];
  [console_ scrollRangeToVisible:NSMakeRange([[console_ string] length], 0)];
}

-(void)clearConsole {
  [console_ setString:@""];
}

@end
