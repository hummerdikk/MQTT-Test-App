//
//  ViewController.m
//  MQTTLibTest
//
//  Created by Kertész Tibor on 26/08/15.
//  Copyright (c) 2015 Kertész Tibor. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (strong,nonatomic) MQTTSessionManager *mqttManager;

@property (weak, nonatomic) IBOutlet UIButton *ConnectButton;
@property (weak, nonatomic) IBOutlet UIButton *DisconnectButton;
@property (weak, nonatomic) IBOutlet UILabel *MessageLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!self.mqttManager) {
        self.mqttManager = [[MQTTSessionManager alloc] init];
        self.mqttManager.delegate = self;
        self.mqttManager.subscriptions = [[NSMutableDictionary alloc] init];
        [self.mqttManager.subscriptions setObject:[NSNumber numberWithInt:MQTTQosLevelAtMostOnce]
                                           forKey:[NSString stringWithFormat:@"%@/#", @"/home"]];
        
        [self.mqttManager connectTo:@"fds-node1.cloudapp.net"
                               port:1883
                                tls:FALSE
                          keepalive:60
                              clean:TRUE
                               auth:FALSE
                               user:nil
                               pass:nil
                          willTopic:[NSString stringWithFormat:@"%@/%@-%@",
                                     @"will",
                                     [UIDevice currentDevice].name,
                                     self.tabBarItem.title]
                               will:[@"willmsq" dataUsingEncoding:NSUTF8StringEncoding]
                            willQos:MQTTQosLevelExactlyOnce
                     willRetainFlag:FALSE
                       withClientId:[UIDevice currentDevice].name];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
