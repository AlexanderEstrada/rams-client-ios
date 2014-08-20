//
//  FamilyRegisterEntry+Extended.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 8/18/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "FamilyRegisterEntry+Extended.h"

@implementation FamilyRegisterEntry (Extended)

+ (FamilyRegisterEntry *)familyRegisterEntryWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context
{
     NSString *Id = [dictionary objectForKey:@"id"];
    
    FamilyRegisterEntry * data = [FamilyRegisterEntry familyRegisterEntryWithId:Id inContext:context];
    if (!data) {
        data = [FamilyRegisterEntry newFamilyRegisterEntryInContext:context];
        data.registerEntryId = Id;
    }
    //migrantID
    data.migrantId = [dictionary objectForKey:@"migrant"];
    
    //type
     data.type = [dictionary objectForKey:@"type"];
    
    return data;
}


+ (FamilyRegisterEntry *)familyRegisterEntryWithId:(NSString *)familyEntryId inContext:(NSManagedObjectContext *)context
{
    @try {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"FamilyRegisterEntry"];
        request.predicate = [NSPredicate predicateWithFormat:@"registerEntryId = %@", familyEntryId];
        NSError *error;
        NSArray *results = [context executeFetchRequest:request error:&error];
        return [results lastObject];
    }
    @catch (NSException *exception) {
        return nil;
    }
}
+ (FamilyRegisterEntry *)newFamilyRegisterEntryInContext:(NSManagedObjectContext *)context{
    @try {
        FamilyRegisterEntry *data = [NSEntityDescription insertNewObjectForEntityForName:@"FamilyRegisterEntry" inManagedObjectContext:context];
        
        return data;
    }
    @catch (NSException *exception) {
        NSLog(@"Error : %@",[exception description]);
        return Nil;
    }
    
}

- (NSDictionary *)format
{
    
    @try {
        NSMutableDictionary *formatted = [NSMutableDictionary dictionary];
        
        //id
        if (self.registerEntryId) {
             [formatted setObject:self.registerEntryId forKey:@"id"];
        }
        
        //type
        [formatted setObject:self.type forKey:@"type"];
        
        //migrant
                [formatted setObject:self.migrantId forKey:@"id"];
        
    return formatted;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while creating formatted Movement data: %@", [exception description]);
    }
    return Nil;
}
@end
