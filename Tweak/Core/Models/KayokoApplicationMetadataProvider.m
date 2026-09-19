//
//  KayokoApplicationMetadataProvider.m
//  Kayoko
//

#import "KayokoApplicationMetadataProvider.h"
#import "KayokoPasteboardItem.h"
#import "KayokoPasteboardManager.h"

#import <objc/runtime.h>

static int const kKayokoApplicationIconFormatListRow = 1;
static int const kKayokoApplicationIconFormatSearchToken = 5;
// IconServices always has an icon for Safari, so it is a reliable neutral
// placeholder when a bundle identifier cannot be resolved (an app that was
// uninstalled, a revoked bundle id, etc.).
static NSString *const kKayokoFallbackBundleIdentifier = @"com.apple.WebSheet";
static NSString *const kKayokoSpotlightBundleIdentifier = @"com.apple.Spotlight";
static NSString *const kKayokoSpringBoardBundleIdentifier = @"com.apple.springboard";

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (IconCache)
+ (nullable instancetype)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier
                                                           format:(int)format
                                                            scale:(CGFloat)scale;
@end

@interface SBApplication : NSObject
@property(nonatomic, copy, readonly) NSString *displayName;
@end

@interface SBApplicationController : NSObject
+ (instancetype)sharedInstance;
- (SBApplication *)applicationWithBundleIdentifier:(NSString *)bundleIdentifier;
@end

NS_ASSUME_NONNULL_END

@interface KayokoApplicationMetadataProvider ()
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *displayNameCache;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *installedCache;
- (nullable SBApplication *)applicationForBundleIdentifier:(NSString *)bundleIdentifier;
@end

@implementation KayokoApplicationMetadataProvider

