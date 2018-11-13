//
//  BlueClient.h
//  BlueLight
//
//  Created by Rail on 6/30/16.
//  Copyright © 2016 Rail. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef NS_ENUM(NSInteger, BlueLightType) {
    BlueLightTypeRGBW   = 3,
    BlueLightTypeRGB    = 4,
    BlueLightTypeYW     = 6
};

typedef NS_ENUM(NSInteger, ClientTask) {
    ClientTaskNone = 0,
    ClientTaskLogin
};

struct CommandHead {
    Byte sequenceNo[3];
    Byte src[2];
    Byte dest[2];
    Byte cmd;
    Byte vendorId[2];
    
};
typedef struct CommandHead CommandHead;

struct ResponseHead {
    Byte sequenceNo[3];
    Byte meshAddr[2];
    Byte check[2];
    Byte cmd;
    Byte vendorId[2];
    
};
typedef struct ResponseHead ResponseHead;

struct Status {
    Byte bright;
    Byte r;
    Byte g;
    Byte b;
    Byte w;
    
};
typedef struct Status Status;


typedef struct {
    UInt8 cmd : 4;
    UInt8 type : 3;
    UInt8 enable : 1;
}AlarmCmd;

typedef struct{ // max 10BYTES
    UInt8 event;
    UInt8 index;
    AlarmCmd par1;
    UInt8 month;
    union {
        UInt8 day;
        UInt8 week; // BIT(n)
    }par2;
    UInt8 hour;
    UInt8 minute;
    UInt8 second;
    UInt8 scene_id;
    UInt8 count;
}Alarm;

typedef NS_ENUM(UInt8, AlarmAction) {
    AlarmActionOff = 0,
    AlarmActionOn,
    AlarmActionScene
};

@class BlueClient;

@protocol BlueClientDelegate <NSObject>

@optional
-(void)didNotifyData:(NSData *)data;
-(void)blueClient:(BlueClient *)client didDiscoverNewClient:(BlueClient *)newClient;
-(void)blueClient:(BlueClient *)client didGetGroupInfo:(NSArray *)groups;
-(void)blueClient:(BlueClient *)client didGetAlarm:(Alarm)alarm;
-(void)didRefreshVersion:(BlueClient *)client;
-(void)blueClient:(BlueClient *)client didSendPack:(BOOL)success;
-(void)blueClient:(BlueClient *)client didReadFirmWare:(NSData *)data;
@end

@interface BlueClient : NSObject

@property (nonatomic, weak) id<BlueClientDelegate> delegate;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *uuidString;
@property (nonatomic, assign) int rssi;
@property (nonatomic, strong) CBPeripheral *peripheral;

@property (nonatomic, copy) NSString *macAddress;
@property (nonatomic, assign) uint32_t u_Mac;
@property (nonatomic, assign) BlueLightType type;

@property (nonatomic, assign) UInt16 meshAddr;
@property (nonatomic, copy) NSString *meshName;
@property (nonatomic, copy) NSString *meshPwd;
@property (nonatomic, assign) ClientTask task;

@property (nonatomic, assign) BOOL isLogin;
@property (nonatomic, assign) BOOL isConnected;

@property (nonatomic, copy) NSString *hardwareVersion;
@property (nonatomic, copy) NSString *softwareVersion;

@property (nonatomic, assign) Status currentStatus;

-(void)prepareLoginWithPwd:(NSString *)pwd block:(void (^)(BOOL success, BlueClient *client))loginBlock;
-(void)doLogin;
-(void)failLogin;
-(void)clean;

-(void)notifyOpen;
-(void)sendCmd:(uint8_t)cmd dest:(uint16_t)dest withData:(NSData *) data;
-(void)updateName:(NSString *)name andPassword:(NSString *)pwd withCallBack:(void(^)(BOOL success))callback;
-(void)updateMeshAddr:(UInt16)meshAddr withCallBack:(void(^)(BOOL success))callback;

-(void)readFireWare;
-(void)sendPack:(NSData *)data index:(NSUInteger)otaPackIndex;

@end
