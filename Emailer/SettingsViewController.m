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

@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *toFields;
@property (weak, nonatomic) IBOutlet UITextField *subjectField;
@property (weak, nonatomic) IBOutlet UITextView *bodyField;
@property (weak, nonatomic) IBOutlet UITextField *urlField0;
@property (weak, nonatomic) IBOutlet UITextField *urlField1;
@property (weak, nonatomic) IBOutlet UITextField *urlField2;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@property (weak, nonatomic) IBOutlet UISwitch *ftpSwitch;


@property (weak, nonatomic) IBOutlet UIToolbar *saveButton;
@property (strong, nonatomic) UIPopoverController *popover;

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
    self.subjectField.text=[[MailFields defaultFields] subject];
    self.bodyField.text=[[MailFields defaultFields] body];
    self.urlField0.text=[[[MailFields defaultFields] url] objectAtIndex:0];
    self.urlField1.text=[[[MailFields defaultFields] url] objectAtIndex:1];
    self.urlField2.text=[[[MailFields defaultFields] url] objectAtIndex:2];
    
    MailFields *test = [MailFields defaultFields];
    if([test ftp]==NO){
        [self.ftpSwitch setOn:NO];
    //[self.ftpSwitch setOn:[[MailFields defaultFields] ftp]];
    }
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
- (IBAction)saveSettings:(UIBarButtonItem *)sender {
    [MailFields setSubject:[MailFields sanitize:self.subjectField.text]];
    [MailFields setBody:[MailFields sanitize:self.bodyField.text]];
    NSMutableArray *recipientFields = [[NSMutableArray alloc]init];
    for(UITextField *field in self.toFields) {
        [recipientFields addObject:[MailFields sanitize:field.text]];
    }
    [MailFields setRecipients:recipientFields];
    NSMutableArray *urlFields = [[NSMutableArray alloc]initWithObjects:
                                 self.urlField0.text,
                                 [MailFields sanitize:self.urlField1.text],
                                 [MailFields sanitize:self.urlField2.text], nil];
    [MailFields setUrl:urlFields];
    [MailFields setUsername:self.usernameField.text];
    [MailFields setPassword:self.passwordField.text];
    
    [MailFields setFtpStatus:self.ftpSwitch.on];
    
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if(section==0){
        return 3;
    }
    else{
        return 3;
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"Nib name" bundle:nil];
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
    [self setUrlField0:nil];
    [self setUrlField1:nil];
    [self setUrlField2:nil];
    [self setUsernameField:nil];
    [self setPasswordField:nil];
    [self setFtpSwitch:nil];
    [super viewDidUnload];
}
@end
