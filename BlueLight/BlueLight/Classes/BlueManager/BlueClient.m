//
//  BlueClient.m
//  BlueLight
//
//  Created by Rail on 6/30/16.
//  Copyright © 2016 Rail. All rights reserved.
//

#import "BlueClient.h"
#import "BTConst.h"
#import "CryptoAction.h"

typedef enum {
    DevOperaStatus_Normal=1,
    DevOperaStatus_ScanSrv_Finish,//完成扫描服务uuid
    DevOperaStatus_ScanChar_Finish,//完成扫描特征
    DevOperaStatus_Login_Start,
    DevOperaStatus_Login_Finish,
    DevOperaStatus_SetName_Start,
    DevOperaStatus_SetPassword_Start,
    DevOperaStatus_SetLtk_Start,
    DevOperaStatus_SetNetwork_Finish,
    DevOperaStatus_FireWareVersion
    //添加部分
    
}OperaStatus;


@interface BlueClient() <CBPeripheralDelegate>
{
    uint8_t loginRand[8];
    uint8_t sectionKey[16];
    int seqNo;
}

@property (nonatomic, strong) CBCharacteristic *notifyChar;
@property (nonatomic, strong) CBCharacteristic *commandChar;
@property (nonatomic, strong) CBCharacteristic *pairChar;
@property (nonatomic, strong) CBCharacteristic *fireWareChar;
@property (nonatomic, strong) CBCharacteristic *otaChar;

@property (nonatomic, assign) OperaStatus operaStatus;

@property (nonatomic, copy) void (^loginBlock)(BOOL success, BlueClient *client);
@property (nonatomic, strong) NSTimer *loginTimer;

@property (nonatomic, copy) void(^updateCallBack)(BOOL success);
@property (nonatomic, strong) NSTimer *updateTimer;

@property (nonatomic, copy) void(^meshAddrCallBack)(BOOL success);
@property (nonatomic, strong) NSTimer *meshAddrTimer;
@property (nonatomic, assign) uint16_t updatedMeshAddr;

//@property (nonatomic, strong) NSTimer *sendPackTimer;
@end


@implementation BlueClient

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initData];
    }
    return self;
}

-(void)initData {
    
}

-(BOOL)isConnected {
    return self.peripheral.state == CBPeripheralStateConnected;
}

-(void)prepareLoginWithPwd:(NSString *)pwd block:(void (^)(BOOL success, BlueClient *client))loginBlock {
    self.meshPwd = pwd;
    [self clean];
    self.loginBlock = loginBlock;
    self.loginTimer = [NSTimer scheduledTimerWithTimeInterval:LoginTime target:self selector:@selector(LoginTimeOut:) userInfo:nil repeats:false];
    
}

-(void)LoginTimeOut:(NSTimer *)timer {
    if (!self.isLogin) {
        if (self.loginBlock != nil) {
            self.loginBlock(false, self);
            self.loginBlock = nil;
        }
        
    }
    
    [self clean];
    if (timer.valid) {
        [timer invalidate];
    }
}

-(void)doLogin{
    
    self.task = ClientTaskLogin;
    [self discoverService];
}

-(void)failLogin {
    if (self.task == ClientTaskLogin) {
        [self LoginTimeOut:self.loginTimer];
    }
}

-(void)clean {
    self.task = ClientTaskNone;
    self.notifyChar = nil;
    self.commandChar = nil;
    self.pairChar = nil;
    self.otaChar = nil;
    
    self.isLogin = false;
}

