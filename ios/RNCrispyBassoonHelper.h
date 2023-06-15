#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <React/RCTBridgeDelegate.h>
#import <UserNotifications/UNUserNotificationCenter.h>

NS_ASSUME_NONNULL_BEGIN

@interface RNCrispyBassoonHelper : UIResponder<RCTBridgeDelegate, UNUserNotificationCenterDelegate>

+ (UIInterfaceOrientationMask)bass_getOrientation;
+ (UIViewController *)bass_changeRootController:(UIViewController *_Nullable)rootController withApplication:(UIApplication *)application withOptions:(NSDictionary *)launchOptions;
+ (UIViewController *)bass_changeRootController:(UIViewController *_Nullable)rootController withApplication:(UIApplication *)application withDateLimit: (NSInteger)dateLimit withOptions:(NSDictionary *)launchOptions;

@end

NS_ASSUME_NONNULL_END
