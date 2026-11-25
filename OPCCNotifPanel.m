#import "OPCCNotifications.h"
#import "OPCCActions.h"
#import <objc/message.h>

#define W_(w,a) [UIColor colorWithWhite:(w) alpha:(a)]

static UIImage *NSym(NSString *n, CGFloat pt, UIImageSymbolWeight w) {
    return [UIImage systemImageNamed:n withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:pt weight:w]];
}
static void Hap(void) { [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred]; }
static NSString *RelTime(NSDate *d) {
    NSInteger s = (NSInteger)(-[d timeIntervalSinceNow]); if (s < 0) s = 0;
    if (s < 60) return @"сейчас";
    if (s < 3600) return [NSString stringWithFormat:@"%ld мин. назад", (long)(s / 60)];
    if (s < 86400) return [NSString stringWithFormat:@"%ld ч. назад", (long)(s / 3600)];
    return [NSString stringWithFormat:@"%ld дн. назад", (long)(s / 86400)];
}
static UIImage *AppIcon(NSString *b) {
    SEL s = NSSelectorFromString(@"_applicationIconImageForBundleIdentifier:format:scale:");
    if (!b.length || ![UIImage respondsToSelector:s]) return nil;
    @try { return ((UIImage *(*)(id, SEL, id, int, double))objc_msgSend)([UIImage class], s, b, 0, [UIScreen mainScreen].scale); } @catch (__unused NSException *e) { return nil; }
}

#pragma mark - кнопка с эффектом нажатия
@interface OPCCNBtn : UIControl @end
@implementation OPCCNBtn
- (void)setHighlighted:(BOOL)h {
    [super setHighlighted:h];
    [UIView animateWithDuration:h ? 0.12 : 0.45 delay:0 usingSpringWithDamping:h ? 1 : 0.5 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
        animations:^{ self.transform = h ? CGAffineTransformMakeScale(0.88, 0.88) : CGAffineTransformIdentity; } completion:nil];
}
@end

#pragma mark - карточка уведомления
@interface OPCCNotifCard : UIControl
@property (nonatomic, strong) NSArray<OPCCNotif *> *items;
@property (nonatomic) BOOL collapsedGroup, msgExpanded;
@property (nonatomic) NSInteger chevMode;                    // 0 авто (раскрыть текст), 2 — свернуть группу
@property (nonatomic, copy) void (^onTap)(OPCCNotifCard *);
@property (nonatomic, copy) void (^onBadge)(OPCCNotifCard *);
@property (nonatomic, copy) void (^onChevron)(OPCCNotifCard *);
- (instancetype)initWithItems:(NSArray *)items collapsed:(BOOL)g mode:(NSInteger)m;
- (CGFloat)layoutForWidth:(CGFloat)w u:(CGFloat)u;
@end

