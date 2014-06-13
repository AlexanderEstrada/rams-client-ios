//
//  IMEditAccommodationVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/9/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMEditAccommodationVC.h"
#import "Accommodation+Extended.h"
#import "Photo+Extended.h"
#import "IMDBManager.h"
#import "IMFormCell.h"
#import "IMLocationManager.h"
#import "IMPhotoBrowserCell.h"
#import "UIImage+ImageUtils.h"
#import "IMAccommodationUpdater.h"
#import "IMOptionChooserViewController.h"



@interface IMEditAccommodationVC ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, UIPopoverControllerDelegate,IMOptionChooserDelegate>

@property (nonatomic) BOOL editingMode;
@property (nonatomic, strong) NSMutableDictionary *data;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) UIBarButtonItem *itemSave;
@property (nonatomic, strong) UIPopoverController *popover;

@end


@implementation IMEditAccommodationVC

#pragma mark Logical Methods
- (void)validateForSave
{
    BOOL stat = self.data[ACC_NAME] && self.data[ACC_CITY];
    self.itemSave.enabled = stat;
}

- (void)save
{
    [self showLoadingViewWithTitle:@"Just a moment please ..."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *photos = [NSMutableArray array];
        
        for (NSDictionary *dict in self.photos) {
            if (dict[PHOTO_ID]) {
                [photos addObject:@{PHOTO_FILENAME:dict[PHOTO_ID]}];
            }else if (dict[PHOTO_IMAGE]) {
                UIImage *image = dict[PHOTO_IMAGE];
                NSData *imageData = UIImageJPEGRepresentation(image, 1);
                NSString *imageBase64 = [imageData base64EncodedStringWithOptions:0];
                [photos addObject:@{@"photo":imageBase64}];
            }
        }
        
        [self.data setObject:photos forKey:ACC_PHOTOS];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            IMAccommodationUpdater *updater = [[IMAccommodationUpdater alloc] init];
            updater.successHandler = ^{
                [self hideLoadingView];
                [[NSNotificationCenter defaultCenter] postNotificationName:IMDatabaseChangedNotification object:nil];
                [self dismissViewControllerAnimated:YES completion:nil];
            };
            updater.failureHandler = ^(NSError *error){
                [self hideLoadingView];
                [self showAlertWithTitle:@"Update Failed" message:@"Please check your network connection and try again. If problem persist, contact administrator."];
            };
            
            [updater sendUpdate:self.data];
        });
    });
}

- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addPhoto
{
    BOOL camera = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    BOOL library = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
    
    if (camera && library) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Photo Source" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Camera" otherButtonTitles:@"Photo Library", nil];
        
        CGRect rect = [self.tableView rectForHeaderInSection:3];
        rect = CGRectMake(self.tableView.bounds.size.width - 100, rect.origin.y, rect.size.width, rect.size.height);
        [actionSheet showFromRect:rect inView:self.tableView animated:YES];
    }else if (library) {
        [self showPhotoLibrary];
    }else {
        [self showAlertWithTitle:@"Photo Library Not Available"
                         message:@"RAMS requires access to your Photo Library. Go to Settings > Privacy > Photos and turn on access for RAMS Manager."];
    }
}

- (void)removePhotoAtIndex:(NSInteger)index
{
    [self.photos removeObjectAtIndex:index];
    [self updatePhotoBrowser];
}

- (void)updatePhotoBrowser
{
    IMPhotoBrowserCell *cell = (IMPhotoBrowserCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3]];
    cell.photos = self.photos;
}

- (void)fetchGPSCoordinate
{
    [[IMLocationManager sharedManager] startUpdatingLocation];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationDidChange:) name:IMLocationDidChangedNotification object:nil];
}

- (void)locationDidChange:(NSNotification *)notification
{
    self.data[ACC_LATITUDE] = notification.userInfo[IMLOCATION_LATITUDE];
    self.data[ACC_LONGITUDE] = notification.userInfo[IMLOCATION_LONGITUDE];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2], [NSIndexPath indexPathForRow:1 inSection:2]]
                          withRowAnimation:UITableViewRowAnimationNone];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark UIImagePickerController Management
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [actionSheet destructiveButtonIndex]) {
        [self showCamera];
    }else if (buttonIndex != [actionSheet cancelButtonIndex]) {
        [self showPhotoLibrary];
    }
}

