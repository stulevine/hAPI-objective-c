//
//  NSURLRequest+AllowAllCerts.m
//  hAPI
//
//  Created by Stuart Levine on 11/20/12.
//  Copyright (c) 2012 Stuart Levine. All rights reserved.
//

#import "NSURLRequest+AllowAllCerts.h"

@implementation NSURLRequest(AllowAllCerts)

+ (BOOL) allowsAnyHTTPSCertificateForHost:(NSString *) host {
    return YES;
}

@end