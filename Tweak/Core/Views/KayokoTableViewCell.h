//
//  KayokoTableViewCell.h
//  Kayoko
//
//  Created by Alexandra Aurora Göttlicher
//

#import <UIKit/UIKit.h>

@class KayokoTableViewCellContent;

NS_ASSUME_NONNULL_BEGIN

@interface KayokoTableViewCell : UITableViewCell

@property(nonatomic, strong) UIImageView *iconImageView;
@property(nonatomic, strong) UILabel *headerLabel;
// The timestamp is split into two labels rather than one two-line label: with a
// single label the intrinsic width is the *widest* line, and `numberOfLines = 0`
// combined with a bounded row height can drop the second line entirely ("19:26"
// went missing). Two stacked labels each size to their own content and cannot
// swallow one another.
@property(nonatomic, strong, nullable) UILabel *timestampDateLabel;
@property(nonatomic, strong, nullable) UILabel *timestampTimeLabel;
@property(nonatomic, strong, nullable) UIView *tagDotView;
@property(nonatomic, strong, nullable) UILabel *contentLabel;
@property(nonatomic, strong, nullable) UILabel *detailLabel;
@property(nonatomic, strong, nullable) UIImageView *contentImageView;

- (instancetype)initWithStyle:(UITableViewCellStyle)style
                      content:(KayokoTableViewCellContent *)content
              reuseIdentifier:(NSString *)reuseIdentifier;
+ (NSString *)reuseIdentifierForContent:(KayokoTableViewCellContent *)content;
+ (CGSize)contentImageViewSizeForPreviewLineCount:(NSUInteger)previewLineCount;
+ (CGSize)contentImageThumbnailSize;
- (void)applyDetailContent:(KayokoTableViewCellContent *)content;
- (void)applyContent:(KayokoTableViewCellContent *)content;
- (void)setContentImage:(nullable UIImage *)image forImageName:(NSString *)imageName;

@end

NS_ASSUME_NONNULL_END
