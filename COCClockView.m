#import "COCClockView.h"
#import "Prefs.h"

#pragma mark - Карточка виджета

@interface COCWidgetCard : UIView
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, assign) CGFloat uiScale;
- (void)setSymbol:(NSString *)symbol title:(NSString *)title value:(NSString *)value;
@end

@implementation COCWidgetCard

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _uiScale = 1.0;
        self.clipsToBounds = YES;

        _iconView = [[UIImageView alloc] init];
        _iconView.tintColor = [UIColor whiteColor];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_iconView];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.78];
        [self addSubview:_titleLabel];

        _valueLabel = [[UILabel alloc] init];
        _valueLabel.textColor = [UIColor whiteColor];
        _valueLabel.adjustsFontSizeToFitWidth = YES;
        _valueLabel.minimumScaleFactor = 0.55;
        [self addSubview:_valueLabel];
    }
    return self;
}

- (void)setSymbol:(NSString *)symbol title:(NSString *)title value:(NSString *)value {
    _iconView.image = [UIImage systemImageNamed:symbol];
    _titleLabel.text = title;
    _valueLabel.text = value;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat s = self.uiScale, pad = 12 * s;
    CGFloat w = self.bounds.size.width, h = self.bounds.size.height;

    _titleLabel.font = [UIFont systemFontOfSize:12 * s weight:UIFontWeightMedium];
    _valueLabel.font = [UIFont systemFontOfSize:22 * s weight:UIFontWeightBold];

    _iconView.frame = CGRectMake(pad, pad, 18 * s, 18 * s);
    _titleLabel.frame = CGRectMake(pad + 24 * s, pad, MAX(0, w - pad * 2 - 24 * s), 18 * s);
    _valueLabel.frame = CGRectMake(pad, h - pad - 28 * s, MAX(0, w - pad * 2), 28 * s);
}

@end

#pragma mark - Часы

typedef NS_ENUM(NSInteger, COCWidgetType) {
    COCWidgetDate = 0,
    COCWidgetBattery = 1,
    COCWidgetText = 2,
};

@implementation COCClockView {
    UIView *_digits;           // контейнер цифр (к нему применяется растяжение)
    UILabel *_timeL;           // "12:50" (вариант 1)
    UILabel *_hourL;           // "12"    (варианты 2 и 3)
    UILabel *_minL;            // "50"
    UILabel *_dateL;
    NSMutableArray<COCWidgetCard *> *_cards;
    NSTimer *_timer;
    NSDateFormatter *_fmt;

    // Кэш настроек
    BOOL _enabled, _use24, _wEn, _wDate, _wBat, _wTxt;
    NSInteger _style;
    CGFloat _pT, _pL, _pB, _pR;
    CGFloat _size, _w, _h, _op, _ox, _oy;
    CGFloat _wOp, _wRad, _wScale;
    NSString *_txt;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
        _cards = [NSMutableArray array];
        _fmt = [[NSDateFormatter alloc] init];
        _fmt.locale = [NSLocale currentLocale];

        UIDevice.currentDevice.batteryMonitoringEnabled = YES;

        _digits = [[UIView alloc] init];
        [self addSubview:_digits];

        UILabel *(^mk)(void) = ^UILabel *{
            UILabel *l = [[UILabel alloc] init];
            l.textColor = [UIColor whiteColor];
            l.textAlignment = NSTextAlignmentLeft;
            l.numberOfLines = 1;
            return l;
        };
        _timeL = mk();
        _hourL = mk();
        _minL = mk();
        [_digits addSubview:_timeL];
        [_digits addSubview:_hourL];
        [_digits addSubview:_minL];

        _dateL = mk();
        [self addSubview:_dateL];

        [self reloadPrefs];
    }
    return self;
}

// Часы не должны перехватывать касания: свайпы, камера, фонарик и т.д. работают как обычно.
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return nil;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [_timer invalidate];
    _timer = nil;
    if (self.window) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tick)
                                                userInfo:nil repeats:YES];
        [self refreshContent];
    }
}

- (void)tick {
    [self refreshContent];
}

#pragma mark Настройки

