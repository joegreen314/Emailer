//
//  EmailerViewController.m
//  Emailer
//
//  Created by Joe Green on 4/17/13.
//  Copyright (c) 2013 Digilog. All rights reserved. hhkkjhjk
// test test test

#import "EmailerViewController.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "FileInfo.h"
#import "MailFields.h"
#import "FTPController.h"

@interface EmailerViewController()
<FTPControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *ftpButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *mailSettingsButton;
@property (weak, nonatomic) IBOutlet UIButton *sendEmailButton;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteFilesButton;

@property (nonatomic) NSMutableArray *files;
@property (nonatomic, assign) UITableView* tableView;
@property (nonatomic, readwrite)  NSMutableArray *fileArray;
@property (strong, nonatomic) NSString* status;
@property (nonatomic) BOOL ftpFlag;
@property (nonatomic) NSString* ftpDir;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;



@end

@implementation EmailerViewController

@synthesize fileList;
@synthesize svc;
@synthesize currentPopoverSegue;
FTPController *fileSender;

- (void)viewDidLoad
{
    [MailFields defaultFields];
    [self refreshFiles];
}

- (void)enableButtons {
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
    if(![[MailFields defaultFields]ftp]){
        self.ftpButton.enabled = NO;
        self.ftpButton.alpha=0;
    }
    else if([self files].count>0){
        self.ftpButton.enabled = YES;
        self.ftpButton.alpha=1;
    }
    else{
        self.ftpButton.enabled = NO;
        self.ftpButton.alpha=.5;
    }
    
    self.mailSettingsButton.enabled = YES;
    //self.mailSettingsButton.alpha=1;
    self.refreshButton.enabled = YES;
    self.refreshButton.alpha=1;
    self.statusLabel.text=self.status;
}

-(void)disableButtons {
    self.sendEmailButton.enabled = NO;
    self.sendEmailButton.alpha=.5;
    if([[MailFields defaultFields]ftp]){
    self.ftpButton.enabled = NO;
    self.ftpButton.alpha=.5;
    }
    self.deleteFilesButton.enabled = NO;
    self.deleteFilesButton.alpha=.5;
    self.refreshButton.enabled = NO;
    self.refreshButton.alpha=.5;
    self.mailSettingsButton.enabled = NO;
    //self.mailSettingsButton.alpha=.5;
}

- (IBAction)refreshButton:(UIButton *)sender {
    [self disableButtons];
    [self refreshFiles];
    [self updateStatus:[NSString stringWithFormat:@"%@ found.",[self getNumFiles]] withError:NO];
    [self enableButtons];
}

- (IBAction)deleteButton:(id)sender {
    [self updateStatus:[NSString stringWithFormat:@"%@ deleted.",[self getNumFiles]] withError:NO];
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

- (IBAction)takePicture:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImagePNGRepresentation(image);
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[self getUniqueImageName]];
    [imageData writeToFile:filePath atomically:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self refreshFiles];
}

-(NSString*) getUniqueImageName {
    int num=0;
    BOOL Done = NO;
    while (!Done){
        for(FileInfo *file in self.files){
            if([file.name isEqualToString:[NSString stringWithFormat:@"image_%d.png",num]]){
                num++;
                break;
            }
        }
        break;
    }
    return [NSString stringWithFormat:@"image_%d.png",num];
}

-(void)updateStatus:(NSString*)status withError:(BOOL)Error{
    if(Error){
        self.status=[NSString stringWithFormat:@"%@ Error: %@",[EmailerViewController getTime], status];
    }
    else{
        self.status=[NSString stringWithFormat:@"%@ : %@",[EmailerViewController getTime], status];
    }
    NSLog(@"%@",self.status);
}

+(NSString*)getTime{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"h:mm a";
    NSString *result = [formatter stringFromDate:[NSDate date]];
    return result;
}

-(void)finishFTPTransfer{
    self.ftpDir=[fileSender.fullPath copy];
    if([fileSender getStatus]){
        [self updateStatus:[fileSender getStatus] withError:YES];
        [self refreshFiles];
    }
    else{
        [self updateStatus:[NSString stringWithFormat:@"Success! %@ sent via FTP.",[self getNumFiles]]withError:NO];
        [self sendMailwithFiles:NO];
    }
}
-(NSString*)getNumFiles{
    
    NSNumber *fileCount = [NSNumber numberWithLong:(unsigned long)[self.files count]];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterSpellOutStyle];
    NSString *strFileCount = [[numberFormatter stringFromNumber:fileCount] capitalizedString];
    if([strFileCount isEqualToString:(@"Zero")])
        strFileCount=@"No";
    
    NSString *numFiles;
    if([self.files count]==1)
        numFiles =[NSString stringWithFormat:@"%@ file",strFileCount];
    else
        numFiles =[NSString stringWithFormat:@"%@ files",strFileCount];
    return numFiles;
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue identifier]isEqualToString:@"openSettings"]){
        currentPopoverSegue = (UIStoryboardPopoverSegue *)segue;
        svc = [segue destinationViewController];
        [svc setDelegate:self];
    }
}

-(void)dismissPop{
    [self enableButtons];
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
            NSString *body=[NSString stringWithFormat:@"%@<br />Directory: %@<br />FilesSent:%@", [[MailFields defaultFields] body],self.ftpDir,filesSent];
            [mailer setMessageBody:body isHTML:YES];
            self.ftpFlag=YES;
            
        }
        
        [self presentViewController:mailer animated:YES completion:nil];
    }
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult: (MFMailComposeResult)result error: (NSError*)error {
    if(result==MFMailComposeResultSent){
        if(!self.ftpFlag)
            [self updateStatus:[NSString stringWithFormat:@"Message sent to outbox.  %@ deleted.", [self getNumFiles]] withError:NO];
        [self deleteFiles];
    }
    else if(result==MFMailComposeResultCancelled){
        if(!self.ftpFlag)
            [self updateStatus:@"Message cancelled." withError:NO];
        [self enableButtons];
    }
    else if(result==MFMailComposeResultSaved){
        if(!self.ftpFlag)
            [self updateStatus:@"Message saved." withError:NO];
        [self enableButtons];
    }
    else if(result==MFMailComposeResultFailed){
        if(!self.ftpFlag)
            [self updateStatus:@"Message failed." withError:NO];
        [self enableButtons];
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
- (BOOL)ShouldAutoRotate
{
    return NO;
}
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}
- (void)viewDidUnload {
    [self setSendEmailButton:nil];
    [self setFileArray:nil];
    [self setRefreshButton:nil];
    [self setFileList:nil];
    [self setDeleteFilesButton:nil];
    [self setFtpButton:nil];
    [self setMailSettingsButton:nil];
    [self setStatusLabel:nil];
    [self setMailSettingsButton:nil];
    [super viewDidUnload];
}
- (IBAction)useCamera:(id)sender {
}
@end
