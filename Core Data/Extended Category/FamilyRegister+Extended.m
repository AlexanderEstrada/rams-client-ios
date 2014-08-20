//
//  FamilyRegister+Extended.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 8/18/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "FamilyRegister+Extended.h"
#import "FamilyRegisterEntry+Extended.h"

@implementation FamilyRegister (Extended)

+ (FamilyRegister *)familyRegisterWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context
{
    @try {
        NSString *Id = [dictionary objectForKey:@"id"];
        
        FamilyRegister * data = [FamilyRegister familyRegisterWithId:Id inContext:context];
        if (!data) {
            data = [FamilyRegister newFamilyRegisterInContext:context];
            data.familyID = Id;
        }
        
        NSArray * familyEntrys = [dictionary objectForKey:@"registerEntry"];
        //get family entry
        for (NSDictionary * familyEntry in familyEntrys) {
            FamilyRegisterEntry * entry = [FamilyRegisterEntry familyRegisterEntryWithDictionary:familyEntry inContext:context];
            if (entry) {
                [data addFamilyEntryIDObject:entry];
            }
        }
        
        return data;
    }
    @catch (NSException *exception) {
        NSLog(@"exeption in familyRegisterWithDictionary : %@",[exception description]);
    }
    return Nil;
    
}

+ (FamilyRegister *)familyRegisterWithId:(NSString *)familyId inContext:(NSManagedObjectContext *)context
{
    @try {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"FamilyRegister"];
        request.predicate = [NSPredicate predicateWithFormat:@"familyID = %@", familyId];
        NSError *error;
        NSArray *results = [context executeFetchRequest:request error:&error];
        return [results lastObject];
    }
    @catch (NSException *exception) {
        return nil;
    }
    
}

+ (FamilyRegister *)newFamilyRegisterInContext:(NSManagedObjectContext *)context{
    
    @try {
        FamilyRegister *data = [NSEntityDescription insertNewObjectForEntityForName:@"FamilyRegister" inManagedObjectContext:context];
        
        return data;
    }
    @catch (NSException *exception) {
        NSLog(@"Error : %@",[exception description]);
        return Nil;
    }

}

- (NSDictionary *)format{
    @try {
        NSMutableDictionary *formatted = [NSMutableDictionary dictionary];
        
        //id
        [formatted setObject:self.familyEntryID forKey:@"id"];
        
        return formatted;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception while creating formatted Movement data: %@", [exception description]);
    }
    return Nil;

}

- (UIImage *)photographImageThumbnail
{
    return self.photographThumbnail ? [UIImage imageWithContentsOfFile:self.photographThumbnail] : nil;
}

- (UIImage *)photographImage
{
    return self.photograph ? [UIImage imageWithContentsOfFile:self.photograph] : nil;
}

@end
