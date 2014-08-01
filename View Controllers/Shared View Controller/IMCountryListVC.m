//
//  IMCountryListVC.m
//  IMMS for iPad
//
//  Created by Mario Yohanes on 7/5/13.
//  Copyright (c) 2013 International Organization for Migration. All rights reserved.
//

#import "IMCountryListVC.h"
#import "IMDBManager.h"
#import "IMFormCell.h"
#import "Registration.h"
#import "RegistrationBioData.h"
#import "Migrant.h"
#import "BioData.h"

@interface IMCountryListVC ()<UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableDictionary *countries;
@property (nonatomic, strong) NSMutableArray *indexTitles;
@property (nonatomic) BOOL modal;
@property (nonatomic) NSString* entity;
@property (nonatomic) NSString* sortDescriptorWithKey;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic) BOOL fromSearchBar;

@end


@implementation IMCountryListVC

#pragma mark Core Data Methods
- (void)setupFetchRequestWithPredicate:(NSPredicate *)predicate
{
    @try {
        NSFetchRequest *request = Nil;

        NSManagedObjectContext *moc = [IMDBManager sharedManager].localDatabase.managedObjectContext;
        if (self.entity) {
            request = [NSFetchRequest fetchRequestWithEntityName:self.entity];
            request.sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"bioData.nationality.name" ascending:YES], nil];
            request.returnsDistinctResults = YES;
        }else {
            request = [NSFetchRequest fetchRequestWithEntityName:@"Country"];
            request.sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil];
        }
        
        [request setReturnsObjectsAsFaults:YES];
        
        if (self.basePredicate) {
            if (predicate) {
                request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:predicate, self.basePredicate, nil]];
            }else{
                request.predicate = self.basePredicate;
            }
        }else if (predicate && !self.fromSearchBar){
            request.predicate = predicate;
        }
        
        NSError *error;
        NSMutableArray *results = [[moc executeFetchRequest:request error:&error] mutableCopy];
        
        if (error) {
            NSLog(@"Fail to Query : %@",[error description]);
            return;
        }
        
        NSMutableDictionary * dict = [NSMutableDictionary dictionary];
        NSMutableArray * indexArray = [NSMutableArray array];
        
        //sort first
        if (self.sortDescriptorWithKey) {
            if ([self.entity isEqualToString:@"Registration"]) {
                for (Registration * data in results) {
                    if (data) {
                        //check if search flag is set, case TRUE, then show only Country that equal from searchBar
                        if (self.fromSearchBar) {
                            if (![predicate evaluateWithObject:data.bioData.nationality]) continue;
                        }
                        
                        NSString *indexTitle = [data.bioData.nationality.name substringToIndex:1];
                        
                        //add index (first char)
                        if (![indexArray containsObject:indexTitle]) {
                            [indexArray addObject:indexTitle];
                        }
                        
                        //add the country data to section data
                        NSMutableArray *sectionData = [[dict objectForKey:indexTitle] mutableCopy];
                        if (!sectionData) {
                            sectionData = [NSMutableArray array];
                        }
                        
                        if (![sectionData containsObject:data.bioData.nationality]) {
                            [sectionData addObject:data.bioData.nationality];
                            [dict setObject:sectionData forKey:indexTitle];
                        }
                        
                    }
                }
                
            }else {
                
                
                for (Migrant * data in results) {
                    if (data) {
                        //check if search flag is set, case TRUE, then show only Country that equal from searchBar
                        if (self.fromSearchBar) {
                            if (![predicate evaluateWithObject:data.bioData.nationality]) continue;
                        }
                        
                        NSString *indexTitle = [data.bioData.nationality.name substringToIndex:1];
                        
                        //add index (first char)
                        if (![indexArray containsObject:indexTitle]) {
                            [indexArray addObject:indexTitle];
                        }
                        
                        //add the country data to section data
                        NSMutableArray *sectionData = [[dict objectForKey:indexTitle] mutableCopy];
                        if (!sectionData) {
                            sectionData = [NSMutableArray array];
                        }
                        
                        if (![sectionData containsObject:data.bioData.nationality]) {
                            [sectionData addObject:data.bioData.nationality];
                            [dict setObject:sectionData forKey:indexTitle];
                        }
                        
                    }
                }
            }
            //cleanup data
            //        nationID = Nil;
            //        cleanedArray = Nil;
            
            
        }else
        {
            for (Country *country in results) {

                //check if search flag is set, case TRUE, then show only Country that equal from searchBar
                if (self.fromSearchBar) {
                    if (![predicate evaluateWithObject:country]) continue;
                }

                NSString *indexTitle = [country.name substringToIndex:1];
    
                //avoid empty country name
                if(!indexTitle) continue;
                    
                
                //add index (first char)
                if (![indexArray containsObject:indexTitle]) {
                    [indexArray addObject:indexTitle];
                }
                
                //add the country data to section data
                NSMutableArray *sectionData = [[dict objectForKey:indexTitle] mutableCopy];
                if (!sectionData) {
                    sectionData = [NSMutableArray array];
                }
                
                [sectionData addObject:country];
                [dict setObject:sectionData forKey:indexTitle];
            }
        }
        //reset flag
        self.fromSearchBar = NO;
        self.countries = dict;
        self.indexTitles = indexArray;
        [self.tableView reloadData];
    }
    @catch (NSException *exception) {
        NSLog(@"Error on setupFetchRequestWithPredicate : %@",[exception description]);
    }
    
    
}


