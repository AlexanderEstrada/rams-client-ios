//
//  IMMovementVC.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 7/1/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

//#import "IMMovementVC.h"
#import "IMMovementViewController.h"
#import "IMFormCell.h"
#import "IMDatePickerVC.h"
#import "IMCountryListVC.h"
#import "IMAccommodationChooserVC.h"
#import "IMOptionChooserViewController.h"
#import "IMDBManager.h"
#import "IMPortChooserVC.h"
#import "NSDate+Relativity.h"
#import "Port+Extended.h"
#import "Movement+Extended.h"

#import "IMMovementListVC.h"

@interface IMMovementViewController ()<UIPopoverControllerDelegate, IMOptionChooserDelegate,UITableViewDataSource, UITableViewDelegate,IMMovementReviewTableVCDelegate>

@property (nonatomic) BOOL creating;
@property (nonatomic) BOOL show;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation IMMovementViewController

- (void)setMigrant:(Migrant *)migrant
{
    _migrant = migrant;
    
    [self.tableView reloadData];
}


- (void)save
{
    if (![self validateInput]) {
        [self showAlertWithTitle:@"Invalid Input" message:@"Please evaluate your inputs before continue."];
        self.navButton.enabled = FALSE;
        return;
    }
    
    if (self.onSave) self.onSave(self.movement, !self.creating);
    
    //set segue to next page
    self.navButton.enabled = TRUE;

}

- (void)cancel
{
    if (self.creating) {
        [self.context deleteObject:self.movement];
    }
    
    if (self.onSave) self.onSave(nil, !self.creating);
}


- (BOOL)validateInput
{
    //check if all value is valid
    BOOL stat = TRUE;
    
    
    if (![self.movement.type isEqual:@"Escape"] && ![self.movement.type isEqual:@"Release"] && ![self.movement.type isEqual:@"Decease"]) {
        stat &= self.movement.date?TRUE:FALSE;
        stat &= self.movement.documentNumber?TRUE:FALSE;
        stat &= self.movement.proposedDate?TRUE:FALSE;
        stat &= self.movement.travelMode?TRUE:FALSE;
        stat &= self.movement.referenceCode?TRUE:FALSE;
        stat &= self.movement.departurePort?TRUE:FALSE;
        if ([self.movement.type isEqual:@"Transfer"]) {
            stat &= self.movement.originLocation?TRUE:FALSE;
            stat &= self.movement.transferLocation?TRUE:FALSE;
        }
        
        if ([self.movement.type isEqual:@"AVR"] || [self.movement.type isEqual:@"Deportation"] || [self.movement.type isEqual:@"Resettlement"]) {
            
            stat &=  self.movement.destinationCountry?TRUE:FALSE;
        }
        
    }else {
        stat &= self.movement.date?TRUE:FALSE;
        stat &= self.movement.type?TRUE:FALSE;
        stat &= self.movement.originLocation?TRUE:FALSE;
    }
    
    return stat;
}


#pragma mark Table View
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self movementSectionFormula:Nil];
}

