//
//  KayokoHeaderCountBadgeView.m
//  Kayoko
//

#import "KayokoHeaderCountBadgeView.h"

// 12pt with a 6pt gap from the title puts the capsule on the title's optical
// baseline without competing with it: at 22pt the title still owns the row, and
// the capsule reads as a footnote pinned to it.
static CGFloat const kKayokoHeaderCountBadgeFontSize = 12;
static CGFloat const kKayokoHeaderCountBadgeHorizontalPadding = 7;
static CGFloat const kKayokoHeaderCountBadgeVerticalPadding = 2.5;
// Below this the row would be a hairline; above it the capsule starts to look
// like a button. 18pt is a comfortable iOS footnote pill.
static CGFloat const kKayokoHeaderCountBadgeMinimumHeight = 18;

@implementation KayokoHeaderCountBadgeView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUserInteractionEnabled:NO];
        // The blur behind the panel is light in some styles and dark in others,
        // so a fill that is always "one step away from the background" is the
        // only way the capsule stays visible in both. `tertiarySystemFillColor`
        // is exactly that: a translucent label-tinted wash.
        [self setBackgroundColor:[UIColor tertiarySystemFillColor]];
        [[self layer] setCornerCurve:kCACornerCurveContinuous];
        [self setClipsToBounds:YES];

        _countLabel = [[UILabel alloc] init];
        // Medium, not bold: the title is Semibold, and matching weight would
        // make the count look like a second title. Medium keeps it legible at
        // 12pt while staying visibly subordinate.
        [_countLabel setFont:[UIFont monospacedDigitSystemFontOfSize:kKayokoHeaderCountBadgeFontSize
                                                              weight:UIFontWeightSemibold]];
        [_countLabel setTextColor:[UIColor secondaryLabelColor]];
        [_countLabel setTextAlignment:NSTextAlignmentCenter];
        [_countLabel setLineBreakMode:NSLineBreakByClipping];
        [_countLabel setNumberOfLines:1];
        [self addSubview:_countLabel];
        [_countLabel setTranslatesAutoresizingMaskIntoConstraints:NO];

        [NSLayoutConstraint activateConstraints:@[
            [[_countLabel leadingAnchor] constraintEqualToAnchor:[self leadingAnchor]
                                                        constant:kKayokoHeaderCountBadgeHorizontalPadding],
            [[_countLabel trailingAnchor] constraintEqualToAnchor:[self trailingAnchor]
                                                         constant:-kKayokoHeaderCountBadgeHorizontalPadding],
            [[_countLabel topAnchor] constraintEqualToAnchor:[self topAnchor]
                                                    constant:kKayokoHeaderCountBadgeVerticalPadding],
            [[_countLabel bottomAnchor] constraintEqualToAnchor:[self bottomAnchor]
                                                       constant:-kKayokoHeaderCountBadgeVerticalPadding],
            [[self heightAnchor] constraintGreaterThanOrEqualToConstant:kKayokoHeaderCountBadgeMinimumHeight]
        ]];

        [self setCount:0];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // A full-height capsule. The height constraint above is a minimum, so the
    // real height comes from the label's intrinsic size plus the vertical
    // padding, which is what we want to round half of.
    [[self layer] setCornerRadius:CGRectGetHeight([self bounds]) / 2.0];
}

- (void)setCount:(NSUInteger)count {
    [self setCount:count animated:NO];
}

- (void)setCount:(NSUInteger)count animated:(BOOL)animated {
    if (_count == count && [[_countLabel text] length] > 0) {
        return;
    }

    _count = count;
    NSString *text = [NSString stringWithFormat:@"%lu", (unsigned long)count];

    if (animated && [[_countLabel text] length] > 0) {
        // Cross-dissolve rather than a width animation: the pill's width is
        // driven by Auto Layout from the label's intrinsic size, and animating
        // text inside a self-sizing pill produces a visible jump as the
        // constraint pass and the animation fight each other.
        [UIView transitionWithView:[self countLabel]
                          duration:0.15
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                          [[self countLabel] setText:text];
                        }
                        completion:nil];
        return;
    }

    [[self countLabel] setText:text];
}

@end
