//
//  IMIOMOfficerVC.m
//  IMMS Manager
//
//  Created by Mario Yohanes on 8/20/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMIOMOfficerVC.h"
#import "IMFormCell.h"
#import <QuartzCore/QuartzCore.h>
#import "IMDBManager.h"
#import "IMNewIOMOfficerVC.h"
#import "IMAuthManager.h"


@interface IMIOMOfficerVC ()<UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableDictionary *data;
@property (nonatomic, strong) NSMutableArray *indexTitles;

@end


@implementation IMIOMOfficerVC
#pragma mark Core Data Methods
- (void)setupFetchRequestWithPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"IomOfficer"];
    request.sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil];
    if (predicate) request.predicate = predicate;
    
    NSManagedObjectContext *moc = [IMDBManager sharedManager].localDatabase.managedObjectContext;
    
    NSError *error;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    
    self.data = [NSMutableDictionary dictionary];
    self.indexTitles = [NSMutableArray array];
    
    for (int i=0; i<[results count]; i++) {
        IomOfficer *officer = results[i];
        NSString *indexTitle = [[officer.name substringToIndex:1] uppercaseString];
        
            //add index (first char)
        if (![self.indexTitles containsObject:indexTitle]) {
            [self.indexTitles addObject:indexTitle];
        }
        
            //add the country data to section data
        NSMutableArray *sectionData = [[self.data objectForKey:indexTitle] mutableCopy];
        if (!sectionData) {
            sectionData = [NSMutableArray array];
        }
        
        [sectionData addObject:officer];
        [self.data setObject:sectionData forKey:indexTitle];
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
        cell = [[IMFormCell alloc] initWithFormType:IMFormCellTypeCheckmark reuseIdentifier:cellIdentifier];
    }
    
    NSString *sectionTitle = self.indexTitles[indexPath.section];
    NSArray *sectionData = self.data[sectionTitle];
    IomOfficer *officer = sectionData[indexPath.row];
    cell.labelTitle.text = [officer description];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *sectionTitle = self.indexTitles[section];
    return [[self.data objectForKey:sectionTitle] count];
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
        NSArray *sectionData = self.data[sectionTitle];
        self.onSelected([sectionData objectAtIndex:indexPath.row]);
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
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name BEGINSWITH %@ OR email BEGINSWITH %@", searchText, searchText];
        [self setupFetchRequestWithPredicate:predicate];
    }else{
        [self setupFetchRequestWithPredicate:nil];
    }
}


#pragma mark View Lifecycle
- (id)initWithAction:(void (^)(IomOfficer *))onSelected
{
    self = [super init];
    
    self.title = @"IOM Officer";
    self.onSelected = onSelected;
    
    if ([IMAuthManager sharedManager].activeUser.roleInterception) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                               target:self
                                                                                               action:@selector(createIOMOfficer)];
    }
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancel)];
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    searchBar.delegate = self;
    searchBar.showsCancelButton = NO;
    searchBar.placeholder = @"Search by name or email";
    searchBar.barStyle = UIBarStyleDefault;
    [searchBar setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.view addSubview:searchBar];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 20, 0, 0);
    [self.tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.tableView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(searchBar, _tableView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[searchBar]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_tableView]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[searchBar(44)][_tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:searchBar attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.tableView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    
    self.modalInPopover = YES;
    self.preferredContentSize = CGSizeMake(450, 500);
    
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

- (void)createIOMOfficer
{
    IMNewIOMOfficerVC *vc = [[IMNewIOMOfficerVC alloc] initWithAction:self.onSelected];
    [self.navigationController pushViewController:vc animated:YES];
}

@end