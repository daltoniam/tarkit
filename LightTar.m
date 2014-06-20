//
//  LightTar.m
//  Create tars.
//  Part of the code was inspired by libarchive
//
//  Created by Patrice Brend'amour of 2014-05-30.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "LightTar.h"

#pragma mark - Definitions

#define TAR_VERBOSE_LOG_MODE

#define TAR_BLOCK_SIZE  512

/*
 * Define structure of POSIX 'ustar' tar header.
 + Provided by libarchive.
 */
#define	USTAR_name_offset 0
#define	USTAR_name_size 100
#define	USTAR_mode_offset 100
#define	USTAR_mode_size 6
#define	USTAR_mode_max_size 8
#define	USTAR_uid_offset 108
#define	USTAR_uid_size 6
#define	USTAR_uid_max_size 8
#define	USTAR_gid_offset 116
#define	USTAR_gid_size 6
#define	USTAR_gid_max_size 8
#define	USTAR_size_offset 124
#define	USTAR_size_size 11
#define	USTAR_size_max_size 12
#define	USTAR_mtime_offset 136
#define	USTAR_mtime_size 11
#define	USTAR_mtime_max_size 11
#define	USTAR_checksum_offset 148
#define	USTAR_checksum_size 8
#define	USTAR_typeflag_offset 156
#define	USTAR_typeflag_size 1
#define	USTAR_linkname_offset 157
#define	USTAR_linkname_size 100
#define	USTAR_magic_offset 257
#define	USTAR_magic_size 6
#define	USTAR_version_offset 263
#define	USTAR_version_size 2
#define	USTAR_uname_offset 265
#define	USTAR_uname_size 32
#define	USTAR_gname_offset 297
#define	USTAR_gname_size 32
#define	USTAR_rdevmajor_offset 329
#define	USTAR_rdevmajor_size 6
#define	USTAR_rdevmajor_max_size 8
#define	USTAR_rdevminor_offset 337
#define	USTAR_rdevminor_size 6
#define	USTAR_rdevminor_max_size 8
#define	USTAR_prefix_offset 345
#define	USTAR_prefix_size 155
#define	USTAR_padding_offset 500
#define	USTAR_padding_size 12


static const char template_header[] = {
	/* name: 100 bytes */
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
	0,0,0,0,
	/* Mode, space-null termination: 8 bytes */
	'0','0','0','0','0','0', ' ','\0',
	/* uid, space-null termination: 8 bytes */
	'0','0','0','0','0','0', ' ','\0',
	/* gid, space-null termination: 8 bytes */
	'0','0','0','0','0','0', ' ','\0',
	/* size, space termation: 12 bytes */
	'0','0','0','0','0','0','0','0','0','0','0', ' ',
	/* mtime, space termation: 12 bytes */
	'0','0','0','0','0','0','0','0','0','0','0', ' ',
	/* Initial checksum value: 8 spaces */
	' ',' ',' ',' ',' ',' ',' ',' ',
	/* Typeflag: 1 byte */
	'0',			/* '0' = regular file */
	/* Linkname: 100 bytes */
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
	0,0,0,0,
	/* Magic: 6 bytes, Version: 2 bytes */
	'u','s','t','a','r','\0', '0','0',
	/* Uname: 32 bytes */
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
	/* Gname: 32 bytes */
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
	/* rdevmajor + space/null padding: 8 bytes */
	'0','0','0','0','0','0', ' ','\0',
	/* rdevminor + space/null padding: 8 bytes */
	'0','0','0','0','0','0', ' ','\0',
	/* Prefix: 155 bytes */
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,
	/* Padding: 12 bytes */
	0,0,0,0,0,0,0,0, 0,0,0,0
};

#pragma mark - Private Methods
@interface LightTar()
+ (NSData *) binaryEncodeDataForPath:(NSString *) path inDirectory:(NSString *)basepath  isDirectory:(BOOL) isDirectory;
+ (void) writeHeader:(char *) buffer forPath:(NSString *) path withBasePath:(NSString *) basePath isDirectory:(BOOL) isDirectory;
+ (void) writeString:(NSString *) string toChar:(char *) charArray withLenght:(int) size;
@end

