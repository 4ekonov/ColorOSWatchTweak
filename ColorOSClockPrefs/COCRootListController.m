#import <spawn.h>
#import <unistd.h>
#import <Preferences/PSSpecifier.h>
#import "COCRootListController.h"

static NSString *const kDomain = @"com.coloros.clocktweak";
static const char *kNotify = "com.coloros.clocktweak/prefsChanged";

@implementation COCRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

static void COCPostChange(void) {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         CFStringCreateWithCString(NULL, kNotify, kCFStringEncodingUTF8),
                                         NULL, NULL, YES);
}

// Кнопка «Сбросить настройки»
- (void)resetPrefs {
    for (PSSpecifier *spec in self.specifiers) {
        NSString *key = [spec propertyForKey:@"key"];
        if (key.length) {
            CFPreferencesSetAppValue((__bridge CFStringRef)key, NULL, (__bridge CFStringRef)kDomain);
        }
    }
    // Размер часов задаётся на экране блокировки и в списке настроек его нет — сбрасываем отдельно
    for (NSString *key in @[ @"size", @"width", @"height", @"collapseSize", @"widgetList", @"widgetPos",
                              @"widgetAlarm", @"widgetWeather", @"widgetBattery", @"widgetDate", @"widgetText" ]) {
        CFPreferencesSetAppValue((__bridge CFStringRef)key, NULL, (__bridge CFStringRef)kDomain);
    }
    CFPreferencesAppSynchronize((__bridge CFStringRef)kDomain);
    COCPostChange();
    [self reloadSpecifiers];
}

// Кнопка «Respring» (нужна, например, чтобы применить скрытие штатных часов)
- (void)respring {
    const char *paths[] = { "/var/jb/usr/bin/killall", "/usr/bin/killall" };
    for (int i = 0; i < 2; i++) {
        if (access(paths[i], X_OK) != 0) continue;
        pid_t pid;
        char *args[] = { "killall", "-9", "SpringBoard", NULL };
        posix_spawn(&pid, paths[i], NULL, NULL, args, NULL);
        return;
    }
}

@end
