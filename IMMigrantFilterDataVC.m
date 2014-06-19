//
//  IMMigrantFilterDataVC.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 6/2/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMMigrantFilterDataVC.h"
#import "IMOptionChooserViewController.h"
#import "IMFormCell.h"
#import "IMCountryListVC.h"
#import "IMDBManager.h"
#import "IMAccommodationChooserVC.h"
#import "Accommodation.h"
#import "NSDate+Relativity.h"


#define filter_Search 0
#define filter_Active 6
#define filter_Sex 1
#define filter_Nationality 2
#define filter_Location 3
#define filter_AgeMin 4
#define filter_AgeMax 5
#define filter_Apply 7
#define filter_Clear 8

#define total_filter 9


@interface IMMigrantFilterDataVC ()<UIPopoverControllerDelegate, IMOptionChooserDelegate>

@property (nonatomic, strong) UIPopoverController *popover;

@end

@interface IMMigrantFilterDataVC ()<UISearchBarDelegate,UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *indexes;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) NSPredicate *nationalityPredicate;
@property (nonatomic, strong) NSPredicate *genderPredicate;
@property (nonatomic, strong) NSPredicate *namePredicate;
@property (nonatomic, strong) NSPredicate *detentionLocationPredicate;
@property (nonatomic, strong) NSPredicate *ageMinPredicate;
@property (nonatomic, strong) NSPredicate *ageMaxPredicate;
@property (nonatomic, strong) NSPredicate *activePredicate;
@property (nonatomic) UIView * disableViewOverlay;
@property (nonatomic) IMFormCell *applyCell;
@property (nonatomic) IMFormCell *resetCell;

@end