#pragma mark - SetNameAndPassword
-(void)updateName:(NSString *)name andPassword:(NSString *)pwd withCallBack:(void(^)(BOOL success))callback {
    self.updateCallBack = ^(BOOL success){
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(success);
        });
    };
    uint8_t buffer[20];
    memset(buffer, 0, 20);
    
    self.operaStatus=DevOperaStatus_SetName_Start;
    [CryptoAction  getNetworkInfo:buffer Opcode:4 Str:name Psk:sectionKey];
    [self writeValue:self.pairChar Buffer:buffer Len:20 response:CBCharacteristicWriteWithResponse];
    NSLog(@"Setting_Name");
    
    self.operaStatus=DevOperaStatus_SetPassword_Start;
    memset(buffer, 0, 20);
    [CryptoAction  getNetworkInfo:buffer Opcode:5 Str:pwd Psk:sectionKey];
    [self writeValue:self.pairChar Buffer:buffer Len:20 response:CBCharacteristicWriteWithResponse];
    NSLog(@"Seting_Password");
    
    uint8_t tempbuffer[20];
    memset(tempbuffer, 0, 20);
    for (int i = 0; i < 0x10; i++) {
        tempbuffer[i] = 0x0F - i;
    }
    self.operaStatus=DevOperaStatus_SetLtk_Start;
    [CryptoAction  getNetworkInfoByte:buffer Opcode:6 Str:tempbuffer Psk:sectionKey];
    [self writeValue:self.pairChar Buffer:buffer Len:20 response:CBCharacteristicWriteWithResponse];
    NSLog(@"Setting_Ltk");
    
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateTimeOut:) userInfo:nil repeats:false];

}

-(void)updateTimeOut:(NSTimer *)timer {
    self.updateCallBack(false);
    self.updateCallBack = nil;
    if (timer.valid) {
        [timer invalidate];
    }
}

#pragma mark - Set Mesh Address
-(void)updateMeshAddr:(UInt16)meshAddr withCallBack:(void (^)(BOOL success))callback {
    self.meshAddrCallBack = callback;
    Byte bytes[2];
    bytes[0] = meshAddr & 0xFF;
    bytes[1] = meshAddr >> 8 & 0xFF;
    
    [self sendCmd:CMD_DEVICE_ADDR dest:0x0000 withData:[NSData dataWithBytes:&bytes length:2]];
    self.updatedMeshAddr = meshAddr;
    self.meshAddrTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(updateMeshAddrTimeOut:) userInfo:nil repeats:false];
}

-(void)updateMeshAddrTimeOut:(NSTimer *)timer {
    self.meshAddrCallBack(false);
    self.meshAddrCallBack = nil;
    if (timer.valid) {
        [timer invalidate];
    }
}

#pragma mark - Send Command
-(void)sendCmd:(uint8_t)cmd dest:(uint16_t)dest withData:(NSData *) data {
    CommandHead head;
    head.cmd = cmd;
    uint32_t seq = [self getNextSnNo];
    head.sequenceNo[2] = seq & 0xff;
    head.sequenceNo[1] = seq >> 8 & 0xff;
    head.sequenceNo[0] = seq >> 16 & 0xff;
    memset(head.src, 0, 2);
    head.dest[0] = dest & 0xff;
    head.dest[1] = dest >> 8 & 0xff;
    head.vendorId[0] = 0x11;
    head.vendorId[1] = 0x02;
    
    
    
    uint8_t buffer[20];
    uint8_t sec_ivm[8];
    
    memset(buffer, 0, 20);
    memcpy(buffer, &head, 10);
    memset(sec_ivm, 0,8);
    [data getBytes:buffer + 10 length:10];
    
    uint32_t tempMac=self.u_Mac;
    
    sec_ivm[0]=(tempMac>>24) & 0xff;
    sec_ivm[1]=(tempMac>>16) & 0xff;
    sec_ivm[2]=(tempMac>>8) & 0xff;
    sec_ivm[3]=tempMac & 0xff;
    
    sec_ivm[4]=1;
    sec_ivm[5]=buffer[0];
    sec_ivm[6]=buffer[1];
    sec_ivm[7]=buffer[2];
    [self logByte:buffer Len:20 Str:@"发送命令"];
    [CryptoAction encryptionPpacket:sectionKey Iv:sec_ivm Mic:buffer+3 MicLen:2 Ps:buffer+5 Len:15];
    
    [self logByte:buffer Len:20 Str:@"加密结果"];
    [self writeValue:self.commandChar Buffer:buffer Len:20 response:CBCharacteristicWriteWithoutResponse];
}

