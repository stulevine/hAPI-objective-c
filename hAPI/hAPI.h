//
// hAPI.h
//

#import <Foundation/Foundation.h>
#import "hAPIAppDelegate.h"

@interface hAPI : NSObject

@property (nonatomic, retain) NSString *hAPIEndPoint;

- (id)initWithEndPoint:(NSString *)endPoint;
+ (NSString *)MD5HexStringFromNSString:(NSString *)inStr;
+ (NSString *)signRequestFromArguments:(NSDictionary *)inArguments withSecret:(NSString *)secret;
+ (NSString *)makeTimeStamp;
- (NSDictionary *)fetchAuthTokenAndSecret:(NSString *)username password:(NSString *)password;
- (NSDictionary *)makehAPICall:(NSString *)method params:(NSDictionary *)params withKey:(NSString *)key withSecret:(NSString *)secret;
+ (NSDictionary *)dictFromQueryString:(NSString *)string;
+ (NSString *)queryStringFromDictionary:(NSDictionary *)dict;

@end
