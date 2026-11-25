#import "OPCCActions.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <AudioToolbox/AudioToolbox.h>

NSString *const OPCCDismissNotification = @"OPCCDismissNotification";
NSString *const OPCCReloadNotification  = @"OPCCReloadNotification";
__weak id OPCCRingerControl = nil;

// ---- приватные интерфейсы (только объявления, классы берём через objc_getClass) ----
@interface SBWiFiManager : NSObject
+ (id)sharedInstance; - (BOOL)wiFiEnabled; - (void)setWiFiEnabled:(BOOL)e; - (NSString *)currentNetworkName;
@end
@interface BluetoothManager : NSObject
+ (id)sharedInstance; - (BOOL)powered; - (BOOL)setPowered:(BOOL)p;
@end
@interface RadiosPreferences : NSObject
- (BOOL)airplaneMode; - (void)setAirplaneMode:(BOOL)m; - (void)synchronize;
@end
@interface SBOrientationLockManager : NSObject
+ (id)sharedInstance; - (BOOL)isUserLocked; - (void)lock; - (void)unlock;
@end
@interface CBBlueLightClient : NSObject
- (BOOL)getBlueLightStatus:(void *)s;
@end
@interface _CDBatterySaver : NSObject
+ (id)batterySaver; - (NSInteger)getPowerMode; - (BOOL)setPowerMode:(NSInteger)m error:(NSError **)e;
@end
@interface AVSystemController : NSObject
+ (id)sharedAVSystemController; - (BOOL)getVolume:(float *)v forCategory:(NSString *)c; - (BOOL)setVolumeTo:(float)v forCategory:(NSString *)c;
@end
@interface DNDModeAssertionDetails : NSObject
+ (id)userRequestedAssertionDetailsWithIdentifier:(NSString *)i modeIdentifier:(NSString *)m lifetime:(id)l;
@end
@interface DNDModeAssertionService : NSObject
+ (id)serviceForClientIdentifier:(NSString *)c;
- (id)takeModeAssertionWithDetails:(id)d error:(NSError **)e;
- (BOOL)invalidateAllActiveModeAssertionsWithError:(NSError **)e;
@end
@interface DNDStateService : NSObject
+ (id)serviceForClientIdentifier:(NSString *)c; - (id)queryCurrentStateWithError:(NSError **)e;
@end
@interface DNDState : NSObject - (BOOL)isActive; @end
@interface CLLocationManager (OPCC)
+ (void)setLocationServicesEnabled:(BOOL)e;
@end
@interface CCUIModuleInstanceManager : NSObject
+ (id)sharedInstance;
@end

static void Load(void) {
    static dispatch_once_t t;
    dispatch_once(&t, ^{
        dlopen("/System/Library/PrivateFrameworks/BluetoothManager.framework/BluetoothManager", RTLD_LAZY);
        dlopen("/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices", RTLD_LAZY);
        dlopen("/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness", RTLD_LAZY);
        dlopen("/System/Library/PrivateFrameworks/DoNotDisturb.framework/DoNotDisturb", RTLD_LAZY);
        dlopen("/System/Library/PrivateFrameworks/CoreDuet.framework/CoreDuet", RTLD_LAZY);
    });
}

static NSString *const kDNDMode   = @"com.apple.donotdisturb.mode.default";
static NSString *const kDNDClient = @"com.opcc.coloroscc";
static NSString *const kDomain    = @"com.opcc.coloroscc";

// ---- кэш и фоновая очередь для «тяжёлых» состояний (раньше они опрашивались в главном потоке и вешали телефон) ----
static dispatch_queue_t Q(void) { static dispatch_queue_t q; static dispatch_once_t t; dispatch_once(&t, ^{ q = dispatch_queue_create("com.opcc.state", DISPATCH_QUEUE_SERIAL); }); return q; }
static NSMutableDictionary *Cache(void) { static NSMutableDictionary *d; static dispatch_once_t t; dispatch_once(&t, ^{ d = [NSMutableDictionary dictionary]; }); return d; }
static NSArray *HeavyIDs(void) { return @[@"location", @"airplane", @"dnd", @"eyecomfort", @"powersaving"]; }

