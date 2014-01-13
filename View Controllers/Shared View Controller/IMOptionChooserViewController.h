//
//  IMCityChooserViewController.h
//  IMDB Mobile
//
//  Created by Mario Yohanes on 5/2/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMTableViewController.h"

@class IMOptionChooserViewController;
@protocol IMOptionChooserDelegate <NSObject>
- (void)optionChooser:(IMOptionChooserViewController *)optionChooser didSelectOptionAtIndex:(NSUInteger)selectedIndex withValue:(id)value;
@end


@interface IMOptionChooserViewController : IMTableViewController

@property (nonatomic, assign) id<IMOptionChooserDelegate> delegate;
@property (nonatomic, strong) NSArray *options;
@property (nonatomic, copy) void (^onOptionSelected)(id selectedValue);
@property (nonatomic, strong) NSString *constantsKey;
@property (nonatomic) BOOL firstRowIsSpecial;
@property (nonatomic, strong) id selectedValue;

+ (UINavigationController *)navigatedChooserWithOptions:(NSArray *)options delegate:(id<IMOptionChooserDelegate>)delegate;
- (id)initWithOptions:(NSArray *)options delegate:(id<IMOptionChooserDelegate>)delegate;
- (id)initWithOptions:(NSArray *)options onOptionSelected:(void (^)(id selectedValue))onOptionSelected;
- (id)initWithConstantsKey:(NSString *)constantsKey delegate:(id<IMOptionChooserDelegate>)delegate;

@end