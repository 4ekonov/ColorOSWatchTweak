#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "OPCCView.h"
#import "OPCCActions.h"
#import "OPCCNotifications.h"

@interface SBControlCenterController : NSObject
+ (id)sharedInstance;
- (void)dismissAnimated:(BOOL)a;
- (void)presentAnimated:(BOOL)a;
- (void)presentAnimated:(BOOL)a completion:(id)c;
- (BOOL)isPresented;
@end
@interface CCUIModularControlCenterOverlayViewController : UIViewController
- (void)opcc_sync;
@end
@interface SpringBoard : UIApplication @end

static const void *kOPCC = &kOPCC;
static BOOL gDismissing = NO;   // идёт закрытие шторки — повторное открытие в этот момент ломало статус-бар
static BOOL gAllowCC = NO;   // YES только в момент, когда шторку открываем мы сами

#pragma mark - диагностика: список методов классов (поможет, если жест не сработает)
static void OPCCDumpNames(void) {
    NSString *path = @"/var/mobile/Documents/OPCC_classes.txt";
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return;
    unsigned n = 0; Class *cl = objc_copyClassList(&n); NSMutableString *o = [NSMutableString string];
    for (unsigned i = 0; i < n; i++) {
        NSString *nm = NSStringFromClass(cl[i]);
        if ([nm hasPrefix:@"NCNotification"] || [nm hasPrefix:@"CSCoverSheet"] || [nm hasPrefix:@"SBCoverSheet"] || [nm hasPrefix:@"CSNotification"]) [o appendFormat:@"%@\n", nm];
    }
    free(cl); [o writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}
static void OPCCDump(void) {
    OPCCDumpNames();
    NSString *path = @"/var/mobile/Documents/OPCC_methods.txt";
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return;
    NSMutableString *o = [NSMutableString string];
    for (NSString *cn in @[@"SBControlCenterController", @"SBSystemGestureManager", @"CCUIModularControlCenterOverlayViewController"]) {
        Class c = NSClassFromString(cn);
        if (!c) { [o appendFormat:@"\n== %@: класса нет\n", cn]; continue; }
        for (int meta = 0; meta < 2; meta++) {
            unsigned n = 0; Method *ms = class_copyMethodList(meta ? object_getClass(c) : c, &n);
            [o appendFormat:@"\n== %@ (%@)\n", cn, meta ? @"class" : @"instance"];
            for (unsigned i = 0; i < n; i++) [o appendFormat:@"%s\n", sel_getName(method_getName(ms[i]))];
            free(ms);
        }
    }
    [o writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

#pragma mark - жест: свайп вниз от правой половины верхнего края
@interface SBCoverSheetPresentationManager : NSObject
+ (id)sharedInstance; - (BOOL)isPresented; - (void)setCoverSheetPresented:(BOOL)p animated:(BOOL)a withCompletion:(id)c;
@end
@interface SBLockScreenManager : NSObject
+ (id)sharedInstance; - (BOOL)isUILocked;
@end

static NSHashTable *gCoverGRs;
static UIWindow *gStrip, *gStripN;

static void OPCCLog(NSString *line) {
    static int n = 0; if (n++ > 200) return;
    NSString *path = @"/var/mobile/Documents/OPCC_gestures.txt";
    NSString *old = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] ?: @"";
    [[old stringByAppendingFormat:@"%@\n", line] writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

// Собираем ВСЕ живые системные recognizer'ы SpringBoard (по окнам и по менеджеру жестов), а не только пойманные при создании
static void OPCCCollect(UIView *v, NSMutableArray *out) {
    for (UIGestureRecognizer *g in v.gestureRecognizers) [out addObject:g];
    for (UIView *s in v.subviews) OPCCCollect(s, out);
}
static BOOL OPCCIsSystemGR(UIGestureRecognizer *g) {
    NSString *gc = NSStringFromClass([g class]);
    NSString *dc = g.delegate ? NSStringFromClass([g.delegate class]) : @"";
    return [gc hasPrefix:@"SB"] || [gc hasPrefix:@"_SB"] || [gc hasPrefix:@"FB"] || [gc containsString:@"SystemGesture"] || [gc containsString:@"CoverSheet"]
        || [dc hasPrefix:@"SB"] || [dc containsString:@"CoverSheet"] || [dc containsString:@"SystemGesture"];
}
static void OPCCScan(void) {
    if (!gCoverGRs) gCoverGRs = [NSHashTable weakObjectsHashTable];
    NSMutableArray *all = [NSMutableArray array];
    NSArray *wins = nil; SEL ws = NSSelectorFromString(@"allWindowsIncludingInternalWindows:onlyVisibleWindows:");
    if ([UIWindow respondsToSelector:ws]) wins = ((id (*)(id, SEL, BOOL, BOOL))objc_msgSend)([UIWindow class], ws, YES, NO);
    if (!wins) wins = [UIApplication sharedApplication].windows;
    for (UIWindow *w in wins) { if (w == gStrip || w == gStripN) continue; OPCCCollect(w, all); }
    @try {
        id mgrCls = (id)objc_getClass("SBSystemGestureManager"); SEL mdm = NSSelectorFromString(@"mainDisplayManager");
        id mgr = [mgrCls respondsToSelector:mdm] ? ((id (*)(id, SEL))objc_msgSend)(mgrCls, mdm) : nil;
        for (NSString *k in @[@"gestureRecognizers", @"_gestureRecognizers", @"allGestureRecognizers"]) {
            @try { id arr = [mgr valueForKey:k]; if ([arr isKindOfClass:[NSArray class]]) [all addObjectsFromArray:arr]; else if ([arr isKindOfClass:[NSSet class]]) [all addObjectsFromArray:[arr allObjects]]; } @catch (__unused NSException *e) {}
        }
    } @catch (__unused NSException *e) {}
    int found = 0;
    for (UIGestureRecognizer *g in all) {
        if (![g isKindOfClass:[UIGestureRecognizer class]] || !OPCCIsSystemGR(g)) continue;
        if (![gCoverGRs containsObject:g]) {
            [gCoverGRs addObject:g];
            OPCCLog([NSString stringWithFormat:@"GR %@ | delegate=%@ | enabled=%d", NSStringFromClass([g class]), g.delegate ? NSStringFromClass([g.delegate class]) : @"-", g.enabled]);
        }
        found++;
    }
    OPCCLog([NSString stringWithFormat:@"scan: окон=%lu всего recognizer=%lu системных=%d", (unsigned long)wins.count, (unsigned long)all.count, found]);
}
static void OPCCSuppressCover(BOOL on) { for (UIGestureRecognizer *g in gCoverGRs.allObjects) g.enabled = !on; }

static UILabel *gStatus;
static void OPCCStatus(NSString *s) { OPCCLog(s); if (gStatus) gStatus.text = s; }
static BOOL OPCCLocked(void) { id l = [objc_getClass("SBLockScreenManager") sharedInstance]; return [l respondsToSelector:@selector(isUILocked)] ? [l isUILocked] : YES; }
static BOOL OPCCCoverPresented(void) { id c = [objc_getClass("SBCoverSheetPresentationManager") sharedInstance]; return [c respondsToSelector:@selector(isPresented)] && [c isPresented]; }
static BOOL OPCCCCPresented(void) { id c = [objc_getClass("SBControlCenterController") sharedInstance]; return [c respondsToSelector:@selector(isPresented)] && [c isPresented]; }

static void OPCCPresentCC(void) {
    if (gDismissing) { OPCCStatus(@"ждём закрытия"); return; }
    if (OPCCCCPresented()) return;
    id cc = [objc_getClass("SBControlCenterController") sharedInstance];
    gAllowCC = YES;
    if ([cc respondsToSelector:@selector(presentAnimated:completion:)]) [cc presentAnimated:YES completion:nil];
    else if ([cc respondsToSelector:@selector(presentAnimated:)]) [cc presentAnimated:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ gAllowCC = NO; });
}
static void OPCCDismissCover(void) {
    id cs = [objc_getClass("SBCoverSheetPresentationManager") sharedInstance];
    if ([cs respondsToSelector:@selector(setCoverSheetPresented:animated:withCompletion:)]) [cs setCoverSheetPresented:NO animated:NO withCompletion:nil];
}
// Когда палец отпущен: если система всё же открыла уведомления — закрываем их и открываем свою шторку
static void OPCCRescue(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BOOL nc = OPCCCoverPresented(), cc = OPCCCCPresented(), lk = OPCCLocked();
        OPCCStatus([NSString stringWithFormat:@"NC=%d CC=%d lock=%d", nc, cc, lk]);
        if (cc) return;
        if (nc && !lk) {
            OPCCDismissCover();
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.12 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ OPCCPresentCC(); OPCCStatus(@"NC закрыт, открываем CC"); });
        } else { OPCCPresentCC(); OPCCStatus(@"открываем CC"); }
    });
}

