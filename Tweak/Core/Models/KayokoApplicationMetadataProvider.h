//
//  KayokoApplicationMetadataProvider.h
//  Kayoko
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KayokoApplicationMetadataProvider : NSObject

// Every accessor below reaches SpringBoard's SBApplicationController through
// XPC. That is cheap once but not cheap in a loop: the search token list sorts
// and then labels every installed application, and every visible cell resolves
// a display name, so an uncached provider turned one list reload into hundreds
// of synchronous round trips on the main thread. Results are cached per bundle
// identifier; call -invalidateCache when the installed application set changes.
- (NSString *)displayNameForBundleIdentifier:(NSString *)bundleIdentifier;
- (BOOL)hasApplicationForBundleIdentifier:(NSString *)bundleIdentifier;
- (nullable UIImage *)iconForBundleIdentifier:(NSString *)bundleIdentifier;
- (nullable UIImage *)smallIconForBundleIdentifier:(NSString *)bundleIdentifier;

- (void)invalidateCache;

@end

NS_ASSUME_NONNULL_END
