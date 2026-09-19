//
//  KayokoTableViewCell.m
//  Kayoko
//
//  Created by Alexandra Aurora Göttlicher
//

#import "KayokoTableViewCell.h"
#import "KayokoTableViewCellContent.h"
#import "KayokoTagColorFormatter.h"

#import <QuartzCore/QuartzCore.h>

static CGFloat const kKayokoTableViewCellTagDotSize = 7;
static CGFloat const kKayokoTableViewCellContentImageWidth = 70;
static CGFloat const kKayokoTableViewCellContentImageSingleLineHeight = 40;
static CGFloat const kKayokoTableViewCellContentImageAdditionalLineHeight = 15;
static NSUInteger const kKayokoTableViewCellMaximumPreviewLineCount = 3;
// The icon is 40pt. iOS app icons are squircles roughly 22.37% of their side in
// corner radius, which is what the system uses for the Home Screen; a fixed 10pt
// was noticeably squarer than the icons it was drawing.
static CGFloat const kKayokoTableViewCellIconSideLength = 40;
static CGFloat const kKayokoTableViewCellIconCornerRadius = 9;
// The timestamp shares the title row, so it must stay narrow enough to leave the
// title usable. "09-19 19:26" at 11pt is ~60pt; cap it a little above that and
// let the label shrink rather than wrap.
static CGFloat const kKayokoTableViewCellTimestampMaximumWidth = 72;
// 11pt reads clearly at a glance, unlike the 9pt this used to be.
static CGFloat const kKayokoTableViewCellTimestampFontSize = 11;
// Gap between the app icon and the timestamp on the title row.
static CGFloat const kKayokoTableViewCellIconTimestampSpacing = 8;
// Gap between the timestamp and the title that follows it.
static CGFloat const kKayokoTableViewCellTimestampTitleSpacing = 8;

@interface KayokoTableViewCellPreviewLabel : UILabel
@end

@implementation KayokoTableViewCellPreviewLabel

- (void)drawTextInRect:(CGRect)rect {
    CGRect textRect = [self textRectForBounds:rect limitedToNumberOfLines:[self numberOfLines]];
    textRect.origin = rect.origin;
    textRect.size.width = rect.size.width;
    [super drawTextInRect:textRect];
}

@end

@interface KayokoTableViewCell ()
@property(nonatomic, copy, nullable) NSString *representedImageName;
@end

@implementation KayokoTableViewCell

+ (NSString *)reuseIdentifierForContent:(KayokoTableViewCellContent *)content {
    NSUInteger lineCount = MIN(MAX([content previewLineCount], 1), kKayokoTableViewCellMaximumPreviewLineCount);
    BOOL hasContentImageSlot = [content contentImage] || [[content thumbnailImageName] length] > 0;
    BOOL hasTagDot = [[content tagHexColor] length] > 0;
    BOOL hasContentText = [[content contentText] length] > 0;
    BOOL hasTimestamp = [[content timestampText] length] > 0;
    return [NSString stringWithFormat:@"KayokoTableViewCell-%lu-%d-%d-%d-%d-%d", (unsigned long)lineCount,
                                      hasContentImageSlot, hasTagDot, hasContentText, [content showsDetail],
                                      hasTimestamp];
}

+ (CGSize)contentImageViewSizeForPreviewLineCount:(NSUInteger)previewLineCount {
    NSUInteger lineCount = MIN(MAX(previewLineCount, 1), kKayokoTableViewCellMaximumPreviewLineCount);
    CGFloat height = kKayokoTableViewCellContentImageSingleLineHeight +
                     (lineCount - 1) * kKayokoTableViewCellContentImageAdditionalLineHeight;
    return CGSizeMake(kKayokoTableViewCellContentImageWidth, height);
}

