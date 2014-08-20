//
//  IMFamilyDataViewController.h
//  IMMS Manager
//
//  Created by IOM Jakarta on 8/18/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMTableViewController.h"
#import "Migrant+Extended.h"
#import "IMFamilyListVC.h"
#import "FamilyRegister+Extended.h"

@interface IMFamilyDataViewController : IMTableViewController <IMFamilyListVCDelegate>

@property (nonatomic, assign) id<IMSideMenuDelegate> sideMenuDelegate;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *save;
@property (nonatomic,strong) FamilyRegister *familyRegister;

@end
