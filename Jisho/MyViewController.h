//  MNViewController.h
//  Jisho


#import <UIKit/UIKit.h>
#import <UIKit/UITextChecker.h>

@interface MyViewController : UIViewController  <UIApplicationDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIActionSheetDelegate>
{
	UITextChecker* 	textChecker_;
	
	NSArray* history_;
	NSArray* gusses_;
	BOOL guessing_;
	BOOL hasDefinition_;
	
	NSIndexPath *tappedIndexPath_;
	
	BOOL viewAppeared_;
			
	NSInteger pinchStartVal_;

}

-(void)reloadView;
- (void)viewWillAppear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
- (void)viewDidDisappear:(BOOL)animated;
- (void)keyboardWasShown:(NSNotification*)aNotification;
- (void)keyboardWillBeHidden:(NSNotification*)aNotification;
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView ;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section ;
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath ;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath ;
-(void)presentReferenceLibrary:(NSString*)term addToHistory:(BOOL)addToHistory;
-(void)pinch:(UIPinchGestureRecognizer*)gesture;
-(void)swipe:(UISwipeGestureRecognizer*)gesture;
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)aSearchText;
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar;
-(void)addToHistory:(NSString*)term;
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
- (void)applicationDidEnterBackground:(UIApplication *)application;
- (void)applicationWillEnterForeground:(UIApplication *)application;
- (void)applicationWillTerminate:(UIApplication *)application;


@property (weak, nonatomic) UISearchBar *searchBar;
@property (weak, nonatomic) UITableView *tableView;

@property (nonatomic, strong) NSString* searchText;
@property (nonatomic, strong) NSArray* history;


// App Delegate
@property (strong, nonatomic) UIWindow *window;


@end
