//
//  IMRegistrationUploadVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 30/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMRegistrationUploadVC.h"
#import "IMHTTPClient.h"
#import "IMDBManager.h"
#import "Registration.h"
#import "Migrant+Extended.h"
#import "Registration+Export.h"

@interface IMRegistrationUploadVC ()

@end

@implementation IMRegistrationUploadVC

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
    
    //get all migrant and save to registration
    @try {
        [self showLoadingViewWithTitle:@"Just a moment please"];
        NSArray *migrants = [[NSArray alloc]init];
        //    self.reloadingData = YES;
        NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Migrant"];
        //    request.predicate = self.basePredicate;
//        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"registrationNumber" ascending:NO]];
        request.returnsObjectsAsFaults = YES;
        
        NSError *error;
        migrants = [context executeFetchRequest:request error:&error];
        
        NSUInteger counter = [migrants count];
        
        
        for (NSDictionary *migrant in migrants) {
            Migrant * data = [Migrant migrantWithDictionary:migrant inContext:context];
            //save to Registration
            if (data) {
                Registration * reg = [Registration registrationFromMigrant:data inManagedObjectContext:context];
                //save to array
                NSError *error;
                if (![context save:&error] && !reg) {
                                    NSLog(@"Failed saving context Error : %@\n after parsing migrant - JSON : \n %@",[error description], migrant);
                }
                
            }
            counter--;
            NSLog(@"Remaining %lu from %lu\n",(unsigned long)counter,(unsigned long)[migrants count]);
        }
    [self hideLoadingView];    
    }
    @catch (NSException *exception) {
        NSLog(@"Fail to copy Migrant Data to Registration with error : %@",[exception description]);
        [self hideLoadingView];
    }
    
    [self hideLoadingView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
