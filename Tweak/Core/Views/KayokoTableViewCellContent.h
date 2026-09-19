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
@property(nonatomic, copy, nullable) NSString *tagHexColor;
// Rendered as a single line on the title row, right after the app icon
// ("09-19 19:26").
@property(nonatomic, copy, nullable) NSString *timestampText;
@property(nonatomic, copy) NSString *contentText;
@property(nonatomic, copy, nullable) NSAttributedString *attributedContentText;
@property(nonatomic, copy, nullable) NSAttributedString *attributedDetailText;
@property(nonatomic, assign) BOOL showsDetail;
@property(nonatomic, strong, nullable) UIImage *contentImage;
@property(nonatomic, copy, nullable) NSString *thumbnailImageName;
@property(nonatomic, assign) NSUInteger previewLineCount;

@end

NS_ASSUME_NONNULL_END
