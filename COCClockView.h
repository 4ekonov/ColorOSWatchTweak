#import <UIKit/UIKit.h>

@interface COCClockView : UIView
/// Перечитывает настройки и перестраивает виджеты.
- (void)reloadPrefs;
/// Выводит часы из режима покоя: вызывать, когда меняется список уведомлений или показывается экран.
- (void)wake;
/// Подсказка: вид списка уведомлений (чтобы не сканировать всё окно).
+ (void)registerListView:(UIView *)view;
@end