static NSInteger OPCCEdgesOf(UIGestureRecognizer *g) {
    SEL s = NSSelectorFromString(@"edges");
    @try { if ([g respondsToSelector:s]) return (NSInteger)((NSUInteger (*)(id, SEL))objc_msgSend)(g, s); } @catch (__unused NSException *e) {}
    @try { id v = [g valueForKey:@"edges"]; if ([v respondsToSelector:@selector(integerValue)]) return [v integerValue]; } @catch (__unused NSException *e) {}
    return -1;
}
static void OPCCEnforceTop(void) {
    if (![OPCCActions boolPref:@"customNotifications" def:YES]) return;
    if (![OPCCActions bottomMode] && ![OPCCActions boolPref:@"topRightGesture" def:YES]) return;
    NSMutableArray *all = [NSMutableArray array];
    NSArray *wins = nil; SEL ws = NSSelectorFromString(@"allWindowsIncludingInternalWindows:onlyVisibleWindows:");
    if ([UIWindow respondsToSelector:ws]) wins = ((id (*)(id, SEL, BOOL, BOOL))objc_msgSend)([UIWindow class], ws, YES, NO);
    if (!wins) wins = [UIApplication sharedApplication].windows;
    for (UIWindow *w in wins) { if (w == gStrip || w == gStripN) continue; OPCCCollect(w, all); }
    @try {
        id mgrCls = (id)objc_getClass("SBSystemGestureManager"); SEL mdm = NSSelectorFromString(@"mainDisplayManager");
        id mgr = [mgrCls respondsToSelector:mdm] ? ((id (*)(id, SEL))objc_msgSend)(mgrCls, mdm) : nil;
        for (NSString *k in @[@"gestureRecognizers", @"_gestureRecognizers", @"allGestureRecognizers"]) {
            @try { id arr = [mgr valueForKey:k]; if ([arr isKindOfClass:[NSArray class]]) [all addObjectsFromArray:arr]; else if ([arr isKindOfClass:[NSSet class]]) [all addObjectsFromArray:[arr allObjects]]; } @catch (__unused NSException *e) {}
        }
    } @catch (__unused NSException *e) {}
    for (UIGestureRecognizer *g in all) {
        if (![g isKindOfClass:[UIGestureRecognizer class]] || !OPCCIsSystemGR(g)) continue;
        if (OPCCEdgesOf(g) == (NSInteger)UIRectEdgeTop && g.enabled) {
            g.enabled = NO;
            OPCCLog([NSString stringWithFormat:@"ОТКЛЮЧЁН верхний жест: %@ | delegate=%@", NSStringFromClass([g class]), g.delegate ? NSStringFromClass([g.delegate class]) : @"-"]);
        }
    }
}

