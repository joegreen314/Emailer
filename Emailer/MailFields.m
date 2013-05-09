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


+(id)alloc {
    _sharedMailFields = [super alloc];
    return _sharedMailFields;
}

-(id)init {
    
    defaults = [NSUserDefaults standardUserDefaults];
    if(self = [super init]) {
        if([defaults objectForKey:@"subject"]==nil) {
            self.mutRecipients = [[NSMutableArray alloc] init];
            [self.mutRecipients addObject:@"jgreen@mandli.com"];
            self.subject = @"Error Report";
            self.body = @"Errors";
        }
        else {
            self.subject=[defaults objectForKey:@"subject"];
            self.body=[defaults objectForKey:@"body"];
            self.mutRecipients = [[NSMutableArray alloc] init];
            self.mutRecipients=[[defaults objectForKey:@"recipients"] copy];
        }
    }
    return self;
}

-(NSArray*)recipients {
    NSArray *recipients = [_sharedMailFields.mutRecipients copy];
    return recipients;
}

@end
