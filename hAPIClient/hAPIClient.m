//
//  hAPI.m
//
// self contained hAPI Objective-c framework with authentication, key/secret storage
// endpoint storage, specify customer_id for staff usage and the ability to make hAPI calls

#import "hAPIClient.h"
#import "NSData+Base64.h"
#import "NSURLRequest+AllowAllCerts.h"
#import <CommonCrypto/CommonDigest.h>

@implementation hAPIClient

@synthesize hAPIEndPoint = _hAPIEndPoint;
@synthesize hAPI_Key = _hAPI_Key;
@synthesize hAPI_Secret = _hAPI_Secret;
@synthesize hAPI_ClientID = _hAPI_ClientID;

- (id)initWithEndPoint:(NSString *)endPoint {
    self = [super init];
    
    if (self) {
        [self setHAPIEndPoint:endPoint];
    }
    
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        if (self.hAPIEndPoint != nil) {
            [self setHAPIEndPoint:self.hAPIEndPoint];
        }
        else {
            [self setHAPIEndPoint:HAPI_ENDPOINT];
        }
    }
    return self;
}

- (void)resetHAPI
{
    self.hAPI_ClientID = @"";
    self.hAPI_Key = @"";
    self.hAPI_Secret = @"";
}

- (BOOL)authenticated
{
    return (self.hAPI_Key != nil
            && self.hAPI_Secret != nil
            && ![self.hAPI_Key isEqualToString:@""]
            && ![self.hAPI_Secret isEqualToString:@""]);
}

- (void)setHAPIEndPoint:(NSString *)hAPIEndPoint
{
    _hAPIEndPoint = hAPIEndPoint;
    [self storeKVP:_hAPIEndPoint forKey:kHAPIEndPoint];
}

- (NSString *)hAPIEndPoint
{
    if (_hAPIEndPoint == nil) {
        _hAPIEndPoint = [self retrieveKVP:kHAPIEndPoint];
    }
    return _hAPIEndPoint;
}

- (void)setHAPI_ClientID:(NSString *)hAPI_ClientID
{
    _hAPI_ClientID = hAPI_ClientID;
    [self storeKVP:_hAPI_ClientID forKey:kHAPIClientID];
}

- (void)setHAPI_Key:(NSString *)hAPI_Key
{
    _hAPI_Key = hAPI_Key;
    [self storeKVP:_hAPI_Key forKey:kHAPIKey];
    
}
- (void)setHAPI_Secret:(NSString *)hAPI_Secret
{
    _hAPI_Secret = hAPI_Secret;
    [self storeKVP:_hAPI_Secret forKey:kHAPISecret];
}

- (NSString *)hAPI_ClientID
{
    if (_hAPI_ClientID == nil) {
        _hAPI_ClientID = [self retrieveKVP:kHAPIClientID];
    }
    return _hAPI_ClientID;
}

- (NSString *)hAPI_Key
{
    if (_hAPI_Key == nil) {
        _hAPI_Key = [self retrieveKVP:kHAPIKey];
    }
    return _hAPI_Key;
}

- (NSString *)hAPI_Secret
{
    if (_hAPI_Secret == nil) {
        _hAPI_Secret = [self retrieveKVP:kHAPISecret];
    }    
    return _hAPI_Secret;
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
        [params setObject:[elts objectAtIndex:1] forKey:[elts objectAtIndex:0]];
    }
    
    return params;
}

+ (NSDictionary *)dictFromQueryString:(NSString *)string
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for (NSString *kvp in [string componentsSeparatedByString:@"&"]) {
        //NSLog(@"%@",kvp);
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
    NSLog(@"endpoint: %@", self.hAPIEndPoint);
    NSString *query = [NSString stringWithFormat:@"%@?method=hapi.authkeys.read&format=json", self.hAPIEndPoint];
    NSString *loginstring = [NSString stringWithFormat:@"%@:%@", username, password];
    NSData *encodedLoginData = [loginstring dataUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedLoginString = [encodedLoginData base64Encoding_xcd];
    NSString *authHeader = [@"Basic " stringByAppendingFormat:@"%@", encodedLoginString];
    NSURL *url = [NSURL URLWithString:query];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url
                                                           cachePolicy: NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval: 5];
    
    [NSMutableURLRequest allowsAnyHTTPSCertificateForHost:url.host];
    [request addValue:authHeader forHTTPHeaderField:@"Authorization"];
    
    NSURLResponse *response;
    
    NSError *error = nil;

    NSData *jsonData = [NSURLConnection sendSynchronousRequest: request returningResponse: &response error: &error];
    
    NSDictionary *results = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error] : nil;
    if (error) NSLog(@"[%@ %@] JSON error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error.localizedDescription);
    NSLog(@"%@", results);
    if ([results valueForKeyPath:@"authkey"] != nil) {
        self.hAPI_Key = [results valueForKeyPath:@"authkey.key"];
        self.hAPI_Secret = [results valueForKeyPath:@"authkey.secret"];
        return results;
    }
    else {
        self.hAPI_Key = [results valueForKeyPath:@"response.authkey.key"];
        self.hAPI_Secret = [results valueForKeyPath:@"response.authkey.secret"];
        return [results valueForKeyPath:@"response"];
    }
}

