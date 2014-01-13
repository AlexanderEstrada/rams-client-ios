//
//  InterceptionData+Extended.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 5/14/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "InterceptionData.h"
#import "InterceptionLocation+Extended.h"
#import "InterceptionGroup+Extended.h"
#import "IomOffice+Extended.h"
#import "IomOfficer+Extended.h"
#import "ImmigrationOfficer+Extended.h"
#import "Country+Extended.h"
#import "Photo+Extended.h"
#import "PoliceOfficer+Extended.h"


@interface InterceptionData (Extended)

+ (InterceptionData *)dataWithDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context;
+ (InterceptionData *)dataWithId:(NSNumber *)dataId inManagedObjectContext:(NSManagedObjectContext *)context;
- (BOOL)isInterceptionGroupExists:(InterceptionGroup *)group;

@property (nonatomic, readonly) NSInteger currentPopulation;
@property (nonatomic, readonly) NSInteger currentAdult;
@property (nonatomic, readonly) NSInteger currentChildren;
@property (nonatomic, readonly) NSInteger currentMale;
@property (nonatomic, readonly) NSInteger currentFemale;
@property (nonatomic, readonly) NSInteger currentUAM;
@property (nonatomic, readonly) NSInteger currentMedicalAttention;

@property (nonatomic, readonly) NSInteger totalAdult;
@property (nonatomic, readonly) NSInteger totalChildren;
@property (nonatomic, readonly) NSInteger totalMale;
@property (nonatomic, readonly) NSInteger totalFemale;
@property (nonatomic, readonly) NSInteger totalUAM;
@property (nonatomic, readonly) NSInteger totalMedicalAttention;

- (NSInteger)totalTransferred;
- (NSInteger)totalEscaped;
- (NSInteger)totalDeported;

- (BOOL)validateForSubmission;
- (NSDictionary *)prepareForSubmissionWithPhotos:(NSArray *)photos;

@end