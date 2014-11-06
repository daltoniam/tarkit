////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCTar.m
//
//  Created by Dalton Cherry on 5/21/14.
//
//  Also created by Patrice Brend'amour of 2014-05-30
//
//  Part of the code was inspired by libarchive
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

@implementation DCTar

////////////////////////////////////////////////////////////////////////////////////////////////////
+(BOOL)compressFileAtPath:(NSString*)filePath toPath:(NSString*)path error:(NSError**)error
{
    //does decompression as needed (based on if the file ends .gz)
    NSFileManager *manager = [NSFileManager defaultManager];
    if([manager fileExistsAtPath:filePath]) {
        
        NSString *workPath = path;
        BOOL doGzip = NO;
        if([workPath hasSuffix:@".gz"]) {
            NSRange range = [workPath rangeOfString:@".gz" options:NSBackwardsSearch];
            NSString *tarPath = [workPath substringToIndex:range.location];
            workPath = tarPath;
            doGzip = YES;
        }
        BOOL status = YES;
        if([workPath hasSuffix:@".tar"]) {
            if(![self tarFileAtPath:filePath toPath:workPath error:error]) {
                if(error)
                    *error = [self errorWithDetail:@"unable to tar the file" code:-3];
                return status;
            }
            
        }
        if(doGzip) {
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:workPath];
            status = [self fileDeflate:fileHandle isGzip:YES toPath:path];
            [fileHandle closeFile];
            if(status) {
                [manager removeItemAtPath:workPath error:nil]; //remove our temp tar file
            }
        }
        return status;
    }
    if(error)
        *error = [self errorWithDetail:@"file not found" code:-2];
    return NO;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
