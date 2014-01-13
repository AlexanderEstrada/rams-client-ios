//
//  IMMenuViewController.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/1/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMMenuViewController.h"
#import "UIImage+ImageEffects.h"
#import "IMAuthManager.h"
#import "IMConstants.h"


@interface IMMenuViewController ()

@property (nonatomic, strong) NSMutableArray *menu;

@end


@implementation IMMenuViewController

NSString *const MENU_ICON           = @"icon";
NSString *const MENU_TITLE          = @"title";
NSString *const MENU_VC_ID          = @"vc-id";

- (void)rebuildMenu
{
    self.menu = [NSMutableArray array];
    
    NSMutableArray *common = [NSMutableArray array];
    [common addObject:[self menuWithTitle:@"Interception Case" identifier:@"Interception"]];
    [common addObject:[self menuWithTitle:@"Accommodation" identifier:@"Accommodation"]];
    [self.menu addObject:common];
    
//    NSMutableArray *common = [NSMutableArray array];
//    [common addObject:[self menuWithTitle:@"Interception Case" identifier:@"Interception"]];
//    [common addObject:[self menuWithTitle:@"Accommodation" identifier:@"Accommodation"]];
//    [common addObject:[self menuWithTitle:@"Irregular Migrant Data" identifier:@"Migrant"]];
//    [common addObject:[self menuWithTitle:@"Statistic" identifier:@"Statistic"]];
//    [self.menu addObject:common];
//    
//    if ([IMAuthManager sharedManager].activeUser && ([IMAuthManager sharedManager].activeUser.roleOperation || [IMAuthManager sharedManager].activeUser.roleICC))
//    {
//        NSMutableArray *special = [NSMutableArray array];
//        [special addObject:[self menuWithTitle:@"Registration" identifier:@"Registration"]];
//        [special addObject:[self menuWithTitle:@"Allowance" identifier:@"Allowance"]];
//        [special addObject:[self menuWithTitle:@"Transfer Request" identifier:@"Transfer"]];
//        [special addObject:[self menuWithTitle:@"Update Movement" identifier:@"Movement"]];
//        [self.menu addObject:special];
//    }
//    
    [self.menu addObject:@[[self menuWithTitle:@"Settings" identifier:@"Settings"]]];
    [self.tableView reloadData];
    [self setCurrentIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (NSDictionary *)menuWithTitle:(NSString *)title identifier:(NSString *)identifier
{
    return @{MENU_TITLE:title, MENU_ICON:identifier, MENU_VC_ID:[NSString stringWithFormat:@"IM%@ViewController", identifier]};
}

#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rebuildMenu) name:IMUserChangedNotification object:nil];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage blurredBackgroundImage]];
    imageView.contentMode = UIViewContentModeTopLeft;
    self.tableView.backgroundView = imageView;
    
    _currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self rebuildMenu];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    IMTableViewCell *cell = (IMTableViewCell *)[self.tableView cellForRowAtIndexPath:self.currentIndexPath];
    if (!cell.selected) [cell setSelected:YES animated:YES];
}

- (void)setCurrentIndexPath:(NSIndexPath *)currentIndexPath
{
    if (self.currentIndexPath && [self.currentIndexPath isEqual:currentIndexPath]) return;
    [[self.tableView cellForRowAtIndexPath:self.currentIndexPath] setSelected:NO];
    _currentIndexPath = currentIndexPath;
    [[self.tableView cellForRowAtIndexPath:self.currentIndexPath] setSelected:YES];
}


#pragma mark Table View Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.menu count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.menu objectAtIndex:section] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section ? 35 : 64;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    IMTableViewCell *cell = (IMTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[IMTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.tintColor = [UIColor IMLightBlue];
        cell.textLabel.highlightedTextColor = [UIColor IMLightBlue];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSDictionary *menu = [self.menu[indexPath.section] objectAtIndex:indexPath.row];
    cell.textLabel.text = menu[MENU_TITLE];
    
    NSString *imageNamedAlt = [NSString stringWithFormat:@"%@-selected", menu[MENU_ICON]];
    UIImage *image = [[UIImage imageNamed:menu[MENU_ICON]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImage *imageAlt = [[UIImage imageNamed:imageNamedAlt] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [cell setImage:image highlightedImage:imageAlt];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentIndexPath = indexPath;
    NSDictionary *menu = [self.menu[indexPath.section] objectAtIndex:indexPath.row];
    [self.sideMenuDelegate changeContentViewTo:menu[MENU_VC_ID] fromSideMenu:YES];
}

@end