- (void)showCamera
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = NO;
    
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)showPhotoLibrary
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.preferredContentSize = CGSizeMake(400, 500);
    
    CGRect rect = [self.tableView rectForHeaderInSection:3];
    rect = CGRectMake(self.tableView.bounds.size.width - 100, rect.origin.y, rect.size.width, rect.size.height);
    self.popover = [[UIPopoverController alloc] initWithContentViewController:imagePickerController];
    [self.popover presentPopoverFromRect:rect inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    dispatch_queue_t queue = dispatch_queue_create("ResizeImageQueue", NULL);
    dispatch_async(queue, ^{
        UIImage *photo;
        if (info[UIImagePickerControllerEditedImage]) {
            photo = info[UIImagePickerControllerEditedImage];
        }else if (info[UIImagePickerControllerOriginalImage]) {
            photo = info[UIImagePickerControllerOriginalImage];
        }
        
        if (photo) {
            photo = [photo scaledToWidth:2048];
            [self.photos addObject:@{PHOTO_IMAGE:photo}];
            dispatch_async(dispatch_get_main_queue(), ^{ [self updatePhotoBrowser]; });
        }
    });
    
    [self dismissImagePicker:picker];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissImagePicker:picker];
}

- (void)dismissImagePicker:(UIImagePickerController *)picker
{
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }else {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    navigationController.navigationBar.tintColor = [UIColor IMLightBlue];
}


#pragma mark View Lifecycle
- (id)initWithAccommodation:(Accommodation *)accommodation
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    self.itemSave = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)];
    
    if (accommodation) {
        self.data = [[accommodation format] mutableCopy];
        [self.data removeObjectForKey:ACC_PHOTOS];
        self.photos = [NSMutableArray array];
        
        for (Photo *photo in accommodation.photos) {
            [self.photos addObject:@{PHOTO_LOCAL_PATH:[photo photoPath], PHOTO_ID:photo.photoId}];
        }
        
        self.editingMode = YES;
        //        self.title = @"Edit Accommodation";
        self.title = @"Edit Location";
        self.itemSave.enabled = YES;
    }else {
        self.data = [NSMutableDictionary dictionary];
        self.data[ACC_TYPE] = @"Housing";
        self.data[ACC_SINGLE_CAPACITY] = @(0);
        self.data[ACC_FAMILY_CAPACITY] = @(0);
        self.data[ACC_ACTIVE] = @(YES);
        
        self.photos = [NSMutableArray array];
        self.editingMode = NO;
        //        self.title = @"New Accommodation";
        self.title = @"New Location";
        self.itemSave.enabled = NO;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.tintColor = [UIColor IMLightBlue];
    self.navigationController.navigationBar.tintColor = [UIColor IMLightBlue];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = self.itemSave;
    self.tableView.contentInset = UIEdgeInsetsMake(10, 0, 0, 0);
}


#pragma mark Table View Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 5;
    else if (section == 1 || section == 2) return 2;
    return 1;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    IMTableHeaderView *header;
    
    switch (section) {
        case 0:
            header = [[IMTableHeaderView alloc] initWithTitle:@"Location Info" reuseIdentifier:cellIdentifier];
            break;
        case 1:
            //            header = [[IMTableHeaderView alloc] initWithTitle:@"Accommodation Capacity" reuseIdentifier:cellIdentifier];
            header = [[IMTableHeaderView alloc] initWithTitle:@"Capacity" reuseIdentifier:cellIdentifier];
            break;
        case 2:
            header = [[IMTableHeaderView alloc] initWithTitle:@"GPS Coordinate"
                                                  actionTitle:@"Use Current Location"
                                                 alignCenterY:YES
                                              reuseIdentifier:cellIdentifier];
            header.buttonAction.tintColor = [UIColor IMLightBlue];
            [header.buttonAction addTarget:self action:@selector(fetchGPSCoordinate) forControlEvents:UIControlEventTouchUpInside];
            break;
        case 3:
            header = [[IMTableHeaderView alloc] initWithTitle:@"Photos"
                                                  actionTitle:@"Add Photo"
                                                 alignCenterY:YES
                                              reuseIdentifier:cellIdentifier];
            header.buttonAction.tintColor = [UIColor IMLightBlue];
            [header.buttonAction addTarget:self action:@selector(addPhoto) forControlEvents:UIControlEventTouchUpInside];
            break;
    }
    
    header.labelTitle.textColor = [UIColor IMLightBlue];
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section < 3 ? 44 : 100;
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

