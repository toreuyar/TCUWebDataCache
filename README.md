TCUWebDataCache
===============

TCUWebDataCache
A simple web cache objective-c iOS library designed mainly for image caching.

Example usage is like:

```objectivec
TCUWebDataCache *webDataCache = [TCUWebDataCache sharedDataCache];
BOOL isCached = [webDataCache isDataFromURLCached:@"http://example.com/image.png"];
NSData *imageData = [webDataCache getDataFromURL:inboundImageURLString cached:YES];
UIImage *image = [UIImage imageWithData:imageData];
```

- Code is on ARC.
- `getDataFromURL:cached:` works synchronously, so it blocks calling thread. Avoid calling this method on main thread.
