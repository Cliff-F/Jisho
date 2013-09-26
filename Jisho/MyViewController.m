//
//  MNViewController.m
//  Jisho
//


#import "MyViewController.h"

#pragma mark - ==========================================
#pragma mark	MyApplication
#pragma mark   ==========================================



@interface MyApplication : UIApplication
-(void)setOverrideFontSize:(NSInteger)size;
-(NSInteger)overrideFontSize;
@end


@implementation MyApplication

static NSInteger sCurrentFontSize = -1;

#define values @[ UIContentSizeCategoryExtraSmall, UIContentSizeCategorySmall, UIContentSizeCategoryMedium, UIContentSizeCategoryLarge, UIContentSizeCategoryExtraLarge, UIContentSizeCategoryExtraExtraLarge, UIContentSizeCategoryExtraExtraExtraLarge, UIContentSizeCategoryAccessibilityMedium, UIContentSizeCategoryAccessibilityLarge, UIContentSizeCategoryAccessibilityExtraLarge, UIContentSizeCategoryAccessibilityExtraExtraLarge, UIContentSizeCategoryAccessibilityExtraExtraExtraLarge]

-(NSInteger)overrideFontSize
{
	if( sCurrentFontSize == -1 )
	{
		NSNumber* num = [[NSUserDefaults standardUserDefaults] objectForKey:@"MyApp-FontSize"];
		
		if( num )
			sCurrentFontSize = num.integerValue;
		else
			sCurrentFontSize = 2;
		
		sCurrentFontSize = MAX( sCurrentFontSize, 0 );
		sCurrentFontSize = MIN( sCurrentFontSize, 11);
		
	}
	
	return sCurrentFontSize;
}

-(void)setOverrideFontSize:(NSInteger)size
{
	
	sCurrentFontSize = size;
	
	sCurrentFontSize = MAX( sCurrentFontSize, 0 );
	sCurrentFontSize = MIN( sCurrentFontSize, 11);
	
	
	NSString* val = UIContentSizeCategoryMedium;
	
	val = values[sCurrentFontSize];
	
	
	NSDictionary* dict = @{ UIContentSizeCategoryNewValueKey : val, @"UIContentSizeCategoryTextLegibilityEnabledKey" : @0 };
	
	[[NSNotificationCenter defaultCenter] postNotificationName:UIContentSizeCategoryDidChangeNotification object:self userInfo:dict];
	
	[[NSUserDefaults standardUserDefaults] setInteger:sCurrentFontSize forKey:@"MyApp-FontSize"];
}

-(NSString*)preferredContentSizeCategory
{
	if( sCurrentFontSize == -1 )
	{
		NSNumber* num = [[NSUserDefaults standardUserDefaults] objectForKey:@"MyApp-FontSize"];
		
		if( num )
			sCurrentFontSize = num.integerValue;
		else
			sCurrentFontSize = 2;
		
		sCurrentFontSize = MAX( sCurrentFontSize, 0 );
		sCurrentFontSize = MIN( sCurrentFontSize, 11);
		
	}
	
	
	NSString* val = UIContentSizeCategoryMedium;
	val = values[sCurrentFontSize];
	
	return val;
}

@end

#pragma mark - ==========================================
#pragma mark	MNViewController
#pragma mark   ==========================================


@implementation MyViewController
@synthesize searchBar;
@synthesize tableView;
@synthesize searchText;
@synthesize history;


#pragma mark - View lifecycle


static NSString* SearchTextKey = @"SearchText";
static NSString* HistoryKey = @"History";
static NSString* FontNameKey = @"FontName";
static NSString* HideScopeBarKey = @"HideScopeBar";
static NSString* StartAsBlank = @"StartAsBlank";