- (void)optionChooser:(IMOptionChooserViewController *)optionChooser didSelectOptionAtIndex:(NSUInteger)selectedIndex withValue:(id)value
{
    if (optionChooser.constantsKey == CONST_LOCATION) {
        self.data[ACC_TYPE] = value;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [self.popover dismissPopoverAnimated:YES];
    self.popover = nil;
}

- (void)showOptionChooserWithConstantsKey:(NSString *)constantsKey indexPath:(NSIndexPath *)indexPath useNavigation:(BOOL)useNavigation
{
    IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithConstantsKey:constantsKey delegate:self];
    vc.view.tintColor = [UIColor IMMagenta];
    [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:useNavigation];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == 3) {
            IMOptionChooserViewController *vc = [[IMOptionChooserViewController alloc] initWithConstantsKey:CONST_LOCATION delegate:self];
            vc.selectedValue = self.data[ACC_TYPE];
            [self showPopoverFromRect:[self.tableView rectForRowAtIndexPath:indexPath] withViewController:vc navigationController:NO];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    IMFormCell *cell;
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
            //            cell.labelTitle.text = @"Accommodation Name";
            cell.labelTitle.text = @"Name";
            cell.textValue.placeholder = @"e.g Hotel Sentabi";
            cell.textValue.text = self.data[ACC_NAME];
            cell.characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet whitespaceCharacterSet]];
            cell.onTextValueReturn = ^(NSString *value){
                if (value && [value length]) {
                    self.data[ACC_NAME] = value;
                }else {
                    [self.data removeObjectForKey:ACC_NAME];
                }
                [self validateForSave];
            };
        }else if (indexPath.row == 1) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Address";
            cell.textValue.placeholder = @"e.g Jl. Jend. Sudirman Kav. 45-46";
            cell.textValue.text = self.data[ACC_ADDRESS];
            cell.characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet whitespaceCharacterSet], [NSCharacterSet characterSetWithCharactersInString:@".-_#()[]/|"]];
            cell.onTextValueReturn = ^(NSString *value){
                if (value && [value length]) {
                    self.data[ACC_ADDRESS] = value;
                }else {
                    [self.data removeObjectForKey:ACC_ADDRESS];
                }
                [self validateForSave];
            };
        }else if (indexPath.row == 2) {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"City";
            cell.textValue.placeholder = @"e.g Jakarta";
            cell.textValue.text = self.data[ACC_CITY];
            cell.characterSets = @[[NSCharacterSet alphanumericCharacterSet], [NSCharacterSet whitespaceCharacterSet]];
            cell.onTextValueReturn = ^(NSString *value){
                if (value && [value length]) {
                    self.data[ACC_CITY] = value;
                }else {
                    [self.data removeObjectForKey:ACC_CITY];
                }
                [self validateForSave];
            };
        }else if (indexPath.row == 3){
            //add location type
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeDetail reuseIdentifier:cellIdentifier];
            cell.labelTitle.text = @"Type";
            cell.labelValue.text = self.data[ACC_TYPE];
            
        }else {
            cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeSwitch reuseIdentifier:cellIdentifier];
            //            cell.labelTitle.text = @"Active Accommodation";
            cell.labelTitle.text = @"Active";
            cell.switcher.onTintColor = [UIColor IMLightBlue];
            cell.switcher.on = [self.data[ACC_ACTIVE] boolValue];
            cell.onSwitcherValueChanged = ^(BOOL value){ self.data[ACC_ACTIVE] = @(value); };
        }
    }else if (indexPath.section == 1) {
        cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeStepper reuseIdentifier:cellIdentifier];
        cell.labelTitle.text = indexPath.row == 0 ? @"Single Room" : @"Family Room";
        cell.stepper.value = indexPath.row == 0 ? [self.data[ACC_SINGLE_CAPACITY] integerValue] : [self.data[ACC_FAMILY_CAPACITY] integerValue];
        cell.onStepperValueChanged = ^(int value){
            self.data[indexPath.row == 0 ? ACC_SINGLE_CAPACITY : ACC_FAMILY_CAPACITY] = @(value);
        };
    }else if (indexPath.section == 2) {
        cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTextInput reuseIdentifier:cellIdentifier];
        cell.labelTitle.text = indexPath.row == 0 ? @"Latitude" : @"Longitude";
        double coordinateValue = indexPath.row == 0 ? [self.data[ACC_LATITUDE] doubleValue] : [self.data[ACC_LONGITUDE] doubleValue];
        cell.textValue.text = [NSString stringWithFormat:@"%f", coordinateValue];
        cell.textValue.placeholder = indexPath.row == 0 ? @"-6.11150000" : @"116.10510000";
        cell.characterSets = @[[NSCharacterSet decimalDigitCharacterSet]];
        cell.onTextValueReturn = ^(NSString *value){
            double doubleValue = [value doubleValue];
            if (doubleValue != 0.0) {
                self.data[indexPath.row == 0 ? ACC_LATITUDE : ACC_LONGITUDE] = @(doubleValue);
            }else {
                [self.data removeObjectForKey:(indexPath.row == 0 ? ACC_LATITUDE : ACC_LONGITUDE)];
            }
        };
    }else {
        IMPhotoBrowserCell *photoBrowser = [[IMPhotoBrowserCell alloc] initWithPhotos:self.photos];
        photoBrowser.onPhotoDeleted = ^(NSInteger deletedPhotoIndex){ [self removePhotoAtIndex:deletedPhotoIndex]; };
        return photoBrowser;
    }
    
    return cell;
}


@end