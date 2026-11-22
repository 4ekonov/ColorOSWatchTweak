#import <CoreText/CoreText.h>
#import <objc/message.h>
#import <dlfcn.h>
#import "COCClockView.h"
#import "Prefs.h"

static NSString *const COCWeatherUpdated = @"COCWeatherUpdated";

#pragma mark - Шрифты

static UIFont *COCRounded(CGFloat size, UIFontWeight weight) {
    UIFont *f = [UIFont systemFontOfSize:size weight:weight];
    UIFontDescriptor *d = [f.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
    return d ? [UIFont fontWithDescriptor:d size:size] : f;
}

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

// Контур глифов строки (используем как маску для градиента — цвет не зависит от CoreText)
static CGPathRef COCCreateLinePath(NSString *s) {
    NSDictionary *attrs = @{ (__bridge id)kCTFontAttributeName: (__bridge id)COCDigitFont(),
                             (__bridge id)kCTKernAttributeName: @(4) };
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:s attributes:attrs];
    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)as);
    CGMutablePathRef path = CGPathCreateMutable();
    CFArrayRef runs = CTLineGetGlyphRuns(line);
    for (CFIndex i = 0; i < CFArrayGetCount(runs); i++) {
        CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runs, i);
        CFIndex cnt = CTRunGetGlyphCount(run);
        if (cnt <= 0) continue;
        CGGlyph glyphs[cnt];
        CGPoint pos[cnt];
        CTRunGetGlyphs(run, CFRangeMake(0, 0), glyphs);
        CTRunGetPositions(run, CFRangeMake(0, 0), pos);
        CTFontRef f = (CTFontRef)CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);
        for (CFIndex j = 0; j < cnt; j++) {
            CGPathRef gp = CTFontCreatePathForGlyph(f, glyphs[j], NULL);
            if (gp) {
                CGAffineTransform t = CGAffineTransformMakeTranslation(pos[j].x, pos[j].y);
                CGPathAddPath(path, &t, gp);
                CGPathRelease(gp);
            }
        }
    }
    CFRelease(line);
    return path;
}

#pragma mark - Цифры (ультра-узкие, градиент как в ColorOS)

@interface COCDigitsView : UIView
@property (nonatomic, copy) NSArray<NSString *> *lines;   // "0851" или "08","51"
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat gapRatio;
@end

@implementation COCDigitsView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.contentMode = UIViewContentModeRedraw;
        _color = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
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

    CGFloat r = 1, g = 1, bl = 1, a = 1;
    [self.color getRed:&r green:&g blue:&bl alpha:&a];
    // Сверху полупрозрачнее, к низу ярче — как на цифрах ColorOS
    CGFloat comps[8] = { r, g, bl, 0.55 * a,  r, g, bl, a };
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGGradientRef grad = CGGradientCreateWithColorComponents(cs, comps, NULL, 2);

    for (NSUInteger i = 0; i < n; i++) {
        CGRect lr = CGRectMake(0, i * (lineH + gap), B.size.width, lineH);
        CGPathRef path = COCCreateLinePath(self.lines[i]);
        CGRect b = CGPathGetBoundingBox(path);
        if (b.size.width > 0 && b.size.height > 0) {
            CGContextSaveGState(ctx);
            CGContextTranslateCTM(ctx, lr.origin.x, lr.origin.y + lr.size.height);
            CGContextScaleCTM(ctx, 1, -1);
            CGContextScaleCTM(ctx, lr.size.width / b.size.width, lr.size.height / b.size.height);
            CGContextTranslateCTM(ctx, -b.origin.x, -b.origin.y);
            CGContextAddPath(ctx, path);
            CGContextClip(ctx);
            CGContextDrawLinearGradient(ctx, grad,
                                        CGPointMake(0, CGRectGetMaxY(b)),
                                        CGPointMake(0, CGRectGetMinY(b)),
                                        kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
            CGContextRestoreGState(ctx);
        }
        CGPathRelease(path);
    }
    CGGradientRelease(grad);
    CGColorSpaceRelease(cs);
}

@end

#pragma mark - Карточка виджета (стиль iOS 17/18: квадрат + материал)