// Стандартная шторка уведомлений живёт в окне CoverSheet — на время нашей панели делаем это окно невидимым
static void OPCCHideCoverWindows(BOOL hide) {
    NSArray *wins = nil; SEL ws = NSSelectorFromString(@"allWindowsIncludingInternalWindows:onlyVisibleWindows:");
    if ([UIWindow respondsToSelector:ws]) wins = ((id (*)(id, SEL, BOOL, BOOL))objc_msgSend)([UIWindow class], ws, YES, NO);
    if (!wins) wins = [UIApplication sharedApplication].windows;
    for (UIWindow *w in wins) {
        if (w == gStrip || w == gStripN) continue;
        NSString *c = NSStringFromClass([w class]), *rc = w.rootViewController ? NSStringFromClass([w.rootViewController class]) : @"";
        if ([c containsString:@"CoverSheet"] || [rc containsString:@"CoverSheet"]) { CGFloat target = hide ? 0 : 1; if (w.alpha != target) { w.alpha = target; OPCCLog([NSString stringWithFormat:@"cover window %@ alpha=%.0f", c, target]); } }
    }
}
static void OPCCShowNotifs(void) {
    if (OPCCLocked() || [OPCCNotifPanel isShown]) return;      // на экране блокировки остаётся стандартная панель
    OPCCHideCoverWindows(YES);
    [OPCCNotifPanel show]; OPCCStatus(@"панель уведомлений");
}
static void OPCCRescueNotifs(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (OPCCLocked()) return;
        BOOL nc = OPCCCoverPresented();
        OPCCStatus([NSString stringWithFormat:@"NC=%d panel=%d", nc, [OPCCNotifPanel isShown]]);
        if (nc) OPCCDismissCover();
        if (![OPCCNotifPanel isShown]) { OPCCHideCoverWindows(YES); [OPCCNotifPanel show]; }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ OPCCHideCoverWindows(NO); });
    });
}

