//
//  Migrant+Extended.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 30/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "Migrant.h"
#import "BioData.h"
#import "Biometric+Storage.h"
#import "IomData+Extended.h"
#import "Allowance+Extended.h"
#import "Accommodation+Extended.h"
#import "Country+Extended.h"
#import "Movement+Extended.h"
#import "FamilyData+Extended.h"
#import "Interception+Extended.h"
#import "IomOffice+Extended.h"


@interface Migrant (Extended)

+ (Migrant *)migrantWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context;
+ (Migrant *)migrantWithId:(NSString *)migrantId inContext:(NSManagedObjectContext *)context;
+ (Migrant *)newMigrantInContext:(NSManagedObjectContext *)context;
+ (Migrant *)newMigrantInContext:(NSManagedObjectContext *)context withId:(NSString*)Id;

@end