-(int)getNextSnNo
{
    seqNo = arc4random();
    return seqNo;
}


//获取灯的状态数据
-(void)notifyOpen
{
    if (!self.isConnected) {
        return;
    }
    NSLog(@"获取灯的状态");
    uint8_t buffer[1]={1};
    [self writeValue:self.notifyChar Buffer:buffer Len:1 response:CBCharacteristicWriteWithResponse];
}

//private



-(void)setPeripheral:(CBPeripheral *)peripheral {
    _peripheral = peripheral;
    _peripheral.delegate = self;
}

#pragma mark - Discover service and characteristics

-(void)discoverService {
    
    if ([self checkServices]) {
        [self discoverCharacteristics];
    }else {
        [self.peripheral discoverServices:nil];
    }
}

-(BOOL)checkServices {
    for (CBService *service in self.peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:BTDevInfo_ServiceUUID]]||[service.UUID isEqual:[CBUUID UUIDWithString:Service_Device_Information]]) {
            return true;
        }
    }
    return false;
}

-(void)discoverCharacteristics {
    if ([self checkCharacteristics]) {
        [self execTask];
    }else {
        for (CBService *service in self.peripheral.services) {
            if ([service.UUID isEqual:[CBUUID UUIDWithString:BTDevInfo_ServiceUUID]]||[service.UUID isEqual:[CBUUID UUIDWithString:Service_Device_Information]]) {
                [self.peripheral discoverCharacteristics:nil forService:service];
                
            }
        }
    }
}

-(BOOL)checkCharacteristics {
    for (CBService *service in self.peripheral.services) {
        for (CBCharacteristic *character in service.characteristics) {
            if ([character.UUID isEqual:[CBUUID UUIDWithString:BTDevInfo_FeatureUUID_Notify]]){
                [self.peripheral setNotifyValue:YES forCharacteristic:character];
                self.notifyChar = character;
            } else if ([character.UUID isEqual:[CBUUID UUIDWithString:BTDevInfo_FeatureUUID_Command]]) {
                self.commandChar = character;
            } else if ([character.UUID isEqual:[CBUUID UUIDWithString:BTDevInfo_FeatureUUID_Pair]]) {
                self.pairChar = character;
            }else if([character.UUID isEqual:[CBUUID UUIDWithString:BTDevInfo_FeatureUUID_OTA]]){
                self.otaChar = character;
            } else if([character.UUID isEqual:[CBUUID UUIDWithString:Characteristic_Firmware]]){
                self.fireWareChar = character;
            }
        }
    }
    if (self.notifyChar && self.commandChar && self.pairChar && self.otaChar && self.fireWareChar) {
        return true;
    }else {
        return false;
    }
}

-(void)execTask {
    if (self.task == ClientTaskLogin) {
        [self sendLogin];
    }
}

#pragma mark - Login
-(void)sendLogin {
    NSLog(@"sending Login");
    self.operaStatus = DevOperaStatus_Login_Start;
    
    uint8_t buffer[17];
    [CryptoAction getRandPro:loginRand Len:8];
    for (int i=0;i<8;i++)
        loginRand[i]=i;
    buffer[0]=12;
    [CryptoAction encryptPair:self.meshName Pas:self.meshPwd Prand:loginRand PResult:buffer+1];
    
    [self logByte:buffer Len:17 Str:@"Login_String"];
    [self writeValue:self.pairChar Buffer:buffer Len:17 response:CBCharacteristicWriteWithResponse];
}


