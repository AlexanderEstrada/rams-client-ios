//
//  IMCityChooserVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 10/8/13.
//  Copyright (c) 2013 Mario Yohanes. All rights reserved.
//

#import "IMAccommodationFilterVC.h"
#import "IMDBManager.h"


@interface IMAccommodationFilterVC ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *indexes;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) NSDictionary *data;
@property (nonatomic, strong) NSPredicate *activePredicate;
@property (nonatomic, strong) NSPredicate *cityPredicate;

@end


@implementation IMAccommodationFilterVC


#pragma mark Data Management
- (void)loadCities
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
        NSString *city = cities[i];
        NSString *indexTitle = [[city substringToIndex:1] uppercaseString];
        
        //add index (first char)
        if (![indexes containsObject:indexTitle]) [indexes addObject:indexTitle];
        
        //add the city to data
        NSMutableArray *sectionData = [[data objectForKey:indexTitle] mutableCopy];
        if (!sectionData) sectionData = [NSMutableArray array];
        
        [sectionData addObject:city];
        [data setObject:sectionData forKey:indexTitle];
    }
    
    self.data = data;
    self.indexes = indexes;
    [self.tableView reloadData];
}

- (void)switchActive:(UISwitch *)sender
{
    if (sender.on) {
        self.activePredicate = nil;
    }else {
        self.activePredicate = [NSPredicate predicateWithFormat:@"active = YES"];
    }
    
    [self sendPredicateChanges];
}

- (void)sendPredicateChanges
{
    if (!self.onSelected) return;
    
    if (self.activePredicate && self.cityPredicate) {
        self.onSelected([NSCompoundPredicate andPredicateWithSubpredicates:@[self.activePredicate, self.cityPredicate]]);
    }else if (self.activePredicate && !self.cityPredicate) {
        self.onSelected(self.activePredicate);
    }else if (!self.activePredicate && self.cityPredicate) {
        self.onSelected(self.cityPredicate);
    }else {
        self.onSelected([NSPredicate predicateWithFormat:@"active = YES"]);
    }
}


#pragma mark View Lifecycle
- (id)initWithAction:(void (^)(NSPredicate *basePredicate))onSelected
{
    self = [super init];
    
    self.onSelected = onSelected;
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
    
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [UIFont boldFontWithSize:16];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentLeft;
    label.text = @"Inactive Accommodation";
    label.textColor = [UIColor IMLightBlue];
    [headerView addSubview:label];
    
    UISwitch *switcher = [[UISwitch alloc] init];
    switcher.translatesAutoresizingMaskIntoConstraints = NO;
    switcher.onTintColor = [UIColor IMLightBlue];
    [switcher addTarget:self action:@selector(switchActive:) forControlEvents:UIControlEventValueChanged];
    [headerView addSubview:switcher];
    
    [self.view addSubview:headerView];
    
    //layout header
    NSDictionary *headerViews = NSDictionaryOfVariableBindings(label, switcher);
    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(10)-[label]-(20,==20@900)-[switcher]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:headerViews]];
    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[label]-|" options:0 metrics:nil views:headerViews]];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(headerView, _tableView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[headerView]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_tableView]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[headerView(>=40)][_tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:headerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.tableView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
}

- (void)loadView
{
    self.view = [[UIView alloc] init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"View Options";
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
    NSString *city = sectionData[indexPath.row];
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        self.cityPredicate = nil;
    }else {
        self.cityPredicate = [NSPredicate predicateWithFormat:@"city = %@", city];
    }
    
    [self sendPredicateChanges];
}

@end
