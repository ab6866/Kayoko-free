//
//  KayokoSearchInfoStripView.h
//  Kayoko
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class KayokoPasteboardItem;
@class KayokoApplicationMetadataProvider;

// A single read-only line of context pinned directly under the search bar:
// the source application, the category (tag) and the user's note.
//
// Why it lives under the search bar rather than inside the rows: the three
// "应用 / 类别 / 备注" switches are meant to answer "where did this last thing
// come from?" before you finish typing. Putting that answer above the results
// keeps the list rows unchanged, so turning a switch on cannot reflow, re-space
// or re-order the items you are already scanning.
//
// The strip is a passive view: it never becomes first responder and it never
// installs a gesture recognizer, so taps landing on it fall straight through to
// whatever is behind it and the search bar's own focus behaviour is untouched.
@interface KayokoSearchInfoStripView : UIView

@property(nonatomic, strong, readonly) UIStackView *stackView;
// Reuses the caller's cached provider so resolving a display name and an icon
// does not spin up a second SpringBoard-backed metadata cache.
@property(nonatomic, strong, nullable) KayokoApplicationMetadataProvider *metadataProvider;

// Height for the given option set. Returns 0 when nothing is enabled, which is
// what lets the presentation controller treat the strip as absent.
+ (CGFloat)heightForShowsApplication:(BOOL)showsApplication
                        showsCategory:(BOOL)showsCategory
                            showsNote:(BOOL)showsNote;

// Clears the strip when `item` is nil or when every enabled field is empty.
// `showsApplication` / `showsCategory` / `showsNote` come straight from the
// preferences; the strip itself does not read user defaults.
- (void)updateWithItem:(nullable KayokoPasteboardItem *)item
      showsApplication:(BOOL)showsApplication
         showsCategory:(BOOL)showsCategory
             showsNote:(BOOL)showsNote;

@end

NS_ASSUME_NONNULL_END
