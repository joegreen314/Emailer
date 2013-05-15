//
//  FTPController.h
//  Emailer
//
//  Created by Joe Green on 5/14/13.
//  Copyright (c) 2013 Digilog. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FileInfo.h"
#import "MailFields.h"

@protocol FTPControllerDelegate <NSObject>

-(void) finishFTPTransfer;

@end

@interface FTPController : NSObject <NSStreamDelegate> {
    id <FTPControllerDelegate> delegate;
}
-(id)init;
-(void)sendTo:(NSString *)destPath from:(NSString *)devicePath;

@property (nonatomic) id<FTPControllerDelegate> delegate;

-(void)beginFTPTransfer:(NSMutableArray*)files;

@end
