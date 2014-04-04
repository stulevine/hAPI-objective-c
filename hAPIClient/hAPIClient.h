//
// hAPI.h
//

#import <Foundation/Foundation.h>

#define HAPI_ENDPOINT @"https://api.voxel.net/version/1.5/"

@protocol hAPIStoreDelegate;

@interface hAPIClient : NSObject

@property (nonatomic, strong) NSString *hAPIEndPoint;
@property (nonatomic, strong) NSString *hAPI_Key;
@property (nonatomic, strong) NSString *hAPI_Secret;
@property (nonatomic, strong) NSString *hAPI_ClientID;

// Storage Contants - default is to use NSUserDefaults
//
#define kHAPIEndPoint   @"hAPIEndPoint"
#define kHAPIClientID   @"hAPIClientID"
#define kHAPIKey        @"hAPIKey"
#define kHAPISecret     @"hAPISecret"

// hAPI Output Formats
#define kJSON   @"json"
#define kXML    @"xml"
#define kRAW    @"raw"

// Notification Center Subscription string for Asynchronous calls - notification when complete
//
#define kHAPICallFinishedLoading @"hAPICallFinished"

- (id)initWithEndPoint:(NSString *)endPoint;
+ (NSString *)MD5HexStringFromNSString:(NSString *)inStr;
+ (NSString *)signRequestFromArguments:(NSDictionary *)inArguments withSecret:(NSString *)secret;
+ (NSString *)makeTimeStamp;
- (NSDictionary *)fetchAuthTokenAndSecret:(NSString *)username password:(NSString *)password;
- (NSDictionary *)makehAPICall:(NSString *)method withFormat:(NSString *)format;
- (NSDictionary *)makehAPICall:(NSString *)method params:(NSDictionary *)params withFormat:(NSString *)format;
- (NSDictionary *)makehAPICall:(NSString *)method params:(NSDictionary *)params withKey:(NSString *)key withSecret:(NSString *)secret withFormat:(NSString *)format;
- (void)makehAPICallAsynchronous:(NSString *)method withFormat:(NSString *)format;
- (void)makehAPICallAsynchronous:(NSString *)method params:(NSDictionary *)params withFormat:(NSString *)format;
- (void)makehAPICallAsynchronous:(NSString *)method params:(NSDictionary *)params withKey:(NSString *)key withSecret:(NSString *)secret withFormat:(NSString *)format;
+ (NSDictionary *)dictFromQueryString:(NSString *)string;
+ (NSString *)queryStringFromDictionary:(NSDictionary *)dict;
- (void)resetHAPI;
- (BOOL)authenticated;

@end

@protocol hAPIStoreDelegate <NSObject>

- (void)storeKVP:(id)object forKey:(NSString *)key;
- (id)retrieveKVP:(NSString *)key;

@end