static RadiosPreferences *Radios(void) { static RadiosPreferences *p; if (!p) p = [[objc_getClass("RadiosPreferences") alloc] init]; return p; }
static CBBlueLightClient *Blue(void) { static CBBlueLightClient *c; if (!c) c = [[objc_getClass("CBBlueLightClient") alloc] init]; return c; }

static BOOL HeavyState(NSString *i) {
    @try {
        if ([i isEqualToString:@"location"]) return [CLLocationManager locationServicesEnabled];
        if ([i isEqualToString:@"airplane"]) return [Radios() airplaneMode];
        if ([i isEqualToString:@"dnd"]) {
            id svc = [objc_getClass("DNDStateService") serviceForClientIdentifier:kDNDClient];
            return [[svc queryCurrentStateWithError:nil] isActive];
        }
        if ([i isEqualToString:@"eyecomfort"]) { char buf[128] = {0}; [Blue() getBlueLightStatus:buf]; return buf[1] != 0; }
        if ([i isEqualToString:@"powersaving"]) return [[objc_getClass("_CDBatterySaver") batterySaver] getPowerMode] != 0;
    } @catch (__unused NSException *e) {}
    return NO;
}
static void HeavyToggle(NSString *i, BOOL on) {
    @try {
        if ([i isEqualToString:@"location"]) [CLLocationManager setLocationServicesEnabled:!on];
        else if ([i isEqualToString:@"airplane"]) { RadiosPreferences *p = Radios(); [p setAirplaneMode:!on]; [p synchronize]; }
        else if ([i isEqualToString:@"dnd"]) {
            id svc = [objc_getClass("DNDModeAssertionService") serviceForClientIdentifier:kDNDClient];
            if (on) [svc invalidateAllActiveModeAssertionsWithError:nil];
            else {
                id d = [objc_getClass("DNDModeAssertionDetails") userRequestedAssertionDetailsWithIdentifier:@"com.opcc.coloroscc.assertion" modeIdentifier:kDNDMode lifetime:nil];
                [svc takeModeAssertionWithDetails:d error:nil];
            }
        }
        else if ([i isEqualToString:@"eyecomfort"]) ((BOOL (*)(id, SEL, BOOL))objc_msgSend)(Blue(), NSSelectorFromString(@"setEnabled:"), !on);
        else if ([i isEqualToString:@"powersaving"]) [[objc_getClass("_CDBatterySaver") batterySaver] setPowerMode:on ? 0 : 1 error:nil];
    } @catch (__unused NSException *e) {}
}

// Запись экрана через системный модуль Центра управления (best-effort)
static void ToggleScreenRecording(void) {
    @try {
        id mgr = [objc_getClass("CCUIModuleInstanceManager") sharedInstance];
        id coll = nil;
        for (NSString *k in @[@"moduleInstances", @"_moduleInstanceByIdentifier"]) { @try { coll = [mgr valueForKey:k]; } @catch (__unused NSException *e) {} if (coll) break; }
        NSArray *insts = [coll isKindOfClass:[NSDictionary class]] ? [(NSDictionary *)coll allValues] : [coll isKindOfClass:[NSSet class]] ? [(NSSet *)coll allObjects] : coll;
        for (id inst in insts) {
            NSString *mid = nil; @try { mid = [[inst valueForKey:@"metadata"] valueForKey:@"moduleIdentifier"]; } @catch (__unused NSException *e) {}
            NSString *l = mid.lowercaseString; if (!([l containsString:@"replaykit"] || [l containsString:@"screenrecord"] || [l containsString:@"screencapture"])) continue;
            id module = [inst valueForKey:@"module"]; SEL set = NSSelectorFromString(@"setSelected:"), is = NSSelectorFromString(@"isSelected");
            if ([module respondsToSelector:set]) {
                BOOL cur = [module respondsToSelector:is] ? ((BOOL (*)(id, SEL))objc_msgSend)(module, is) : NO;
                ((void (*)(id, SEL, BOOL))objc_msgSend)(module, set, !cur); return;
            }
        }
    } @catch (__unused NSException *e) {}
}

@implementation OPCCActions

