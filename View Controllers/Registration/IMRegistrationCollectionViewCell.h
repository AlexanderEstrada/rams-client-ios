//
//  IMRegistrationCollectionViewCell.h
//  IMMS Manager
//
//  Created by Mario Yohanes on 30/10/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IMRegistrationCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelSubtitle;
@property (weak, nonatomic) IBOutlet UILabel *labelDetail1;
@property (weak, nonatomic) IBOutlet UILabel *labelDetail2;
@property (weak, nonatomic) IBOutlet UILabel *labelDetail3;
@property (weak, nonatomic) IBOutlet UILabel *labelDetail4;
@property (weak, nonatomic) IBOutlet UILabel *labelDetail5;
@property (weak, nonatomic) IBOutlet UIImageView *photoView;
@property (weak, nonatomic) IBOutlet UIButton *buttonUpload;


@end