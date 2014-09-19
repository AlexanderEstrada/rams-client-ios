//
//  IMCityChooserVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/8/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMAccommodationFilterVC.h"
#import "IMDBManager.h"
#import "Accommodation+Extended.h"




@interface IMAccommodationFilterVC ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *indexes;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) NSDictionary *data;
@property (nonatomic, strong) NSPredicate *activePredicate;
@property (nonatomic, strong) NSPredicate *cityPredicate;

@property (nonatomic) filter_type type;
@end


@implementation IMAccommodationFilterVC

@synthesize city;
@synthesize active;
@synthesize type;

#pragma mark Data Management
- (void)loadCities
{
    NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Migrant"];
    request.propertiesToFetch = @[@"detentionLocation"];
    request.returnsDistinctResults = YES;
    [request setResultType:NSDictionaryResultType];
    request.returnsObjectsAsFaults = YES;
    
    NSError *error;
    NSArray *results = [context executeFetchRequest:request error:&error];
    NSArray *locationID = [results valueForKeyPath:@"@distinctUnionOfObjects.detentionLocation"];
    //remove redundent data
    NSArray * cleanedArray = [[NSSet setWithArray:locationID] allObjects];
    
    NSMutableArray *indexes = [NSMutableArray array];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    //add indext A for all city
    [data setObject:@[@"All Cities"] forKey:@"A"];
    [indexes addObject:@"A"];
    
    for (NSString * place in cleanedArray) {
        Accommodation *location = [Accommodation accommodationWithId:place inManagedObjectContext:context];
        if (location) {
            //get all migrants position and add only place that occupide by migrant
            
            NSString *cityLocal = location.city;
            NSString *indexTitle = [[cityLocal substringToIndex:1] uppercaseString];
            
            //add index (first char)
            if (![indexes containsObject:indexTitle]) [indexes addObject:indexTitle];
            
            //add the city to data
            NSMutableArray *sectionData = [[data objectForKey:indexTitle] mutableCopy];
            if (!sectionData) sectionData = [NSMutableArray array];
            
            if(![sectionData containsObject:cityLocal])[sectionData addObject:cityLocal];
            if(![data objectForKey:sectionData]) [data setObject:sectionData forKey:indexTitle];
        }
        
        
    }
    
    self.data = data;
    self.indexes = indexes;
    [self.tableView reloadData];
    //reset all
    context = Nil;
    request = Nil;
    results = Nil;
    locationID = Nil;
    cleanedArray = Nil;
    error = Nil;
    
}

- (void)loadCitiesPredicate
{
    NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Accommodation"];
    request.propertiesToFetch = @[@"city"];
    request.returnsDistinctResults = YES;
    [request setResultType:NSDictionaryResultType];
    
    NSError *error;
    NSArray *results = [context executeFetchRequest:request error:&error];
    NSMutableArray *cities = [[results valueForKeyPath:@"@distinctUnionOfObjects.city"] mutableCopy];
    [cities sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    NSMutableArray *indexes = [NSMutableArray array];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setObject:@[@"All Cities"] forKey:@"A"];
    
    for (int i=0; i<[cities count]; i++) {
        NSString *cityLocal = cities[i];
        NSString *indexTitle = [[cityLocal substringToIndex:1] uppercaseString];
        
        //add index (first char)
        if (![indexes containsObject:indexTitle]) [indexes addObject:indexTitle];
        
        //add the city to data
        NSMutableArray *sectionData = [[data objectForKey:indexTitle] mutableCopy];
        if (!sectionData) sectionData = [NSMutableArray array];
        
        [sectionData addObject:cityLocal];
        [data setObject:sectionData forKey:indexTitle];
    }
    
    self.data = data;
    self.indexes = indexes;
    [self.tableView reloadData];
    //reset all
    context = Nil;
    request = Nil;
    error = Nil;
    results = Nil;
    cities = Nil;
}

- (void)switchActive:(UISwitch *)sender
{
    if (sender.on) {
        self.activePredicate = [NSPredicate predicateWithFormat:@"active = NO"];
        self.active = NO;
    }else {
        self.activePredicate = [NSPredicate predicateWithFormat:@"active = YES"];
        self.active = YES;
    }
    
    
    [self sendPredicateChanges];
}

- (void)switchOccupied:(UISwitch *)sender
{
    if (sender.on) {
        self.type = type_value;
        [self loadCities];
    }else {
        self.type = type_predicate;
        [self loadCitiesPredicate];
    }
    
    if (self.onUpdateView) {
        self.onUpdateView(self.type);
    }
}

- (void)sendPredicateChanges
{
    
    NSPredicate *tmp = Nil;
    
    if (self.activePredicate) {
        if (!tmp) {
            tmp =self.activePredicate;
        }else {
            tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self.activePredicate]];
        }
    }
    if (self.cityPredicate) {
        if (!tmp) {
            tmp =self.cityPredicate;
        }else {
            tmp =[NSCompoundPredicate andPredicateWithSubpredicates:@[tmp,self.cityPredicate]];
        }
    }
    //send to caller
    if (self.onSelected) {
        self.onSelected(tmp);
        return;
    }else if (self.onSelectedValue) {
        self.onSelectedValue(self.active,self.city,tmp);
        return;
    }else return;
}


