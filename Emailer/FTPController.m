//
//  FTPController.m
//  Emailer
//
//  Created by Joe Green on 5/14/13.
//  Copyright (c) 2013 Digilog. All rights reserved.
//

#import "FTPController.h"
#include <CFNetwork/CFNetwork.h>


@interface FTPController ()

@property (nonatomic) NSMutableArray* files;
@property (nonatomic) int currFile;
@property (nonatomic) int currDir; //directories we've created
@property (nonatomic) int numDir; //directories we must create before adding new files
@property (nonatomic) NSString* path;

@property BOOL cancel;
@property int totalSize;
@property int currSize;
@property int currProgress;

@property (nonatomic, strong, readwrite) NSOutputStream *  writeStream;
@property (nonatomic, strong, readwrite) NSInputStream *   readStream;

@property (nonatomic, assign, readonly ) uint8_t *         buffer;
@property (nonatomic, assign, readwrite) size_t            bufferOffset;
@property (nonatomic, assign, readwrite) size_t            bufferLimit;
@property (nonatomic) NSString* status;

@end

@implementation FTPController
{
    uint8_t                     _buffer[32768];
}
@synthesize delegate;

- (uint8_t *)buffer
{
    return self->_buffer;
}

-(id)init {
    self = [super init];
    return self;
}

-(NSString*)getStatus {
    return self.status;
}

-(void)beginFTPTransfer:(NSMutableArray*)files {
    self.cancel=NO;
    self.status=@"";
    self.files=files;
    self.currFile=0;
    self.currDir=0; //Number of directories created so far
    self.numDir=4; //Must create four directories
    [self initProgress];
    
    [self createNewDir];
}

-(void)createNewDir{
    
    if(self.cancel){
        [self endFTPTransfer];
        NSLog(@"1");
        return;
    }
    switch (self.currDir){ //Format directories, then add them one at a time
        case 0:{
            //ftp://jgreen:j0egr33n@fezzik.mandli.com/StatenameDOT/
            self.path = [NSString stringWithFormat:@"ftp://%@/%@/",
                         [[[MailFields defaultFields] url] objectAtIndex:0],
                         [[[MailFields defaultFields] url] objectAtIndex:1]];
            //NSLog(@"RUNNING CASE 0");
        } break;
        case 1:{
            self.path = [NSString stringWithFormat:@"%@%@/", self.path,
                         [[[MailFields defaultFields] url] objectAtIndex:2]];
            //NSLog(@"RUNNING CASE 1");
        } break;
        case 2:{
            NSString *deviceName = [[UIDevice currentDevice]name];
            self.path = [NSString stringWithFormat:@"%@%@/", self.path, deviceName];
            //NSLog(@"RUNNING CASE 2");
        } break;
        case 3:{
            NSString *date = [FTPController getDate];
            self.path = [NSString stringWithFormat:@"%@%@/", self.path, date];
            self.fullPath=[self.path copy];
            //NSLog(@"RUNNING CASE 3");
        } break;
    }
    self.currDir++;
    NSLog(@"Creating dir: %@", self.path);
    [self sendTo:self.path from:nil];
}

-(void)sendNextFile{
    if(self.cancel){
        [self endFTPTransfer];
        
        NSLog(@"2");
        return;
    }
    NSString *file=[[self.files objectAtIndex:self.currFile]filePath];
    NSString *fileName = [[self.files objectAtIndex:self.currFile]name];
    NSString *dest = [NSString stringWithFormat:@"%@%@", self.path, fileName];
    self.currSize = [(FileInfo*)[self.files objectAtIndex:self.currFile] size];
    self.currFile++;
    
    NSLog(@"Sending file: %@ to ftpserver: %@" ,file, dest);
    [self sendTo:dest from:file];
}

-(void)endFTPTransfer{
    [delegate performSelector:@selector(finishFTPTransfer)];
    
}

-(void)cancelFTPTransfer{
    self.cancel=YES;
    self.status=@"Transfer cancelled";
    [self endFTPTransfer];
}

-(void)initProgress{
    self.totalSize=4+[self.files count];
    //for(FileInfo *file in self.files){
    //    self.totalSize += (int)[file size];
    //}
}

-(void)updateProgress{
    self.currProgress++;
    //self.currProgress += self.currSize;
    //NSNumber* progress = [NSNumber numberWithFloat:(float)self.currProgress / (float)self.totalSize];
    NSNumber* progress = [NSNumber numberWithFloat:(float)self.currProgress/self.totalSize];
    [delegate performSelector:@selector(updateFTPProgress:) withObject:(id)progress];
}

+(NSString*)getDate{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy_MM_dd";
    NSString *result = [formatter stringFromDate:[NSDate date]];
    return result;
}

-(void)sendTo:(NSString *)destPath from:(NSString *)devicePath {
    
    if(devicePath){
        self.readStream = [NSInputStream inputStreamWithFileAtPath:devicePath];
        [self.readStream open];
    }
    
    NSURL* url = [NSURL URLWithString:destPath];
    self.writeStream = CFBridgingRelease(
                                         CFWriteStreamCreateWithFTPURL(NULL, (__bridge CFURLRef) url)
                                         );
    if(self.writeStream == nil){
        self.status=@"Transfer failed! Bad URL";
        [self endFTPTransfer];
        
        NSLog(@"3");
        return;
    }
    
    if ([[MailFields defaultFields] user] != 0) {
        BOOL success = [self.writeStream setProperty:[[MailFields defaultFields] user] forKey:(id)kCFStreamPropertyFTPUserName];
        assert(success);
        success = [self.writeStream setProperty:[[MailFields defaultFields] pass] forKey:(id)kCFStreamPropertyFTPPassword];
        assert(success);
    }
    
    self.writeStream.delegate = self;
    [self.writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.writeStream open];
    
    // Tell the UI we're sending.
    
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
// An NSStream delegate callback that's called when events happen on our
// network stream.
{
    
    if(self.cancel){
        [self stopSendWithStatus:nil];
        return;
    }
    assert(aStream == self.writeStream);
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            NSLog(@"OpenCompleted");
        } break;
        case NSStreamEventHasBytesAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventHasSpaceAvailable: {
            NSLog(@"HasSpaceAvailable");
            // If we don't have any data buffered, go read the next chunk of data.
            
            if (self.bufferOffset == self.bufferLimit) {
                NSInteger   bytesRead;
                
                bytesRead = [self.readStream read:self.buffer maxLength:32768];
                
                if (bytesRead == -1) {
                    [self stopSendWithStatus:@"Transfer failed! File read error"];
                    NSLog(@"1");
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
                    [self stopSendWithStatus:@"Transfer failed! Network write error"];
                } else {
                    self.bufferOffset += bytesWritten;
                }
            }
        } break;
        case NSStreamEventErrorOccurred: {
            [self stopSendWithStatus:@"Transfer failed! Stream open error"];
        } break;
        case NSStreamEventEndEncountered: {
            NSLog(@"EndEncountered");
            //This case runs when we are creating a directory
            [self stopSendWithStatus:nil];
        } break;
        default: {
            assert(NO);
        } break;
    }
}

- (void)stopSendWithStatus:(NSString *)statusString
{
    self.status=statusString;
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
    
    if(self.cancel){
        return;
    }
    else{
        [self updateProgress];
    }
    
    if(self.currDir!=self.numDir){
        [self createNewDir];
    }
    else if(self.currFile<[self.files count]){
        [self sendNextFile];
    }
    else {
        [self endFTPTransfer];
    }
    //[self sendDidStopWithStatus:statusString];
}



@end
