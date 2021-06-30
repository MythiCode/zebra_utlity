//
//  XYWIFIManager.h
//  Printer
//
//  Created by apple on 16/4/5.
//  Copyright © 2016年 Admin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class POSWIFIManager;
typedef void(^POSWIFIBlock)(BOOL isConnect);
typedef void(^POSWIFICallBackBlock)(NSData *data);
enum {
    SocketOfflineByServer,// 服务器掉线，默认为0
    SocketOfflineByUser,  // 用户主动cut
};

/**
 *连接多个设备
 * 采用 XYWIFIManager *manager = [[XYWIFIManager alloc] init] 实例化对象，
 * 将 manager 保存，发送指令时指定相对应的 manager 发送指令
 */
@protocol POSWIFIManagerDelegate <NSObject>

// 成功连接主机
- (void)POSWIFIManager:(POSWIFIManager *)manager didConnectedToHost:(NSString *)host port:(UInt16)port;
// 断开连接
- (void)POSWIFIManager:(POSWIFIManager *)manager willDisconnectWithError:(NSError *)error;
// 写入数据成功
- (void)POSWIFIManager:(POSWIFIManager *)manager didWriteDataWithTag:(long)tag;
// 收到回传
- (void)POSWIFIManager:(POSWIFIManager *)manager didReadData:(NSData *)data tag:(long)tag;
// 断开连接
- (void)POSWIFIManagerDidDisconnected:(POSWIFIManager *)manager;
@end

@interface POSWIFIManager : NSObject
{
    int commandSendMode; //命令发送模式 0:立即发送 1：批量发送
}
#pragma mark - 基本属性
// 主机地址
@property (nonatomic,copy) NSString *hostStr;
// 端口
@property (nonatomic,assign) UInt16 port;
// 是否连接成功
@property (nonatomic,assign) BOOL connectOK;
// 是自动断开连接 还是 手动断开
@property (nonatomic,assign) BOOL isAutoDisconnect;

@property (nonatomic,weak) id<POSWIFIManagerDelegate> delegate;
// 连接回调
@property (nonatomic,copy) POSWIFIBlock callBack;
// 接收服务端返回的数据
@property (nonatomic,copy) POSWIFICallBackBlock callBackBlock;
@property (nonatomic,strong) NSMutableArray *commandBuffer;
//发送队列数组
#pragma mark - 基本方法
+ (instancetype)shareWifiManager;
//连接主机
-(void)POSConnectWithHost:(NSString *)hostStr port:(UInt16)port completion:(POSWIFIBlock)block;
// 断开主机
- (void)POSDisConnect;

//修改版本的推荐使用发送数据的两个方法
-(void)POSWriteCommandWithData:(NSData *)data;

-(void)POSWriteCommandWithData:(NSData *)data withResponse:(POSWIFICallBackBlock)block;