#pragma mark - Peripheral Delegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"did Discover Services");
    [self discoverCharacteristics];
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"did Discover Characteristics");
    if ([self checkCharacteristics]) {
        [self execTask];
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        BTLog(@"收到数据错误: %@", [error localizedDescription]);
        return;
    }
    if ([characteristic isEqual:self.pairChar]) {
        uint8_t *data=(uint8_t *)[characteristic.value bytes];
        
        if (self.operaStatus == DevOperaStatus_Login_Start) {
            if (data[0] == 13) {
                uint8_t buffer[16];
                if ([CryptoAction encryptPair:self.meshName Pas:self.meshPwd Prand:data+1 PResult:buffer]) {
                    [self logByte:buffer Len:16 Str:@"CheckBuffer"];
                    [CryptoAction getSectionKey:self.meshName Pas:self.meshPwd Prandm:loginRand Prands:data+1 PResult:sectionKey];
                    
                    [self logByte:sectionKey Len:16 Str:@"SectionKey"];
                    
                    if (self.loginBlock != nil) {
                        self.loginBlock(true, self);
                        self.loginBlock = nil;
                    }
                    
                    self.isLogin = true;
                    if (self.loginTimer != nil && self.loginTimer.valid) {
                        [self.loginTimer invalidate];
                    }
                }
            }
            self.operaStatus = DevOperaStatus_Login_Finish;
//            if (_operaType==DevOperaType_Set)
//            {
//                if (_isLogin){
//                    [self setNewNetworkDataPro];
//                }else{
//                    [self setNewNetworkNextPro];
//                }
//            }
        }
        else if (_operaStatus==DevOperaStatus_SetLtk_Start) {
            if (data[0]==7) {
                BTLog(@"%@",@"Set Success");
                self.updateCallBack(true);
            }else {
                BTLog(@"%@",@"Set Fail");
                self.updateCallBack(false);
            }
            self.updateCallBack = nil;
            if (self.updateTimer.valid) {
                [self.updateTimer invalidate];
            }
            self.operaStatus=DevOperaStatus_SetNetwork_Finish;
        }
    }
    else if ([characteristic isEqual:self.commandChar]) {
        if (self.isLogin)
        {
            BTLog(@"%@",@"Command 数据解析");
            uint8_t *buffer = (uint8_t *)[characteristic.value bytes];
            [self parseData:buffer];
        }
    } else if ([characteristic isEqual:self.notifyChar]) {
//        BTLog(@"Recieve Notify Data%@",characteristic.value);
        [self didNotify:characteristic.value];
    }
    else if ([characteristic isEqual:self.fireWareChar]){
        NSData *data = [characteristic value];
        
        if ([_delegate respondsToSelector:@selector(blueClient:didReadFirmWare:)] && data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate blueClient:self didReadFirmWare:data];
            });
            
        }
    }
    
}



