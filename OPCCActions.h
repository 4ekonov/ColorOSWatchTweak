#import <UIKit/UIKit.h>
extern NSString *const OPCCDismissNotification;
extern NSString *const OPCCReloadNotification;
extern __weak id OPCCRingerControl;   // заполняется хуком SBRingerControl в Tweak.xm

@interface OPCCActions : NSObject
// настройки
+ (void)syncPrefs;
+ (CGFloat)shadeScale;    // масштаб шторки
+ (CGFloat)buttonScale;   // размер круглых кнопок
+ (BOOL)showLabels;       // подписи под кнопками
+ (BOOL)shadeScaleIsSet;  // задан ли масштаб вручную (иначе подбирается под экран)
+ (BOOL)boolPref:(NSString *)key def:(BOOL)d;
+ (BOOL)isHomeButtonDevice;   // iPhone с кнопкой «Домой» (определяется автоматически)
+ (BOOL)bottomMode;           // шторка выезжает снизу (авто для iPhone с кнопкой, можно переопределить в настройках)
// каталог кнопок
+ (NSArray<NSString *> *)allIDs;
+ (NSArray<NSString *> *)defaultIDs;
+ (NSArray<NSString *> *)activeIDs;
+ (void)saveActiveIDs:(NSArray<NSString *> *)ids;
+ (NSString *)titleFor:(NSString *)ident;
+ (NSString *)symbolFor:(NSString *)ident;
+ (BOOL)isDimmed:(NSString *)ident;
+ (BOOL)stateFor:(NSString *)ident;                       // быстрое чтение из кэша
+ (void)refreshStates:(void (^)(void))done;               // тяжёлые состояния читаются в фоне
+ (void)tap:(NSString *)ident;
+ (void)longPress:(NSString *)ident;
// ползунки
+ (float)brightness;  + (void)setBrightness:(float)v;
+ (float)volume;      + (void)setVolume:(float)v;
// плитки
+ (BOOL)wifiOn;  + (NSString *)wifiName;  + (void)setWifi:(BOOL)on;
+ (BOOL)btOn;    + (void)setBT:(BOOL)on;
+ (NSInteger)ringerMode;                 // 0 звонок, 1 вибро, 2 без звука
+ (void)setRingerMode:(NSInteger)m;
// запуск приложений / настроек (сами плавно закрывают шторку)
+ (void)launchAppNow:(NSString *)bundleID;   // без закрытия шторки (для панели уведомлений)
+ (void)openApp:(NSString *)bundleID;
+ (void)openSettingsURL:(NSString *)url;
@end
