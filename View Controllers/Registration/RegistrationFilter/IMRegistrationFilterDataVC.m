//
//  IMRegistrationFilterDataVC.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 4/11/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMRegistrationFilterDataVC.h"
#import "IMOptionChooserViewController.h"
#import "IMFormCell.h"
#import "IMCountryListVC.h"
#import "IMDBManager.h"
#import "IMAccommodationChooserVC.h"
#import "Accommodation.h"


@interface IMRegistrationFilterDataVC ()<UIPopoverControllerDelegate, IMOptionChooserDelegate>

@property (nonatomic, strong) UIPopoverController *popover;

@end

@interface IMRegistrationFilterDataVC ()<UISearchBarDelegate,UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *indexes;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) NSPredicate *nationalityPredicate;
@property (nonatomic, strong) NSPredicate *genderPredicate;
@property (nonatomic, strong) NSPredicate *namePredicate;
@property (nonatomic, strong) NSPredicate *detentionLocationPredicate;
@property (nonatomic) UIView * disableViewOverlay;

@end


@implementation IMRegistrationFilterDataVC
#pragma mark Data Management

- (void)sendPredicateChanges
{
    if (!self.onSelected) return;
    
    
    NSPredicate *tmp = Nil;
    
    if (self.nationalityPredicate) {
        if (!tmp) {
            tmp =self.nationalityPredicate;
        }else {
            tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self.nationalityPredicate]];
        }
    }
    if (self.genderPredicate) {
        if (!tmp) {
            tmp =self.genderPredicate;
        }else {
            tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self.genderPredicate]];
        }
    }
    if (self.namePredicate){
        if (!tmp) {
            tmp =self.namePredicate;
        }else {
            tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self.namePredicate]];
        }
    }
    if (self.detentionLocationPredicate){
        if (!tmp) {
            tmp =self.detentionLocationPredicate;
        }else {
            tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self.detentionLocationPredicate]];
        }
    }
    
    //send to caller
    self.onSelected(tmp);
    
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (id)initWithAction:(void (^)(NSPredicate *basePredicate))onSelected andBasePredicate:(NSPredicate *)basepredicate
{
    self = [super init];
    
    self.onSelected = onSelected;
    self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    self.basePredicate = basepredicate;
    return self;
}

- (id)initWithAction:(void (^)(NSPredicate *basePredicate))onSelected
{
    self = [super init];
    
    self.onSelected = onSelected;
    self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    self.basePredicate = Nil;
    
    return self;
}


#pragma mark -
#pragma mark UISearchBarDelegate Methods

