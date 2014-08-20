//
//  IMFamilyViewController.h
//  IMMS Manager
//
//  Created by IOM Jakarta on 7/31/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMTableViewController.h"
#import "Migrant+Extended.h"
#import "IMFamilyListVC.h"


@interface IMFamilyViewController : IMTableViewController <IMFamilyListVCDelegate>

@property (nonatomic, assign) id<IMSideMenuDelegate> sideMenuDelegate;
@property (nonatomic, strong) Migrant *migrant;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *save;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;

@property (weak, nonatomic) IBOutlet UITableViewCell *cellFamily;

@end
