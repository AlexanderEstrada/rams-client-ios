//
//  IMNewInterceptionLocationVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 7/29/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMNewInterceptionLocationVC.h"
#import "IMLocationManager.h"
#import "IMGPlacesFetcher.h"
#import "NSString+NamingConvention.h"
#import "IMFormCell.h"
#import "IMInterceptionLocationUpdater.h"


@interface IMNewInterceptionLocationVC ()<UIAlertViewDelegate>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) NSString *locationName;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *province;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIButton *buttonGoogle;
@property (nonatomic, strong) IMGPlace *foundPlace;
@property (nonatomic, strong) UIBarButtonItem *itemSave;

@property (nonatomic, strong) NSDictionary *fetchedLocation;

@end


@implementation IMNewInterceptionLocationVC


#pragma mark Logical Methods
- (void)save
{
    [self.itemSave setEnabled:NO];
    [self showLoadingViewWithTitle:@"Submitting new location..."];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"name"]                 = self.locationName;
    params[@"locality"]             = self.city;
    params[@"administrativeArea"]   = self.province;
    params[@"latitude"]             = @(self.coordinate.latitude);
    params[@"longitude"]            = @(self.coordinate.longitude);
    
    //check for fetchedLocation, if exists, then submit for update
    if (self.fetchedLocation[@"id"]) {
        params[@"id"] = self.fetchedLocation[@"id"];
        self.fetchedLocation = nil;
    }
    
    IMInterceptionLocationUpdater *updater = [[IMInterceptionLocationUpdater alloc] init];
    updater.successHandler = ^{
                                self.fetchedLocation = nil;
                                [self.itemSave setEnabled:YES];
                                [self hideLoadingView];
                                
                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Saved" message:nil delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                                alert.tag = IMAlertContinueToPopNavigation_Tag;
                                [alert show];
                            };
    updater.conflictHandler = ^(NSDictionary *jsonData){
                                [self.itemSave setEnabled:YES];
                                [self hideLoadingView];
                                self.fetchedLocation = jsonData;
                                
                                NSString *message = [NSString stringWithFormat:@"Location with same coordinate exists. Do you want to update \n\"%@, %@, %@\" \ninformation with your input?", self.fetchedLocation[@"name"], self.fetchedLocation[@"locality"], self.fetchedLocation[@"administrativeArea"]];
                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Duplicate Location" message:message delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
                                alert.tag = IMAlertLocationExists_Tag;
                                [alert show];
                            };
    updater.failureHandler = ^(NSError *error){
                                NSLog(@"Error while submitting new location: %@", [error description] );
                                self.fetchedLocation = nil;
                                [self.itemSave setEnabled:YES];
                                [self hideLoadingView];
                                [self showAlertWithTitle:@"Error" message:@"Error occurred while saving new interception location. Please check your network connection and try again."];
                            };
    
    [updater submitInterceptionLocation:params];
}


#pragma mark UI Workflow
- (void)fetchCurrentLocation
{
    [self.activityIndicator startAnimating];
    [[IMLocationManager sharedManager] startUpdatingLocation];
}

- (void)locationChanges:(NSNotification *)notification
{
    [self.activityIndicator stopAnimating];
    self.coordinate = CLLocationCoordinate2DMake([notification.userInfo[@"latitude"] doubleValue], [notification.userInfo[@"longitude"] doubleValue]);
}

- (void)searchLocationWithGoogle
{
    if (!self.locationName || ![self.locationName length]) {
        [self showAlertWithTitle:@"Location Name Empty" message:@"You need to define location name before searching."];
        return;
    }
    
    [self.activityIndicator startAnimating];
    [self.buttonGoogle setEnabled:NO];
    IMGPlacesFetcher *fetcher = [[IMGPlacesFetcher alloc] initWithCompletionHandler:^(NSArray *places, BOOL hasNext){
        [self.buttonGoogle setEnabled:YES];
        [self.activityIndicator stopAnimating];
        self.foundPlace = [places lastObject];
        
        if (self.foundPlace) {
            NSString *message = [NSString stringWithFormat:@"Found location:\n%@", [self.foundPlace description]];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm Location" message:message delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
            alert.tag = IMAlertLocationConfirmation_Tag;
            [alert show];
        }else {
            [self showAlertWithTitle:@"Location Not Found" message:@"Try changing location name and search again."];
        }
    }];
    
    [fetcher searchPlacesWithKeyword:self.locationName];
}


