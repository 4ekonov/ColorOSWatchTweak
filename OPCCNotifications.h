#import <UIKit/UIKit.h>
extern NSString *const OPCCNotifsChanged;

@interface OPCCNotif : NSObject
@property (nonatomic, copy) NSString *ident, *bundleID, *appName, *title, *message;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) id request;
@end

// Хранилище уведомлений: наполняется хуками в Tweak.xm
@interface OPCCNotifStore : NSObject
+ (NSArray<OPCCNotif *> *)all;
+ (void)post:(id)request;
+ (void)withdraw:(id)request;
+ (void)clear:(OPCCNotif *)n;
+ (void)clearAll;
@end

// Своя панель уведомлений в стиле ColorOS
@interface OPCCNotifPanel : NSObject
+ (void)show;
+ (void)hide;
+ (BOOL)isShown;
+ (void)setOnHide:(void (^)(void))block;   // вызывается, когда панель полностью скрыта
@end
