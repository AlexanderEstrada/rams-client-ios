//
//  IMFamilyListVCViewController.h
//  IMMS Manager
//
//  Created by IOM Jakarta on 7/31/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMCollectionViewController.h"
#import "DataReceiver.h"
#import "Migrant.h"

@protocol IMFamilyListVCDelegate;

@interface IMFamilyListVC : IMCollectionViewController <DataReceiver>

@property (weak, atomic) id<IMFamilyListVCDelegate> delegate;
@property (nonatomic, strong) NSPredicate *basePredicate;
@property (nonatomic) BOOL reloadingData;
@property (nonatomic, strong) NSOperationQueue *thumbnailQueue;
@property (nonatomic) int currentIndex;
@property (nonatomic) int maxSelection;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *save;
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancel;



- (void)reloadData;
- (id)initWithPredicate:(NSPredicate *)basepredicate;

@property (nonatomic, copy) void (^onSelect)(Migrant *migrant);
@property (nonatomic, copy) void (^onMultiSelect)(NSMutableArray *migrants);
@end


@protocol IMFamilyListVCDelegate <NSObject>

@end
