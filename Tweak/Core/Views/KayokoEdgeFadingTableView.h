//
//  KayokoEdgeFadingTableView.h
//  Kayoko
//

#import <UIKit/UIKit.h>

#import "KayokoEdgeFadeMaskController.h"

NS_ASSUME_NONNULL_BEGIN

@interface KayokoEdgeFadingTableView : UITableView
@property(nonatomic, assign) CGFloat edgeFadeWidth;
@property(nonatomic, assign) CGFloat edgeFadeLeadingScrollOffset;
// Inset the fade envelope away from the scroll view's edges. The search header
// is a tableHeaderView, so its subviews live inside the scrolling content and
// would otherwise be dimmed by the leading fade as soon as the list scrolls.
@property(nonatomic, assign) UIEdgeInsets edgeFadeInsets;
@property(nonatomic, assign) KayokoEdgeFadeAxis edgeFadeAxis;
@property(nonatomic, assign, getter=isEdgeFadeEnabled) BOOL edgeFadeEnabled;
- (void)updateEdgeFadeMask;
@end

NS_ASSUME_NONNULL_END
