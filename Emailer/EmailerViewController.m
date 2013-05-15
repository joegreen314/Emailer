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
#import "FTPController.h"

@interface EmailerViewController()
<UITableViewDelegate, UITableViewDataSource, FTPControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *ftpButton;
@property (weak, nonatomic) IBOutlet UIButton *mailSettingsButton;
@property (weak, nonatomic) IBOutlet UIButton *sendEmailButton;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteFilesButton;

@property (nonatomic) NSMutableArray *files;
@property (nonatomic, assign) UITableView* tableView;
@property (nonatomic, readwrite)  NSMutableArray *fileArray;


@end

@implementation EmailerViewController

@synthesize fileList;
@synthesize svc;
@synthesize currentPopoverSegue;
FTPController *fileSender;

- (void)viewDidLoad
{
    [self refreshFiles];
}

- (void)enableButtons {
    if([self files].count>0) {
        self.sendEmailButton.enabled = YES;
        self.sendEmailButton.alpha=1;
        self.deleteFilesButton.enabled = YES;
        self.deleteFilesButton.alpha=1;
        self.ftpButton.enabled = YES;
        self.ftpButton.alpha=1;
    }
    else {
        self.sendEmailButton.enabled = NO;
        self.sendEmailButton.alpha=.5;
        self.deleteFilesButton.enabled = NO;
        self.deleteFilesButton.alpha=.5;
        self.ftpButton.enabled = NO;
        self.ftpButton.alpha=.5;
    }
    self.mailSettingsButton.enabled = YES;
    self.mailSettingsButton.alpha=1;
    self.refreshButton.enabled = YES;
    self.refreshButton.alpha=1;
}

-(void)disableButtons {
    self.sendEmailButton.enabled = NO;
    self.sendEmailButton.alpha=.5;
    self.ftpButton.enabled = NO;
    self.ftpButton.alpha=.5;
    self.deleteFilesButton.enabled = NO;
    self.deleteFilesButton.alpha=.5;
    self.refreshButton.enabled = NO;
    self.refreshButton.alpha=.5;
    self.mailSettingsButton.enabled = NO;
    self.mailSettingsButton.alpha=.5;
}

- (IBAction)refreshButton:(UIButton *)sender {
    [self disableButtons];
    [self refreshFiles];
}

- (IBAction)deleteButton:(id)sender {
    [self deleteFiles];
}

- (IBAction)settingsButton:(id)sender {
}

- (IBAction)ftpButton:(UIButton *)sender {
    [self disableButtons];
    fileSender = [[FTPController alloc]init];
    fileSender.delegate = self;
    [fileSender beginFTPTransfer:self.files];
}

- (IBAction)emailButton:(UIButton *)sender {
    [self disableButtons];
    [self sendMailwithFiles:YES];
}

-(void)finishFTPTransfer{
    NSLog(@"FTP transfer complete");
    [self sendMailwithFiles:NO];
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
}


-(void) sendMailwithFiles:(BOOL) includeAttachments {
    if([MFMailComposeViewController canSendMail]) {
        
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
        [mailer setSubject:[[MailFields defaultFields] subject]];
        [mailer setToRecipients:[MailFields defaultFields].recipients];
        [mailer setMessageBody:[[MailFields defaultFields] body] isHTML:YES];
        [mailer setCcRecipients:[[NSArray alloc] initWithObjects:@"Vehicle Technician Support <digilogsupport@mandli.com>", nil]];
        if(includeAttachments){
            for(FileInfo *file in self.files) {
                NSString *path = [NSString stringWithFormat:@"%@", file.filePath ];
                NSData *data = [NSData dataWithContentsOfFile:path];
                [mailer addAttachmentData:data mimeType:@"error/zip" fileName:file.name];
            }
        }
        else{
            NSString *filesSent=@"";
            for(FileInfo *file in self.files){
                filesSent = [NSString stringWithFormat:@"%@<br />%@",filesSent,[file name]];
            }
            NSString *body=[NSString stringWithFormat:@"%@<br /><br />FilesSent:%@", [[MailFields defaultFields] body],filesSent];
            [mailer setMessageBody:body isHTML:YES];
        }
        
        [self presentViewController:mailer animated:YES completion:nil];
    }
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult: (MFMailComposeResult)result error: (NSError*)error {
    if(result==MFMailComposeResultSent){
        [self deleteFiles];
    }
    else {
        [self refreshFiles];
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
            NSString* path =[NSString stringWithFormat:@"%@/%@", documentsDirectory, fileName];
            int size = [[fileMgr attributesOfItemAtPath: path error: NULL] fileSize];
            FileInfo *file = [[FileInfo alloc]initFile:fileName inDirectory:documentsDirectory withSize:size];
            [self.files addObject:file];
        }
    }
    
    self.fileArray=[self.files copy];
    [self.tableView reloadData];
    [self.fileList reloadData];
    [self enableButtons];
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
    NSString *fname = [[self.fileArray objectAtIndex:indexPath.row] name];
    NSString *size = [[self.fileArray objectAtIndex:indexPath.row] fsize];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)",fname,size];
    //cell.textLabel.text = [[self.fileArray objectAtIndex:indexPath.row] name];
    return cell;
}

- (void)viewDidUnload {
    [self setSendEmailButton:nil];
    [self setFileArray:nil];
    [self setRefreshButton:nil];
    [self setFileList:nil];
    [self setDeleteFilesButton:nil];
    [self setFtpButton:nil];
    [self setMailSettingsButton:nil];
    [super viewDidUnload];
}
@end
