//
//  UploadDriveViewController.m
//  eIndberetning
//
//  Created by Jacob Hansen on 09/11/14.
//  Copyright (c) 2014 IT-Minds. All rights reserved.
//

#import "UploadDriveViewController.h"
#import "eMobilityHTTPSClient.h"
#import "UserInfo.h"
#import "Settings.h"

@interface UploadDriveViewController ()
@property (weak, nonatomic) IBOutlet UIButton *tryAgianButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIImageView *municipalityLogoImageView;
@property (weak, nonatomic) IBOutlet UILabel *infoText;

@property (strong, nonatomic) SavedReport * savedReport;
@property (strong, nonatomic) NSArray *rates;
@property (strong,nonatomic) Profile* profile;
@end

@implementation UploadDriveViewController

const double WAIT_TIME_S = 1.5;

-(void)setupVisuals
{
    UserInfo* info = [UserInfo sharedManager];
    [info loadInfo];
    
    [self.cancelButton setBackgroundColor:info.appInfo.TextColor];
    [self.cancelButton setTitleColor:info.appInfo.SecondaryColor forState:UIControlStateNormal];
    self.cancelButton.layer.cornerRadius = 1.5f;
    
    [self.tryAgianButton setBackgroundColor:info.appInfo.SecondaryColor];
    [self.tryAgianButton setTitleColor:info.appInfo.TextColor forState:UIControlStateNormal];
    self.tryAgianButton.layer.cornerRadius = 1.5f;
    
    [self.municipalityLogoImageView setImage:info.appInfo.ImgData];
    
    [self.spinner setColor:info.appInfo.SecondaryColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    self.infoText.numberOfLines = 2;
    
    [self setupVisuals];
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
    
    [dic setObject:[[self.report transformToDictionary] mutableCopy] forKey:@"DriveReport"];
    
    NSError * err;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&err];
    NSString * myString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    _savedReport =  [SavedReport new];
    _savedReport.jsonToSend = myString;
    _savedReport.rate = _report.rate.rateDescription;
    _savedReport.purpose = _report.purpose.purpose;
    _savedReport.totalDistance = _report.route.totalDistanceEdit;
    _savedReport.createdAt = [NSDate new];
    [Settings addSavedReport:_savedReport];
    NSLog(@"dic: %@", myString);
    [self doSync];
}

-(void)doSync
{
    
    UserInfo* info = [UserInfo sharedManager];
    eMobilityHTTPSClient* client = [eMobilityHTTPSClient sharedeMobilityHTTPSClient];
    self.spinner.hidden = NO;
    [self.spinner startAnimating];
    [client postDriveReport:self.report forToken:info.token withBlock:^(NSURLSessionTask *task, id resonseObject)
     {
         [self.spinner stopAnimating];
         self.spinner.hidden = YES;
         [Settings removeSavedReport:_savedReport];
         //Optional: also sync userdata on succesfull submit
         NSDictionary *profileDic = [resonseObject objectForKey:@"profile"];
         NSDictionary *rateDic = [resonseObject objectForKey:@"rates"];
         
         self.profile = [Profile initFromJsonDic:profileDic];
         self.rates = [Rate initFromJsonDic:rateDic];
         //Optional
         
        self.infoText.text = @"Din indberetning er modtaget.";
        [NSTimer scheduledTimerWithTimeInterval:WAIT_TIME_S target:self selector:@selector(succesSync) userInfo:nil repeats:NO];
     }
     failBlock:^(NSURLSessionTask * task, NSError *Error)
     {
         self.spinner.hidden = YES;
         [self.spinner stopAnimating];
         NSLog(@"%@", Error);
         
         NSInteger errorCode = [Error.userInfo[ErrorCodeKey] intValue];
         [self failSyncWithErrorCode:(NSInteger)errorCode];
     }];
}

-(void) succesSync
{
    //Optional: also sync userdata on succesfull submit
    [self.delegate didFinishSyncWithProfile:self.profile AndRate:self.rates];
    //Optional
    [self dismissViewControllerAnimated:true completion:nil];
    [self.delegate didFinishUpload];
}

- (void) failSyncWithErrorCode:(NSInteger)errorCode
{
    if(errorCode == TokenNotFound)
    {
        [self.delegate tokenNotFound];
        [self dismissViewControllerAnimated:true completion:nil];
    }
    else
    {
        //Change text, hide spinner, show button
        self.infoText.text = @"Der skete en fejl ved afsendelsen af din rapport! Prøv igen eller tryk på 'Gem' og send rapporten fra hovedmenuen på et andet tidspunkt.";
        self.spinner.hidden = true;
        self.tryAgianButton.hidden = false;
        self.cancelButton.hidden = false;
    }
}

- (IBAction)tryAgianButtonPressed:(id)sender {
    self.spinner.hidden = false;
    self.tryAgianButton.hidden = true;
    self.cancelButton.hidden = true;
    
    self.infoText.text = @"Uploader kørselsdata";
    [self doSync];
}

//This is action called alongside an unwind to StartDriveTableViewVC
- (IBAction)cancelButtonPressed:(id)sender {
    //Reset the report, so that a clean report is shown in StartDriveTableViewVC
    //(It is already saved to Settings)
    self.report.shouldReset = true;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
