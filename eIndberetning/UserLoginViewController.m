//
//  UserLoginViewController.m
//  OS2Indberetning
//
//  Created by Marc le Fevre Johansen on 14/02/16.
//  Copyright © 2016 IT-Minds. All rights reserved.
//

#import "UserLoginViewController.h"
#import "eMobilityHTTPSClient.h"
#import "ErrorMsgViewController.h"
#import "CoreDataManager.h"
#import "UserInfo.h"
#import "Profile.h"

@interface UserLoginViewController ()

//UI
@property (weak, nonatomic) IBOutlet UITextField *usernameInput;
@property (weak, nonatomic) IBOutlet UITextField *passwordInput;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

//Fields
@property (strong, nonatomic) eMobilityHTTPSClient *client;
@property (nonatomic, strong) ErrorMsgViewController* errorMsg;
@property (nonatomic,strong) CoreDataManager* CDManager;

@end

@implementation UserLoginViewController

-(CoreDataManager*)CDManager
{
    return [CoreDataManager sharedeCoreDataManager];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.client = [eMobilityHTTPSClient sharedeMobilityHTTPSClient];
    [self.client setBaseUrl:[NSURL URLWithString:self.appInfo.APIUrl]];
    [self.appInfo getImageDataIfNotPresent];

    UserInfo *userInfo = [UserInfo sharedManager];
    userInfo.appInfo = self.appInfo;
    [userInfo saveInfo];
    
    [self setupVisuals];
}

-(void)setupVisuals{
    UserInfo *info = [UserInfo sharedManager];
    [info loadInfo];
    
    [self.loginButton setBackgroundColor:info.appInfo.SecondaryColor];
    [self.loginButton setTitleColor:info.appInfo.TextColor forState:UIControlStateNormal];
    
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setBarTintColor:info.appInfo.PrimaryColor];
    [self.navigationController.navigationBar setTintColor:info.appInfo.SecondaryColor];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : info.appInfo.TextColor}];
    
    //Set back button to just an arrow
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    [[self navigationItem] setBackBarButtonItem:backButton];
    
    //Set title for navbar
    [self setTitle:@"Log ind"];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextView delegate methods
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return true;
}


#pragma mark - Navigation


- (IBAction)loginButtonPressed:(id)sender {
    
    //Check if input fields are empty
    if (self.usernameInput.text && !(self.usernameInput.text.length > 0)){
        [self handleErrorForMessage:@"Du skal indtaste et brugernavn"];
        return;
    }
    
    if (self.passwordInput.text && !(self.passwordInput.text.length > 0)){
        [self handleErrorForMessage:@"Du skal indtaste et password"];
        return;
    }
    
    NSLog(@"Logging in...");
    [self.client credentialsLogin:
                        self.usernameInput.text
                        password:self.passwordInput.text
    withBlock:^(NSURLSessionTask *task, id responseObject)
     {
         NSLog(@"%@", responseObject);
         
         UserInfo* info = [UserInfo sharedManager];
         
         NSDictionary *profileDic = [responseObject objectForKey:@"profile"];
         NSDictionary *rateDic = [responseObject objectForKey:@"rates"];
         
         Profile* profile = [Profile initFromJsonDic:profileDic];
         NSArray* rates = [Rate initFromJsonDic:rateDic];
         
         
         [self.CDManager deleteAllObjects:@"CDRate"];
         [self.CDManager deleteAllObjects:@"CDEmployment"];
         
         [self.CDManager insertEmployments:profile.employments];
         [self.CDManager insertRates:rates];
         
         //Transfer userdata to local userinfo object
         info.last_sync_date = [NSDate date];
         info.name = [NSString stringWithFormat:@"%@ %@", profile.FirstName, profile.LastName];
         info.home_loc = profile.homeCoordinate;
         info.profileId = profile.profileId;
         
         info.authorization = profile.authorization;
         
         [info saveInfo];
         
         AppDelegate* del =  [[UIApplication sharedApplication] delegate];
         [del changeToStartView];
         //[self performSegueWithIdentifier:@"ShowStartViewSegue" sender:self];
    }
    failBlock:^(NSURLSessionTask *task, NSError *error)
    {
         NSInteger errorCode = [error.userInfo[ErrorCodeKey] intValue];
        
        NSString* errorString = error.userInfo[ErrorMessageKey];
        
        [self handleErrorForMessage:errorString];
        
     }];
    
}

-(void) handleErrorForMessage:(NSString *) message{
    self.errorMsg = [[ErrorMsgViewController alloc] initWithNibName:@"ErrorMsgViewController" bundle:nil];
    [self.errorMsg showErrorMsg: message];
    
    CAKeyframeAnimation * anim = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
    anim.values = @[ [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-5.0f, 0.0f, 0.0f) ], [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(5.0f, 0.0f, 0.0f) ] ] ;
    anim.autoreverses = YES ;
    anim.repeatCount = 2.0f ;
    anim.duration = 0.07f ;
    
    [self.loginButton.layer addAnimation:anim forKey:nil];
    NSLog(@"Error message to show: %@", message);
}

/*
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
