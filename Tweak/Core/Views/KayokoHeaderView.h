//
//  KayokoHeaderView.h
//  Kayoko
//

#import <UIKit/UIKit.h>

@class KayokoGrabberView;
@class KayokoHeaderCountBadgeView;

NS_ASSUME_NONNULL_BEGIN

static CGFloat const kKayokoHeaderContentSpacing = 8;

@interface KayokoHeaderView : UIView

@property(nonatomic, strong, readonly) KayokoGrabberView *grabber;
@property(nonatomic, strong, readonly) UILabel *titleLabel;
@property(nonatomic, strong, readonly) UIControl *titleTapControl;
@property(nonatomic, strong, readonly) UIButton *leadingButton;
@property(nonatomic, strong, readonly) UIButton *trailingButton;
@property(nonatomic, strong, readonly) UIButton *alternateTrailingButton;
// Item-count badge that rides directly after the title, e.g. "历史记录 (12)".
// It is nil-free by construction: the badge exists for every header, it is only
// hidden when there is nothing meaningful to show.
@property(nonatomic, strong, readonly) KayokoHeaderCountBadgeView *countBadgeView;
// Transparent interaction surface for the count capsule menu. The badge itself
// remains a render-only view so it cannot swallow or compete with taps.
@property(nonatomic, strong, readonly) UIButton *countBadgeControl;
@property(nonatomic, assign) CGFloat grabberFoldProgress;

+ (CGFloat)preferredHeight;
- (instancetype)initWithTitle:(NSString *)title NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (void)setTitleText:(NSString *)title;
// Drives the badge. A zero count remains visible for an empty list; callers
// hide it only for content that has no list count, so it is cheap to call from
// every content-state update.
- (void)setCountBadgeHidden:(BOOL)hidden count:(NSUInteger)count;
- (void)updateStyleForButton:(UIButton *)button
               withImageName:(NSString *)imageName
                   imageSize:(NSUInteger)imageSize
                   tintColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
