//
//  hAPI.m
//

#import "hAPI.h"
#import "hAPIKey.h"
#import "NSData+Base64.h"
#import <CommonCrypto/CommonDigest.h>

@implementation hAPI

@synthesize hAPIEndPoint = _hAPIEndPoint;

- (id)initWithEndPoint:(NSString *)endPoint {
    self = [super init];
    
    if (self) {
        [self setHAPIEndPoint:endPoint];
    }
    
    return self;
}

- (void)setHAPIEndPoint:(NSString *)hAPIEndPoint
{
    _hAPIEndPoint = hAPIEndPoint;
}

+ (NSString *)MD5HexStringFromNSString:(NSString *)inStr
{
    const char *data = [inStr UTF8String];
    CC_LONG length = (CC_LONG) strlen(data);
    
    unsigned char *md5buf = (unsigned char*)calloc(1, CC_MD5_DIGEST_LENGTH);
    
    CC_MD5_CTX md5ctx;
    CC_MD5_Init(&md5ctx);
    CC_MD5_Update(&md5ctx, data, length);
    CC_MD5_Final(md5buf, &md5ctx);
    
    NSMutableString *md5hex = [NSMutableString string];
	size_t i;
    for (i = 0 ; i < CC_MD5_DIGEST_LENGTH ; i++) {
        [md5hex appendFormat:@"%02x", md5buf[i]];
    }
    free(md5buf);
    return md5hex;
}

+ (NSString *)makeTimeStamp
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZ"];
    NSTimeZone *utc = [NSTimeZone timeZoneWithAbbreviation:@"EST"];
    [dateFormatter setTimeZone:utc];
    
    NSString *timestamp = [dateFormatter stringFromDate: [NSDate date]];
    return timestamp;
}

+ (NSString *)signRequestFromArguments:(NSDictionary *)inArguments withSecret:(NSString *)secret
{
    NSMutableDictionary *newArgs = [NSMutableDictionary dictionaryWithDictionary:inArguments];
	
	// combine the args
	NSMutableArray *argArray = [NSMutableArray array];
	NSMutableString *sigString = [NSMutableString stringWithString:secret];
	NSArray *sortedArgs = [[newArgs allKeys] sortedArrayUsingSelector:@selector(compare:)];
	NSEnumerator *argEnumerator = [sortedArgs objectEnumerator];
	NSString *nextKey;
	while ((nextKey = [argEnumerator nextObject])) {
		NSString *value = [newArgs objectForKey:nextKey];
		[sigString appendFormat:@"%@%@", nextKey, value];
		[argArray addObject:[NSArray arrayWithObjects:nextKey, value, nil]];
	}
	
	NSString *signature = [self MD5HexStringFromNSString:sigString];    
	return signature;
}

+ (NSString *)signedURLFromURL:(NSString *)url withSecret:(NSString *)secret
{
    NSMutableDictionary *params = [self paramsFromURLEscaped:url];
    
    return [NSString stringWithFormat:@"%@&api_sig=%@", url, [self signRequestFromArguments:params withSecret:secret]];
}

+ (NSMutableDictionary *)paramsFromURLEscaped:(NSString *)url
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *queryString = [[NSURL URLWithString:url] query];
    
    for (NSString *param in [queryString componentsSeparatedByString:@"&"]) {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        if([elts count] < 2) continue;
        [params setObject:[[elts objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:[elts objectAtIndex:0]];
    }
    
    return params;
}

+ (NSMutableDictionary *)paramsFromURL:(NSString *)url
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *queryString = [[NSURL URLWithString:url] query];
        
    for (NSString *param in [queryString componentsSeparatedByString:@"&"]) {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        if([elts count] < 2) continue;
        [params setObject:[elts objectAtIndex:1] forKey:[elts objectAtIndex:0]];
    }
    
    return params;
}

+ (NSDictionary *)dictFromQueryString:(NSString *)string
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for (NSString *kvp in [string componentsSeparatedByString:@"&"]) {
        NSArray *kv = [kvp componentsSeparatedByString:@"="];
        if([kv count] < 2) continue;
        [dict setObject:[kv objectAtIndex:1] forKey:[kv objectAtIndex:0]];
    }
    return dict;
}

+ (NSString *)queryStringFromDictionary:(NSDictionary *)dict
{
    NSString *queryString = [[NSString alloc] initWithFormat:@""];
    for (id key in dict) {
        if ([queryString length])
            queryString = [queryString stringByAppendingFormat:@"&"];
        queryString = [queryString stringByAppendingFormat:@"%@=%@", key, [dict objectForKey: key]];
    }
    return queryString;
}

- (NSDictionary *)fetchAuthTokenAndSecret:(NSString *)username password:(NSString *)password
{
    NSString *query = [NSString stringWithFormat:@"%@?method=voxel.hapi.authkeys.read&format=json", _hAPIEndPoint];
    NSMutableString *loginstring = [NSString stringWithFormat:@"%@:%@", username, password];
    NSData *encodedLoginData = [loginstring dataUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedLoginString = [encodedLoginData base64Encoding_xcd];
    NSString *authHeader = [@"Basic " stringByAppendingFormat:@"%@", encodedLoginString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString:query]
                                                           cachePolicy: NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval: 5];
    
    [request addValue:authHeader forHTTPHeaderField:@"Authorization"];
    
    NSURLResponse *response;
    NSError *error = nil;
    
    NSData *jsonData = [NSURLConnection sendSynchronousRequest: request returningResponse: &response error: &error];
    
    NSDictionary *results = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error] : nil;
    if (error) NSLog(@"[%@ %@] JSON error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error.localizedDescription);
    
    return [results valueForKeyPath:@"authkey"];
}

- (NSDictionary *)makehAPICall:(NSString *)method params:(NSDictionary *)params withKey:(NSString *)key withSecret:(NSString *)secret
{    
    NSString *urlString = [NSString stringWithFormat:@"%@?format=json&key=%@&timestamp=%@&method=%@",
                            _hAPIEndPoint,
                            key,
                            [hAPI makeTimeStamp],
                            method];
    
    NSString *queryString = [hAPI queryStringFromDictionary:params];
    //NSLog(@"qs: %@", queryString);
    
    if ([queryString length])
        urlString = [urlString stringByAppendingFormat:@"&%@",queryString];

    NSURL *requestURL = [NSURL URLWithString: [hAPI signedURLFromURL:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                                          withSecret:secret]];
    //NSLog(@"[%@ %@] sent %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), requestURL);
    
    NSData *jsonData = [[NSString stringWithContentsOfURL:requestURL encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error = nil;

    NSDictionary *results = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error] : nil;
    if (error) NSLog(@"[%@ %@] JSON error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error.localizedDescription);
    return results;
}

@end
