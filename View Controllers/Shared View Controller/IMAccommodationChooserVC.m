//
//  IMAccommodationListVC.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/5/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMAccommodationChooserVC.h"
#import "IMDBManager.h"
#import "Accommodation+Extended.h"
#import <QuartzCore/QuartzCore.h>
#import "IMFormCell.h"
#import "Registration.h"
#import "IMConstants.h"
#import "Migrant.h"


@interface IMAccommodationChooserVC ()<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic) BOOL modal;
@property (nonatomic, strong) NSDictionary *data;
@property (nonatomic, strong) NSArray *indexTitles;
@property (nonatomic) NSString* entity;
@property (nonatomic) NSString* sortDescriptorWithKey;
@property (nonatomic,strong) NSString * searchString;

@end


@implementation IMAccommodationChooserVC

#pragma mark Action
- (void)cancel
{
    if (self.onCancel) self.onCancel();
    else if (self.modal) [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)filterControlValueChanged:(UISegmentedControl *)segmentedControl
{
    [self setupFetchRequestWithPredicate:[self filterPredicate]];
}


#pragma mark Core Data Methods
- (void)setupFetchRequestWithPredicate:(NSPredicate *)filterPredicate
{
    NSFetchRequest *request = Nil;
    if (self.entity) {
        request = [NSFetchRequest fetchRequestWithEntityName:self.entity];
        request.propertiesToFetch = @[@"detentionLocation"];
        request.returnsDistinctResults = YES;
        [request setResultType:NSDictionaryResultType];
        request.returnsObjectsAsFaults = YES;
        
    }else{
        request = [NSFetchRequest fetchRequestWithEntityName:@"Accommodation"];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"city" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    }
    
    if (self.basePredicate && filterPredicate) {
        request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[self.basePredicate, filterPredicate]];
    }else if (self.basePredicate && !filterPredicate) {
        request.predicate = self.basePredicate;
    }else if (!self.basePredicate && filterPredicate) {
        request.predicate = filterPredicate;
    }
    
    
    NSManagedObjectContext *moc = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    self.options = [results copy];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    //sort first
    if (self.sortDescriptorWithKey) {
        
        NSArray *locationID = [results valueForKeyPath:@"@distinctUnionOfObjects.detentionLocation"];
        //remove redundent data
        NSArray * cleanedArray = [[NSSet setWithArray:locationID] allObjects];
        
        NSMutableArray * tmp = [NSMutableArray array];
        NSPredicate *searchPredicate = Nil;
        Accommodation * place = Nil;
        if (self.searchString) {
            searchPredicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR city CONTAINS[cd] %@", self.searchString, self.searchString];
            self.searchString = Nil;
        }
        
        for (NSString * detentionLocation in cleanedArray) {
            if (detentionLocation) {
                place = [Accommodation accommodationWithId:detentionLocation inManagedObjectContext:moc];
                //                NSLog(@"place.name : %@",place.name);
                if (![tmp containsObject:place]) {
                    if (searchPredicate) {
                        if ([searchPredicate evaluateWithObject:place]) {
                            [tmp addObject:place];
                        }
                    }else{
                        [tmp addObject:place];
                    }
                }
            }
        }
        
        
        NSArray *cities = [tmp valueForKeyPath:@"@distinctUnionOfObjects.city"];
        for (NSString *city in cities) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"city = %@ AND type like[cd] %@", city,[[self accommodationTypes] objectAtIndex:self.segmentedControl.selectedSegmentIndex]];
            if (![dictionary objectForKey:city]) {
                [dictionary setObject:[tmp filteredArrayUsingPredicate:predicate] forKey:city];
            }
            
        }
        //cleanup data
        cities = Nil;
        searchPredicate = Nil;
        place = Nil;
        locationID = Nil;
        cleanedArray = Nil;
        tmp = Nil;
    }else{
        
        NSArray *cities = [results valueForKeyPath:@"@distinctUnionOfObjects.city"];
        for (NSString *city in cities) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"active = YES AND city = %@", city];
            [dictionary setObject:[results filteredArrayUsingPredicate:predicate] forKey:city];
        }
    }
    
    //cleanup data
    request = Nil;
    results = Nil;
    moc = Nil;
    self.data = dictionary;
    self.indexTitles = [[self.data allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    [self.tableView reloadData];
}

- (void)setupFetchRequestWithPredicateTest:(NSPredicate *)filterPredicate
{
    NSManagedObjectContext *context = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    NSMutableArray *cityList = [NSMutableArray array];
    NSMutableDictionary *locationList = [NSMutableDictionary dictionary];
    
    NSArray *results;
    NSError *error;
    //todo : only display  location that occupide by migrant
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Migrant"];
    request.propertiesToFetch = @[@"detentionLocation"];
    request.returnsDistinctResults = YES;
    [request setResultType:NSDictionaryResultType];
    request.returnsObjectsAsFaults = YES;
    results = [context executeFetchRequest:request error:&error];
     self.options = [results copy];
    NSArray *locationID = [results valueForKeyPath:@"@distinctUnionOfObjects.detentionLocation"];
    
    //remove redundent data
    NSArray * cleanedArray = [[NSSet setWithArray:locationID] allObjects];
    
    
    
    for (NSString * place in cleanedArray) {
        if (place) {
            Accommodation *location = [Accommodation accommodationWithId:place inManagedObjectContext:context];
            if (location) {
                NSString *cityName = location.city;
                
                if (![cityList containsObject:cityName]) [cityList addObject:cityName];
                
                NSMutableArray *locationInCity = [locationList[cityName] mutableCopy];
                if (!locationInCity) locationInCity = [NSMutableArray array];
                
                if(![locationInCity containsObject:location]) [locationInCity addObject:location];
                if (![locationList[cityList] isEqualToArray:locationInCity]) {
                    locationList[cityName] = [locationInCity sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
                }
            }//end if (location)
        }//end if (place)
    }//end for
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (NSString *city in cityList) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"active = YES AND city = %@", city];
        [dictionary setObject:[results filteredArrayUsingPredicate:predicate] forKey:city];
    }
    
    self.data = dictionary;
    self.indexTitles = [[self.data allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    [self.tableView reloadData];
    context = Nil;
    cityList = Nil;
    locationList = Nil;
}//end all

#pragma mark View Lifecycle
- (id)initWithBasePredicate:(NSPredicate *)basePredicate presentAsModal:(BOOL)modal
{
    self = [super init];
    self.modal = modal;
    if (!basePredicate) {
        //only show that active accomodation
        self.basePredicate = [NSPredicate predicateWithFormat:@"active = YES"];
    }else self.basePredicate = basePredicate;
    
    self.entity = Nil;
    self.sortDescriptorWithKey = Nil;
    
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:[self accommodationTypes]];
    self.segmentedControl.selectedSegmentIndex = 0;
    [self.segmentedControl addTarget:self action:@selector(filterControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = self.segmentedControl;
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    searchBar.delegate = self;
    searchBar.showsCancelButton = NO;
    searchBar.placeholder = @"Search by accommodation's name or city";
    [searchBar setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    
    [self.view addSubview:searchBar];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorColor = [UIColor IMBorderColor];
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.tableView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(searchBar, _tableView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[searchBar]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_tableView]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[searchBar(44)][_tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:searchBar attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.tableView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    
    return self;
}

- (id)initWithBasePredicate:(NSPredicate *)basePredicate presentAsModal:(BOOL)modal withEntity:(NSString *)entity sortDescriptorWithKey:(NSString*)key
{
    if (entity && key) {
        self = [super init];
        self.modal = modal;
//        self.basePredicate = basePredicate;
        if (!basePredicate) {
            //only show that active accomodation
            self.basePredicate = [NSPredicate predicateWithFormat:@"active = YES"];
        }else self.basePredicate = basePredicate;
        
        self.entity = entity;
        self.sortDescriptorWithKey = key;
        
        
        self.segmentedControl = [[UISegmentedControl alloc] initWithItems:[self accommodationTypes]];
        self.segmentedControl.selectedSegmentIndex = 0;
        [self.segmentedControl addTarget:self action:@selector(filterControlValueChanged:) forControlEvents:UIControlEventValueChanged];
        self.navigationItem.titleView = self.segmentedControl;
        
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
        searchBar.delegate = self;
        searchBar.showsCancelButton = NO;
        searchBar.placeholder = @"Search by accommodation's name or city";
        [searchBar setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [self.view addSubview:searchBar];
        
        self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.separatorColor = [UIColor IMBorderColor];
        self.tableView.backgroundColor = [UIColor whiteColor];
        [self.tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.view addSubview:self.tableView];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(searchBar, _tableView);
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[searchBar]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_tableView]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[searchBar(44)][_tableView]|" options:0 metrics:nil views:views]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:searchBar attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.tableView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
        
        return self;
    }else return Nil;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.modal) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    }
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 20, 0, 0);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupFetchRequestWithPredicate:[self filterPredicate]];
}

- (NSArray *)accommodationTypes
{
    //    return @[@"Housing", @"Rudenim", @"Kanim",@"Interception Site"];
    return [IMConstants constantsForKey:CONST_LOCATION];
}

- (NSPredicate *)filterPredicate
{
    if (self.entity) {
        return Nil;
    }else return [NSPredicate predicateWithFormat:@"active = YES AND type like[cd] %@", [[self accommodationTypes] objectAtIndex:self.segmentedControl.selectedSegmentIndex]];
    //    return [NSPredicate predicateWithFormat:@"active = YES AND type = %@", [[self accommodationTypes] objectAtIndex:self.segmentedControl.selectedSegmentIndex]];
}

- (NSPredicate *)filterPredicateWithSearchQuery:(NSString *)searchText
{
    NSPredicate *filterPredicate = [self filterPredicate];
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR city CONTAINS[cd] %@", searchText, searchText];
    if (self.entity) {
        self.searchString  = searchText;
        return Nil;
    }else {
        return [NSCompoundPredicate andPredicateWithSubpredicates:@[filterPredicate, searchPredicate]];
    }
    
}


#pragma mark UISearchBarDelegate Methods
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchString = searchBar.text = Nil;
    searchBar.showsCancelButton = NO;
    [searchBar resignFirstResponder];
    [self setupFetchRequestWithPredicate:[self filterPredicate]];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length] > 0) {
        [self setupFetchRequestWithPredicate:[self filterPredicateWithSearchQuery:searchText]];
    }else{
        [self setupFetchRequestWithPredicate:[self filterPredicate]];
    }
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = YES;
    return YES;
}