- (instancetype)init {
    self = [super init];
    if (self) {
        _displayNameCache = [[NSMutableDictionary alloc] init];
        _installedCache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)invalidateCache {
    [[self displayNameCache] removeAllObjects];
    [[self installedCache] removeAllObjects];
}

// A single XPC round trip per bundle identifier, remembered afterwards. The
// negative result ("this app is not installed") is cached too -- it is exactly
// the case that made the search token list slow, because uninstalled bundle
// identifiers show up in history and were re-queried on every reload.
- (nullable SBApplication *)cachedApplicationForBundleIdentifier:(NSString *)bundleIdentifier {
    NSNumber *cachedInstalled = [[self installedCache] objectForKey:bundleIdentifier];
    if (cachedInstalled && ![cachedInstalled boolValue]) {
        return nil;
    }

    SBApplication *application = [self applicationForBundleIdentifier:bundleIdentifier];
    [[self installedCache] setObject:@(application != nil) forKey:bundleIdentifier];
    return application;
}

- (NSString *)displayNameForBundleIdentifier:(NSString *)bundleIdentifier {
    if ([self isContinuityBundleIdentifier:bundleIdentifier]) {
        return [[KayokoPasteboardManager localizationBundle] localizedStringForKey:@"Continuity"
                                                                             value:nil
                                                                             table:@"Tweak"];
    }

    if ([self isSpotlightBundleIdentifier:bundleIdentifier]) {
        return [[KayokoPasteboardManager localizationBundle] localizedStringForKey:@"Spotlight"
                                                                             value:nil
                                                                             table:@"Tweak"];
    }

    if ([self isSpringBoardBundleIdentifier:bundleIdentifier]) {
        return [[KayokoPasteboardManager localizationBundle] localizedStringForKey:@"SpringBoard"
                                                                             value:nil
                                                                             table:@"Tweak"];
    }

    NSString *cacheKey = bundleIdentifier ?: @"";
    NSString *cachedName = [[self displayNameCache] objectForKey:cacheKey];
    if (cachedName) {
        return cachedName;
    }

    NSString *displayName = [[self cachedApplicationForBundleIdentifier:bundleIdentifier] displayName];
    NSString *resolvedName = [displayName length] > 0 ? displayName : (bundleIdentifier ?: @"");
    [[self displayNameCache] setObject:resolvedName forKey:cacheKey];
    return resolvedName;
}

- (BOOL)isContinuityBundleIdentifier:(NSString *)bundleIdentifier {
    NSString *normalizedBundleIdentifier = [[bundleIdentifier
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    return [normalizedBundleIdentifier isEqualToString:kKayokoContinuityBundleIdentifier] ||
           [normalizedBundleIdentifier isEqualToString:@"continuity"] ||
           [normalizedBundleIdentifier isEqualToString:@"handoff"];
}

- (BOOL)isSpotlightBundleIdentifier:(NSString *)bundleIdentifier {
    NSString *normalizedBundleIdentifier = [[bundleIdentifier
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    return [normalizedBundleIdentifier isEqualToString:[kKayokoSpotlightBundleIdentifier lowercaseString]] ||
           [normalizedBundleIdentifier isEqualToString:@"spotlight"];
}

- (nullable SBApplication *)applicationForBundleIdentifier:(NSString *)bundleIdentifier {
    return [[objc_getClass("SBApplicationController") sharedInstance] applicationWithBundleIdentifier:bundleIdentifier];
}

- (BOOL)isSpringBoardBundleIdentifier:(NSString *)bundleIdentifier {
    NSString *normalizedBundleIdentifier = [[bundleIdentifier
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    return [normalizedBundleIdentifier isEqualToString:kKayokoSpringBoardBundleIdentifier] ||
           [normalizedBundleIdentifier isEqualToString:@"springboard"];
}

- (BOOL)hasApplicationForBundleIdentifier:(NSString *)bundleIdentifier {
    if ([self isContinuityBundleIdentifier:bundleIdentifier]) {
        return YES;
    }
    if ([self isSpotlightBundleIdentifier:bundleIdentifier]) {
        return YES;
    }
    if ([self isSpringBoardBundleIdentifier:bundleIdentifier]) {
        return YES;
    }

    // Shares the cache with -displayNameForBundleIdentifier: so the token list,
    // which needs both answers per bundle identifier, only pays for one lookup.
    return [self cachedApplicationForBundleIdentifier:bundleIdentifier] != nil;
}

- (nullable UIImage *)continuityIcon {
    return [UIImage imageNamed:@"HandOff"
                             inBundle:[KayokoPasteboardManager localizationBundle]
        compatibleWithTraitCollection:nil];
}

- (nullable UIImage *)continuitySearchTokenIcon {
    UIImage *icon = [UIImage imageNamed:@"HandOff-Search"
                               inBundle:[KayokoPasteboardManager localizationBundle]
          compatibleWithTraitCollection:nil];
    return [icon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (nullable UIImage *)springBoardIcon {
    return [UIImage imageNamed:@"HomeScreen"
                             inBundle:[KayokoPasteboardManager localizationBundle]
        compatibleWithTraitCollection:nil];
}

- (nullable UIImage *)springBoardSearchTokenIcon {
    UIImage *icon = [UIImage imageNamed:@"HomeScreen-Search"
                               inBundle:[KayokoPasteboardManager localizationBundle]
          compatibleWithTraitCollection:nil];
    return [icon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (nullable UIImage *)spotlightIcon {
    return [UIImage imageNamed:@"Spotlight"
                             inBundle:[KayokoPasteboardManager localizationBundle]
        compatibleWithTraitCollection:nil];
}

- (nullable UIImage *)spotlightSearchTokenIcon {
    UIImage *icon = [UIImage imageNamed:@"Spotlight-Search"
                               inBundle:[KayokoPasteboardManager localizationBundle]
          compatibleWithTraitCollection:nil];
    return [icon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (nullable UIImage *)applicationIconForBundleIdentifier:(NSString *)bundleIdentifier
                                                  format:(int)format
                                                   scale:(CGFloat)scale {
    NSString *effectiveBundleIdentifier = [bundleIdentifier length] > 0 ? bundleIdentifier : kKayokoFallbackBundleIdentifier;
    // IconServices already caches this lookup; retaining another copy here would keep placeholder images stale after
    // the corresponding application becomes available.
    UIImage *icon = [UIImage _applicationIconImageForBundleIdentifier:effectiveBundleIdentifier
                                                               format:format
                                                                scale:scale];
    if (!icon && ![effectiveBundleIdentifier isEqualToString:kKayokoFallbackBundleIdentifier]) {
        icon = [UIImage _applicationIconImageForBundleIdentifier:kKayokoFallbackBundleIdentifier
                                                          format:format
                                                           scale:scale];
    }
    return icon;
}

- (nullable UIImage *)iconForBundleIdentifier:(NSString *)bundleIdentifier {
    if ([self isContinuityBundleIdentifier:bundleIdentifier]) {
        return [self continuityIcon];
    }

    if ([self isSpotlightBundleIdentifier:bundleIdentifier]) {
        return [self spotlightIcon];
    }

    if ([self isSpringBoardBundleIdentifier:bundleIdentifier]) {
        return [self springBoardIcon];
    }

    return [self applicationIconForBundleIdentifier:bundleIdentifier
                                             format:kKayokoApplicationIconFormatListRow
                                              scale:[[UIScreen mainScreen] scale]];
}

- (nullable UIImage *)smallIconForBundleIdentifier:(NSString *)bundleIdentifier {
    if ([self isContinuityBundleIdentifier:bundleIdentifier]) {
        return [self continuitySearchTokenIcon];
    }

    if ([self isSpotlightBundleIdentifier:bundleIdentifier]) {
        return [self spotlightSearchTokenIcon];
    }

    if ([self isSpringBoardBundleIdentifier:bundleIdentifier]) {
        return [self springBoardSearchTokenIcon];
    }

    return [self applicationIconForBundleIdentifier:bundleIdentifier
                                             format:kKayokoApplicationIconFormatSearchToken
                                              scale:[[UIScreen mainScreen] scale]];
}

@end