- (void)reloadPrefs {
    _enabled = COCB(@"enabled", YES);
    _style   = (NSInteger)COCF(@"layout", 1);
    _use24   = COCB(@"use24h", YES);

    _pT = COCF(@"padTop", 70);
    _pL = COCF(@"padLeft", 24);
    _pB = COCF(@"padBottom", 0);
    _pR = COCF(@"padRight", 24);

    _size = COCF(@"size", 100);
    _w    = COCF(@"width", 100);
    _h    = COCF(@"height", 100);
    _op   = COCF(@"clockOpacity", 100);
    _ox   = COCF(@"offsetX", 0);
    _oy   = COCF(@"offsetY", 0);

    _wEn    = COCB(@"widgetsEnabled", YES);
    _wDate  = COCB(@"widgetDate", YES);
    _wBat   = COCB(@"widgetBattery", YES);
    _wTxt   = COCB(@"widgetText", NO);
    _txt    = COCS(@"widgetTextValue", @"ColorOS");
    _wOp    = COCF(@"widgetOpacity", 20);
    _wRad   = COCF(@"widgetRadius", 22);
    _wScale = COCF(@"widgetScale", 100);

    if (_style < 1 || _style > 3) _style = 1;

    self.hidden = !_enabled;

    // Перестраиваем виджеты
    for (COCWidgetCard *c in _cards) [c removeFromSuperview];
    [_cards removeAllObjects];
    if (_wEn) {
        NSArray *types = @[ @(COCWidgetDate), @(COCWidgetBattery), @(COCWidgetText) ];
        BOOL on[3] = { _wDate, _wBat, _wTxt };
        for (NSUInteger i = 0; i < types.count; i++) {
            if (!on[i]) continue;
            COCWidgetCard *card = [[COCWidgetCard alloc] initWithFrame:CGRectZero];
            card.tag = [types[i] integerValue];
            [self addSubview:card];
            [_cards addObject:card];
        }
    }

    [self refreshContent];
    [self setNeedsLayout];
}

#pragma mark Содержимое

- (void)refreshContent {
    NSDate *now = [NSDate date];

    _fmt.dateFormat = _use24 ? @"HH" : @"h";
    NSString *h = [_fmt stringFromDate:now];
    _fmt.dateFormat = @"mm";
    NSString *m = [_fmt stringFromDate:now];
    NSString *t = [NSString stringWithFormat:@"%@:%@", h, m];

    BOOL changed = NO;
    if (![_timeL.text isEqualToString:t]) {
        _timeL.text = t;
        _hourL.text = h;
        _minL.text = m;
        changed = YES;
    }

    _fmt.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"EEEMMMMd" options:0
                                                       locale:[NSLocale currentLocale]];
    NSString *d = [_fmt stringFromDate:now];
    if (![_dateL.text isEqualToString:d]) {
        _dateL.text = d;
        changed = YES;
    }

    for (COCWidgetCard *card in _cards) {
        switch (card.tag) {
            case COCWidgetDate: {
                _fmt.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"EEEE" options:0
                                                                   locale:[NSLocale currentLocale]];
                NSString *wd = [_fmt stringFromDate:now];
                _fmt.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"dMMM" options:0
                                                                   locale:[NSLocale currentLocale]];
                NSString *dm = [_fmt stringFromDate:now];
                [card setSymbol:@"calendar" title:wd value:dm];
                break;
            }
            case COCWidgetBattery: {
                UIDevice *dev = UIDevice.currentDevice;
                float lvl = dev.batteryLevel;
                NSString *v = lvl < 0 ? @"—" : [NSString stringWithFormat:@"%d%%", (int)roundf(lvl * 100)];
                BOOL chg = dev.batteryState == UIDeviceBatteryStateCharging ||
                           dev.batteryState == UIDeviceBatteryStateFull;
                [card setSymbol:(chg ? @"bolt.fill" : @"battery.100") title:@"Батарея" value:v];
                break;
            }
            case COCWidgetText:
                [card setSymbol:@"star.fill" title:@"Заметка" value:_txt];
                break;
        }
    }

    if (changed) [self setNeedsLayout];
}

#pragma mark Раскладка

