//
//  XYWIFIManager.m
//  Printer
//
//  Created by apple on 16/4/5.
//  Copyright © 2016年 Admin. All rights reserved.
//

#import "POSWIFIManager.h"
#import "AsyncSocket.h"
#import <SystemConfiguration/CaptiveNetwork.h>

static POSWIFIManager *shareManager = nil;

@interface POSWIFIManager ()<AsyncSocketDelegate>
// 连接的socket对象
@property (nonatomic,strong) AsyncSocket *sendSocket;
@property (nonatomic,strong) NSTimer *connectTimer;
@end

@implementation POSWIFIManager
+ (instancetype)shareWifiManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareManager = [[POSWIFIManager alloc] init];
    });
    return shareManager;
}

- (instancetype)init {
    if (self = [super init]) {
        _sendSocket = [[AsyncSocket alloc] initWithDelegate:self];
        _sendSocket.userData = SocketOfflineByServer;
        _commandBuffer=[[NSMutableArray alloc]init];
    }
    return self;
}

/**
 手动断开连接
 */
- (void)POSDisConnect {
    
    if (_sendSocket) {
        _sendSocket.userData = SocketOfflineByUser;
        _isAutoDisconnect = NO;
        [self.connectTimer invalidate];
        [_sendSocket disconnect];
    }
}


-(void)POSWriteCommandWithData:(NSData *)data{
    if (_connectOK) {
         NSLog(@"----%@",data);
        if (commandSendMode==0){
            [_sendSocket writeData:data withTimeout:-1 tag:0];
           
        }
        else
            [_commandBuffer addObject: data];
        //[_sendSocket writeData:data withTimeout:-1 tag:0];
    }

    
}

-(void)POSWriteCommandWithData:(NSData *)data withResponse:(POSWIFICallBackBlock)block{

    if (_connectOK) {
        self.callBackBlock = block;
        if (commandSendMode==0)
            [_sendSocket writeData:data withTimeout:-1 tag:0];
        else
            [_commandBuffer addObject: data];
        //[_sendSocket writeData:data withTimeout:-1 tag:0];
    }

}

/**
 发送消息
 */
- (void)POSSendMSGWith:(NSString *)str {
    if (_connectOK) {
        str = [str stringByAppendingString:@"\r\n"];
        NSData *data = [str dataUsingEncoding:NSASCIIStringEncoding];
        NSLog(@"%@==%@",str,data);
        if (commandSendMode==0)
       [_sendSocket writeData:data withTimeout:-1 tag:0];
        else
        [_commandBuffer addObject: data];
       
    }
}
//
///**
//    发送POS指令
// */
//- (void)XYWritePOSCommandWithData:(NSData *)data withResponse:(XYWIFICallBackBlock)block {
//    if (_connectOK) {
//        self.callBackBlock = block;
//        if (commandSendMode==0)
//            [_sendSocket writeData:data withTimeout:-1 tag:0];
//        else
//            [_commandBuffer addObject: data];
//        //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    }
//}

//连接主机
-(void)POSConnectWithHost:(NSString *)hostStr port:(UInt16)port completion:(POSWIFIBlock)block
{
    _connectOK = NO;
    _hostStr = hostStr;
    _port = port;
    
    NSError *error=nil;
    // 填写主机地址 和 端口号
    //_connectOK = [_sendSocket connectToHost: hostStr onPort: port error: &error];
    _connectOK=[self.sendSocket connectToHost:hostStr onPort:port withTimeout:3 error:&error];
    block(_connectOK);
////    self.callBack = block;
//    if (!_connectOK)
//    {
//        NSLog(@"%@",error);
//        [self showAlert:@"连接失败"];
//    }else{
//        NSLog(@"connect success!");
//        [self onSocket:_sendSocket didConnectToHost:hostStr port:port];
//    }
//    
//    [_sendSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
}

// 已经建立连接
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"%s host=%@  port = %d", __FUNCTION__, host,port);
    if ([self.delegate respondsToSelector:@selector(POSWIFIManager:didConnectedToHost:port:)]) {
        [self.delegate POSWIFIManager:self didConnectedToHost:host port:port];
    }
//    self.callBack(YES);
    // 每隔30s像服务器发送心跳包
    //self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];// 在longConnectToSocket方法中进行长连接需要向服务器发送的讯息
    
    //[self.connectTimer fire];

    [_sendSocket readDataWithTimeout: -1 tag: 0];
}

