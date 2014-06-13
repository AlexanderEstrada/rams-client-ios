//
//  InterceptionGroup+Extended.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 5/14/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "InterceptionGroup.h"

@interface InterceptionGroup (Extended)

+ (InterceptionGroup *)groupWithDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context;
+ (InterceptionGroup *)groupWithId:(NSNumber *)groupId inManagedObjectContext:(NSManagedObjectContext *)context;
- (BOOL)isInterceptionMovementExists:(InterceptionMovement *)movement;

@property (nonatomic, readonly) int currentAdult;
@property (nonatomic, readonly) int currentChildren;
@property (nonatomic, readonly) int currentMale;
@property (nonatomic, readonly) int currentFemale;
@property (nonatomic, readonly) int currentUAM;
@property (nonatomic, readonly) int currentMedicalAttention;
@property (nonatomic, readonly) int currentPopulationByAgeGroup;
@property (nonatomic, readonly) int currentPopulationByGender;

- (NSString *)stringGroupPopulation;
- (BOOL)validateForSubmission;
- (NSDictionary *)prepareForSubmission;

@end
