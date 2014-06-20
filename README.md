tarkit
======

untar and tar files on iOS and OS X. Also supports gzip tars. 

## Example

## Untar

```objc
NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
NSString* dataPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"test.tar.gz"];
NSString* toPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"testDir"];
[DCTar decompressFileAtPath:dataPath toPath:toPath error:nil];
```

##Tar

```objc
NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
NSString* toPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"test.tar.gz"];
NSString* dataPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"testDir"];
[DCTar compressFileAtPath:dataPath toPath:toPath error:nil];
```


## Discussion
It is important to know that all the file system based tar commands used chunked/buffer methods to save memory. Due to the fact that tars are normally used to compress lots of content, It is strongly recommend to use those method versus the in memory data options.

## Credit

I got some of the tar code from here:

- [Light-Untar-for-iOS](https://github.com/mhausherr/Light-Untar-for-iOS)

## Install ##

The recommended approach for installing tarkit is via the CocoaPods package manager (like most libraries).

## Requirements ##

tarkit requires at least iOS 5/OSX 10.7 or above.


## License ##

tarkit is license under the Apache License.

## Contact ##

### Dalton Cherry ###
* https://github.com/daltoniam
* http://twitter.com/daltoniam
* http://daltoniam.com
