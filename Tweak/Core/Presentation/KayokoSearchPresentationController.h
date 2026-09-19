//
//  KayokoSearchPresentationController.h
//  Kayoko
//

#import <UIKit/UIKit.h>

#import "KayokoPanelPresentationMode.h"

@class KayokoHistoryListView;
@class KayokoHeaderView;
@class KayokoSearchPresentationController;
@class KayokoPasteboardItem;
@class KayokoApplicationMetadataProvider;

NS_ASSUME_NONNULL_BEGIN

@protocol KayokoSearchPresentationControllerDelegate <NSObject>

- (void)searchPresentationController:(KayokoSearchPresentationController *)controller
        didUpdateKeyboardBottomInset:(CGFloat)keyboardBottomInset;
- (void)searchPresentationController:(KayokoSearchPresentationController *)controller
    didRequestCollapseFromFullscreenPanWithVelocity:(CGFloat)velocityY;

@end

@interface KayokoSearchPresentationController : NSObject

@property(nonatomic, weak, nullable) id<KayokoSearchPresentationControllerDelegate> delegate;
@property(nonatomic, assign) KayokoPanelPresentationMode presentationMode;
@property(nonatomic, assign) BOOL keepsSearchBarVisible;
@property(nonatomic, assign, readonly, getter=isSearchActive) BOOL searchActive;
@property(nonatomic, assign, readonly) CGFloat keyboardBottomInset;
// Shared with the search controller so the strip's app icon and display name
// reuse the same SpringBoard-backed cache rather than building a second one.
@property(nonatomic, strong, nullable) KayokoApplicationMetadataProvider *metadataProvider;

// The "应用 / 类别 / 备注" line under the search bar. Called with the current
// preference values; the header only grows while at least one of them is on.
- (void)setShowsApplicationInSearchInfoStrip:(BOOL)showsApplication
                                 showsCategory:(BOOL)showsCategory
                                     showsNote:(BOOL)showsNote;
// The row the strip should describe. Pass nil to clear it.
- (void)setSearchInfoStripItem:(nullable KayokoPasteboardItem *)item
                  forTableView:(nullable KayokoHistoryListView *)tableView;

- (instancetype)initWithContainerView:(UIView *)containerView
                           headerView:(KayokoHeaderView *)headerView
                     historySearchBar:(UISearchBar *)historySearchBar
                   favoritesSearchBar:(UISearchBar *)favoritesSearchBar
               historySearchTokenView:(UIView *)historySearchTokenView
             favoritesSearchTokenView:(UIView *)favoritesSearchTokenView
                     historyTableView:(KayokoHistoryListView *)historyTableView
                   favoritesTableView:(KayokoHistoryListView *)favoritesTableView
                 panGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer;

- (CGFloat)searchHeaderHeight;
- (void)layout;
- (void)updateSearchTokenViews;
- (void)attachToTableView:(KayokoHistoryListView *)tableView hidesSearchBar:(BOOL)hidesSearchBar;
- (void)hideSearchBarInTableView:(nullable KayokoHistoryListView *)tableView animated:(BOOL)animated;
- (void)revealSearchBarInTableView:(nullable KayokoHistoryListView *)tableView animated:(BOOL)animated;
- (void)beginSearchWithActiveTableView:(KayokoHistoryListView *)activeTableView
                            completion:(nullable void (^)(void))completion;
- (void)endSearchRestoringFrame:(BOOL)restoresFrame
                activeTableView:(KayokoHistoryListView *)activeTableView
                     completion:(nullable void (^)(void))completion;
- (void)endSearchRestoringFrame:(BOOL)restoresFrame
                activeTableView:(KayokoHistoryListView *)activeTableView
                     animations:(nullable void (^)(void))animations
                     completion:(nullable void (^)(void))completion;
- (void)endSearchRestoringFrame:(BOOL)restoresFrame
                activeTableView:(KayokoHistoryListView *)activeTableView
                     animations:(nullable void (^)(void))animations
                   panVelocityY:(CGFloat)panVelocityY
                     completion:(nullable void (^)(void))completion;
- (void)handleFullscreenPanGestureRecognizer:(UIPanGestureRecognizer *)recognizer
                             activeTableView:(KayokoHistoryListView *)activeTableView
                                  headerView:(nullable KayokoHeaderView *)headerView;
- (void)resetKeyboardInsets;
- (void)resetAfterSearchStateClearedWithActiveTableView:(nullable KayokoHistoryListView *)activeTableView;
- (CGRect)resetAfterSearchStateClearedWithActiveTableView:(nullable KayokoHistoryListView *)activeTableView
                                   restoresContainerFrame:(BOOL)restoresContainerFrame;

@end

NS_ASSUME_NONNULL_END
