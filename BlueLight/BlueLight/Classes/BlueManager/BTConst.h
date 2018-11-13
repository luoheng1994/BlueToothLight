//
//  BTConst.h
//  TelinkBlue
//
//  Created by Green on 11/14/15.
//  Copyright (c) 2015 Green. All rights reserved.
//

#ifndef TelinkBlue_BTConst_h
#define TelinkBlue_BTConst_h


#define _isDebugLog true


#define BTDevInfo_Name @"Telink tLight"
#define BTDevInfo_UserNameDef @"chitek_mesh"
#define BTDevInfo_OutOfMesh @"out_of_mesh"
#define BTDevInfo_UserPasswordDef @"123"
#define BTDevInfo_UID  0x1102

#define BTDevInfo_ServiceUUID @"00010203-0405-0607-0809-0A0B0C0D1910"
#define BTDevInfo_FeatureUUID_Notify @"00010203-0405-0607-0809-0A0B0C0D1911"
#define BTDevInfo_FeatureUUID_Command @"00010203-0405-0607-0809-0A0B0C0D1912"
#define BTDevInfo_FeatureUUID_Pair @"00010203-0405-0607-0809-0A0B0C0D1914"
#define BTDevInfo_FeatureUUID_OTA  @"00010203-0405-0607-0809-0A0B0C0D1913"

#define Service_Device_Information @"0000180a-0000-1000-8000-00805f9b34fb"

#define Characteristic_Firmware @"00002a26-0000-1000-8000-00805f9b34fb"
//#define Characteristic_Manufacturer @"00002a29-0000-1000-8000-00805f9b34fb"
//#define Characteristic_Model @"00002a24-0000-1000-8000-00805f9b34fb"
//#define Characteristic_Hardware @"00002a27-0000-1000-8000-00805f9b34fb"

#define CheckStr(A) (!A || A.length<1)


#define BTLog(A, B) if (_isDebugLog) NSLog(A, B)
#define LoginTime 5
#define MaxSeqValue  0xFFFFFF



#define CMD_USER_ALL        0xEA
#define CMD_GET_G_8         0xDD
#define CMD_GROUP           0xD7

#define CMD_Light_ON_OFF    0xD0
#define CMD_SET_LUM         0xD2
#define CMD_SET_LIGHT       0xE2
#define CMD_GET_ALARM       0xE6
#define CMD_ALARM           0xE5
#define CMD_SET_TIME        0xE4
#define CMD_GET_TIME        0xE8
#define CMD_CHANGE_COLOR    0xF0
#define CMD_START_CHANGE    0xF1
#define CMD_DEVICE_ADDR     0xE0


#define NOTIFY_MESH_LIGHT_STATUS    0xDC
#define NOTIFY_USER_ALL             0xEB
#define NOTIFY_GET_G_8              0xD4
#define NOTIFY_GET_ALARM            0xE7
#define NOTIFY_DEVICE_ADDR          0xE1



#endif