@interface OPCCStripView : UIView { CGPoint _start; BOOL _fired; }
@property (nonatomic) NSInteger kind;   // 0 — Центр управления, 1 — уведомления
@end
@implementation OPCCStripView
- (void)flash:(BOOL)on {
    if (![OPCCActions boolPref:@"debugStrip" def:YES]) { self.backgroundColor = [UIColor clearColor]; return; }
    self.backgroundColor = on ? [UIColor colorWithRed:1 green:0 blue:0 alpha:0.45] : [UIColor colorWithRed:1 green:0 blue:0 alpha:0.12];
}
- (void)touchesBegan:(NSSet *)ts withEvent:(UIEvent *)e {
    _start = [[ts anyObject] locationInView:nil]; _fired = NO;
    [self flash:YES]; OPCCLog([NSString stringWithFormat:@"touchesBegan x=%.0f y=%.0f", _start.x, _start.y]);
    if (_kind == 1 && OPCCLocked()) { [super touchesBegan:ts withEvent:e]; return; }   // экран блокировки: пусть работает стандартная панель
    OPCCEnforceTop();
    [super touchesBegan:ts withEvent:e];
}
- (void)touchesMoved:(NSSet *)ts withEvent:(UIEvent *)e {
    [super touchesMoved:ts withEvent:e];
    CGPoint p = [[ts anyObject] locationInView:nil]; CGFloat dy = p.y - _start.y, dx = p.x - _start.x;
    if (!_fired && dy > 6 && dy > fabs(dx)) {
        if (_kind == 1 && OPCCLocked()) return;
        _fired = YES;
        if (_kind == 1) OPCCShowNotifs(); else { OPCCPresentCC(); OPCCStatus(@"свайп: просим CC"); }
    }
}
- (void)finish { [self flash:NO]; }
- (void)touchesEnded:(NSSet *)ts withEvent:(UIEvent *)e { [super touchesEnded:ts withEvent:e]; if (_fired) { if (_kind == 1) OPCCRescueNotifs(); else OPCCRescue(); } [self performSelector:@selector(finish) withObject:nil afterDelay:0.3]; }
- (void)touchesCancelled:(NSSet *)ts withEvent:(UIEvent *)e {
    OPCCLog(@"touchesCancelled (система забрала касание)");
    CGPoint p = [[ts anyObject] locationInView:nil];
    if (!_fired && p.y - _start.y > 3 && !(_kind == 1 && OPCCLocked())) { _fired = YES; if (_kind == 1) OPCCShowNotifs(); else OPCCPresentCC(); }
    if (_fired) { if (_kind == 1) OPCCRescueNotifs(); else OPCCRescue(); }   // система отобрала касание — доводим дело до конца сами
    [super touchesCancelled:ts withEvent:e]; [self performSelector:@selector(finish) withObject:nil afterDelay:0.3];
}
@end

