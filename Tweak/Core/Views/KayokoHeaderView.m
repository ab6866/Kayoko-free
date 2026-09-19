//
//  KayokoHeaderView.m
//  Kayoko
//

#import "KayokoHeaderView.h"

#import "KayokoGrabberView.h"
#import "KayokoHeaderButtonStyle.h"
#import "KayokoHeaderCountBadgeView.h"

static CGFloat const kKayokoHeaderHeight = 60;
static CGFloat const kKayokoTitleTapControlHeight = 44;
static CGFloat const kKayokoTitleTapControlTrailingSpacing = 8;
static CGFloat const kKayokoTrailingHeaderButtonCenterSpacing = 44;
// Gap between the title and the count capsule.
static CGFloat const kKayokoHeaderCountBadgeLeadingSpacing = 6;

@interface KayokoHeaderView ()

@property(nonatomic, strong, readwrite) KayokoGrabberView *grabber;
@property(nonatomic, strong, readwrite) UILabel *titleLabel;
@property(nonatomic, strong, readwrite) UIControl *titleTapControl;
@property(nonatomic, strong, readwrite) UIButton *leadingButton;
@property(nonatomic, strong, readwrite) UIButton *trailingButton;
@property(nonatomic, strong, readwrite) UIButton *alternateTrailingButton;
@property(nonatomic, strong, readwrite) KayokoHeaderCountBadgeView *countBadgeView;
@property(nonatomic, strong, readwrite) UIButton *countBadgeControl;

@end

@implementation KayokoHeaderView

+ (CGFloat)preferredHeight {
    return kKayokoHeaderHeight;
}

