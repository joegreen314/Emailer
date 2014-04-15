//
//  MailFields.m
//  Emailer
//
//  Created by Joe Green on 5/2/13.
//  Copyright (c) 2013 Digilog. All rights reserved.
//

#import "MailFields.h"

@interface MailFields()
@property (strong) NSMutableArray* mutRecipients;
@property (strong) NSMutableArray* mutUrl;
@end

@implementation MailFields

static MailFields* _sharedMailFields = nil;
NSUserDefaults *defaults;

+(MailFields*)defaultFields {
    if(!_sharedMailFields) {
        _sharedMailFields=[[self alloc] init];
    }
    return _sharedMailFields;
}
+(void)setSubject:(NSString*)subject {
    _sharedMailFields.subject = subject;
    [defaults setObject:subject forKey:@"subject"];
    [defaults synchronize];
}
+(void)setBody:(NSString*)body {
    _sharedMailFields.body = body;
    [defaults setObject:body forKey:@"body"];
    [defaults synchronize];
}
+(void)setRecipients:(NSMutableArray*)to {
    _sharedMailFields.mutRecipients = [to copy];
    [defaults setObject:to forKey:@"recipients"];
    [defaults synchronize];
}

+(void)setUrl:(NSMutableArray*)url{
    _sharedMailFields.mutUrl = [url copy];
    [defaults setObject:url forKey:@"url"];
    [defaults synchronize];
}
+(void)setUsername:(NSString*)user{
    _sharedMailFields.user = user;
    [defaults setObject:user forKey:@"user"];
    [defaults synchronize];
}
+(void)setPassword:(NSString*)pass{
    _sharedMailFields.pass = pass;
    [defaults setObject:pass forKey:@"pass"];
    [defaults synchronize];
    
}

+(void)setFtpStatus:(BOOL)ftpIsEnabled{
    _sharedMailFields.ftp = ftpIsEnabled;
    [defaults setBool:ftpIsEnabled forKey:@"ftp"];
    [defaults synchronize];
}

+(NSString*)sanitize:(NSString*)string{
    NSString *allowedchars = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_-.";
    
    NSCharacterSet *charactersToRemove=[[NSCharacterSet characterSetWithCharactersInString:allowedchars] invertedSet ];
    
    return [[string componentsSeparatedByCharactersInSet:charactersToRemove ]
            componentsJoinedByString:@"_"];
}

+(id)alloc {
    _sharedMailFields = [super alloc];
    return _sharedMailFields;
}

-(id)init {
    
    defaults = [NSUserDefaults standardUserDefaults];
    if(self = [super init]) {
        if(![defaults boolForKey:@"loadSavedSettings"]) {
            [MailFields setSubject:[NSString stringWithFormat:
                                    @"%@ Collection Report",
                                    [[UIDevice currentDevice]name]]];
            [MailFields setBody:[NSString stringWithFormat:
                                 @"%@ Collection Report",
                                 [[UIDevice currentDevice]name]]];
            [MailFields setUsername:@"username"];
            [MailFields setPassword:@"password"];
            [MailFields setUrl:[[NSMutableArray alloc] initWithObjects:@"fezzik.mandli.com",@"StatenameDOT", @"Daily_Upload", nil]];
            [MailFields setFtpStatus:YES];
            [MailFields setRecipients:[[NSMutableArray alloc] initWithObjects:@"jgreen@mandli.com",nil]];
            [defaults setBool:YES forKey:@"loadSavedSettings"];
            [defaults synchronize];
        }
        else {
            self.subject=[defaults objectForKey:@"subject"];
            self.body=[defaults objectForKey:@"body"];
            self.mutRecipients = [[NSMutableArray alloc] initWithArray:[defaults objectForKey:@"recipients"]];
            //self.mutRecipients=[[defaults objectForKey:@"recipients"] copy];
            self.mutUrl = [[NSMutableArray alloc] initWithArray:[defaults objectForKey:@"url"]];
            self.user=[defaults objectForKey:@"user"];
            self.pass=[defaults objectForKey:@"pass"];
            self.ftp=[defaults boolForKey:@"ftp"];
            
        }
    }
    return self;
}

-(NSArray*)recipients {
    NSArray *recipients = [_sharedMailFields.mutRecipients copy];
    return recipients;
}
-(NSArray*)url{
    NSArray *url= [_sharedMailFields.mutUrl copy];
    return url;
}

@end