// 发送TSC完整指令
- (void)POSSendMSGWith:(NSString *)str;
// 发送POS完整指令
//- (void)XYWritePOSCommandWithData:(NSData *)data withResponse:(XYWIFICallBackBlock)block;
//#pragma mark - 打印机指令
//#pragma mark - ====================TSC指令===================
///**
// * 1.设置标签尺寸
// * width : 标签宽度
// * height : 标签高度
// */
//- (void)XYaddSizeWidth:(int)width height:(int)height;
///**
// * 2.设置间隙长度
// * gap : 间隙长度
// */
//- (void)XYaddGap:(int)gap;
///**
// * 3.产生钱箱控制脉冲
// * m : 钱箱引脚号
// * t1 : 高电平时间
// * t2 : 低电平时间
// */
//- (void)XYaddCashDrwer:(int)m  t1:(int)t1  t2:(int)t2;
///**
// * 4.控制每张标签的停止位置
// * offset : 停止偏移量
// */
//- (void)XYaddOffset:(float)offset;
///**
// * 5.设置打印速度
// * speed : 打印速度
// */
//- (void)XYaddSpeed:(float)speed;
///**
// * 6.设置打印浓度
// * n : 打印浓度
// */
//- (void)XYaddDensity:(int)n;
///**
// * 7.设置打印方向和镜像
// * n : 打印方向
// */
//- (void)XYaddDirection:(int)n;
///**
// * 8.设置原点坐标
// * x : 原点横坐标
// * y : 原点纵坐标
// */
//- (void)XYaddReference:(int)x  y:(int)y;
///**
// * 9.清除打印缓冲区数据
// */
//- (void)XYaddCls;
///**
// * 10.走纸
// * feed : 走纸长度
// */
//- (void)XYaddFeed:(int)feed;
///**
// * 11.退纸
// * feed : 退纸长度
// */
//- (void)XYaddBackFeed:(int)feed;
///**
// * 12.走一张标签纸距离
// */
//- (void)XYaddFormFeed;
///**
// * 13.标签位置进行一次校准
// */
//- (void)XYaddHome;
///**
// * 14.打印标签
// * m : 打印的标签份数
// */
//- (void)XYaddPrint:(int)m;
///**
// * 15.设置国际代码页
// * page : 国际代码页
// */
//- (void)XYaddCodePage:(int)page;
///**
// * 16.设置蜂鸣器
// * level: 声音阶级
// * interval : 声音长短
// */
//- (void)XYaddSound:(int)level interval:(int)interval;
///**
// * 17.设置打印机报错
// * feed : 走纸长度
// */
//- (void)XYaddLimitFeed:(int)feed;
///**
// * 18.在打印缓冲区绘制黑块
// * x : 其实横坐标
// * y : 起始纵坐标
// * width: 线宽
// * height: 线高
// */
//- (void)XYaddBar:(int)x y:(int)y width:(int)width height:(int)height;
///**
// * 19.在打印缓冲区绘制一维条码
// * x : 其实横坐标
// * y : 起始纵坐标
// * type : 条码类型
// * height : 条码高度
// * readable : 是否打印可识别字符
// * rotation : 条码旋转角度0,90,180,270
// * conten: 条码数据，数据需参考条码规则输入
// */
//- (void)XYadd1DBarcodeX:(int)x
//                      y:(int)y
//                   type:(NSString *)type
//                 height:(int)height
//               readable:(int)readable
//               rotation:(int)rotation
//                 narrow:(int)narrow
//                   wide:(int)wide
//                content:(NSString *)content;
///**
// * 20.在打印缓冲区绘制矩形
// * x : 其实横坐标
// * y : 起始纵坐标
// * xend : 终点横坐标
// * yend : 终点纵坐标
// */
//- (void)XYaddBox:(int)x y:(int)y xend:(int)xend yend:(int)yend;
///**
// * 21.在打印缓冲区绘制位图
// * x : 起始横坐标
// * y : 起始纵坐标
// * width: 位图打印宽度
// * height: 高度
// */
//- (void)XYaddBitmap:(int)x
//                  y:(int)y
//              width:(int)width
//             height:(int)height
//               mode:(int)mode data:(int)data;
///**
// * 22.擦除打印缓冲区中指定区域的数据
// * x : 起始横坐标
// * y : 起始纵坐标
// * xwidth : 横向宽度
// * yheight : 纵向高度
// */
//- (void)XYaddErase:(int)x y:(int)y xwidth:(int)xwidth yheight:(int)yheight;
///**
// * 23.将指定区域的数据黑白反色
// * x : 起始横坐标
// * y : 起始纵坐标
// * xwidth : 横向宽度
// * yheight : 纵向高度
// */
//- (void)XYaddReverse:(int)x y:(int)y xwidth:(int)xwidth yheight:(int)yheight;
///**
// * 24.在打印缓冲区中绘制文字
// * x : 起始横坐标
// * y : 起始纵坐标
// * font : 字体类型
// * rotation : 旋转角度
// * xmul : 横向放大系数1-10倍
// * ymul : 纵向放大系数1-10倍
// * content : 文字字符串
// */
//- (void)XYaddText:(int)x y:(int)y font:(NSString *)font rotation:(int)rotation x_mul:(int)xmul y_mul:(int)ymul content:(NSString *)content;
///**
// * 25.在打印缓冲区中绘制文字
// * x : 起始横坐标
// * y : 起始纵坐标
// * level : 纠错级别
// * cellWidth : 单元大小
// * totation : 旋转角度
// * dataStr : 打印文字
// */
//- (void)XYaddQRCode:(int)x y:(int)y level:(int)level cellWidth:(int)cellWidth rotation:(int)totation data:(NSString *)dataStr;
///**
// * 26.设置剥离功能是否开启
// * enable : 是否使能
// */
//- (void)XYaddPeel:(NSString *)enable;
///**
// * 27.设置撕离功能是否开启
// * enable : 是否使能
// */
//- (void)XYaddTear:(NSString *)enable;
//
///**
// * 28.设置切刀功能是否开启
// * enable : 是否使能
// */
//- (void)XYaddCut:(NSString *)enable;
///**
// * 29.设置打印机出错时，是否打印上一张内容
// * enable : 是否使能
// */
//- (void)XYaddReprint:(NSString *)enable;
///**
// * 30.设置是否按走纸键打印最近一张标签
// * enable : 是否使能
// */
//- (void)XYaddPrintKeyEnable:(NSString *)enable;
///**
// * 31.设置按走纸键打印最近一张标签的份数
// * m : 打印份数
// */
//- (void)XYaddPrintKeyNum:(int)m;
//
//
//#pragma mark - ================POS指令====================
///**
// *1.水平定位
// */
//- (void)XYhorizontalPosition;
///**
// * 2.打印并换行
// */
//- (void)XYprintAndFeed;
///**
// * 3.打印并回到标准模式
// */
//- (void)XYPrintAndBackToNormalModel;
///**
// * 4.页模式下取消打印数据
// */
//- (void)XYCancelPrintData;
///**
// * 5.实时状态传送
// * param:指定所要传送的打印状态
// *   1 <= param <= 4
// * callBlock : 打印机返回的相关状态
// */
//- (void)XYUpdataPrinterState:(int)param completion:(XYWIFICallBackBlock)callBlock;
///**
// * 6.实时对打印机请求
// * param : 表示对打印机发送的请求
// *  1 <= param <= 2
// */
//- (void)XYUpdataPrinterAnswer:(int)param;
///**
// * 7.实时产生钱箱开启脉冲
// *  m : 指定钱箱插座的引脚
// *  t : 电平时间
// *  n = 1
// *  m = 0,1
// *  1 <= t <= 8
// */
//- (void)XYOpenBoxAndPulse:(int) n m:(int) m t:(int) t;
///**
// * 8.页模式下打印
// */
//- (void)XYPrintOnPageModel;
///**
// * 9.设置字符右间距
// * n : 表示字符间距
// *  0 <= n <= 255
// */
//- (void)XYSetCharRightMargin:(int)n;
///**
// * 10.选择打印模式
// * n : 根据n的值设置字符打印模式
// *  0 <= n <= 255
// */
//- (void)XYSelectPrintModel:(int)n;
///**
// * 11.设置绝对打印位置
// *  0 <= nL <= 255
// *  0 <= nh <= 255
// */
//- (void)XYSetPrintLocationWithParam:(int)nL nH:(int)nH;
///**
// * 12.选择/取消用户自定义字符
// *   0 <= n <= 255
// */
//- (void)XYSelectOrCancelCustomCharacter:(int)n;
//
///**
// * 13.定义用户自定义字符
// *  y=3
// *  32<=c1<=c2<=127
// *  0<=x<=12 标准ASCII码字体A（12 x 24）
// *  0<=x<=9 压缩SCII码字体（9 x 17）
// *  0<=d1 ... d(y*xk)<=255
// *  points : 点矩阵数组,数组元素位字符串类型
// */
//- (void)XYDefinCustomCharacter:(int)y c1:(int)c1 c2:(int)c2 dx:(NSArray *)points;
///**
// * 14.选择位图模式
// * 选择由m指定的一种位图模式，位图点数由nL和nH确定
// * m=0,1,32,33
// * 0<=nL<=255
// * 0<=nH<=3
// * 0<=d<=255
// */
//- (void)XYSelectBitmapModel:(int)m nL:(int)nL nH:(int)nH dx:(NSArray *)points;
//
///**
// * 15.取消下划线模式
// * 0<=n<=2,48<=n<=50
// * 根据n的值选择或取消下划线模式
// */
//- (void)XYCancelUnderLineModelWith:(int)n;
///**
// * 16.设置默认行间距
// */
//- (void)XYSetDefaultLineMargin;
///**
// * 17.设置行间距
// * 0<=n<=255
// * 设置行间距位【n*纵向或横向移动单位】
// */
//- (void)XYSetLineMarginWith:(int)n;
///**
// * 18.选择打印机
// * 0<=n<=1
// */
//- (void)XYSelectPrinterWith:(int)n;
///**
// * 19.取消用户自定义字符
// * 32<=n<=127
// */
//- (void)XYCancelCustomCharacterWith:(int)n;
///**
// * 20.初始化打印机
// *
// */
//- (void)XYInitializePrinter;
///**
// * 21.设置横向跳格位置
// * 1<=n<=255
// * 0<=k<=32
// */
//- (void)XYSetTabLocationWith:(NSArray *)points;
///**
// * 22.选择/取消加粗模式
// * 0<=n<=255
// * n最低位为0时，取消加粗模式，位1时，选择加粗模式
// */
//- (void)XYSelectOrCancelBoldModelWith:(int)n;
///**
// * 23.选择/取消双重打印模式
// * 0<=n<=255
// * n最低位：0 取消
// *         1 加粗
// */
//- (void)XYSelectOrCancelDoublePrintModel:(int)n;
///**
// * 24.打印并走纸
// * 0<=n<=255
// * 打印缓冲区数据并走纸【n*纵向或横向移动单位】
// */
//- (void)XYPrintAndPushPageWith:(int)n;
///**
// * 25.选择页模式
// */
//- (void)XYSelectPageModel;
///**
// * 26.选择字体
// * n = 0,1,48,49
// */
//- (void)XYSelectFontWith:(int)n;
///**
// * 27.选择国际字符集
// * 0<=n<=15
// */
//- (void)XYSelectINTL_CHAR_SETWith:(int)n;
///**
// * 28.选择标准模式
// */
//- (void)XYSelectNormalModel;
///**
// * 29.在页模式下选择打印区域方向
// * 0<=n<=3  48<=n<=51
// * n指定打印区域的方向和起始位置
// */
//- (void)XYSelectPrintDirectionOnPageModel:(int)n;
///**
// * 30.选择/取消顺时针旋转90度
// * 0<=n<=1  48<=n<=49
// * 0,48 : 取消
// * 1,49 : 选择
// */
//- (void)XYSelectOrCancelRotationClockwise:(int)n;
///**
// * 31.页模式下设置打印区域
// * 范围：0<=xL,xH,yL,yH,dxL,dxH,dyL,dyH<=255
// */
//- (void)XYSetprintLocationOnPageModelWithXL:(int)xL
//                                         xH:(int)xH
//                                         yL:(int)yL
//                                         yH:(int)yH
//                                        dxL:(int)dxL
//                                        dxH:(int)dxH
//                                        dyL:(int)dyL
//                                        dyH:(int)dyH;
//
///**
// * 32.设置横向打印位置
// * 范围： nL  0 - 255
// nH  0 - 255
// */
//- (void)XYSetHorizonLocationWith:(int)nL nH:(int)nH;
///**
// * 33.选择对齐方式
// * 范围： n  0 - 2
// 48 - 50
// */
//- (void)XYSelectAlignmentWithN:(int)n;
///**
// * 34.选择打印纸传感器以输出信号
// * 范围： n  0 - 255
// */
//- (void)XYSelectSensorForOutputSignal:(int)n;
///**
// * 35.选择打印纸传感器以停止打印
// * 范围： n  0 - 255
// */
//- (void)XYSelectSensorForStopPrint:(int)n;
///**
// * 36.允许/禁止按键
// * 范围： n  0 - 255
// */
//- (void)XYAllowOrDisableKeypress:(int)n;
///**
// * 37.打印并向前走纸 N 行
// * 范围： n  0 - 255
// */
//- (void)XYPrintAndPushPageRow:(int)n;
///**
// * 38.产生钱箱控制脉冲
// * 范围：m  0 , 1 , 48 , 49
// t1 0  - 255
// t2 0 - 255
// */
//- (void)XYMakePulseWithCashboxWithM:(int)m t1:(int)t1 t2:(int)t2;
///**
// * 39.选择字符代码表
// * 范围： n  0 - 10 或 16 - 19
// */
//- (void)XYSelectCharacterTabN:(int)n;
///**
// * 40.选择/取消倒置打印模式
// * 范围： n  0 - 255
// */
//- (void)XYSelectOrCancelInversionPrintModel:(int)n;
///**
// * 41.打印下载到FLASH中的位图
// * 范围：n  1 - 255
// m  0 - 3 , 48 - 51
// */
//- (void)XYPrintFlashBitmapWithN:(int)n m:(int)m;
///**
// * 42.定义FLASH位图
// *范围：n  1 - 255
// * points : 位图的横向点数和纵向点数
// */
//- (void)XYDefinFlashBitmapWithN:(int)n Points:(NSArray *)points;
///**
// * 43.选择字符大小
// * 范围：n  0 - 255
// */
//- (void)XYSelectCharacterSize:(int)n;
///**
// * 44.页模式下设置纵向绝对位置
// * 范围：nL  1 - 255
// nH  0 - 255
// */
//- (void)XYSetVertLocationOnPageModelWithnL:(int)nL nH:(int)nH;
///**
// * 45.定义下载位图
// * 范围：x  1 - 255
// y  1 - 48
// x * y <= 912
// d  0 - 255
// */
//- (void)XYDefineLoadBitmapWithX:(int)x Y:(int)y Points:(NSArray *)points;
///**
// * 46.执行打印数据十六进制转储
// * 范围：pL = 2
// pH = 0
// n = 0,48
// m = 1,49
// */
//- (void)XYPrintDataAndSaveAsHexWithpL:(int)pL pH:(int)pH n:(int)n m:(int)m;
///**
// * 47.打印下载位图
// * 范围：m  0 - 3 或 48 - 51
// */
//- (void)XYPrintLoadBitmapM:(int)m;
///**
// * 48.开始/结束宏定义
// */
//- (void)XYBeginOrEndDefine;
///**
// * 49.选择/取消黑白反显打印模式
// * 范围：n  0 - 255
// */
//- (void)XYSelectORCancelBWPrintModel:(int)n;
///**
// * 50.选择HRI字符的打印位置
// * 范围：n  0 - 3 或 48 - 51
// */
//- (void)XYSelectHRIPrintLocation:(int)n;
///**
// * 51.设置左边距
// * 范围：nL  0 - 255
// nH  0 - 255
// */
//- (void)XYSetLeftMarginWithnL:(int)nL nH:(int)nH;
///**
// * 52.设置横向和纵向移动单位
// * 范围：x  0 - 255
// y  0 - 255
// */
//- (void)XYSetHoriAndVertUnitXWith:(int)x y:(int)y;
///**
// * 53.选择切纸模式并切纸
// * model : 0,1  选择模式1 和 模式2
// * 模式1范围 : m = 0,48,1,49
// * 模式2范围 : m = 66, n = 0-255
// */
//- (void)XYSelectCutPaperModelAndCutPaperWith:(int)m n:(int)n selectedModel:(int)model;
///**
// * 54.设置打印区域宽高
// * 范围：nL  0 - 255
// nH  0 - 255
// */
//- (void)XYSetPrintLocationWith:(int)nL nH:(int)nH;
///**
// * 55.页模式下设置纵向相对位置
// * 范围：nL  0 - 255
// nH  0 - 255
// */
//- (void)XYSetVertRelativeLocationOnPageModelWith:(int)nL nH:(int)nH;
///**
// * 56.执行宏命令
// * 范围：r  0 - 255
// t  0 - 255
// m  0,1
// */
//- (void)XYRunMacroMommandWith:(int)r t:(int)t m:(int)m;
///**
// * 57.打开/关闭自动状态反传功能(ASB)
// * 范围：n  0 - 255
// */
//- (void)XYOpenOrCloseASB:(int)n;
///**
// * 58.选择HRI使用字体
// * 范围：n  0,1,48,49
// */
//- (void)XYSelectHRIFontToUse:(int)n;
///**
// * 59. 选择条码高度
// * 范围：n  1 - 255
// */
//- (void)XYSelectBarcodeHeight:(int)n;
///**
// * 60.打印条码
// * model : 0,1 代表两种类型 0：表示类型1  1:表示类型2
// * 类型1: m  0-6
// * 类型2: m  65-73
// */
//- (void)XYPrintBarCodeWithPoints:(int)m n:(int)n points:(NSArray *)points selectModel:(int)model;
///**
// * 61.返回状态
// * 范围：n  1,2,49,50
// */
//- (void)XYCallBackStatus:(int)n completion:(XYWIFICallBackBlock)block;
///**
// * 62.打印光栅位图
// * 范围：m  0 - 3 或 48 - 51
// xL 0 - 255
// xH 0 - 255
// yL 0 - 255
// yH 0 - 255
// points 表示位图数据
// */
//- (void)XYPrintRasterBitmapWith:(int)m
//                             xL:(int)xL
//                             xH:(int)xH
//                             yl:(int)yL
//                             yh:(int)yH
//                         points:(NSArray *)points;
///**
// * 63.设置条码宽度
// * 范围：n  2 - 6
// */
//- (void)XYSetBarcodeWidth:(int)n;
//#pragma mark - ============汉字字符控制命令============
///**
// * 64.设置汉字字符模式
// * 范围：n  0 - 255
// */
//- (void)XYSetChineseCharacterModel:(int)n;
///**
// * 65.选择汉字模式
// */
//- (void)XYSelectChineseCharacterModel;
///**
// * 66.选择/取消汉字下划线模式
// * 范围：n  0 - 2 或 48 - 50
// */
//- (void)XYSelectOrCancelChineseUderlineModel:(int)n;
///**
// * 67.取消汉字模式
// */
//- (void)XYCancelChineseModel;
///**
// * 68.定义用户自定义汉字
// * c1,c2代表字符编码
// * points 表示汉子矩阵
// */
//- (void)XYDefineCustomChinesePointsC1:(int)c1 c2:(int)c2 points:(NSArray *)points;
///**
// * 69.设置汉字字符左右间距
// * 范围：n1  0 - 255
// n2  0 - 255
// */
//- (void)XYSetChineseMarginWithLeftN1:(int)n1 n2:(int)n2;
///**
// * 70.选择/取消汉字倍高倍宽
// * 范围：n  0 - 255
// */
//- (void)XYSelectOrCancelChineseHModelAndWModel:(int)n;
//#pragma mark - ============打印机提示命令============
///**
// * 72.打印机来单打印蜂鸣提示
// * 范围：n  1 - 9
// t  1 - 9
// */
//- (void)XYPrinterSound:(int)n t:(int)t;
///**
// * 73.打印机来单打印蜂鸣提示及报警灯闪烁
// * 范围：m  1 - 20
// t  1 - 20
// n  0 - 3
// */
//- (void)XYPrinterSoundAndAlarmLight:(int)m t:(int)t n:(int)n;

- (void)POSSetCommandMode:(BOOL)Mode;

/*
 * 74.设置打印机发送命令模式
 * 范围：0，1
 ＊ 0:立即发送
 ＊ 1:批量发送
 */

-(NSArray*)POSGetBuffer;
/*
 * 75.返回等待发送指令队列
 */

-(void)POSClearBuffer;
/*
 * 76.清空等待发送指令队列
 */

-(void)POSSendCommandBuffer;
/*
 * 77.发送指令队列
 */


@end