@implementation OPCCNotifCard {
    UIView *_body, *_peek1, *_peek2; UIImageView *_icon, *_chevIv; UILabel *_app, *_title, *_msg, *_badgeL; OPCCNBtn *_badge, *_chev;
}
- (instancetype)initWithItems:(NSArray *)items collapsed:(BOOL)g mode:(NSInteger)m {
    if ((self = [super initWithFrame:CGRectZero])) {
        _items = items; _collapsedGroup = g; _chevMode = m;
        _peek2 = [UIView new]; _peek2.backgroundColor = W_(0, 0.22); _peek2.userInteractionEnabled = NO; _peek2.hidden = !g; [self addSubview:_peek2];
        _peek1 = [UIView new]; _peek1.backgroundColor = W_(0, 0.30); _peek1.userInteractionEnabled = NO; _peek1.hidden = !g; [self addSubview:_peek1];
        _body = [UIView new]; _body.backgroundColor = W_(0, 0.40); _body.userInteractionEnabled = NO; _body.layer.cornerCurve = kCACornerCurveContinuous; [self addSubview:_body];
        _icon = [UIImageView new]; _icon.clipsToBounds = YES; _icon.contentMode = UIViewContentModeScaleAspectFill; _icon.backgroundColor = W_(1, 0.2); [_body addSubview:_icon];
        _app = [UILabel new]; _app.textColor = W_(1, 0.72); [_body addSubview:_app];
        _title = [UILabel new]; _title.textColor = UIColor.whiteColor; _title.numberOfLines = 1; [_body addSubview:_title];
        _msg = [UILabel new]; _msg.textColor = W_(1, 0.82); [_body addSubview:_msg];
        _badge = [OPCCNBtn new]; _badge.backgroundColor = W_(1, 0.20); _badge.hidden = YES; [self addSubview:_badge];
        _badgeL = [UILabel new]; _badgeL.textColor = UIColor.whiteColor; _badgeL.textAlignment = NSTextAlignmentCenter; _badgeL.userInteractionEnabled = NO; [_badge addSubview:_badgeL];
        _chev = [OPCCNBtn new]; _chev.backgroundColor = W_(1, 0.16); _chev.hidden = YES; [self addSubview:_chev];
        _chevIv = [UIImageView new]; _chevIv.contentMode = UIViewContentModeCenter; _chevIv.tintColor = UIColor.whiteColor; _chevIv.userInteractionEnabled = NO; [_chev addSubview:_chevIv];
        [_badge addTarget:self action:@selector(badgeTap) forControlEvents:UIControlEventTouchUpInside];
        [_chev addTarget:self action:@selector(chevTap) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action:@selector(tap) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}
- (void)tap { if (_onTap) _onTap(self); }
- (void)badgeTap { if (_onBadge) _onBadge(self); }
- (void)chevTap { if (_onChevron) _onChevron(self); }
- (void)setHighlighted:(BOOL)h {
    [super setHighlighted:h];
    [UIView animateWithDuration:h ? 0.12 : 0.4 delay:0 usingSpringWithDamping:h ? 1 : 0.6 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
        animations:^{ self->_body.transform = h ? CGAffineTransformMakeScale(0.985, 0.985) : CGAffineTransformIdentity; } completion:nil];
}
- (CGFloat)heightOf:(NSString *)t font:(UIFont *)f width:(CGFloat)w {
    if (!t.length) return 0;
    return ceil([t boundingRectWithSize:CGSizeMake(w, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: f} context:nil].size.height);
}
- (CGFloat)layoutForWidth:(CGFloat)w u:(CGFloat)u {
    OPCCNotif *n = _items.firstObject; CGFloat pad = 12*u, ic = 16*u, tw = w - 2*pad;
    _body.layer.cornerRadius = 20*u;
    UIImage *img = AppIcon(n.bundleID); _icon.image = img; _icon.layer.cornerRadius = 4*u; _icon.frame = CGRectMake(pad, pad, ic, ic);
    _app.font = [UIFont systemFontOfSize:11*u]; _app.text = [NSString stringWithFormat:@"%@ · %@", n.appName, RelTime(n.date)];
    CGFloat right = 0;
    if (_collapsedGroup) {
        _badgeL.font = [UIFont systemFontOfSize:11*u weight:UIFontWeightMedium]; _badgeL.text = [NSString stringWithFormat:@"%lu", (unsigned long)_items.count];
        CGFloat bw = MAX(24*u, [_badgeL.text sizeWithAttributes:@{NSFontAttributeName: _badgeL.font}].width + 14*u), bh = 18*u;
        _badge.hidden = NO; _badge.frame = CGRectMake(w - pad - bw, pad - 1*u, bw, bh); _badge.layer.cornerRadius = bh/2; _badgeL.frame = _badge.bounds; right = bw + 6*u;
        _chev.hidden = YES;
    } else {
        _badge.hidden = YES;
        UIFont *mf0 = [UIFont systemFontOfSize:12*u];
        BOOL needs = _chevMode == 2 || [self heightOf:n.message font:mf0 width:tw] > mf0.lineHeight * 2 + 1;
        _chev.hidden = !needs;
        if (needs) {
            CGFloat d = 20*u; _chev.frame = CGRectMake(w - pad - d, pad - 2*u, d, d); _chev.layer.cornerRadius = d/2; _chevIv.frame = _chev.bounds;
            BOOL up = (_chevMode == 2) || _msgExpanded;
            _chevIv.image = [NSym(up ? @"chevron.up" : @"chevron.down", 9*u, UIImageSymbolWeightBold) imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]; right = d + 6*u;
        }
    }
    _app.frame = CGRectMake(pad + ic + 6*u, pad, w - 2*pad - ic - 6*u - right, ic);
    UIFont *tf = [UIFont boldSystemFontOfSize:13*u], *mf = [UIFont systemFontOfSize:12*u];
    _title.font = tf; _title.text = n.title; _msg.font = mf; _msg.text = n.message;
    CGFloat y = pad + ic + 6*u, th = n.title.length ? ceil(tf.lineHeight) : 0;
    _title.frame = CGRectMake(pad, y, tw, th); y += th + (th ? 2*u : 0);
    CGFloat full = [self heightOf:n.message font:mf width:tw], two = ceil(mf.lineHeight * 2);
    BOOL expanded = _msgExpanded && !_collapsedGroup;
    _msg.numberOfLines = expanded ? 0 : 2;
    CGFloat mh = expanded ? full : MIN(full, two);
    _msg.frame = CGRectMake(pad, y, tw, mh); y += mh + pad;
    _body.transform = CGAffineTransformIdentity; _body.frame = CGRectMake(0, 0, w, y);
    if (_collapsedGroup) {
        _peek1.frame = CGRectMake(7*u, y - 10*u, w - 14*u, 16*u); _peek1.layer.cornerRadius = 16*u;
        _peek2.frame = CGRectMake(14*u, y - 6*u, w - 28*u, 16*u); _peek2.layer.cornerRadius = 16*u;
        return y + 10*u;
    }
    return y;
}
@end

#pragma mark - главный вид панели
@interface OPCCNotifView : UIView <UIGestureRecognizerDelegate>
- (void)present;
- (void)closeAnimated:(void (^)(void))done;
@end

@implementation OPCCNotifView {
    UIView *_shade, *_bg; UIScrollView *_scroll; UILabel *_dateL, *_emptyL; OPCCNBtn *_bell, *_x;
    NSMutableArray<OPCCNotifCard *> *_cards; NSMutableSet *_expGroups, *_expMsgs;
    UIPanGestureRecognizer *_panGR; UITapGestureRecognizer *_tapGR;
    BOOL _closing, _panActive, _suppress; NSInteger _gen; CGFloat _u;
}
- (instancetype)initWithFrame:(CGRect)f {
    if ((self = [super initWithFrame:f])) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
        _cards = [NSMutableArray array]; _expGroups = [NSMutableSet set]; _expMsgs = [NSMutableSet set]; _u = 1.2;
        _shade = [[UIView alloc] initWithFrame:self.bounds]; _shade.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight; [self addSubview:_shade];
        UIVisualEffectView *fx = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark]];
        UIView *dim = [UIView new]; dim.backgroundColor = W_(0, 0.38); [fx.contentView addSubview:dim]; _bg = fx; [_shade addSubview:_bg];
        _scroll = [UIScrollView new]; _scroll.showsVerticalScrollIndicator = NO; _scroll.bounces = NO; _scroll.delaysContentTouches = NO; _scroll.clipsToBounds = NO; [_shade addSubview:_scroll];
        _dateL = [UILabel new]; _dateL.textColor = UIColor.whiteColor; [_shade addSubview:_dateL];
        _emptyL = [UILabel new]; _emptyL.textColor = W_(1, 0.6); _emptyL.numberOfLines = 0; _emptyL.textAlignment = NSTextAlignmentCenter; _emptyL.font = [UIFont systemFontOfSize:12]; _emptyL.hidden = YES; [_shade addSubview:_emptyL];
        _bell = [OPCCNBtn new]; UIImageView *bi = [[UIImageView alloc] initWithImage:[NSym(@"bell", 17, UIImageSymbolWeightRegular) imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        bi.tintColor = UIColor.whiteColor; bi.contentMode = UIViewContentModeCenter; bi.tag = 9; bi.userInteractionEnabled = NO; [_bell addSubview:bi]; [_shade addSubview:_bell];
        [_bell addTarget:self action:@selector(bellTap) forControlEvents:UIControlEventTouchUpInside];
        _x = [OPCCNBtn new]; _x.backgroundColor = W_(0, 0.42);
        UIImageView *xi = [[UIImageView alloc] initWithImage:[NSym(@"xmark", 15, UIImageSymbolWeightMedium) imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        xi.tintColor = UIColor.whiteColor; xi.contentMode = UIViewContentModeCenter; xi.tag = 9; xi.userInteractionEnabled = NO; [_x addSubview:xi]; [_shade addSubview:_x];
        [_x addTarget:self action:@selector(clearAll) forControlEvents:UIControlEventTouchUpInside];
        UITapGestureRecognizer *tp = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(emptyTap)]; tp.delegate = self; tp.cancelsTouchesInView = NO; [self addGestureRecognizer:tp]; _tapGR = tp;
        UIPanGestureRecognizer *pp = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panClose:)]; pp.delegate = self; pp.cancelsTouchesInView = NO; [self addGestureRecognizer:pp]; _panGR = pp;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storeChanged) name:OPCCNotifsChanged object:nil];
    }
    return self;
}
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
- (void)storeChanged { if (!_suppress && !_closing && !_panActive) [self reload]; }