@interface COCWidgetCard : UIView
@property (nonatomic, strong) UIVisualEffectView *blur;
@property (nonatomic, strong) UIView *tintView;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, copy) NSString *symbol;
@property (nonatomic, assign) CGFloat fillAlpha;
- (void)setSymbol:(NSString *)symbol value:(NSString *)value;
@end

@implementation COCWidgetCard

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.clipsToBounds = YES;

        UIBlurEffect *eff = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
        _blur = [[UIVisualEffectView alloc] initWithEffect:eff];
        [self addSubview:_blur];

        _tintView = [[UIView alloc] init];
        [self addSubview:_tintView];

        _iconView = [[UIImageView alloc] init];
        _iconView.tintColor = [UIColor whiteColor];
        _iconView.contentMode = UIViewContentModeTopLeft;
        [self addSubview:_iconView];

        _valueLabel = [[UILabel alloc] init];
        _valueLabel.textColor = [UIColor whiteColor];
        _valueLabel.adjustsFontSizeToFitWidth = YES;
        _valueLabel.minimumScaleFactor = 0.5;
        [self addSubview:_valueLabel];

        _fillAlpha = 0.1;
    }
    return self;
}

- (void)setFillAlpha:(CGFloat)fillAlpha {
    _fillAlpha = fillAlpha;
    _tintView.backgroundColor = [UIColor colorWithWhite:1 alpha:fillAlpha];
}

- (void)setSymbol:(NSString *)symbol value:(NSString *)value {
    _symbol = [symbol copy];
    _valueLabel.text = value;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width, h = self.bounds.size.height;
    CGFloat pad = w * 0.17;

    _blur.frame = self.bounds;
    _tintView.frame = self.bounds;
    _tintView.backgroundColor = [UIColor colorWithWhite:1 alpha:_fillAlpha];

    UIImageSymbolConfiguration *cfg =
        [UIImageSymbolConfiguration configurationWithPointSize:w * 0.30 weight:UIImageSymbolWeightMedium];
    _iconView.image = _symbol ? [UIImage systemImageNamed:_symbol withConfiguration:cfg] : nil;
    _iconView.frame = CGRectMake(pad, pad, w - pad * 2, w * 0.36);

    _valueLabel.font = COCRounded(w * 0.24, UIFontWeightSemibold);
    _valueLabel.frame = CGRectMake(pad, h - pad - w * 0.30, w - pad * 2, w * 0.30);
}

@end

#pragma mark - Погода (open-meteo, без ключа)

static BOOL COCWValid = NO;
static double COCWTemp = 0;
static int COCWCode = 0;
static NSDate *COCWFetched = nil;
static BOOL COCWBusy = NO;
static NSString *COCWGeoCity = nil;
static double COCWLat = 0, COCWLon = 0;

static NSString *COCWeatherSymbol(int c) {
    if (c == 0) return @"sun.max.fill";
    if (c == 1 || c == 2) return @"cloud.sun.fill";
    if (c == 3) return @"cloud.fill";
    if (c == 45 || c == 48) return @"cloud.fog.fill";
    if (c >= 51 && c <= 57) return @"cloud.drizzle.fill";
    if (c >= 61 && c <= 67) return @"cloud.rain.fill";
    if ((c >= 71 && c <= 77) || c == 85 || c == 86) return @"cloud.snow.fill";
    if (c >= 80 && c <= 82) return @"cloud.heavyrain.fill";
    if (c >= 95) return @"cloud.bolt.rain.fill";
    return @"cloud.fill";
}

