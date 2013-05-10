//
//  EmailerViewController.m
//  Emailer
//
//  Created by Joe Green on 4/17/13.
//  Copyright (c) 2013 Digilog. All rights reserved.
// test test test

#import "EmailerViewController.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "FileInfo.h"
#import "MailFields.h"

@interface EmailerViewController()
<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) NSMutableArray *files;
@property (weak, nonatomic) IBOutlet UIButton *sendEmailButton;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteFilesButton;

@property (nonatomic, assign) UITableView* tableView;
@property (nonatomic, readwrite)  NSMutableArray *fileArray;

@end

@implementation EmailerViewController

@synthesize fileList;
@synthesize svc;
@synthesize currentPopoverSegue;

- (void)viewDidLoad
{
    [self refreshFiles];
}

- (void)updateButtons {
    if([self files].count>0) {
        self.sendEmailButton.enabled = YES;
        self.sendEmailButton.alpha=1;
        self.deleteFilesButton.enabled = YES;
        self.deleteFilesButton.alpha=1;
    }
    else {
        self.sendEmailButton.enabled = NO;
        self.sendEmailButton.alpha=.5;
        self.deleteFilesButton.enabled = NO;
        self.deleteFilesButton.alpha=.5;
    }
}

- (IBAction)refreshButton:(UIButton *)sender {
    [self refreshFiles];
}

- (IBAction)deleteButton:(id)sender {
    [self deleteFiles];
}

- (IBAction)settingsButton:(id)sender {
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue identifier]isEqualToString:@"openSettings"]){
        currentPopoverSegue = (UIStoryboardPopoverSegue *)segue;
        svc = [segue destinationViewController];
        [svc setDelegate:self];
    }
}
-(void)dismissPop{
    [[currentPopoverSegue popoverController] dismissPopoverAnimated:YES];
    //dismiss the popover
}

- (IBAction)openMail:(UIButton *)sender {
    
    if([MFMailComposeViewController canSendMail]) {
        
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
        [mailer setSubject:[[MailFields defaultFields] subject]];
        [mailer setToRecipients:[MailFields defaultFields].recipients];
        [mailer setMessageBody:[[MailFields defaultFields] body] isHTML:YES];
        [mailer setCcRecipients:[[NSArray alloc] initWithObjects:@"Vehicle Technician Support <digilogsupport@mandli.com>", nil]];
        
        for(FileInfo *file in self.files) {
            NSString *path = [NSString stringWithFormat:@"%@", file.filePath ];
            NSData *data = [NSData dataWithContentsOfFile:path];
            [mailer addAttachmentData:data mimeType:@"error/zip" fileName:file.name];
        }
        
        [self presentViewController:mailer animated:YES completion:nil];
    }
}
-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult: (MFMailComposeResult)result error: (NSError*)error {
    if(result==MFMailComposeResultSent){
        [self deleteFiles];
    }
    [self dismissModalViewControllerAnimated:YES];
}

-(void)deleteFiles {
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSError *err;
    if(self.files.count) {
        for(int index=0; index<self.files.count; index++){
            NSString *tempPath = ((FileInfo*)[self.files objectAtIndex:(index)]).filePath;
            [fileMgr removeItemAtPath:tempPath error:&err];
        }
    }
    [self refreshFiles];
}


-(void)refreshFiles {
    [self.files removeAllObjects];
    self.files = [[NSMutableArray alloc] init];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *documentsDirectory;
    NSArray * fileNames;
    NSArray *p = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if ([p count]) {
        documentsDirectory = [p objectAtIndex:0];
        fileNames = [fileMgr contentsOfDirectoryAtPath:documentsDirectory error:nil];
    }
    if (fileNames) {
        for(int index = 0; index<fileNames.count; index++) {
            NSString * fileName = [fileNames objectAtIndex:index];
            FileInfo *file = [[FileInfo alloc]initFile:fileName inDirectory:documentsDirectory withSize:@" "];
            [self.files addObject:file];
        }
    }
    
    self.fileArray=[self.files copy];
    [self.tableView reloadData];
    [self.fileList reloadData];
    [self updateButtons];
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.fileArray count];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = [[self.fileArray objectAtIndex:indexPath.row] name];
    
    return cell;
}

- (void)viewDidUnload {
    [self setSendEmailButton:nil];
    [self setFileArray:nil];
    [self setRefreshButton:nil];
    [self setFileList:nil];
    [self setDeleteFilesButton:nil];
    [super viewDidUnload];
}
@end
