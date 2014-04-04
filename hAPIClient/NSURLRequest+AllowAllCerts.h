//
//  NSURLRequest+AllowAllCerts.h
//  hAPI
//
//  Created by Stuart Levine on 11/20/12.
//  Copyright (c) 2012 Stuart Levine. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLRequest (AllowAllCerts)

+ (BOOL) allowsAnyHTTPSCertificateForHost:(NSString *) host;

@end
