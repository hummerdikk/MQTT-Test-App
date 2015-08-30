//
//  ViewController.m
//  MQTTLibTest
//
//  Created by Kertész Tibor on 26/08/15.
//  Copyright (c) 2015 Kertész Tibor. All rights reserved.
//

#import "ViewController.h"
#import "Helper.h"
#import <MQTTClient/MQTTClient.h>
#import <MQTTClient/MQTTSessionManager.h>

@interface ViewController ()<MQTTSessionManagerDelegate>

@property (strong,nonatomic) MQTTSessionManager *mqttManager;

@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UIButton *disconnectButton;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // If we are starting the mqtt first, let's do some setup
    if (self.mqttManager == nil) {
        
        self.mqttManager = [[MQTTSessionManager alloc] init];
        self.mqttManager.delegate = self;
        self.mqttManager.subscriptions = [[NSMutableDictionary alloc] init];
        
        self.mqttManager.subscriptions[kHomePathStr] = @(MQTTQosLevelAtMostOnce);
        
        [self.mqttManager connectTo:@"fds-node1.cloudapp.net"
                               port:1883
                                tls:NO
                          keepalive:60
                              clean:YES
                               auth:NO
                               user:nil
                               pass:nil
                               will:NO
                          willTopic:nil
                            willMsg:nil
                            willQos:MQTTQosLevelAtMostOnce
                     willRetainFlag:NO
                       withClientId:[UIDevice currentDevice].name];
    } else {
        //else we can reconnect to the last mqtt server
        [self.mqttManager connectToLast];
    }
    
    [self.mqttManager addObserver:self
                       forKeyPath:@"state"
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    switch (self.mqttManager.state) {
        case MQTTSessionManagerStateClosed: {
            self.messageLabel.text = @"closed";
            self.disconnectButton.enabled = NO;
            self.connectButton.enabled = NO;
            break;
        }
        case MQTTSessionManagerStateClosing: {
            self.messageLabel.text = @"closing";
            self.disconnectButton.enabled = NO;
            self.connectButton.enabled = NO;
            break;
        }
        case MQTTSessionManagerStateConnected: {
            self.messageLabel.text = [NSString stringWithFormat:@"connected as %@-%@",
                                [UIDevice currentDevice].name,
                                self.tabBarItem.title];
            self.disconnectButton.enabled = YES;
            self.connectButton.enabled = NO;
            [self.mqttManager sendData:[@"joins" dataUsingEncoding:NSUTF8StringEncoding]
                             topic:@"/home"
                               qos:MQTTQosLevelExactlyOnce
                            retain:NO];
            
            break;
        }
        case MQTTSessionManagerStateConnecting: {
            self.messageLabel.text = @"connecting";
            self.disconnectButton.enabled = NO;
            self.connectButton.enabled = NO;
            break;
        }
        case MQTTSessionManagerStateError: {
            self.messageLabel.text = @"error";
            self.disconnectButton.enabled = NO;
            self.connectButton.enabled = NO;
            break;
        }
        case MQTTSessionManagerStateStarting:
        default: {
            self.messageLabel.text = @"not connected";
            self.disconnectButton.enabled = NO;
            self.connectButton.enabled = YES;
            break;
        }
    }
}

- (IBAction)connectButtonTouched:(id)sender {
    [self.mqttManager connectToLast];
}

- (IBAction)disconnectButtonTouched:(id)sender {
    
    
    NSData * sendData = [@"leaves" dataUsingEncoding:NSUTF8StringEncoding];
    [self.mqttManager sendData:sendData
                         topic:@"/home"
                           qos:MQTTQosLevelExactlyOnce
                        retain:NO];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.mqttManager disconnect];
    });
    
}

#pragma mark - MQTTSessionManagerDelegate

//Handle the incomming message
- (void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained {
    /*
     * MQTTClient: process received message
     */
    
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *senderString = topic;
    
    self.messageLabel.text = [NSString stringWithFormat:@"%@,%@",dataString,senderString];
}

@end