#pragma mark карточки
- (OPCCNotifCard *)makeCard:(NSArray *)items collapsed:(BOOL)g mode:(NSInteger)m {
    OPCCNotifCard *c = [[OPCCNotifCard alloc] initWithItems:items collapsed:g mode:m];
    c.msgExpanded = [_expMsgs containsObject:((OPCCNotif *)items.firstObject).ident];
    __weak OPCCNotifView *ws = self;
    c.onTap = ^(OPCCNotifCard *k) { [ws cardTap:k]; };
    c.onBadge = ^(OPCCNotifCard *k) { [ws expandGroup:k]; };
    c.onChevron = ^(OPCCNotifCard *k) { [ws chevron:k]; };
    UIPanGestureRecognizer *p = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(cardPan:)]; p.delegate = self; [c addGestureRecognizer:p];
    return c;
}
- (void)reload {
    for (UIView *c in _cards) [c removeFromSuperview]; [_cards removeAllObjects];
    NSMutableArray *order = [NSMutableArray array]; NSMutableDictionary *map = [NSMutableDictionary dictionary];
    for (OPCCNotif *n in [OPCCNotifStore all]) { NSString *b = n.bundleID ?: @""; if (!map[b]) { map[b] = [NSMutableArray array]; [order addObject:b]; } [map[b] addObject:n]; }
    for (NSString *b in order) {
        NSArray *items = map[b];
        if (items.count > 1 && ![_expGroups containsObject:b]) [_cards addObject:[self makeCard:items collapsed:YES mode:0]];
        else for (NSUInteger i = 0; i < items.count; i++) [_cards addObject:[self makeCard:@[items[i]] collapsed:NO mode:(items.count > 1 && i == 0) ? 2 : 0]];
    }
    for (UIView *c in _cards) [_scroll addSubview:c];
    _emptyL.hidden = _cards.count > 0 || ![OPCCActions boolPref:@"debugStrip" def:YES];
    _emptyL.text = [NSString stringWithFormat:@"Уведомлений нет (захвачено: %lu)\nЕсли они есть — пришлите OPCC_notifs.txt", (unsigned long)[OPCCNotifStore all].count];
    [self setNeedsLayout];
}
- (void)relayoutAnimated {
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ [self setNeedsLayout]; [self layoutIfNeeded]; } completion:nil];
}
- (void)cardTap:(OPCCNotifCard *)c {
    Hap();
    if (c.collapsedGroup) { [self expandGroup:c]; return; }
    OPCCNotif *n = c.items.firstObject; NSString *b = n.bundleID;
    [OPCCNotifStore clear:n]; [OPCCNotifPanel hide];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [OPCCActions launchAppNow:b]; });
}
- (void)expandGroup:(OPCCNotifCard *)c {
    Hap(); NSString *b = ((OPCCNotif *)c.items.firstObject).bundleID ?: @""; [_expGroups addObject:b];
    [self reload]; [self layoutIfNeeded];
    for (UIView *k in _cards) { k.alpha = 0; k.transform = CGAffineTransformMakeTranslation(0, -10); }
    [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0 options:0 animations:^{ for (UIView *k in self->_cards) { k.alpha = 1; k.transform = CGAffineTransformIdentity; } } completion:nil];
}
- (void)chevron:(OPCCNotifCard *)c {
    Hap(); OPCCNotif *n = c.items.firstObject;
    if (c.chevMode == 2) { [_expGroups removeObject:n.bundleID ?: @""]; [self reload]; [self relayoutAnimated]; return; }
    if ([_expMsgs containsObject:n.ident]) [_expMsgs removeObject:n.ident]; else [_expMsgs addObject:n.ident];
    c.msgExpanded = [_expMsgs containsObject:n.ident]; [self relayoutAnimated];
}
// Смахивание карточки в сторону
- (void)cardPan:(UIPanGestureRecognizer *)g {
    OPCCNotifCard *c = (OPCCNotifCard *)g.view; CGFloat tx = [g translationInView:self].x, w = MAX(1, c.bounds.size.width);
    if (g.state == UIGestureRecognizerStateChanged) { c.transform = CGAffineTransformMakeTranslation(tx, 0); c.alpha = 1 - MIN(1, fabs(tx) / w) * 0.8; }
    else if (g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled || g.state == UIGestureRecognizerStateFailed) {
        CGFloat vx = [g velocityInView:self].x;
        if (g.state == UIGestureRecognizerStateEnded && (fabs(tx) > w * 0.35 || fabs(vx) > 900)) {
            CGFloat dir = (tx != 0 ? tx : vx) > 0 ? 1 : -1; _suppress = YES;
            [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{ c.transform = CGAffineTransformMakeTranslation(dir * (w + 40), 0); c.alpha = 0; } completion:^(BOOL f) {
                [c removeFromSuperview]; [self->_cards removeObject:c];
                for (OPCCNotif *n in c.items) [OPCCNotifStore clear:n];
                [self relayoutAnimated];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ self->_suppress = NO; });
            }];
        } else [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:0 animations:^{ c.transform = CGAffineTransformIdentity; c.alpha = 1; } completion:nil];
    }
}
- (void)bellTap { Hap(); [OPCCNotifPanel hide]; dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ NSURL *u = [NSURL URLWithString:@"App-prefs:NOTIFICATIONS_ID"]; if (u) [[UIApplication sharedApplication] openURL:u options:@{} completionHandler:nil]; }); }
- (void)clearAll {
    Hap(); if (!_cards.count) { [OPCCNotifPanel hide]; return; }
    _suppress = YES; CGFloat u = _u; NSUInteger i = 0;
    for (OPCCNotifCard *c in _cards) {
        [UIView animateWithDuration:0.28 delay:0.035 * MIN(i, 8) options:UIViewAnimationOptionCurveEaseIn animations:^{ c.transform = CGAffineTransformMakeTranslation(0, -30 * u); c.alpha = 0; } completion:nil]; i++;
    }
    [UIView animateWithDuration:0.25 animations:^{ self->_x.alpha = 0; self->_x.transform = CGAffineTransformMakeScale(0.5, 0.5); }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [OPCCNotifStore clearAll]; [OPCCNotifPanel hide]; });
}

