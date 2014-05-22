////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCTar.m
//
//  Created by Dalton Cherry on 5/21/14.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

#import "DCTar.h"
#import <zlib.h>

// const definition
#define TAR_BLOCK_SIZE                  512
#define TAR_TYPE_POSITION               156
#define TAR_NAME_POSITION               0
#define TAR_NAME_SIZE                   100
#define TAR_SIZE_POSITION               124
#define TAR_SIZE_SIZE                   12
#define TAR_MAX_BLOCK_LOAD_IN_MEMORY    100

@implementation DCTar

////////////////////////////////////////////////////////////////////////////////////////////////////
+(BOOL)compressFileAtPath:(NSString*)filePath toPath:(NSString*)path error:(NSError**)error
{
    //does both gzip and tar
    //TODO: make a way to tar and gzipped a file.
    //probably create two tar method and gzipped
    return NO;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(BOOL)compressData:(NSData*)data toPath:(NSString*)path error:(NSError**)error
{
    //does both gzip and tar
    //TODO: make a way to tar and gzipped a data blob.
    return NO;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(BOOL)decompressFileAtPath:(NSString*)filePath toPath:(NSString*)path error:(NSError**)error
{
    //does decompression as needed (based on if the file ends .gz)
    NSFileManager *manager = [NSFileManager defaultManager];
    if([manager fileExistsAtPath:filePath]) {
        NSDictionary *attributes = [manager attributesOfItemAtPath:filePath error:nil];
        unsigned long long size = [attributes[NSFileSize] longLongValue];
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
        
        if([filePath hasSuffix:@".gz"]) {
            NSRange range = [filePath rangeOfString:@".gz" options:NSBackwardsSearch];
            NSString *tarPath = [filePath substringToIndex:range.location];
            [manager removeItemAtPath:tarPath error:nil];
            if([self fileInflate:fileHandle isGzip:YES toPath:tarPath]) {
                [fileHandle closeFile];
                attributes = [manager attributesOfItemAtPath:tarPath error:nil];
                size = [attributes[NSFileSize] longLongValue];
                fileHandle = [NSFileHandle fileHandleForReadingAtPath:tarPath];
                filePath = tarPath;
            }
        }
        if([filePath hasSuffix:@".tar"]) {
            BOOL status = [self untarFileAtPath:filePath toPath:path error:error];
            [manager removeItemAtPath:filePath error:nil]; //remove our temp tar file
            return status;
        }
        return YES;
    }
    if(error)
        *error = [self errorWithDetail:@"file not found" code:-2];
    return NO;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(BOOL)decompressData:(NSData*)data toPath:(NSString*)path error:(NSError**)error
{
    return [self untarData:[self gzipDecompress:data] toPath:path error:error];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(BOOL)tarFileAtPath:(NSString*)tarFilePath toPath:(NSString*)path error:(NSError**)error
{
    //tar the file
     //TODO: make a way to tar a file.
    return NO;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(BOOL)untarFileAtPath:(NSString*)tarFilePath toPath:(NSString*)path error:(NSError**)error
{
    NSFileManager *manager = [NSFileManager defaultManager];
    if([manager fileExistsAtPath:tarFilePath]) {
        NSDictionary *attributes = [manager attributesOfItemAtPath:tarFilePath error:nil];
        unsigned long long size = [attributes[NSFileSize] longLongValue];
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:tarFilePath];
        return [self untarObject:fileHandle size:size toPath:path error:error];
    }
    if(error)
        *error = [self errorWithDetail:@"tar file not found" code:-2];
    return NO;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(BOOL)tarData:(NSData*)tarData toPath:(NSString*)path error:(NSError**)error
{
    //TODO: make a way to tar a data blob.
    return NO;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(BOOL)untarData:(NSData*)tarData toPath:(NSString*)path error:(NSError**)error
{
    return [self untarObject:tarData size:[tarData length] toPath:path error:error];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSData*)gzipCompress:(NSData*)data
{
    return [self deflate:data isGzip:YES];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSData*)gzipDecompress:(NSData*)data
{
    return [self inflate:data isGzip:YES];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(BOOL)gzipDecompress:(NSString*)filePath toPath:(NSString*)toPath error:(NSError**)error
{
    NSFileManager *manager = [NSFileManager defaultManager];
    if([manager fileExistsAtPath:filePath]) {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
        BOOL status = [self fileInflate:fileHandle isGzip:YES toPath:toPath];
        if(!status) {
            if(error)
                *error = [self errorWithDetail:@"gzip failed to decompress the file" code:-3];
        }
        return status;
    }
    if(error)
        *error = [self errorWithDetail:@"tar file not found" code:-2];
    return NO;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSData*)zlibDecompress:(NSData*)data
{
    return [self inflate:data isGzip:NO];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSData*)zlibCompress:(NSData*)data
{
    return [self deflate:data isGzip:NO];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
//private methods
////////////////////////////////////////////////////////////////////////////////////////////////////
+(BOOL)untarObject:(id)tarObject size:(unsigned long long)size toPath:(NSString*)path error:(NSError**)error
{
    //do untar awesomeness
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    BOOL didError = NO;
    unsigned long long location = 0; // Position in the file
    while (location < size) {
        unsigned long long blockCount = 1; // 1 block for the header
        @autoreleasepool {
            char type = [self typeForObject:tarObject atOffset:location];
            if(type == '0' || type == '\0') {
                NSString *name = [self nameForObject:tarObject atOffset:location];
                NSString *filePath = [path stringByAppendingPathComponent:name]; // Create a full path from the name
                
                unsigned long long size = [self sizeForObject:tarObject atOffset:location];
                //NSLog(@"file created: %@",name);
                
                if(size == 0) {
                    [@"" writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:error];
                }
                
                blockCount += (size - 1) / TAR_BLOCK_SIZE + 1; // size/TAR_BLOCK_SIZE rounded up
                [self writeFileDataForObject:tarObject atLocation:(location + TAR_BLOCK_SIZE) withLength:size atPath:filePath];
                
            } else if(type == '5') {
                NSString *name = [self nameForObject:tarObject atOffset:location];
                NSString *directoryPath = [path stringByAppendingPathComponent:name]; // Create a full path from the name
                [manager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil]; //Write the directory on filesystem
                //NSLog(@"directory created: %@",name);
                
            } else if(type == 'g') {
                
            } else if(type > '0' || type < 'Z') {
                //NSLog(@"unknown type: %c",type);
                //does nothing
                //NSLog(@"nothing char: %c",type);
            } else {
                //Failure
                //NSLog(@"failure: %c",type);
                didError = YES;
                break;
            }
        }
        location += blockCount * TAR_BLOCK_SIZE;
    }
    if(didError) {
        if(error)
            *error = [self errorWithDetail:@"Unexpected type found in tar file" code:-1];
        return NO;
    }
    return YES;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSError*)errorWithDetail:(NSString*)detail code:(NSInteger)code
{
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:detail forKey:NSLocalizedDescriptionKey];
    return [[NSError alloc] initWithDomain:@"TarKit" code:code userInfo:details];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+ (char)typeForObject:(id)object atOffset:(unsigned long long)offset
{
    char type;
    
    memcpy(&type, [self dataForObject:object inRange:NSMakeRange(offset + TAR_TYPE_POSITION, 1)
                           orLocation:offset + TAR_TYPE_POSITION andLength:1].bytes, 1);
    return type;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSString *)nameForObject:(id)object atOffset:(unsigned long long)offset
{
    char nameBytes[TAR_NAME_SIZE + 1]; // TAR_NAME_SIZE+1 for nul char at end
    
    memset(&nameBytes, '\0', TAR_NAME_SIZE + 1); // Fill byte array with nul char
    memcpy(&nameBytes, [self dataForObject:object inRange:NSMakeRange(offset + TAR_NAME_POSITION, TAR_NAME_SIZE)
                                orLocation:offset + TAR_NAME_POSITION andLength:TAR_NAME_SIZE].bytes, TAR_NAME_SIZE);
    return [NSString stringWithCString:nameBytes encoding:NSASCIIStringEncoding];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+ (unsigned long long)sizeForObject:(id)object atOffset:(unsigned long long)offset
{
    char sizeBytes[TAR_SIZE_SIZE + 1]; // TAR_SIZE_SIZE+1 for nul char at end
    
    memset(&sizeBytes, '\0', TAR_SIZE_SIZE + 1); // Fill byte array with nul char
    memcpy(&sizeBytes, [self dataForObject:object inRange:NSMakeRange(offset + TAR_SIZE_POSITION, TAR_SIZE_SIZE)
                                orLocation:offset + TAR_SIZE_POSITION andLength:TAR_SIZE_SIZE].bytes, TAR_SIZE_SIZE);
    return strtol(sizeBytes, NULL, 8); // Size is an octal number, convert to decimal
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)writeFileDataForObject:(id)object atLocation:(unsigned long long)location withLength:(unsigned long long)length atPath:(NSString *)path
{
    if ([object isKindOfClass:[NSData class]]) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:[object subdataWithRange:NSMakeRange(location, length)] attributes:nil]; //Write the file on filesystem
    } else if ([object isKindOfClass:[NSFileHandle class]]){
        if ([[NSData data] writeToFile:path atomically:NO]) {
            NSFileHandle *destinationFile = [NSFileHandle fileHandleForWritingAtPath:path];
            [object seekToFileOffset:location];
            
            unsigned long long maxSize = TAR_MAX_BLOCK_LOAD_IN_MEMORY * TAR_BLOCK_SIZE;
            
            while (length > maxSize) {
                @autoreleasepool {
                    [destinationFile writeData:[object readDataOfLength:maxSize]];
                    location += maxSize;
                    length -= maxSize;
                }
            }
            [destinationFile writeData:[object readDataOfLength:length]];
            [destinationFile closeFile];
        }
    }
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSData *)dataForObject:(id)object inRange:(NSRange)range orLocation:(unsigned long long)location andLength:(unsigned long long)length
{
    if ([object isKindOfClass:[NSData class]]) {
        return [object subdataWithRange:range];
    } else if ([object isKindOfClass:[NSFileHandle class]]) {
        [object seekToFileOffset:location];
        return [object readDataOfLength:length];
    }
    return nil;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
//compression stuff
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSData*)deflate:(NSData*)data isGzip:(BOOL)isgzip
{
    if ([data length] == 0)
        return nil;
    
    z_stream strm;
    
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.next_in=(Bytef*)[data bytes];
    strm.avail_in = [data length];
    
    if(isgzip){
        if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK)
            return nil;
    } else {
        if (deflateInit(&strm, Z_DEFAULT_COMPRESSION) != Z_OK)
            return nil;
    }
    
    NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chuncks for expansion
    do {
        
        if (strm.total_out >= [compressed length])
            [compressed increaseLengthBy:16384];
        
        strm.next_out = [compressed mutableBytes] + strm.total_out;
        strm.avail_out = [compressed length] - strm.total_out;
        
        deflate(&strm, Z_FINISH);
        
    } while (strm.avail_out == 0);
    
    deflateEnd(&strm);
    
    [compressed setLength:strm.total_out];
    return [NSData dataWithData:compressed];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSData*)inflate:(NSData*)data isGzip:(BOOL)isgzip
{
    if ([data length] == 0)
        return nil;
    
    unsigned full_length = [data length];
    unsigned half_length = [data length] / 2;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    BOOL done = NO;
    int status;
    
    z_stream strm;
    strm.next_in = (Bytef*)[data bytes];
    strm.avail_in = [data length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    
    if(isgzip) {
        if(inflateInit2(&strm, (15+32)) != Z_OK)
            return nil;
    } else {
        if(inflateInit(&strm) != Z_OK)
            return nil;
    }
    
    while (!done)
    {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length])
            [decompressed increaseLengthBy:half_length];
        
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = [decompressed length] - strm.total_out;
        
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END)
            done = YES;
        else if (status != Z_OK)
            break;
    }
    if (inflateEnd (&strm) != Z_OK)
        return nil;
    
    // Set real length.
    if (done)
    {
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData:decompressed];
    }
    return nil;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(BOOL)fileInflate:(NSFileHandle*)fileHandle isGzip:(BOOL)isgzip toPath:(NSString*)toPath
{
    z_stream strm;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.avail_in = 0;
    strm.next_in = Z_NULL;
    
    if(isgzip) {
        if(inflateInit2(&strm, (15+32)) != Z_OK)
            return NO;
    } else {
        if(inflateInit(&strm) != Z_OK)
            return NO;
    }
    [@"" writeToFile:toPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    NSFileHandle *writeHandle = [NSFileHandle fileHandleForWritingAtPath:toPath];
    BOOL done = NO;
    NSInteger chunkSize = 16384;
    do {
        NSData *chunk = [fileHandle readDataOfLength:chunkSize];
        strm.avail_in = [chunk length];
        strm.next_in = (Bytef*)[chunk bytes];
        
        do {
            NSMutableData *decompressed = [NSMutableData dataWithLength:chunkSize];
            strm.avail_out = chunkSize;
            strm.next_out = (Bytef*)[decompressed mutableBytes];
            NSInteger status = inflate (&strm, Z_SYNC_FLUSH);
            if (status == Z_STREAM_END)
                done = YES;
            else if (status != Z_OK) {
                done = YES;
                return NO;
            }
            NSInteger have = chunkSize - strm.avail_out;
            [decompressed setLength:have];
            [writeHandle writeData:decompressed];
            
        } while (strm.avail_out == 0);
        
        
    } while (!done);
    
    [writeHandle closeFile];
    if (inflateEnd (&strm) != Z_OK)
        return NO;
    
    return YES;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
@end
