//
//  BlueManager.m
//  BlueLight
//
//  Created by Rail on 6/30/16.
//  Copyright © 2016 Rail. All rights reserved.
//

#import "BlueManager.h"

struct Manufacture {
    Byte meshUUID[2];
    Byte mac[4];
    Byte productUUID[2];
    Byte status;
    Byte deviceAddress[2];
    
};
typedef struct Manufacture Manufacture;

@interface BlueManager ()<CBCentralManagerDelegate>

@property (nonatomic, assign) BOOL autoScan;
@property (nonatomic, strong) NSMutableArray *loginClients;

@property (nonatomic, strong) NSMutableArray *neaybyDevices;
@property (nonatomic, strong) NSMutableArray *connectableDevices;


@end

@implementation BlueManager

-(instancetype)init {
    self = [super init];
    if (self) {
        self.loginClients = [NSMutableArray new];
        self.centralQueue = dispatch_queue_create("com.rail.bluemanager", DISPATCH_QUEUE_SERIAL);
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:self.centralQueue options:@{CBCentralManagerOptionShowPowerAlertKey:@true}];
    }
    return self;
}

-(BOOL)isPowerOn {
    return self.centralManager.state == CBCentralManagerStatePoweredOn;
}

#pragma mark Scan Device

-(void)loginWithPwd:(NSString *)pwd client:(BlueClient *)client{
    
    [self.loginClients addObject:client];
    client.meshPwd = pwd;
    __block BlueManager *weakSelf = self;
    [client prepareLoginWithPwd:pwd block:^(BOOL success, BlueClient *loginClient) {
        if (success) {
            if ([weakSelf.delegate respondsToSelector:@selector(blueManager:didSuccessLoginClient:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.delegate blueManager:weakSelf didSuccessLoginClient:loginClient];
                });
            }
        }else {
            if ([weakSelf.delegate respondsToSelector:@selector(blueManager:didFailLoginClient:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.delegate blueManager:weakSelf didFailLoginClient:loginClient];
                });
                
            }
            [self cancelLogin:loginClient];
        }
        
        
    }];
    [self connectClient:client];
}

-(void)cancelLogin:(BlueClient *)client {
    if (client != nil && client.isConnected) {
        [self disConnectClient:client];
    }
}

-(void)connectClient:(BlueClient *)client {
    
    NSArray *peripherals = [self.centralManager retrievePeripheralsWithIdentifiers:@[[[NSUUID alloc] initWithUUIDString:client.uuidString]]];
    if (peripherals.count > 0) {
        client.peripheral = peripherals[0];
        [self.centralManager connectPeripheral:client.peripheral options:nil];
    }
}

-(void)disConnectClient:(BlueClient *)client {
    if (client.isConnected) {
       [self.centralManager cancelPeripheralConnection:client.peripheral];
    }
}

-(void)startScan {
    self.autoScan = true;
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
}

-(void)stopScan {
    self.autoScan = false;
    [self.centralManager stopScan];
}

#pragma mark CBCentralManagerDelegate

-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch ([central state])
    {
        case CBCentralManagerStateUnsupported:
            NSLog(@"The platform/hardware doesn't support Bluetooth Low Energy.");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"The app is not authorized to use Bluetooth Low Energy.");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@"Bluetooth is currently powered off.");
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"isLECapableHardware: TRUE");
            if (self.autoScan) {
                [self startScan];
            }
            break;
        case CBCentralManagerStateUnknown:
        default:
            break;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(blueManager:didUpdateState:)]) {
            [self.delegate blueManager:self didUpdateState:[central state]];
        }
    });
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSData *manufactureData = [advertisementData objectForKey:CBAdvertisementDataManufacturerDataKey];
    Manufacture menu;
    if (manufactureData.length == 29) {
        [manufactureData getBytes:&menu range:NSMakeRange(2, 11)];
    }else if (manufactureData.length == 35) {
        [manufactureData getBytes:&menu range:NSMakeRange(8, 11)];
    }else {
        return;
    }
    
    uint16_t meshUUID = (menu.meshUUID[0] << 8 & 0xff00) + menu.meshUUID[1];
    if (meshUUID != BTDevInfo_UID) {
        return;
    }
    
    
    NSString *periName = peripheral.name;
    NSString *userName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    
    BlueClient *client = [BlueClient new];
    client.meshName = userName;
    client.meshPwd = @"";
    client.name = periName;
    client.uuidString = peripheral.identifier.UUIDString;
    client.peripheral = peripheral;
    client.rssi = RSSI.intValue;
    
    client.type = menu.productUUID[0];
    client.meshAddr = (menu.deviceAddress[0] & 0xff) + (menu.deviceAddress[1] << 8 & 0xff00);
    client.macAddress = [NSString stringWithFormat:@"%02x%02x%02x%02x", menu.mac[3], menu.mac[2], menu.mac[1], menu.mac[0]];
    client.u_Mac = (menu.mac[0] << 24 & 0xff000000) + (menu.mac[1] << 16 & 0xff0000) + (menu.mac[2] << 8 & 0xff00) + (menu.mac[3] & 0xff);
    
    
//    NSLog(@"%@ %@ %04x", periName, client.macAddress, client.meshAddr);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(blueManager:didDiscoverClient:)]) {
            [self.delegate blueManager:self didDiscoverClient:client];
        }
    });
}


-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    BlueClient *client = [self getClientBy:peripheral];
    [client doLogin];
    
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    BlueClient *client = [self getClientBy:peripheral];
    [client failLogin];
    [self removeClient:client];
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    BlueClient *client = [self getClientBy:peripheral];
    [client failLogin];
    [self removeClient:client];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(blueManager:didDisConnectClient:)]) {
            [self.delegate blueManager:self didDisConnectClient:client];
        }
    });
}

-(BlueClient *)getClientBy:(CBPeripheral *)peripheral {
    for (BlueClient *client in self.loginClients) {
        if ([client.uuidString isEqualToString:peripheral.identifier.UUIDString]) {
            return client;
        }
    }
    return nil;
}

-(void)removeClient:(BlueClient *)client{
    [self.loginClients removeObject:client];
}





@end
