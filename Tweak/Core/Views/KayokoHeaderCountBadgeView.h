//
//  KayokoHeaderCountBadgeView.h
//  Kayoko
//
//  The little capsule that sits after the header title and carries the item
//  count, e.g. "历史记录 (12)".
//
//  Why a capsule and not plain parentheses: the number lives in a fixed-width,
//  fixed-height pill so that a 1-digit / 2-digit / 3-digit count changes the
//  pill's width by a predictable amount and never re-flows the title's optical
//  centre by more than a hair. A bare "(12)" would sit at the title's own
//  weight and colour and read as part of the word rather than as data.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KayokoHeaderCountBadgeView : UIView

@property(nonatomic, strong, readonly) UILabel *countLabel;
@property(nonatomic, assign) NSUInteger count;

- (void)setCount:(NSUInteger)count animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
