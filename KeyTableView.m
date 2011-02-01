//
//  PublicKeysTableView.m
//  iRSA
//
//  Created by Jan Galler on 16.01.11.
//  Copyright 2011 PQ-Developing.com. All rights reserved.
//

#import "KeyTableView.h"
#import "KeyPropertys.h"
#import "iRSAAppDelegate.h"
#import "SendMail.h"

@implementation KeyTableView
@synthesize dataArray, myTable, currentKeyLength, bitArray, keyAddModeInt, otherTable;


#pragma mark -
#pragma mark Initialization & Dealloc

- (id) init{
	self = [super init];
	if (self != nil) {
		self.currentKeyLength = [NSNumber numberWithInt:2048];
		self.bitArray = [[NSArray alloc]init];
		iRSAAppDelegate *myAppDelegate = (iRSAAppDelegate *)[[NSApplication sharedApplication] delegate];
		myAppDelegate.keyDataArray = [[NSMutableArray alloc]init];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(addItem:)
													 name:@"addNewKey"
												   object:nil];
	}
	return self;
}

- (void)awakeFromNib{
	[self setupBitPopupButton];
	[myTable setTarget:self];
	[otherTable setTarget:self];
	[myTable setDoubleAction:@selector(doubleClickToRow:)];
	[otherTable setDoubleAction:@selector(doubleClickToRow:)];

}

-(void)setupKeyPopUpButton{
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center postNotificationName:@"itemCountChanged" object:nil userInfo:nil];	
}

-(void)setupBitPopupButton{
	self.bitArray = [NSArray arrayWithObjects:@"512",@"1024",@"2048",@"4096",@"8192",@"16384",@"32768",@"65536",nil];
	
	for(NSString *currentBit in self.bitArray){
		NSMenuItem* newItem = [[NSMenuItem alloc] initWithTitle:currentBit action:nil keyEquivalent:@""];
		[newItem setTarget:self];
		[[setupBitPopUpButton menu] addItem:newItem];
		[newItem release];		
	}
	
	int cache = [[self.bitArray objectAtIndex:0] intValue];
	self.currentKeyLength = [NSNumber numberWithInt:cache];
}

- (void) dealloc{
	[otherTable release];
	[bitArray release];
	[currentKeyLength release];
	[keyClass release];
	[myTable release];
	[dataArray release];
	[super dealloc];
}

#pragma mark -
#pragma mark NSNotification Methods

- (void)addItem:(NSNotification *)notification{
	iRSAAppDelegate *myAppDelegate = (iRSAAppDelegate *)[[NSApplication sharedApplication] delegate];
	
	[myAppDelegate.keyDataArray addObject:[KeyPropertys keyItemWithData:@"untitled" :[[notification userInfo]objectForKey:@"publicKey"] :[[notification userInfo]objectForKey:@"privateKey"] :[[notification userInfo]objectForKey:@"publicKeyData"] :[[notification userInfo]objectForKey:@"privateKeyData"]: @"noOne"]];
	
	[self setupKeyPopUpButton];
	[self.myTable noteNumberOfRowsChanged];
	[self.otherTable noteNumberOfRowsChanged];
	
	NSInteger newRowIndex = [myAppDelegate.keyDataArray count]-1;
	[myTable selectRowIndexes:[NSIndexSet indexSetWithIndex:newRowIndex]
		 byExtendingSelection:NO];
	
	[myTable editColumn:[myTable columnWithIdentifier:@"identifier"]
					row:newRowIndex withEvent:nil select:YES];
	
	[myTable editColumn:[myTable columnWithIdentifier:@"person"]
					row:newRowIndex withEvent:nil select:YES];
	
}


#pragma mark -
#pragma mark IBActions

