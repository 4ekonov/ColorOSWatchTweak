#import "OPCCNotifications.h"
#import <objc/runtime.h>
#import <objc/message.h>

NSString *const OPCCNotifsChanged = @"OPCCNotifsChanged";

@interface LSApplicationProxy : NSObject
+ (id)applicationProxyForIdentifier:(NSString *)i;
- (NSString *)localizedName;
@end

static id KV(id o, NSString *k) { if (!o) return nil; @try { return [o valueForKey:k]; } @catch (__unused NSException *e) { return nil; } }
static NSString *KS(id o, NSString *k) {
    id v = KV(o, k);
    if ([v isKindOfClass:[NSString class]]) return v;
    if ([v isKindOfClass:[NSAttributedString class]]) return [(NSAttributedString *)v string];
    return nil;
}
static void NLog(NSString *s) {
    static int n = 0; if (n++ > 80) return;
    NSString *path = @"/var/mobile/Documents/OPCC_notifs.txt";
    NSString *old = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] ?: @"";
    [[old stringByAppendingFormat:@"%@\n", s] writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@implementation OPCCNotif
@end

@implementation OPCCNotifStore
+ (NSMutableArray *)items { static NSMutableArray *a; static dispatch_once_t t; dispatch_once(&t, ^{ a = [NSMutableArray array]; }); return a; }
+ (NSArray *)all { @synchronized (self) { return [[self items] copy]; } }
+ (void)changed { dispatch_async(dispatch_get_main_queue(), ^{ [[NSNotificationCenter defaultCenter] postNotificationName:OPCCNotifsChanged object:nil]; }); }

+ (NSString *)nameForBundle:(NSString *)b {
    static NSMutableDictionary *cache; if (!cache) cache = [NSMutableDictionary dictionary];
    if (!b.length) return @"";
    NSString *n = cache[b]; if (n) return n;
    @try { n = [[objc_getClass("LSApplicationProxy") applicationProxyForIdentifier:b] localizedName]; } @catch (__unused NSException *e) {}
    if (!n.length) n = b;
    cache[b] = n; return n;
}

+ (void)post:(id)r {
    if (!r) return;
    id content = KV(r, @"content");
    NSString *ident = KS(r, @"notificationIdentifier"); if (!ident.length) ident = [NSString stringWithFormat:@"%p", r];
    NSString *bundle = KS(r, @"sectionIdentifier") ?: @"";
    NSString *title = KS(content, @"title"), *sub = KS(content, @"subtitle"), *msg = KS(content, @"message"), *header = KS(content, @"header");
    if (!title.length) { title = sub; sub = nil; }
    NSString *message = msg ?: @"";
    if (sub.length) message = message.length ? [NSString stringWithFormat:@"%@\n%@", sub, message] : sub;
    if (!title.length && !message.length) return;
    id d = KV(r, @"timestamp"); if (![d isKindOfClass:[NSDate class]]) d = KV(content, @"date"); if (![d isKindOfClass:[NSDate class]]) d = [NSDate date];

    OPCCNotif *n = [OPCCNotif new];
    n.ident = ident; n.bundleID = bundle; n.title = title ?: @""; n.message = message; n.date = d; n.request = r;
    n.appName = header.length ? header : [self nameForBundle:bundle];
    @synchronized (self) {
        NSMutableArray *a = [self items]; NSUInteger idx = NSNotFound;
        for (NSUInteger i = 0; i < a.count; i++) if ([((OPCCNotif *)a[i]).ident isEqualToString:ident]) { idx = i; break; }
        if (idx != NSNotFound) a[idx] = n; else [a addObject:n];
        [a sortUsingComparator:^NSComparisonResult(OPCCNotif *x, OPCCNotif *y) { return [y.date compare:x.date]; }];
    }
    NLog([NSString stringWithFormat:@"+ %@ | %@ | %@ | %@", bundle, n.appName, n.title, n.message]);
    [self changed];
}
+ (void)withdraw:(id)r {
    NSString *ident = KS(r, @"notificationIdentifier"); if (!ident.length) return;
    @synchronized (self) { NSMutableArray *a = [self items]; for (NSInteger i = (NSInteger)a.count - 1; i >= 0; i--) if ([((OPCCNotif *)a[i]).ident isEqualToString:ident]) [a removeObjectAtIndex:i]; }
    [self changed];
}

// Убираем уведомление и в самой системе (через её действие «очистить»), иначе оно вернётся после респринга
+ (void)systemClear:(id)req {
    @try {
        id act = KV(req, @"clearAction"), runner = KV(act, @"actionRunner");
        SEL s = NSSelectorFromString(@"executeAction:fromOrigin:endpoint:withParameters:completion:");
        if (act && runner && [runner respondsToSelector:s]) { ((void (*)(id, SEL, id, id, id, id, id))objc_msgSend)(runner, s, act, nil, nil, nil, nil); NLog(@"clear: через clearAction"); return; }
        NLog(@"clear: clearAction недоступен");
    } @catch (__unused NSException *e) { NLog(@"clear: исключение"); }
}
+ (void)clear:(OPCCNotif *)n {
    @synchronized (self) { [[self items] removeObject:n]; }
    [self systemClear:n.request]; [self changed];
}
+ (void)clearAll {
    NSArray *all = [self all];
    for (OPCCNotif *n in all) [self systemClear:n.request];
    @synchronized (self) { [[self items] removeAllObjects]; }
    [self changed];
}
@end
