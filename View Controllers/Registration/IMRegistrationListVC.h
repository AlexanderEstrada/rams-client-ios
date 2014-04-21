//
//  IMRegistrationListVC.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 30/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMCollectionViewController.h"


@interface IMRegistrationListVC : IMCollectionViewController

@property (nonatomic, strong) NSPredicate *basePredicate;
@property (nonatomic, strong) NSMutableArray *data_to_view;
@property (nonatomic, strong) NSArray *data;
@property (nonatomic) int current_index;
@property (nonatomic) BOOL reloadingData;
@property (nonatomic) BOOL noMoreResultsAvail;
@property (nonatomic) BOOL loading;
@property (nonatomic, strong) NSOperationQueue *thumbnailQueue;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;


@end


