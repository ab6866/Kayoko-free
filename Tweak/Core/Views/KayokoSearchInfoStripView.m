//
//  KayokoSearchInfoStripView.m
//  Kayoko
//

#import "KayokoSearchInfoStripView.h"

#import "KayokoApplicationMetadataProvider.h"
#import "KayokoPasteboardItem.h"
#import "KayokoTag.h"
#import "KayokoTagCatalog.h"
#import "KayokoTagColorFormatter.h"

static CGFloat const kKayokoSearchInfoStripHeight = 22;
static CGFloat const kKayokoSearchInfoStripHorizontalInset = 16;
static CGFloat const kKayokoSearchInfoStripGlyphSideLength = 13;
static CGFloat const kKayokoSearchInfoStripGlyphTextSpacing = 5;
static CGFloat const kKayokoSearchInfoStripGroupSpacing = 14;
static CGFloat const kKayokoSearchInfoStripFontSize = 11.5;

@interface KayokoSearchInfoStripView ()

@property(nonatomic, strong, readwrite) UIStackView *stackView;

@end

@implementation KayokoSearchInfoStripView

+ (CGFloat)heightForShowsApplication:(BOOL)showsApplication
                        showsCategory:(BOOL)showsCategory
                            showsNote:(BOOL)showsNote {
    // The strip keeps a fixed slot for as long as any switch is on, so toggling
    // a switch or scrolling onto an item with no note cannot make the whole list
    // jump by a line. When all three are off the strip costs nothing at all.
    BOOL showsAnything = showsApplication || showsCategory || showsNote;
    return showsAnything ? kKayokoSearchInfoStripHeight : 0;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        [self setClipsToBounds:YES];
        // A passive read-out: it must never take focus, never install a gesture
        // recognizer and never claim a touch, so a tap that lands on the strip
        // continues on to whatever is underneath and the search bar's own focus
        // handling is left exactly as it was.
        [self setUserInteractionEnabled:NO];
        [self setAccessibilityElementsHidden:YES];

        _stackView = [[UIStackView alloc] init];
        [_stackView setAxis:UILayoutConstraintAxisHorizontal];
        [_stackView setAlignment:UIStackViewAlignmentCenter];
        [_stackView setSpacing:kKayokoSearchInfoStripGroupSpacing];
        [self addSubview:_stackView];

        [_stackView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [[_stackView leadingAnchor] constraintEqualToAnchor:[self leadingAnchor]
                                                       constant:kKayokoSearchInfoStripHorizontalInset],
            [[_stackView trailingAnchor] constraintLessThanOrEqualToAnchor:[self trailingAnchor]
                                                                 constant:-kKayokoSearchInfoStripHorizontalInset],
            [[_stackView centerYAnchor] constraintEqualToAnchor:[self centerYAnchor]],
            [[_stackView topAnchor] constraintGreaterThanOrEqualToAnchor:[self topAnchor]],
            [[_stackView bottomAnchor] constraintLessThanOrEqualToAnchor:[self bottomAnchor]]
        ]];
    }
    return self;
}

#pragma mark - Content

- (void)updateWithItem:(KayokoPasteboardItem *)item
      showsApplication:(BOOL)showsApplication
         showsCategory:(BOOL)showsCategory
             showsNote:(BOOL)showsNote {
    for (UIView *arrangedSubview in [[[self stackView] arrangedSubviews] copy]) {
        [[self stackView] removeArrangedSubview:arrangedSubview];
        [arrangedSubview removeFromSuperview];
    }

    if (!item) {
        [self setHidden:YES];
        return;
    }

    KayokoApplicationMetadataProvider *metadataProvider = self.metadataProvider ?: [[KayokoApplicationMetadataProvider alloc] init];
    NSMutableArray<UIView *> *chips = [[NSMutableArray alloc] initWithCapacity:3];

    if (showsApplication) {
        NSString *bundleIdentifier = [item bundleIdentifier];
        NSString *displayName = [metadataProvider displayNameForBundleIdentifier:bundleIdentifier];
        if ([displayName length] > 0) {
            UIImage *icon = [metadataProvider smallIconForBundleIdentifier:bundleIdentifier];
            [chips addObject:[self chipWithGlyphImage:icon fallbackSymbolName:@"app" text:displayName]];
        }
    }

    if (showsCategory) {
        KayokoTag *tag = [[KayokoTagCatalog sharedCatalog] tagForUUID:[item tagUUID]];
        NSString *title = [tag title];
        if ([title length] > 0) {
            UIColor *dotColor = [KayokoTagColorFormatter visibleColorFromHexColor:[tag hexColor]];
            [chips addObject:[self chipWithDotColor:dotColor text:title]];
        }
    }

    if (showsNote) {
        NSString *note = [item note];
        if ([note length] > 0) {
            [chips addObject:[self chipWithGlyphImage:nil fallbackSymbolName:@"note.text" text:note]];
        }
    }

    for (UIView *chip in chips) {
        [[self stackView] addArrangedSubview:chip];
    }

    [self setHidden:[chips count] == 0];
}