-(void)reloadView
{
	
	CGRect frame = CGRectMake(0, 20, self.view.bounds.size.width, self.view.bounds.size.height-20);
	
	[self.tableView removeFromSuperview];
	
	
	UITableView* aTableView = [[UITableView alloc] initWithFrame:frame];
	aTableView.delegate = (id <UITableViewDelegate> )self;
	aTableView.dataSource = (id <UITableViewDataSource> )self;
	aTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
	
	
	
	UISearchBar *bar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
	
	bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	bar.delegate = (id <UISearchBarDelegate> )self;
	bar.searchBarStyle = UISearchBarStyleMinimal;
	bar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	bar.showsScopeBar = NO;
	bar.showsBookmarkButton = NO;
	
	
	[self.view addSubview: aTableView];
	aTableView.tableHeaderView = bar;
	
	
	self.searchBar = bar;
	self.tableView = aTableView;
	
	searchBar.text = self.searchText;
	[self searchBar:searchBar textDidChange:searchBar.text];	
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.backgroundColor = [UIColor whiteColor];
	
	[self reloadView];
	
	UIPinchGestureRecognizer* gesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
	
	[self.window addGestureRecognizer: gesture];

}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"ClearWhenDone"] )
	{
		searchBar.text =  nil;
		
	}else
	{
		searchBar.text = self.searchText;
	}
	
	[self.tableView reloadData];
	
	if( tappedIndexPath_ )
		[self.tableView selectRowAtIndexPath:tappedIndexPath_ animated:NO scrollPosition:UITableViewScrollPositionMiddle];
	
	//[self registerForKeyboardNotifications];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver:self
				 selector:@selector(keyboardWasShown:)
						 name:UIKeyboardDidShowNotification object:nil];
	
	[nc addObserver:self
				 selector:@selector(keyboardWillBeHidden:)
						 name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	viewAppeared_ = YES;
	
	if( tappedIndexPath_ )
	{
		[self.tableView deselectRowAtIndexPath:tappedIndexPath_ animated:YES];
		tappedIndexPath_ = nil;
	}
	if( searchBar.text.length == 0 )
		[self.searchBar becomeFirstResponder];
	
}


- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	viewAppeared_ = NO;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	
}


- (void)keyboardWasShown:(NSNotification*)aNotification
{
	NSDictionary* info = [aNotification userInfo];
	CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
	
	UIEdgeInsets contentInsets;
	
	if( UIInterfaceOrientationIsLandscape(self.interfaceOrientation) )
		contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.width, 0.0);
	else
		contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);

	tableView.contentInset = contentInsets;
	tableView.scrollIndicatorInsets = contentInsets;
	
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
	UIEdgeInsets contentInsets = UIEdgeInsetsZero;
	tableView.contentInset = contentInsets;
	tableView.scrollIndicatorInsets = contentInsets;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// Return the number of sections.
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"DisableHistory"] ) return 2;

	return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// Return the number of rows in the section.
	
	if( section == 0 ) return hasDefinition_?1:0;
	if( section == 1 ) return (guessing_?1:[gusses_ count]);
	if( section == 2 ) return ([self.history count]> 0 ? [self.history count]+1: 0);
	
	return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if( hasDefinition_ && section == 0 ) 
	{
		return NSLocalizedString(@"Match",@"");
	}
	
	
	if( ([gusses_ count] > 0 || guessing_ ) && section == 1 ) return NSLocalizedString(@"Guess",@"");
	if( [self.history count] > 0 && section == 2 ) return NSLocalizedString(@"History",@"");
	
	return nil;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) 
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
		
		NSString* fontname = [[NSUserDefaults standardUserDefaults] objectForKey:FontNameKey];
		if( !fontname ) fontname = @"Baskerville";
		
		UIFont *font = [UIFont fontWithName:fontname size:24];
		
		cell.textLabel.font = font;
		
	}
	
	
	// Configure the cell...
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.userInteractionEnabled = YES;
	
	
	switch ( indexPath.section ) {
		case 0:
			cell.textLabel.textColor = [UIColor colorWithRed:0.16 green:0.41 blue:1.0 alpha:1];
			cell.textLabel.text = self.searchText;
			break;
			
		case 1:
			if( guessing_ )
			{
				cell.textLabel.textColor = [UIColor lightGrayColor];
				cell.textLabel.text = NSLocalizedString(@"Guessing...", @"");
				cell.userInteractionEnabled = NO;
				cell.accessoryType = UITableViewCellAccessoryNone;
				
			}else if( [gusses_ count] > 0 )
			{
				cell.textLabel.textColor = [UIColor blackColor];
				cell.textLabel.text = [gusses_ objectAtIndex:indexPath.row];
			}
			
			break;
			
		case 2:
			if( indexPath.row == [self.history count] )
			{
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
				
				cell.textLabel.font = [UIFont boldSystemFontOfSize:18];
				cell.textLabel.text = NSLocalizedString(@"History...",@"");
				cell.textLabel.textAlignment = NSTextAlignmentCenter;
				
				
			}
			else
			{
				cell.textLabel.textColor = [UIColor blackColor];
				cell.textLabel.text = [self.history objectAtIndex:indexPath.row];
				
			}
			break;
			
			
		default:
			break;
	}
	
	
	return cell;
}

