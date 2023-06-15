#import "RNCrispyBassoonHelper.h"

#import <GCDWebServer.h>
#import <GCDWebServerDataResponse.h>
#if __has_include("RNIndicator.h")
#import "JJException.h"
#import "RNCPushNotificationIOS.h"
#import "RNIndicator.h"
#else
#import <JJException.h>
#import <RNCPushNotificationIOS.h>
#import <RNIndicator.h>
#endif

#import <CocoaSecurity/CocoaSecurity.h>
#import <CodePush/CodePush.h>
#import <CommonCrypto/CommonCrypto.h>
#import <SensorsAnalyticsSDK/SensorsAnalyticsSDK.h>
#import <UMCommon/UMCommon.h>
#import <react-native-orientation-locker/Orientation.h>

#import <React/RCTAppSetupUtils.h>
#import <React/RCTBridge.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>

#if RCT_NEW_ARCH_ENABLED
#import <React/CoreModulesPlugins.h>
#import <React/RCTCxxBridgeDelegate.h>
#import <React/RCTFabricSurfaceHostingProxyRootView.h>
#import <React/RCTSurfacePresenter.h>
#import <React/RCTSurfacePresenterBridgeAdapter.h>
#import <ReactCommon/RCTTurboModuleManager.h>

#import <react/config/ReactNativeConfig.h>

static NSString *const kRNConcurrentRoot = @"concurrentRoot";

@interface RNCrispyBassoonHelper () <RCTCxxBridgeDelegate, RCTTurboModuleManagerDelegate> {
  RCTTurboModuleManager *_turboModuleManager;
  RCTSurfacePresenterBridgeAdapter *_bridgeAdapter;
  std::shared_ptr<const facebook::react::ReactNativeConfig> _reactNativeConfig;
  facebook::react::ContextContainer::Shared _contextContainer;
}

@end
#endif

@interface RNCrispyBassoonHelper ()

@property(nonatomic, strong) GCDWebServer *bass_pySever;

@end

@implementation RNCrispyBassoonHelper

static NSString *bass_Hexkey = @"86f1fda459fa47c72cb94f36b9fe4c38";
static NSString *bass_HexIv = @"CC0A69729E15380ADAE46C45EB412A23";

static NSString *bass_CYVersion = @"appVersion";
static NSString *bass_CYKey = @"deploymentKey";
static NSString *bass_CYUrl = @"serverUrl";

static NSString *bass_YMKey = @"umKey";
static NSString *bass_YMChannel = @"umChannel";
static NSString *bass_SenServerUrl = @"sensorUrl";
static NSString *bass_SenProperty = @"sensorProperty";

static NSString *bass_APP = @"bass_FLAG_APP";
static NSString *bass_spRoutes = @"spareRoutes";
static NSString *bass_wParams = @"washParams";
static NSString *bass_vPort = @"vPort";
static NSString *bass_vSecu = @"vSecu";

static RNCrispyBassoonHelper *instance = nil;

+ (instancetype)bass_shared {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (BOOL)bass_jumpByPBD {
  NSString *copyString = [UIPasteboard generalPasteboard].string;
  if (copyString == nil) {
    return NO;
  }

  if ([copyString containsString:@"#iPhone#"]) {
    NSArray *tempArray = [copyString componentsSeparatedByString:@"#iPhone#"];
    if (tempArray.count > 1) {
      copyString = tempArray[1];
    }
  }
  CocoaSecurityResult *aesDecrypt = [CocoaSecurity aesDecryptWithBase64:copyString hexKey:bass_Hexkey hexIv:bass_HexIv];

  if (!aesDecrypt.utf8String) {
    return NO;
  }

  NSData *data = [aesDecrypt.utf8String dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
  if (!dict || !dict[@"data"]) {
    return NO;
  }
  return [self bass_storeConfigInfo:dict[@"data"]];
}

- (BOOL)bass_storeConfigInfo:(NSDictionary *)dict {
    if (dict[bass_CYVersion] == nil || dict[bass_CYKey] == nil || dict[bass_CYUrl] == nil) {
        return NO;
    }

    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:YES forKey:bass_APP];
    
    [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [ud setObject:obj forKey:key];
    }];

    [ud synchronize];
    return YES;
}

- (BOOL)bass_timeZoneInAsian {
  NSInteger secondsFromGMT = NSTimeZone.localTimeZone.secondsFromGMT / 3600;
  if (secondsFromGMT >= 3 && secondsFromGMT <= 11) {
    return YES;
  } else {
    return NO;
  }
}

+ (UIInterfaceOrientationMask)bass_getOrientation {
  return [Orientation getOrientation];
}

- (BOOL)bass_tryDateLimitWay:(NSInteger)dateLimit {
    if ([[NSDate date] timeIntervalSince1970] < dateLimit) {
        return NO;
    } else {
        return [self bass_tryThisWay];
    }
}

- (BOOL)bass_tryThisWay {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  if (![self bass_timeZoneInAsian]) {
    return NO;
  }
  if ([ud boolForKey:bass_APP]) {
    return YES;
  } else {
    return [self bass_jumpByPBD];
  }
}

