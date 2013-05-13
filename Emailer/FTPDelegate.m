//
//  FTPDelegate.m
//  Emailer
//
//  Created by Joe Green on 5/13/13.
//  Copyright (c) 2013 Digilog. All rights reserved.
//

#import "FTPDelegate.h"
#import "SCRFTPRequest.h"

@implementation FTPDelegate

-(id)init {
    
    SCRFTPRequest *ftpRequest = [[SCRFTPRequest alloc] initWithURL:[NSURL URLWithString:@"crewftp.roadview.com"]
                                                      toUploadFile:[[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"]];
    
    ftpRequest.username = @"digilog";
    ftpRequest.password = @"digilog";
    
    // Specify a custom upload file name (optional)
    ftpRequest.customUploadFileName = @"App_Info.plist";
    
    // The delegate must implement the SCRFTPRequestDelegate protocol
    ftpRequest.delegate = self;
    
    [ftpRequest startRequest];
    return self;
}
// Required delegate methods
- (void)ftpRequestDidFinish:(SCRFTPRequest *)request {
    
    NSLog(@"Upload finished.");
}

- (void)ftpRequest:(SCRFTPRequest *)request didFailWithError:(NSError *)error {
    
    NSLog(@"Upload failed: %@", [error localizedDescription]);
}


@end
