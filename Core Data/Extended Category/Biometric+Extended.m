//
//  Biometric+Extended.m
//  IMDB Mobile
//
//  Created by Mario Yohanes on 12/11/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import "Biometric+Extended.h"
#import "IMConstants.h"
#import "Biometric.h"


//@interface Biometric () {
//    dispatch_queue_t imageQueue;
//    NSManagedObjectContext *context;
//}
//
//@property (nonatomic) NSInteger currentProgress;
//@property (nonatomic) NSInteger currentTotal;
//@property (nonatomic) BOOL hasNext;
//
//@end

@implementation Biometric (Extended)

NSString *const BIO_ENTITY_NAME             = @"Biometric";
NSString *const BIO_ID                      = @"id";
NSString *const BIO_PHOTOGRAPH              = @"photograph";

NSString *const BIO_LEFT_THUMB_IMAGE        = @"leftThumbImage";
NSString *const BIO_LEFT_THUMB_TEMPLATE     = @"leftThumbTemplate";
NSString *const BIO_RIGHT_THUMB_IMAGE       = @"rightThumbImage";
NSString *const BIO_RIGHT_THUMB_TEMPLATE    = @"rightThumbTemplate";

NSString *const BIO_LEFT_INDEX_IMAGE        = @"leftIndexImage";
NSString *const BIO_LEFT_INDEX_TEMPLATE     = @"leftIndexTemplate";
NSString *const BIO_RIGHT_INDEX_IMAGE       = @"rightIndexImage";
NSString *const BIO_RIGHT_INDEX_TEMPLATE    = @"rightIndexTemplate";


+ (Biometric *)biometricFromDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context{
    @try {
        if (dictionary == Nil) {
            return Nil;
        }else
        {
//            NSLog(@" dictionary : %@",dictionary);

            
        NSString *biometricId = [dictionary objectForKey:BIO_ID];
        Biometric *biometric = [Biometric biometricWithId:biometricId inContext:context];
        if (!biometric) {
            biometric = [NSEntityDescription insertNewObjectForEntityForName:BIO_ENTITY_NAME inManagedObjectContext:context];
            biometric.biometricId = biometricId;
        }
        
        [biometric updatePhotographFromBase64String:dictionary[BIO_PHOTOGRAPH]];
        
        //template
        [biometric updateTemplateFromBase64String:dictionary[BIO_RIGHT_THUMB_TEMPLATE] forFingerPosition:RightThumb];
        [biometric updateTemplateFromBase64String:dictionary[BIO_RIGHT_INDEX_TEMPLATE] forFingerPosition:RightIndex];
        [biometric updateTemplateFromBase64String:dictionary[BIO_LEFT_THUMB_TEMPLATE] forFingerPosition:LeftThumb];
        [biometric updateTemplateFromBase64String:dictionary[BIO_LEFT_INDEX_TEMPLATE] forFingerPosition:LeftIndex];
        
        //finger image
        [biometric updateFingerImageFromBase64String:dictionary[BIO_RIGHT_THUMB_IMAGE] forFingerPosition:RightThumb];
        [biometric updateFingerImageFromBase64String:dictionary[BIO_RIGHT_INDEX_IMAGE] forFingerPosition:RightIndex];
        [biometric updateFingerImageFromBase64String:dictionary[BIO_LEFT_THUMB_IMAGE] forFingerPosition:LeftThumb];
        [biometric updateFingerImageFromBase64String:dictionary[BIO_LEFT_INDEX_IMAGE] forFingerPosition:LeftIndex];
            
            
        }
    }
                           
    @catch (NSException *exception) {
        NSLog(@"Exception while creating Biometric: %@\n%@", dictionary, [exception description]);
        return nil;
    }
}

+ (Biometric *)biometricWithId:(NSString *)biometricId inContext:(NSManagedObjectContext *)context
{
    @try {
        if (!biometricId) {
            return nil;
        }
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:BIO_ENTITY_NAME];
        request.predicate = [NSPredicate predicateWithFormat:@"biometricId = %@", biometricId];
        NSError *error;
        NSArray *results = [context executeFetchRequest:request error:&error];
        return [results lastObject];
    }
    @catch (NSException *exception) {
        return nil;
    }
}

- (void)updateBiometricWithDictionary:(NSDictionary *)dictionary
{
    [self updatePhotographFromBase64String:dictionary[BIO_PHOTOGRAPH]];
    
    //template
    [self updateTemplateFromBase64String:dictionary[BIO_RIGHT_THUMB_TEMPLATE] forFingerPosition:RightThumb];
    [self updateTemplateFromBase64String:dictionary[BIO_RIGHT_INDEX_TEMPLATE] forFingerPosition:RightIndex];
    [self updateTemplateFromBase64String:dictionary[BIO_LEFT_THUMB_TEMPLATE] forFingerPosition:LeftThumb];
    [self updateTemplateFromBase64String:dictionary[BIO_LEFT_INDEX_TEMPLATE] forFingerPosition:LeftIndex];
    
    //finger image
    [self updateFingerImageFromBase64String:dictionary[BIO_RIGHT_THUMB_IMAGE] forFingerPosition:RightThumb];
    [self updateFingerImageFromBase64String:dictionary[BIO_RIGHT_INDEX_IMAGE] forFingerPosition:RightIndex];
    [self updateFingerImageFromBase64String:dictionary[BIO_LEFT_THUMB_IMAGE] forFingerPosition:LeftThumb];
    [self updateFingerImageFromBase64String:dictionary[BIO_LEFT_INDEX_IMAGE] forFingerPosition:LeftIndex];
}

@end