#pragma mark -
#pragma mark Table view delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	tappedIndexPath_ = indexPath;
	
	if( indexPath.section == 0 )
	{
		[self presentReferenceLibrary:self.searchText addToHistory:YES];
	}
	
	
	if( indexPath.section == 1 )
	{
		[self presentReferenceLibrary:[gusses_ objectAtIndex:indexPath.row] addToHistory:YES];
	}
	
	if( indexPath.section == 2 )
	{
		if( indexPath.row == [self.history count] )
		{
			[self.tableView deselectRowAtIndexPath:tappedIndexPath_ animated:YES];
			tappedIndexPath_ = nil;
			
			UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:@""
																				delegate:self
																	cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
															 destructiveButtonTitle:NSLocalizedString( @"Clear History" , @"")
																	otherButtonTitles:NSLocalizedString( @"Send History" , @"") , nil];
			
			
			[sheet showFromRect:[self.tableView rectForRowAtIndexPath:indexPath] inView:self.tableView animated:YES];
			return;
		}
		
		[self presentReferenceLibrary:[self.history objectAtIndex:indexPath.row] addToHistory:NO];
		
	}
	
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if( buttonIndex == 1 )
	{
		[searchBar resignFirstResponder];
		
		NSString* body = [self.history componentsJoinedByString:@"\n"];
		
		UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:@[body]
																							  applicationActivities:nil];
		
		
		[self presentViewController:vc animated:YES completion:nil];
		
	}
	
	if( buttonIndex == 0 )
	{
		// Clear History
		self.history = nil;
		[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];
		
	}
	

}

#pragma mark - Actions


-(void)presentReferenceLibrary:(NSString*)term addToHistory:(BOOL)addToHistory
{
	UISwipeGestureRecognizer* gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
	gesture.direction = UISwipeGestureRecognizerDirectionRight;
	UIReferenceLibraryViewController *controller = [[UIReferenceLibraryViewController alloc] initWithTerm:term];	
	if( addToHistory ) [self addToHistory: term];
	
	
	
	[self presentViewController:controller animated:YES completion:^{
		
		// Add history after presenting modal view
		
		
		UIPinchGestureRecognizer* pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
		
		[controller.view addGestureRecognizer: pinchGesture];
		
		
		UISwipeGestureRecognizer* gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
		gesture.direction = UISwipeGestureRecognizerDirectionRight;
		
		[controller.view addGestureRecognizer:gesture];
		
		

	}];
	
	
	
	[controller.view addGestureRecognizer:gesture];
	
}

-(void)pinch:(UIPinchGestureRecognizer*)gesture
{
	MyApplication* myApp = (MyApplication*)[UIApplication sharedApplication];
	
	NSInteger size = [myApp overrideFontSize];
	
	
	if( gesture.state == UIGestureRecognizerStateBegan )
	{
		pinchStartVal_ = size;
	}
	
	
	size = (NSInteger) ( (CGFloat)(pinchStartVal_+1) * gesture.scale ) - 1;
	
	[myApp setOverrideFontSize: size];
	
}