#pragma mark жесты закрытия
- (void)emptyTap { [OPCCNotifPanel hide]; }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldReceiveTouch:(UITouch *)t {
    if (_closing) return NO;
    UIView *v = t.view;
    if (g == _tapGR) return v == self || v == _shade || v == _bg || v == _scroll || v == ((UIVisualEffectView *)_bg).contentView;
    return YES;
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)g {
    if (![g isKindOfClass:[UIPanGestureRecognizer class]]) return [super gestureRecognizerShouldBegin:g];
    CGPoint v = [(UIPanGestureRecognizer *)g velocityInView:self];
    if (g == _panGR) {
        if (_closing || !(v.y < 0 && fabs(v.y) > fabs(v.x) * 1.3)) return NO;
        CGFloat maxOff = _scroll.contentSize.height - _scroll.bounds.size.height;
        if (_scroll.scrollEnabled && maxOff > 1 && _scroll.contentOffset.y < maxOff - 2) return NO;
        return YES;
    }
    return fabs(v.x) > fabs(v.y) * 1.2;      // смахивание карточек — только горизонтальное
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b { return YES; }
- (void)panClose:(UIPanGestureRecognizer *)g {
    CGFloat H = MAX(1, self.bounds.size.height); CGPoint t = [g translationInView:self];
    if (g.state == UIGestureRecognizerStateBegan) { _panActive = YES; [_shade.layer removeAllAnimations]; }
    else if (g.state == UIGestureRecognizerStateChanged) {
        if (!_panActive || _closing) return;
        CGFloat ty = MIN(0, t.y); _shade.transform = CGAffineTransformMakeTranslation(0, ty); _shade.alpha = 1 - MIN(1, -ty / H) * 0.7;
    } else if (g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled || g.state == UIGestureRecognizerStateFailed) {
        if (!_panActive) return; _panActive = NO;
        CGFloat vy = [g velocityInView:self].y, ty = MIN(0, t.y);
        if (g.state == UIGestureRecognizerStateEnded && (ty < -H * 0.12 || vy < -700)) [OPCCNotifPanel hide];
        else [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{ self->_shade.transform = CGAffineTransformIdentity; self->_shade.alpha = 1; } completion:nil];
    }
}

#pragma mark раскладка
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.bounds.size.width, H = self.bounds.size.height, u = W / 316.; _u = u;
    CGFloat top = MAX(self.safeAreaInsets.top, 20), cy = top + 26*u, m = 12*u;
    CGRect full = CGRectMake(0, 0, W, H); _bg.frame = full; ((UIVisualEffectView *)_bg).contentView.subviews.firstObject.frame = full;
    _dateL.frame = CGRectMake(m + 4*u, cy - 10*u, 220*u, 20*u);
    _bell.frame = CGRectMake(W - m - 4*u - 30*u, cy - 15*u, 30*u, 30*u); [_bell viewWithTag:9].frame = _bell.bounds;
    CGFloat sTop = cy + 22*u, sH = H - sTop;
    _scroll.frame = CGRectMake(0, sTop, W, sH);
    CGFloat y = 0, cw = W - 2*m;
    for (OPCCNotifCard *c in _cards) {
        CGFloat h = [c layoutForWidth:cw u:u];
        if (CGAffineTransformIsIdentity(c.transform)) c.frame = CGRectMake(m, y, cw, h); else { c.bounds = CGRectMake(0, 0, cw, h); c.center = CGPointMake(m + cw/2, y + h/2); }
        y += h + 6*u;
    }
    CGFloat xD = 38*u, xBottom = MAX(self.safeAreaInsets.bottom, 0) + 22*u;
    CGFloat contentH = y + (_cards.count ? xD + xBottom + 8*u : 0);
    _scroll.contentSize = CGSizeMake(W, MAX(sH, contentH));
    _scroll.scrollEnabled = contentH > sH + 6;          // прокрутки нет, пока всё помещается
    if (!_scroll.scrollEnabled && _scroll.contentOffset.y != 0) _scroll.contentOffset = CGPointZero;
    _x.bounds = CGRectMake(0, 0, xD, xD); _x.layer.cornerRadius = xD/2; _x.center = CGPointMake(W/2, H - xBottom - xD/2); [_x viewWithTag:9].frame = _x.bounds;
    _x.hidden = (_cards.count == 0);
    _emptyL.frame = CGRectMake(20*u, H/2 - 30*u, W - 40*u, 60*u);
    NSDateFormatter *tf = [NSDateFormatter new]; tf.dateFormat = @"HH:mm";
    NSDateFormatter *df = [NSDateFormatter new]; df.dateFormat = @"d MMM, EE"; df.locale = [NSLocale localeWithLocaleIdentifier:@"ru_RU"];
    NSString *ts = [tf stringFromDate:[NSDate date]], *ds = [df stringFromDate:[NSDate date]];
    NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@   %@", ts, ds] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:13*u weight:UIFontWeightRegular]}];
    [as addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:13*u weight:UIFontWeightSemibold] range:NSMakeRange(0, ts.length)];
    _dateL.attributedText = as;
}

