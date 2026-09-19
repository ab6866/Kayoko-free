//
//  KayokoTableViewCellContent.h
//  Kayoko
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KayokoTableViewCellContent : NSObject

@property(nonatomic, strong, nullable) UIImage *icon;
@property(nonatomic, copy) NSString *displayName;
@property(nonatomic, copy, nullable) NSAttributedString *attributedDisplayName;
@property(nonatomic, copy, nullable) NSString *applicationName;
@property(nonatomic, copy, nullable) NSString *categoryName;
@property(nonatomic, copy, nullable) NSString *noteText;
@property(nonatomic, copy, nullable) NSString *tagHexColor;
// The timestamp is split across the row: the time ("19:26") sits directly under
// the app icon in the left column, and the date ("09-19") sits at the trailing
// edge on the same baseline. Keeping them apart means the title row is free of
// the stamp, the title gets the full width back, and the two halves of the
// timestamp are each anchored to something the eye already tracks -- the icon
// it came from, and the edge of the row.
@property(nonatomic, copy, nullable) NSString *timestampTimeText;
@property(nonatomic, copy, nullable) NSString *timestampDateText;
@property(nonatomic, copy) NSString *contentText;
@property(nonatomic, copy, nullable) NSAttributedString *attributedContentText;
@property(nonatomic, copy, nullable) NSAttributedString *attributedDetailText;
@property(nonatomic, assign) BOOL showsDetail;
// When YES the display name, the preview text and the timestamp are drawn in a
// bolder weight. The flag rides on the content object rather than the cell so a
// recycled cell cannot keep the previous row's weight.
@property(nonatomic, assign) BOOL showsBoldText;
@property(nonatomic, strong, nullable) UIImage *contentImage;
@property(nonatomic, copy, nullable) NSString *thumbnailImageName;
@property(nonatomic, assign) NSUInteger previewLineCount;

@end

NS_ASSUME_NONNULL_END
