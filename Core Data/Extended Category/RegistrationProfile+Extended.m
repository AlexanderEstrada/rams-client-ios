//
//  RegistrationProfile+Extended.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/5/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "RegistrationProfile+Extended.h"

@implementation RegistrationProfile (Extended)

- (Country *)nationality
{
    if (self.nationalityCountryCode) {
        return [Country countryWithCode:self.nationalityCountryCode inManagedObjectContext:self.managedObjectContext];
    }
    
    return nil;
}

- (Country *)countryOfBirth
{
    if (self.countryOfBirthCountryCode) {
        return [Country countryWithCode:self.countryOfBirthCountryCode inManagedObjectContext:self.managedObjectContext];
    }
    
    return nil;
}

- (Accommodation *)accommodation
{
    if (self.accommodationId) {
        return [Accommodation accommodationWithId:self.accommodationId inManagedObjectContext:self.managedObjectContext];
    }
    
    return nil;
}

- (IomOffice *)iomOffice
{
    if (self.iomOfficeName) {
        return [IomOffice officeWithName:self.iomOfficeName inManagedObjectContext:self.managedObjectContext];
    }
    
    return nil;
}

- (void)setNationality:(Country *)nationality
{
    self.nationalityCountryCode = nationality.code;
}

- (void)setCountryOfBirth:(Country *)countryOfBirth
{
    self.countryOfBirthCountryCode = countryOfBirth.code;
}

- (void)setAccommodation:(Accommodation *)accommodation
{
    self.accommodationId = accommodation.accommodationId;
}

- (void)setIomOffice:(IomOffice *)iomOffice
{
    self.iomOfficeName = iomOffice.name;
}

@end
