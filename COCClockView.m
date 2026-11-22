#import <CoreText/CoreText.h>
#import "COCClockView.h"
#import "Prefs.h"

#pragma mark - Цифры (ультра-узкий шрифт, растягивается ровно под прямоугольник)

static CTFontRef COCDigitFont(void) {
    static CTFontRef font = NULL;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSArray *names = @[ @"DINCondensed-Bold", @"AvenirNextCondensed-Heavy",
                            @"HelveticaNeue-CondensedBold", @"ArialNarrow-Bold" ];
        for (NSString *n in names) {
            if ([UIFont fontWithName:n size:10]) {
                font = CTFontCreateWithName((__bridge CFStringRef)n, 200, NULL);
                break;
            }
        }
        if (!font) font = CTFontCreateUIFontForLanguage(kCTFontUIFontEmphasizedSystem, 200, NULL);
    });
    return font;
}

@interface COCDigitsView : UIView
@property (nonatomic, copy) NSArray<NSString *> *lines;   // 1 строка "0851" или 2 строки "08","51"
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat gapRatio;           // зазор между строками / общая высота
@end

@implementation COCDigitsView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.contentMode = UIViewContentModeRedraw;
        _color = [UIColor whiteColor];
        _gapRatio = 0.03;
    }
    return self;
}

- (void)setLines:(NSArray<NSString *> *)lines {
    if ([_lines isEqualToArray:lines]) return;
    _lines = [lines copy];
    [self setNeedsDisplay];
}

- (void)setColor:(UIColor *)color {
    _color = color;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    NSUInteger n = self.lines.count;
    if (n == 0) return;

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect B = self.bounds;
    CGFloat gap = (n > 1) ? B.size.height * self.gapRatio : 0;
    CGFloat lineH = (B.size.height - gap * (n - 1)) / n;

    CGContextSetFillColorWithColor(ctx, self.color.CGColor);

    for (NSUInteger i = 0; i < n; i++) {
        CGRect r = CGRectMake(0, i * (lineH + gap), B.size.width, lineH);

        NSDictionary *attrs = @{ (__bridge id)kCTFontAttributeName: (__bridge id)COCDigitFont(),
                                 (__bridge id)kCTKernAttributeName: @(4) };
        NSAttributedString *as = [[NSAttributedString alloc] initWithString:self.lines[i] attributes:attrs];
        CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)as);
        CGRect b = CTLineGetBoundsWithOptions(line, kCTLineBoundsUseGlyphPathBounds);
        if (b.size.width > 0 && b.size.height > 0) {
            CGContextSaveGState(ctx);
            // Переходим в систему координат CoreText (y вверх) с началом в левом нижнем углу строки
            CGContextTranslateCTM(ctx, r.origin.x, r.origin.y + r.size.height);
            CGContextScaleCTM(ctx, 1, -1);
            // Растягиваем границы глифов ровно на прямоугольник
            CGContextScaleCTM(ctx, r.size.width / b.size.width, r.size.height / b.size.height);
            CGContextTranslateCTM(ctx, -b.origin.x, -b.origin.y);
            CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
            CGContextSetTextPosition(ctx, 0, 0);
            CTLineDraw(line, ctx);
            CGContextRestoreGState(ctx);
        }
        CFRelease(line);
    }
}

@end

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

static UIColor *COCPaletteColor(NSInteger idx) {
    // Пастельная палитра как в «Clock & color» у ColorOS
    switch (idx) {
        case 1: return [UIColor colorWithRed:0.88 green:0.86 blue:1.00 alpha:1];  // лавандовый
        case 2: return [UIColor colorWithRed:0.78 green:0.86 blue:1.00 alpha:1];  // голубой
        case 3: return [UIColor colorWithRed:0.75 green:0.92 blue:1.00 alpha:1];  // бирюзовый
        case 4: return [UIColor colorWithRed:0.91 green:0.80 blue:1.00 alpha:1];  // сиреневый
        case 5: return [UIColor colorWithRed:1.00 green:0.79 blue:0.76 alpha:1];  // розовый
        case 6: return [UIColor colorWithRed:1.00 green:0.89 blue:0.77 alpha:1];  // персиковый
        default: return [UIColor whiteColor];
    }
}

@implementation COCClockView {
    COCDigitsView *_digits;
    UILabel *_dateL;
    NSMutableArray<COCWidgetCard *> *_cards;
    NSTimer *_timer;
    NSDateFormatter *_fmt;

    // Кэш настроек
    BOOL _enabled, _use24, _wEn, _wDate, _wBat, _wTxt;
    NSInteger _style, _colorIdx;
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

        _digits = [[COCDigitsView alloc] init];
        [self addSubview:_digits];

        _dateL = [[UILabel alloc] init];
        _dateL.textAlignment = NSTextAlignmentLeft;
        [self addSubview:_dateL];

        [self reloadPrefs];
    }
    return self;
}

