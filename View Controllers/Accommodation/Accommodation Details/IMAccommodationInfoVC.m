//
//  IMAccommodationDetailVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/8/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMAccommodationInfoVC.h"
#import "Accommodation+Extended.h"

@interface IMAccommodationInfoVC ()

@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UILabel *labelAddress;
@property (weak, nonatomic) IBOutlet UILabel *labelTypeValue;
@property (weak, nonatomic) IBOutlet UILabel *labelOccupancyValue;
@property (weak, nonatomic) IBOutlet UILabel *labelCapacityValue;
@property (weak, nonatomic) IBOutlet UILabel *labelType;
@property (weak, nonatomic) IBOutlet UILabel *labelOccupancy;
@property (weak, nonatomic) IBOutlet UILabel *labelCapacity;

@end


@implementation IMAccommodationInfoVC

- (void)setAccommodation:(Accommodation *)accommodation
{
    self.labelName.text = accommodation.name;
    
    if ([accommodation.address length] && accommodation.city) {
        self.labelAddress.text = [NSString stringWithFormat:@"%@. %@", accommodation.address, accommodation.city];
    }else {
        self.labelAddress.text = accommodation.city;
    }
    
    self.labelTypeValue.text = accommodation.type;
    
    if (accommodation.singleCapacity.intValue > 0 || accommodation.familyCapacity.intValue > 0) {
        self.labelCapacity.text = [NSString stringWithFormat:@"%i Single, %i Family", accommodation.singleCapacity.intValue, accommodation.familyCapacity.intValue];
    }else {
        self.labelCapacityValue.text = @"Undefined Capacity";
    }
    
    self.labelOccupancyValue.text = [NSString stringWithFormat:@"%i Single, %i Family", accommodation.singleOccupancy.intValue, accommodation.familyOccupancy.intValue];
}


#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.labelName.textColor = [UIColor IMLightBlue];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view insertSubview:toolbar atIndex:0];
}

@end
