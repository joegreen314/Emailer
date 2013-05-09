//
//  SettingsViewController.h
//  Emailer
//
//  Created by Joe Green on 5/2/13.
//  Copyright (c) 2013 Digilog. All rights reserved.
//

#import <UIKit/UIKit.h>@protocol SettingsViewControllerDelegate;

@interface SettingsViewController : UITableViewController
@end

@protocol SettingsViewControllerDelegate <NSObject>

@required

-(void)dismissPop:(NSString*)value;

@end