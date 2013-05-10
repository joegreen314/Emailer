//
//  SettingsViewController.m
//  Emailer
//
//  Created by Joe Green on 5/2/13.
//  Copyright (c) 2013 Digilog. All rights reserved.
//

#import "SettingsViewController.h"
#import "MailFields.h"

@interface SettingsViewController ()
@property (weak, nonatomic) IBOutlet UITextField *subjectField;
@property (weak, nonatomic) IBOutlet UITextView *bodyField;
@property (weak, nonatomic) IBOutlet UIToolbar *saveButton;
@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *toFields;

@end

@implementation SettingsViewController
@synthesize delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _popover = [[UIPopoverController alloc] initWithContentViewController:self];
    int index=0;
    for(UITextField *field in self.toFields) {
        if([[[MailFields defaultFields] recipients] count]>index) {
            field.text=[[[MailFields defaultFields] recipients] objectAtIndex:index];
            index++;
        }
    }
    //self.toField.text=[[MailFields defaultFields] recipients][0];
    self.subjectField.text=[[MailFields defaultFields] subject];
    self.bodyField.text=[[MailFields defaultFields] body];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
- (IBAction)saveSettings:(UIBarButtonItem *)sender {
    [MailFields setSubject:self.subjectField.text];
    [MailFields setBody:self.bodyField.text];
    NSMutableArray *recipientFields = [[NSMutableArray alloc]init];
    for(UITextField *field in self.toFields) {
        [recipientFields addObject:field.text];
    }
    [MailFields setRecipients:recipientFields];
    //[MailFields setRecipients:self.toField.text];
    
    [delegate dismissPop];
}
- (IBAction)cancelButton:(id)sender {
    [delegate dismissPop];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 3;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (void)viewDidUnload {
    [self setSubjectField:nil];
    [self setBodyField:nil];
    [self setSaveButton:nil];
    [self setToFields:nil];
    [super viewDidUnload];
}
@end
