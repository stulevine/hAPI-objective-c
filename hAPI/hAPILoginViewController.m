//
//  hAPILoginViewController.m
//  hAPI
//
//  Created by Stuart Levine on 4/3/14.
//  Copyright (c) 2014 Stuart Levine. All rights reserved.
//

#import "hAPILoginViewController.h"
#import "hAPIClient.h"

#define ShowNetworkActivityIndicator() [UIApplication sharedApplication].networkActivityIndicatorVisible = YES
#define HideNetworkActivityIndicator() [UIApplication sharedApplication].networkActivityIndicatorVisible = NO

@interface hAPILoginViewController ()
@property (strong, nonatomic) IBOutlet UITextField *username;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) hAPIClient *hAPIClient;
@property (strong, nonatomic) NSString *hAPI_Endpoint;
@property (strong, nonatomic) IBOutlet UITextField *hAPIEndpoint;

@end

@implementation hAPILoginViewController

@synthesize hAPIClient = _hAPIClient;
@synthesize hAPI_Endpoint = _hAPI_Endpoint;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (hAPIClient *)hAPIClient {
    if (_hAPIClient == NULL) {
        hAPIAppDelegate *delegate = [hAPIAppDelegate sharedDelegate];
        _hAPIClient = delegate.hAPIClient;
    }
    return _hAPIClient;
}

- (NSString *)hAPI_Endpoint {
    if (_hAPI_Endpoint == NULL) {
        _hAPI_Endpoint = self.hAPIEndpoint.text;
    }
    return _hAPI_Endpoint;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.password setDelegate:self];
    self.hAPIEndpoint.text = @"https://api.voxel.net/version/1.5/";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)loginAction:(UIButton *)sender
{
    [self.password resignFirstResponder];
    [self.username resignFirstResponder];
    [self.hAPIEndpoint resignFirstResponder];
    if ([self.hAPI_Endpoint length]) {
        [self.hAPIClient setHAPIEndPoint:self.hAPI_Endpoint];
    }
    ShowNetworkActivityIndicator();
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.internaplabs.hAPI", NULL);
    dispatch_async(backgroundQueue, ^{
        NSDictionary *result = [self.hAPIClient fetchAuthTokenAndSecret:self.username.text password:self.password.text];
        if ([[result valueForKey:@"status"] isEqualToString:@"fail"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Auth Failure" message:[result valueForKeyPath:@"error.message"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                HideNetworkActivityIndicator();
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                HideNetworkActivityIndicator();
                [self dismissViewControllerAnimated:YES completion:^{}];
            });
        }
    });

}

#pragma Mark UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self loginAction:nil];
    return NO;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL)shouldAutorotate {
    return false;
}

@end
