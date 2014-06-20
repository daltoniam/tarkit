////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCTar.h
//
//  Created by Dalton Cherry on 5/21/14.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Discussion.
 It is important to know that all the file system based tar commands used chunked/buffer methods to save memory.
 Due to the fact that tars are normally used to compress lots of content, It is strongly recommend to use those method
 versus the in memory data options.
 */
#import <Foundation/Foundation.h>

@interface DCTar : NSObject

/**
 Create a gzipped tar file from a file or directory.
 @param: filePath is the path to file on disk.
 @param: toPath is the path to create the tar at.
 @param: error is used to report back if an error happened.
 @return if the compression was successful or not.
 */
+(BOOL)compressFileAtPath:(NSString*)filePath toPath:(NSString*)toPath error:(NSError**)error;

/**
 Create a gzipped tar file from a data blob.
 @param: data is the file data blob to create a tar with.
 @param: toPath is the path to create the tar at.
 @param: error is used to report back if an error happened.
 @return if the compression was successful or not.
 */
//+(BOOL)compressData:(NSData*)data toPath:(NSString*)path error:(NSError**)error;

/**
 decompress a tar or gzipped tar (.tar or tar.giz) file.
 @param: filePath is the path to the tar file on disk.
 @param: toPath is the directory path to create the export data at.
 @param: error is used to report back if an error happened.
 @return if the decompression was successful or not.
 */
+(BOOL)decompressFileAtPath:(NSString*)filePath toPath:(NSString*)path error:(NSError**)error;

/**
 decompress a tar or gzipped tar (.tar or tar.giz) file.
 @param: data is the file tar blob to decompress.
 @param: toPath is the directory path to create the export data at.
 @param: error is used to report back if an error happened.
 @return if the decompression was successful or not.
 */
+(BOOL)decompressData:(NSData*)data toPath:(NSString*)path error:(NSError**)error;

/**
 Create a tar file (no gzipping) from a file or directory.
 @param: filePath is the path to file on disk.
 @param: toPath is the path to create the tar at.
 @param: error is used to report back if an error happened.
 @return if the compression was successful or not.
 */
+(BOOL)tarFileAtPath:(NSString*)tarFilePath toPath:(NSString*)path error:(NSError**)error;

/**
 decompress a tar file.
 @param: filePath is the path to the tar file on disk.
 @param: toPath is the directory path to create the export data at.
 @param: error is used to report back if an error happened.
 @return if the decompression was successful or not.
 */
+(BOOL)untarFileAtPath:(NSString*)tarFilePath toPath:(NSString*)path error:(NSError**)error;

/**
 Create a tar file (not gzipped) from a data blob.
 @param: data is the file data blob to create a tar with.
 @param: toPath is the path to create the tar at.
 @param: error is used to report back if an error happened.
 @return if the compression was successful or not.
 */
//+(BOOL)tarData:(NSData*)tarData toPath:(NSString*)path error:(NSError**)error;

/**
 decompress a tar file (not gzipped).
 @param: data is the file tar blob to decompress.
 @param: toPath is the directory path to create the export data at.
 @param: error is used to report back if an error happened.
 @return if the decompression was successful or not.
 */
+(BOOL)untarData:(NSData*)tarData toPath:(NSString*)path error:(NSError**)error;

/**
 gzipped some data.
 @param: The data to gzip.
 @return The newly gzipped data.
 */
+(NSData*)gzipCompress:(NSData*)data;

/**
 decompress a gzipped data blob.
 @param: The data to ungzip.
 @return The newly unzipped data.
 */
+(NSData*)gzipDecompress:(NSData*)data;

/**
 decompress a gzipped file.
 @param: filePath is the path to file on disk.
 @param: toPath is the path to create the tar at.
 @param: error is used to report back if an error happened.
 @return if the compression was successful or not.
 */
+(BOOL)gzipDecompress:(NSString*)filePath toPath:(NSString*)toPath error:(NSError**)error;

/**
 decompress a zlib data blob.
 @param: The data to decompress.
 @return The newly decompressed data.
 */
+(NSData*)zlibDecompress:(NSData*)data;

/**
 compress a zlib data blob.
 @param: The data to compress.
 @return The newly compressed data.
 */
+(NSData*)zlibCompress:(NSData*)data;

@end