static void COCWeatherRefresh(NSString *city) {
    if (city.length == 0 || COCWBusy) return;
    if (COCWFetched && -[COCWFetched timeIntervalSinceNow] < 1200 &&
        [city isEqualToString:COCWGeoCity]) return;
    COCWBusy = YES;

    void (^finish)(BOOL, double, int, double, double) =
        ^(BOOL ok, double t, int code, double lat, double lon) {
            dispatch_async(dispatch_get_main_queue(), ^{
                COCWBusy = NO;
                if (ok) {
                    COCWValid = YES; COCWTemp = t; COCWCode = code;
                    COCWLat = lat; COCWLon = lon; COCWGeoCity = city;
                    COCWFetched = [NSDate date];
                } else {
                    COCWFetched = [NSDate dateWithTimeIntervalSinceNow:-1000]; // повтор через ~3 мин
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:COCWeatherUpdated object:nil];
            });
        };

    void (^forecast)(double, double) = ^(double lat, double lon) {
        NSString *u = [NSString stringWithFormat:
            @"https://api.open-meteo.com/v1/forecast?latitude=%.4f&longitude=%.4f"
            @"&current=temperature_2m,weather_code&timezone=auto", lat, lon];
        NSURLSessionDataTask *t = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:u]
            completionHandler:^(NSData *data, NSURLResponse *resp, NSError *err) {
                NSDictionary *j = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
                NSDictionary *cur = [j isKindOfClass:[NSDictionary class]] ? j[@"current"] : nil;
                if ([cur isKindOfClass:[NSDictionary class]] && cur[@"temperature_2m"]) {
                    finish(YES, [cur[@"temperature_2m"] doubleValue], [cur[@"weather_code"] intValue], lat, lon);
                } else {
                    finish(NO, 0, 0, 0, 0);
                }
            }];
        [t resume];
    };

    if ([city isEqualToString:COCWGeoCity] && (COCWLat != 0 || COCWLon != 0)) {
        forecast(COCWLat, COCWLon);
        return;
    }

    NSString *enc = [city stringByAddingPercentEncodingWithAllowedCharacters:
                        [NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *g = [NSString stringWithFormat:
        @"https://geocoding-api.open-meteo.com/v1/search?name=%@&count=1", enc];
    NSURLSessionDataTask *gt = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:g]
        completionHandler:^(NSData *data, NSURLResponse *resp, NSError *err) {
            NSDictionary *j = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
            NSArray *res = [j isKindOfClass:[NSDictionary class]] ? j[@"results"] : nil;
            NSDictionary *first = ([res isKindOfClass:[NSArray class]] && res.count) ? res[0] : nil;
            if ([first isKindOfClass:[NSDictionary class]] && first[@"latitude"]) {
                forecast([first[@"latitude"] doubleValue], [first[@"longitude"] doubleValue]);
            } else {
                finish(NO, 0, 0, 0, 0);
            }
        }];
    [gt resume];
}

#pragma mark - Ближайший будильник (MobileTimer, с защитой от отсутствия API)

static NSDate *COCNextAlarmDate(void) {
    static id mgr = nil;
    static dispatch_once_t once;
    static NSDate *cached = nil, *checked = nil;
    dispatch_once(&once, ^{
        dlopen("/System/Library/PrivateFrameworks/MobileTimer.framework/MobileTimer", RTLD_LAZY);
        Class c = NSClassFromString(@"MTAlarmManager");
        if (c) mgr = [[c alloc] init];
    });
    if (!mgr) return nil;
    if (checked && -[checked timeIntervalSinceNow] < 30) return cached;
    checked = [NSDate date];
    cached = nil;
    @try {
        SEL s = NSSelectorFromString(@"nextAlarmSync");
        if ([mgr respondsToSelector:s]) {
            id alarm = ((id (*)(id, SEL))objc_msgSend)(mgr, s);
            if (alarm) {
                if ([alarm respondsToSelector:NSSelectorFromString(@"nextFireDate")]) {
                    cached = [alarm valueForKey:@"nextFireDate"];
                }
                if (!cached && [alarm respondsToSelector:NSSelectorFromString(@"hour")] &&
                    [alarm respondsToSelector:NSSelectorFromString(@"minute")]) {
                    NSInteger hh = [[alarm valueForKey:@"hour"] integerValue];
                    NSInteger mm = [[alarm valueForKey:@"minute"] integerValue];
                    cached = [[NSCalendar currentCalendar] nextDateAfterDate:[NSDate date]
                                                               matchingHour:hh minute:mm second:0
                                                                    options:NSCalendarMatchNextTime];
                }
            }
        }
    } @catch (NSException *e) {
        cached = nil;
    }
    return cached;
}

#pragma mark - Часы

typedef NS_ENUM(NSInteger, COCWidgetType) {
    COCWidgetAlarm = 0,
    COCWidgetWeather,
    COCWidgetBattery,
    COCWidgetDate,
    COCWidgetText,
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
        default: return [UIColor colorWithRed:1 green:1 blue:1 alpha:1];          // белый
    }
}