- (void)searchBar:(UISearchBar *)searchBar
    textDidChange:(NSString *)searchText {
    // We don't want to do anything until the user clicks
    // the 'Search' button.
    // If you wanted to display results as the user types
    // you would do that here.
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    // searchBarTextDidBeginEditing is called whenever
    // focus is given to the UISearchBar
    // call our activate method so that we can do some
    // additional things when the UISearchBar shows.
    [self searchBar:searchBar activate:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    // searchBarTextDidEndEditing is fired whenever the
    // UISearchBar loses focus
    // We don't need to do anything here.
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    // Clear the search text
    // Deactivate the UISearchBar
    searchBar.text=@"";
    [self searchBar:searchBar activate:NO];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    // Do the search and show the results in tableview
    // Deactivate the UISearchBar
	
    // You'll probably want to do this on another thread
    // SomeService is just a dummy class representing some
    // api that you are using to do the search
    if ([searchBar.text length] > 0 ) {
        
        self.name = searchBar.text;
        self.namePredicate = [NSPredicate predicateWithFormat:@"bioData.firstName LIKE[cd] %@ || bioData.familyName LIKE[cd] %@ || unhcrNumber LIKE[cd] %@", self.name,self.name,self.name];
        
        //send update predicate
        [self sendPredicateChanges];
    }
	
    [self searchBar:searchBar activate:NO];
	
    
}

// We call this when we want to activate/deactivate the UISearchBar
// Depending on active (YES/NO) we disable/enable selection and
// scrolling on the UITableView
// Show/Hide the UISearchBar Cancel button
// Fade the screen In/Out with the disableViewOverlay and
// simple Animations
- (void)searchBar:(UISearchBar *)searchBar activate:(BOOL) active{
    self.tableView.allowsSelection = !active;
    self.tableView.scrollEnabled = !active;
    if (!active) {
        [_disableViewOverlay removeFromSuperview];
    } else {
        self.disableViewOverlay.alpha = 0;
        [self.view addSubview:self.disableViewOverlay];
		
        [UIView beginAnimations:@"FadeIn" context:nil];
        [UIView setAnimationDuration:0.5];
        self.disableViewOverlay.alpha = 0.6;
        [UIView commitAnimations];
		
        // probably not needed if you have a details view since you
        // will go there on selection
        NSIndexPath *selected = [self.tableView
                                 indexPathForSelectedRow];
        if (selected) {
            [self.tableView deselectRowAtIndexPath:selected
                                          animated:NO];
        }
    }
    [searchBar setShowsCancelButton:active animated:YES];
}

#pragma mark Table View Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    static NSString *headerIdentifier = @"filterHeader";
    
    IMTableHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerIdentifier];
    if (!headerView) {
        headerView = [[IMTableHeaderView alloc] initWithTitle:@"" actionTitle:nil alignCenterY:YES reuseIdentifier:headerIdentifier];
        headerView.labelTitle.font = [UIFont thinFontWithSize:28];
        headerView.labelTitle.textAlignment = NSTextAlignmentCenter;
        headerView.labelTitle.textColor = [UIColor IMRed];
        headerView.backgroundView = [[UIView alloc] init];
        headerView.backgroundView.backgroundColor = [UIColor whiteColor];
    }
    
    headerView.labelTitle.text = @"Migrant Filter";
    
    //    headerView.
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    IMFormCell *cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            UISearchBar * searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
            
            searchBar.delegate = self;
            searchBar.showsCancelButton = NO;
            searchBar.placeholder = @"Search by Name or UNHCR number";
            [cell addSubview:searchBar];
        }else if (indexPath.row == 1) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Gender";
            cell.labelValue.text = self.gender;
        }else if (indexPath.row == 2) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Nationality";
            cell.labelValue.text = self.country.name;
        }else if (indexPath.row == 3) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Detention Location";
            cell.labelValue.text = self.detentionLocation.name;
        }else if (indexPath.row == 4){
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Clear Filter Values";
            cell.labelTitle.tintColor = [UIColor IMRed];
            cell.labelTitle.font = [UIFont thinFontWithSize:28];
            cell.labelTitle.textAlignment = NSTextAlignmentCenter;
            cell.labelTitle.textColor = [UIColor IMRed];
        }
        
    }
    return cell;
}

