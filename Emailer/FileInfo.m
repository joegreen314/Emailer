//
//  FileInfo.m
//  Emailer
//
//  Created by Joe Green on 5/1/13.
//  Copyright (c) 2013 Digilog. All rights reserved.
//

#import "FileInfo.h"

@interface FileInfo()
    @property (nonatomic) NSString * filePath;
    @property (nonatomic) NSString * directoryPath;
    @property (nonatomic) NSString * name;
    @property (nonatomic) NSString * fsize;
@end

@implementation FileInfo

-(FileInfo*)initFile:(NSString*)name inDirectory:(NSString*)dir withSize:(int)size {
    
    self = [super init];
    if(self) {
        self.name = name;
        self.directoryPath=dir;
        self.filePath=[NSString stringWithFormat:@"%@/%@", dir, name];
        double dsize = size;
        NSString *unit;
        if(size>1000000) {
            dsize/=1000000;
            unit=@"MB";
        }
        else if(size>1000) {
            dsize/=1000;
            unit=@"kB";
        }
        else
            unit=@"B";
        
        
        
        self.fsize = [NSString stringWithFormat:@"%.1f %@", dsize, unit];
    }
    return self;
}

@end