- (void)layoutSubviews {
    [super layoutSubviews];

    // Область контента: границы минус отступы, плюс смещение
    CGRect R = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(_pT, _pL, _pB, _pR));
    R = CGRectOffset(R, _ox, _oy);

    CGFloat base = (_style == 1) ? 84 : (_style == 2 ? 128 : 150);
    CGFloat fs = base * _size / 100.0;
    UIFont *font = [UIFont monospacedDigitSystemFontOfSize:fs weight:UIFontWeightBold];

    CGFloat sx = _w / 100.0, sy = _h / 100.0;
    CGSize nat = CGSizeZero;
    CGPoint anchor, pos;

    _timeL.hidden = (_style != 1);
    _hourL.hidden = _minL.hidden = (_style == 1);

    _digits.transform = CGAffineTransformIdentity;

    if (_style == 1) {
        _timeL.font = font;
        [_timeL sizeToFit];
        nat = _timeL.bounds.size;
        _timeL.frame = CGRectMake(0, 0, nat.width, nat.height);
        // «растянутые»: по умолчанию растягиваем на всю ширину области
        if (nat.width > 0) sx *= R.size.width / nat.width;
        anchor = CGPointMake(0.5, 0);
        pos = CGPointMake(CGRectGetMidX(R), CGRectGetMinY(R));
    } else {
        _hourL.font = _minL.font = font;
        [_hourL sizeToFit];
        [_minL sizeToFit];
        CGSize hs = _hourL.bounds.size, ms = _minL.bounds.size;
        CGFloat overlap = fs * 0.16;
        _hourL.frame = CGRectMake(0, 0, hs.width, hs.height);
        _minL.frame = CGRectMake(0, hs.height - overlap, ms.width, ms.height);
        nat = CGSizeMake(MAX(hs.width, ms.width), hs.height + ms.height - overlap);
        if (_style == 3 && nat.height > 0) sy *= (R.size.height * 0.60) / nat.height;
        anchor = CGPointMake(0, 0);
        pos = CGPointMake(CGRectGetMinX(R), CGRectGetMinY(R));
    }

    // Порядок важен: anchorPoint → bounds → position → transform
    _digits.layer.anchorPoint = anchor;
    _digits.bounds = CGRectMake(0, 0, nat.width, nat.height);
    _digits.layer.position = pos;
    _digits.transform = CGAffineTransformMakeScale(sx, sy);

    CGFloat dw = nat.width * sx, dh = nat.height * sy;
    CGFloat digitsBottom = CGRectGetMinY(R) + dh;

    // Дата
    _dateL.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [_dateL sizeToFit];
    CGSize ds = _dateL.bounds.size;
    if (_style == 1) {
        _dateL.frame = CGRectMake(CGRectGetMidX(R) - ds.width / 2, digitsBottom + 2, ds.width, ds.height);
    } else {
        _dateL.frame = CGRectMake(CGRectGetMinX(R), digitsBottom + 4, ds.width, ds.height);
    }
    CGFloat dateBottom = CGRectGetMaxY(_dateL.frame);

    // Прозрачность часов
    _digits.alpha = _op / 100.0;
    _dateL.alpha = _op / 100.0;

    // Виджеты
    CGFloat ws = _wScale / 100.0;
    CGFloat cardH = 76 * ws, gap = 10;
    NSUInteger n = _cards.count;
    for (COCWidgetCard *c in _cards) {
        c.uiScale = ws;
        c.backgroundColor = [UIColor colorWithWhite:1 alpha:_wOp / 100.0];
        c.layer.cornerRadius = _wRad;
        if (@available(iOS 13.0, *)) c.layer.cornerCurve = kCACornerCurveContinuous;
    }

    if (n > 0) {
        if (_style == 2) {
            // Виджеты сбоку: колонка справа от цифр
            CGFloat colW = R.size.width - dw - 14;
            colW = MIN(MAX(colW, 130), R.size.width * 0.5);
            CGFloat x = CGRectGetMaxX(R) - colW;
            CGFloat y = CGRectGetMinY(R);
            for (COCWidgetCard *c in _cards) {
                c.frame = CGRectMake(x, y, colW, cardH);
                y += cardH + gap;
            }
        } else {
            // Виджеты снизу (варианты 1 и 3): ряд под датой
            CGFloat rowW = R.size.width;
            CGFloat cw = (rowW - gap * (n - 1)) / n;
            CGFloat x = CGRectGetMinX(R);
            CGFloat y = dateBottom + 16;
            for (COCWidgetCard *c in _cards) {
                c.frame = CGRectMake(x, y, cw, cardH);
                x += cw + gap;
            }
        }
    }
}

@end
