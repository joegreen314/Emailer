//
//  EmailerViewController.h
//  Emailer
//
//  Created by Joe Green on 4/17/13.
//  Copyright (c) 2013 Digilog. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "SettingsViewController.h"

@interface EmailerViewController : UIViewController <MFMailComposeViewControllerDelegate,UITableViewDelegate,UITableViewDataSource, SettingsViewControllerDelegate, UIPopoverControllerDelegate, NSStreamDelegate>


@property (strong, nonatomic) IBOutlet UITableView *fileList;
@property (nonatomic, readonly) NSMutableArray *fileArray;

@property (strong, nonatomic) UIStoryboardPopoverSegue *currentPopoverSegue;
@property (strong, nonatomic) SettingsViewController *svc;
@end
