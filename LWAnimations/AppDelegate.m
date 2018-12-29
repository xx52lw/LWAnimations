//
//  AppDelegate.m
//  Loter
//
//  Created by liwei on 2017/10/9.
//  Copyright © 2017年 JCP. All rights reserved.
//
// ===================================================================================================================================
#import "AppDelegate.h"

#import <UserNotifications/UserNotifications.h>
#import <AdSupport/AdSupport.h>
#import "JPUSHService.h"
// ===================================================================================================================================
#pragma mark - AppDelegate
@interface AppDelegate ()<UNUserNotificationCenterDelegate>
{
    NSUserDefaults *ud;
}
@property (nonatomic,strong) NSDictionary * launchOptions;

@property (nonatomic,assign) BOOL  isFirstShowAd;

@end
// ===================================================================================================================================
#pragma mark - AppDelegate工具方法
@interface AppDelegate (tools)

- (void)addIntoAPPNotification;  // 添加进入APP的通知
- (void)doAppStartTaskEnd;       // 处理任务结束
- (void)selectIntoAPPController; // 选择进入APP控制器方式
- (void)registerAPNS;            // 处理APNS
- (void)doBaiduMap;              // 处理百度地图
- (void)doShareSDK;              // 处理share分享
- (void)doMTA;                   // 处理行为上报
- (void)doUM;                    // 处理友盟统计
- (void)doJGPushOptions:(NSDictionary *)launchOptions;// 处理极光推送
- (BOOL)isUpdateAvailableFrom:(NSString *)curVer to:(NSString *)newVer; // 比较是否升级版本
- (void)doApplication:(UIApplication *)app openURL:(NSURL *)url; // 处理应用URL回调

@end
// ===================================================================================================================================
#pragma mark - AppDelegate
@implementation AppDelegate

#pragma mark 启动
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // 处理APNS
    [self registerAPNS];
    // 处理极光
    [self doJGPushOptions:launchOptions];

    return YES;
}
void uncaughtExceptionHandler(NSException *exception) {
    NSArray *symbols = [exception callStackSymbols];
    NSString *cashLog = exception.name;
    cashLog = [NSString stringWithFormat:@"%@\n%@\n",cashLog,exception.reason];
    for (NSString *string in symbols) {
        cashLog = [NSString stringWithFormat:@"%@%@\n",cashLog,string];
    }
    [[NSUserDefaults standardUserDefaults] setObject:cashLog forKey:@"cashReason"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"cashTime"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
#pragma mark APP进入后台
- (void)applicationDidEnterBackground:(UIApplication *)application{
    
}
#pragma mark APP将要从后台返回
- (void)applicationWillEnterForeground:(UIApplication *)application{
  
}
#pragma mark 进入前台
- (void)applicationDidBecomeActive:(UIApplication *)application {
 
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
  
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    const unsigned *tokenBytes = [deviceToken bytes];
    [JPUSHService registerDeviceToken:deviceToken];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x", ntohl(tokenBytes[0]), ntohl(tokenBytes[1]),
                          ntohl(tokenBytes[2]), ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]), ntohl(tokenBytes[6]),
                          ntohl(tokenBytes[7])];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
}
#pragma mark - app在前台收到推送消息框会调用--iOS10之后
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{
    
    NSDictionary * userInfo = notification.request.content.userInfo;
    if (@available(iOS 10.0, *)) {
        if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
            [JPUSHService handleRemoteNotification:userInfo];
        }
        // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以选择设置
        completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound);
    } else {
        // Fallback on earlier versions
    }
}
#pragma mark - 点击推送消息框会调用--iOS10之后
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler{
    NSDictionary *dict = response.notification.request.content.userInfo;
    NSLog(@"点击推送消息框会调用--iOS10之后 -   %@",dict);
    
    completionHandler();  // 系统要求执行这个方法
}
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    
}
#pragma mark - 此方法是 用户点击了通知，应用在前台 或者开启后台并且应用在后台 时调起
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    completionHandler(UIBackgroundFetchResultNewData);
    NSLog(@"********** iOS7.0之后 background **********");
    NSLog(@"此方法是 用户点击了通知，应用在前台 或者开启后台并且应用在后台 时调起   %@",userInfo);
    
}

@end
// ===================================================================================================================================
#pragma mark - AppDelegate工具方法
@implementation AppDelegate (tools)

// =============================================
#pragma mark 处理极光推送
- (void)doJGPushOptions:(NSDictionary *)launchOptions {
    NSString *advertisingId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    BOOL apsForProduction = YES;
#ifdef DEBUG
    apsForProduction = NO;
#endif
    [JPUSHService setupWithOption:launchOptions appKey:@"370114604bef87d7edb65475"
                          channel:@"AppStore"
                 apsForProduction:apsForProduction
            advertisingIdentifier:advertisingId];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kJPFNetworkDidLoginNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jgLoginNotification:) name:kJPFNetworkDidLoginNotification object:nil];
//    [JPUSHService registrationIDCompletionHandler:^(int resCode, NSString *registrationID) {
//        NSLog(@"registrationID = %@",registrationID);
//
//    }];
    [JPUSHService setTags:[[NSSet alloc] initWithObjects:@"123456", nil] completion:^(NSInteger iResCode, NSSet *iTags, NSInteger seq) {
        NSLog(@"");
    } seq:nil];
}


// =============================================
#pragma mark 比较是否升级版本
- (BOOL)isUpdateAvailableFrom:(NSString *)curVer to:(NSString *)newVer {
    BOOL result = NO;
    NSArray *arrayA = [curVer componentsSeparatedByString:@"."];
    NSArray *arrayB = [newVer componentsSeparatedByString:@"."];
    NSInteger maxCount = (arrayA.count > arrayB.count) ? arrayA.count : arrayB.count;
    for(NSUInteger i = 0; i < maxCount; ++i) {
        NSInteger verBit1 = (i < arrayA.count) ? [[arrayA objectAtIndex:i] integerValue] : 0;
        NSInteger verBit2 = (i < arrayB.count) ? [[arrayB objectAtIndex:i] integerValue] : 0;
        if (verBit1 < verBit2) {
            result = YES;
            break;
        }
        else if (verBit1 > verBit2) {
            result = NO;
            break;
        }
    }
    return result;
}
- (void)registerAPNS {
    float sysVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (sysVer >= 10) {
        if (@available(iOS 10.0, *)) {
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            center.delegate = self;
            [center requestAuthorizationWithOptions:UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if (granted) {
                }
            }];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        } else {
            // Fallback on earlier versions
        }
    } else if (sysVer >= 8) {
        UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}

@end
// ===================================================================================================================================
