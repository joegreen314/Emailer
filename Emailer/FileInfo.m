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
    @property (nonatomic) NSString * fileSize;
@end

@implementation FileInfo

-(FileInfo*)initFile:(NSString*)name inDirectory:(NSString*)dir withSize:(NSString*)size {
    
    self = [super init];
    if(self) {
        self.name = name;
        self.fileSize=size;
        self.directoryPath=dir;
        self.filePath=[NSString stringWithFormat:@"%@/%@", dir, name];
    }
    return self;
}

@end