- (NSInteger)movementSectionFormula:(NSString *)movementType{
    
    NSInteger totalSection =2;
    NSArray *items = [IMConstants constantsForKey:CONST_MOVEMENT_TYPE];
    NSUInteger item = [items indexOfObject:movementType?movementType:self.movement.type];
    switch (item) {
        case 6:
            //Decease
        case 5:
            //Release
        case 0:
            // Escape
            totalSection += 1;
            break;
        case 1:
            // Transfer
            totalSection += 7;
            break;
        case 2:
            // AVR
        case 3:
            //Resettlement
        case 4 :
            //Deportation
            totalSection +=6;
            break;
        default:
            //only show movement type and date
            break;
    }
    
    return totalSection;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"movementCellIdentifier";
    
    IMFormCell *cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
    
    /*
     1. type
     2. date
     3. document number
     4. proposed date
     5. travel mode
     6. reference code
     7. departure port
     
     case tranfer :
     8. origin location
     9. transfer location
     
     case avr/deportation/resettlement
     8. destination country
     
     */
    
    if (!self.movement) {
        self.movement = [Movement newMovementInContext:self.context];
    }
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Movement Type";
            cell.labelValue.text = self.movement.type;
        } else if (indexPath.row == 1) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Movement Date";
            cell.labelValue.text = [self.movement.date mediumFormatted];
        }else if (indexPath.row == 2) {
            if ([self.movement.type isEqualToString:@"Escape"] || [self.movement.type isEqualToString:@"Release"] || [self.movement.type isEqualToString:@"Decease"]) {
                cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
                cell.labelTitle.text = @"Origin Location";
                cell.labelValue.text = self.movement.originLocation.name;
            }else{
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Document Number";
            cell.textValue.placeholder = @"e.g LSD-09C02429";
            cell.textValue.text = self.movement.documentNumber;
            cell.onTextValueReturn = ^(NSString *value){ self.movement.documentNumber = value; };
            cell.characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet whitespaceCharacterSet]];
            }
        }else if (indexPath.row == 3) {
            
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Proposed Date";
            cell.labelValue.text = [self.movement.proposedDate mediumFormatted];
            
        }else if (indexPath.row == 4) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Travel Mode";
            cell.labelValue.text = self.movement.travelMode;
        }else if (indexPath.row == 5) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Reference Code";
            cell.textValue.placeholder = @"e.g travel/vehicle/flight number";
            cell.textValue.text = self.movement.referenceCode;
            cell.onTextValueReturn = ^(NSString *value){ self.movement.referenceCode = value; };
            cell.characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet whitespaceCharacterSet]];
        }else if (indexPath.row == 6) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Departure Port";
            cell.labelValue.text = self.movement.departurePort.name;
        }else if (indexPath.row == 7) {
            switch ([self movementSectionFormula:Nil]) {
                case 8:
                    cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
                    cell.labelTitle.text = @"Destination Country";
                    cell.labelValue.text = self.movement.destinationCountry.name;
                    break;
                  case 9:
                    cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
                    cell.labelTitle.text = @"Origin Location";
                    cell.labelValue.text = self.movement.originLocation.name;
                    break;
                default:
                    break;
            }
        }else if (indexPath.row == 8) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Transfer Location";
            cell.labelValue.text = self.movement.transferLocation.name;
        }
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = @"Movement Detail";
    
    static NSString *identifier = @"HeaderIdentifier";
    IMTableHeaderView *header = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!header) {
        header = [[IMTableHeaderView alloc] initWithTitle:title actionTitle:nil reuseIdentifier:identifier];
        header.labelTitle.font = [UIFont boldFontWithSize:16];
    }
    
    header.labelTitle.text = title;
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        
        /*
         1. type
         2. date
         3. document number
         4. proposed date
         5. travel mode
         6. reference code
         7. departure port
         
         case tranfer :
         8. origin location
         9. transfer location
         
         case avr/deportation/resettlement
         8. destination country
         */
        if (indexPath.row == 0) {
            IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithConstantsKey:CONST_MOVEMENT_TYPE delegate:self];
            vc.selectedValue = self.movement.type;
            vc.firstRowIsSpecial = NO;
            [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
        }else if (indexPath.row == 1) {
            IMDatePickerVC *datePicker = [[IMDatePickerVC alloc] initWithAction:^(NSDate *date){
                self.movement.date = date;
                IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                cell.labelValue.text = [self.movement.date mediumFormatted];
            }];
            datePicker.maximumDate = [NSDate date];
            datePicker.date = self.movement.date;
            [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:datePicker navigationController:NO];
        }else if (indexPath.row == 3){
            IMDatePickerVC *datePicker = [[IMDatePickerVC alloc] initWithAction:^(NSDate *date){
                self.movement.proposedDate = date;
                IMFormCell *cell = (IMFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                cell.labelValue.text = [self.movement.proposedDate mediumFormatted];
            }];
            datePicker.maximumDate = [NSDate date];
            datePicker.date = self.movement.proposedDate;
            [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:datePicker navigationController:NO];
            
        }else if (indexPath.row == 4){
            IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithConstantsKey:CONST_TRAVEL_MODE delegate:self];
            vc.selectedValue = self.movement.travelMode;
            vc.firstRowIsSpecial = NO;
            [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
        }else if (indexPath.row == 6){
            [self showPort:indexPath];
        }else if (indexPath.row == 7) {
            
            switch ([self movementSectionFormula:Nil]) {
                case 8:{
//                     case avr/deportation/resettlement
                    //case movement type is resettlement then show all country, else only show migrant nationality that registered (AVR/Deportation)
                    IMCountryListVC *vc = nil;
                    vc = [self.movement.type isEqualToString:@"Resettlement"]?[[IMCountryListVC alloc] initWithBasePredicate:nil presentAsModal:NO popover:YES]:[[IMCountryListVC alloc] initWithBasePredicate:Nil presentAsModal:NO popover:YES withEntity:@"Migrant" sortDescriptorWithKey:@"bioData.nationality.name"];
                    
                    vc.onSelected = ^(Country *country){
                        self.movement.destinationCountry = [Country countryWithCode:country.code inManagedObjectContext:self.movement.managedObjectContext];
                        [self.popover dismissPopoverAnimated:YES];
                        self.popover = nil;
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    };
                    [self showPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
                    break;
                }
                case 9:
                     [self showAccommodation:indexPath];
                    break;
                default:
                    break;
            }
        }else if (indexPath.row == 8) {
            [self showAccommodation:indexPath];
        }else if (indexPath.row == 2 && ([self.movement.type isEqualToString:@"Escape"] || [self.movement.type isEqualToString:@"Release"] || [self.movement.type isEqualToString:@"Decease"])){
             [self showAccommodation:indexPath];
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
    if (optionChooser.constantsKey == CONST_MOVEMENT_TYPE) {
        self.movement.type = value;
        //reload table
        [self.tableView reloadData];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        
//        //set to disable to avoid user error while input
//        if (self.navButton.enabled && ![self validateInput]) {
//            self.navButton.enabled = FALSE;
//        }
        

    }else if (optionChooser.constantsKey == CONST_TRAVEL_MODE){
        self.movement.travelMode = value;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:4 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [self.popover dismissPopoverAnimated:YES];
    self.popover = nil;
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

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    self.popover = nil;
}

- (void)showAccommodation:(NSIndexPath *)indexPath
{
    IMAccommodationChooserVC *vc = Nil;
    if (indexPath.row == 7) {
        //only show detention location based on migrant detention location
         vc = [[IMAccommodationChooserVC alloc] initWithBasePredicate:Nil presentAsModal:NO withEntity:@"Migrant" sortDescriptorWithKey:@"detentionLocation"];

    }else{
        vc = [[IMAccommodationChooserVC alloc] initWithBasePredicate:nil presentAsModal:NO];
    }
   
    vc.onSelected = ^(Accommodation *accommodation){
        switch (indexPath.row) {
            case 2:
            case 7:
                self.movement.originLocation = [Accommodation accommodationWithId:accommodation.accommodationId inManagedObjectContext:self.movement.managedObjectContext];
                break;
            case 8:
                self.movement.transferLocation = [Accommodation accommodationWithId:accommodation.accommodationId inManagedObjectContext:self.movement.managedObjectContext];
                break;
            default:
                break;
        }
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    vc.preferredContentSize = CGSizeMake(500, 400);
    [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:YES];
}

- (void)showPort:(NSIndexPath *)indexPath
{
    IMPortChooserVC *vc = [[IMPortChooserVC alloc] initWithBasePredicate:nil presentAsModal:NO];
    vc.onSelected = ^(Port *port){
        self.movement.departurePort = [Port portWithName:port.name inManagedObjectContext:self.movement.managedObjectContext];
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    vc.preferredContentSize = CGSizeMake(500, 400);
    [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (!self.context) {
        self.context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    }
    if (!self.movement) {
        self.movement = [Movement newMovementInContext:self.context];
    }
    self.creating = YES;
    self.show = NO;
    self.navigationController.navigationBar.tintColor = [UIColor IMMagenta];
    self.view.tintColor = [UIColor IMMagenta];
    
    self.navButton.enabled = YES;
    [self showMigrantList:Nil shouldShowMigrantList:NO];
    //setup navigation bar items
//    UIBarButtonItem *itemSave = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
//                                                                                target:self action:@selector(save)];
//    self.navigationItem.rightBarButtonItems = @[self.navButton,itemSave];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ShowListMigrant) name:IMShowMigrantListNotification object:nil];
    
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCancelNotification) name:IMCancelNotification object:nil];
}

- (void)ShowListMigrant{
    if (!self.show) {
        self.show = YES;
    }
    
}

- (void)onCancelNotification{
    if (self.movement) {
        self.movement = Nil;
    }
}
-(void)showMigrantList:(IMMovementReviewTableVC *)view shouldShowMigrantList:(BOOL)bShowMigrantList{
    NSLog(@"============= get notification ============= ");
    if (bShowMigrantList) {
        [self.sideMenuDelegate changeContentViewTo:@"IMMigrantViewController" fromSideMenu:NO];
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark View Lifecycle
- (id)initWithMigrant:(Migrant *)migrant action:(void (^)(Movement *movement, BOOL editing))onSave
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    self.title = @"Add Movement";
    self.onSave = onSave;
    self.migrant = migrant;
    self.modalInPopover = YES;
    self.preferredContentSize = CGSizeMake(500, 550);
    self.modalPresentationStyle = UIModalPresentationFormSheet;
    self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    self.tableView.backgroundColor = [UIColor whiteColor];
    
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];


    
 
    return self;
}

-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    [self.tableView reloadData];
    if (!self.context) {
            self.context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    }
    if (!self.movement) {
        self.movement = [Movement newMovementInContext:self.context];
    }
    if (self.show) {
        [self.sideMenuDelegate changeContentViewTo:@"IMMigrantViewController" fromSideMenu:NO];
    }
}

- (void) updateRow:(NSString *)lastMovementType and:(NSString *)currentMovementType
{
    NSInteger lastRowTotal = lastMovementType ?[self movementSectionFormula:lastMovementType]:2;
    NSInteger currentRowTotal = [self movementSectionFormula:currentMovementType];

    NSMutableArray *arrayOfCommand = [NSMutableArray array];
    if (lastRowTotal < currentRowTotal) {
        //case need update and insert the row
        for (; lastRowTotal < currentRowTotal; lastRowTotal++) {
            [arrayOfCommand addObject:[NSIndexPath indexPathForRow:(lastRowTotal -1) inSection:0]];
        }
        [self.tableView beginUpdates];
        [self.tableView  insertRowsAtIndexPaths:arrayOfCommand withRowAnimation:UITableViewRowAnimationRight];
        [self.tableView endUpdates];
    }else {
        //case need update and delete the row
        for (; currentRowTotal < lastRowTotal; currentRowTotal++) {
            [arrayOfCommand addObject:[NSIndexPath indexPathForRow:(currentRowTotal -1) inSection:0]];
        }
        [self.tableView beginUpdates];
        [self.tableView  deleteRowsAtIndexPaths:arrayOfCommand withRowAnimation:UITableViewRowAnimationRight];
        [self.tableView endUpdates];
    }
    
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"ShowMigrantList"]) {
        if (![self validateInput])  {
             [self showAlertWithTitle:@"Invalid Input" message:@"Please evaluate your inputs before saving."];
            return NO;
        }
    }
    
    if (self.onSave) self.onSave(self.movement, !self.creating);
    
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ShowMigrantList"]) {
        [[segue destinationViewController] setDelegate:self];
        [[segue destinationViewController] setMovement:self.movement];
    }
}


// - (void)viewDidLoad
// {
// [super viewDidLoad];
//
// if (!self.group) {
// NSManagedObjectContext *context = [[IMDBManager sharedManager] localDatabase].managedObjectContext;
// self.group = [NSEntityDescription insertNewObjectForEntityForName:@"InterceptionGroup" inManagedObjectContext:context];
// self.creating = YES;
// }
// }

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