// Часы не перехватывают касания: свайпы, камера, фонарик работают как обычно.
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
    _enabled  = COCB(@"enabled", YES);
    _style    = (NSInteger)COCF(@"layout", 1);
    _use24    = COCB(@"use24h", YES);
    _colorIdx = (NSInteger)COCF(@"clockColor", 1);

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

    UIColor *tint = COCPaletteColor(_colorIdx);
    _digits.color = tint;
    _dateL.textColor = tint;

    // Перестраиваем виджеты
    for (COCWidgetCard *c in _cards) [c removeFromSuperview];
    [_cards removeAllObjects];
    if (_wEn) {
        BOOL on[3] = { _wDate, _wBat, _wTxt };
        for (NSInteger i = 0; i < 3; i++) {
            if (!on[i]) continue;
            COCWidgetCard *card = [[COCWidgetCard alloc] initWithFrame:CGRectZero];
            card.tag = i;
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

    // Ведущий ноль всегда: 0851
    _fmt.dateFormat = _use24 ? @"HH" : @"hh";
    NSString *h = [_fmt stringFromDate:now];
    _fmt.dateFormat = @"mm";
    NSString *m = [_fmt stringFromDate:now];

    _digits.lines = (_style == 1) ? @[ h, m ] : @[ [h stringByAppendingString:m] ];

    _fmt.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"EEEMMMMd" options:0
                                                       locale:[NSLocale currentLocale]];
    NSString *d = [_fmt stringFromDate:now];
    BOOL changed = NO;
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

    // Размер — общий масштаб, ширина/высота — растяжение поверх него
    CGFloat k = _size / 100.0;
    CGFloat sx = k * _w / 100.0, sy = k * _h / 100.0;

    // Дата
    _dateL.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    [_dateL sizeToFit];
    CGSize ds = _dateL.bounds.size;

    CGRect dr;           // прямоугольник цифр
    CGPoint dateOrigin;  // положение даты

    if (_style == 1) {
        // Вариант 1: вертикальные цифры слева (08 над 51), виджеты сбоку справа
        CGFloat bw = R.size.width * 0.34;
        CGFloat lineH = bw * 1.9;
        CGFloat bh = lineH * 2.06;
        _digits.gapRatio = 0.03;
        dr = CGRectMake(R.origin.x, R.origin.y, bw * sx, bh * sy);
        dateOrigin = CGPointMake(CGRectGetMaxX(dr) + 18, R.origin.y);
    } else if (_style == 2) {
        // Вариант 2: 0851 в одну строку (≈60% ширины), под ним дата и виджеты
        CGFloat bw = R.size.width * 0.62;
        CGFloat bh = bw * 0.95;
        dr = CGRectMake(R.origin.x, R.origin.y, bw * sx, bh * sy);
        dateOrigin = CGPointMake(R.origin.x, CGRectGetMaxY(dr) + 10);
    } else {
        // Вариант 3: дата сверху, 0851 во всю ширину, виджеты снизу
        CGFloat bw = R.size.width;
        CGFloat bh = bw * 0.80;
        dateOrigin = CGPointMake(R.origin.x, R.origin.y);
        dr = CGRectMake(R.origin.x, R.origin.y + ds.height + 8, bw * sx, bh * sy);
    }

    _digits.frame = dr;
    _dateL.frame = CGRectMake(dateOrigin.x, dateOrigin.y, ds.width, ds.height);

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

    if (n == 0) return;

    if (_style == 1) {
        // Колонка справа от цифр, под датой
        CGFloat x = CGRectGetMaxX(dr) + 18;
        CGFloat colW = MAX(CGRectGetMaxX(R) - x, 110);
        CGFloat y = CGRectGetMaxY(_dateL.frame) + 10;
        for (COCWidgetCard *c in _cards) {
            c.frame = CGRectMake(x, y, colW, cardH);
            y += cardH + gap;
        }
    } else {
        // Ряд под часами (вариант 2 — под датой, вариант 3 — под цифрами)
        CGFloat y = (_style == 2) ? CGRectGetMaxY(_dateL.frame) + 14 : CGRectGetMaxY(dr) + 16;
        CGFloat cw = (R.size.width - gap * (n - 1)) / n;
        CGFloat x = CGRectGetMinX(R);
        for (COCWidgetCard *c in _cards) {
            c.frame = CGRectMake(x, y, cw, cardH);
            x += cw + gap;
        }
    }
}

@end
