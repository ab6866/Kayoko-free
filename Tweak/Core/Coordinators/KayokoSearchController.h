//
//  KayokoSearchController.h
//  Kayoko
//

#import <UIKit/UIKit.h>

#import "KayokoPanelPresentationMode.h"

@class KayokoSearchController;
@class KayokoHeaderView;
@class KayokoHistoryListViewController;
@class KayokoHistoryListView;
@class KayokoSearchPresentationController;

NS_ASSUME_NONNULL_BEGIN

@protocol KayokoSearchControllerDelegate <NSObject>

- (KayokoHistoryListViewController *)activeListViewControllerForSearchController:
    (KayokoSearchController *)searchController;
- (void)searchControllerWillBeginSearchInputTransition:(KayokoSearchController *)searchController;
- (void)searchControllerWillAnimateSearchState:(KayokoSearchController *)searchController;
- (void)searchControllerDidFinishAnimatingSearchState:(KayokoSearchController *)searchController;
- (void)searchController:(KayokoSearchController *)searchController
    didUpdateKeyboardBottomInset:(CGFloat)keyboardBottomInset;
- (void)searchController:(KayokoSearchController *)searchController didFailLoadingSearchWithError:(NSError *)error;

@end

@interface KayokoSearchController : NSObject

@property(nonatomic, weak, nullable) id<KayokoSearchControllerDelegate> delegate;
@property(nonatomic, assign) KayokoPanelPresentationMode presentationMode;
@property(nonatomic, assign) BOOL keepsSearchBarVisible;
@property(nonatomic, assign, readonly, getter=isSearchActive) BOOL searchActive;
@property(nonatomic, assign, readonly) CGFloat keyboardBottomInset;
// Exposed so the panel can drive the "应用 / 类别 / 备注" strip that lives in the
// search header. The strip is presentation state, not search state, so it is
// addressed through the presentation controller rather than mirrored here.
@property(nonatomic, strong, readonly) KayokoSearchPresentationController *presentationController;

- (instancetype)initWithContainerView:(UIView *)containerView
                           headerView:(KayokoHeaderView *)headerView
            historyListViewController:(KayokoHistoryListViewController *)historyListViewController
          favoritesListViewController:(KayokoHistoryListViewController *)favoritesListViewController
                 panGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer;

- (void)layout;
- (void)attachToListViewController:(KayokoHistoryListViewController *)listViewController
                    hidesSearchBar:(BOOL)hidesSearchBar;
- (void)refreshForListViewController:(KayokoHistoryListViewController *)listViewController;
- (void)refreshAfterTransientContentForListViewController:(KayokoHistoryListViewController *)listViewController
                                   restoresFirstResponder:(BOOL)restoresFirstResponder
                                      targetContentOffset:(CGPoint)targetContentOffset;
- (void)cancelSearchWithCompletion:(nullable void (^)(void))completion;
- (void)cancelSearchWithAnimations:(nullable void (^)(void))animations completion:(nullable void (^)(void))completion;
- (BOOL)isActiveSearchFirstResponder;
- (void)resignSearchFirstResponder;
- (void)handleApplicationMetadataChanged;
- (void)handleFullscreenPanGestureRecognizer:(UIPanGestureRecognizer *)recognizer
                                  headerView:(nullable KayokoHeaderView *)headerView;
- (void)resetSearchState;
- (CGRect)resetSearchStatePreservingContainerFrame;

@end

NS_ASSUME_NONNULL_END