#pragma mark - Implementation
@implementation LightTar

+ (NSData *)createTarWithFilesAndDirectoriesAtURL:(NSURL *)url error:(NSError **)error
{
    return [self createTarWithFilesAndDirectoriesAtPath:[url path] error:error];
}


+ (NSData *)createTarWithFilesAndDirectoriesAtPath:(NSString *)path error:(NSError **)error
{
    NSMutableData *data = [NSMutableData data];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if([fileManager fileExistsAtPath:path]) {
        
        NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtPath:path];
        
        
        NSString *file;
        BOOL isDir;
        while ((file = [dirEnumerator nextObject])) {
            DDLogVerbose(@"File: %@", file);
            [fileManager fileExistsAtPath:[path stringByAppendingPathComponent:file] isDirectory:&isDir];
            NSData *tarContent = [self binaryEncodeDataForPath:file inDirectory:path isDirectory:isDir ];
            if(tarContent) {
                [data appendData:tarContent];
            }
        }
        //Append two empty blocks to indicate end
        char block[TAR_BLOCK_SIZE*2];
        memset(&block, '\0', TAR_BLOCK_SIZE*2);
        [data appendBytes:block length:TAR_BLOCK_SIZE*2];
        return data;
    }
    return nil;
}

#pragma mark Private methods implementation


+ (NSData *) binaryEncodeDataForPath:(NSString *) path inDirectory:(NSString *)basepath  isDirectory:(BOOL) isDirectory {
    
    NSMutableData *tarData;
    char block[TAR_BLOCK_SIZE];
    
    if(isDirectory) {
        path = [path stringByAppendingString:@"/"];
    }
    //write header
    [self writeHeader:block forPath:path withBasePath:basepath isDirectory:isDirectory];
    tarData = [NSMutableData dataWithBytes:block length:TAR_BLOCK_SIZE];
    
    //write data
    if(!isDirectory) {
        [self writeDataFromPath: [basepath stringByAppendingPathComponent:path] toData:tarData];
    }
    return tarData;
}

+ (void) writeHeader:(char *) buffer forPath:(NSString *) path withBasePath:(NSString *) basePath isDirectory:(BOOL) isDirectory {
    memcpy(buffer,&template_header, TAR_BLOCK_SIZE);
    
    NSError *error;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[basePath stringByAppendingPathComponent:path] error:&error];
    int permissions = [[attributes objectForKey:NSFilePosixPermissions] shortValue];
    NSDate * modificationDate = [attributes objectForKey:NSFileModificationDate];
    long ownerId = [[attributes objectForKey:NSFileOwnerAccountID] longValue];
    long groupId = [[attributes objectForKey:NSFileGroupOwnerAccountID] longValue];
    NSString *ownerName = [attributes objectForKey:NSFileOwnerAccountName];
    NSString *groupName = [attributes objectForKey:NSFileGroupOwnerAccountName];
    unsigned long long fileSize = [[attributes objectForKey:NSFileSize] longLongValue];
    
    char nameChar[USTAR_name_size];
    [self writeString:path toChar:nameChar withLenght:USTAR_name_size];
    char unameChar[USTAR_uname_size];
    [self writeString:ownerName toChar:unameChar withLenght:USTAR_uname_size];
    char gnameChar[USTAR_gname_size];
    [self writeString:groupName toChar:gnameChar withLenght:USTAR_gname_size];
    
    
    format_number(permissions & 07777, buffer+USTAR_mode_offset, USTAR_mode_size, USTAR_mode_max_size, 0);
    format_number(ownerId,
                  buffer + USTAR_uid_offset, USTAR_uid_size, USTAR_uid_max_size, 0);
	format_number(groupId,
                  buffer + USTAR_gid_offset, USTAR_gid_size, USTAR_gid_max_size, 0);
    
	format_number(fileSize, buffer + USTAR_size_offset, USTAR_size_size, USTAR_size_max_size, 0);
    
	format_number([modificationDate timeIntervalSince1970],
                  buffer + USTAR_mtime_offset, USTAR_mtime_size, USTAR_mtime_max_size, 0);
    
    unsigned long nameLength = strlen(nameChar);
    if (nameLength <= USTAR_name_size)
		memcpy(buffer + USTAR_name_offset, nameChar, nameLength);
	else {
		/* Store in two pieces, splitting at a '/'. */
		const char *p = strchr(nameChar + nameLength - USTAR_name_size - 1, '/');
		/*
		 * Look for the next '/' if we chose the first character
		 * as the separator.  (ustar format doesn't permit
		 * an empty prefix.)
		 */
		if (p == nameChar)
			p = strchr(p + 1, '/');
        memcpy(buffer + USTAR_prefix_offset, nameChar, p - nameChar);
		memcpy(buffer + USTAR_name_offset, p + 1,
               nameChar + nameLength - p - 1);
	}
    
    memcpy(buffer+USTAR_uname_offset,unameChar,USTAR_uname_size);
    memcpy(buffer+USTAR_gname_offset,gnameChar,USTAR_gname_size);
    
    if(isDirectory) {
        format_number(0, buffer + USTAR_size_offset, USTAR_size_size, USTAR_size_max_size, 0);
        memset(buffer+USTAR_typeflag_offset,'5',USTAR_typeflag_size);
    }
    
    //Checksum
    int checksum = 0;
    for (int i = 0; i < TAR_BLOCK_SIZE; i++)
		checksum += 255 & (unsigned int)buffer[i];
	buffer[USTAR_checksum_offset + 6] = '\0';
	format_octal(checksum, buffer + USTAR_checksum_offset, 6);
}