-(void)didNotify:(NSData *)data {
    if (self.isLogin) {
        uint8_t *buffer = (uint8_t *)[data bytes];
        [self parseData:buffer];
        
        NSData *respData = [NSData dataWithBytes:buffer length:20];
        ResponseHead head;
        Byte dataBuffer[10];
        [respData getBytes:&head length:10];
        [respData getBytes:&dataBuffer range:NSMakeRange(10, 10)];
        switch (head.cmd) {
            case NOTIFY_USER_ALL:
                switch (dataBuffer[0]) {
                    case 0x11:
                        if ([self.delegate respondsToSelector:@selector(didRefreshVersion:)]) {
                            BlueClient *client = [BlueClient new];
                            client.meshAddr = (head.meshAddr[0] & 0xff) + (head.meshAddr[1] & 0xff00);
                            client.type = dataBuffer[1];
                            client.hardwareVersion = [NSString stringWithFormat:@"H%02x%02x%02x", dataBuffer[1], dataBuffer[2], dataBuffer[3]];
                            client.softwareVersion = [NSString stringWithFormat:@"%02x%02x", dataBuffer[4], dataBuffer[5]];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.delegate didRefreshVersion:client];
                            });
                        }
                        break;
                    case 0x03:
                    case 0x04:
                    case 0x06:
                        if ([self.delegate respondsToSelector:@selector(blueClient:didDiscoverNewClient:)]) {
                            
                            BlueClient *client = [BlueClient new];
                            client.meshAddr = (head.meshAddr[0] & 0xff) + (head.meshAddr[1] & 0xff00);
                            client.type = dataBuffer[0];
                            client.macAddress = [NSString stringWithFormat:@"%02x%02x%02x%02x", dataBuffer[9], dataBuffer[8], dataBuffer[7], dataBuffer[6]];
                            
                            Status currentStatus;
                            [respData getBytes:&currentStatus range:NSMakeRange(11, 5)];
                            client.currentStatus = currentStatus;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.delegate blueClient:self didDiscoverNewClient:client];
                            });
                        }
                        break;
                    default:
                        break;
                }
                
                
                break;
            case NOTIFY_GET_G_8:
                if ([self.delegate respondsToSelector:@selector(blueClient:didGetGroupInfo:)]) {
                    NSMutableArray *groups = [NSMutableArray new];
                    BlueClient *client = [BlueClient new];
                    client.meshAddr = (head.meshAddr[0] & 0xff) + (head.meshAddr[1] & 0xff00);
                    for (int i = 0; i < 8; i ++) {
                        if (dataBuffer[i] != 0xff) {
                            [groups addObject:[NSNumber numberWithShort:(uint16_t)((dataBuffer[i] & 0xff) + 0x8000)]];
                        }
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate blueClient:client didGetGroupInfo:groups];
                    });
                    
                }
                break;
            case NOTIFY_MESH_LIGHT_STATUS:
                if ([self.delegate respondsToSelector:@selector(didNotifyData:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate didNotifyData:respData];
                    });
                    
                }
                break;
            case NOTIFY_GET_ALARM:
                if ([self.delegate respondsToSelector:@selector(blueClient:didGetAlarm:)]) {
                    BlueClient *client = [BlueClient new];
                    client.meshAddr = (head.meshAddr[0] & 0xff) + (head.meshAddr[1] & 0xff00);
                    Alarm alarm;
                    [respData getBytes:&alarm range:NSMakeRange(10, 10)];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate blueClient:client didGetAlarm:alarm];
                    });
                }
                break;
            case NOTIFY_DEVICE_ADDR:
                self.meshAddrCallBack(true);
                self.meshAddrCallBack = nil;
                if (self.meshAddrTimer.valid) {
                    [self.meshAddrTimer invalidate];
                }
                
                break;
            default:
                break;
        }
    }
}

-(void) parseData:(uint8_t *)buffer {
    uint8_t sec_ivm[8];
    uint32_t tempMac=self.u_Mac;
    
    sec_ivm[0]=(tempMac >> 24) & 0xff;
    sec_ivm[1]=(tempMac >> 16) & 0xff;
    sec_ivm[2]=(tempMac >> 8) & 0xff;
    
    memcpy(sec_ivm + 3, buffer, 5);
    
    if (!(buffer[0]==0 && buffer[1]==0 && buffer[2]==0)) {
        if ([CryptoAction decryptionPpacket:sectionKey Iv:sec_ivm Mic:buffer+5 MicLen:2 Ps:buffer+7 Len:13]) {
            [self logByte:buffer Len:20 Str:@"收到数据"];
        }else {
            NSLog(@"解密返回失败");
        }
        
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Notify<_>characteristic---Error: %@< ___ >%@", error.localizedDescription, [[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding]);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error && ![characteristic isEqual:self.otaChar]) {
        NSLog(@"Write___Error: %@<--> %@", [error localizedFailureReason],[[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding]);
        return;
    }
    if ([characteristic isEqual:self.pairChar]){
        [self.peripheral readValueForCharacteristic:self.pairChar];
    }
    if ([characteristic isEqual:self.otaChar]){
        if ([self.delegate respondsToSelector:@selector(blueClient:didSendPack:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate blueClient:self didSendPack:true];
            });
        }
//        if (self.sendPackTimer.valid) {
//            [self.sendPackTimer invalidate];
//        }
    }
}

