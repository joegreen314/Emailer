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

- (IBAction)openMail:(UIButton *)sender {
    
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSError *err;
    
    if([MFMailComposeViewController canSendMail]) {
        
        
        MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
        picker.mailComposeDelegate = self;
        [picker setSubject:[[MailFields defaultFields] subject]];
        [picker setToRecipients:[MailFields defaultFields].recipients];
        [picker setMessageBody:[[MailFields defaultFields] body] isHTML:YES];
        [picker setCcRecipients:[[NSArray alloc] initWithObjects:@"Vehicle Technician Support <digilogsupport@mandli.com>", nil]];
        
        //Get documents directory
        NSString *documentsDirectory;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        if ([paths count] > 0) {
            documentsDirectory = [paths objectAtIndex:0];
        }

        NSArray * files = [fileMgr contentsOfDirectoryAtPath:documentsDirectory error:&err];
        
        if (files)
        {
            for(int index=0;index<files.count;index++)
            {
                NSString * file = [files objectAtIndex:index];
                
                    NSString *path = [NSString stringWithFormat:@"%@/%@", documentsDirectory,file ];
                    NSData *data = [NSData dataWithContentsOfFile:path];
                    [picker addAttachmentData:data mimeType:@"error/zip" fileName:file];
            }
            [self refreshFiles];
            [self presentViewController:picker animated:YES completion:nil];
            
        }
        
    }
    
}
-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult: (MFMailComposeResult)result error: (NSError*)error {
    if(result==MFMailComposeResultSent)
    {
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
    self.files=nil;
    self.files=[[NSMutableArray alloc]init];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *documentsDirectory;
    NSArray *p = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if ([p count] > 0) {
        documentsDirectory = [p objectAtIndex:0];
    }
    
    NSArray * fileNames = [fileMgr contentsOfDirectoryAtPath:documentsDirectory error:nil];
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
    if (cell == nil) {
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