- (void)longConnectToSocket {
    // 根据服务器要求发送固定格式的数据，假设为指令@"longConnect"，但是一般不会是这么简单的指令
    
    NSString *longConnect = @"longConnect";
    
    NSData   *dataStream  = [longConnect dataUsingEncoding:NSUTF8StringEncoding];
    
    //[_sendSocket writeData:dataStream withTimeout:1 tag:1];

    //[_sendSocket writeData:dataStream withTimeout:-1 tag:0];


}

/**
 写数据
 */
- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"%s %d, tag = %ld", __FUNCTION__, __LINE__, tag);
    if ([self.delegate respondsToSelector:@selector(POSWIFIManager:didWriteDataWithTag:)]) {
        [self.delegate POSWIFIManager:self didWriteDataWithTag:tag];
    }
    [_sendSocket readDataWithTimeout: -1 tag: 0];
}

// 遇到错误关闭连接
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    _isAutoDisconnect = YES;
    if ([self.delegate respondsToSelector:@selector(POSWIFIManager:willDisconnectWithError:)]) {
        [self.delegate POSWIFIManager:self willDisconnectWithError:err];
    }
    NSLog(@"%s %d, tag = %@", __FUNCTION__, __LINE__, err);
}

// 读取数据 这里必须要使用流式数据
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    
    NSString *msg = [[NSString alloc] initWithData: data encoding:NSUTF8StringEncoding];
    
    if ([self.delegate respondsToSelector:@selector(POSWIFIManager:didReadData:tag:)]) {
        [self.delegate POSWIFIManager:self didReadData:data tag:tag];
    }
    self.callBackBlock(data);
    NSLog(@"%s %d, ==读取到从服务端返回的内容=== %@", __FUNCTION__, __LINE__, msg);
    
    [_sendSocket readDataWithTimeout: -1 tag: 0];
}

// 断开连接后执行
- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    NSLog(@"%s %d", __FUNCTION__, __LINE__);
    _connectOK = NO;
    if ([self.delegate respondsToSelector:@selector(POSWIFIManagerDidDisconnected:)]) {
        [self.delegate POSWIFIManagerDidDisconnected:self];
    }
    if (sock.userData == SocketOfflineByServer) {
        _isAutoDisconnect = YES;
        // 重连
        
        [self POSConnectWithHost:_hostStr port:_port completion:^(BOOL isConnect) {
            
        }];
    }else if (sock.userData == SocketOfflineByUser) {
        _isAutoDisconnect = NO;
        return;
    }
    
}

- (void)showAlert:(NSString *)str {
    UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"提示" message:str delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alter show];
}