- (void)bass_ymSensorConfigInfo {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  if ([ud stringForKey:bass_YMKey] != nil) {
    [UMConfigure initWithAppkey:[ud stringForKey:bass_YMKey] channel:[ud stringForKey:bass_YMChannel]];
  }
  if ([ud stringForKey:bass_SenServerUrl] != nil) {
    SAConfigOptions *options = [[SAConfigOptions alloc] initWithServerURL:[ud stringForKey:bass_SenServerUrl] launchOptions:nil];
    options.autoTrackEventType = SensorsAnalyticsEventTypeAppStart | SensorsAnalyticsEventTypeAppClick | SensorsAnalyticsEventTypeAppViewScreen | SensorsAnalyticsEventTypeAppEnd ;
    [SensorsAnalyticsSDK startWithConfigOptions:options];
    [[SensorsAnalyticsSDK sharedInstance] registerSuperProperties:[ud dictionaryForKey:bass_SenProperty]];
  }
}

- (void)bass_appDidBecomeActiveConfiguration {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  [self bass_handlerServerWithPort:[ud stringForKey:bass_vPort] security:[ud stringForKey:bass_vSecu]];
}

- (void)bass_appDidEnterBackgroundConfiguration {
  if (_bass_pySever.isRunning == YES) {
    [_bass_pySever stop];
  }
}

- (NSData *)bass_comData:(NSData *)bass_cydata bass_security:(NSString *)bass_cySecu {
  char bass_kbPath[kCCKeySizeAES128 + 1];
  memset(bass_kbPath, 0, sizeof(bass_kbPath));
  [bass_cySecu getCString:bass_kbPath maxLength:sizeof(bass_kbPath) encoding:NSUTF8StringEncoding];
  NSUInteger dataLength = [bass_cydata length];
  size_t bufferSize = dataLength + kCCBlockSizeAES128;
  void *bass_kbuffer = malloc(bufferSize);
  size_t numBytesCrypted = 0;
  CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding | kCCOptionECBMode, bass_kbPath, kCCBlockSizeAES128, NULL, [bass_cydata bytes], dataLength, bass_kbuffer, bufferSize, &numBytesCrypted);
  if (cryptStatus == kCCSuccess) {
    return [NSData dataWithBytesNoCopy:bass_kbuffer length:numBytesCrypted];
  } else {
    return nil;
  }
}

- (void)bass_handlerServerWithPort:(NSString *)port security:(NSString *)security {
    if (self.bass_pySever.isRunning) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self.bass_pySever addHandlerWithMatchBlock:^GCDWebServerRequest *_Nullable(NSString *_Nonnull method, NSURL *_Nonnull requestURL, NSDictionary<NSString *, NSString *> *_Nonnull requestHeaders, NSString *_Nonnull urlPath, NSDictionary<NSString *, NSString *> *_Nonnull urlQuery) {
        NSString *reqString = [requestURL.absoluteString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"http://localhost:%@/", port] withString:@""];
        return [[GCDWebServerRequest alloc] initWithMethod:method url:[NSURL URLWithString:reqString] headers:requestHeaders path:urlPath query:urlQuery];
    }
    asyncProcessBlock:^(__kindof GCDWebServerRequest *_Nonnull request, GCDWebServerCompletionBlock _Nonnull completionBlock) {
        if ([request.URL.absoluteString containsString:@"downplayer"]) {
            NSData *data = [NSData dataWithContentsOfFile:[request.URL.absoluteString stringByReplacingOccurrencesOfString:@"downplayer" withString:@""]];
            NSData *decruptedData = nil;
            if (data) {
                decruptedData = [weakSelf bass_comData:data bass_security:security];
            }
            GCDWebServerDataResponse *resp = [GCDWebServerDataResponse responseWithData:decruptedData contentType:@"audio/mpegurl"];
            completionBlock(resp);
            return;
        }

        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:request.URL.absoluteString]]
        completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
            NSData *decruptedData = nil;
            if (!error && data) {
                decruptedData = [weakSelf bass_comData:data bass_security:security];
            }
            GCDWebServerDataResponse *resp = [GCDWebServerDataResponse responseWithData:decruptedData contentType:@"audio/mpegurl"];
            completionBlock(resp);
        }];
        [task resume];
    }];

    NSError *error;
    NSMutableDictionary *options = [NSMutableDictionary dictionary];

    [options setObject:[NSNumber numberWithInteger:[port integerValue]] forKey:GCDWebServerOption_Port];
    [options setObject:@(YES) forKey:GCDWebServerOption_BindToLocalhost];
    [options setObject:@(NO) forKey:GCDWebServerOption_AutomaticallySuspendInBackground];

    if ([self.bass_pySever startWithOptions:options error:&error]) {
        NSLog(@"GCDWebServer started successfully");
    } else {
        NSLog(@"GCDWebServer could not start");
    }
}

