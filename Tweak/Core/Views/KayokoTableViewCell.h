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
// The timestamp sits on the title row, immediately to the right of the app
// icon and to the left of the title. It is one single-line "MM-dd HH:mm"
// label: the earlier two-line variant under the icon forced a taller row and
// read as a second column, which made the row height depend on a text style
// toggle. Keeping it on the title line means the row height is identical with
// the timestamp on or off.
@property(nonatomic, strong, nullable) UILabel *timestampLabel;
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
