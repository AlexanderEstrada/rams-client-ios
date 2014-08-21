//
//  FamilyRegister+Extended.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 8/18/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "FamilyRegister+Extended.h"
#import "FamilyRegisterEntry+Extended.h"
#import "Biometric+Extended.h"

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
    @try {
        //check if the path has change
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.photographThumbnail] && self.photographThumbnail) {
            //get from old file
            NSString * Identifier = [self.photographThumbnail lastPathComponent];
            //case has change then update the path before show
            NSString *dir = [Biometric photograpThumbnailDir];
            self.photographThumbnail = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", Identifier]];
        }
        
        return self.photographThumbnail ? [UIImage imageWithContentsOfFile:self.photographThumbnail] : nil;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception on FamilyRegister - photographImageThumbnail : %@",[exception description]);
    }
    return Nil;
    
}

- (UIImage *)photographImage
{
    @try{
        //check if the path has change
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.photograph] && self.photograph) {
            //get from old file
            NSString * Identifier = [self.photograph lastPathComponent];
            //case has change then update the path before show
            NSString *dir = [Biometric photograpDir];
            self.photograph = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", Identifier]];
        }
        return self.photograph ? [UIImage imageWithContentsOfFile:self.photograph] : nil;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception on FamilyRegister - photographImage : %@",[exception description]);
    }
    return Nil;
}

@end