#pragma mark View Lifecycle
- (id)initWithAction:(void (^)(NSPredicate *basePredicate))onSelected
{
    self = [super init];
    self.type = type_predicate;
    self.onSelected = onSelected;
    self.activePredicate = [NSPredicate predicateWithFormat:@"active = YES"];
    self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self setupUI];
    
    return self;
}

- (id)initWithValues:(void (^)(BOOL initActive,NSString * initCity,NSPredicate *basePredicate))onSelectedValue
{
    self = [super init];
    self.type = type_value;
    self.onSelectedValue = onSelectedValue;
    self.activePredicate = [NSPredicate predicateWithFormat:@"active = YES"];
    self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self setupUI];
    
    return self;
    
}
- (void)setupUI
{
    UIView *headerView = [[UIView alloc] init];
    headerView.translatesAutoresizingMaskIntoConstraints = NO;
    headerView.backgroundColor = [UIColor whiteColor];
    
    UIView *headerView_2 = [[UIView alloc] init];
    headerView_2.translatesAutoresizingMaskIntoConstraints = NO;
    headerView_2.backgroundColor = [UIColor whiteColor];
    
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont boldFontWithSize:16];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentLeft;
    label.text = NSLocalizedString(@"Inactive Accommodation",Nil);
    label.textColor = [UIColor IMLightBlue];
    [headerView addSubview:label];
    
    UISwitch *switcher = [[UISwitch alloc] init];
    switcher.translatesAutoresizingMaskIntoConstraints = NO;
    switcher.onTintColor = [UIColor IMLightBlue];
    [switcher addTarget:self action:@selector(switchActive:) forControlEvents:UIControlEventValueChanged];
    [headerView addSubview:switcher];
    
    //add label for All Location on occupied only
    UILabel *label2 = [[UILabel alloc] init];
    label2.translatesAutoresizingMaskIntoConstraints = NO;
    label2.font = [UIFont boldFontWithSize:16];
    label2.backgroundColor = [UIColor clearColor];
    label2.textAlignment = NSTextAlignmentLeft;
    label2.text = NSLocalizedString(@"Occupied",Nil);
    label2.textColor = [UIColor IMLightBlue];
    [headerView_2 addSubview:label2];
    
    UISwitch *occupide = [[UISwitch alloc] init];
    occupide.translatesAutoresizingMaskIntoConstraints = NO;
    occupide.onTintColor = [UIColor IMLightBlue];
    [occupide addTarget:self action:@selector(switchOccupied:) forControlEvents:UIControlEventValueChanged];
    occupide.on = TRUE;
    [headerView_2 addSubview:occupide];
    
    [self.view addSubview:headerView];
    [self.view addSubview:headerView_2];
    
    //layout header
    NSDictionary *headerViews = NSDictionaryOfVariableBindings(label, switcher);
    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(10)-[label]-(20,==20@900)-[switcher]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:headerViews]];
    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[label]-|" options:0 metrics:nil views:headerViews]];
    
    NSDictionary *headerView2 = NSDictionaryOfVariableBindings(label2, occupide);
    [headerView_2 addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(10)-[label2]-(20,==20@900)-[occupide]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:headerView2]];
    [headerView_2 addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[label2]-|" options:0 metrics:nil views:headerView2]];
    
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(headerView,headerView_2, _tableView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[headerView]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[headerView_2]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_tableView]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[headerView(>=40)][headerView_2(>=40)][_tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:headerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.tableView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:headerView_2 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.tableView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
}

- (void)loadView
{
    self.view = [[UIView alloc] init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"View Options",Nil);
    self.tableView.separatorColor = [UIColor IMBorderColor];
    [self loadCities];
}


#pragma mark Table View Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.indexes count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *sectionTitle = self.indexes[section];
    return [[self.data objectForKey:sectionTitle] count];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.indexes;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [self.indexes indexOfObject:title];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.textLabel.font = [UIFont regularFontWithSize:16];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSString *sectionTitle = self.indexes[indexPath.section];
    NSArray *sectionData = self.data[sectionTitle];
    cell.textLabel.text = sectionData[indexPath.row];
    cell.accessoryType = [self.selectedIndexPath isEqual:indexPath] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.selectedIndexPath && ![self.selectedIndexPath isEqual:indexPath]) {
        [[tableView cellForRowAtIndexPath:self.selectedIndexPath] setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    self.selectedIndexPath = indexPath;
    [[tableView cellForRowAtIndexPath:self.selectedIndexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
    
    NSString *sectionTitle = self.indexes[indexPath.section];
    NSArray *sectionData = self.data[sectionTitle];
    NSString *cityLocal = sectionData[indexPath.row];
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        self.cityPredicate = nil;
        self.city = Nil;
    }else {
        self.cityPredicate = [NSPredicate predicateWithFormat:@"city = %@", cityLocal];
        self.city = cityLocal;
    }
    
    [self sendPredicateChanges];
}

@end