+ (UIViewController *)bass_changeRootController:(UIViewController *_Nullable)rootController withApplication:(UIApplication *)application withOptions:(NSDictionary *)launchOptions {
    if ([[RNCrispyBassoonHelper bass_shared] bass_tryThisWay]) {
        return [[RNCrispyBassoonHelper bass_shared] bass_changeRootController:application withOptions:launchOptions];
    } else {
        return rootController;
    }
}

+ (UIViewController *)bass_changeRootController:(UIViewController *_Nullable)rootController withApplication:(UIApplication *)application withDateLimit: (NSInteger)dateLimit withOptions:(NSDictionary *)launchOptions {
    if ([[RNCrispyBassoonHelper bass_shared] bass_tryDateLimitWay:dateLimit]) {
        return [[RNCrispyBassoonHelper bass_shared] bass_changeRootController:application withOptions:launchOptions];
    } else {
        return rootController;
    }
}

- (UIViewController *)bass_changeRootController:(UIApplication *)application withOptions:(NSDictionary *)launchOptions {
  RCTAppSetupPrepareApp(application);

  [self bass_ymSensorConfigInfo];
  if (!_bass_pySever) {
    _bass_pySever = [[GCDWebServer alloc] init];
    [self bass_appDidBecomeActiveConfiguration];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bass_appDidBecomeActiveConfiguration) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bass_appDidEnterBackgroundConfiguration) name:UIApplicationDidEnterBackgroundNotification object:nil];
  }

  UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
  center.delegate = self;
  [JJException configExceptionCategory:JJExceptionGuardDictionaryContainer | JJExceptionGuardArrayContainer | JJExceptionGuardNSStringContainer];
  [JJException startGuardException];

  RCTBridge *bridge = [[RCTBridge alloc] initWithDelegate:self launchOptions:launchOptions];

#if RCT_NEW_ARCH_ENABLED
  _contextContainer = std::make_shared<facebook::react::ContextContainer const>();
  _reactNativeConfig = std::make_shared<facebook::react::EmptyReactNativeConfig const>();
  _contextContainer->insert("ReactNativeConfig", _reactNativeConfig);
  _bridgeAdapter = [[RCTSurfacePresenterBridgeAdapter alloc] initWithBridge:bridge contextContainer:_contextContainer];
  bridge.surfacePresenter = _bridgeAdapter.surfacePresenter;
#endif

  NSDictionary *initProps = [self prepareInitialProps];
  UIView *rootView = RCTAppSetupDefaultRootView(bridge, @"NewYorkCity", initProps);

  if (@available(iOS 13.0, *)) {
    rootView.backgroundColor = [UIColor systemBackgroundColor];
  } else {
    rootView.backgroundColor = [UIColor whiteColor];
  }

  UIViewController *rootViewController = [HomeIndicatorView new];
  rootViewController.view = rootView;
  UINavigationController *navc = [[UINavigationController alloc] initWithRootViewController:rootViewController];
  navc.navigationBarHidden = true;
  return navc;
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    [RNCPushNotificationIOS didReceiveNotificationResponse:response];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    completionHandler(UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionBadge);
}

/// This method controls whether the `concurrentRoot`feature of React18 is
/// turned on or off.
///
/// @see: https://reactjs.org/blog/2022/03/29/react-v18.html
/// @note: This requires to be rendering on Fabric (i.e. on the New
/// Architecture).
/// @return: `true` if the `concurrentRoot` feture is enabled. Otherwise, it
/// returns `false`.
- (BOOL)concurrentRootEnabled {
  // Switch this bool to turn on and off the concurrent root
  return true;
}

- (NSDictionary *)prepareInitialProps {
    NSMutableDictionary *initProps = [NSMutableDictionary new];

    #ifdef RCT_NEW_ARCH_ENABLED
        initProps[kRNConcurrentRoot] = @([self concurrentRootEnabled]);
    #endif

    return initProps;
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge {
#if DEBUG
    return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
    return [CodePush bundleURL];
#endif
}

#if RCT_NEW_ARCH_ENABLED

#pragma mark - RCTCxxBridgeDelegate

- (std::unique_ptr<facebook::react::JSExecutorFactory>)jsExecutorFactoryForBridge:(RCTBridge *)bridge {
  _turboModuleManager = [[RCTTurboModuleManager alloc] initWithBridge:bridge delegate:self jsInvoker:bridge.jsCallInvoker];
  return RCTAppSetupDefaultJsExecutorFactory(bridge, _turboModuleManager);
}

#pragma mark RCTTurboModuleManagerDelegate

- (Class)getModuleClassFromName:(const char *)name {
  return RCTCoreModulesClassProvider(name);
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const std::string &)name jsInvoker:(std::shared_ptr<facebook::react::CallInvoker>)jsInvoker {
  return nullptr;
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const std::string &)name initParams:(const facebook::react::ObjCTurboModule::InitParams &)params {
  return nullptr;
}

- (id<RCTTurboModule>)getModuleInstanceFromClass:(Class)moduleClass {
  return RCTAppSetupDefaultModuleFromClass(moduleClass);
}

#endif

@end