#pragma mark Table View
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.indexTitles count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.data objectForKey:self.indexTitles[section]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *sectionData = [self.data objectForKey:self.indexTitles[indexPath.section]];
    Accommodation *rowData = sectionData[indexPath.row];
    
    NSString *cellIdentifier = rowData.address ? @"Subtitle" : @"Title";
    IMFormCell *cell = (IMFormCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[IMFormCell alloc] initWithFormType:(rowData.address ? IMFormCellTypeSubtitle : IMFormCellTypeTitle) reuseIdentifier:cellIdentifier];
    }
    
    cell.labelTitle.text = rowData.name;
    cell.labelValue.text = rowData.address;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *sectionData = [self.data objectForKey:self.indexTitles[indexPath.section]];
    Accommodation *rowData = sectionData[indexPath.row];
    return rowData.address ? 50 : 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return self.segmentedControl.selectedSegmentIndex > 0 ? 0 : 30;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.segmentedControl.selectedSegmentIndex > 0 ? nil : [self.indexTitles objectAtIndex:section];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.segmentedControl.selectedSegmentIndex > 0 ? nil : self.indexTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return self.segmentedControl.selectedSegmentIndex > 0 ? NSNotFound : [self.indexTitles indexOfObject:title];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView indexPathForSelectedRow]) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:[tableView indexPathForSelectedRow]];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    if (self.onSelected) {
        NSArray *sectionData = [self.data objectForKey:self.indexTitles[indexPath.section]];
        Accommodation *rowData = sectionData[indexPath.row];
        self.onSelected(rowData);
    }
}

@end