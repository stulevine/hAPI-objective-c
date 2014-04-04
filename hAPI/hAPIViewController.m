//
//  hAPIViewController.m
//  hAPI
//
//  Created by Stuart Levine on 11/12/12.
//  Copyright (c) 2012 Stuart Levine. All rights reserved.
//
#import "hAPIViewController.h"
#import "hAPILoginViewController.h"

#define HAPI_PREFIX @"voxel"

#define ShowNetworkActivityIndicator() [UIApplication sharedApplication].networkActivityIndicatorVisible = YES
#define HideNetworkActivityIndicator() [UIApplication sharedApplication].networkActivityIndicatorVisible = NO

@interface hAPIViewController ()
@property (nonatomic, strong) hAPILoginViewController *loginViewController;
@property (strong, nonatomic) IBOutlet UITextField *hAPI_ClientID;

@end

@implementation hAPIViewController

@synthesize hAPIClient = _hAPIClient;
@synthesize username = _username;
@synthesize password = _password;
@synthesize authButton = _authButton;
@synthesize usernameLabel = _usernameLabel;
@synthesize passwordLabel = _passwordLabel;
@synthesize output = _output;
@synthesize callLabel = _callLabel;
@synthesize hAPICall = _hAPICall;
@synthesize makeCallButton = _makeCallButton;
@synthesize working = _working;
@synthesize params = _params;
@synthesize paramsLabel = _paramsLabel;
@synthesize logoutButton = _logoutButton;
@synthesize hAPI_Endpoint = _hAPI_Endpoint;
@synthesize loginViewController = _loginViewController;

- (hAPILoginViewController *)loginViewController {
    if (_loginViewController == NULL) {
        _loginViewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"Login"];
    }
    return _loginViewController;
}

- (NSString *)hAPI_Endpoint {
    if (_hAPI_Endpoint == NULL) {
        _hAPI_Endpoint = @"https://api.voxel.net/version/1.5/";
    }
    return _hAPI_Endpoint;
}

- (hAPIClient *)hAPIClient {
    if (_hAPIClient == NULL) {
        hAPIAppDelegate *delegate = [hAPIAppDelegate sharedDelegate];
        _hAPIClient = delegate.hAPIClient;
    }
    return _hAPIClient;
}

- (IBAction)logout:(id)sender {
    self.output.text = @"";
    [self.hAPIClient resetHAPI];
    [self presentViewController:self.loginViewController animated:YES completion:^{}];
}

- (IBAction)makehAPICall:(id)sender {
    [self.hAPICall resignFirstResponder];
    [self.params resignFirstResponder];
    [self.hAPI_ClientID resignFirstResponder];
    if ([self.hAPI_ClientID.text length]) {
        [self.hAPIClient setHAPI_ClientID:self.hAPI_ClientID.text];
    }
    self.output.text = @"";
    [self.working startAnimating];
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.internaplabs.hAPI", NULL);
    dispatch_async(backgroundQueue, ^{
        NSDictionary *results = [self.hAPIClient makehAPICall:[NSString stringWithFormat:@"%@.%@", HAPI_PREFIX, self.hAPICall.text]
                                                        params:[hAPIClient dictFromQueryString: self.params.text]
                                                    withFormat:@"json"];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.output.text = [NSString stringWithFormat:@"%@", results];
            [self.working stopAnimating];
        });
    });
}

- (void)viewDidAppear:(BOOL)animated {
    if (![self.hAPIClient authenticated]) {
        [self presentViewController:self.loginViewController animated:YES completion:^{}];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.hAPICall setDelegate:self];
    [self.params setDelegate:self];
    [self.hAPI_ClientID setDelegate:self];
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

- (BOOL)shouldAutorotate {
    return false;
}

#pragma Mark UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

@end
