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

@property (nonatomic, strong, readwrite) NSOutputStream *  writeStream;
@property (nonatomic, strong, readwrite) NSInputStream *   readStream;

@property (nonatomic, assign, readonly ) uint8_t *         buffer;
@property (nonatomic, assign, readwrite) size_t            bufferOffset;
@property (nonatomic, assign, readwrite) size_t            bufferLimit;
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

-(void)beginFTPTransfer:(NSMutableArray*)files {
    
    self.files=files;
    self.currFile=0;
    self.currDir=0; //Number of directories created so far
    self.numDir=2; //Must create two directories
    [self createNewDir];
}

-(void)createNewDir{
    switch (self.currDir){
        case 0:{
            NSString* addr=@"ftp://jgreen:j0egr33n@fezzik.mandli.com/Digilog/Test/";
            NSString *deviceName = [[UIDevice currentDevice]name];
            self.path = [NSString stringWithFormat:@"%@%@/", addr, deviceName];
            NSLog(@"RUNNING CASE 0");
        } break;
        case 1:{
            NSString *date = [self getDate];
            self.path = [NSString stringWithFormat:@"%@%@/", self.path, date];
            NSLog(@"RUNNING CASE 1");
        } break;
    }
    self.currDir++;
    NSLog(@"Creating dir: %@", self.path);
    [self sendTo:self.path from:nil];
}

-(void)sendNextFile{
    NSString *file=[[self.files objectAtIndex:self.currFile]filePath];
    NSString *fileName = [[self.files objectAtIndex:self.currFile]name];
    NSString *dest = [NSString stringWithFormat:@"%@%@", self.path, fileName];
    self.currFile++;
    
    NSLog(@"Sending file: %@ to ftpserver: %@" ,file, dest);
    [self sendTo:dest from:file];
}

-(void)endFTPTransfer{
    [delegate performSelector:@selector(finishFTPTransfer)];
}

-(NSString*)getDate{
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
            [self stopSendWithStatus:nil];
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
    if(self.currDir!=self.numDir){
        [self createNewDir];
    }
    else if(self.currFile<[self.files count]){
        [self sendNextFile];
    }
    else
        [self endFTPTransfer];
    //[self sendDidStopWithStatus:statusString];
}



@end