#pragma mark - Chips

- (UIView *)chipWithGlyphImage:(UIImage *)image fallbackSymbolName:(NSString *)symbolName text:(NSString *)text {
    UIImage *resolvedImage = image ?: [UIImage systemImageNamed:symbolName];
    UIImageView *glyphView = [[UIImageView alloc] init];
    [glyphView setImage:resolvedImage];
    [glyphView setContentMode:UIViewContentModeScaleAspectFit];
    [glyphView setTintColor:[UIColor tertiaryLabelColor]];
    return [self chipWithGlyphView:glyphView roundsGlyphToCircle:NO text:text];
}

- (UIView *)chipWithDotColor:(UIColor *)dotColor text:(NSString *)text {
    UIView *dotView = [[UIView alloc] init];
    [dotView setBackgroundColor:dotColor];
    [[dotView layer] setCornerRadius:kKayokoSearchInfoStripGlyphSideLength / 2.0];
    [[dotView layer] setCornerCurve:kCACornerCurveContinuous];
    return [self chipWithGlyphView:dotView roundsGlyphToCircle:YES text:text];
}

- (UIView *)chipWithGlyphView:(UIView *)glyphView roundsGlyphToCircle:(BOOL)roundsGlyphToCircle text:(NSString *)text {
    UIView *container = [[UIView alloc] init];
    [container setTranslatesAutoresizingMaskIntoConstraints:NO];

    // App icons arrive as squares; the tag colour arrives as a circle. One
    // 13pt box either way keeps the baseline of every chip identical.
    if (roundsGlyphToCircle) {
        [[glyphView layer] setCornerRadius:kKayokoSearchInfoStripGlyphSideLength / 2.0];
    } else if ([glyphView isKindOfClass:[UIImageView class]]) {
        [[glyphView layer] setCornerRadius:kKayokoSearchInfoStripGlyphSideLength * 0.28];
        [[glyphView layer] setCornerCurve:kCACornerCurveContinuous];
        [glyphView setClipsToBounds:YES];
    }

    [container addSubview:glyphView];
    [glyphView setTranslatesAutoresizingMaskIntoConstraints:NO];

    UILabel *label = [[UILabel alloc] init];
    [label setText:text];
    [label setFont:[UIFont systemFontOfSize:kKayokoSearchInfoStripFontSize weight:UIFontWeightMedium]];
    [label setTextColor:[UIColor secondaryLabelColor]];
    [label setNumberOfLines:1];
    [label setLineBreakMode:NSLineBreakByTruncatingTail];
    // Label yields first: on a narrow panel the note truncates before the app
    // name or the tag does, because those two are the ones that identify the row.
    [label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                           forAxis:UILayoutConstraintAxisHorizontal];
    [container addSubview:label];
    [label setTranslatesAutoresizingMaskIntoConstraints:NO];

    [NSLayoutConstraint activateConstraints:@[
        [[glyphView leadingAnchor] constraintEqualToAnchor:[container leadingAnchor]],
        [[glyphView centerYAnchor] constraintEqualToAnchor:[container centerYAnchor]],
        [[glyphView widthAnchor] constraintEqualToConstant:kKayokoSearchInfoStripGlyphSideLength],
        [[glyphView heightAnchor] constraintEqualToConstant:kKayokoSearchInfoStripGlyphSideLength],
        [[label leadingAnchor] constraintEqualToAnchor:[glyphView trailingAnchor]
                                              constant:kKayokoSearchInfoStripGlyphTextSpacing],
        [[label trailingAnchor] constraintEqualToAnchor:[container trailingAnchor]],
        [[label topAnchor] constraintEqualToAnchor:[container topAnchor]],
        [[label bottomAnchor] constraintEqualToAnchor:[container bottomAnchor]]
    ]];

    return container;
}

@end
