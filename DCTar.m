////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCTar.m
//
//  Created by Dalton Cherry on 5/21/14.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

#import "DCTar.h"
#import <zlib.h>

@implementation DCTar

////////////////////////////////////////////////////////////////////////////////////////////////////
+(BOOL)compressFileAtPath:(NSString*)filePath toPath:(NSString*)path error:(NSError**)error
{
    //does both gzip and tar
    return NO;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(BOOL)compressData:(NSData*)data toPath:(NSString*)path error:(NSError**)error
{
    //does both gzip and tar
    return NO;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(BOOL)decompressFileAtPath:(NSString*)filePath toPath:(NSString*)path error:(NSError**)error
{
    //does decompression as needed (based on if the file ends .gz)
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
    return NO;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(BOOL)untarFileAtPath:(NSString*)tarFilePath toPath:(NSString*)path error:(NSError**)error
{
    NSFileManager *manager = [NSFileManager defaultManager];
    if([manager fileExistsAtPath:tarFilePath]) {
        //NSFileHandle *fileHandle = [] TODO: Support untar from disk for huge tar files
        
    }
    return NO;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(BOOL)tarData:(NSData*)tarData toPath:(NSString*)path error:(NSError**)error
{
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
    return NO;
}
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
@end