//#pragma mark - =============打印机TSC指令============
///**
// * 1.设置标签尺寸
// */
//- (void)XYaddSizeWidth:(int)width height:(int)height; {
//    
//    NSString *sizeStr = [NSString stringWithFormat:@"SIZE %d mm,%d mm",width,height];
//    [self XYSendMSGWith:sizeStr];
//}
///**
// * 2.设置间隙长度
// */
//- (void)XYaddGap:(int)gap {
//    
//    NSString *gapStr = [NSString stringWithFormat:@"GAP %d mm,0",gap];
//    [self XYSendMSGWith:gapStr];
//}
///**
// * 3.产生钱箱控制脉冲
// */
//- (void)XYaddCashDrwer:(int)m  t1:(int)t1  t2:(int)t2 {
//    NSString *cash = [NSString stringWithFormat:@"CASHDRAWER %d,%d,%d",m,t1,t2];
//    [self XYSendMSGWith:cash];
//}
///**
// * 4.控制每张标签的停止位置
// */
//- (void)XYaddOffset:(float)offset {
//    NSString *offsetStr = [NSString stringWithFormat:@"OFFSET %.1f mm",offset];
//    [self XYSendMSGWith:offsetStr];
//}
///**
// * 5.设置打印速度
// */
//- (void)XYaddSpeed:(float)speed {
//    NSString *speedStr = [NSString stringWithFormat:@"SPEED %.1f",speed];
//    [self XYSendMSGWith:speedStr];
//}
///**
// * 6.设置打印浓度
// */
//- (void)XYaddDensity:(int)n {
//    NSString *denStr = [NSString stringWithFormat:@"DENSITY %d",n];
//    [self XYSendMSGWith:denStr];
//}
///**
// * 7.设置打印方向和镜像
// */
//- (void)XYaddDirection:(int)n {
//    NSString *directionStr = [NSString stringWithFormat:@"DIRECTION %d",n];
//    [self XYSendMSGWith:directionStr];
//}
///**
// * 8.设置原点坐标
// */
//- (void)XYaddReference:(int)x  y:(int)y {
//    NSString *refStr = [NSString stringWithFormat:@"REFERENCE %d,%d",x,y];
//    [self XYSendMSGWith:refStr];
//}
///**
// * 9.清除打印缓冲区数据
// */
//- (void)XYaddCls {
//    NSString *clsStr = @"CLS ";
//    [self XYSendMSGWith:clsStr];
//}
///**
// * 10.走纸
// */
//- (void)XYaddFeed:(int)feed {
//    NSString *feedStr = [NSString stringWithFormat:@"FEED %d",feed];
//    [self XYSendMSGWith:feedStr];
//}
///**
// * 11.退纸
// */
//- (void)XYaddBackFeed:(int)feed {
//    NSString *back = [NSString stringWithFormat:@"BACKFEED %d",feed];
//    [self XYSendMSGWith:back];
//}
///**
// * 12.走一张标签纸距离
// */
//- (void)XYaddFormFeed {
//    [self XYSendMSGWith:@"FORMFEED "];
//}
///**
// * 13.标签位置进行一次校准
// */
//- (void)XYaddHome {
//    [self XYSendMSGWith:@"HOME "];
//}
///**
// * 14.打印标签
// */
//- (void)XYaddPrint:(int)m {
//    NSString *printStr = [NSString stringWithFormat:@"PRINT %d",m];
//    [self XYSendMSGWith:printStr];
//}
///**
// * 15.设置国际代码页
// */
//- (void)XYaddCodePage:(int)page {
//    NSString *code = [NSString stringWithFormat:@"CODEPAGE %d",page];
//    [self XYSendMSGWith:code];
//}
///**
// * 16.设置蜂鸣器
// */
//- (void)XYaddSound:(int)level interval:(int)interval {
//    NSString *soundStr = [NSString stringWithFormat:@"SOUND %d,%d",level,interval];
//    [self XYSendMSGWith:soundStr];
//}
///**
// * 17.设置打印机报错
// */
//- (void)XYaddLimitFeed:(int)feed {
//    NSString *limitStr = [NSString stringWithFormat:@"LIMITFEED %d mm",feed];
//    [self XYSendMSGWith:limitStr];
//}
///**
// * 18.在打印缓冲区绘制黑块
// */
//- (void)XYaddBar:(int)x y:(int)y width:(int)width height:(int)height {
//    NSString *barStr = [NSString stringWithFormat:@"BAR %d,%d,%d,%d",x,y,width,height];
//    [self XYSendMSGWith:barStr];
//}
///**
// * 19.在打印缓冲区绘制一维条码
// */
//- (void)XYadd1DBarcodeX:(int)x
//                      y:(int)y
//                   type:(NSString *)type
//                 height:(int)height
//               readable:(int)readable
//               rotation:(int)rotation
//                 narrow:(int)narrow
//                   wide:(int)wide
//                content:(NSString *)content
//{
//    NSString *codeStr = [NSString stringWithFormat:@"BARCODE %d,%d,\"%@\",%d,%d,%d,%d,%d,\"%@\"",x,y,type,height,readable,rotation,narrow,wide,content];
//    [self XYSendMSGWith:codeStr];
//}
///**
// * 20.在打印缓冲区绘制矩形
// */
//- (void)XYaddBox:(int)x y:(int)y xend:(int)xend yend:(int)yend {
//    NSString *boxStr = [NSString stringWithFormat:@"BOX %d,%d,%d,%d",x,y,xend,yend];
//    [self XYSendMSGWith:boxStr];
//}
///**
// * 21.在打印缓冲区绘制位图
// */
//- (void)XYaddBitmap:(int)x
//                  y:(int)y
//              width:(int)width
//             height:(int)height
//               mode:(int)mode data:(int)data {
//    NSString *bitStr = [NSString stringWithFormat:@"BITMAP %d,%d,%d,%d,%d,%d",x,y,width,height,mode,data];
//    [self XYSendMSGWith:bitStr];
//}
///**
// * 22.擦除打印缓冲区中指定区域的数据
// */
//- (void)XYaddErase:(int)x y:(int)y xwidth:(int)xwidth yheight:(int)yheight {
//    NSString *eraseStr = [NSString stringWithFormat:@"ERASE %d,%d,%d,%d",x,y,xwidth,yheight];
//    [self XYSendMSGWith:eraseStr];
//}
///**
// * 23.将指定区域的数据黑白反色
// */
//- (void)XYaddReverse:(int)x y:(int)y xwidth:(int)xwidth yheight:(int)yheight {
//    NSString *revStr = [NSString stringWithFormat:@"REVERSE %d,%d,%d,%d",x,y,xwidth,yheight];
//    [self XYSendMSGWith:revStr];
//}
///**
// * 24.将指定区域的数据黑白反色
// */
//- (void)XYaddText:(int)x y:(int)y font:(NSString *)font rotation:(int)rotation x_mul:(int)xmul y_mul:(int)ymul content:(NSString *)content {
//    NSString *text = [NSString stringWithFormat:@"TEXT %d,%d,%@,%d,%d,%d,%@",x,y,font,rotation,xmul,ymul,content];
//    [self XYSendMSGWith:text];
//}
///**
// * 25.在打印缓冲区中绘制文字
// */
//- (void)XYaddQRCode:(int)x y:(int)y level:(int)level cellWidth:(int)cellWidth rotation:(int)totation data:(NSString *)dataStr {
////    NSString *qrCode = [@"QRCODE " stringByAppendingString:enable];
//    NSString *qrCode = [NSString stringWithFormat:@"QRCODE %d,%d,%d,%d,%d,%@",x,y,level,cellWidth,totation,dataStr];
//    [self XYSendMSGWith:qrCode];
//}
///**
// * 26.设置剥离功能是否开启
// */
//- (void)XYaddPeel:(NSString *)enable {
//    NSString *peel = [@"SET PEEL " stringByAppendingString:enable];
//    [self XYSendMSGWith:peel];
//}
///**
// * 27.设置撕离功能是否开启
// */
//- (void)XYaddTear:(NSString *)enable {
//    NSString *tear = [@"SET TEAR " stringByAppendingString:enable];
//    [self XYSendMSGWith:tear];
//}
///**
// * 28.设置切刀功能是否开启
// */
//- (void)XYaddCut:(NSString *)enable {
//    NSString *cut = [@"SET CUTTER " stringByAppendingString:enable];
//    [self XYSendMSGWith:cut];
//}
///**
// * 29.设置打印机出错时，是否打印上一张内容
// */
//- (void)XYaddReprint:(NSString *)enable {
//    NSString *reprint = [@"SET REPRINT " stringByAppendingString:enable];
//    [self XYSendMSGWith:reprint];
//}
///**
// * 30.设置是否按走纸键打印最近一张标签
// */
//- (void)XYaddPrintKeyEnable:(NSString *)enable {
//    NSString *printKey = [@"SET PRINTKEY " stringByAppendingString:enable];
//    [self XYSendMSGWith:printKey];
//}
///**
// * 31.设置按走纸键打印最近一张标签的份数
// */
//- (void)XYaddPrintKeyNum:(int)m {
//    NSString *printKey = [NSString stringWithFormat:@"SET PRINTKEY %d",m];
//    [self XYSendMSGWith:printKey];
//}
//
//#pragma mark - ===============打印机POS指令================
//#pragma mark - 水平定位
//- (void)XYhorizontalPosition {
//    Byte kValue[1] = {0};
//    kValue[0] = 0x09;
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//
//#pragma mark - 打印并换行
//- (void)XYprintAndFeed {
//    Byte kValue[1] = {0};
//    kValue[0] = 0x0A;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//
//#pragma mark - 打印并回到标准模式
//- (void)XYPrintAndBackToNormalModel {
//    Byte kValue[1] = {0};
//    kValue[0] = 0x0C;
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//#pragma mark - 页模式下取消打印
//- (void)XYCancelPrintData {
//    Byte kValue[1] = {0};
//    kValue[0] = 0x18;
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//
//#pragma mark -实时状态传送
//- (void)XYUpdataPrinterState:(int)param completion:(XYWIFICallBackBlock)callBlock {
//    self.callBackBlock = callBlock;
//    Byte kValue[3] = {0};
//    kValue[0] = 16;
//    kValue[1] = 4;
//    kValue[2] = param;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//    
//}
//#pragma mark -  实时对打印机请求
//- (void)XYUpdataPrinterAnswer:(int)param {
//    Byte kValue[3] = {0};
//    kValue[0] = 16;
//    kValue[1] = 5;
//    kValue[2] = param;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//
//#pragma mark - 实时产生钱箱开启脉冲
//- (void)XYOpenBoxAndPulse:(int) n m:(int) m t:(int) t {
//    Byte kValue[5] = {0};
//    kValue[0] = 16;
//    kValue[1] = 20;
//    kValue[2] = n;
//    kValue[3] = m;
//    kValue[4] = t;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//
//#pragma mark - 页模式下打印
//- (void)XYPrintOnPageModel {
//    Byte kValue[2] = {0};
//    kValue[0] = 0x1B;
//    kValue[1] = 0x0c;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//
//#pragma mark - 设置字符右间距
//- (void)XYSetCharRightMargin:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 27;
//    kValue[1] = 32;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//
//#pragma mark - 选择打印模式
//- (void)XYSelectPrintModel:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 27;
//    kValue[1] = 33;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//
//#pragma mark - 设置打印绝对位置
//- (void)XYSetPrintLocationWithParam:(int)nL nH:(int)nH {
//    
//    Byte kValue[4] = {0};
//    kValue[0] = 27;
//    kValue[1] = 36;
//    kValue[2] = nL;
//    kValue[3] = nH;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//
//#pragma mark - 12.选择/取消用户自定义字符
//- (void)XYSelectOrCancelCustomCharacter:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 27;
//    kValue[1] = 37;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//
//
///**
// * 13.定义用户自定义字符
// */
//- (void)XYDefinCustomCharacter:(int)y c1:(int)c1 c2:(int)c2 dx:(NSArray *)points
//{
//    int length = 5 + points.count;
//    
//    Byte kValue[length];
//    kValue[0] = 27;
//    kValue[1] = 38;
//    kValue[2] = y;
//    kValue[3] = c1;
//    kValue[4] = c2;
//    
//    for (int i = 0; i<points.count; i++) {
//        NSString *str = points[i];
//        kValue[5+i] = str.intValue;
//    }
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//
///**
// * 14.选择位图模式
// */
//- (void)XYSelectBitmapModel:(int)m nL:(int)nL nH:(int)nH dx:(NSArray *)points
//{    int length = 5 + points.count;
//    Byte kValue[length];
//    kValue[0] = 27;
//    kValue[1] = 42;
//    kValue[2] = m;
//    kValue[3] = nL;
//    kValue[4] = nH;
//    
//    for (int i = 0; i<points.count; i++) {
//        NSString *va = points[i];
//        kValue[5+i] = va.intValue;
//    }
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//    
//}
//
///**
// * 15.取消下划线模式
// */
//- (void)XYCancelUnderLineModelWith:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 27;
//    kValue[1] = 45;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 16.设置默认行间距
// */
//- (void)XYSetDefaultLineMargin {
//    Byte kValue[2] = {0};
//    kValue[0] = 27;
//    kValue[1] = 50;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//
///**
// * 17.设置行间距
// */
//- (void)XYSetLineMarginWith:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 27;
//    kValue[1] = 51;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//
///**
// * 18.选择打印机
// */
//- (void)XYSelectPrinterWith:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 27;
//    kValue[1] = 61;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 19.取消用户自定义字符
// */
//- (void)XYCancelCustomCharacterWith:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 27;
//    kValue[1] = 63;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//
///**
// * 20.初始化打印机
// */
//- (void)XYInitializePrinter {
//    Byte kValue[2] = {0};
//    kValue[0] = 27;
//    kValue[1] = 64;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 21.设置横向跳格位置
// */
//- (void)XYSetTabLocationWith:(NSArray *)points {
//    
//    Byte kValue[3 + points.count];
//    kValue[0] = 27;
//    kValue[1] = 68;
//    
//    for (int i = 0; i<points.count; i++) {
//        NSString *str = points[i];
//        kValue[2+i] = str.intValue;
//        if (i == points.count-1) {
//            kValue[3+i] = 0;
//        }
//    }
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 22.选择/取消加粗模式
// */
//- (void)XYSelectOrCancelBoldModelWith:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 27;
//    kValue[1] = 69;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 23.选择/取消双重打印模式
// */
//- (void)XYSelectOrCancelDoublePrintModel:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 27;
//    kValue[1] = 71;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 24.打印并走纸
// */
//- (void)XYPrintAndPushPageWith:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 27;
//    kValue[1] = 74;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 25.选择页模式
// */
//- (void)XYSelectPageModel {
//    Byte kValue[2] = {0};
//    kValue[0] = 27;
//    kValue[1] = 76;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 26.选择字体
// */
//- (void)XYSelectFontWith:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 27;
//    kValue[1] = 77;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 27.选择国际字符集
// */
//- (void)XYSelectINTL_CHAR_SETWith:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 27;
//    kValue[1] = 82;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 28.选择标准模式
// */
//- (void)XYSelectNormalModel {
//    Byte kValue[2] = {0};
//    kValue[0] = 27;
//    kValue[1] = 83;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 29.在页模式下选择打印区域方向
// */
//- (void)XYSelectPrintDirectionOnPageModel:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 27;
//    kValue[1] = 84;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 30.选择/取消顺时针旋转90度
// */
//- (void)XYSelectOrCancelRotationClockwise:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 27;
//    kValue[1] = 86;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//
///**
// * 31.页模式下设置打印区域
// */
//- (void)XYSetprintLocationOnPageModelWithXL:(int)xL
//                                         xH:(int)xH
//                                         yL:(int)yL
//                                         yH:(int)yH
//                                        dxL:(int)dxL
//                                        dxH:(int)dxH
//                                        dyL:(int)dyL
//                                        dyH:(int)dyH
//{
//    Byte kValue[10];
//    kValue[0] = 27;
//    kValue[1] = 87;
//    kValue[2] = xL;
//    kValue[3] = xH;
//    kValue[4] = yL;
//    kValue[5] = yH;
//    kValue[6] = dxL;
//    kValue[7] = dxH;
//    kValue[8] = dyL;
//    kValue[9] = dyH;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//
///**
// * 32.设置横向打印位置
// */
//- (void)XYSetHorizonLocationWith:(int)nL nH:(int)nH {
//    Byte kValue[4] = {0};
//    kValue[0] = 27;
//    kValue[1] = 92;
//    kValue[2] = nL;
//    kValue[3] = nH;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//
///**
// * 33.选择对齐方式
// */
//- (void)XYSelectAlignmentWithN:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 27;
//    kValue[1] = 97;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 34.选择打印纸传感器以输出信号
// */
//- (void)XYSelectSensorForOutputSignal:(int)n {
//    Byte kValue[4] = {0};
//    kValue[0] = 27;
//    kValue[1] = 99;
//    kValue[2] = 51;
//    kValue[3] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//
///**
// * 35.选择打印纸传感器以停止打印
// */
//- (void)XYSelectSensorForStopPrint:(int)n {
//    Byte kValue[4] = {0};
//    kValue[0] = 27;
//    kValue[1] = 99;
//    kValue[2] = 52;
//    kValue[3] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 36.允许/禁止按键
// */
//- (void)XYAllowOrDisableKeypress:(int)n {
//    Byte kValue[4] = {0};
//    kValue[0] = 27;
//    kValue[1] = 99;
//    kValue[2] = 53;
//    kValue[3] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 37.打印并向前走纸 N 行
// */
//- (void)XYPrintAndPushPageRow:(int)n{
//    Byte kValue[3] = {0};
//    kValue[0] = 27;
//    kValue[1] = 100;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 38.产生钱箱控制脉冲
// */
//- (void)XYMakePulseWithCashboxWithM:(int)m t1:(int)t1 t2:(int)t2 {
//    Byte kValue[5];
//    kValue[0] = 27;
//    kValue[1] = 112;
//    kValue[2] = m;
//    kValue[3] = t1;
//    kValue[4] = t2;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 39.选择字符代码表
// */
//- (void)XYSelectCharacterTabN:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 27;
//    kValue[1] = 116;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 40.选择/取消倒置打印模式
// */
//- (void)XYSelectOrCancelInversionPrintModel:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 27;
//    kValue[1] = 123;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//
///**
// * 41.打印下载到FLASH中的位图
// */
//- (void)XYPrintFlashBitmapWithN:(int)n m:(int)m {
//    Byte kValue[4] = {0};
//    kValue[0] = 28;
//    kValue[1] = 112;
//    kValue[2] = n;
//    kValue[3] = m;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 42.定义FLASH位图
// */
//- (void)XYDefinFlashBitmapWithN:(int)n Points:(NSArray *)points {
//    int length = points.count;
//    Byte kValue[3+length];
//    kValue[0] = 28;
//    kValue[1] = 113;
//    kValue[2] = n;
//    
//    for (int i = 0; i<points.count; i++) {
//        NSString *str = points[i];
//        kValue[3+i] = str.intValue;
//    }
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 43.选择字符大小
// */
//- (void)XYSelectCharacterSize:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 29;
//    kValue[1] = 33;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 44.页模式下设置纵向绝对位置
// */
//- (void)XYSetVertLocationOnPageModelWithnL:(int)nL nH:(int)nH {
//    Byte kValue[4] = {0};
//    kValue[0] = 29;
//    kValue[1] = 36;
//    kValue[2] = nL;
//    kValue[3] = nH;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 45.定义下载位图
// */
//- (void)XYDefineLoadBitmapWithX:(int)x Y:(int)y Points:(NSArray *)points {
//    Byte kValue[4+points.count];
//    kValue[0] = 29;
//    kValue[1] = 42;
//    kValue[2] = x;
//    kValue[3] = y;
//    
//    for (int i = 0; i<points.count; i++) {
//        NSString *str = points[i];
//        kValue[4+i] = str.intValue;
//    }
//    
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 46.执行打印数据十六进制转储
// */
//- (void)XYPrintDataAndSaveAsHexWithpL:(int)pL pH:(int)pH n:(int)n m:(int)m {
//    Byte kValue[7];
//    kValue[0] = 29;
//    kValue[1] = 40;
//    kValue[2] = 65;
//    kValue[3] = pL;
//    kValue[4] = pH;
//    kValue[5] = n;
//    kValue[6] = m;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 47.打印下载位图
// */
//- (void)XYPrintLoadBitmapM:(int)m {
//    Byte kValue[3] = {0};
//    kValue[0] = 29;
//    kValue[1] = 47;
//    kValue[2] = m;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 48.开始/结束宏定义
// */
//- (void)XYBeginOrEndDefine {
//    Byte kValue[2] = {0};
//    kValue[0] = 29;
//    kValue[1] = 58;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 49.选择/取消黑白反显打印模式
// */
//- (void)XYSelectORCancelBWPrintModel:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 29;
//    kValue[1] = 66;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 50.选择HRI字符的打印位置
// */
//- (void)XYSelectHRIPrintLocation:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 29;
//    kValue[1] = 72;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 51.设置左边距
// */
//- (void)XYSetLeftMarginWithnL:(int)nL nH:(int)nH {
//    Byte kValue[4] = {0};
//    kValue[0] = 29;
//    kValue[1] = 76;
//    kValue[2] = nL;
//    kValue[3] = nH;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 52.设置横向和纵向移动单位
// */
//- (void)XYSetHoriAndVertUnitXWith:(int)x y:(int)y {
//    Byte kValue[4] = {0};
//    kValue[0] = 29;
//    kValue[1] = 80;
//    kValue[2] = x;
//    kValue[3] = y;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 53.选择切纸模式并切纸
// */
//- (void)XYSelectCutPaperModelAndCutPaperWith:(int)m n:(int)n selectedModel:(int)model {
//    Byte kValue[4] = {0};
//    kValue[0] = 29;
//    kValue[1] = 86;
//    kValue[2] = m;
//    if (model == 1) {
//        kValue[3] = n;
//    }
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 54.设置打印区域宽高
// */
//- (void)XYSetPrintLocationWith:(int)nL nH:(int)nH {
//    Byte kValue[4] = {0};
//    kValue[0] = 29;
//    kValue[1] = 87;
//    kValue[2] = nL;
//    kValue[3] = nH;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 55.页模式下设置纵向相对位置
// */
//- (void)XYSetVertRelativeLocationOnPageModelWith:(int)nL nH:(int)nH {
//    Byte kValue[4] = {0};
//    kValue[0] = 29;
//    kValue[1] = 92;
//    kValue[2] = nL;
//    kValue[3] =nH;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 56.执行宏命令
// */
//- (void)XYRunMacroMommandWith:(int)r t:(int)t m:(int)m {
//    Byte kValue[5] = {0};
//    kValue[0] = 29;
//    kValue[1] = 94;
//    kValue[2] = r;
//    kValue[3] = t;
//    kValue[4] = m;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 57.打开/关闭自动状态反传功能(ASB)
// */
//- (void)XYOpenOrCloseASB:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 29;
//    kValue[1] = 97;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 58.选择HRI使用字体
// */
//- (void)XYSelectHRIFontToUse:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 29;
//    kValue[1] = 102;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 59. 选择条码高度
// */
//- (void)XYSelectBarcodeHeight:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 29;
//    kValue[1] = 104;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 60.打印条码
// */
//- (void)XYPrintBarCodeWithPoints:(int)m n:(int)n points:(NSArray *)points selectModel:(int)model {
//    
//    Byte kValue[4+points.count];
//    kValue[0] = 29;
//    kValue[1] = 107;
//    kValue[2] = m;
//    
//    if (model == 0) {
//        for (int i = 0; i<points.count; i++) {
//            NSString *str = points[i];
//            kValue[3+i] = str.intValue;
//            if (i == points.count-1) {
//                kValue[4+i] = 0;
//            }
//        }
//    }else if (model == 1) {
//        kValue[3] = n;
//        for (int i = 0; i<points.count; i++) {
//            NSString *str = points[i];
//            kValue[4+i] = str.intValue;
//        }
//    }
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//    
//}
///**
// * 61.返回状态
// */
//- (void)XYCallBackStatus:(int)n completion:(XYWIFICallBackBlock)block {
//    self.callBackBlock = block;
//    Byte kValue[3] = {0};
//    kValue[0] = 29;
//    kValue[1] = 114;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 62.打印光栅位图
// */
//- (void)XYPrintRasterBitmapWith:(int)m
//                             xL:(int)xL
//                             xH:(int)xH
//                             yl:(int)yL
//                             yh:(int)yH
//                         points:(NSArray *)points
//{
//    Byte kValue[8+points.count];
//    kValue[0] = 29;
//    kValue[1] = 118;
//    kValue[2] = 48;
//    kValue[3] = m;
//    kValue[4] = xL;
//    kValue[5] = xH;
//    kValue[6] = yL;
//    kValue[7] = yH;
//    
//    for (int i = 0; i<points.count; i++) {
//        NSString *str = points[i];
//        kValue[8+i] =str.intValue;
//    }
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 63.设置条码宽度
// */
//- (void)XYSetBarcodeWidth:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 29;
//    kValue[1] = 119;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//#pragma mark - ============汉字字符控制命令============
///**
// * 64.设置汉字字符模式
// */
//- (void)XYSetChineseCharacterModel:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 28;
//    kValue[1] = 33;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 65.选择汉字模式
// */
//- (void)XYSelectChineseCharacterModel {
//    Byte kValue[2] = {0};
//    kValue[0] = 28;
//    kValue[1] = 38;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 66.选择/取消汉字下划线模式
// */
//- (void)XYSelectOrCancelChineseUderlineModel:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 28;
//    kValue[1] = 45;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 67.取消汉字模式
// */
//- (void)XYCancelChineseModel {
//    Byte kValue[2] = {0};
//    kValue[0] = 28;
//    kValue[1] = 46;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 68.定义用户自定义汉字
// */
//- (void)XYDefineCustomChinesePointsC1:(int)c1 c2:(int)c2 points:(NSArray *)points {
//    Byte kValue[4 + points.count];
//    kValue[0] = 28;
//    kValue[1] = 50;
//    kValue[2] = c1;
//    kValue[3] = c2;
//    
//    for (int i=0; i<points.count; i++) {
//        NSString *str = points[i];
//        kValue[4+i] = str.intValue;
//    }
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//    
//}
///**
// * 69.设置汉字字符左右间距
// */
//- (void)XYSetChineseMarginWithLeftN1:(int)n1 n2:(int)n2 {
//    Byte kValue[4] = {0};
//    kValue[0] = 28;
//    kValue[1] = 83;
//    kValue[2] = n1;
//    kValue[3] = n2;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 70.选择/取消汉字倍高倍宽
// */
//- (void)XYSelectOrCancelChineseHModelAndWModel:(int)n {
//    Byte kValue[3] = {0};
//    kValue[0] = 28;
//    kValue[1] = 87;
//    kValue[2] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
//#pragma mark - ============打印机提示命令============
///**
// * 72.打印机来单打印蜂鸣提示
// */
//- (void)XYPrinterSound:(int)n t:(int)t {
//    Byte kValue[4] = {0};
//    kValue[0] = 27;
//    kValue[1] = 66;
//    kValue[2] = n;
//    kValue[3] = t;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}
///**
// * 73.打印机来单打印蜂鸣提示及报警灯闪烁
// */
//- (void)XYPrinterSoundAndAlarmLight:(int)m t:(int)t n:(int)n {
//    Byte kValue[5] = {0};
//    kValue[0] = 27;
//    kValue[1] = 67;
//    kValue[2] = m;
//    kValue[3] = t;
//    kValue[4] = n;
//    
//    NSData *data = [NSData dataWithBytes:&kValue length:sizeof(kValue)];
//    NSLog(@"%@",[NSString stringWithFormat:@"写入:%@",data]);
//    //[_sendSocket writeData:data withTimeout:-1 tag:0];
//    if (commandSendMode==0)
//        [_sendSocket writeData:data withTimeout:-1 tag:0];
//    else
//        [_commandBuffer addObject: data];
//}


-(NSArray*)POSGetBuffer
{
    return [_commandBuffer copy];
}

-(void)POSClearBuffer
{
    [_commandBuffer removeAllObjects];
}

-(void)sendCommand:(NSData *)data
{
    [_sendSocket writeData:data withTimeout:-1 tag:0];
}

-(void)POSSendCommandBuffer
{
    float timeInterver=0.5;
 
    for (int t=0;t<[_commandBuffer count];t++)
    {
        //[self performSelectorOnMainThread:@selector(sendCommand:) withObject:_commandBuffer[t] waitUntilDone:NO ];
        [self performSelector:@selector(sendCommand:) withObject:_commandBuffer[t] afterDelay:timeInterver];
        timeInterver=timeInterver+0.2;
    }
    [_commandBuffer removeAllObjects];
}

- (void)POSSetCommandMode:(BOOL)Mode{
    commandSendMode=Mode;
}


@end