#pragma mark 发送OTA数据
//读取固件版本
-(void)readFireWare {
    if (!self.isConnected) {
        return;
    }
    [self.peripheral readValueForCharacteristic:self.fireWareChar];
}

-(void)sendPack:(NSData *)data index:(NSUInteger)otaPackIndex{
    if (!self.isConnected || !self.otaChar || !self.isLogin)
        return;
//    self.sendPackTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(sendPackTimeOut) userInfo:nil repeats:false];
    NSUInteger length = data.length;
    uint8_t *tempData=(uint8_t *)[data bytes];                 //数据包
    uint8_t pack_head[2];
    pack_head[1] = (otaPackIndex >>8)& 0xff;                    //从0开始
    pack_head[0] = (otaPackIndex)&0xff;
    
    //普通数据包
    if (length > 0 && length < 16) {
        length = 16;
    }
    uint8_t otaBuffer[length+4];              //总包
    memset(otaBuffer, 0, length+4);
    
    
    uint8_t otaCmd[length+2];               //待校验包
    memset(otaCmd, 0, length+2);
    
    for (int i = 0; i < 2; i ++) {                    //index指数部分
        otaBuffer[i] = pack_head[i];
    }
    for (int i = 2; i < length+2; i++) {        //bin 文件数据包
        if (i < [data length]+2) {
            otaBuffer[i] = tempData[i-2];
        }else{
            otaBuffer[i] = 0xff;
        }
    }
    for (int i = 0; i < length+2; i++) {
        otaCmd[i] = otaBuffer[i];
    }
    
    //CRC校验部分
    unsigned short crc_t = crc16(otaCmd, (int)length+2);
    uint8_t crc[2];
    crc[1] = (crc_t >> 8) & 0xff;
    crc[0] = (crc_t)&0xff;
    for (int i = (int)length+3; i > (int)length+1; i--) {   //2->4
        otaBuffer[i] = crc[i-length-2];
    }
    
    [self logByte:otaBuffer Len:(int)length+4 Str:@"数据包"];
    NSData *tempdata=[NSData dataWithBytes:otaBuffer length:length+4];
    
    [self.peripheral writeValue:tempdata forCharacteristic:self.otaChar type:CBCharacteristicWriteWithoutResponse];
    
}

-(void) sendPackTimeOut{
//    if (self.sendPackTimer.valid) {
//        [self.sendPackTimer invalidate];
//    }
    if ([self.delegate respondsToSelector:@selector(blueClient:didSendPack:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate blueClient:self didSendPack:false];
        });
    }
}


extern unsigned short crc16 (unsigned char *pD, int len)
{
    static unsigned short poly[2]={0, 0xa001};              //0x8005 <==> 0xa001
    unsigned short crc = 0xffff;
    int i,j;
    for(j=len; j>0; j--)
    {
        unsigned char ds = *pD++;
        for(i=0; i<8; i++)
        {
            crc = (crc >> 1) ^ poly[(crc ^ ds ) & 1];
            ds = ds >> 1;
        }
    }
    return crc;
}


#pragma mark Utils

-(void)writeValue:(CBCharacteristic *)characteristic Buffer:(uint8_t *)buffer Len:(int)len response:(CBCharacteristicWriteType)type {
    if (!characteristic)
        return;
    
    if (self.peripheral.state!=CBPeripheralStateConnected)
        return;
    
    NSData *data=[NSData dataWithBytes:buffer length:len];
    [self.peripheral writeValue:data forCharacteristic:characteristic type:type];
}

-(void)logByte:(uint8_t *)bytes Len:(int)len Str:(NSString *)str
{
    NSMutableString *tempMStr=[[NSMutableString alloc] init];
    for (int i=0;i<len;i++)
        [tempMStr appendFormat:@"%0x ",bytes[i]];
    NSLog(@"%@ == %@",str,tempMStr);
}

@end