static UIWindow *OPCCMakeStrip(CGRect f, NSInteger kind, BOOL label) {
    UIWindow *w = [[UIWindow alloc] initWithFrame:f];
    w.windowLevel = 100000; w.backgroundColor = [UIColor clearColor];
    UIViewController *vc = [UIViewController new];
    OPCCStripView *sv = [[OPCCStripView alloc] initWithFrame:w.bounds]; sv.kind = kind; vc.view = sv; [sv flash:NO]; w.rootViewController = vc;
    if (label && [OPCCActions boolPref:@"debugStrip" def:YES]) {
        gStatus = [[UILabel alloc] initWithFrame:CGRectInset(sv.bounds, 4, 0)]; gStatus.font = [UIFont boldSystemFontOfSize:8]; gStatus.textColor = [UIColor whiteColor];
        gStatus.numberOfLines = 2; gStatus.userInteractionEnabled = NO; gStatus.text = @"OPCC готов"; [sv addSubview:gStatus];
    }
    w.hidden = NO; return w;
}
static void OPCCInstallStrips(void) {
    CGRect sb = [UIScreen mainScreen].bounds; CGFloat W = sb.size.width; BOOL bottom = [OPCCActions bottomMode];
    // Центр управления: на iPhone с чёлкой — сверху справа; на iPhone с кнопкой остаётся стандартный жест снизу
    if (!gStrip && !bottom && [OPCCActions boolPref:@"topRightGesture" def:YES]) gStrip = OPCCMakeStrip(CGRectMake(W * 0.5, 0, W * 0.5, 28), 0, YES);
    // Уведомления: сверху слева (на iPhone с кнопкой — по всей ширине)
    if (!gStripN && [OPCCActions boolPref:@"customNotifications" def:YES]) gStripN = OPCCMakeStrip(bottom ? CGRectMake(0, 0, W, 28) : CGRectMake(0, 0, W * 0.5, 28), 1, bottom);
    OPCCLog(@"полосы жестов установлены");
    [OPCCNotifPanel setOnHide:^{ OPCCHideCoverWindows(NO); }];
    OPCCEnforceTop();
    [NSTimer scheduledTimerWithTimeInterval:2.0 repeats:YES block:^(NSTimer *tm) {       // жесты могут пересоздаваться системой — применяем снова
        OPCCEnforceTop();
        if (![OPCCNotifPanel isShown]) OPCCHideCoverWindows(NO);                          // страховка: окно шторки не должно остаться невидимым
    }];
}

#pragma mark - сбор уведомлений для своей панели
%hook NCNotificationDispatcher
- (void)postNotificationWithRequest:(id)r { %orig; [OPCCNotifStore post:r]; }
- (void)modifyNotificationWithRequest:(id)r { %orig; [OPCCNotifStore post:r]; }
- (void)withdrawNotificationWithRequest:(id)r { %orig; [OPCCNotifStore withdraw:r]; }
%end
%hook NCNotificationMasterList
- (void)insertNotificationRequest:(id)r { %orig; [OPCCNotifStore post:r]; }
- (void)modifyNotificationRequest:(id)r { %orig; [OPCCNotifStore post:r]; }
- (void)removeNotificationRequest:(id)r { %orig; [OPCCNotifStore withdraw:r]; }
%end

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)app {
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{ OPCCInstallStrips(); OPCCDump(); });
}
%end

#pragma mark - отключение стандартного жеста Центра управления (снизу)
%hook SBControlCenterController
- (BOOL)_shouldAllowControlCenterGesture {
    if (gDismissing) return NO;
    if (![OPCCActions bottomMode] && !gAllowCC && [OPCCActions boolPref:@"disableBottomGesture" def:YES]) return NO;
    return %orig;
}
%end