- (NSDictionary *)makehAPICall:(NSString *)method withFormat:(NSString *)format
{
    return [self makehAPICall:method params:nil withKey:self.hAPI_Key withSecret:self.hAPI_Secret withFormat:format];
}

- (NSDictionary *)makehAPICall:(NSString *)method params:(NSDictionary *)params withFormat:(NSString *)format
{
    return [self makehAPICall:method params:params withKey:self.hAPI_Key withSecret:self.hAPI_Secret withFormat:format];
}

- (NSDictionary *)makehAPICall:(NSString *)method params:(NSDictionary *)params withKey:(NSString *)key withSecret:(NSString *)secret withFormat:(NSString *)format
{    
    NSString *urlString = [NSString stringWithFormat:@"%@?format=%@&key=%@&timestamp=%@&method=%@",
                            self.hAPIEndPoint,
                            format,
                            key,
                            [hAPIClient makeTimeStamp],
                            method];
    
    NSString *queryString = [hAPIClient queryStringFromDictionary:params];
    
    if (self.hAPI_ClientID != nil && ![self.hAPI_ClientID isEqualToString:@""]) {
        if ([queryString length])
            queryString = [NSString stringWithFormat:@"customer_id=%@&%@", self.hAPI_ClientID, queryString];
        else
            queryString = [NSString stringWithFormat:@"customer_id=%@", self.hAPI_ClientID];
    }
    
    if ([queryString length])
        urlString = [urlString stringByAppendingFormat:@"&%@",queryString];

    NSURL *requestURL = [NSURL URLWithString: [hAPIClient signedURLFromURL:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                                          withSecret:secret]];
    //NSLog(@"[%@ %@] sent %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), requestURL);
    
    NSData *jsonData = [[NSString stringWithContentsOfURL:requestURL encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error = nil;

    NSDictionary *results = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error] : nil;
    if (error) NSLog(@"[%@ %@] JSON error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error.localizedDescription);
    return results;
}

- (void)makehAPICallAsynchronous:(NSString *)method withFormat:(NSString *)format
{
    return [self makehAPICallAsynchronous:method params:nil withKey:self.hAPI_Key withSecret:self.hAPI_Secret withFormat:format];
}

- (void)makehAPICallAsynchronous:(NSString *)method params:(NSDictionary *)params withFormat:(NSString *)format
{
    return [self makehAPICallAsynchronous:method params:params withKey:self.hAPI_Key withSecret:self.hAPI_Secret withFormat:format];
}

- (void)makehAPICallAsynchronous:(NSString *)method params:(NSDictionary *)params withKey:(NSString *)key withSecret:(NSString *)secret withFormat:(NSString *)format
{
    NSString *urlString = [NSString stringWithFormat:@"%@?format=%@&key=%@&timestamp=%@&method=%@",
                           self.hAPIEndPoint,
                           format,
                           key,
                           [hAPIClient makeTimeStamp],
                           method];
    
    NSString *queryString = [hAPIClient queryStringFromDictionary:params];
    
    if (self.hAPI_ClientID != nil && ![self.hAPI_ClientID isEqualToString:@""]) {
        if ([queryString length])
            queryString = [NSString stringWithFormat:@"customer_id=%@&%@", self.hAPI_ClientID, queryString];
        else
            queryString = [NSString stringWithFormat:@"customer_id=%@", self.hAPI_ClientID];
    }
        
    if ([queryString length])
        urlString = [urlString stringByAppendingFormat:@"&%@",queryString];
    
    NSURL *requestURL = [NSURL URLWithString: [hAPIClient signedURLFromURL:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                                          withSecret:secret]];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    {
        NSError *dataError = nil;
        NSDictionary *results = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&dataError] : nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:kHAPICallFinishedLoading object:results];
        if (dataError) NSLog(@"[%@ %@] JSON error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), dataError.localizedDescription);
    }];
}

#pragma Mark - Delegate Methods

- (void)storeKVP:(id)object forKey:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id)retrieveKVP:(NSString *)key
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

@end
