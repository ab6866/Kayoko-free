//
//  KayokoTableViewCell.m
//  Kayoko
//
//  Created by Alexandra Aurora Göttlicher
//

#import "KayokoTableViewCell.h"
#import "KayokoTableViewCellContent.h"
#import "KayokoTagColorFormatter.h"

static CGFloat const kKayokoTableViewCellTagDotSize = 7;
static CGFloat const kKayokoTableViewCellContentImageWidth = 70;
static CGFloat const kKayokoTableViewCellContentImageSingleLineHeight = 40;
static CGFloat const kKayokoTableViewCellContentImageAdditionalLineHeight = 15;
static NSUInteger const kKayokoTableViewCellMaximumPreviewLineCount = 3;
// The timestamp sits under the 40pt icon, so it may exceed the icon width a
// little without overlapping the title (they are vertically separated).
static CGFloat const kKayokoTableViewCellTimestampMaximumWidth = 64;
// Icon (40pt) + gap + date line + time line, both at 9pt.
static CGFloat const kKayokoTableViewCellTimestampFontSize = 9;
static CGFloat const kKayokoTableViewCellTimestampIconGap = 3;

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
    BOOL hasTimestamp = [[content timestampDateText] length] > 0 || [[content timestampTimeText] length] > 0;
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
        BOOL hasTimestamp = [[content timestampDateText] length] > 0 || [[content timestampTimeText] length] > 0;
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
        [[[self iconImageView] layer] setCornerRadius:10];
        [self addSubview:[self iconImageView]];

        [[self iconImageView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        // No centerY pin here: vertical placement is resolved later, once we
        // know whether a timestamp is present (see "Vertical alignment" below).
        [NSLayoutConstraint activateConstraints:@[
            [[[self iconImageView] widthAnchor] constraintEqualToConstant:40],
            [[[self iconImageView] heightAnchor] constraintEqualToConstant:40],
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
            [[[self contentImageView] layer] setCornerRadius:4];
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
        [NSLayoutConstraint activateConstraints:@[ [[[self headerLabel] leadingAnchor]
                                                    constraintEqualToAnchor:[[self iconImageView] trailingAnchor]
                                                                   constant:16] ]];

        NSLayoutXAxisAnchor *textTrailingAnchor =
            [self contentImageView] ? [[self contentImageView] leadingAnchor] : [self trailingAnchor];
        CGFloat textTrailingConstant = [self contentImageView] ? -16 : -24;

        // Timestamp lives directly under the app icon (left column), so the
        // title row stays clean and the full date+time is visible. It is two
        // separate labels: a single two-line label sized its intrinsic width to
        // the widest line and could drop the time line inside a fixed-height row.
        if (hasTimestamp) {
            [self setTimestampDateLabel:[[UILabel alloc] init]];
            [[self timestampDateLabel] setFont:[UIFont systemFontOfSize:kKayokoTableViewCellTimestampFontSize
                                                                  weight:UIFontWeightRegular]];
            [[self timestampDateLabel] setTextColor:[UIColor secondaryLabelColor]];
            [[self timestampDateLabel] setTextAlignment:NSTextAlignmentCenter];
            [[self timestampDateLabel] setLineBreakMode:NSLineBreakByClipping];
            [self addSubview:[self timestampDateLabel]];

            [self setTimestampTimeLabel:[[UILabel alloc] init]];
            [[self timestampTimeLabel] setFont:[UIFont systemFontOfSize:kKayokoTableViewCellTimestampFontSize
                                                                  weight:UIFontWeightRegular]];
            [[self timestampTimeLabel] setTextColor:[UIColor secondaryLabelColor]];
            [[self timestampTimeLabel] setTextAlignment:NSTextAlignmentCenter];
            [[self timestampTimeLabel] setLineBreakMode:NSLineBreakByClipping];
            [self addSubview:[self timestampTimeLabel]];

            for (UILabel *label in @[ [self timestampDateLabel], [self timestampTimeLabel] ]) {
                [label setTranslatesAutoresizingMaskIntoConstraints:NO];
                [label setContentHuggingPriority:UILayoutPriorityRequired
                                         forAxis:UILayoutConstraintAxisHorizontal];
                [label setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                       forAxis:UILayoutConstraintAxisHorizontal];
            }

            // The two lines are the same height by construction, so constraining
            // the time label below the date label is enough to stack them.
            [NSLayoutConstraint activateConstraints:@[
                [[[self timestampDateLabel] topAnchor] constraintEqualToAnchor:[[self iconImageView] bottomAnchor]
                                                                      constant:kKayokoTableViewCellTimestampIconGap],
                [[[self timestampDateLabel] centerXAnchor] constraintEqualToAnchor:[[self iconImageView] centerXAnchor]],
                [[[self timestampDateLabel] widthAnchor]
                    constraintLessThanOrEqualToConstant:kKayokoTableViewCellTimestampMaximumWidth],

                [[[self timestampTimeLabel] topAnchor] constraintEqualToAnchor:[[self timestampDateLabel] bottomAnchor]],
                [[[self timestampTimeLabel] centerXAnchor] constraintEqualToAnchor:[[self iconImageView] centerXAnchor]],
                [[[self timestampTimeLabel] widthAnchor]
                    constraintLessThanOrEqualToConstant:kKayokoTableViewCellTimestampMaximumWidth]
            ]];
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
        // below it. That is only correct when the timestamp is hidden: with the
        // timestamp on, the icon+time column is taller than it looks, so the
        // column (and the icon inside it) was dragged upwards relative to the
        // text block, and the text appeared top-heavy. Turning the timestamp off
        // then reset the icon to the centre by a different code path, so the two
        // states did not agree.
        //
        // Instead, treat the left column (icon + optional timestamp) and the
        // right column (title/preview/detail) as two blocks and centre each of
        // them vertically. This adapts to every combination of the timestamp
        // switch, preview line count and item-details mode.
        if (hasTimestamp) {
            // Left column: icon top -> timestamp bottom, centred as a unit.
            [[[self iconImageView] topAnchor] constraintGreaterThanOrEqualToAnchor:[self topAnchor]
                                                                          constant:6]
                .active = YES;
            [[[self timestampTimeLabel] bottomAnchor] constraintLessThanOrEqualToAnchor:[self bottomAnchor]
                                                                               constant:-6]
                .active = YES;

            UILayoutGuide *leftColumnGuide = [[UILayoutGuide alloc] init];
            [self addLayoutGuide:leftColumnGuide];
            [NSLayoutConstraint activateConstraints:@[
                [[leftColumnGuide topAnchor] constraintEqualToAnchor:[[self iconImageView] topAnchor]],
                [[leftColumnGuide bottomAnchor] constraintEqualToAnchor:[[self timestampTimeLabel] bottomAnchor]],
                [[leftColumnGuide centerYAnchor] constraintEqualToAnchor:[self centerYAnchor]]
            ]];
        } else {
            // No timestamp: the icon column is just the icon.
            [NSLayoutConstraint activateConstraints:@[
                [[[self iconImageView] topAnchor] constraintGreaterThanOrEqualToAnchor:[self topAnchor] constant:6],
                [[[self iconImageView] bottomAnchor] constraintLessThanOrEqualToAnchor:[self bottomAnchor]
                                                                             constant:-6]
            ]];
        }

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
    [[self timestampDateLabel] setText:nil];
    [[self timestampTimeLabel] setText:nil];
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

    if ([self timestampDateLabel]) {
        [[self timestampDateLabel] setText:[content timestampDateText]];
    }
    if ([self timestampTimeLabel]) {
        [[self timestampTimeLabel] setText:[content timestampTimeText]];
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