#pragma mark - настройки (CFPreferences: работает между процессами сразу)
+ (id)pref:(NSString *)k { return CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)k, (__bridge CFStringRef)kDomain)); }
+ (void)setPref:(id)v key:(NSString *)k { CFPreferencesSetAppValue((__bridge CFStringRef)k, (__bridge CFPropertyListRef)v, (__bridge CFStringRef)kDomain); CFPreferencesAppSynchronize((__bridge CFStringRef)kDomain); }
+ (void)syncPrefs { CFPreferencesAppSynchronize((__bridge CFStringRef)kDomain); }
+ (CGFloat)shadeScale  { id v = [self pref:@"shadeScale"];  return [v respondsToSelector:@selector(doubleValue)] ? MAX(0.5, MIN(2.0, [v doubleValue])) : 1.1; }
+ (CGFloat)buttonScale { id v = [self pref:@"buttonScale"]; return [v respondsToSelector:@selector(doubleValue)] ? MAX(0.7, MIN(1.8, [v doubleValue])) : 1.2; }
+ (BOOL)shadeScaleIsSet { return [[self pref:@"shadeScale"] respondsToSelector:@selector(doubleValue)]; }
+ (BOOL)boolPref:(NSString *)k def:(BOOL)d { id v = [self pref:k]; return [v respondsToSelector:@selector(boolValue)] ? [v boolValue] : d; }
+ (BOOL)isHomeButtonDevice {
    UIScreen *s = [UIScreen mainScreen]; SEL sel = NSSelectorFromString(@"_displayCornerRadius");
    if ([s respondsToSelector:sel]) { CGFloat r = ((CGFloat (*)(id, SEL))objc_msgSend)(s, sel); if (r > 0.5) return NO; }   // скруглённый экран — iPhone с чёлкой/островом
    CGSize n = s.nativeBounds.size; return MAX(n.width, n.height) < 2000;
}
+ (BOOL)bottomMode {
    id v = [self pref:@"shadeEdge"]; NSString *e = [v isKindOfClass:[NSString class]] ? v : @"auto";
    if ([e isEqualToString:@"top"]) return NO;
    if ([e isEqualToString:@"bottom"]) return YES;
    return [self isHomeButtonDevice];
}
+ (BOOL)showLabels     { id v = [self pref:@"showLabels"];  return [v respondsToSelector:@selector(boolValue)] ? [v boolValue] : YES; }

#pragma mark - каталог
+ (NSArray *)allIDs {
    return @[@"torch",@"location",@"airplane",@"devicecontrols",@"ewallet",@"autorotate",@"dnd",
             @"quickshare",@"eyecomfort",@"powersaving",@"screenrecord",@"camera",
             @"calculator",@"timer",@"mobiledata"];
}
+ (NSArray *)defaultIDs {
    return @[@"torch",@"location",@"airplane",@"devicecontrols",@"ewallet",@"autorotate",@"dnd",
             @"quickshare",@"eyecomfort",@"powersaving",@"screenrecord",@"camera"];
}
+ (NSArray *)activeIDs {
    NSArray *a = [self pref:@"buttons"];
    if (![a isKindOfClass:[NSArray class]]) return [self defaultIDs];
    NSMutableArray *out = [NSMutableArray array];
    for (NSString *i in a) if ([[self allIDs] containsObject:i] && ![out containsObject:i]) [out addObject:i];   // старые/удалённые id отсеиваются
    return out;
}
+ (void)saveActiveIDs:(NSArray *)ids { [self setPref:ids key:@"buttons"]; }
+ (NSDictionary *)meta {
    return @{
     @"torch":@[@"Фонарик ▾",@"flashlight.off.fill"], @"location":@[@"Геолокация",@"location.fill"],
     @"airplane":@[@"Режим полёта",@"airplane"], @"devicecontrols":@[@"Управление устройствами",@"house.fill"],
     @"ewallet":@[@"Кошелёк",@"wallet.pass.fill"], @"autorotate":@[@"Автоповорот",@"arrow.triangle.2.circlepath"],
     @"dnd":@[@"Не беспокоить ▾",@"moon.fill"], @"quickshare":@[@"Quick Share",@"arrow.triangle.2.circlepath.circle"],
     @"eyecomfort":@[@"Комфорт для глаз",@"eye.fill"], @"powersaving":@[@"Энергосбережение",@"battery.100"],
     @"screenrecord":@[@"Запись экрана ▾",@"video.fill"],
     @"camera":@[@"Камера",@"camera.fill"], @"calculator":@[@"Калькулятор",@"plus.forwardslash.minus"],
     @"timer":@[@"Таймер",@"timer"], @"mobiledata":@[@"Мобильные данные",@"antenna.radiowaves.left.and.right"]};
}
+ (NSString *)titleFor:(NSString *)i  { return [self meta][i][0] ?: i; }
+ (NSString *)symbolFor:(NSString *)i { return [self meta][i][1] ?: @"circle"; }
+ (BOOL)isDimmed:(NSString *)i { return [@[@"devicecontrols",@"ewallet"] containsObject:i]; }

