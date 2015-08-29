//
//  ViewController.m
//  MQTTLibTest
//
//  Created by Kertész Tibor on 26/08/15.
//  Copyright (c) 2015 Kertész Tibor. All rights reserved.
//

#import "ViewController.h"
#import "Helper.h"

@interface ViewController ()

@property (strong,nonatomic) MQTTSessionManager *mqttManager;

@property (weak, nonatomic) IBOutlet UIButton *ConnectButton;
@property (weak, nonatomic) IBOutlet UIButton *DisconnectButton;
@property (weak, nonatomic) IBOutlet UILabel *MessageLabel;

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
            self.MessageLabel.text = @"closed";
            self.DisconnectButton.enabled = false;
            self.ConnectButton.enabled = false;
            break;
        }
        case MQTTSessionManagerStateClosing: {
            self.MessageLabel.text = @"closing";
            self.DisconnectButton.enabled = false;
            self.ConnectButton.enabled = false;
            break;
        }
        case MQTTSessionManagerStateConnected: {
            self.MessageLabel.text = [NSString stringWithFormat:@"connected as %@-%@",
                                [UIDevice currentDevice].name,
                                self.tabBarItem.title];
            self.DisconnectButton.enabled = true;
            self.ConnectButton.enabled = false;
            [self.mqttManager sendData:[@"joins" dataUsingEncoding:NSUTF8StringEncoding]
                             topic:@"/home"
                               qos:MQTTQosLevelExactlyOnce
                            retain:FALSE];
            
            break;
        }
        case MQTTSessionManagerStateConnecting: {
            self.MessageLabel.text = @"connecting";
            self.DisconnectButton.enabled = false;
            self.ConnectButton.enabled = false;
            break;
        }
        case MQTTSessionManagerStateError: {
            self.MessageLabel.text = @"error";
            self.DisconnectButton.enabled = false;
            self.ConnectButton.enabled = false;
            break;
        }
        case MQTTSessionManagerStateStarting:
        default: {
            self.MessageLabel.text = @"not connected";
            self.DisconnectButton.enabled = false;
            self.ConnectButton.enabled = true;
            break;
        }
    }
}

- (IBAction)connect:(id)sender{
    [self.mqttManager connectToLast];
}

- (IBAction)disconnect:(id)sender{
    
    
    NSData * sendData = [@"leaves" dataUsingEncoding:NSUTF8StringEncoding];
    [self.mqttManager sendData:sendData
                         topic:@"/home"
                           qos:MQTTQosLevelExactlyOnce
                        retain:FALSE];
    
    // this one looks like a very VERRRY dirty hack, ... and bad practice!
    // Tibi pls protect your idea here! IMPROTANT
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    
    [self.mqttManager disconnect];
}

//Handle the incomming message
- (void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained {
    /*
     * MQTTClient: process received message
     */
    
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *senderString = topic;
    
    self.MessageLabel.text = [NSString stringWithFormat:@"%@,%@",dataString,senderString];
}

@end
