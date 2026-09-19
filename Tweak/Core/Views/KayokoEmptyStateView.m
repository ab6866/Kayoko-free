//
//  KayokoEmptyStateView.m
//  Kayoko
//

#import "KayokoEmptyStateView.h"
#import "KayokoPasteboardManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface KayokoEmptyStateView ()
@property(nonatomic, strong) UIStackView *contentStackView;
@property(nonatomic, strong) UIStackView *actionButtonStackView;
@property(nonatomic, strong) UILabel *messageLabel;
@property(nonatomic, strong) UILabel *hintLabel;
@property(nonatomic, strong) UIButton *actionButton;
@property(nonatomic, strong) NSLayoutConstraint *contentStackViewCenterYConstraint;
@property(nonatomic, copy, nullable) void (^actionHandler)(void);
@end

NS_ASSUME_NONNULL_END

@implementation KayokoEmptyStateView

- (instancetype)init {
    self = [super init];

    if (self) {
        [self setContentStackView:[[UIStackView alloc] init]];
        [[self contentStackView] setAxis:UILayoutConstraintAxisVertical];
        [[self contentStackView] setAlignment:UIStackViewAlignmentCenter];
        [[self contentStackView] setSpacing:6];
        [self addSubview:[self contentStackView]];

        [self setMessageLabel:[[UILabel alloc] init]];
        [[self messageLabel] setFont:[UIFont systemFontOfSize:17 weight:UIFontWeightSemibold]];
        [[self messageLabel] setTextColor:[UIColor labelColor]];
        [[self messageLabel] setTextAlignment:NSTextAlignmentCenter];
        [[self messageLabel] setNumberOfLines:0];
        [[self contentStackView] addArrangedSubview:[self messageLabel]];

        // A bare "No History Items" tells the user nothing actionable. The hint
        // line explains how items get here, which is the actual question when
        // the list is empty for the first time.
        [self setHintLabel:[[UILabel alloc] init]];
        [[self hintLabel] setFont:[UIFont systemFontOfSize:14 weight:UIFontWeightRegular]];
        [[self hintLabel] setTextColor:[UIColor secondaryLabelColor]];
        [[self hintLabel] setTextAlignment:NSTextAlignmentCenter];
        [[self hintLabel] setNumberOfLines:0];
        [[self hintLabel] setHidden:YES];
        [[self contentStackView] addArrangedSubview:[self hintLabel]];

        [self setActionButtonStackView:[[UIStackView alloc] init]];
        [[self actionButtonStackView] setAxis:UILayoutConstraintAxisHorizontal];
        [[self actionButtonStackView] setAlignment:UIStackViewAlignmentCenter];
        [[self actionButtonStackView] setDistribution:UIStackViewDistributionFillEqually];
        [[self actionButtonStackView] setSpacing:12];
        [[self actionButtonStackView] setHidden:YES];
        [[self contentStackView] addArrangedSubview:[self actionButtonStackView]];

        [self setActionButton:[UIButton buttonWithType:UIButtonTypeSystem]];
        [[self actionButton] setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
        [[[self actionButton] titleLabel] setFont:[UIFont systemFontOfSize:16 weight:UIFontWeightSemibold]];
        [[[self actionButton] titleLabel] setLineBreakMode:NSLineBreakByTruncatingTail];
        [[self actionButton] setBackgroundColor:[[UIColor systemBlueColor] colorWithAlphaComponent:0.14]];
        [[[self actionButton] layer] setCornerRadius:8];
        [[self actionButton] setClipsToBounds:YES];
        [[self actionButton] addTarget:self
                                action:@selector(handleActionButtonPressed)
                      forControlEvents:UIControlEventTouchUpInside];
        [[self actionButtonStackView] addArrangedSubview:[self actionButton]];

        [[self contentStackView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[self actionButtonStackView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[self messageLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[self hintLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [[self actionButton] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self setContentStackViewCenterYConstraint:[[[self contentStackView] centerYAnchor]
                                                       constraintEqualToAnchor:[self centerYAnchor]]];
        [NSLayoutConstraint activateConstraints:@[
            [[[self contentStackView] centerXAnchor] constraintEqualToAnchor:[self centerXAnchor]],
            [self contentStackViewCenterYConstraint],
            [[[self contentStackView] leadingAnchor] constraintGreaterThanOrEqualToAnchor:[self leadingAnchor]
                                                                                 constant:24],
            [[[self contentStackView] trailingAnchor] constraintLessThanOrEqualToAnchor:[self trailingAnchor]
                                                                               constant:-24],
            [[[self contentStackView] widthAnchor] constraintLessThanOrEqualToAnchor:[self widthAnchor] constant:-48],
            [[[self messageLabel] leadingAnchor] constraintGreaterThanOrEqualToAnchor:[self leadingAnchor] constant:24],
            [[[self messageLabel] trailingAnchor] constraintLessThanOrEqualToAnchor:[self trailingAnchor] constant:-24],
            [[[self messageLabel] widthAnchor] constraintLessThanOrEqualToAnchor:[self widthAnchor] constant:-48],
            [[[self hintLabel] leadingAnchor] constraintGreaterThanOrEqualToAnchor:[self leadingAnchor] constant:24],
            [[[self hintLabel] trailingAnchor] constraintLessThanOrEqualToAnchor:[self trailingAnchor] constant:-24],
            [[[self hintLabel] widthAnchor] constraintLessThanOrEqualToAnchor:[self widthAnchor] constant:-48],
            [[[self actionButtonStackView] widthAnchor] constraintEqualToConstant:86],
            [[[self actionButtonStackView] heightAnchor] constraintEqualToConstant:36]
        ]];
    }

    return self;
}

- (void)setKeyboardBottomInset:(CGFloat)keyboardBottomInset {
    keyboardBottomInset = MAX(keyboardBottomInset, 0);
    if (_keyboardBottomInset == keyboardBottomInset) {
        return;
    }

    _keyboardBottomInset = keyboardBottomInset;
    [[self contentStackViewCenterYConstraint] setConstant:-keyboardBottomInset / 2.0];
    [self setNeedsLayout];
}

- (void)clearActionButton {
    [self setActionHandler:nil];
    [[self actionButtonStackView] setHidden:YES];
    [[self actionButton] setTitle:nil forState:UIControlStateNormal];
}

- (void)updateWithHistoryKey:(NSString *)historyKey {
    [self clearActionButton];
    BOOL showingFavorites = [historyKey isEqualToString:kKayokoHistoryKeyFavorites];
    NSBundle *bundle = [KayokoPasteboardManager localizationBundle];
    [self setName:[bundle localizedStringForKey:(showingFavorites ? @"Favorites" : @"History")
                                           value:nil
                                           table:@"Tweak"]];
    [[self messageLabel]
        setText:[bundle localizedStringForKey:(showingFavorites ? @"No Favorite Items" : @"No History Items")
                                        value:nil
                                        table:@"Tweak"]];
    [[self hintLabel] setText:[bundle localizedStringForKey:(showingFavorites ? @"Favorites Empty Hint"
                                                                             : @"History Empty Hint")
                                                      value:nil
                                                      table:@"Tweak"]];
    [[self hintLabel] setHidden:NO];
}

- (void)updateWithStorageError:(NSError *)error {
    [self clearActionButton];
    NSBundle *bundle = [KayokoPasteboardManager localizationBundle];
    [self setName:[bundle localizedStringForKey:@"History" value:nil table:@"Tweak"]];
    NSString *title = [bundle localizedStringForKey:@"Unable to Load History" value:nil table:@"Tweak"];
    NSString *format = [bundle localizedStringForKey:@"%@\n%@" value:nil table:@"Tweak"];
    NSString *detail = [[error localizedDescription] length] > 0 ? [error localizedDescription] : [error description];
    [[self messageLabel] setText:[NSString stringWithFormat:format, title, detail ?: @""]];
    // No actionable advice here: an error is not something the user can fix by
    // copying something, so the hint stays out of the way.
    [[self hintLabel] setHidden:YES];
    [[self hintLabel] setText:nil];
}

- (void)updateWithAuthorizationRequiredActionHandler:(void (^)(void))actionHandler {
    NSBundle *bundle = [KayokoPasteboardManager localizationBundle];
    [self setName:[bundle localizedStringForKey:@"Kayoko" value:nil table:@"Tweak"]];
    [[self messageLabel] setText:[bundle localizedStringForKey:@"Open Settings → “Kayoko” to complete verification."
                                                         value:nil
                                                         table:@"Tweak"]];
    [[self hintLabel] setHidden:YES];
    [[self hintLabel] setText:nil];
    [[self actionButton] setTitle:[bundle localizedStringForKey:@"Continue" value:nil table:@"Tweak"]
                         forState:UIControlStateNormal];
    [self setActionHandler:actionHandler];
    [[self actionButtonStackView] setHidden:NO];
}

- (void)handleActionButtonPressed {
    if ([self actionHandler]) {
        [self actionHandler]();
    }
}

@end
