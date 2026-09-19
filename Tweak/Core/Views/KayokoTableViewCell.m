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
// The time is a caption for the icon above it, so it is small and shares the
// icon's 40pt column. "19:26" at 11pt is ~29pt, which fits without truncating.
static CGFloat const kKayokoTableViewCellTimestampFontSize = 11;
// Gap between the bottom of the icon and the baseline area of its time caption.
static CGFloat const kKayokoTableViewCellIconTimestampSpacing = 3;
// Inset of the date from the trailing edge of the ROW. This is an absolute
// position, not a relative one: the date forms a column down the right-hand side
// and must not move when a row happens to carry a content thumbnail.
static CGFloat const kKayokoTableViewCellTimestampDateTrailingSpacing = 24;
// "09-19" at 11pt Regular is ~30pt. Reserving that as a hard minimum means the
// date can never be compressed into an ellipsis however long the surrounding
// content is; it is the difference between "the date is showing" and "the date
// is showing a fragment".
static CGFloat const kKayokoTableViewCellTimestampDateMinimumWidth = 34;
// Gap the text column must leave before the date column. The date is a fixed
// column that has to stay legible, so the title and the preview text are the
// ones that yield: they stop this far short of where the date begins rather
// than running underneath it.
static CGFloat const kKayokoTableViewCellTimestampDateTextSpacing = 8;
// Optical alignment of the text column against the 40pt icon.
//
// The icon is the tallest thing in the row and everything else is aligned to it.
// A 16pt label's line box is ~19pt tall while the glyphs inside it are ~11.5pt,
// so the visible top of a line sits roughly 3.5pt below the label's frame top;
// pulling the label up by that much puts the title's CAP HEIGHT level with the
// icon's top edge, which is what the eye reads as "aligned".
static CGFloat const kKayokoTableViewCellTitleIconOpticalOffset = 3.5;
// Same idea at the bottom: the last line's visible baseline sits a few points
// above the frame bottom, so the content label is pushed down slightly to land
// its descenders on the icon's bottom edge.
static CGFloat const kKayokoTableViewCellContentIconOpticalOffset = -1;
// The preview should breathe below the title without losing its bottom alignment
// to the icon column. Five points is enough to separate the two text roles while
// remaining inside the fixed row heights for one, two, and three preview lines.
static CGFloat const kKayokoTableViewCellTitleContentSpacing = 5;

// A preview label that draws its text from the TOP of its frame instead of
// vertically centred.
//
// Why a subclass at all: the preview's height is a fixed `lineHeight * lines`,
// which for a single line is a fraction taller than the glyphs themselves. UIKit
// centres the glyphs in that box, so a one-line preview sat a point or two lower
// than the title above it and the two-line preview looked detached. Pinning the
// text rect to the top keeps the first preview line welded to the title.
//
// The previous implementation ALSO reset the rect's width and origin, which let
// text overflow the label. `size.width` is deliberately left alone here: the
// text is clipped/truncated inside the label's own bounds, and the row reserves
// the date column with a constraint instead.
@interface KayokoTableViewCellPreviewLabel : UILabel
@end

