//
//  FileInfo.h
//  Emailer
//
//  Created by Joe Green on 5/1/13.
//  Copyright (c) 2013 Digilog. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileInfo : NSObject

@property (readonly, nonatomic) NSString * filePath;
@property (readonly, nonatomic) NSString * directoryPath;
@property (readonly, nonatomic) NSString * name;
@property (readonly, nonatomic) NSString * fileSize;

-(id)initFile:(NSString*)name inDirectory:(NSString*)dir withSize:(NSString*)size;

@end
