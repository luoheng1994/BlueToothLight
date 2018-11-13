//
//  BlueManager.h
//  BlueLight
//
//  Created by Rail on 6/30/16.
//  Copyright © 2016 Rail. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BTConst.h"
#import "BlueClient.h"
@class BlueManager;

@protocol BlueManagerDelegate <NSObject>

@optional
-(void)blueManager:(BlueManager *)manager didDiscoverClient:(BlueClient *)client;

-(void)blueManager:(BlueManager *)manager didDisConnectClient:(BlueClient *)client;

-(void)blueManager:(BlueManager *)manager didSuccessLoginClient:(BlueClient *)client;
-(void)blueManager:(BlueManager *)manager didFailLoginClient:(BlueClient *)client;
-(void)blueManager:(BlueManager *)manager didUpdateState:(CBCentralManagerState)state;

@end

@interface BlueManager : NSObject

@property (nonatomic, weak) id<BlueManagerDelegate> delegate;
@property (nonatomic, strong) CBCentralManager * centralManager;
@property (nonatomic, strong) dispatch_queue_t centralQueue;


-(BOOL)isPowerOn;
-(void)startScan;
-(void)stopScan;

-(void)loginWithPwd:(NSString *)pwd client:(BlueClient *)client;
-(void)cancelLogin:(BlueClient *)client;

@end