+ (void) writeDataFromPath:(NSString *)path toData:(NSMutableData *)data {
    NSData *content = [NSData dataWithContentsOfFile:path];
    NSUInteger contentSize = [content length];
    unsigned long padding =  (TAR_BLOCK_SIZE - (contentSize % TAR_BLOCK_SIZE)) % TAR_BLOCK_SIZE ;
    char buffer[padding];
    memset(&buffer, '\0', padding);
    [data appendData:content];
    [data appendBytes:buffer length:padding];
}

+ (void) writeString:(NSString *) string toChar:(char *) charArray withLenght:(int) size
{
    NSData *stringData = [string dataUsingEncoding:NSASCIIStringEncoding];
    memset(charArray, '\0', size);
    [stringData getBytes:charArray length:[stringData length]];
}


#pragma mark - Formatting 
//Thanks to libarchive

/*
 * Format a number into a field, with some intelligence.
 */
static int
format_number(int64_t v, char *p, int s, int maxsize, int strict)
{
	int64_t limit;
    
	limit = ((int64_t)1 << (s*3));
    
	/* "Strict" only permits octal values with proper termination. */
	if (strict)
		return (format_octal(v, p, s));
    
	/*
	 * In non-strict mode, we allow the number to overwrite one or
	 * more bytes of the field termination.  Even old tar
	 * implementations should be able to handle this with no
	 * problem.
	 */
	if (v >= 0) {
		while (s <= maxsize) {
			if (v < limit)
				return (format_octal(v, p, s));
			s++;
			limit <<= 3;
		}
	}
    
	/* Base-256 can handle any number, positive or negative. */
	return (format_256(v, p, maxsize));
}

/*
 * Format a number into the specified field using base-256.
 */
static int
format_256(int64_t v, char *p, int s)
{
	p += s;
	while (s-- > 0) {
		*--p = (char)(v & 0xff);
		v >>= 8;
	}
	*p |= 0x80; /* Set the base-256 marker bit. */
	return (0);
}

/*
 * Format a number into the specified field.
 */
static int
format_octal(int64_t v, char *p, int s)
{
	int len;
    
	len = s;
    
	/* Octal values can't be negative, so use 0. */
	if (v < 0) {
		while (len-- > 0)
			*p++ = '0';
		return (-1);
	}
    
	p += s;		/* Start at the end and work backwards. */
	while (s-- > 0) {
		*--p = (char)('0' + (v & 7));
		v >>= 3;
	}
    
	if (v == 0)
		return (0);
    
	/* If it overflowed, fill field with max value. */
	while (len-- > 0)
		*p++ = '7';
    
	return (-1);
}



@end