@implementation COCClockView {
    COCDigitsView *_digits;
    UILabel *_dateL;
    UILabel *_weatherL;     // только в варианте 3 (справа в строке даты)
    NSMutableArray<COCWidgetCard *> *_cards;
    NSTimer *_timer;
    NSDateFormatter *_fmt;
    UIColor *_tint;

    // Кэш настроек
    BOOL _enabled, _use24, _wEn, _wAlarm, _wWeather, _wBat, _wDate, _wTxt, _showWeather;
    NSInteger _style, _colorIdx;
    CGFloat _pT, _pL, _pB, _pR;
    CGFloat _size, _w, _h, _op, _ox, _oy;
    CGFloat _wOp, _wRad, _wScale;
    NSString *_txt, *_city;
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

        _weatherL = [[UILabel alloc] init];
        _weatherL.textAlignment = NSTextAlignmentRight;
        [self addSubview:_weatherL];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(weatherUpdated)
                                                     name:COCWeatherUpdated object:nil];
        [self reloadPrefs];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_timer invalidate];
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

- (void)tick { [self refreshContent]; }
- (void)weatherUpdated { [self refreshContent]; [self setNeedsLayout]; }

#pragma mark Настройки

- (void)reloadPrefs {
    _enabled  = COCB(@"enabled", YES);
    _style    = (NSInteger)COCF(@"layout", 1);
    _use24    = COCB(@"use24h", YES);
    _colorIdx = (NSInteger)COCF(@"clockColor", 1);

    _pT = COCF(@"padTop", 110);
    _pL = COCF(@"padLeft", 24);
    _pB = COCF(@"padBottom", 0);
    _pR = COCF(@"padRight", 24);

    _size = COCF(@"size", 100);
    _w    = COCF(@"width", 100);
    _h    = COCF(@"height", 100);
    _op   = COCF(@"clockOpacity", 100);
    _ox   = COCF(@"offsetX", 0);
    _oy   = COCF(@"offsetY", 0);

    _wEn      = COCB(@"widgetsEnabled", YES);
    _wAlarm   = COCB(@"widgetAlarm", YES);
    _wWeather = COCB(@"widgetWeather", YES);
    _wBat     = COCB(@"widgetBattery", NO);
    _wDate    = COCB(@"widgetDate", NO);
    _wTxt     = COCB(@"widgetText", NO);
    _txt      = COCS(@"widgetTextValue", @"ColorOS");
    _wOp      = COCF(@"widgetOpacity", 20);
    _wRad     = COCF(@"widgetRadius", 18);
    _wScale   = COCF(@"widgetScale", 100);
    _showWeather = COCB(@"showWeather", YES);
    _city        = COCS(@"weatherCity", @"Moscow");

    if (_style < 1 || _style > 3) _style = 1;

    self.hidden = !_enabled;

    _tint = COCPaletteColor(_colorIdx);
    _digits.color = _tint;

    // Перестраиваем виджеты (порядок: будильник, погода, батарея, дата, заметка)
    for (COCWidgetCard *c in _cards) [c removeFromSuperview];
    [_cards removeAllObjects];
    if (_wEn) {
        BOOL on[5] = { _wAlarm, _wWeather, _wBat, _wDate, _wTxt };
        for (NSInteger i = 0; i < 5; i++) {
            if (!on[i]) continue;
            COCWidgetCard *card = [[COCWidgetCard alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
            card.tag = i;
            [self addSubview:card];
            [_cards addObject:card];
        }
    }

    [self refreshContent];
    [self setNeedsLayout];
}

#pragma mark Содержимое

- (NSAttributedString *)weatherAttrWithFont:(UIFont *)font color:(UIColor *)color {
    UIImage *img = [UIImage systemImageNamed:COCWeatherSymbol(COCWCode)];
    img = [img imageWithTintColor:color renderingMode:UIImageRenderingModeAlwaysOriginal];
    NSTextAttachment *a = [[NSTextAttachment alloc] init];
    a.image = img;
    CGFloat h = font.pointSize * 0.95;
    CGFloat w = img.size.height > 0 ? img.size.width * (h / img.size.height) : h;
    a.bounds = CGRectMake(0, -font.pointSize * 0.18, w, h);

    NSMutableAttributedString *m = [[NSMutableAttributedString alloc] initWithAttributedString:
                                    [NSAttributedString attributedStringWithAttachment:a]];
    NSString *t = [NSString stringWithFormat:@" %d°", (int)lround(COCWTemp)];
    [m appendAttributedString:[[NSAttributedString alloc] initWithString:t attributes:
        @{ NSFontAttributeName: font, NSForegroundColorAttributeName: color }]];
    return m;
}

- (void)refreshContent {
    NSDate *now = [NSDate date];

    // Ведущий ноль всегда: 0851
    _fmt.dateFormat = _use24 ? @"HH" : @"hh";
    NSString *h = [_fmt stringFromDate:now];
    _fmt.dateFormat = @"mm";
    NSString *m = [_fmt stringFromDate:now];
    _digits.lines = (_style == 1) ? @[ h, m ] : @[ [h stringByAppendingString:m] ];

    // Погода
    if (_showWeather || _wWeather) COCWeatherRefresh(_city);
    BOOL showW = _showWeather && COCWValid;

    // Дата / погода рядом с часами
    NSString *(^fmt)(NSString *) = ^NSString *(NSString *tpl) {
        self->_fmt.dateFormat = [NSDateFormatter dateFormatFromTemplate:tpl options:0
                                                                 locale:[NSLocale currentLocale]];
        return [self->_fmt stringFromDate:now];
    };
    NSString *dm = fmt(@"dMMM");
    NSString *wd = fmt(@"EEE");
    UIColor *col = [_tint colorWithAlphaComponent:0.92];

    if (_style == 3) {
        UIFont *f = [UIFont systemFontOfSize:18 weight:UIFontWeightRegular];
        _dateL.numberOfLines = 1;
        _dateL.attributedText = [[NSAttributedString alloc]
            initWithString:[NSString stringWithFormat:@"%@  %@", dm, wd]
                attributes:@{ NSFontAttributeName: f, NSForegroundColorAttributeName: col }];
        _weatherL.attributedText = showW ? [self weatherAttrWithFont:f color:col] : nil;
    } else {
        UIFont *f = [UIFont systemFontOfSize:20 weight:UIFontWeightMedium];
        NSDictionary *attrs = @{ NSFontAttributeName: f, NSForegroundColorAttributeName: col };
        NSMutableAttributedString *ms = [[NSMutableAttributedString alloc]
            initWithString:[NSString stringWithFormat:@"%@\n%@", dm, wd] attributes:attrs];
        if (showW) {
            [ms appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:attrs]];
            [ms appendAttributedString:[self weatherAttrWithFont:f color:col]];
        }
        NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
        ps.lineSpacing = 3;
        [ms addAttribute:NSParagraphStyleAttributeName value:ps range:NSMakeRange(0, ms.length)];
        _dateL.numberOfLines = 0;
        _dateL.attributedText = ms;
        _weatherL.attributedText = nil;
    }

    // Содержимое виджетов
    for (COCWidgetCard *card in _cards) {
        switch (card.tag) {
            case COCWidgetAlarm: {
                NSDate *ad = COCNextAlarmDate();
                NSString *v = @"—";
                if (ad) {
                    _fmt.dateFormat = _use24 ? @"HH:mm" : @"h:mm";
                    v = [_fmt stringFromDate:ad];
                }
                [card setSymbol:@"alarm.fill" value:v];
                break;
            }
            case COCWidgetWeather: {
                NSString *v = COCWValid ? [NSString stringWithFormat:@"%d°", (int)lround(COCWTemp)] : @"—";
                [card setSymbol:(COCWValid ? COCWeatherSymbol(COCWCode) : @"cloud.fill") value:v];
                break;
            }
            case COCWidgetBattery: {
                UIDevice *dev = UIDevice.currentDevice;
                float lvl = dev.batteryLevel;
                NSString *v = lvl < 0 ? @"—" : [NSString stringWithFormat:@"%d%%", (int)roundf(lvl * 100)];
                BOOL chg = dev.batteryState == UIDeviceBatteryStateCharging ||
                           dev.batteryState == UIDeviceBatteryStateFull;
                [card setSymbol:(chg ? @"battery.100.bolt" : @"battery.100") value:v];
                break;
            }
            case COCWidgetDate:
                [card setSymbol:@"calendar" value:dm];
                break;
            case COCWidgetText:
                [card setSymbol:@"star.fill" value:_txt];
                break;
        }
    }

    [self setNeedsLayout];
}

#pragma mark Раскладка

- (void)layoutSubviews {
    [super layoutSubviews];

    // Область контента: границы минус отступы, плюс смещение
    CGRect R = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(_pT, _pL, _pB, _pR));
    R = CGRectOffset(R, _ox, _oy);
    CGFloat u = R.size.width;

    // «Размер» — общий масштаб, «ширина/высота» — растяжение поверх него
    CGFloat k = _size / 100.0;
    CGFloat sx = k * _w / 100.0, sy = k * _h / 100.0;

    // Квадрат виджета как на скринах ColorOS: ~19% ширины области
    CGFloat ws = _wScale / 100.0;
    CGFloat sq = 0.19 * u * ws;
    CGFloat colGap = MAX(8, sq * 0.18);

    CGRect dr;
    _weatherL.hidden = (_style != 3);

    if (_style == 3) {
        // Вариант 3: строка «дата — погода», 0851 во всю ширину, виджеты под цифрами
        [_dateL sizeToFit];
        [_weatherL sizeToFit];
        CGSize ds = _dateL.bounds.size, wsz = _weatherL.bounds.size;
        CGFloat rowH = MAX(ds.height, wsz.height);
        _dateL.frame = CGRectMake(R.origin.x, R.origin.y, ds.width, ds.height);
        _weatherL.frame = CGRectMake(CGRectGetMaxX(R) - wsz.width, R.origin.y, wsz.width, wsz.height);
        dr = CGRectMake(R.origin.x, R.origin.y + rowH + 14, u * sx, u * 0.774 * sy);
    } else {
        if (_style == 1) {
            // Вариант 1: вертикальные цифры слева (08 над 51)
            CGFloat bw = u * 0.36;
            CGFloat bh = bw * 1.9 * 2.06;
            _digits.gapRatio = 0.03;
            dr = CGRectMake(R.origin.x, R.origin.y, bw * sx, bh * sy);
        } else {
            // Вариант 2: компактное 0851 (~68% ширины)
            CGFloat bw = u * 0.68;
            dr = CGRectMake(R.origin.x, R.origin.y, bw * sx, bw * 1.04 * sy);
        }
        // Дата тремя строками под цифрами
        CGSize ds = [_dateL sizeThatFits:CGSizeMake(MAX(u * 0.5, 80), CGFLOAT_MAX)];
        _dateL.frame = CGRectMake(R.origin.x, CGRectGetMaxY(dr) + 12, ds.width, ds.height);
    }

    _digits.frame = dr;
    _digits.alpha = _op / 100.0;
    _dateL.alpha = _op / 100.0;
    _weatherL.alpha = _op / 100.0;

    // Карточки
    NSUInteger n = _cards.count;
    CGFloat radius = MIN(_wRad * ws, sq / 2.0);
    for (COCWidgetCard *c in _cards) {
        c.fillAlpha = _wOp / 100.0 * 0.5;
        c.layer.cornerRadius = radius;
        if (@available(iOS 13.0, *)) c.layer.cornerCurve = kCACornerCurveContinuous;
    }
    if (n == 0) return;

    if (_style == 3) {
        // Ряд под цифрами: 1 — слева, 2 — по краям, 3+ — равномерно
        CGFloat y = CGRectGetMaxY(dr) + u * 0.07;
        for (NSUInteger i = 0; i < n; i++) {
            CGFloat x = (n == 1) ? R.origin.x : R.origin.x + i * (u - sq) / (n - 1);
            _cards[i].frame = CGRectMake(x, y, sq, sq);
        }
    } else {
        // Колонка квадратов у правого края
        CGFloat x = CGRectGetMaxX(R) - sq;
        CGFloat y = R.origin.y;
        for (COCWidgetCard *c in _cards) {
            c.frame = CGRectMake(x, y, sq, sq);
            y += sq + colGap;
        }
    }
}

@end