- (IBAction)pushAddNewKey:(id)sender{
	[NSApp beginSheet:keySetupSheet modalForWindow:keyTableView modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (IBAction)pushRemoveKey:(id)sender{
	iRSAAppDelegate *myAppDelegate = (iRSAAppDelegate *)[[NSApplication sharedApplication] delegate];
	[myAppDelegate.keyDataArray removeObjectsAtIndexes:[self.myTable selectedRowIndexes]];
	[self setupKeyPopUpButton];
	[self.myTable noteNumberOfRowsChanged];
	[self.otherTable noteNumberOfRowsChanged];
	[self setupKeyPopUpButton];
}

-(IBAction)pushGenerateSetupKey:(id)sender{
	
	if(self.keyAddModeInt == 0){
		
		[keySetupSheet orderOut:nil];
		[NSApp endSheet:keySetupSheet];
		
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		[center postNotificationName:@"startKeyGenerate" object:nil userInfo:nil];
		
		if (self.currentKeyLength == 0) {
			self.currentKeyLength = [NSNumber numberWithInt:2048];
		}
		
		keyClass = [[KeyGenerate alloc]init];
		[keyClass performSelectorInBackground:@selector (generatePublicAndPrivateRSAKeyWithPrivatKeyLength:) withObject:self.currentKeyLength];
		
	}else if (self.keyAddModeInt == 1) {
		[keySetupSheet orderOut:nil];
		[NSApp endSheet:keySetupSheet];
		
		iRSAAppDelegate *myAppDelegate = (iRSAAppDelegate *)[[NSApplication sharedApplication] delegate];
		NSData *cache = [[enterOwnPublicKey stringValue] dataUsingEncoding:NSUTF8StringEncoding];
	
		[myAppDelegate.keyDataArray addObject:[KeyPropertys keyItemWithData:@"untitled" :[enterOwnPublicKey stringValue] :@"-" :cache :nil :@"noOne"]];
		
		[self setupKeyPopUpButton];
		[self.myTable noteNumberOfRowsChanged];
		[self.otherTable noteNumberOfRowsChanged];
		
		NSInteger newRowIndex = [myAppDelegate.keyDataArray count]-1;
		[myTable selectRowIndexes:[NSIndexSet indexSetWithIndex:newRowIndex]
			 byExtendingSelection:NO];
		
		[myTable editColumn:[myTable columnWithIdentifier:@"identifier"]
						row:newRowIndex withEvent:nil select:YES];
		
		[myTable editColumn:[myTable columnWithIdentifier:@"person"]
						row:newRowIndex withEvent:nil select:YES];
	}
	
		

}
-(IBAction)pushChooseBit:(id)sender{
	int cache = [[self.bitArray objectAtIndex:[sender indexOfSelectedItem]] intValue];
	self.currentKeyLength = [NSNumber numberWithInt:cache];
}

-(IBAction)pushCancelGenerate:(id)sender{
	[keySetupSheet orderOut:nil];
	[NSApp endSheet:keySetupSheet];
}


#pragma mark -
#pragma mark Delegate Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
	iRSAAppDelegate *myAppDelegate = (iRSAAppDelegate *)[[NSApplication sharedApplication] delegate];
	
	NSMutableArray *externalKeys = [[[NSMutableArray alloc]init]autorelease];
	NSMutableArray *internalKeys = [[[NSMutableArray alloc]init]autorelease];
	
	int max = [myAppDelegate.keyDataArray count];
	int i;
	
	for(i=0;i<max;i++){
		KeyPropertys* item = [myAppDelegate.keyDataArray objectAtIndex:i];
		
		if ([item.privateKey isEqualToString:@"-"]) {
			[externalKeys addObject:item];
		}else {
			[internalKeys addObject:item];
		}

	}
	
	NSInteger returnInteger = 0;
	
	if ([tableView tag] == 1) {
		returnInteger = [internalKeys count];
	}else {
		returnInteger = [externalKeys count];
	}

    return returnInteger;
}

-(void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSIndexSet *indexes = [myTable selectedRowIndexes];
	if ([indexes count] == 0) {
		[removeButton setEnabled:NO];
	} else {
		[removeButton setEnabled:YES];
	}
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	iRSAAppDelegate *myAppDelegate = (iRSAAppDelegate *)[[NSApplication sharedApplication] delegate];
	//KeyPropertys* item = [myAppDelegate.keyDataArray objectAtIndex:rowIndex];
	
	NSString *returnString;
	
	int max = [myAppDelegate.keyDataArray count];
	int i;
	
	for(i=rowIndex;i<max;i++){
		
		KeyPropertys* item = [myAppDelegate.keyDataArray objectAtIndex:i];
		
		if ([aTableView tag] == 1) {
			
			if ([item.privateKey isEqualToString:@"-"]) {
				continue;
			}else if (![item.privateKey isEqualToString:@"-"]) {
				if ([[aTableColumn identifier] isEqualToString:@"identifier"]){
					returnString = item.keyIdentifier;
				}else if ([[aTableColumn identifier] isEqualToString:@"publicKey"]){
					returnString = item.publicKey;
				}else if ([[aTableColumn identifier] isEqualToString:@"privateKey"]){
					returnString = item.privateKey;
				}
				[self setupKeyPopUpButton];
			}
			
		}else if ([aTableView tag] == 2){
			
			if ([item.privateKey isEqualToString:@"-"]) {
				
				if ([[aTableColumn identifier] isEqualToString:@"identifier"]){
					returnString = item.keyIdentifier;
				}else if ([[aTableColumn identifier] isEqualToString:@"publicKey"]){
					returnString = item.publicKey;
				}else if ([[aTableColumn identifier] isEqualToString:@"person"]){
					returnString = item.keyPerson;
				}
			}else if (![item.privateKey isEqualToString:@"-"]) {
				continue;
			}
			
			
		}
		
	}

	
	
	return returnString;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	
	iRSAAppDelegate *myAppDelegate = (iRSAAppDelegate *)[[NSApplication sharedApplication] delegate];
	KeyPropertys* item = [myAppDelegate.keyDataArray objectAtIndex:rowIndex];

	if ([[aTableColumn identifier] isEqualToString:@"identifier"]) {
		NSLog(@"identifier");
		item.keyIdentifier = anObject;
		[self setupKeyPopUpButton];
	}else {
		NSLog(@"person");
		item.keyPerson = anObject;

	}

	
	/*
	if ([aTableView tag] == 1) {
		if ([[aTableColumn identifier] isEqualToString:@"identifier"]) {
			[self setupKeyPopUpButton];
			item.keyIdentifier = anObject;
		}
	}else if ([aTableView tag] == 2) {
		if ([[aTableColumn identifier] isEqualToString:@"person"]) {
			item.keyPerson = anObject;
		}else if ([[aTableColumn identifier] isEqualToString:@"identifier"]) {
			[self setupKeyPopUpButton];
			item.keyIdentifier = anObject;
		}
	}
	*/
}

- (void)tabView:(NSTabView *)tabV didSelectTabViewItem:(NSTabViewItem *)tabViewItem{
	self.keyAddModeInt = [[tabViewItem identifier]intValue];
	
	if (self.keyAddModeInt == 0) {
		[keyAddEnterButton setTitle:@"Generate"];
	}else if(self.keyAddModeInt == 1){
		[keyAddEnterButton setTitle:@"Enter"];
	}

}

-(void)doubleClickToRow:(NSTableView *)sender{
	if ([sender clickedColumn] == 0){
		NSLog(@"0!");
	}else if ([sender clickedColumn] >= 1){
		iRSAAppDelegate *myAppDelegate = (iRSAAppDelegate *)[[NSApplication sharedApplication] delegate];
		KeyPropertys* item = [myAppDelegate.keyDataArray objectAtIndex:[sender clickedRow]];
		//	NSLog(@"Item Nummer: %i",[sender clickedRow]);
		//	NSLog(@"ItemIdentifier: %@",item.keyIdentifier);
		//	NSLog(@"PublicKey: %@",item.publicKey);
		[infoBox setTitle:item.keyIdentifier];
		[publicKeyView setString:item.publicKey];
		
		[NSApp beginSheet:infoSheet modalForWindow:keyTableView modalDelegate:self didEndSelector:nil contextInfo:@""];
	}
}

- (IBAction)doubleClickAction:(NSTableView *)sender {
	
	if ([sender clickedColumn] == 0){
	
	}else if ([sender clickedColumn] >= 1){
		iRSAAppDelegate *myAppDelegate = (iRSAAppDelegate *)[[NSApplication sharedApplication] delegate];
		KeyPropertys* item = [myAppDelegate.keyDataArray objectAtIndex:[sender clickedRow]];
	//	NSLog(@"Item Nummer: %i",[sender clickedRow]);
	//	NSLog(@"ItemIdentifier: %@",item.keyIdentifier);
	//	NSLog(@"PublicKey: %@",item.publicKey);
		[infoBox setTitle:item.keyIdentifier];
		[publicKeyView setString:item.publicKey];
		
		[NSApp beginSheet:infoSheet modalForWindow:keyTableView modalDelegate:self didEndSelector:nil contextInfo:@""];
	}
	
}

-(IBAction)pushDoneButton:(id)sender{
	[infoSheet orderOut:nil];
	[NSApp endSheet:infoSheet];
}

-(IBAction)pushCancelButton:(id)sender{
	[infoSheet orderOut:nil];
	[NSApp endSheet:infoSheet];
}

-(IBAction)pushShareByMailButton:(id)sender{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[[publicKeyView textStorage]string],@"publicKey",nil];
//	NSLog(@"fail: %@",[[publicKeyView textStorage]string]);
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center postNotificationName:@"sendMail" object:nil userInfo:dict];
}

@end
