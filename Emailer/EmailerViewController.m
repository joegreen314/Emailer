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
#include <CFNetwork/CFNetwork.h>

@interface EmailerViewController()
<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) NSMutableArray *files;
@property (weak, nonatomic) IBOutlet UIButton *sendEmailButton;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteFilesButton;

@property (nonatomic, assign) UITableView* tableView;
@property (nonatomic, readwrite)  NSMutableArray *fileArray;


@property (nonatomic, strong, readwrite) NSOutputStream *  writeStream;
@property (nonatomic, strong, readwrite) NSInputStream *   readStream;

@property (nonatomic, assign, readonly ) uint8_t *         buffer;
@property (nonatomic, assign, readwrite) size_t            bufferOffset;
@property (nonatomic, assign, readwrite) size_t            bufferLimit;

@end

@implementation EmailerViewController
{
    uint8_t                     _buffer[32768];
}

- (uint8_t *)buffer
{
    return self->_buffer;
}

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



- (IBAction)ftpButton:(UIButton *)sender {
    NSString *dest=@"ftp://jgreen:j0egr33n@fezzik.mandli.com/Digilog/Test/test.txt";
    NSString *file=[[self.files objectAtIndex:0]filePath];
    
    [self sendTo:dest from:file];
    }

-(void)sendTo:(NSString *)destPath from:(NSString *)devicePath {
    
    self.readStream = [NSInputStream inputStreamWithFileAtPath:devicePath];
    [self.readStream open];
    
    NSURL* url = [NSURL URLWithString:destPath];
    self.writeStream = CFBridgingRelease(
                                           CFWriteStreamCreateWithFTPURL(NULL, (__bridge CFURLRef) url)
                                           );
    assert(self.writeStream != nil);
    
    //if ([self.usernameText.text length] != 0) {
    //    success = [self.networkStream setProperty:self.usernameText.text forKey:(id)kCFStreamPropertyFTPUserName];
    //    assert(success);
    //    success = [self.networkStream setProperty:self.passwordText.text forKey:(id)kCFStreamPropertyFTPPassword];
    //    assert(success);
    //}
    
    self.writeStream.delegate = self;
    [self.writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.writeStream open];
    
    // Tell the UI we're sending.
    
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
// An NSStream delegate callback that's called when events happen on our
// network stream.
{
#pragma unused(aStream)
    assert(aStream == self.writeStream);
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            //[self updateStatus:@"Opened connection"];
        } break;
        case NSStreamEventHasBytesAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventHasSpaceAvailable: {
            //[self updateStatus:@"Sending"];
            
            // If we don't have any data buffered, go read the next chunk of data.
            
            if (self.bufferOffset == self.bufferLimit) {
                NSInteger   bytesRead;
                
                bytesRead = [self.readStream read:self.buffer maxLength:32768];
                
                if (bytesRead == -1) {
                    //[self stopSendWithStatus:@"File read error"];
                } else if (bytesRead == 0) {
                    [self stopSendWithStatus:nil];
                } else {
                    self.bufferOffset = 0;
                    self.bufferLimit  = bytesRead;
                }
            }
            
            // If we're not out of data completely, send the next chunk.
            
            if (self.bufferOffset != self.bufferLimit) {
                NSInteger   bytesWritten;
                bytesWritten = [self.writeStream write:&self.buffer[self.bufferOffset] maxLength:self.bufferLimit - self.bufferOffset];
                assert(bytesWritten != 0);
                if (bytesWritten == -1) {
                    [self stopSendWithStatus:@"Network write error"];
                } else {
                    self.bufferOffset += bytesWritten;
                }
            }
        } break;
        case NSStreamEventErrorOccurred: {
            [self stopSendWithStatus:@"Stream open error"];
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }
}

- (void)stopSendWithStatus:(NSString *)statusString
{
    if (self.writeStream != nil) {
        [self.writeStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.writeStream.delegate = nil;
        [self.writeStream close];
        self.writeStream = nil;
    }
    if (self.readStream != nil) {
        [self.readStream close];
        self.readStream = nil;
    }
    //[self sendDidStopWithStatus:statusString];
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
            NSString* path =[NSString stringWithFormat:@"%@/%@", documentsDirectory, fileName];
            int size = [[fileMgr attributesOfItemAtPath: path error: NULL] fileSize];
            FileInfo *file = [[FileInfo alloc]initFile:fileName inDirectory:documentsDirectory withSize:size];
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
    [super viewDidUnload];
}
@end
