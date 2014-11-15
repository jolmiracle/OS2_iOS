//
//  InitialVIewController.m
//  eIndberetning
//
//  Created by Jacob Hansen on 24/09/14.
//  Copyright (c) 2014 IT-Minds. All rights reserved.
//

#import "InitialVIewController.h"
#import "eMobilityHTTPSClient.h"
#import "Profile.h"
#import "UserInfo.h"
#import "AppDelegate.h"

@interface InitialVIewController ()
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (strong, nonatomic) eMobilityHTTPSClient *client;
@end

@implementation InitialVIewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
        
    self.textField.delegate = self;
    self.client = [eMobilityHTTPSClient sharedeMobilityHTTPSClient];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return true;
}

- (IBAction)okButtonPressed:(id)sender {
    
    [self.client syncWithToken:self.textField.text withBlock:^(NSURLSessionTask *task, id resonseObject)
     {
         NSLog(@"%@", resonseObject);
         
         NSDictionary *profileDic = resonseObject;
         
         Profile* profile = [Profile initFromJsonDic:profileDic];
         UserInfo* info = [UserInfo sharedManager];
         
         //Search through the tokens
         for (Token* token in profile.tokens) {
             if([token.tokenString isEqualToString: self.textField.text]) //And something with status!
             {
                 info.guid = token.guid;
                 break;
             }
         }
         
         [info saveInfo];
         
         if(info.guid)
         {
             [self performSegueWithIdentifier:@"ShowStartViewSegue" sender:self];
         }
         else
         {
             //Print error message
         }
     }
     failBlock:^(NSURLSessionTask * task, NSError *Error)
     {
         NSLog(@"%@", Error);
         
     }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