@implementation KayokoTableViewCellPreviewLabel

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines {
    CGRect textRect = [super textRectForBounds:bounds limitedToNumberOfLines:numberOfLines];
    textRect.origin.y = bounds.origin.y;
    return textRect;
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:[self textRectForBounds:rect limitedToNumberOfLines:[self numberOfLines]]];
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
    BOOL hasTimestamp = [[content timestampTimeText] length] > 0 || [[content timestampDateText] length] > 0;
    return [NSString stringWithFormat:@"KayokoTableViewCell-%lu-%d-%d-%d-%d-%d-%d", (unsigned long)lineCount,
                                      hasContentImageSlot, hasTagDot, hasContentText, [content showsDetail],
                                      hasTimestamp, [content showsBoldText]];
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
        BOOL hasTimestamp = [[content timestampTimeText] length] > 0 || [[content timestampDateText] length] > 0;
        BOOL hasTimestampDate = [[content timestampDateText] length] > 0;
        BOOL showsBoldText = [content showsBoldText];
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
                [[[self contentImageView] centerYAnchor] constraintEqualToAnchor:[self centerYAnchor]]
            ]];
        }

        [self setHeaderLabel:[[UILabel alloc] init]];
        // The title carries the most information and gets the extra weight when
        // "Show Bold Text" is on; the regular weight is one step lighter than
        // the previous medium so the two states are clearly distinguishable.
        [[self headerLabel] setFont:[UIFont systemFontOfSize:16
                                                       weight:showsBoldText ? UIFontWeightSemibold
                                                                            : UIFontWeightMedium]];
        [[self headerLabel] setTextColor:[UIColor labelColor]];
        [[self headerLabel] setLineBreakMode:NSLineBreakByTruncatingTail];
        [[self headerLabel] setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                              forAxis:UILayoutConstraintAxisHorizontal];
        [[self headerLabel] setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                            forAxis:UILayoutConstraintAxisHorizontal];
        [self addSubview:[self headerLabel]];

        [[self headerLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];

        // The timestamp is split: the time is a caption under the icon, the date
        // is a right-hand column at the same height.
        //
        // Both use a dynamic colour rather than `secondaryLabelColor`. In light
        // mode the secondary label is ~60% black, which at 11pt over a light
        // blurred background is what made the old stamp hard to read; and on
        // dark backgrounds a translucent white was equally washed out. A
        // dynamic provider returning near-solid black / white keeps the stamp
        // legible in both styles while the smaller size keeps it subordinate to
        // the title.
        UIColor *timestampColor = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
          if ([traitCollection userInterfaceStyle] == UIUserInterfaceStyleDark) {
              return [UIColor colorWithWhite:1 alpha:0.92];
          }

          return [UIColor colorWithWhite:0 alpha:0.86];
        }];

        if (hasTimestamp) {
            CGFloat timestampWeight = showsBoldText ? UIFontWeightSemibold : UIFontWeightMedium;

            [self setTimestampTimeLabel:[[UILabel alloc] init]];
            [[self timestampTimeLabel] setFont:[UIFont systemFontOfSize:kKayokoTableViewCellTimestampFontSize
                                                                 weight:timestampWeight]];
            [[self timestampTimeLabel] setTextColor:timestampColor];
            [[self timestampTimeLabel] setTextAlignment:NSTextAlignmentCenter];
            [[self timestampTimeLabel] setLineBreakMode:NSLineBreakByTruncatingTail];
            [[self timestampTimeLabel] setNumberOfLines:1];
            // Fixed length: it should neither stretch nor get squeezed.
            [[self timestampTimeLabel] setContentHuggingPriority:UILayoutPriorityRequired
                                                         forAxis:UILayoutConstraintAxisHorizontal];
            [[self timestampTimeLabel] setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                                      forAxis:UILayoutConstraintAxisHorizontal];
            [self addSubview:[self timestampTimeLabel]];
            [[self timestampTimeLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];

            [self setTimestampDateLabel:[[UILabel alloc] init]];
            [[self timestampDateLabel] setFont:[UIFont systemFontOfSize:kKayokoTableViewCellTimestampFontSize
                                                                 weight:UIFontWeightRegular]];
            [[self timestampDateLabel] setTextColor:timestampColor];
            [[self timestampDateLabel] setTextAlignment:NSTextAlignmentRight];
            [[self timestampDateLabel] setLineBreakMode:NSLineBreakByTruncatingHead];
            [[self timestampDateLabel] setNumberOfLines:1];
            [[self timestampDateLabel] setContentHuggingPriority:UILayoutPriorityRequired
                                                         forAxis:UILayoutConstraintAxisHorizontal];
            [[self timestampDateLabel] setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                                      forAxis:UILayoutConstraintAxisHorizontal];
            [self addSubview:[self timestampDateLabel]];
            [[self timestampDateLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];

            [NSLayoutConstraint activateConstraints:@[
                // Time: under the icon, never wider than the icon itself so it
                // cannot push into the title column.
                [[[self timestampTimeLabel] topAnchor] constraintEqualToAnchor:[[self iconImageView] bottomAnchor]
                                                                      constant:kKayokoTableViewCellIconTimestampSpacing],
                [[[self timestampTimeLabel] centerXAnchor] constraintEqualToAnchor:[[self iconImageView] centerXAnchor]],
                [[[self timestampTimeLabel] leadingAnchor] constraintGreaterThanOrEqualToAnchor:
                                                                 [[self iconImageView] leadingAnchor]],
                [[[self timestampTimeLabel] trailingAnchor] constraintLessThanOrEqualToAnchor:
                                                                  [[self iconImageView] trailingAnchor]],
                // Date: right-aligned to the ROW's trailing edge -- always the
                // same x, whatever the item contains.
                //
                // It is deliberately NOT anchored to textTrailingAnchor: that
                // anchor moves leftwards when a content thumbnail is present, so
                // pinning the date to it made the date jump next to the image on
                // image items and sit at the far right on text items. A column of
                // dates has to line up down the list, so it belongs to the row
                // edge, not to whatever else is on the row.
                //
                // No collision with the thumbnail: the thumbnail is centred and
                // the date sits at the caption's height, below it (the caption
                // lives under the icon, which is the bottom of the left column).
                [[[self timestampDateLabel] trailingAnchor] constraintEqualToAnchor:[self trailingAnchor]
                                                                           constant:
                                                                               -kKayokoTableViewCellTimestampDateTrailingSpacing],
                [[[self timestampDateLabel] centerYAnchor]
                    constraintEqualToAnchor:[[self timestampTimeLabel] centerYAnchor]],
                // Hard floor: the date may never be squeezed narrower than the
                // width its own text needs. Without this, a long title or a long
                // preview could compress the stamp and the date would render as
                // an ellipsis ("...9-19") instead of a date.
                [[[self timestampDateLabel] widthAnchor]
                    constraintGreaterThanOrEqualToConstant:kKayokoTableViewCellTimestampDateMinimumWidth],
                // Never let the date run into the title column, and never let the
                // two halves of the stamp collide in the middle of the row.
                [[[self timestampDateLabel] leadingAnchor] constraintGreaterThanOrEqualToAnchor:
                                                               [[self iconImageView] trailingAnchor]
                                                                          constant:16]
            ]];
        }

        // Resolve the horizontal columns only after the date label exists. A
        // previous version asked `timestampDateLabel.leadingAnchor` for its
        // anchor before creating the label, which produced a nil anchor and
        // silently left the title/preview unconstrained. The date column is
        // now the stable right-hand boundary for every other right-side item.
        NSLayoutXAxisAnchor *dateLeadingAnchor =
            hasTimestampDate ? [[self timestampDateLabel] leadingAnchor] : nil;
        if ([self contentImageView]) {
            // The thumbnail yields to the fixed date column instead of sharing
            // the row's trailing inset with it. This prevents the date from
            // being painted over by an image item while preserving its x
            // position across every row.
            NSLayoutXAxisAnchor *imageTrailingAnchor = dateLeadingAnchor ?: [self trailingAnchor];
            CGFloat imageTrailingConstant = dateLeadingAnchor
                                               ? -kKayokoTableViewCellTimestampDateTextSpacing
                                               : -24;
            [[[self contentImageView] trailingAnchor]
                constraintEqualToAnchor:imageTrailingAnchor
                               constant:imageTrailingConstant].active = YES;
        }

        // Where the text column is allowed to end. When a date is present it
        // owns a reserved strip at the row's right edge. If a thumbnail is
        // present, text stops before the thumbnail; otherwise it stops before
        // the date itself. Either way, the preview can only truncate inside its
        // own frame and cannot draw through the date column.
        BOOL reservesDateColumn = hasTimestampDate;
        NSLayoutXAxisAnchor *textTrailingAnchor =
            reservesDateColumn && [self contentImageView]
                ? [[self contentImageView] leadingAnchor]
                : (reservesDateColumn ? dateLeadingAnchor
                                      : ([self contentImageView] ? [[self contentImageView] leadingAnchor]
                                                                 : [self trailingAnchor]));
        CGFloat textTrailingConstant =
            reservesDateColumn && [self contentImageView]
                ? -16
                : (reservesDateColumn ? -kKayokoTableViewCellTimestampDateTextSpacing
                                      : ([self contentImageView] ? -16 : -24));

        // The title always starts to the right of the icon now: neither half of
        // the timestamp shares its row any more.
        [NSLayoutConstraint activateConstraints:@[ [[[self headerLabel] leadingAnchor]
                                                    constraintEqualToAnchor:[[self iconImageView] trailingAnchor]
                                                                   constant:16] ]];

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
            [[self contentLabel]
                setFont:[UIFont systemFontOfSize:14 weight:showsBoldText ? UIFontWeightMedium : UIFontWeightRegular]];
            [[self contentLabel] setTextColor:[[UIColor labelColor] colorWithAlphaComponent:0.8]];
            [[self contentLabel] setLineBreakMode:NSLineBreakByTruncatingTail];
            [[self contentLabel] setNumberOfLines:lineCount];
            [self addSubview:[self contentLabel]];
            [[self contentLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
            CGFloat previewLabelHeight = ceil([[[self contentLabel] font] lineHeight] * lineCount);
            [NSLayoutConstraint activateConstraints:@[
                [[[self contentLabel] topAnchor]
                    constraintEqualToAnchor:[[self headerLabel] bottomAnchor]
                               constant:kKayokoTableViewCellTitleContentSpacing],
                [[[self contentLabel] leadingAnchor] constraintEqualToAnchor:[[self headerLabel] leadingAnchor]],
                [[[self contentLabel] trailingAnchor] constraintEqualToAnchor:textTrailingAnchor
                                                                     constant:textTrailingConstant],
                [[[self contentLabel] heightAnchor] constraintEqualToConstant:previewLabelHeight]
            ]];
        }

        if (showsDetail) {
            [self setDetailLabel:[[UILabel alloc] init]];
            [[self detailLabel] setFont:[UIFont systemFontOfSize:12 weight:UIFontWeightRegular]];
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
        // The two columns are aligned to the ICON, not centred as independent
        // blocks. That is what the row is actually asking for: the icon is the
        // row's anchor, the title hangs off its top edge, and the last line of
        // content sits on its bottom edge. Centring each column separately (the
        // previous behaviour) made a one-line item and a three-line item drift
        // off the icon by different amounts, so the icon never looked aligned
        // with anything.
        //
        // The left column still carries the time caption, and the caption is
        // still part of the column, so the icon cannot detach from its own
        // timestamp. What changed is that the column's position comes from the
        // cell's own vertical centre rather than from a centre-of-mass fit.
        NSLayoutYAxisAnchor *iconColumnBottomAnchor =
            hasTimestamp ? [[self timestampTimeLabel] bottomAnchor] : [[self iconImageView] bottomAnchor];
        UILayoutGuide *iconColumnGuide = [[UILayoutGuide alloc] init];
        [self addLayoutGuide:iconColumnGuide];
        [NSLayoutConstraint activateConstraints:@[
            [[iconColumnGuide topAnchor] constraintEqualToAnchor:[[self iconImageView] topAnchor]],
            [[iconColumnGuide bottomAnchor] constraintEqualToAnchor:iconColumnBottomAnchor],
            [[iconColumnGuide centerYAnchor] constraintEqualToAnchor:[self centerYAnchor]],
            [[[self iconImageView] topAnchor] constraintGreaterThanOrEqualToAnchor:[self topAnchor] constant:6],
            [iconColumnBottomAnchor constraintLessThanOrEqualToAnchor:[self bottomAnchor] constant:-6]
        ]];

        // Title top-aligned to the icon's top edge, content bottom-aligned to the
        // icon's bottom edge.
        //
        // Both are equalities at default-high priority so the icon column's own
        // centring (required) still wins when the row is shorter than the text
        // needs -- the text may then overflow slightly rather than the icon being
        // shoved out of the cell. The >= / <= pairs below are the hard bounds
        // that keep the text inside the cell in every case.
        NSLayoutYAxisAnchor *textBottomAnchor =
            showsDetail ? [[self detailLabel] bottomAnchor]
                        : (hasContentText ? [[self contentLabel] bottomAnchor] : [[self headerLabel] bottomAnchor]);
        NSMutableArray<NSLayoutConstraint *> *iconAlignedConstraints = [NSMutableArray array];
        // The title's cap-height sits a touch below the label's frame top, so a
        // bare equality reads as "title slightly low". Lifting by the difference
        // between the 40pt icon and the 16pt title's line box makes the optical
        // tops coincide.
        NSLayoutConstraint *titleTopConstraint =
            [[[self headerLabel] topAnchor] constraintEqualToAnchor:[[self iconImageView] topAnchor]
                                                           constant:-kKayokoTableViewCellTitleIconOpticalOffset];
        [titleTopConstraint setPriority:UILayoutPriorityDefaultHigh];
        [iconAlignedConstraints addObject:titleTopConstraint];
        if (textBottomAnchor != [[self headerLabel] bottomAnchor]) {
            NSLayoutConstraint *contentBottomConstraint =
                [textBottomAnchor constraintEqualToAnchor:[[self iconImageView] bottomAnchor]
                                                 constant:kKayokoTableViewCellContentIconOpticalOffset];
            [contentBottomConstraint setPriority:UILayoutPriorityDefaultHigh];
            [iconAlignedConstraints addObject:contentBottomConstraint];
        }
        [NSLayoutConstraint activateConstraints:iconAlignedConstraints];

        // Hard bounds: the text block may never leave the cell, whatever the
        // icon alignment above wants to do.
        [NSLayoutConstraint activateConstraints:@[
            [[[self headerLabel] topAnchor] constraintGreaterThanOrEqualToAnchor:[self topAnchor] constant:6],
            [textBottomAnchor constraintLessThanOrEqualToAnchor:[self bottomAnchor] constant:-6]
        ]];

        [self applyContent:content];

        // The date column belongs to the row's chrome, not to its content, so
        // it must sit above anything the content draws. It is added early (with
        // the other timestamp views) while the preview and detail labels are
        // added later, which meant a long preview painted straight over the
        // date. Re-raising the two stamp labels here restores the intended
        // order: content underneath, the stamp on top.
        if ([self timestampTimeLabel]) {
            [self bringSubviewToFront:[self timestampTimeLabel]];
        }
        if ([self timestampDateLabel]) {
            [self bringSubviewToFront:[self timestampDateLabel]];
        }
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
    [[self timestampTimeLabel] setText:nil];
    [[self timestampDateLabel] setText:nil];
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

    if ([self timestampTimeLabel]) {
        [[self timestampTimeLabel] setText:[content timestampTimeText]];
    }

    if ([self timestampDateLabel]) {
        [[self timestampDateLabel] setText:[content timestampDateText]];
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
