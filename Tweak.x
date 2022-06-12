
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <sys/types.h>
#import "SpringBoard.h"
#import <objc/runtime.h>

// GCD
#define GCD_AFTER_MAIN(__dp_af) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(__dp_af * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

#define GCD_END });

#define XLOG(log, ...)	NSLog(@"[tap2debug] " log, ##__VA_ARGS__)

NSString* toggleOneTimeApplicationID;
#ifndef kCFCoreFoundationVersionNumber_iOS_11_0
#define kCFCoreFoundationVersionNumber_iOS_11_0 1443.00
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_13_0
#define kCFCoreFoundationVersionNumber_iOS_13_0 1665.15
#endif

@interface NSTask : NSObject

- (id)init;
- (void)setLaunchPath:(NSString *)path;
- (void)setArguments:(NSArray *)arguments;
- (void)launch;
- (int)processIdentifier;

@end

@interface LSApplicationProxy : NSObject
+ (id) applicationProxyForIdentifier:(id)arg1;
@property (readonly, nonatomic) NSString* canonicalExecutablePath;
@end

@interface TaskManager : NSObject
+ (TaskManager*)sharedManager;
@property (nonatomic,strong) NSTask * runningTask;
@end

@implementation TaskManager
+ (TaskManager*)sharedManager {
    static TaskManager *_sharedSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedSingleton = [[self alloc] init];
    });
    return _sharedSingleton;
}
@end

@interface UIView(findvc)
-(UIViewController*)findViewController;
@end

@implementation UIView(find)
-(UIViewController*)findViewController
{
    UIResponder* target= self;
    while (target) {
        target = target.nextResponder;
        if ([target isKindOfClass:[UIViewController class]]) {
            break;
        }
    }
    return (UIViewController*)target;
}
@end