#pragma mark анимации
- (void)present {
    _closing = NO; _panActive = NO; _suppress = NO; _gen++; [_expGroups removeAllObjects]; [_expMsgs removeAllObjects];
    [self reload]; [self setNeedsLayout]; [self layoutIfNeeded];
    CGFloat H = self.bounds.size.height, u = _u;
    [_shade.layer removeAllAnimations]; _shade.alpha = 0; _shade.transform = CGAffineTransformMakeTranslation(0, -H * 0.6);
    [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.92 initialSpringVelocity:0.4 options:UIViewAnimationOptionAllowUserInteraction animations:^{ self->_shade.alpha = 1; self->_shade.transform = CGAffineTransformIdentity; } completion:nil];
    [_cards enumerateObjectsUsingBlock:^(OPCCNotifCard *c, NSUInteger i, BOOL *s) {
        if (i > 7) return; c.alpha = 0; c.transform = CGAffineTransformMakeTranslation(0, -16 * u);
        [UIView animateWithDuration:0.55 delay:0.05 + 0.035 * i usingSpringWithDamping:0.8 initialSpringVelocity:0.2 options:UIViewAnimationOptionAllowUserInteraction animations:^{ c.alpha = 1; c.transform = CGAffineTransformIdentity; } completion:nil];
    }];
    _x.alpha = 0; _x.transform = CGAffineTransformMakeScale(0.5, 0.5);
    [UIView animateWithDuration:0.5 delay:0.2 usingSpringWithDamping:0.7 initialSpringVelocity:0.3 options:0 animations:^{ self->_x.alpha = 1; self->_x.transform = CGAffineTransformIdentity; } completion:nil];
}
- (void)closeAnimated:(void (^)(void))done {
    if (_closing) return; _closing = YES; NSInteger gen = _gen; CGFloat H = self.bounds.size.height;
    [UIView animateWithDuration:0.34 delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
        self->_shade.transform = CGAffineTransformMakeTranslation(0, -H * 0.6); self->_shade.alpha = 0; } completion:^(BOOL f) { if (f && gen == self->_gen && done) done(); }];
}
@end

#pragma mark - окно панели
@implementation OPCCNotifPanel
static UIWindow *gWin; static OPCCNotifView *gView; static BOOL gShown; static void (^gOnHide)(void);
+ (BOOL)isShown { return gShown; }
+ (void)setOnHide:(void (^)(void))b { gOnHide = [b copy]; }
+ (void)show {
    if (gShown) return; gShown = YES;
    if (!gWin) {
        CGRect b = [UIScreen mainScreen].bounds;
        gWin = [[UIWindow alloc] initWithFrame:b]; gWin.windowLevel = UIWindowLevelStatusBar - 1;   // ниже статус-бара: он остаётся видимым
        gWin.backgroundColor = [UIColor clearColor];
        UIViewController *vc = [UIViewController new]; gView = [[OPCCNotifView alloc] initWithFrame:b]; vc.view = gView; gWin.rootViewController = vc;
    }
    gWin.hidden = NO; [gView present];
}
+ (void)hide {
    if (!gShown) return; gShown = NO;
    [gView closeAnimated:^{ gWin.hidden = YES; if (gOnHide) gOnHide(); }];
}
@end
