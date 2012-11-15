//
//  hAPIViewController.m
//  hAPI
//
//  Created by Stuart Levine on 11/12/12.
//  Copyright (c) 2012 Stuart Levine. All rights reserved.
//

#import "hAPIViewController.h"
#import "CustomButton.h"

#define HAPI_PREFIX @"voxel"

@interface hAPIViewController ()

@end

@implementation hAPIViewController

@synthesize hAPIClient = _hAPIClient;
@synthesize username = _username;
@synthesize password = _password;
@synthesize authButton = _authButton;
@synthesize usernameLabel = _usernameLabel;
@synthesize passwordLabel = _passwordLabel;
@synthesize output = _output;
@synthesize hAPI_Key = _hAPI_Key;
@synthesize hAPI_Secret = _hAPI_Secret;
@synthesize callLabel = _callLabel;
@synthesize hAPICall = _hAPICall;
@synthesize makeCallButton = _makeCallButton;
@synthesize working = _working;
@synthesize params = _params;
@synthesize paramsLabel = _paramsLabel;
@synthesize logoutButton = _logoutButton;

- (IBAction)authenticateHAPI:(id)sender {
    [self.password resignFirstResponder];
    [self.username resignFirstResponder];
    [self.working startAnimating];
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.internaplabs.hAPI", NULL);
    dispatch_async(backgroundQueue, ^{
        NSDictionary *result = [_hAPIClient fetchAuthTokenAndSecret:self.username.text password:self.password.text];
        self.hAPI_Key = [result valueForKey:@"key"];
        self.hAPI_Secret = [result valueForKey:@"secret"];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:self.hAPI_Key forKey:@"hAPI_Key"];
        [defaults setObject:self.hAPI_Secret forKey:@"hAPI_Secret"];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.output.text = [NSString stringWithFormat:@"key = %@\nsecret = %@", self.hAPI_Key, self.hAPI_Secret];
            [self toggleAuth:YES];
            [self.working stopAnimating];
        });
    });
}

- (IBAction)logout:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.hAPI_Key = @"";
    self.hAPI_Secret = @"";
    [defaults setObject:self.hAPI_Key forKey:@"hAPI_Key"];
    [defaults setObject:self.hAPI_Secret forKey:@"hAPI_Secret"];
    self.output.text = @"";
    [self toggleAuth:NO];
    
}

- (IBAction)makehAPICall:(id)sender {
    [self.hAPICall resignFirstResponder];
    [self.params resignFirstResponder];
    self.output.text = @"";
    [self.working startAnimating];
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.internaplabs.hAPI", NULL);
    dispatch_async(backgroundQueue, ^{
        NSDictionary *results = [_hAPIClient makehAPICall: [NSString stringWithFormat:@"%@.%@", HAPI_PREFIX, self.hAPICall.text]
                                            params:[hAPI dictFromQueryString: self.params.text]
                                           withKey:self.hAPI_Key
                                        withSecret:self.hAPI_Secret];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.output.text = [NSString stringWithFormat:@"%@", results];
            [self.working stopAnimating];
        });
    });
}

- (void)toggleAuth:(BOOL)onOff
{
    [self.authButton setHidden:onOff];
    [self.username setHidden:onOff];
    [self.password setHidden:onOff];
    [self.usernameLabel setHidden:onOff];
    [self.passwordLabel setHidden:onOff];
    [self.makeCallButton setHidden:!onOff];
    [self.callLabel setHidden:!onOff];
    [self.hAPICall setHidden:!onOff];
    [self.logoutButton setHidden:!onOff];
    [self.paramsLabel setHidden:!onOff];
    [self.params setHidden:!onOff];
    [self.outputFormat setHidden:!onOff];
    [self.formatLabel setHidden:!onOff];
}

- (void)viewDidAppear:(BOOL)animated
{
    [CustomButton addGradient:self.logoutButton];
    [CustomButton addGradient:self.authButton];
    [CustomButton addGradient:self.makeCallButton];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _hAPIClient = [[hAPI alloc] initWithEndPoint:@"https://api.voxel.net/version/1.0/"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.hAPI_Key = [defaults objectForKey:@"hAPI_Key"];
    self.hAPI_Secret = [defaults objectForKey:@"hAPI_Secret"];
    if ([self.hAPI_Key length] && [self.hAPI_Secret length]) {
        [self toggleAuth:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setOutputFormat:nil];
    [self setFormatLabel:nil];
    [super viewDidUnload];
}
@end