void show_debug_view(UIViewController* showVC, NSString* _bundleid)
{
	NSString* bundle = _bundleid;
    if(!bundle){
    	XLOG(@"error bundleid is null");
    	return;
    }
	UIViewController * vc = showVC;

	NSString * debugserver = @"/usr/bin/debugserver";
    NSString * ip_port = @"127.0.0.1:1111";
    NSString * last_server = [[NSUserDefaults standardUserDefaults] objectForKey:@"server_bin_path"] ;
    NSString * last_ip =[[NSUserDefaults standardUserDefaults] objectForKey:@"ip_port"] ;
    if(last_server!=nil){
        debugserver = last_server;
    }
    if(last_ip!=nil){
        ip_port = last_ip;
    }

    Class LSApplicationProxy_class = objc_getClass("LSApplicationProxy");
    NSObject* proxyObj = [LSApplicationProxy_class performSelector:@selector(applicationProxyForIdentifier:) withObject:bundle];
	NSString * canonicalExecutablePath = [proxyObj performSelector:@selector(canonicalExecutablePath)];

    UIAlertController * panel = [UIAlertController alertControllerWithTitle:@"🍎 SERVER LAUNCHER" message:canonicalExecutablePath preferredStyle:UIAlertControllerStyleAlert];
    [panel addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
		textField.userInteractionEnabled = NO;
        textField.placeholder = @"server path(not null)";
        textField.text = debugserver;
		GCD_AFTER_MAIN(0.3)
			textField.userInteractionEnabled = YES;
		GCD_END
    }];
    [panel addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"ip:port(nullable)";
        textField.text = ip_port;

    }];
    [panel addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"executable path(not null)";
        textField.text = canonicalExecutablePath;
        textField.enabled = NO;
        textField.textColor = [UIColor lightGrayColor];
    }];
    [panel addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"-x";
        textField.text = @"-x";
        textField.enabled = NO;
        textField.textColor = [UIColor lightGrayColor];
    }];
    [panel addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"backboard";
        textField.text = @"backboard";
        textField.enabled = NO;
        textField.textColor = [UIColor lightGrayColor];
    }];

    UIAlertAction * okaction = [UIAlertAction actionWithTitle:@"▶ START️ SERVER" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {

        UITextField * tf_server = panel.textFields[0];
        UITextField * tf_ip = panel.textFields[1];
        UITextField * tf_exepath = panel.textFields[2];
        UITextField * tf_x = panel.textFields[3];
        UITextField * tf_board = panel.textFields[4];

        NSString * bin_serverpath = [tf_server.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (!bin_serverpath || bin_serverpath.length == 0) {
            XLOG(@"server path is null,stop");
            return ;
        }

        NSString * arg_ipport = [tf_ip.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (!arg_ipport || arg_ipport.length == 0) {
            XLOG(@"ipport is null,continue");
        }

        NSString * arg_exepath = [tf_exepath.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (!arg_exepath || arg_exepath.length == 0) {
            XLOG(@"exe path is null,stop");
            return ;
        }

        NSString * arg_x = [tf_x.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (!arg_x || arg_x.length == 0) {
            XLOG(@"arg_x is null,user default -x");
            arg_x = @"-x";
        }

        NSString * arg_board = [tf_board.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (!arg_board || arg_board.length == 0) {
            XLOG(@"arg_board is null,user default -x backboard");
            arg_board = @"-x backboard";
        }
        XLOG(@"launch path %@",bin_serverpath);
        XLOG(@"%@ %@ %@ %@",bin_serverpath,arg_ipport,arg_exepath,arg_board);
		NSMutableArray * args = [NSMutableArray array];
		[args addObject:arg_ipport];
		[args addObject:arg_exepath];
        [args addObject:arg_x];
        [args addObject:arg_board];
        [[NSUserDefaults standardUserDefaults] setObject:bin_serverpath forKey:@"server_bin_path"] ;
        [[NSUserDefaults standardUserDefaults] setObject:arg_ipport forKey:@"ip_port"] ;
        [[NSUserDefaults standardUserDefaults] synchronize];

        NSTask * task = [TaskManager sharedManager].runningTask;
        if(task){
            kill(task.processIdentifier,SIGKILL);
            task = nil;
        }
        task = [[NSTask alloc]init];
        [task setLaunchPath:bin_serverpath];
		[task setArguments:args];
    	[task launch];
        [TaskManager sharedManager].runningTask = task;
    }];
    UIAlertAction * cancelaction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        XLOG(@"cancel");
    }];
    UIAlertAction * stopAction = [UIAlertAction actionWithTitle:@"⏹ STOP SERVER" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSTask * task = [TaskManager sharedManager].runningTask;
        if(task){
            kill(task.processIdentifier,SIGKILL);
            task = nil;
        }
    }];

    [panel addAction:okaction];
    [panel addAction:stopAction];
    [panel addAction:cancelaction];
    XLOG("vc:%@", vc);
    [vc presentViewController:panel animated:YES completion:nil];
}

%group iOS10Down
%hook SBApplication

- (id)valueForKeyPath:(NSString*)keyPath
{
	if([keyPath isEqualToString:@"info.xia0_hasHiddenTag"])
	{
		return [[self _appInfo] valueForKey:@"xia0_hasHiddenTag"];
	}

	return %orig;
}

%end
%end

%group Shortcut_iOS13Up

%hook SBIconView

- (NSArray *)applicationShortcutItems
{
	NSArray* orig = %orig;

	NSString* applicationID;
	if([self respondsToSelector:@selector(applicationBundleIdentifier)])
	{
		applicationID = [self applicationBundleIdentifier];
	}
	else if([self respondsToSelector:@selector(applicationBundleIdentifierForShortcuts)])
	{
		applicationID = [self applicationBundleIdentifierForShortcuts];
	}

	if(!applicationID)
	{
		return orig;
	}


	SBSApplicationShortcutItem* toggleSafeModeOnceItem = [[%c(SBSApplicationShortcutItem) alloc] init];

	toggleSafeModeOnceItem.localizedTitle = @"Tap2Debug";


	//toggleSafeModeOnceItem.icon = [[%c(SBSApplicationShortcutSystemItem) alloc] initWithSystemImageName:@"fx"];
	toggleSafeModeOnceItem.bundleIdentifierToLaunch = applicationID;
	toggleSafeModeOnceItem.type = @"com.xia0.tap2debug";

	return [orig arrayByAddingObject:toggleSafeModeOnceItem];

	return orig;
}

+ (void)activateShortcut:(SBSApplicationShortcutItem*)item withBundleIdentifier:(NSString*)bundleID forIconView:(id)iconView
{
	if(![item.type isEqualToString:@"com.xia0.tap2debug"]){
		return %orig;
	}

	XLOG("bundleID:%@ view:%@", bundleID, iconView);
	GCD_AFTER_MAIN(0.01)
		show_debug_view([iconView findViewController], bundleID);
	GCD_END
}

%end

%end

%group Shortcut_iOS12Down

%hook SBUIAppIconForceTouchControllerDataProvider

- (NSArray *)applicationShortcutItems
{
	NSArray* orig = %orig;

	NSString* applicationID = [self applicationBundleIdentifier];

	if(!applicationID)
	{
		return orig;
	}


    SBSApplicationShortcutItem* toggleSafeModeOnceItem = [[%c(SBSApplicationShortcutItem) alloc] init];

    toggleSafeModeOnceItem.localizedTitle = @"Tap2Debug";

    //toggleSafeModeOnceItem.icon = [[%c(SBSApplicationShortcutSystemItem) alloc] init];
    toggleSafeModeOnceItem.bundleIdentifierToLaunch = applicationID;
    toggleSafeModeOnceItem.type = @"com.xia0.tap2debug";

    if(!orig)
    {
        return @[toggleSafeModeOnceItem];
    }
    else
    {
        return [orig arrayByAddingObject:toggleSafeModeOnceItem];
    }

	return orig;
}

%end

%hook SBUIAppIconForceTouchController

- (void)appIconForceTouchShortcutViewController:(id)arg1 activateApplicationShortcutItem:(SBSApplicationShortcutItem*)item
{
	if(![item.type isEqualToString:@"com.xia0.tap2debug"]){
		return %orig;
	}

	NSString* bundleID = item.bundleIdentifierToLaunch;
	// Ivar ivar = object_getInstanceVariable(object_getClass(self.delegate), "_rootFolderController", NULL);
	// id rootFolderController = (__bridge id)((__bridge void *)self.delegate + ivar_getOffset(ivar));
	// id rootFolderController = MSHookIvar<id>(self.delegate, "_rootFolderController");
	SBIconController* sbivc = self.delegate;
	id rootFolderController = sbivc._rootFolderController;
	XLOG(@"tap on app:%@ vc:%@ rootFolderController:%@", bundleID, arg1, rootFolderController);
	[self dismissAnimated:YES withCompletionHandler:^{
		GCD_AFTER_MAIN(0.01)
			show_debug_view(rootFolderController, bundleID);
		GCD_END
	}];
}

%end

%end

%ctor {
	%init();
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0) {
		%init(Shortcut_iOS13Up);
	}
	else {
		%init(Shortcut_iOS12Down);
	}

	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_11_0) {
		%init(iOS10Down);
	}
}