#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == IMAlertLocationConfirmation_Tag) {
        if (buttonIndex != [alertView cancelButtonIndex]) {
            self.coordinate = self.foundPlace.coordinate;
            self.city = self.foundPlace.city;
            self.province = self.foundPlace.province;
            if ([self.foundPlace.name length]) self.locationName = self.foundPlace.name;
            
            self.foundPlace = nil;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }else if (alertView.tag == IMAlertLocationExists_Tag) {
        if (buttonIndex != [alertView cancelButtonIndex]) {
            [self save];
        }
    }else if (alertView.tag == IMAlertContinueToPopNavigation_Tag) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}


#pragma mark Setter
- (void)validateForSave
{
    self.itemSave.enabled = [self.locationName length] && [self.city length] && [self.province length];
}

- (void)setLocationName:(NSString *)locationName
{
    _locationName = locationName;
    
    self.buttonGoogle.enabled = [self.locationName length] > 3;
    [self validateForSave];
}

- (void)setCity:(NSString *)city
{
    _city = city;
    [self validateForSave];
}

- (void)setProvince:(NSString *)province
{
    _province = province;
    [self validateForSave];
}

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate
{
    _coordinate = coordinate;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self validateForSave];
}


#pragma mark View Lifecycle
- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    self.preferredContentSize = CGSizeMake(450, 500);
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Create";
    self.itemSave = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    self.navigationItem.rightBarButtonItem = self.itemSave;
    self.itemSave.enabled = NO;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.hidesWhenStopped = YES;
    [self.activityIndicator setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    self.buttonGoogle = [UIButton buttonWithTitle:@"Search Location with Google" titleColor:[UIColor IMRed] fontSize:14];
    self.buttonGoogle.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    [self.buttonGoogle setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
    [self.buttonGoogle setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.buttonGoogle addTarget:self action:@selector(searchLocationWithGoogle) forControlEvents:UIControlEventTouchUpInside];
    self.buttonGoogle.enabled = NO;
    
    [self.tableView setScrollEnabled:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationChanges:) name:IMLocationDidChangedNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self fetchCurrentLocation];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}


#pragma mark Table View
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section ? 3 : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath.section) {
        IMFormCell *cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:@"IMFormCellTypeTextInput"];
        cell.labelTitle.text = @"Location Name";
        cell.textValue.text = self.locationName;
        cell.textValue.placeholder = @"e.g Pelabuhan Ratu";
        cell.onTextValueReturn = ^(NSString *text){ self.locationName = text; };
        return cell;
    }else {
        NSString *identifier = indexPath.row < 2 ? @"IMFormCellTypeTextInput" : @"IMFormCellTypeDetail";
        IMFormCellType type = indexPath.row < 2 ? IMFormCellTypeTextInput : IMFormCellTypeDetail;
        
        IMFormCell *cell = (IMFormCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell) {
            cell = [[IMFormCell alloc] initWithFormType:type reuseIdentifier:identifier];
        }
        
        NSArray *characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet whitespaceCharacterSet], [NSCharacterSet characterSetWithCharactersInString:@",-"]];
        cell.characterSets = characterSets;
        cell.maxCharCount = 50;
        
        if (indexPath.row == 0) {
            cell.labelTitle.text = @"City or Locality";
            cell.textValue.text = self.city;
            cell.textValue.placeholder = @"e.g Banten";
            cell.onTextValueReturn = ^(NSString *text){ self.city = text; };
        }else if (indexPath.row == 1) {
            cell.labelTitle.text = @"Province or Administrative Area";
            cell.textValue.text = self.province;
            cell.textValue.placeholder = @"e.g West Java";
            cell.onTextValueReturn = ^(NSString *text){ self.province = text; };
        }else {
            cell.labelTitle.text = @"GPS Coordinate";
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.labelValue.text = [NSString stringWithFormat:@"%f, %f", self.coordinate.latitude, self.coordinate.longitude];
        }
        
        return cell;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (!section) return nil;
    
    return [[UIView alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section ? 30 : 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (section) return nil;
    
    UIView *view = [[UIView alloc] init];
    [view addSubview:self.activityIndicator];
    [view addSubview:self.buttonGoogle];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_buttonGoogle, _activityIndicator);
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[_activityIndicator(20)]-(>=20,==20@900)-[_buttonGoogle(<=300)]-|"
                                                                 options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.buttonGoogle attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.activityIndicator attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return section ? 0 : 50;
}

@end