#pragma mark - состояния
+ (BOOL)stateFor:(NSString *)i {
    if ([i isEqualToString:@"torch"]) {
        AVCaptureDevice *d = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        return d.torchMode == AVCaptureTorchModeOn;
    }
    if ([i isEqualToString:@"autorotate"]) { Load(); @try { return ![[objc_getClass("SBOrientationLockManager") sharedInstance] isUserLocked]; } @catch (__unused NSException *e) { return NO; } }
    if ([i isEqualToString:@"screenrecord"]) return [UIScreen mainScreen].isCaptured;
    if ([HeavyIDs() containsObject:i]) @synchronized (Cache()) { return [Cache()[i] boolValue]; }
    return NO;
}
+ (void)refreshStates:(void (^)(void))done {
    Load();
    dispatch_async(Q(), ^{
        for (NSString *i in HeavyIDs()) { BOOL s = HeavyState(i); @synchronized (Cache()) { Cache()[i] = @(s); } }
        if (done) dispatch_async(dispatch_get_main_queue(), done);
    });
}

+ (void)tap:(NSString *)i {
    Load();
    if ([HeavyIDs() containsObject:i]) {                  // всё тяжёлое — в фоне, интерфейс обновляется сразу
        BOOL on = [self stateFor:i];
        @synchronized (Cache()) { Cache()[i] = @(!on); }
        dispatch_async(Q(), ^{ HeavyToggle(i, on); });
        return;
    }
    @try {
        if ([i isEqualToString:@"torch"]) {
            AVCaptureDevice *d = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            BOOL on = d.torchMode == AVCaptureTorchModeOn;
            if ([d hasTorch] && [d lockForConfiguration:nil]) { d.torchMode = on ? AVCaptureTorchModeOff : AVCaptureTorchModeOn; [d unlockForConfiguration]; }
        } else if ([i isEqualToString:@"autorotate"]) {
            id m = [objc_getClass("SBOrientationLockManager") sharedInstance]; [m isUserLocked] ? [m unlock] : [m lock];
        } else if ([i isEqualToString:@"screenrecord"]) {
            ToggleScreenRecording();                       // шторку не закрываем
        } else if ([i isEqualToString:@"quickshare"])  [self openSettingsURL:@"App-prefs:General&path=AIRDROP"];
        else if ([i isEqualToString:@"mobiledata"])    [self openSettingsURL:@"App-prefs:MOBILE_DATA_SETTINGS_ID"];
        else if ([i isEqualToString:@"devicecontrols"]) [self openApp:@"com.apple.Home"];
        else if ([i isEqualToString:@"ewallet"])        [self openApp:@"com.apple.Passbook"];
        else if ([i isEqualToString:@"camera"])         [self openApp:@"com.apple.camera"];
        else if ([i isEqualToString:@"calculator"])     [self openApp:@"com.apple.calculator"];
        else if ([i isEqualToString:@"timer"])          [self openApp:@"com.apple.mobiletimer"];
    } @catch (__unused NSException *e) {}
}

+ (void)longPress:(NSString *)i {
    NSDictionary *m = @{@"location":@"App-prefs:Privacy&path=LOCATION", @"airplane":@"App-prefs:AIRPLANE_MODE",
                        @"dnd":@"App-prefs:DO_NOT_DISTURB", @"powersaving":@"App-prefs:BATTERY_USAGE",
                        @"eyecomfort":@"App-prefs:DISPLAY", @"quickshare":@"App-prefs:General&path=AIRDROP",
                        @"mobiledata":@"App-prefs:MOBILE_DATA_SETTINGS_ID"};
    if (m[i]) [self openSettingsURL:m[i]];
}

