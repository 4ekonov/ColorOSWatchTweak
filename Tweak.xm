#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "Prefs.h"
#import "COCClockView.h"

#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

@interface CSCoverSheetViewController : UIViewController
@end
@interface CSMainPageContentViewController : UIViewController
@end
@interface CSCombinedListViewController : UIViewController
@end

static NSHashTable *COCClocks;   // наши view часов
static NSHashTable *COCHidden;   // скрытые штатные view часов
static NSHashTable *COCLists;    // контроллеры списка уведомлений

static BOOL COCEnabled(void) {
    return COCB(@"enabled", YES);
}

#pragma mark - Установка наших часов

static void COCInstall(UIView *host) {
    if (!host) return;
    for (UIView *v in host.subviews) {
        if ([v isKindOfClass:[COCClockView class]]) return;
    }
    COCClockView *clock = [[COCClockView alloc] initWithFrame:host.bounds];
    clock.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    // Снизу, чтобы уведомления рисовались поверх часов при прокрутке
    [host insertSubview:clock atIndex:0];
    [COCClocks addObject:clock];
}

%group MainPage
%hook CSMainPageContentViewController
- (void)viewDidLoad {
    %orig;
    COCInstall(self.view);
}
%end
%end

// Запасной вариант, если класса главной страницы нет
%group Fallback
%hook CSCoverSheetViewController
- (void)viewDidLoad {
    %orig;
    COCInstall(self.view);
}
%end
%end

#pragma mark - Отступы для уведомлений

%hook CSCombinedListViewController
- (void)viewDidLoad {
    %orig;
    [COCLists addObject:self];
}
- (UIEdgeInsets)_listViewDefaultContentInsets {
    UIEdgeInsets i = %orig;
    if (COCEnabled()) {
        i.top += COCF(@"notifTop", 0);
        i.bottom += COCF(@"notifBottom", 0);
    }
    return i;
}
%end

#pragma mark - Скрытие штатных часов

// Подменяем layoutSubviews у штатных view времени/даты. Если у класса нет своего
// layoutSubviews — метод добавляется только этому классу (UIView не трогаем).
static void COCHideStock(NSString *className) {
    Class c = NSClassFromString(className);
    if (!c) return;
    SEL sel = @selector(layoutSubviews);
    Method m = class_getInstanceMethod(c, sel);
    if (!m) return;
    IMP orig = method_getImplementation(m);
    IMP imp = imp_implementationWithBlock(^(UIView *s) {
        ((void (*)(id, SEL))orig)(s, sel);
        if (COCEnabled() && COCB(@"hideStock", YES)) {
            s.hidden = YES;
            [COCHidden addObject:s];
        } else if ([COCHidden containsObject:s]) {
            s.hidden = NO;
            [COCHidden removeObject:s];
        }
    });
    if (!class_addMethod(c, sel, imp, method_getTypeEncoding(m))) {
        method_setImplementation(m, imp);
    }
}

#pragma mark - Реакция на изменение настроек

static void COCPrefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name,
                            const void *object, CFDictionaryRef userInfo) {
    CFPreferencesAppSynchronize((__bridge CFStringRef)COC_DOMAIN);
    dispatch_async(dispatch_get_main_queue(), ^{
        for (COCClockView *v in COCClocks.allObjects) [v reloadPrefs];
        for (UIView *v in COCHidden.allObjects) [v setNeedsLayout];
        for (UIViewController *vc in COCLists.allObjects) {
            SEL s = NSSelectorFromString(@"_updateListViewContentInset");
            if ([vc respondsToSelector:s]) [vc performSelector:s];
            [vc.view setNeedsLayout];
        }
    });
}

%ctor {
    @autoreleasepool {
        if (![[NSProcessInfo processInfo].processName isEqualToString:@"SpringBoard"]) return;

        COCClocks = [NSHashTable weakObjectsHashTable];
        COCHidden = [NSHashTable weakObjectsHashTable];
        COCLists  = [NSHashTable weakObjectsHashTable];

        %init;
        if (NSClassFromString(@"CSMainPageContentViewController")) {
            %init(MainPage);
        } else {
            %init(Fallback);
        }

        // Кандидаты штатных часов/даты (iOS 15; на iOS 16/17 список уточняется по логам)
        NSArray *stock = @[ @"SBFLockScreenDateView",
                            @"SBFLockScreenDateSubtitleView",
                            @"CSProminentTimeView",
                            @"CSProminentSubtitleDateView" ];
        for (NSString *n in stock) COCHideStock(n);

        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
                                        COCPrefsChanged, CFSTR(COC_NOTIFY), NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
    }
}
