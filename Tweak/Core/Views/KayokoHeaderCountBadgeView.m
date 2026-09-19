//
//  KayokoHeaderCountBadgeView.m
//  Kayoko
//

#import "KayokoHeaderCountBadgeView.h"

// 12pt with a 6pt gap from the title puts the capsule on the title's optical
// baseline without competing with it: at 22pt the title still owns the row, and
// the capsule reads as a footnote pinned to it.
static CGFloat const kKayokoHeaderCountBadgeFontSize = 12;
static CGFloat const kKayokoHeaderCountBadgeHorizontalPadding = 6.5;
static CGFloat const kKayokoHeaderCountBadgeVerticalPadding = 2;
// A 16pt pill is the tightest shape that still reads as a capsule rather than a
// mis-rendered dot at 12pt text. Anything taller started to look like a button,
// which is exactly the wrong affordance now that the capsule is a read-out.
static CGFloat const kKayokoHeaderCountBadgeMinimumHeight = 16;

@implementation KayokoHeaderCountBadgeView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUserInteractionEnabled:NO];
        // The blur behind the panel is light in some styles and dark in others,
        // so a fill that is always "one step away from the background" is the
        // only way the capsule stays visible in both.
        //
        // A flat wash of `tertiarySystemFillColor` looked like a widget with a
        // missing glyph: too pale against a light blur to hold the digits, and
        // the muted label colour on top of it washed the number out further.
        // A thin stroke plus a solid-enough fill gives the capsule a defined
        // edge without turning it into a control, and the text colour tracks the
        // primary label so the count stays the most legible thing in the pill.
        [self setBackgroundColor:[UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
          if ([traitCollection userInterfaceStyle] == UIUserInterfaceStyleDark) {
              return [UIColor colorWithWhite:1 alpha:0.16];
          }

          return [UIColor colorWithWhite:0 alpha:0.09];
        }]];
        [[self layer] setCornerCurve:kCACornerCurveContinuous];
        [[self layer] setBorderWidth:0.5];
        [self updateBorderColor];
        [self setClipsToBounds:YES];

        _countLabel = [[UILabel alloc] init];
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

// CGColor is not dynamic, so the hairline has to be re-resolved whenever the
// interface style changes instead of once at init.
- (void)updateBorderColor {
    UIColor *borderColor = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
      if ([traitCollection userInterfaceStyle] == UIUserInterfaceStyleDark) {
          return [UIColor colorWithWhite:1 alpha:0.14];
      }

      return [UIColor colorWithWhite:0 alpha:0.08];
    }];
    [[self layer] setBorderColor:[[borderColor resolvedColorWithTraitCollection:[self traitCollection]] CGColor]];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateBorderColor];
    }
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