#pragma mark - ползунки
+ (float)brightness { return [UIScreen mainScreen].brightness; }
+ (void)setBrightness:(float)v {
    Load();
    v = MAX(0.01f, MIN(1.f, v));
    void (*set)(float, int) = dlsym(RTLD_DEFAULT, "BKSDisplayBrightnessSet");
    if (set) set(v, 1); else [UIScreen mainScreen].brightness = v;
}
+ (float)volume { float v = 0; [[objc_getClass("AVSystemController") sharedAVSystemController] getVolume:&v forCategory:@"Audio/Video"]; return v; }
+ (void)setVolume:(float)v { [[objc_getClass("AVSystemController") sharedAVSystemController] setVolumeTo:MAX(0, MIN(1, v)) forCategory:@"Audio/Video"]; }

#pragma mark - плитки
+ (BOOL)wifiOn { Load(); return [[objc_getClass("SBWiFiManager") sharedInstance] wiFiEnabled]; }
+ (NSString *)wifiName { Load(); NSString *n = [[objc_getClass("SBWiFiManager") sharedInstance] currentNetworkName]; return n.length ? n : nil; }
+ (void)setWifi:(BOOL)on { Load(); [[objc_getClass("SBWiFiManager") sharedInstance] setWiFiEnabled:on]; }
+ (BOOL)btOn { Load(); return [[objc_getClass("BluetoothManager") sharedInstance] powered]; }
+ (void)setBT:(BOOL)on { Load(); id m = [objc_getClass("BluetoothManager") sharedInstance]; [m setPowered:on]; ((BOOL (*)(id, SEL, BOOL))objc_msgSend)(m, NSSelectorFromString(@"setEnabled:"), on); }

+ (id)ringer {
    if (OPCCRingerControl) return OPCCRingerControl;
    id r = nil;
    @try { r = [[UIApplication sharedApplication] valueForKey:@"ringerControl"]; } @catch (__unused NSException *e) {}
    if (!r) { @try { r = [[UIApplication sharedApplication] valueForKey:@"_ringerControl"]; } @catch (__unused NSException *e) {} }
    if (r) OPCCRingerControl = r;
    return r;
}
+ (NSInteger)ringerMode {
    id r = [self ringer]; SEL s = NSSelectorFromString(@"isRingerMuted");
    if (r && [r respondsToSelector:s]) {
        BOOL muted = ((BOOL (*)(id, SEL))objc_msgSend)(r, s);
        if (!muted) return 0;
        return [[self pref:@"silentKind"] integerValue] == 1 ? 1 : 2;
    }
    return [[self pref:@"ringerMode"] integerValue];
}
+ (void)setRingerMode:(NSInteger)m {
    [self setPref:@(m) key:@"ringerMode"];
    if (m) [self setPref:@(m) key:@"silentKind"];
    id r = [self ringer]; SEL s = NSSelectorFromString(@"setRingerMuted:");
    if (r && [r respondsToSelector:s]) ((void (*)(id, SEL, BOOL))objc_msgSend)(r, s, m != 0);
    CFPreferencesSetAppValue(CFSTR("silent-vibrate"), m == 1 ? kCFBooleanTrue : kCFBooleanFalse, CFSTR("com.apple.springboard"));
    CFPreferencesAppSynchronize(CFSTR("com.apple.springboard"));
    if (m == 1) AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

#pragma mark - запуск (сначала плавно закрываем шторку, потом открываем — иначе всё зависало)
+ (void)dismissThen:(dispatch_block_t)b {
    [[NSNotificationCenter defaultCenter] postNotificationName:OPCCDismissNotification object:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.55 * NSEC_PER_SEC)), dispatch_get_main_queue(), b);
}
+ (void)launchAppNow:(NSString *)b {
    if (!b.length) return;
    UIApplication *app = [UIApplication sharedApplication];
    SEL sel = NSSelectorFromString(@"launchApplicationWithIdentifier:suspended:");
    if ([app respondsToSelector:sel]) ((void (*)(id, SEL, id, BOOL))objc_msgSend)(app, sel, b, NO);
}
+ (void)openApp:(NSString *)b { [self dismissThen:^{ [self launchAppNow:b]; }]; }
+ (void)openSettingsURL:(NSString *)u {
    [self dismissThen:^{
        NSURL *url = [NSURL URLWithString:u]; if (!url) return;
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }];
}
@end
