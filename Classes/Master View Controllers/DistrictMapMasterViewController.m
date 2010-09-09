//
//  DistrictOfficeMasterViewController.m
//  TexLege
//
//  Created by Gregory Combs on 8/23/10.
//  Copyright 2010 Gregory S. Combs. All rights reserved.
//

#import "DistrictMapMasterViewController.h"
#import "DistrictMapDataSource.h"
#import "DistrictMapObj.h"
#import "MapViewController.h"
#import "UtilityMethods.h"
#import "TexLegeAppDelegate.h"
#import "TexLegeTheme.h"
#import "DistrictMapObj.h"
#import "TexLegeCoreDataUtils.h"

@interface DistrictMapMasterViewController (Private)
- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar;
@end



@implementation DistrictMapMasterViewController
@synthesize chamberControl, sortControl, filterControls;


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}


#pragma mark -
#pragma mark Initialization

- (NSString *) viewControllerKey {
	return @"DistrictMapMasterViewController";
}

- (NSString *)nibName {
	return [self viewControllerKey];
}


- (Class)dataSourceClass {
	return [DistrictMapDataSource class];
}

/*
 - (void)configureWithManagedObjectContext:(NSManagedObjectContext *)context {
 [super configureWithManagedObjectContext:context];	
 }
 */

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.tableView.rowHeight = 44.0f;
	self.tableView.delegate = self;
	self.tableView.dataSource = self.dataSource;	
	
	if ([UtilityMethods isIPadDevice])
	    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
	
	self.searchDisplayController.delegate = self;
	self.searchDisplayController.searchResultsDelegate = self;
	self.dataSource.searchDisplayController = self.searchDisplayController;
	self.searchDisplayController.searchResultsDataSource = self.dataSource;
	
	self.chamberControl.tintColor = [TexLegeTheme accent];
	self.sortControl.tintColor = [TexLegeTheme accent];
	self.searchDisplayController.searchBar.tintColor = [TexLegeTheme accent];
	self.navigationItem.titleView = self.filterControls;
	
	self.selectObjectOnAppear = nil;
/*
 if (!self.selectObjectOnAppear && [UtilityMethods isIPadDevice])
		self.selectObjectOnAppear = [self firstDataObject];
*/
}

- (void)viewDidUnload {
	self.chamberControl = nil;
	self.sortControl = nil;
	self.filterControls = nil;
	[super viewDidUnload];
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	/*
	//// ALL OF THE FOLLOWING MUST NOT RUN ON IPHONE (I.E. WHEN THERE'S NO SPLITVIEWCONTROLLER	
	if ([UtilityMethods isIPadDevice] && self.selectObjectOnAppear == nil) {
		id detailObject = nil;

		if (self.detailViewController && [self.detailViewController isKindOfClass:[MapViewController class]]) {
			MapViewController *mapVC = (MapViewController *)self.detailViewController;
			if (mapVC && [mapVC.mapView.annotations count]) {
				for (id<MKAnnotation>annotation in mapVC.mapView.annotations) {
					if ([annotation isKindOfClass:[DistrictOfficeObj class]]) {
						detailObject = annotation;
						continue;
					}
				}
			}
			if (!detailObject) {
				NSIndexPath *currentIndexPath = [self.tableView indexPathForSelectedRow];
				if (!currentIndexPath) {			
					NSUInteger ints[2] = {0,0};	// just pick the first one then
					currentIndexPath = [NSIndexPath indexPathWithIndexes:ints length:2];
				}
				detailObject = [self.dataSource dataObjectForIndexPath:currentIndexPath];				
			}
			self.selectObjectOnAppear = detailObject;
			
		}
			
		self.selectObjectOnAppear = detailObject;
	}	
	
	// END: IPAD ONLY
	 */
}


#pragma mark -
#pragma mark Table view delegate

