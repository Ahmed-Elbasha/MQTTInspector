//
//  MQTTInspectorSetupSessionTableViewController.m
//  MQTTInspector
//
//  Created by Christoph Krey on 14.11.13.
//  Copyright © 2013-2016 Christoph Krey. All rights reserved.
//

#import "MQTTInspectorSetupSessionTableViewController.h"
#import "Model.h"
#import "MQTTInspectorDetailViewController.h"


@interface MQTTInspectorSetupSessionTableViewController ()
@property (weak, nonatomic) IBOutlet UITextField *nameText;
@property (weak, nonatomic) IBOutlet UITextField *hostText;
@property (weak, nonatomic) IBOutlet UITextField *portText;
@property (weak, nonatomic) IBOutlet UISwitch *tlsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *authSwitch;
@property (weak, nonatomic) IBOutlet UITextField *userText;
@property (weak, nonatomic) IBOutlet UITextField *passwdText;
@property (weak, nonatomic) IBOutlet UITextField *clientIdText;
@property (weak, nonatomic) IBOutlet UISwitch *cleansessionSwitch;
@property (weak, nonatomic) IBOutlet UITextField *keepaliveText;
@property (weak, nonatomic) IBOutlet UISwitch *autoConnectSwitch;
@property (weak, nonatomic) IBOutlet UITextField *protocolLevelText;
@property (weak, nonatomic) IBOutlet UITextField *sizeLimitText;
@property (weak, nonatomic) IBOutlet UISwitch *useWebsocketsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *allowUntrustedCertificatesSwitch;
@property (strong, nonatomic) UIDocumentInteractionController *dic;

@end

@implementation MQTTInspectorSetupSessionTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.title = self.session.name;
    
    self.nameText.text = self.session.name;
    self.hostText.text = self.session.host;
    self.portText.text = [NSString stringWithFormat:@"%@", self.session.port];
    self.tlsSwitch.on = [self.session.tls boolValue];
    self.allowUntrustedCertificatesSwitch.enabled = self.tlsSwitch.on;
    self.allowUntrustedCertificatesSwitch.on = [self.session.allowUntrustedCertificates boolValue];
    self.useWebsocketsSwitch.on = [self.session.websocket boolValue];
    self.authSwitch.on = [self.session.auth boolValue];
    self.userText.text = self.session.user;
    self.passwdText.text = self.session.passwd;
    self.clientIdText.text = self.session.clientid;
    self.cleansessionSwitch.on = [self.session.cleansession boolValue];
    self.keepaliveText.text = [NSString stringWithFormat:@"%@", self.session.keepalive];
    self.allowUntrustedCertificatesSwitch.on = [self.session.allowUntrustedCertificates boolValue];
    self.useWebsocketsSwitch.on = [self.session.websocket boolValue];
    self.autoConnectSwitch.on = [self.session.autoconnect boolValue];
    self.protocolLevelText.text = [NSString stringWithFormat:@"%@", self.session.protocolLevel];
    self.sizeLimitText.text = [NSString stringWithFormat:@"%@", self.session.sizelimit];
    
    self.nameText.delegate = self;
    self.hostText.delegate = self;
    self.portText.delegate = self;
    self.userText.delegate = self;
    self.passwdText.delegate = self;
    self.clientIdText.delegate = self;
    self.keepaliveText.delegate = self;
    self.protocolLevelText.delegate = self;
    self.sizeLimitText.delegate = self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"setSessionForFilters:"] ||
        [segue.identifier isEqualToString:@"setSessionForSubs:"] ||
        [segue.identifier isEqualToString:@"setSessionForPubs:"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setSession:)]) {
            [segue.destinationViewController performSelector:@selector(setSession:)
                                                  withObject:self.session];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (IBAction)nameChanged:(UITextField *)sender {
    
    NSString *newName = sender.text;

    Session *existingSession = [Session existSessionWithName:newName inManagedObjectContext:self.session.managedObjectContext];
    if (!existingSession || (existingSession == self.session)) {
        self.session.name = newName;
        self.title = self.session.name;
    } else {
        [MQTTInspectorDetailViewController alert:@"Duplicate Session"];
    }
}
- (IBAction)hostChanged:(UITextField *)sender {
    self.session.host = sender.text;
}
- (IBAction)portChanged:(UITextField *)sender {
    self.session.port = @([sender.text intValue]);
}
- (IBAction)tlsChanged:(UISwitch *)sender {
    self.session.tls = @(sender.on);
    if (sender.on) {
        self.session.port = @(8883);
    } else {
        self.session.port = @(1883);
    }
    self.portText.text = [NSString stringWithFormat:@"%@", self.session.port];
    self.allowUntrustedCertificatesSwitch.enabled = self.tlsSwitch.on;
}

- (IBAction)allowUntrustedCertificatesChanged:(UISwitch *)sender {
    self.session.allowUntrustedCertificates = @(sender.on);
}

- (IBAction)useWebsocketsChanged:(UISwitch *)sender {
    self.session.websocket = @(sender.on);
}

- (IBAction)authChanged:(UISwitch *)sender {
    self.session.auth = @(sender.on);
}

- (IBAction)userChanged:(UITextField *)sender {
    self.session.user = sender.text;
}

- (IBAction)passwdChanged:(UITextField *)sender {
    self.session.passwd = sender.text;
}

- (IBAction)clientIdChanged:(UITextField *)sender {
    self.session.clientid = sender.text;
}

- (IBAction)cleansessionChanged:(UISwitch *)sender {
    self.session.cleansession = @(sender.on);
}

- (IBAction)keepalvieChanged:(UITextField *)sender {
    self.session.keepalive = @([sender.text intValue]);
}

- (IBAction)autoConnectChanged:(UISwitch *)sender {
    self.session.autoconnect = @(sender.on);
}

- (IBAction)dnssrvSelected:(UIStoryboardSegue *)segue
{
    self.hostText.text = self.session.host;
    self.portText.text = [NSString stringWithFormat:@"%@", self.session.port];
}
- (IBAction)protocolLevelChanged:(UITextField *)sender {
    self.session.protocolLevel = @([sender.text intValue]);
}

- (IBAction)sizeLimitChanged:(UITextField *)sender {
    self.session.sizelimit = @([sender.text intValue]);
}

- (IBAction)send:(UIBarButtonItem *)sender {
    NSMutableArray *subs = [[NSMutableArray alloc] init];
    for (Subscription *sub in self.session.hasSubs) {
        [subs addObject:@{@"topic": [sub.topic description],
                          @"qos": [sub.qos description]
                          }];
    }
    
    NSMutableArray *pubs = [[NSMutableArray alloc] init];
    for (Publication *pub in self.session.hasPubs) {
        [pubs addObject:@{@"name": [pub.name description],
                          @"topic": [pub.topic description],
                          @"qos": [pub.qos description],
                          @"retained": [pub.retained description]
                          }];
    }
    
    NSDictionary *dict = @{@"_type": @"MQTTInspector-Session",
                           @"name": self.session.name ? self.session.name : @"",
                           @"host": self.session.host ? self.session.host : @"",
                           @"port": [NSString stringWithFormat:@"%@", self.session.port ? self.session.port : @(0)],
                           @"tls": [NSString stringWithFormat:@"%@", self.session.tls ? self.session.tls : @(0)],
                           @"auth": [NSString stringWithFormat:@"%@", self.session.auth ? self.session.auth : @(0)],
                           @"user": self.session.user ? self.session.user : @"",
                           @"passwd": self.session.passwd ? self.session.passwd : @"",
                           @"clientid": self.session.clientid ? self.session.clientid : @"",
                           @"cleansession": [NSString stringWithFormat:@"%@", self.session.cleansession ? self.session.cleansession : @(0)],
                           @"keepalive": [NSString stringWithFormat:@"%@", self.session.keepalive ? self.session.keepalive : @(60)],
                           @"websocket": [NSString stringWithFormat:@"%@", self.session.websocket ? self.session.websocket : @(0)],
                           @"allowUntrustedCertificates": [NSString stringWithFormat:@"%@", self.session.allowUntrustedCertificates ? self.session.allowUntrustedCertificates : @(0)],
                           @"autoconnect": [NSString stringWithFormat:@"%@", self.session.autoconnect ? self.session.autoconnect : @(0)],
                           @"protocollevel": [NSString stringWithFormat:@"%@", self.session.protocolLevel ? self.session.protocolLevel : @(0)],
                           @"sizeLimit": [NSString stringWithFormat:@"%@", self.session.sizelimit ? self.session.sizelimit : @(0)],
                           @"includefilter": [NSString stringWithFormat:@"%@", self.session.includefilter ? self.session.includefilter : @(1)],
                           @"attributefilter": self.session.attributefilter ? self.session.attributefilter : @"",
                           @"datafilter": self.session.datafilter ? self.session.datafilter : @"",
                           @"topicfilter": self.session.topicfilter ? self.session.topicfilter : @"",
                           @"subs": subs,
                           @"pubs": pubs
                           };
    
    NSError *error;
    NSData *myData = [NSJSONSerialization dataWithJSONObject:dict
                                                     options:NSJSONWritingPrettyPrinted
                                                       error:&error];
    
    NSURL *directoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    NSString *fileName = [NSString stringWithFormat:@"session.mqti"];
    NSURL *fileURL = [directoryURL URLByAppendingPathComponent:fileName];
    

    [[NSFileManager defaultManager] createFileAtPath:[fileURL path]
                                            contents:myData
                                          attributes:nil];
    
    self.dic = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    self.dic.delegate = self;
    [self.dic presentOptionsMenuFromBarButtonItem:sender animated:YES];
    
}

@end
