//
//  IomData+Extended.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 12/11/12.
//  Copyright (c) 2012 International Organization for Migration. All rights reserved.
//

#import "IomData.h"
#import "Allowance+Extended.h"
#import "IomOffice+Extended.h"

@interface IomData (Extended)

+ (IomData *)iomDataFromDictionary:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)context;
+ (IomData *)iomDataWithId:(NSString *)iomDataId inManagedObjectContext:(NSManagedObjectContext *)context;
+ (BOOL)validateIomDataDictionary:(NSDictionary *)dictionary;
+ (BOOL)isAllowanceExists:(Allowance *)allowance inList:(NSSet *)list;

- (Allowance *)latestAllowance;
- (Allowance *)thisMonthAllowance;

@end