@implementation IMMigrantFilterDataVC
@synthesize age_max;
@synthesize age_min;

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
    
    if (self.ageMinPredicate){
        if (!tmp) {
            tmp =self.ageMinPredicate;
        }else {
            tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self.ageMinPredicate]];
        }
    }
    
    if (self.ageMaxPredicate){
        if (!tmp) {
            tmp =self.ageMaxPredicate;
        }else {
            tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self.ageMaxPredicate]];
        }
    }
    
    if (self.activePredicate){
        if (!tmp) {
            tmp =self.activePredicate;
        }else {
            tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self.activePredicate]];
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
    self.name = searchBar.text= Nil;
    self.namePredicate = Nil;
    [self searchBar:searchBar activate:NO];
    //send update predicate
    [self sendPredicateChanges];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    // Do the search and show the results in tableview
    // Deactivate the UISearchBar
	
    // You'll probably want to do this on another thread
    // SomeService is just a dummy class representing some
    // api that you are using to do the search
    
    self.name = searchBar.text;
    self.namePredicate = ([searchBar.text length] > 0 ) ? [NSPredicate predicateWithFormat:@"bioData.firstName CONTAINS[cd] %@ || bioData.familyName CONTAINS[cd] %@ || unhcrNumber CONTAINS[cd] %@", self.name,self.name,self.name]: Nil;
	
    //send update predicate
    [self sendPredicateChanges];
    
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
    
    return total_filter;
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
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    IMFormCell *cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
    
    if (indexPath.section == 0) {
        if (indexPath.row == filter_Search) {
            UISearchBar * searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
            
            searchBar.delegate = self;
            searchBar.showsCancelButton = NO;
            searchBar.placeholder = @"Search by Name or UNHCR number";
            [cell addSubview:searchBar];
        }else if (indexPath.row == filter_Sex) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            //cell.labelTitle.text = @"Gender";
            cell.labelTitle.text = @"Sex";
            cell.labelValue.text = self.gender;
        }else if (indexPath.row == filter_Nationality) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Nationality";
            cell.labelValue.text = self.country.name;
        }else if (indexPath.row == filter_Location) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Detention Location";
            cell.labelValue.text = self.detentionLocation.name;
        }else if (indexPath.row == filter_AgeMin){
            //TODO : get max and min age range
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeStepper reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Age Min";
            cell.stepper.value = self.age_min;
            cell.onStepperValueChanged = ^(int value){
                self.age_min = value;
                //implement Age Min
                if (self.age_min > 0) {
                    self.ageMinPredicate = [NSPredicate predicateWithFormat:@"(bioData.dateOfBirth <= %@)", [self calculateAge:self.age_min]];
                    self.applyCell.hidden = self.resetCell.hidden = false;
                }
            };
        }else if (indexPath.row == filter_AgeMax){
            //TODO : get max and min age range
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeStepper reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Age Max";
            cell.stepper.value = self.age_max;
            cell.onStepperValueChanged = ^(int value){
                self.age_max = value;
                if (self.age_max > 0) {
                    self.ageMaxPredicate = [NSPredicate predicateWithFormat:@"(bioData.dateOfBirth >= %@)", [self calculateAge:self.age_max+1]];
                    //                    cell.button.hidden = false;
                    self.applyCell.hidden = self.resetCell.hidden = false;
                    
                }
            };
        }else if (indexPath.row == filter_Apply){
            self.applyCell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            self.applyCell.labelTitle.text = @"Apply Filter Values";
            self.applyCell.labelTitle.tintColor = [UIColor IMRed];
            self.applyCell.labelTitle.font = [UIFont thinFontWithSize:28];
            self.applyCell.labelTitle.textAlignment = NSTextAlignmentCenter;
            self.applyCell.labelTitle.textColor = [UIColor IMRed];
            self.applyCell.hidden = true;
            cell = self.applyCell;
        }else if (indexPath.row == filter_Clear){
            self.resetCell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            self.resetCell.labelTitle.text = @"Clear Filter Values";
            self.resetCell.labelTitle.tintColor = [UIColor IMRed];
            self.resetCell.labelTitle.font = [UIFont thinFontWithSize:28];
            self.resetCell.labelTitle.textAlignment = NSTextAlignmentCenter;
            self.resetCell.labelTitle.textColor = [UIColor IMRed];
            self.resetCell.hidden = true;
            cell = self.resetCell;
        }else if (indexPath.row == filter_Active){
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeSwitch reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Active Migrant";
            cell.switcher.on = self.activeMigrant;
            cell.onSwitcherValueChanged = ^(BOOL value){
                self.activeMigrant = value;
                if (self.activeMigrant) {
                    self.activePredicate = [NSPredicate predicateWithFormat:@"active = YES"];
                }else {
                    self.activePredicate = [NSPredicate predicateWithFormat:@"active = NO"];
                }
                self.applyCell.hidden = self.resetCell.hidden = false;
            };
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
        if (indexPath.row == filter_Sex) {
            IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithConstantsKey:CONST_GENDER delegate:self];
            vc.selectedValue = self.gender;
            [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
        }else if (indexPath.row == filter_Nationality) {
//            NSPredicate *reg = [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"bioData.nationality.name != %@",Nil],self.basePredicate]];
            IMCountryListVC *vc = [[IMCountryListVC alloc] initWithBasePredicate:Nil presentAsModal:NO popover:YES withEntity:@"Migrant" sortDescriptorWithKey:@"bioData.nationality.name"];
            vc.onSelected = ^(Country *country){
                Country *selectedCountry = [Country countryWithCode:country.code inManagedObjectContext:context];
                self.country = selectedCountry;
                //set predicate
                self.nationalityPredicate = [NSPredicate predicateWithFormat:@"bioData.nationality.code = %@ || bioData.nationality.name = %@ || bioData.countryOfBirth.code = %@ || bioData.countryOfBirth.name = %@", self.country.code,self.country.name, self.country.code,self.country.name];
                
                [self.popover dismissPopoverAnimated:YES];
                self.popover = nil;
                [self.tableView reloadRowsAtIndexPaths:@[indexPath, [NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                
                //show button
                self.applyCell.hidden = self.resetCell.hidden = false;
            };
            [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
            
        }else if (indexPath.row == filter_Location) {
            [self showAccommodation:indexPath withContext:context];
            
        }else if (indexPath.row == filter_Apply){
            if (self.age_max < self.age_min) {
                //show alert
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Input" message:@"Age Max can not less than Age Min" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }else{
                //send change
                [self sendPredicateChanges];
            }
        }else if (indexPath.row == filter_Clear){
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
        //set predicate
        self.genderPredicate = [NSPredicate predicateWithFormat:@"bioData.gender = %@", self.gender];
        //        }
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        //show button
        self.applyCell.hidden = self.resetCell.hidden = false;
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
//    NSPredicate *reg = (self.basePredicate != Nil) ? [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"detentionLocation != %@",Nil],self.basePredicate]]:Nil;
//    NSLog(@"self.basePredicate : %@",[self.basePredicate description]);
    IMAccommodationChooserVC *vc = [[IMAccommodationChooserVC alloc] initWithBasePredicate:Nil presentAsModal:NO withEntity:@"Migrant" sortDescriptorWithKey:@"detentionLocation"];
    if (vc) {
   
    vc.onSelected = ^(Accommodation *accommodation){
        self.detentionLocation = [Accommodation accommodationWithId:accommodation.accommodationId inManagedObjectContext:context];
        //set predicate
        self.detentionLocationPredicate = [NSPredicate predicateWithFormat:@"detentionLocation = %@", self.detentionLocation.accommodationId];
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        //show button
        self.applyCell.hidden = self.resetCell.hidden = false;
        
    };
    vc.preferredContentSize = CGSizeMake(500, 400);
    [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:YES];
        
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.nationalityPredicate = self.genderPredicate = self.namePredicate = self.detentionLocationPredicate = Nil;
    self.country = Nil;
    self.detentionLocation =Nil;
    self.gender = self.name = Nil;
    //set predicate
    self.activePredicate = Nil;
    self.activeMigrant = TRUE;
    //    self.totalPredicate =0;
    self.disableViewOverlay = [[UIView alloc]
                               initWithFrame:CGRectMake(0, 88, 320, 416)];
    
    //0, 0, 320, 44
    self.disableViewOverlay.backgroundColor=[UIColor blackColor];
    self.disableViewOverlay.alpha = 0;    
}

// Since this view is only for searching give the UISearchBar
// focus right away
- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    //check if there is any of filter value is fill, then show apply and reset button
    
    if (self.nationalityPredicate || self.genderPredicate || self.namePredicate || self.detentionLocationPredicate || self.ageMinPredicate || self.ageMaxPredicate || self.activePredicate)
    {
     self.applyCell.hidden = self.resetCell.hidden = false;
    }
}

- (NSDate *)calculateAge:(int)ageValue
{
    if (ageValue > 0) {
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDate *today = [NSDate date];
        
        // components for "min Years ago"
        NSDateComponents *dateOffset = [[NSDateComponents alloc] init];
        [dateOffset setYear:0-ageValue];
        
        // date on "today minus age_min years"
        NSDate *minYearsAgo = [calendar dateByAddingComponents:dateOffset toDate:today options:0];
        
        // only use month and year component to create a date at the beginning of the month
        NSDateComponents *minYearsAgoComponents = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:minYearsAgo];
        
        return minYearsAgo = [calendar dateFromComponents:minYearsAgoComponents];
    }else return Nil;
}

- (void)resetValue
{
    self.activePredicate = self.ageMinPredicate = self.ageMaxPredicate = self.nationalityPredicate = self.genderPredicate = self.namePredicate = self.detentionLocationPredicate = Nil;
    
    self.country = Nil;
    self.detentionLocation =Nil;
    self.gender = self.name = Nil;
    self.age_min = 0;
    self.age_max = 0;
    self.activeMigrant = TRUE;
    
    //hide button
    self.applyCell.hidden = self.resetCell.hidden = TRUE;
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
