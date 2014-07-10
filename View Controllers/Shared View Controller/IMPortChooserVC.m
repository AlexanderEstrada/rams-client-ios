//
//  IMPortChooserVC.m
//  IMMS Manager
//
//  Created by IOM Jakarta on 6/27/14.
//  Copyright (c) 2014 Mario Yohanes. All rights reserved.
//

#import "IMPortChooserVC.h"
#import "IMDBManager.h"
#import "Port+Extended.h"
#import <QuartzCore/QuartzCore.h>
#import "IMFormCell.h"
#import "IMConstants.h"
#import "Migrant.h"


 @interface IMPortChooserVC ()<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

//@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic) BOOL modal;
@property (nonatomic, strong) NSDictionary *data;
@property (nonatomic, strong) NSArray *indexTitles;
@property (nonatomic,strong) NSString * searchString;

@end


@implementation IMPortChooserVC

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
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Port"];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"city" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    
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
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
        NSArray *cities = [results valueForKeyPath:@"@distinctUnionOfObjects.city"];
        for (NSString *city in cities) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"city = %@", city];
            [dictionary setObject:[results filteredArrayUsingPredicate:predicate] forKey:city];
        }
    
    
    //cleanup data
    request = Nil;
    results = Nil;
    moc = Nil;
    self.data = dictionary;
    self.indexTitles = [[self.data allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    [self.tableView reloadData];
}


#pragma mark View Lifecycle
- (id)initWithBasePredicate:(NSPredicate *)basePredicate presentAsModal:(BOOL)modal
{
    self = [super init];
    self.modal = modal;
    self.basePredicate = basePredicate;
    
//    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:[self PortProvince]];
//    self.segmentedControl.selectedSegmentIndex = 0;
//    [self.segmentedControl addTarget:self action:@selector(filterControlValueChanged:) forControlEvents:UIControlEventValueChanged];
//    self.navigationItem.titleView = self.segmentedControl;
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    searchBar.delegate = self;
    searchBar.showsCancelButton = NO;
    searchBar.placeholder = @"Search by port's name or city";
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

- (NSArray *)PortProvince
{
    //get all province in port
    NSManagedObjectContext *moc = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    NSFetchRequest *request  = [NSFetchRequest fetchRequestWithEntityName:@"Port"];
        request.sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"province" ascending:YES], nil];
    
    [request setReturnsObjectsAsFaults:YES];
    
    NSError *error;
    NSArray * result = [moc executeFetchRequest:request error:&error];
    NSMutableArray * province = [NSMutableArray array];
    for (Port * port in result) {
        [province addObject:port.province];
    }
   return province;
}

- (NSPredicate *)filterPredicate
{
//     return [NSPredicate predicateWithFormat:@"province = %@", [[self PortProvince] objectAtIndex:self.segmentedControl.selectedSegmentIndex]];
    return Nil;
}

- (NSPredicate *)filterPredicateWithSearchQuery:(NSString *)searchText
{
//    NSPredicate *filterPredicate = [self filterPredicate];
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR city CONTAINS[cd] %@", searchText, searchText];
//        return [NSCompoundPredicate andPredicateWithSubpredicates:@[filterPredicate, searchPredicate]];
    return searchPredicate;
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
    Port *rowData = sectionData[indexPath.row];
    
    NSString *cellIdentifier = @"Title";
    IMFormCell *cell = (IMFormCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeTitle reuseIdentifier:cellIdentifier];
    }
    
    cell.labelTitle.text = rowData.name;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
//    return self.segmentedControl.selectedSegmentIndex > 0 ? 0 : 30;
        return 30;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
//    return self.segmentedControl.selectedSegmentIndex > 0 ? nil : [self.indexTitles objectAtIndex:section];
        return [self.indexTitles objectAtIndex:section];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
//    return self.segmentedControl.selectedSegmentIndex > 0 ? nil : self.indexTitles;
    return self.indexTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
//    return self.segmentedControl.selectedSegmentIndex > 0 ? NSNotFound : [self.indexTitles indexOfObject:title];
    return [self.indexTitles indexOfObject:title];
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
        Port *rowData = sectionData[indexPath.row];
        self.onSelected(rowData);
    }
}

@end

