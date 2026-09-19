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
// The timestamp is drawn as two separate labels:
//
//   timestampTimeLabel -- "19:26", centred directly under the app icon and
//                         constrained to the icon's width, so it reads as a
//                         caption belonging to that icon.
//   timestampDateLabel -- "09-19", pinned to the trailing edge of the row at
//                         the same vertical centre as the time, where it acts
//                         as a column of dates down the right-hand side.
//
// Splitting them keeps the title row clear (the old single-line "MM-dd HH:mm"
// stamp sat between the icon and the title and squeezed the title), and the
// left column no longer depends on combining two strings into one label.
@property(nonatomic, strong, nullable) UILabel *timestampTimeLabel;
@property(nonatomic, strong, nullable) UILabel *timestampDateLabel;
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
