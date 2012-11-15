//
//  hAPIViewController.h
//  hAPI
//
//  Created by Stuart Levine on 11/12/12.
//  Copyright (c) 2012 Stuart Levine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "hAPI.h"

@interface hAPIViewController : UIViewController
@property (strong, nonatomic) hAPI *hAPIClient;
@property (strong, nonatomic) IBOutlet UITextField *username;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) IBOutlet UIButton *authButton;
@property (strong, nonatomic) IBOutlet UITextView *output;
@property (strong, nonatomic) NSString *hAPI_Key;
@property (strong, nonatomic) NSString *hAPI_Secret;
@property (strong, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) IBOutlet UILabel *passwordLabel;
@property (strong, nonatomic) IBOutlet UILabel *callLabel;
@property (strong, nonatomic) IBOutlet UITextField *hAPICall;
@property (strong, nonatomic) IBOutlet UIButton *makeCallButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *working;
@property (strong, nonatomic) IBOutlet UITextField *params;
@property (strong, nonatomic) IBOutlet UILabel *paramsLabel;
@property (strong, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *outputFormat;
@property (weak, nonatomic) IBOutlet UILabel *formatLabel;

@end
