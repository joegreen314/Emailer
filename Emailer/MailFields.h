//
//  MailFields.h
//  Emailer
//
//  Created by Joe Green on 5/2/13.
//  Copyright (c) 2013 Digilog. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MailFields : NSObject
+(MailFields*)defaultFields;
+(void)setSubject:(NSString*)subject;
+(void)setBody:(NSString*)body;
+(void)setRecipients:(NSMutableArray*)recipients;

@property (nonatomic,strong) NSArray *recipients;
@property (nonatomic,strong) NSString *subject;
@property (nonatomic,strong) NSString *body;


@end