#pragma mark - стиль уведомлений (тёмные полупрозрачные скруглённые карточки)
@interface NCNotificationShortLookView : UIView @end
@interface NCNotificationLongLookView : UIView @end
static void OPCCStyleCard(UIView *v) {
    if ([OPCCActions boolPref:@"customNotifications" def:YES] || ![OPCCActions boolPref:@"styleNotifications" def:YES]) return;
    v.layer.cornerRadius = 22; v.layer.cornerCurve = kCACornerCurveContinuous;
    v.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.6];
    for (UIView *s in v.subviews) if ([NSStringFromClass([s class]) containsString:@"MaterialView"]) s.hidden = YES;
}
%hook NCNotificationShortLookView
- (void)layoutSubviews { %orig; OPCCStyleCard((UIView *)self); }
%end
%hook NCNotificationLongLookView
- (void)layoutSubviews { %orig; OPCCStyleCard((UIView *)self); }
%end

#pragma mark - переключатель звука
%hook SBRingerControl
- (id)init { id r = %orig; OPCCRingerControl = r; return r; }
- (BOOL)isRingerMuted { OPCCRingerControl = self; return %orig; }
- (void)setRingerMuted:(BOOL)m { OPCCRingerControl = self; %orig; }
%end

#pragma mark - подмена Центра управления
%hook CCUIModularControlCenterOverlayViewController

- (void)viewDidLoad {
    %orig;
    __weak UIViewController *weakSelf = self;
    OPCCView *v = [[OPCCView alloc] initWithFrame:self.view.bounds];
    v.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    v.dismissBlock = ^{
        gDismissing = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ gDismissing = NO; });   // страховка
        id cc = [objc_getClass("SBControlCenterController") sharedInstance];
        // наша шторка к этому моменту уже уехала, поэтому системное закрытие делаем мгновенным — так окно «ожидания» минимально
        if ([cc respondsToSelector:@selector(dismissAnimated:)]) [cc dismissAnimated:NO];
        else [weakSelf dismissViewControllerAnimated:YES completion:nil];
    };
    v.presentBlock = ^(UIViewController *vc) { [weakSelf presentViewController:vc animated:YES completion:nil]; };
    objc_setAssociatedObject(self, kOPCC, v, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self.view addSubview:v];
}

- (void)viewDidLayoutSubviews { %orig; [self opcc_sync]; }

%new
- (void)opcc_sync {
    OPCCView *v = objc_getAssociatedObject(self, kOPCC);
    if (!v) return;
    for (UIView *s in self.view.subviews) if (s != v) s.hidden = YES;   // прячем оригинальный iOS CC
    self.view.backgroundColor = [UIColor clearColor];
    UIView *host = v.superview ?: self.view;
    v.frame = host.bounds;
    [host bringSubviewToFront:v];
    // Системные тап-жесты «закрыть по касанию» срабатывали на наших кнопках — отключаем их
    for (UIView *h in @[self.view, self.view.superview ?: self.view]) {
        for (UIGestureRecognizer *g in h.gestureRecognizers)
            if ([g isKindOfClass:[UITapGestureRecognizer class]]) g.enabled = NO;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    OPCCView *v = objc_getAssociatedObject(self, kOPCC);
    UIWindow *w = self.view.window;
    if (w && v.superview != w) {            // кладём нашу шторку прямо в окно, чтобы она не ехала снизу вместе со стоковой
        [w addSubview:v]; v.frame = w.bounds;
    }
    [self opcc_sync];
    [v present];
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    if (self.presentedViewController) return;     // поверх показано другое окно — шторку не закрываем
    gDismissing = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ gDismissing = NO; });   // страховка, если закрытие отменили
    [(OPCCView *)objc_getAssociatedObject(self, kOPCC) closeForSystemDismiss];
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    gDismissing = NO;
    OPCCView *v = objc_getAssociatedObject(self, kOPCC);
    [v stop];
    if (v.superview != self.view) { [self.view addSubview:v]; v.frame = self.view.bounds; }
}

%end