-(void)swipe:(UISwipeGestureRecognizer*)gesture
{
	[self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark -
#pragma mark Search bar delegate



- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)aSearchText
{
	if( [aSearchText isEqualToString:@""] ) aSearchText = nil;
	
	self.searchText = aSearchText;
	
	if( aSearchText == nil  )
	{
		gusses_ = nil;
		hasDefinition_ = NO;
		
		if( viewAppeared_ )
			[self.tableView reloadData];
		return;
	}
	
	guessing_ = YES;
	
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0);
	dispatch_async(queue, ^{
		
		
		
		hasDefinition_ = [UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:aSearchText];
		
		if( hasDefinition_ )
		{
			[self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
		}
		
		
		if( textChecker_ == nil )
		{
			textChecker_ = [[UITextChecker alloc] init];
		}
		
		NSString* language = [[UITextChecker availableLanguages] objectAtIndex:0];
		if( !language ) language = @"en_US";
		
		
		
		NSArray* guessedArray = nil;
		NSArray *possibleCompletions = nil;
		
		if( aSearchText.length > 1 )
		{
			@synchronized(textChecker_)
			{
				guessedArray = [textChecker_ guessesForWordRange:NSMakeRange(0, aSearchText.length) inString:aSearchText language:language];
				
				possibleCompletions = [textChecker_ completionsForPartialWordRange:NSMakeRange(0, aSearchText.length)
																																	inString:aSearchText language:language];
			}
		}
		
		
		
		NSMutableArray *array = [[NSMutableArray alloc] init];
		
		
		
		for( NSString* str in guessedArray )
		{
			if( aSearchText != self.searchText ) break;
			
			if( ![str isEqualToString:self.searchText] )
				if( [UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:str] )
				{
					[array addObject: str];
				}
		}
		
		for( NSString* str in possibleCompletions )
		{
			if( aSearchText != self.searchText  ) break;
			
			if( ![str isEqualToString:self.searchText] )
				if( [UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:str] )
				{
					[array addObject: str];
				}
		}
		
		if( aSearchText == self.searchText  )
		{
			@synchronized(self)
			{
				gusses_ = array;
				guessing_ = NO;
				
				if( viewAppeared_ )
					[self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
			}
		}
		
	});
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	
	if( hasDefinition_ )
	{
		[self presentReferenceLibrary:self.searchText addToHistory:YES];
		
	}else if( [gusses_ count] > 0 )
	{
		[self presentReferenceLibrary:[gusses_ objectAtIndex:0] addToHistory:YES];
		
	}
	
}


-(void)addToHistory:(NSString*)term
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"DisableHistory"] ) return;
	
	
	NSMutableArray* array = [[NSMutableArray alloc] init];
	[array addObjectsFromArray:self.history];
	[array removeObject: term];
	[array insertObject:term atIndex:0];
	self.history = array;
	
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	[searchBar resignFirstResponder];	
}


#pragma mark - Application Delegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	
	// Check international mode option
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	
	
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	NSString* aSearchText = [ud objectForKey:SearchTextKey];
	
	self.searchText = aSearchText;
	
	NSArray* aHistory = [ud objectForKey:HistoryKey];
	
	self.history = aHistory;
	
	self.window.rootViewController = self;
	[self.window makeKeyAndVisible];
	
		
	return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{

	
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	
	if( [ud  boolForKey:StartAsBlank] )
	{

		guessing_ = NO;
		self.searchText = nil;

		if( self.presentedViewController )
			[self dismissViewControllerAnimated:YES completion:nil];

	}
	
	[self reloadView];
		
	[ud setObject:searchText forKey:SearchTextKey];
	[ud setObject:history forKey:HistoryKey];
	[ud synchronize];
}




- (void)applicationWillEnterForeground:(UIApplication *)application
{

	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

	[ud synchronize];
	
	if( [ud  boolForKey:StartAsBlank] )
	{

		guessing_ = NO;
		self.searchText = nil;

		
		if( self.presentedViewController )
			[self dismissViewControllerAnimated:YES completion:nil];

	}
	[self reloadView];
	
	if( searchBar.text.length == 0 )
		[self.searchBar becomeFirstResponder];

}


- (void)applicationWillTerminate:(UIApplication *)application
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	
	[ud setObject:searchText forKey:SearchTextKey];
	[ud setObject:history forKey:HistoryKey];
	[ud synchronize];
}


@end



