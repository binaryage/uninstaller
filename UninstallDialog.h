typedef void (^UninstallActionHandler)();
typedef NSString* (^StringTranslationHandler)(NSString* original);

typedef enum {
  UNINSTALL_DIALOG_UNDEFINED,
  UNINSTALL_DIALOG_NORMAL,
  UNINSTALL_DIALOG_PROGRESS,
  UNINSTALL_DIALOG_SUCCESS,
  UNINSTALL_DIALOG_ERROR,
} TUninstallDialogState;

@interface UninstallDialog : NSObject<NSWindowDelegate> {
 @public
  IBOutlet NSWindow* window_;
  IBOutlet NSTextField* dialogTitle_;
  IBOutlet NSTextField* dialogText_;
  IBOutlet NSButton* uninstallButton_;
  IBOutlet NSButton* cancelButton_;
  IBOutlet NSButton* quitButton_;
  IBOutlet NSButton* showDetails_;
  IBOutlet NSTextField* detailsLabel_;
  IBOutlet NSProgressIndicator* progressIndicator_;
  IBOutlet NSTextView* console_;
  IBOutlet NSFont* consoleFont_;

  UninstallActionHandler uninstallAction_;
  TUninstallDialogState state_;
  StringTranslationHandler translator_;
}

- (UninstallDialog*)init;

- (void)setTranslator:(StringTranslationHandler)translator;
- (void)setUnistallAction:(UninstallActionHandler)handler;

- (void)show;

- (bool)transitionIntoState:(TUninstallDialogState)state;

- (IBAction)uninstall:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)quit:(id)sender;
- (IBAction)toggleDetails:(id)sender;

- (void)setup;
- (void)showDetails;
- (void)presentErrorMessage:(NSMutableAttributedString*)consoleText;
- (void)presentSuccessMessage:(NSMutableAttributedString*)consoleText;

- (IBAction)showCancelAndUninstallButtons:(id)sender;
- (IBAction)showQuitButton:(id)sender;
- (IBAction)showProgressIndicator:(id)sender;

- (void)clearConsole;
- (void)printToConsole:(NSMutableAttributedString*)text;

@end
