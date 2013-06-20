//
//  TCUWebDataCache.m
//  TCUWebDataCache
//
//  Created by Töre Çağrı Uyar on 2012.
//  Copyright (c) 2012 Töre Çağrı Uyar. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "TCUWebDataCache.h"

@interface TCUWebDataCache()

@property(nonatomic, retain) NSDictionary *cache;

- (NSString *)filePathForFileName:(NSString *)fileName;
- (NSString *)cacheDirectoryPath;

@end

@implementation TCUWebDataCache

@synthesize cache;

+ (TCUWebDataCache *)sharedDataCache {
    __strong static TCUWebDataCache *_sharedWebDataCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedWebDataCache = [[self alloc] init];
    });
    return _sharedWebDataCache;
}

- (id)init {
    self = [super init];
    if (self) {
        lastIndex = 0;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:[self cacheDirectoryPath]]) {
            [fileManager removeItemAtPath:[self cacheDirectoryPath] error:NULL];
        }
        [fileManager createDirectoryAtPath:[self cacheDirectoryPath] withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    return self;
}

- (void)dealloc {
    self.cache = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[self cacheDirectoryPath]]) {
        [fileManager removeItemAtPath:[self cacheDirectoryPath] error:NULL];
    }
}

- (NSMutableDictionary *)cache {
    if (!cache) {
        cache = [[NSMutableDictionary alloc] init];
    }
    return cache;
}

- (NSString *)filePathForFileName:(NSString *)fileName {
    return [[self cacheDirectoryPath] stringByAppendingPathComponent:fileName];
}

- (NSString *)cacheDirectoryPath {
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"TCUWebDataCache/"];
}

- (BOOL)isDataFromURLCached:(NSString *)URLString {
    NSString *fileName = [self.cache objectForKey:URLString];
    if (fileName) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[self filePathForFileName:fileName]]) {
            return YES;
        }
    }
    return NO;
}

- (NSData *)getDataFromURL:(NSString *)URLString cached:(BOOL)cached {
    if (!URLString) {
        return nil;
    }
    @synchronized(self) {
        if ([self.cache objectForKey:URLString] && cached) {
            NSString *filePath = [self filePathForFileName:[self.cache objectForKey:URLString]];
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                NSData *data = [NSData dataWithContentsOfFile:filePath];
                if (data) {
                    return data;
                }
            }
        }
    }
    NSURL *URL = [NSURL URLWithString:URLString];
    if (!URL) {
        return nil;
    }
    NSData *data = [NSData dataWithContentsOfURL:URL options:NSDataReadingUncached error:NULL];
    if (data) {
        @synchronized(self) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath:[self cacheDirectoryPath]]) {
                [fileManager createDirectoryAtPath:[self cacheDirectoryPath] withIntermediateDirectories:YES attributes:nil error:NULL];
                lastIndex = 0;
                self.cache = nil;
            }
            BOOL hadCacheEntry = YES;
            NSString *fileName = nil;
            fileName = [self.cache valueForKey:URLString];
            if (!fileName) {
                fileName = [NSString stringWithFormat:@"%lld.data", lastIndex];
                hadCacheEntry = NO;
            }
            if ([data writeToFile:[self filePathForFileName:fileName] atomically:YES]) {
                if (!hadCacheEntry) {
                    [self.cache setValue:fileName forKey:URLString];
                    lastIndex++;
                }
            }
        }
    }
    return data;
}

- (NSData *)getCachedDataFromURL:(NSString *)URLString {
    if (!URLString) {
        return nil;
    }
    @synchronized(self) {
        if ([self.cache objectForKey:URLString]) {
            NSString *filePath = [self filePathForFileName:[self.cache objectForKey:URLString]];
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                NSData *data = [NSData dataWithContentsOfFile:filePath];
                if (data) {
                    return data;
                }
            }
        }
    }
    return nil;
}

@end