#pragma mark UISearchBarDelegate Methods
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = @"";
    searchBar.showsCancelButton = NO;
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
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", searchText];
        //set flag to know this is from searchBar
        self.fromSearchBar =YES;
        [self setupFetchRequestWithPredicate:predicate];
    }else{
        [self setupFetchRequestWithPredicate:nil];
    }
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = YES;
    return YES;
}


#pragma mark UITableViewDelegate Methods
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.textLabel.font = [UIFont regularFontWithSize:17];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSString *sectionTitle = self.indexTitles[indexPath.section];
    NSArray *sectionData = self.countries[sectionTitle];
    Country *country = sectionData[indexPath.row];
    cell.textLabel.text = country.name;
    
    UIImage *image = [UIImage imageNamed:country.code];
    if (!image) {
        image = [UIImage imageNamed:@"flag-default"];
    }
    cell.imageView.image = image;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *sectionTitle = self.indexTitles[section];
    return [[self.countries objectForKey:sectionTitle] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.indexTitles count];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.indexTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [self.indexTitles indexOfObject:title];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
    if (self.onSelected) {
        NSString *sectionTitle = self.indexTitles[indexPath.section];
        NSArray *sectionData = self.countries[sectionTitle];
        self.onSelected([sectionData objectAtIndex:indexPath.row]);
    }
}

#pragma mark View lifecycle
- (id)initWithBasePredicate:(NSPredicate *)basePredicate presentAsModal:(BOOL)modal popover:(BOOL)popover withEntity:(NSString*)entity sortDescriptorWithKey:(NSString*)key
{
    
    if (entity && key) {
        self = [super init];
        
        self.title = @"Choose Country";
        self.basePredicate = basePredicate;
        self.modal = modal;
        self.entity = entity;
        self.sortDescriptorWithKey = key;
        
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
        searchBar.delegate = self;
        searchBar.showsCancelButton = NO;
        searchBar.placeholder = @"Search by location name";
        [searchBar setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [self.view addSubview:searchBar];
        
        self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
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

#pragma mark View lifecycle
- (id)initWithBasePredicate:(NSPredicate *)basePredicate presentAsModal:(BOOL)modal popover:(BOOL)popover
{
    self = [super init];
    
    self.title = @"Choose Country";
    self.basePredicate = basePredicate;
    self.modal = modal;
    self.entity = Nil;
    self.sortDescriptorWithKey = Nil;
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    searchBar.delegate = self;
    searchBar.showsCancelButton = NO;
    searchBar.placeholder = @"Search by location name";
    [searchBar setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.view addSubview:searchBar];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
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

- (void)loadView
{
    self.view = [[UIView alloc] init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.modal) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    }
    //set from searchBar to NO
    self.fromSearchBar = NO;
    self.modalInPopover = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupFetchRequestWithPredicate:nil];
}

- (void)cancel
{
    if (self.onCancel) self.onCancel();
    else if (self.modal) [self dismissViewControllerAnimated:YES completion:nil];
}

@end