- (instancetype)initWithTitle:(NSString *)title {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self setClipsToBounds:YES];

        _grabber = [[KayokoGrabberView alloc] init];
        [self addSubview:_grabber];
        [_grabber setTranslatesAutoresizingMaskIntoConstraints:NO];

        _leadingButton = [[UIButton alloc] init];
        [self addSubview:_leadingButton];
        [_leadingButton setTranslatesAutoresizingMaskIntoConstraints:NO];

        _titleLabel = [[UILabel alloc] init];
        // 26pt read as a page banner rather than a section title next to the
        // 24pt header buttons; 22pt sits closer to the iOS "large title" step
        // and leaves the buttons visually independent.
        [_titleLabel setFont:[UIFont systemFontOfSize:22 weight:UIFontWeightSemibold]];
        [_titleLabel setTextColor:[UIColor labelColor]];
        [_titleLabel setAdjustsFontSizeToFitWidth:YES];
        [_titleLabel setMinimumScaleFactor:0.85];
        // The title must never stretch to eat the count badge's space; the
        // badge is the fixed element and the title yields to it.
        [_titleLabel setContentHuggingPriority:UILayoutPriorityRequired
                                       forAxis:UILayoutConstraintAxisHorizontal];
        [_titleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                                     forAxis:UILayoutConstraintAxisHorizontal];
        [self addSubview:_titleLabel];
        [_titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];

        _countBadgeView = [[KayokoHeaderCountBadgeView alloc] init];
        [self addSubview:_countBadgeView];
        [_countBadgeView setTranslatesAutoresizingMaskIntoConstraints:NO];

        // Keep interaction separate from the render-only badge. This gives the
        // capsule a reliable tap target without re-enabling interaction on the
        // badge label or allowing its drawing view to own the menu lifecycle.
        _countBadgeControl = [[UIButton alloc] init];
        [_countBadgeControl setBackgroundColor:[UIColor clearColor]];
        [_countBadgeControl setShowsTouchWhenHighlighted:NO];
        [_countBadgeControl setAccessibilityTraits:UIAccessibilityTraitButton];
        [_countBadgeControl setAccessibilityLabel:@"Count settings"];
        [self addSubview:_countBadgeControl];
        [_countBadgeControl setTranslatesAutoresizingMaskIntoConstraints:NO];

        _trailingButton = [[UIButton alloc] init];
        [self addSubview:_trailingButton];
        [_trailingButton setTranslatesAutoresizingMaskIntoConstraints:NO];

        _alternateTrailingButton = [[UIButton alloc] init];
        [_alternateTrailingButton setHidden:YES];
        [self addSubview:_alternateTrailingButton];
        [_alternateTrailingButton setTranslatesAutoresizingMaskIntoConstraints:NO];

        _titleTapControl = [[UIControl alloc] init];
        [_titleTapControl setBackgroundColor:[UIColor clearColor]];
        [_titleTapControl setAccessibilityTraits:[_titleTapControl accessibilityTraits] | UIAccessibilityTraitButton];
        [self addSubview:_titleTapControl];
        [_titleTapControl setTranslatesAutoresizingMaskIntoConstraints:NO];

        // The grabber is deliberately NOT constrained any more. It is kept as a
        // property because the fold progress is plumbed through it during
        // fullscreen search drags, but it has no frame and draws nothing -- see
        // the note on `grabber` in the header.
        [_grabber setHidden:YES];

        [NSLayoutConstraint activateConstraints:@[
            [[_leadingButton bottomAnchor] constraintEqualToAnchor:[self bottomAnchor] constant:-2],
            [[_leadingButton centerXAnchor] constraintEqualToAnchor:[self leadingAnchor]
                                                           constant:kKayokoLeadingHeaderButtonCenterXInset],
            [[_titleLabel centerYAnchor] constraintEqualToAnchor:[_leadingButton centerYAnchor]],
            [[_titleLabel leadingAnchor] constraintEqualToAnchor:[self leadingAnchor]
                                                        constant:kKayokoTitleLabelLeadingInset],
            // The capsule is welded to the title's trailing edge and vertically
            // centred on it, so the pair reads as one unit at any font size.
            [[_countBadgeView leadingAnchor] constraintEqualToAnchor:[_titleLabel trailingAnchor]
                                                            constant:kKayokoHeaderCountBadgeLeadingSpacing],
            [[_countBadgeView centerYAnchor] constraintEqualToAnchor:[_titleLabel centerYAnchor]],
            [[_countBadgeView trailingAnchor] constraintLessThanOrEqualToAnchor:[_trailingButton leadingAnchor]
                                                                       constant:-kKayokoTitleTapControlTrailingSpacing],
            [[_countBadgeControl leadingAnchor] constraintEqualToAnchor:[_countBadgeView leadingAnchor]],
            [[_countBadgeControl trailingAnchor] constraintEqualToAnchor:[_countBadgeView trailingAnchor]],
            [[_countBadgeControl topAnchor] constraintEqualToAnchor:[_countBadgeView topAnchor]],
            [[_countBadgeControl bottomAnchor] constraintEqualToAnchor:[_countBadgeView bottomAnchor]],
            [[_trailingButton centerYAnchor] constraintEqualToAnchor:[_leadingButton centerYAnchor]],
            [[_trailingButton centerXAnchor] constraintEqualToAnchor:[self trailingAnchor]
                                                            constant:-kKayokoTrailingHeaderButtonCenterXInset],
            [[_alternateTrailingButton centerYAnchor] constraintEqualToAnchor:[_leadingButton centerYAnchor]],
            [[_alternateTrailingButton centerXAnchor]
                constraintEqualToAnchor:[_trailingButton centerXAnchor]
                               constant:-kKayokoTrailingHeaderButtonCenterSpacing],
            [[_titleTapControl leadingAnchor] constraintEqualToAnchor:[_titleLabel leadingAnchor]],
            [[_titleTapControl trailingAnchor] constraintEqualToAnchor:[_alternateTrailingButton leadingAnchor]
                                                              constant:-kKayokoTitleTapControlTrailingSpacing],
            [[_titleTapControl centerYAnchor] constraintEqualToAnchor:[_titleLabel centerYAnchor]],
            [[_titleTapControl heightAnchor] constraintEqualToConstant:kKayokoTitleTapControlHeight]
        ]];

        [self setTitleText:title];
    }
    return self;
}

- (void)setTitleText:(NSString *)title {
    if ([title length] == 0) {
        return;
    }

    [[self titleLabel] setText:title];
    [[self titleTapControl] setAccessibilityLabel:title];
}

- (void)setCountBadgeHidden:(BOOL)hidden count:(NSUInteger)count {
    [[self countBadgeView] setHidden:hidden];
    [[self countBadgeView] setCount:count animated:YES];
}

- (void)setGrabberFoldProgress:(CGFloat)progress {
    _grabberFoldProgress = MIN(MAX(progress, 0), 1);
    [[self grabber] setFoldProgress:_grabberFoldProgress];
}

- (void)updateStyleForButton:(UIButton *)button
               withImageName:(NSString *)imageName
                   imageSize:(NSUInteger)imageSize
                   tintColor:(UIColor *)color {
    // Weight .regular rather than .medium: at a matched 22pt the header buttons
    // carry the same presence as the title without competing with it.
    UIImageSymbolConfiguration *configuration =
        [UIImageSymbolConfiguration configurationWithPointSize:imageSize weight:UIImageSymbolWeightRegular];
    UIImage *image = [UIImage systemImageNamed:imageName] ?: [UIImage systemImageNamed:@"doc.on.doc"];
    [button setImage:[image imageWithConfiguration:configuration] forState:UIControlStateNormal];
    [button setTintColor:color];
}

@end