//+(BOOL)compressData:(NSData*)data toPath:(NSString*)path error:(NSError**)error
//{
//    //does both gzip and tar
//    //TODO: make a way to tar and gzipped a data blob.
//    return NO;
//}
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
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if([fileManager fileExistsAtPath:tarFilePath]) {
        
        [fileManager removeItemAtPath:path error:nil];
        [@"" writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
        for(NSString *file in [fileManager enumeratorAtPath:tarFilePath]) {
            BOOL isDir = NO;
            [fileManager fileExistsAtPath:[tarFilePath stringByAppendingPathComponent:file] isDirectory:&isDir];
            NSData *tarContent = [self binaryEncodeDataForPath:file inDirectory:tarFilePath isDirectory:isDir];
            [fileHandle writeData:tarContent];
        }
        //Append two empty blocks to indicate end
        char block[TAR_BLOCK_SIZE*2];
        memset(&block, '\0', TAR_BLOCK_SIZE*2);
        [fileHandle writeData:[NSData dataWithBytes:block length:TAR_BLOCK_SIZE*2]];
        [fileHandle closeFile];
        return YES;
    }
    if(error)
        *error = [self errorWithDetail:@"tar file not found" code:-2];
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
//+(BOOL)tarData:(NSData*)tarData toPath:(NSString*)path error:(NSError**)error
//{
//    //TODO: make a way to tar a data blob.
//    return NO;
//}
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
////////////////////////////////////////////////////////////////////////////////////////////////////
//untar methods
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
    
    memcpy(&type, [self dataForObject:object inRange:NSMakeRange((uInt)offset + TAR_TYPE_POSITION, 1)
                           orLocation:offset + TAR_TYPE_POSITION andLength:1].bytes, 1);
    return type;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSString *)nameForObject:(id)object atOffset:(unsigned long long)offset
{
    char nameBytes[TAR_NAME_SIZE + 1]; // TAR_NAME_SIZE+1 for nul char at end
    
    memset(&nameBytes, '\0', TAR_NAME_SIZE + 1); // Fill byte array with nul char
    memcpy(&nameBytes, [self dataForObject:object inRange:NSMakeRange((uInt)offset + TAR_NAME_POSITION, TAR_NAME_SIZE)
                                orLocation:offset + TAR_NAME_POSITION andLength:TAR_NAME_SIZE].bytes, TAR_NAME_SIZE);
    return [NSString stringWithCString:nameBytes encoding:NSASCIIStringEncoding];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+ (unsigned long long)sizeForObject:(id)object atOffset:(unsigned long long)offset
{
    char sizeBytes[TAR_SIZE_SIZE + 1]; // TAR_SIZE_SIZE+1 for nul char at end
    
    memset(&sizeBytes, '\0', TAR_SIZE_SIZE + 1); // Fill byte array with nul char
    memcpy(&sizeBytes, [self dataForObject:object inRange:NSMakeRange((uInt)offset + TAR_SIZE_POSITION, TAR_SIZE_SIZE)
                                orLocation:offset + TAR_SIZE_POSITION andLength:TAR_SIZE_SIZE].bytes, TAR_SIZE_SIZE);
    return strtol(sizeBytes, NULL, 8); // Size is an octal number, convert to decimal
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)writeFileDataForObject:(id)object atLocation:(unsigned long long)location withLength:(unsigned long long)length atPath:(NSString *)path
{
    if ([object isKindOfClass:[NSData class]]) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:[object subdataWithRange:NSMakeRange((uInt)location, (uInt)length)] attributes:nil]; //Write the file on filesystem
    } else if ([object isKindOfClass:[NSFileHandle class]]){
        if ([[NSData data] writeToFile:path atomically:NO]) {
            NSFileHandle *destinationFile = [NSFileHandle fileHandleForWritingAtPath:path];
            [object seekToFileOffset:location];
            
            uInt maxSize = TAR_MAX_BLOCK_LOAD_IN_MEMORY * TAR_BLOCK_SIZE;
            
            while (length > maxSize) {
                @autoreleasepool {
                    [destinationFile writeData:[object readDataOfLength:maxSize]];
                    location += maxSize;
                    length -= maxSize;
                }
            }
            [destinationFile writeData:[object readDataOfLength:(uInt)length]];
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
        return [object readDataOfLength:(uInt)length];
    }
    return nil;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
//tar stuff
////////////////////////////////////////////////////////////////////////////////////////////////////
+ (NSData*)binaryEncodeDataForPath:(NSString *) path inDirectory:(NSString *)basepath  isDirectory:(BOOL) isDirectory{
    
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
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)writeHeader:(char*)buffer forPath:(NSString*)path withBasePath:(NSString*)basePath isDirectory:(BOOL)isDirectory {
    
    memcpy(buffer,&template_header, TAR_BLOCK_SIZE);
    NSError *error = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[basePath stringByAppendingPathComponent:path] error:&error];
    int permissions = [[attributes objectForKey:NSFilePosixPermissions] shortValue];
    NSDate * modificationDate = [attributes objectForKey:NSFileModificationDate];
    long ownerId = [[attributes objectForKey:NSFileOwnerAccountID] longValue];
    long groupId = [[attributes objectForKey:NSFileGroupOwnerAccountID] longValue];
    NSString *ownerName = [attributes objectForKey:NSFileOwnerAccountName];
    NSString *groupName = [attributes objectForKey:NSFileGroupOwnerAccountName];
    unsigned long long fileSize = [[attributes objectForKey:NSFileSize] longLongValue];
    
    char nameChar[USTAR_name_size];
    [self writeString:path toChar:nameChar withLength:USTAR_name_size];
    char unameChar[USTAR_uname_size];
    [self writeString:ownerName toChar:unameChar withLength:USTAR_uname_size];
    char gnameChar[USTAR_gname_size];
    [self writeString:groupName toChar:gnameChar withLength:USTAR_gname_size];
    
    
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
////////////////////////////////////////////////////////////////////////////////////////////////////
+(void)writeDataFromPath:(NSString *)path toData:(NSMutableData*)data {
    NSData *content = [NSData dataWithContentsOfFile:path];
    NSUInteger contentSize = [content length];
    unsigned long padding =  (TAR_BLOCK_SIZE - (contentSize % TAR_BLOCK_SIZE)) % TAR_BLOCK_SIZE ;
    char buffer[padding];
    memset(&buffer, '\0', padding);
    [data appendData:content];
    [data appendBytes:buffer length:padding];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+ (void)writeString:(NSString*)string toChar:(char*)charArray withLength:(NSInteger)size
{
    NSData *stringData = [string dataUsingEncoding:NSASCIIStringEncoding];
    memset(charArray, '\0', size);
    [stringData getBytes:charArray length:[stringData length]];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Formatting
//Thanks to libarchive

////////////////////////////////////////////////////////////////////////////////////////////////////
//Format a number into a field, with some intelligence.
static int format_number(int64_t v, char *p, int s, int maxsize, int strict)
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
////////////////////////////////////////////////////////////////////////////////////////////////////
//Format a number into the specified field using base-256.
static int format_256(int64_t v, char *p, int s)
{
	p += s;
	while (s-- > 0) {
		*--p = (char)(v & 0xff);
		v >>= 8;
	}
	*p |= 0x80; /* Set the base-256 marker bit. */
	return (0);
}
////////////////////////////////////////////////////////////////////////////////////////////////////
//Format a number into the specified field.
static int format_octal(int64_t v, char *p, int s)
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
    strm.avail_in = (uInt)[data length];
    
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
        strm.avail_out = (uInt)([compressed length] - strm.total_out);
        
        deflate(&strm, Z_FINISH);
        
    } while (strm.avail_out == 0);
    
    deflateEnd(&strm);
    
    [compressed setLength:strm.total_out];
    return [NSData dataWithData:compressed];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(BOOL)fileDeflate:(NSFileHandle*)fileHandle isGzip:(BOOL)isgzip toPath:(NSString*)toPath
{
    z_stream strm;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.avail_in = 0;
    strm.next_in = Z_NULL;
    
    if(isgzip){
        if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK)
            return NO;
    } else {
        if (deflateInit(&strm, Z_DEFAULT_COMPRESSION) != Z_OK)
            return NO;
    }
    
    [@"" writeToFile:toPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    NSFileHandle *writeHandle = [NSFileHandle fileHandleForWritingAtPath:toPath];
    BOOL done = NO;
    uInt chunkSize = 16384;
    do {
        NSData *chunk = [fileHandle readDataOfLength:chunkSize];
        strm.avail_in = (uInt)[chunk length];
        strm.next_in = (Bytef*)[chunk bytes];
        int flush = Z_NO_FLUSH;
        if(chunk.length == 0)
            flush = Z_FINISH;
        do {
            NSMutableData *compressed = [NSMutableData dataWithLength:chunkSize];
            strm.avail_out = chunkSize;
            strm.next_out = (Bytef*)[compressed mutableBytes];
            NSInteger status = deflate (&strm, flush);
            if (status == Z_STREAM_END)
                done = YES;
            else if(status == Z_BUF_ERROR)
                continue;
            else if (status != Z_OK) {
                done = YES;
                return NO;
            }
            NSInteger have = chunkSize - strm.avail_out;
            [compressed setLength:have];
            [writeHandle writeData:compressed];
            
        } while (strm.avail_out == 0);
        
    } while (!done);
    deflateEnd(&strm);
    return YES;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
+(NSData*)inflate:(NSData*)data isGzip:(BOOL)isgzip
{
    if ([data length] == 0)
        return nil;
    
    uInt full_length = (uInt)[data length];
    uInt half_length = (uInt)[data length] / 2;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    BOOL done = NO;
    int status;
    
    z_stream strm;
    strm.next_in = (Bytef*)[data bytes];
    strm.avail_in = (uInt)[data length];
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
        strm.avail_out = (uInt)([decompressed length] - strm.total_out);
        
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END)
            done = YES;
        else if(status == Z_BUF_ERROR)
            continue;
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
    uInt chunkSize = 16384;
    do {
        NSData *chunk = [fileHandle readDataOfLength:chunkSize];
        strm.avail_in = (uInt)[chunk length];
        strm.next_in = (Bytef*)[chunk bytes];
        
        do {
            NSMutableData *decompressed = [NSMutableData dataWithLength:chunkSize];
            strm.avail_out = chunkSize;
            strm.next_out = (Bytef*)[decompressed mutableBytes];
            NSInteger status = inflate (&strm, Z_SYNC_FLUSH);
            if (status == Z_STREAM_END)
                done = YES;
            else if(status == Z_BUF_ERROR)
                continue;
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
