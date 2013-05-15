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

+(void)setRecipients:(NSMutableArray*)recipients;
+(void)setSubject:(NSString*)subject;
+(void)setBody:(NSString*)body;
+(void)setUrl:(NSMutableArray*)url;
+(void)setUsername:(NSString*)user;
+(void)setPassword:(NSString*)pass;

@property (nonatomic,strong) NSArray *recipients;
@property (nonatomic,strong) NSString *subject;
@property (nonatomic,strong) NSString *body;
@property (nonatomic,strong) NSMutableArray *url;
@property (nonatomic,strong) NSString *user;
@property (nonatomic,strong) NSString *pass;



@end
