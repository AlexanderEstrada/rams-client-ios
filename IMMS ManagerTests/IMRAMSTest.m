//
//  IMRAMSTest.m
//  RAMS Client
//
//  Created by IOM Jakarta on 9/15/14.
//  Copyright (c) 2014 International Organization for Migration. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Registration+Export.h"
#import "Migrant+Extended.h"

@interface IMRAMSTest : XCTestCase
@property (nonatomic, strong) Registration *registration;
@property (nonatomic, strong) Migrant *migrant;
@end

@implementation IMRAMSTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.registration.bioData.firstName =@"Testing";
    
    
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    self.registration = Nil;
    self.migrant = nil;
}

- (void)testExample
{
//    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
