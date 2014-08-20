//
//  DataLoadingOperation.m
//  FluentResourcePaging-example
//
//  Created by Alek Astrom on 2014-04-11.
//  Copyright (c) 2014 Alek Åström. All rights reserved.
//

#import "DataLoadingOperation.h"
#import "IMConstants.h"


const NSTimeInterval DataLoadingOperationDuration = 0.3;

@implementation DataLoadingOperation

- (instancetype)initWithIndexes:(NSIndexSet *)indexes withEntity:(NSString *)entity sortDescriptorWithKey:(NSString *)sort basePredicate:(NSPredicate *) basePredicate
{
    
    self = [super init];
    
    if (self) {
        
        _indexes = indexes;
        
        typeof(self) weakSelf = self;
        [self addExecutionBlock:^{
            
            NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entity];
            
            
            if(sort) request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:sort ascending:YES]];
            request.returnsObjectsAsFaults = YES;
            request.fetchOffset = [indexes firstIndex];
            request.fetchLimit = Default_Page_Size;
            if (basePredicate) request.predicate = basePredicate;

            // Generate data
            NSError *error;
            weakSelf->_dataPage = [context executeFetchRequest:request error:&error];
            if (error) NSLog(@"Error Loading Data : %@",[error description]);
        }];
    }
    
    return self;
}
- (instancetype)initWithIndexes:(NSIndexSet *)indexes{

    self = [super init];
    
    if (self) {
    
        _indexes = indexes;
        
        typeof(self) weakSelf = self;
        [self addExecutionBlock:^{
            // Simulate fetching
            [NSThread sleepForTimeInterval:DataLoadingOperationDuration];
            
            NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Migrant"];

            
            request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO]];
            request.returnsObjectsAsFaults = YES;
                    request.fetchOffset = [indexes firstIndex];
                    request.fetchLimit = Default_Page_Size;
            
            
            // Generate data
            NSError *error;
           weakSelf->_dataPage = [context executeFetchRequest:request error:&error];
             if (error) NSLog(@"Error Loading Data : %@",[error description]);
        }];
    }
    
    return self;
}

@end
