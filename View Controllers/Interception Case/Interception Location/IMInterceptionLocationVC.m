//
//  IMInterceptionLocationVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 7/29/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMInterceptionLocationVC.h"
#import "InterceptionLocation+Extended.h"
#import "IMDBManager.h"
#import "IMFormCell.h"
#import "IMTableHeaderView.h"
#import <QuartzCore/QuartzCore.h>
#import "IMNewInterceptionLocationVC.h"
#import "IMAuthManager.h"


@interface IMInterceptionLocationVC ()<UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableDictionary *locations;
@property (nonatomic, strong) NSMutableArray *indexTitles;
@property (nonatomic, strong) UITableView *tableView;

@end



@implementation IMInterceptionLocationVC

#pragma mark Core Data Methods
- (void)setupFetchRequestWithPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"InterceptionLocation"];
    request.sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil];
    if (predicate) request.predicate = predicate;
    
    NSManagedObjectContext *moc = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    
    self.locations = [NSMutableDictionary dictionary];
    self.indexTitles = [NSMutableArray array];
    
    for (int i=0; i<[results count]; i++) {
        InterceptionLocation *location = results[i];
        NSString *indexTitle = [location.name substringToIndex:1];
        
        //add index (first char)
        if (![self.indexTitles containsObject:indexTitle]) {
            [self.indexTitles addObject:indexTitle];
        }
        
        //add the country data to section data
        NSMutableArray *sectionData = [[self.locations objectForKey:indexTitle] mutableCopy];
        if (!sectionData) {
            sectionData = [NSMutableArray array];
        }
        
        [sectionData addObject:location];
        [self.locations setObject:sectionData forKey:indexTitle];
    }
    
    results = nil;
    [self.tableView reloadData];
}


#pragma mark Table View Methods
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"InterceptionLocationIdentifier";
    
    IMFormCell *cell = (IMFormCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        IMFormCellType type = self.editing ? IMFormCellTypeDetail : IMFormCellTypeCheckmark;
        cell = [[IMFormCell alloc] initWithFormType:type reuseIdentifier:cellIdentifier];
    }
    
    NSString *sectionTitle = self.indexTitles[indexPath.section];
    NSArray *sectionData = self.locations[sectionTitle];
    InterceptionLocation *location = sectionData[indexPath.row];
    cell.labelTitle.text = [location description];
        
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *sectionTitle = self.indexTitles[section];
    return [[self.locations objectForKey:sectionTitle] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.indexTitles count];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.indexTitles;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.onSelected) {
        NSString *sectionTitle = self.indexTitles[indexPath.section];
        NSArray *sectionData = self.locations[sectionTitle];
        self.onSelected([sectionData objectAtIndex:indexPath.row]);
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


#pragma mark UISearchBarDelegate Methods
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    [self setupFetchRequestWithPredicate:nil];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length] > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR locality CONTAINS[cd] %@ or administrativeArea contains[cd] %@", searchText, searchText, searchText];
        [self setupFetchRequestWithPredicate:predicate];
    }else{
        [self setupFetchRequestWithPredicate:nil];
    }
}


#pragma mark View Lifecycle
- (id)initWithAction:(void (^)(InterceptionLocation *selectedLocation))onSelected
{
    self = [super init];
    
    self.title = @"Interception Location";
    
    if ([IMAuthManager sharedManager].activeUser.roleInterception) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                               target:self
                                                                                               action:@selector(createInterceptionLocation)];
    }
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancel)];
        
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    searchBar.delegate = self;
    searchBar.showsCancelButton = NO;
    searchBar.barStyle = UIBarStyleDefault;
    searchBar.placeholder = @"Search by location name, city or province";
    [searchBar setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.view addSubview:searchBar];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 20, 0, 0);
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.tableView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(searchBar, _tableView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[searchBar]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_tableView]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[searchBar(44)][_tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:searchBar attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.tableView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    
    self.preferredContentSize = CGSizeMake(450, 500);
    self.modalInPopover = YES;
    self.onSelected = onSelected;
    self.tableView.tintColor = [UIColor IMRed];
    
    return self;
}

- (void)loadView
{
    self.view = [[UIView alloc] init];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setupFetchRequestWithPredicate:nil];
}

- (void)cancel
{
    if (self.onSelected) self.onSelected(nil);
}

- (void)createInterceptionLocation
{
    IMNewInterceptionLocationVC *vc = [[IMNewInterceptionLocationVC alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end