//
//  RegistrationProfile+Extended.h
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/5/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "RegistrationProfile.h"
#import "Country+Extended.h"
#import "IomOffice+Extended.h"
#import "Accommodation+Extended.h"


@interface RegistrationProfile (Extended)

- (Country *)nationality;
- (Country *)countryOfBirth;
- (Accommodation *)accommodation;
- (IomOffice *)iomOffice;

- (void)setNationality:(Country *)nationality;
- (void)setCountryOfBirth:(Country *)countryOfBirth;
- (void)setAccommodation:(Accommodation *)accommodation;
- (void)setIomOffice:(IomOffice *)iomOffice;

@end
