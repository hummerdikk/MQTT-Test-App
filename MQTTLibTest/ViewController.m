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
    
    //If we are starting the mqtt first, let's do some setup
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
    }else{
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
        case MQTTSessionManagerStateClosed:
            self.MessageLabel.text = @"closed";
            self.DisconnectButton.enabled = false;
            self.ConnectButton.enabled = false;
            break;
        case MQTTSessionManagerStateClosing:
            self.MessageLabel.text = @"closing";
            self.DisconnectButton.enabled = false;
            self.ConnectButton.enabled = false;
            break;
        case MQTTSessionManagerStateConnected:
            self.MessageLabel.text = [NSString stringWithFormat:@"connected as %@-%@",
                                [UIDevice currentDevice].name,
                                self.tabBarItem.title];
            self.DisconnectButton.enabled = true;
            self.ConnectButton.enabled = false;
            [self.mqttManager sendData:[@"joins" dataUsingEncoding:NSUTF8StringEncoding]
                             topic:[NSString stringWithFormat:@"%@/%@-%@",
                                    @"hello",
                                    [UIDevice currentDevice].name,
                                    self.tabBarItem.title]
                               qos:MQTTQosLevelExactlyOnce
                            retain:FALSE];
            
            break;
        case MQTTSessionManagerStateConnecting:
            self.MessageLabel.text = @"connecting";
            self.DisconnectButton.enabled = false;
            self.ConnectButton.enabled = false;
            break;
        case MQTTSessionManagerStateError:
            self.MessageLabel.text = @"error";
            self.DisconnectButton.enabled = false;
            self.ConnectButton.enabled = false;
            break;
        case MQTTSessionManagerStateStarting:
        default:
            self.MessageLabel.text = @"not connected";
            self.DisconnectButton.enabled = false;
            self.ConnectButton.enabled = true;
            break;
    }
}

- (IBAction)conn :(id)sender)

@end
