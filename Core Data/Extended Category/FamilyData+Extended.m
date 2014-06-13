//
//  FamilyData+Extended.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 30/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "FamilyData+Extended.h"
#import "Child+Extended.h"

@implementation FamilyData (Extended)


+ (FamilyData *)familyWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context
{
    @try {
        
    FamilyData *family = [self familyWithFatherId:[dictionary objectForKey:@"father"] inContext:context];
        if (!family) {
            //create new family data
            family = [NSEntityDescription insertNewObjectForEntityForName:@"FamilyData" inManagedObjectContext:context];
        }
        family.father = [dictionary objectForKey:@"father"];
        family.mother = [dictionary objectForKey:@"mother"];
        family.spouse = [dictionary objectForKey:@"spouse"];
        
        //get childs
        if (dictionary [@"childs"]) {
            NSArray *childs = dictionary [@"childs"];
            for (NSDictionary *child in childs) {
                Child *data = [Child childWithId:[child objectForKey:@"registrationNumber"] inContext:context];
                if (!data) {
                    data = [NSEntityDescription insertNewObjectForEntityForName:@"Child" inManagedObjectContext:context];
                    data.registrationNumber = [child objectForKey:@"registrationNumber"];
                }
                //add child to family
                [family addChildsObject:data];
            }
        }
        
        return family;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while creating new Country: \n%@", [exception description]);
        return nil;
    }
    
    
}
+ (FamilyData *)familyWithFatherId:(NSString *)fatherId inContext:(NSManagedObjectContext *)context
{
    @try {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"FamilyData"];
        request.predicate = [NSPredicate predicateWithFormat:@"father = %@", fatherId];
        NSError *error;
        NSArray *results = [context executeFetchRequest:request error:&error];
        return [results lastObject];
    }
    @catch (NSException *exception) {
        NSLog(@"Throw exception for familyWithFatherId : %@",[exception description]);
        return nil;
    }
}


@end