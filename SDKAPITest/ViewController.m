//
//  ViewController.m
//  SDKAPITest
//
//  Created by Jue on 2018/10/31.
//  Copyright © 2018年 Jue. All rights reserved.
//

#import "ViewController.h"
#import <RongIMKit/RongIMKit.h>

#define PLIST_PATH [[NSBundle mainBundle] pathForResource:@"Parameters" ofType:@"plist"]
#define DATA [[NSDictionary alloc] initWithContentsOfFile:PLIST_PATH]
#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)NSArray *testAPIs;
@property (nonatomic, strong)UIAlertController *alert;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view addSubview:self.tableView];
    [self initRongCloud];
    self.testAPIs = @[@"测试连接", @"发送单聊消息", @"发送群组消息", @"加入聊天室并发送消息", @"发送聊天室消息"];
}

- (void)viewDidLayoutSubviews {
    [self.view addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"H:|[_tableView]|"
      options:0
      metrics:nil
      views:NSDictionaryOfVariableBindings(_tableView)]];

    [self.view addConstraints:
     [NSLayoutConstraint
      constraintsWithVisualFormat:@"V:|[_tableView]|"
      options:0
      metrics:nil
      views:NSDictionaryOfVariableBindings(_tableView)]];
}

#pragma mark tabelview data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.testAPIs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reusableCellWithIdentifier = @"testAPIsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableCellWithIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reusableCellWithIdentifier];
    }
    cell.textLabel.text = self.testAPIs[indexPath.row];
    cell.textLabel.font = [UIFont systemFontOfSize:20.f];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch (indexPath.row) {
        case 0:
            [self conncetToRongCloud];
            break;
            
        case 1:
            [self sendPrivateMessage];
            break;
            
        case 2:
            [self sendGroupMessage];
            break;
            
        case 3:
            [self joinChatRoom];
            break;
            
        default:
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

#pragma mark lazy loading
- (UITableView *)tableView {
    if (_tableView == nil) {
        _tableView = [UITableView new];
        _tableView.tableFooterView = [UIView new];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.backgroundColor = [UIColor colorWithRed:224 / 255.f green:224 / 255.f blue:223 / 255.f alpha:0.8f];
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}

#pragma mark private method
- (void)alertInfo:(NSString *)infoStr {
    self.alert = [UIAlertController alertControllerWithTitle:nil message:infoStr preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [self.alert addAction:action];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:self.alert animated:YES completion:nil];
    });
}

/**
 初始化SDK
 */
- (void)initRongCloud {
    NSDictionary *parameterDic = DATA[@"init"];
    NSString *appkey = parameterDic[@"appkey"];
    [[RCIM sharedRCIM] initWithAppKey:appkey];
}

/**
 连接融云测试
 */
- (void)conncetToRongCloud {
    NSDictionary *parameterDic = DATA[@"connect"];
    NSString *token = parameterDic[@"token"];
    __weak typeof(self) weakSelf = self;
    [[RCIM sharedRCIM] connectWithToken:token
                                success:^(NSString *userId) {
                                    [weakSelf alertInfo:@"连接成功"];
                                } error:^(RCConnectErrorCode status) {
                                    [weakSelf alertInfo:[NSString stringWithFormat:@"连接失败，错误码：%ld",(long)status]];
                                } tokenIncorrect:^{
                                    [weakSelf alertInfo:@"连接失败，token无效"];
                                }];
}

/**
 发送单聊消息测试
 */
- (void)sendPrivateMessage {
    NSDictionary *parameterDic = DATA[@"privateMessage"];
    NSString *targetId = parameterDic[@"targetId"];
    [self sendMessageWith:ConversationType_PRIVATE targetId:targetId];
}

/**
 发送群组消息测试
 */
- (void)sendGroupMessage {
    NSDictionary *parameterDic = DATA[@"groupMessage"];
    NSString *targetId = parameterDic[@"targetId"];
    [self sendMessageWith:ConversationType_GROUP targetId:targetId];
}

/**
 发送消息方法

 @param conversationType 会话类型
 @param targetId 会话Id
 */
- (void)sendMessageWith:(RCConversationType)conversationType targetId:(NSString *)targetId {
    RCTextMessage *testMsg = [RCTextMessage messageWithContent:@"测试消息"];
    __weak typeof(self) weakSelf = self;
    [[RCIM sharedRCIM] sendMessage:conversationType targetId:targetId content:testMsg pushContent:nil pushData:nil success:^(long messageId) {
        [weakSelf alertInfo:@"发送成功"];
    } error:^(RCErrorCode nErrorCode, long messageId) {
        if (nErrorCode == 22406) {
            [weakSelf alertInfo:[NSString stringWithFormat:@"发送失败，messageId: %ld，原因：非群组成员",(long)messageId]];
        } else {
            [weakSelf alertInfo:[NSString stringWithFormat:@"发送失败，messageId: %ld，错误码：%ld",(long)messageId,(long)nErrorCode]];
        }
    }];
}

- (void)joinChatRoom {
    NSDictionary *parameterDic = DATA[@"joinChatroom"];
    NSString *targetId = parameterDic[@"targetId"];
    WS(weakself);
    [[RCIMClient sharedRCIMClient] joinChatRoom:targetId messageCount:10 success:^{
        [weakself sendMessageWith:ConversationType_CHATROOM targetId:targetId];
    } error:^(RCErrorCode status) {
        [weakself alertInfo:[NSString stringWithFormat:@"加入失败，错误码: %ld",(long)status]];
    }];
}
@end