+ (CGSize)contentImageThumbnailSize {
    CGSize maximumViewSize = [self contentImageViewSizeForPreviewLineCount:kKayokoTableViewCellMaximumPreviewLineCount];
    CGFloat sideLength = MAX(maximumViewSize.width, maximumViewSize.height);
    return CGSizeMake(sideLength, sideLength);
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
                      content:(KayokoTableViewCellContent *)content
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        NSUInteger lineCount = MIN(MAX([content previewLineCount], 1), kKayokoTableViewCellMaximumPreviewLineCount);
        CGSize contentImageViewSize = [[self class] contentImageViewSizeForPreviewLineCount:lineCount];
        BOOL hasContentText = [[content contentText] length] > 0;
        BOOL showsDetail = [content showsDetail];
        BOOL hasTimestamp = [[content timestampText] length] > 0;
        [self setBackgroundColor:[UIColor clearColor]];
        UIView *selectedBackgroundView = [[UIView alloc] init];
        UIColor *selectedBackgroundColor =
            [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
              if ([traitCollection userInterfaceStyle] == UIUserInterfaceStyleDark) {
                  return [UIColor colorWithWhite:1 alpha:0.08];
              }

              return [UIColor colorWithWhite:0 alpha:0.055];
            }];
        [selectedBackgroundView setBackgroundColor:selectedBackgroundColor];
        [self setSelectedBackgroundView:selectedBackgroundView];

        [self setIconImageView:[[UIImageView alloc] init]];
        [[self iconImageView] setContentMode:UIViewContentModeScaleAspectFit];
        [[self iconImageView] setClipsToBounds:YES];
        [[[self iconImageView] layer] setCornerRadius:kKayokoTableViewCellIconCornerRadius];
        // Continuous curvature: a plain circular corner on a 40pt tile looks
        // visibly different from the squircle iOS uses for app icons, which is
        // the giveaway when a row mixes system icons with this one.
        [[[self iconImageView] layer] setCornerCurve:kCACornerCurveContinuous];
        // Matches the hairline the settings header draws around its icon, so an
        // icon whose artwork does not reach the edges still reads as a tile.
        [[[self iconImageView] layer] setBorderWidth:0.5];
        [[[self iconImageView] layer]
            setBorderColor:[[[UIColor labelColor] colorWithAlphaComponent:0.10] CGColor]];
        [self addSubview:[self iconImageView]];

        [[self iconImageView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        // No centerY pin here: vertical placement is resolved later, once we
        // know which labels are present (see "Vertical alignment" below).
        [NSLayoutConstraint activateConstraints:@[
            [[[self iconImageView] widthAnchor] constraintEqualToConstant:kKayokoTableViewCellIconSideLength],
            [[[self iconImageView] heightAnchor] constraintEqualToConstant:kKayokoTableViewCellIconSideLength],
            [[[self iconImageView] leadingAnchor] constraintEqualToAnchor:[self leadingAnchor] constant:24]
        ]];

        UIImage *contentImage = [content contentImage];
        NSString *thumbnailImageName = [content thumbnailImageName];
        BOOL hasContentImageSlot = contentImage || [thumbnailImageName length] > 0;
        [self setRepresentedImageName:thumbnailImageName];
        if (hasContentImageSlot) {
            [self setContentImageView:[[UIImageView alloc] init]];
            [[self contentImageView] setImage:contentImage];

            [[self contentImageView] setContentMode:UIViewContentModeScaleAspectFill];
            [[self contentImageView] setClipsToBounds:YES];
            [[self contentImageView]
                setBackgroundColor:contentImage ? [UIColor clearColor] : [UIColor tertiarySystemFillColor]];
            [[[self contentImageView] layer] setCornerRadius:6];
            [[[self contentImageView] layer] setCornerCurve:kCACornerCurveContinuous];
            [self addSubview:[self contentImageView]];

            [[self contentImageView] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [NSLayoutConstraint activateConstraints:@[
                [[[self contentImageView] widthAnchor] constraintEqualToConstant:contentImageViewSize.width],
                [[[self contentImageView] heightAnchor] constraintEqualToConstant:contentImageViewSize.height],
                [[[self contentImageView] centerYAnchor] constraintEqualToAnchor:[self centerYAnchor]],
                [[[self contentImageView] trailingAnchor] constraintEqualToAnchor:[self trailingAnchor] constant:-24]
            ]];
        }

        [self setHeaderLabel:[[UILabel alloc] init]];
        [[self headerLabel] setFont:[UIFont systemFontOfSize:16 weight:UIFontWeightMedium]];
        [[self headerLabel] setTextColor:[UIColor labelColor]];
        [[self headerLabel] setLineBreakMode:NSLineBreakByTruncatingTail];
        [[self headerLabel] setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                              forAxis:UILayoutConstraintAxisHorizontal];
        [[self headerLabel] setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                            forAxis:UILayoutConstraintAxisHorizontal];
        [self addSubview:[self headerLabel]];

        [[self headerLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];

        NSLayoutXAxisAnchor *textTrailingAnchor =
            [self contentImageView] ? [[self contentImageView] leadingAnchor] : [self trailingAnchor];
        CGFloat textTrailingConstant = [self contentImageView] ? -16 : -24;

        // The timestamp shares the title row: icon -> timestamp -> title. It used
        // to hang below the icon as two stacked lines, which made the left column
        // taller than the icon and forced the row height to depend on a text
        // style toggle. On the title line the row height is the same with the
        // timestamp on or off, and the eye reads "when" and "what" together.
        if (hasTimestamp) {
            [self setTimestampLabel:[[UILabel alloc] init]];
            [[self timestampLabel] setFont:[UIFont systemFontOfSize:kKayokoTableViewCellTimestampFontSize
                                                             weight:UIFontWeightRegular]];
            [[self timestampLabel] setTextColor:[UIColor secondaryLabelColor]];
            [[self timestampLabel] setTextAlignment:NSTextAlignmentLeft];
            [[self timestampLabel] setLineBreakMode:NSLineBreakByTruncatingTail];
            // Never wrap: this is a fixed-format stamp on a single-line row.
            [[self timestampLabel] setNumberOfLines:1];
            // The timestamp is fixed-length; it should neither stretch to fill
            // slack nor get squeezed to nothing when the title is long. The title
            // wins the tug-of-war and truncates instead.
            [[self timestampLabel] setContentHuggingPriority:UILayoutPriorityRequired
                                                     forAxis:UILayoutConstraintAxisHorizontal];
            [[self timestampLabel] setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                                  forAxis:UILayoutConstraintAxisHorizontal];
            [self addSubview:[self timestampLabel]];
            [[self timestampLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];

            [NSLayoutConstraint activateConstraints:@[
                [[[self timestampLabel] leadingAnchor] constraintEqualToAnchor:[[self iconImageView] trailingAnchor]
                                                                      constant:kKayokoTableViewCellIconTimestampSpacing],
                [[[self timestampLabel] centerYAnchor] constraintEqualToAnchor:[[self iconImageView] centerYAnchor]],
                [[[self timestampLabel] widthAnchor]
                    constraintLessThanOrEqualToConstant:kKayokoTableViewCellTimestampMaximumWidth],
                [[[self headerLabel] leadingAnchor] constraintEqualToAnchor:[[self timestampLabel] trailingAnchor]
                                                                   constant:kKayokoTableViewCellTimestampTitleSpacing],
                [[[self timestampLabel] trailingAnchor] constraintLessThanOrEqualToAnchor:textTrailingAnchor
                                                                                 constant:textTrailingConstant]
            ]];
        } else {
            [NSLayoutConstraint activateConstraints:@[ [[[self headerLabel] leadingAnchor]
                                                        constraintEqualToAnchor:[[self iconImageView] trailingAnchor]
                                                                       constant:16] ]];
        }

        if ([[content tagHexColor] length] > 0) {
            [self setTagDotView:[[UIView alloc] init]];
            [[[self tagDotView] layer] setCornerRadius:kKayokoTableViewCellTagDotSize / 2.0];
            [self addSubview:[self tagDotView]];
            [[self tagDotView] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [NSLayoutConstraint activateConstraints:@[
                [[[self tagDotView] leadingAnchor] constraintEqualToAnchor:[[self headerLabel] trailingAnchor]
                                                                  constant:6],
                [[[self tagDotView] widthAnchor] constraintEqualToConstant:kKayokoTableViewCellTagDotSize],
                [[[self tagDotView] heightAnchor] constraintEqualToConstant:kKayokoTableViewCellTagDotSize],
                [[[self tagDotView] centerYAnchor] constraintEqualToAnchor:[[self headerLabel] centerYAnchor]],
                [[[self tagDotView] trailingAnchor] constraintLessThanOrEqualToAnchor:textTrailingAnchor
                                                                            constant:textTrailingConstant]
            ]];
        } else {
            [NSLayoutConstraint activateConstraints:@[ [[[self headerLabel] trailingAnchor]
                                                        constraintEqualToAnchor:textTrailingAnchor
                                                                       constant:textTrailingConstant] ]];
        }

        if (hasContentText) {
            [self setContentLabel:[[KayokoTableViewCellPreviewLabel alloc] init]];
            [[self contentLabel] setFont:[UIFont systemFontOfSize:14]];
            [[self contentLabel] setTextColor:[[UIColor labelColor] colorWithAlphaComponent:0.8]];
            [[self contentLabel] setLineBreakMode:NSLineBreakByTruncatingTail];
            [[self contentLabel] setNumberOfLines:lineCount];
            [self addSubview:[self contentLabel]];
            [[self contentLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
            CGFloat previewLabelHeight = ceil([[[self contentLabel] font] lineHeight] * lineCount);
            [NSLayoutConstraint activateConstraints:@[
                [[[self contentLabel] topAnchor] constraintEqualToAnchor:[[self headerLabel] bottomAnchor] constant:2],
                [[[self contentLabel] leadingAnchor] constraintEqualToAnchor:[[self headerLabel] leadingAnchor]],
                [[[self contentLabel] trailingAnchor] constraintEqualToAnchor:textTrailingAnchor
                                                                     constant:textTrailingConstant],
                [[[self contentLabel] heightAnchor] constraintEqualToConstant:previewLabelHeight]
            ]];
        }

        if (showsDetail) {
            [self setDetailLabel:[[UILabel alloc] init]];
            [[self detailLabel] setFont:[UIFont systemFontOfSize:12]];
            [[self detailLabel] setTextColor:[UIColor secondaryLabelColor]];
            [[self detailLabel] setLineBreakMode:NSLineBreakByTruncatingTail];
            [self addSubview:[self detailLabel]];
            [[self detailLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [NSLayoutConstraint activateConstraints:@[
                [[[self detailLabel] leadingAnchor] constraintEqualToAnchor:[[self headerLabel] leadingAnchor]],
                [[[self detailLabel] trailingAnchor] constraintEqualToAnchor:textTrailingAnchor
                                                                    constant:textTrailingConstant]
            ]];
        }

        // Fallback vertical placement. These are deliberately BELOW required
        // priority: they are only a starting point so Auto Layout has a
        // deterministic layout before the centring guides below are added, and
        // they must yield to those guides. Leaving them at required priority
        // would make the header top pin (e.g. constant 13) fight the guide's
        // centring constraint whenever the text block is taller than the row is
        // assumed to be -- an unsatisfiable pair that logs a warning and can
        // render inconsistently. The >= / <= bounds stay required so content can
        // never be pushed outside the cell.
        NSArray<NSLayoutConstraint *> *fallbackConstraints = nil;
        if (hasContentText) {
            fallbackConstraints = @[ [[[self headerLabel] topAnchor] constraintEqualToAnchor:[self topAnchor]
                                                                                    constant:showsDetail ? 13 : 12] ];
            if (showsDetail) {
                [NSLayoutConstraint activateConstraints:@[
                    [[[self detailLabel] topAnchor] constraintEqualToAnchor:[[self contentLabel] bottomAnchor]
                                                                   constant:2],
                    [[[self detailLabel] bottomAnchor] constraintLessThanOrEqualToAnchor:[self bottomAnchor]
                                                                                constant:-8]
                ]];
            } else {
                [NSLayoutConstraint activateConstraints:@[ [[[self contentLabel] bottomAnchor]
                                                            constraintLessThanOrEqualToAnchor:[self bottomAnchor]
                                                                                     constant:-10] ]];
            }
        } else if (showsDetail) {
            [NSLayoutConstraint activateConstraints:@[
                [[[self detailLabel] topAnchor] constraintEqualToAnchor:[[self headerLabel] bottomAnchor] constant:1],
                [[[self detailLabel] bottomAnchor] constraintLessThanOrEqualToAnchor:[self bottomAnchor] constant:-8]
            ]];
            fallbackConstraints = @[ [[[self headerLabel] topAnchor] constraintGreaterThanOrEqualToAnchor:[self topAnchor]
                                                                                                 constant:8] ];
        } else {
            fallbackConstraints = @[ [[[self headerLabel] centerYAnchor] constraintEqualToAnchor:[self centerYAnchor]] ];
        }
        for (NSLayoutConstraint *constraint in fallbackConstraints) {
            [constraint setPriority:UILayoutPriorityDefaultHigh];
        }
        [NSLayoutConstraint activateConstraints:fallbackConstraints];

        // Vertical alignment.
        //
        // The icon used to be pinned to the cell centre while the timestamp hung
        // below it, which dragged the whole left column upwards when the
        // timestamp was on and left the two states disagreeing. The timestamp
        // now shares the title row, so the left column IS the icon (40pt) and
        // the original centre pin is correct again in both states -- but it is
        // expressed as bounds plus a guide rather than a hard pin, so a future
        // taller row still keeps the icon inside it.
        UILayoutGuide *iconColumnGuide = [[UILayoutGuide alloc] init];
        [self addLayoutGuide:iconColumnGuide];
        [NSLayoutConstraint activateConstraints:@[
            [[iconColumnGuide topAnchor] constraintEqualToAnchor:[[self iconImageView] topAnchor]],
            [[iconColumnGuide bottomAnchor] constraintEqualToAnchor:[[self iconImageView] bottomAnchor]],
            [[iconColumnGuide centerYAnchor] constraintEqualToAnchor:[self centerYAnchor]],
            [[[self iconImageView] topAnchor] constraintGreaterThanOrEqualToAnchor:[self topAnchor] constant:6],
            [[[self iconImageView] bottomAnchor] constraintLessThanOrEqualToAnchor:[self bottomAnchor] constant:-6]
        ]];

        // Right column: the text block centred as a unit.
        NSLayoutYAxisAnchor *textColumnBottomAnchor =
            showsDetail ? [[self detailLabel] bottomAnchor]
                        : (hasContentText ? [[self contentLabel] bottomAnchor] : [[self headerLabel] bottomAnchor]);
        UILayoutGuide *textColumnGuide = [[UILayoutGuide alloc] init];
        [self addLayoutGuide:textColumnGuide];
        [NSLayoutConstraint activateConstraints:@[
            [[textColumnGuide topAnchor] constraintEqualToAnchor:[[self headerLabel] topAnchor]],
            [[textColumnGuide bottomAnchor] constraintEqualToAnchor:textColumnBottomAnchor],
            [[textColumnGuide centerYAnchor] constraintEqualToAnchor:[self centerYAnchor]],
            [[textColumnGuide topAnchor] constraintGreaterThanOrEqualToAnchor:[self topAnchor] constant:6],
            [[textColumnGuide bottomAnchor] constraintLessThanOrEqualToAnchor:[self bottomAnchor] constant:-6]
        ]];

        [self applyContent:content];
    }

    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self setHidden:NO];
    [self setRepresentedImageName:nil];
    [[self iconImageView] setImage:nil];
    [[self headerLabel] setAttributedText:nil];
    [[self headerLabel] setText:nil];
    [[self timestampLabel] setText:nil];
    [[self tagDotView] setBackgroundColor:nil];
    [[self contentLabel] setAttributedText:nil];
    [[self contentLabel] setText:nil];
    [[self detailLabel] setAttributedText:nil];
    [[self detailLabel] setText:nil];
    [[self contentImageView] setImage:nil];
    [[self contentImageView] setBackgroundColor:[UIColor tertiarySystemFillColor]];
}

- (void)applyDetailContent:(KayokoTableViewCellContent *)content {
    NSAttributedString *attributedDetailText = [content attributedDetailText];
    if (!attributedDetailText) {
        [[self detailLabel] setAttributedText:nil];
        [[self detailLabel] setText:nil];
        return;
    }

    NSMutableAttributedString *styledDetailText = [attributedDetailText mutableCopy];
    [styledDetailText addAttribute:NSFontAttributeName
                             value:[[self detailLabel] font]
                             range:NSMakeRange(0, [styledDetailText length])];
    [[self detailLabel] setAttributedText:styledDetailText];
}

- (void)applyContent:(KayokoTableViewCellContent *)content {
    [[self iconImageView] setImage:[content icon]];

    if ([content attributedDisplayName]) {
        NSMutableAttributedString *attributedDisplayName = [[content attributedDisplayName] mutableCopy];
        NSRange fullRange = NSMakeRange(0, [attributedDisplayName length]);
        [attributedDisplayName addAttribute:NSFontAttributeName value:[[self headerLabel] font] range:fullRange];
        [attributedDisplayName addAttribute:NSForegroundColorAttributeName
                                      value:[[self headerLabel] textColor]
                                      range:fullRange];
        [[self headerLabel] setAttributedText:attributedDisplayName];
    } else {
        [[self headerLabel] setAttributedText:nil];
        [[self headerLabel] setText:[content displayName]];
    }

    if ([self tagDotView]) {
        [[self tagDotView] setBackgroundColor:[KayokoTagColorFormatter visibleColorFromHexColor:[content tagHexColor]]];
    }

    if ([self timestampLabel]) {
        [[self timestampLabel] setText:[content timestampText]];
    }

    NSUInteger lineCount = MIN(MAX([content previewLineCount], 1), kKayokoTableViewCellMaximumPreviewLineCount);
    [[self contentLabel] setNumberOfLines:lineCount];
    if ([content attributedContentText]) {
        NSMutableAttributedString *attributedText = [[content attributedContentText] mutableCopy];
        NSRange fullRange = NSMakeRange(0, [attributedText length]);
        [attributedText addAttribute:NSFontAttributeName value:[[self contentLabel] font] range:fullRange];
        [attributedText addAttribute:NSForegroundColorAttributeName
                               value:[[self contentLabel] textColor]
                               range:fullRange];
        [[self contentLabel] setAttributedText:attributedText];
    } else {
        [[self contentLabel] setAttributedText:nil];
        [[self contentLabel] setText:[content contentText] ?: @""];
    }
    [self applyDetailContent:content];

    UIImage *contentImage = [content contentImage];
    [self setRepresentedImageName:[content thumbnailImageName]];
    [[self contentImageView] setImage:contentImage];
    [[self contentImageView]
        setBackgroundColor:contentImage ? [UIColor clearColor] : [UIColor tertiarySystemFillColor]];
}

- (void)setContentImage:(UIImage *)image forImageName:(NSString *)imageName {
    if ([[self representedImageName] length] == 0 || ![[self representedImageName] isEqualToString:imageName]) {
        return;
    }

    if (![self contentImageView]) {
        return;
    }

    [[self contentImageView] setImage:image];
    [[self contentImageView] setBackgroundColor:image ? [UIColor clearColor] : [UIColor tertiarySystemFillColor]];
}

@end
