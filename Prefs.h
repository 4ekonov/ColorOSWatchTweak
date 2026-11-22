#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Домен настроек и имя Darwin-уведомления (то же самое в Root.plist)
#define COC_DOMAIN @"com.coloros.clocktweak"
#define COC_NOTIFY "com.coloros.clocktweak/prefsChanged"

static inline id COCRaw(NSString *key) {
    return CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)key,
                                                       (__bridge CFStringRef)COC_DOMAIN));
}

static inline CGFloat COCF(NSString *key, CGFloat def) {
    id v = COCRaw(key);
    return [v isKindOfClass:[NSNumber class]] ? [v doubleValue] : def;
}

static inline BOOL COCB(NSString *key, BOOL def) {
    id v = COCRaw(key);
    return [v isKindOfClass:[NSNumber class]] ? [v boolValue] : def;
}

static inline NSString *COCS(NSString *key, NSString *def) {
    id v = COCRaw(key);
    return [v isKindOfClass:[NSString class]] ? v : def;
}