//START:code.split.delegate
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath withAnimation:(BOOL)animated {
	TexLegeAppDelegate *appDelegate = [TexLegeAppDelegate appDelegate];
	
	//if (![UtilityMethods isIPadDevice])
		[aTableView deselectRowAtIndexPath:newIndexPath animated:YES];
		
	
	id dataObject = [self.dataSource dataObjectForIndexPath:newIndexPath];
/*	if ([dataObject isKindOfClass:[NSManagedObject class]])
		[appDelegate setSavedTableSelection:[dataObject objectID] forKey:self.viewControllerKey];
	else
		[appDelegate setSavedTableSelection:newIndexPath forKey:self.viewControllerKey];
*/
	[appDelegate setSavedTableSelection:nil forKey:self.viewControllerKey];
	
	if (!self.detailViewController) {
		MapViewController *tempVC = [[MapViewController alloc] init];
		self.detailViewController = tempVC;
		[tempVC release];
	}

	DistrictMapObj *map = dataObject;
	if (map) {
		MapViewController *mapVC = (MapViewController *)self.detailViewController;
		[mapVC view];
		MKMapView *mapView = mapVC.mapView;
		if (mapVC && mapView) {
			
			[mapVC clearAnnotationsAndOverlays];

			[mapView addOverlay:[map polygon]];
			[mapView addAnnotation:map];
			[mapVC moveMapToAnnotation:map];			
		}
		if (aTableView == self.searchDisplayController.searchResultsTableView) { // we've clicked in a search table
			[self searchBarCancelButtonClicked:nil];
		}
		
		if (![UtilityMethods isIPadDevice]) {
			// push the detail view controller onto the navigation stack to display it				
			[self.navigationController pushViewController:self.detailViewController animated:YES];
			self.detailViewController = nil;
		}
		
	}
	
}
//END:code.split.delegate


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	self.chamberControl = nil;
	self.sortControl = nil;
	self.filterControls = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Filtering and Searching

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSInteger)scope
{
	/*
	 Update the filtered array based on the search text and scope.
	 */
	if ([self.dataSource respondsToSelector:@selector(setFilterChamber:)])
		[self.dataSource setFilterChamber:scope];
	
	// start filtering names...
	if (searchText.length > 0) {
		if ([self.dataSource respondsToSelector:@selector(setFilterByString:)])
			[self.dataSource performSelector:@selector(setFilterByString:) withObject:searchText];
	}	
	else {
		if ([self.dataSource respondsToSelector:@selector(removeFilter)])
			[self.dataSource performSelector:@selector(removeFilter)];
	}
	
}

- (IBAction) filterChamber:(id)sender {
	if (sender == chamberControl) {
		[self filterContentForSearchText:self.searchDisplayController.searchBar.text 
								   scope:self.chamberControl.selectedSegmentIndex];
		[self.tableView reloadData];
	}
}

- (IBAction) sortType:(id)sender {
	if (sender == self.sortControl) {
		BOOL byDistrict = (self.sortControl.selectedSegmentIndex == 1);
		
		[(DistrictMapDataSource *) self.dataSource setByDistrict:byDistrict];
		[(DistrictMapDataSource *) self.dataSource sortByType:sender];
				
		[self.tableView reloadData];
	}
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:self.chamberControl.selectedSegmentIndex];
    
	// Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
	self.searchDisplayController.searchBar.text = @"";
	[self.dataSource removeFilter];
	
	[self.searchDisplayController setActive:NO animated:YES];
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
	[self.dataSource setHideTableIndex:YES];	
	// for some reason, these get zeroed out after we restart searching.
	self.searchDisplayController.searchResultsTableView.rowHeight = self.tableView.rowHeight;
	self.searchDisplayController.searchResultsTableView.backgroundColor = self.tableView.backgroundColor;
	self.searchDisplayController.searchResultsTableView.sectionIndexMinimumDisplayRowCount = self.tableView.sectionIndexMinimumDisplayRowCount;
	
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
	[self.dataSource setHideTableIndex:NO];	
}



@end