- (void)showPopoverFromRect:(CGRect)rect withViewController:(UIViewController *)vc navigationController:(BOOL)useNavigation
{
    rect = CGRectMake(rect.size.width - 150, rect.origin.y, rect.size.width, rect.size.height);
    vc.view.tintColor = [UIColor IMMagenta];
    vc.modalInPopover = NO;
    
    if (useNavigation) {
        UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:vc];
        navCon.navigationBar.tintColor = [UIColor IMMagenta];
        self.popover = [[UIPopoverController alloc] initWithContentViewController:navCon];
    }else {
        vc.view.tintColor = [UIColor IMMagenta];
        self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    }
    
    self.popover.delegate = self;
    [self.popover presentPopoverFromRect:rect inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

-(BOOL)isNumeric:(NSString*)inputString{
    BOOL isValid = NO;
    NSCharacterSet *alphaNumbersSet = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *stringSet = [NSCharacterSet characterSetWithCharactersInString:inputString];
    isValid = [alphaNumbersSet isSupersetOfSet:stringSet];
    return isValid;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    
    if (self.selectedIndexPath && ![self.selectedIndexPath isEqual:indexPath]) {
        [[tableView cellForRowAtIndexPath:self.selectedIndexPath] setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    self.selectedIndexPath = indexPath;
    [[tableView cellForRowAtIndexPath:self.selectedIndexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
    
    
    if (indexPath.section == 0) {
        if (indexPath.row == 1) {
            IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithConstantsKey:CONST_GENDER delegate:self];
            vc.selectedValue = self.gender;
            [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
            
        }else if (indexPath.row == 2) {
//            NSPredicate *reg =[NSPredicate predicateWithFormat:@"bioData.nationality.name != %@",Nil];

//            IMCountryListVC *vc = [[IMCountryListVC alloc] initWithBasePredicate:self.basePredicate presentAsModal:NO popover:YES withEntity:@"Registration" sortDescriptorWithKey:@"bioData.nationality.name"];
                IMCountryListVC *vc = [[IMCountryListVC alloc] initWithBasePredicate:Nil presentAsModal:NO popover:YES];
            vc.onSelected = ^(Country *country){
                Country *selectedCountry = [Country countryWithCode:country.code inManagedObjectContext:context];
                
                self.country = selectedCountry;
                
                
                //set predicate
                self.nationalityPredicate = [NSPredicate predicateWithFormat:@"bioData.nationality.code = %@ || bioData.nationality.name = %@ || bioData.countryOfBirth.code = %@ || bioData.countryOfBirth.name = %@", self.country.code,self.country.name, self.country.code,self.country.name];
                
                [self.popover dismissPopoverAnimated:YES];
                self.popover = nil;
                [self.tableView reloadRowsAtIndexPaths:@[indexPath, [NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                
                //send change
                [self sendPredicateChanges];
                
            };
            [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
            
        }else if (indexPath.row == 3) {
            [self showAccommodation:indexPath withContext:context];
            
        }else if (indexPath.row == 4){
            [self resetValue];
            if (self.doneCompletionBlock) {
                self.doneCompletionBlock(Nil);
            }
        }
        
    }
    
    
}

- (void)showOptionChooserWithConstantsKey:(NSString *)constantsKey indexPath:(NSIndexPath *)indexPath useNavigation:(BOOL)useNavigation
{
    IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithConstantsKey:constantsKey delegate:self];
    vc.view.tintColor = [UIColor IMMagenta];
    [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:useNavigation];
}


- (void)optionChooser:(IMOptionChooserViewController *)optionChooser didSelectOptionAtIndex:(NSUInteger)selectedIndex withValue:(id)value
{
    if (optionChooser.constantsKey == CONST_GENDER) {
        self.gender = value;
        if ([self.gender isEqualToString:@"All"]) {
            //reset value
            self.genderPredicate = Nil;
        }else {
            //set predicate
            self.genderPredicate = [NSPredicate predicateWithFormat:@"bioData.gender = %@", self.gender];
        }
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];

        //send change
        [self sendPredicateChanges];
    }
    
    [self.popover dismissPopoverAnimated:YES];
    self.popover = nil;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    self.popover = nil;
}

- (void)showAccommodation:(NSIndexPath *)indexPath withContext:(NSManagedObjectContext *)context
{
    IMAccommodationChooserVC *vc = [[IMAccommodationChooserVC alloc] initWithBasePredicate:nil presentAsModal:NO];
    
    vc.onSelected = ^(Accommodation *accommodation){
        self.detentionLocation = [Accommodation accommodationWithId:accommodation.accommodationId inManagedObjectContext:context];
        //set predicate
        self.detentionLocationPredicate = [NSPredicate predicateWithFormat:@"detentionLocation = %@", self.detentionLocation.accommodationId];
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

        //send change
        [self sendPredicateChanges];
        
    };
    vc.preferredContentSize = CGSizeMake(500, 400);
    [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.nationalityPredicate = self.genderPredicate = self.namePredicate = self.detentionLocationPredicate = Nil;
    self.country = Nil;
    self.detentionLocation =Nil;
    self.gender = self.name = Nil;
    //    self.totalPredicate =0;
    self.disableViewOverlay = [[UIView alloc]
                               initWithFrame:CGRectMake(0, 88, 320, 416)];
    
    //0, 0, 320, 44
    self.disableViewOverlay.backgroundColor=[UIColor blackColor];
    self.disableViewOverlay.alpha = 0;
    //    self.dict = [NSMutableDictionary dictionary];
    
}

// Since this view is only for searching give the UISearchBar
// focus right away
- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
}


- (void)resetValue
{
    self.nationalityPredicate = self.genderPredicate = self.namePredicate = self.detentionLocationPredicate = Nil;
    self.country = Nil;
    self.detentionLocation =Nil;
    self.gender = self.name = Nil;
    //    self.totalPredicate =0;
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
