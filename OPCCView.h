#import <UIKit/UIKit.h>
@interface OPCCView : UIView
@property (nonatomic, copy) void (^dismissBlock)(void);
@property (nonatomic, copy) void (^presentBlock)(UIViewController *vc);
- (void)closeForSystemDismiss;   // анимация закрытия, когда закрывает система
- (void)present;      // анимация выдвижения шторки
- (void)stop;         // остановить таймеры
- (void)reloadButtons;
@end
