#import "TUIGroupInfoController_Minimalist.h"
#import "TUICommonModel.h"
#import "TUIGroupMembersCell.h"
#import "TUIGroupMemberCell.h"
#import "TUIGroupProfileCardViewCell_Minimalist.h"
#import "TUIGroupMemberController_Minimalist.h"
#import "TUIAddCell.h"
#import "TUIDefine.h"
#import "TUICore.h"
#import "TIMGroupInfo+TUIDataProvider.h"
#import "TUIGroupInfoDataProvider_Minimalist.h"
#import "TUIGroupManageController_Minimalist.h"
#import "TUIThemeManager.h"
#import "TUIGroupNoticeCell.h"
#import "TUIGroupNoticeController_Minimalist.h"
#import "TUISelectGroupMemberViewController_Minimalist.h"
#import "TUILogin.h"
#import "TUIGroupMemberTableViewCell_Minimalist.h"
#import "TUIGroupButtonCell_Minimalist.h"

#define ADD_TAG @"-1"
#define DEL_TAG @"-2"

@interface TUIGroupInfoController_Minimalist () <TUIModifyViewDelegate, TUIGroupMembersCellDelegate, TUIProfileCardDelegate, TUIGroupInfoDataProviderDelegate_Minimalist, TUINotificationProtocol>
@property(nonatomic, strong) TUIGroupInfoDataProvider_Minimalist *dataProvider;
@property (nonatomic, strong) TUINaviBarIndicatorView *titleView;
@property (nonatomic, strong) UIViewController *showContactSelectVC;
@property NSInteger tag;
@property (nonatomic, weak) UIViewController *callingSelectGroupMemberVC;
@property (nonatomic, copy) NSString *callingType;

@end

@implementation TUIGroupInfoController_Minimalist

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    self.dataProvider = [[TUIGroupInfoDataProvider_Minimalist alloc] initWithGroupID:self.groupId];
    self.dataProvider.delegate = self;
    [self.dataProvider loadData];
    
    @weakify(self)
    [RACObserve(self.dataProvider, dataList) subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        [self.tableView reloadData];
    }];
    
    _titleView = [[TUINaviBarIndicatorView alloc] init];
    self.navigationItem.titleView = _titleView;
    self.navigationItem.title = @"";
    [_titleView setTitle:TUIKitLocalizableString(ProfileDetails)];
    
    [TUICore registerEvent:TUICore_TUIContactNotify subKey:TUICore_TUIContactNotify_SelectedContactsSubKey object:self];
    
    [TUICore registerEvent:TUICore_TUIGroupNotify subKey:TUICore_TUIGroupNotify_SelectGroupMemberSubKey object:self];
    
}

- (void)setupViews {
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.backgroundColor = TUICoreDynamicColor(@"", @"#FFFFFF");
    self.tableView.delaysContentTouches = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = [UIColor whiteColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, -58, 0, 0);
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
}

- (void)updateData {
    [self.dataProvider loadData];
}

- (void)updateGroupInfo {
    [self.dataProvider updateGroupInfo];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataProvider.dataList.count;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor clearColor];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSMutableArray *array = self.dataProvider.dataList[section];
    return array.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *array = self.dataProvider.dataList[indexPath.section];
    NSObject *data = array[indexPath.row];
    if([data isKindOfClass:[TUIGroupProfileCardCellData_Minimalist class]]){
        return [(TUIGroupProfileCardCellData_Minimalist *)data heightOfWidth:Screen_Width];
    }
    else if([data isKindOfClass:[TUIGroupMemberCellData_Minimalist class]]){
        return [(TUIGroupMemberCellData_Minimalist *)data heightOfWidth:Screen_Width];
    }
    else if([data isKindOfClass:[TUIGroupButtonCellData_Minimalist class]]){
        return [(TUIGroupButtonCellData_Minimalist *)data heightOfWidth:Screen_Width];;
    }
    else if ([data isKindOfClass:[TUICommonSwitchCellData class]]) {
        return [(TUICommonSwitchCellData *)data heightOfWidth:Screen_Width];;
    }
    else if ([data isKindOfClass:TUIGroupNoticeCellData.class]) {
        return 72.0;
    }
    return kScale390(55);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *array = self.dataProvider.dataList[indexPath.section];
    NSObject *data = array[indexPath.row];
    @weakify(self)

    if([data isKindOfClass:[TUIGroupProfileCardCellData_Minimalist class]]){
        TUIGroupProfileCardViewCell_Minimalist *cell = [tableView dequeueReusableCellWithIdentifier:TGroupCommonCell_ReuseId];
        if(!cell){
            cell = [[TUIGroupProfileCardViewCell_Minimalist alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TGroupCommonCell_ReuseId];
        }
        [cell fillWithData:(TUIGroupProfileCardCellData_Minimalist *)data];
        __weak typeof(cell)weakCell = cell;
        cell.headerView.itemMessage.messageBtnClickBlock = ^{
            @strongify(self)
            [self onSendMessage:weakCell];
        };
        
        cell.headerView.itemAudio.messageBtnClickBlock = ^{
            @strongify(self)
            [self groupCall:self.dataProvider.groupInfo.groupID isVideoCall:NO];
        };
        
        cell.headerView.itemVideo.messageBtnClickBlock = ^{
            @strongify(self)
            [self groupCall:self.dataProvider.groupInfo.groupID isVideoCall:YES];
        };
        return cell;
    }
    else if([data isKindOfClass:[TUICommonTextCellData class]]){
        TUICommonTextCell *cell = [tableView dequeueReusableCellWithIdentifier:TKeyValueCell_ReuseId];
        if(!cell){
            cell = [[TUICommonTextCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TKeyValueCell_ReuseId];
        }
        [cell fillWithData:(TUICommonTextCellData *)data];
        cell.backgroundColor = TUICoreDynamicColor(@"", @"#f9f9f9");
        cell.contentView.backgroundColor = TUICoreDynamicColor(@"", @"#f9f9f9");

        return cell;
    }
    else if([data isKindOfClass:[TUIGroupMemberCellData_Minimalist class]]){
        TUIGroupMemberTableViewCell_Minimalist *cell = [tableView dequeueReusableCellWithIdentifier:TGroupMembersCell_ReuseId];
        if(!cell){
            cell = [[TUIGroupMemberTableViewCell_Minimalist alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TGroupMembersCell_ReuseId];
        }
        [cell fillWithData:(TUIGroupMemberCellData_Minimalist *)data];
        cell.backgroundColor = TUICoreDynamicColor(@"", @"#f9f9f9");
        cell.contentView.backgroundColor = TUICoreDynamicColor(@"", @"#f9f9f9");

        return cell;
    }
    else if([data isKindOfClass:[TUICommonSwitchCellData class]]){
        TUICommonSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:TSwitchCell_ReuseId];
        if(!cell){
            cell = [[TUICommonSwitchCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TSwitchCell_ReuseId];
        }
        [cell fillWithData:(TUICommonSwitchCellData *)data];
        cell.backgroundColor = TUICoreDynamicColor(@"", @"#f9f9f9");
        cell.contentView.backgroundColor = TUICoreDynamicColor(@"", @"#f9f9f9");
        return cell;
    }
    else if([data isKindOfClass:[TUIGroupButtonCellData_Minimalist class]]){
        TUIGroupButtonCell_Minimalist *cell = [tableView dequeueReusableCellWithIdentifier:TButtonCell_ReuseId];
        if(!cell){
            cell = [[TUIGroupButtonCell_Minimalist alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TButtonCell_ReuseId];
        }
        [cell fillWithData:(TUIGroupButtonCellData_Minimalist *)data];
        return cell;
    }
    else if([data isKindOfClass:TUIGroupNoticeCellData.class]) {
        TUIGroupNoticeCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TUIGroupNoticeCell"];
        if (cell == nil) {
            cell = [[TUIGroupNoticeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TUIGroupNoticeCell"];
        }
        cell.backgroundColor = TUICoreDynamicColor(@"", @"#f9f9f9");
        cell.contentView.backgroundColor = TUICoreDynamicColor(@"", @"#f9f9f9");
        cell.cellData = data;
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
}

- (void)leftBarButtonClick:(UIButton *)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark TUIGroupInfoDataProviderDelegate

- (void)onSendMessage:(TUIGroupProfileCardViewCell_Minimalist *)cell
{
    TUIGroupProfileCardCellData_Minimalist *cellData = cell.cardData;
    
    UIImage *avataImage = [UIImage new];
    if (cell.headerView.headImg.image) {
        avataImage = cell.headerView.headImg.image;
    }
    
    NSDictionary *param = @{
        TUICore_TUIChatService_GetChatViewControllerMethod_TitleKey : cellData.name ?: @"",
        TUICore_TUIChatService_GetChatViewControllerMethod_GroupIDKey : cellData.identifier ?: @"",
        TUICore_TUIChatService_GetChatViewControllerMethod_AvatarImageKey : avataImage ?: [UIImage new]
    };
    
    UIViewController *chatVC = (UIViewController *)[TUICore callService:TUICore_TUIChatService_Minimalist
                                                                 method:TUICore_TUIChatService_GetChatViewControllerMethod
                                                                  param:param];
    [self.navigationController pushViewController:(UIViewController *)chatVC animated:YES];
}

- (void)groupCall:(NSString *)groupID isVideoCall:(BOOL)isVideoCall {
    NSDictionary *param = @{
        TUICore_TUIGroupService_GetSelectGroupMemberViewControllerMethod_GroupIDKey : groupID,
        TUICore_TUIGroupService_GetSelectGroupMemberViewControllerMethod_NameKey : TUIKitLocalizableString(Make-a-call),
    };
    UIViewController *vc = [TUICore callService:TUICore_TUIGroupService_Minimalist
                                         method:TUICore_TUIGroupService_GetSelectGroupMemberViewControllerMethod
                                          param:param];
    [self.navigationController pushViewController:vc animated:YES];
    
    self.callingSelectGroupMemberVC = vc;
    self.callingType = isVideoCall ? @"1" : @"0";
}


- (void)didSelectMembers
{
    TUIGroupMemberController_Minimalist *membersController = [[TUIGroupMemberController_Minimalist alloc] init];
    membersController.groupId = _groupId;
    membersController.groupInfo = self.dataProvider.groupInfo;
    [self.navigationController pushViewController:membersController animated:YES];
}

- (void)didSelectAddOption:(UITableViewCell *)cell
{
    __weak typeof(self) weakSelf = self;
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:TUIKitLocalizableString(TUIKitGroupProfileJoinType) preferredStyle:UIAlertControllerStyleActionSheet];

    [ac tuitheme_addAction:[UIAlertAction actionWithTitle:TUIKitLocalizableString(TUIKitGroupProfileJoinDisable) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf.dataProvider setGroupAddOpt:V2TIM_GROUP_ADD_FORBID];
    }]];
    [ac tuitheme_addAction:[UIAlertAction actionWithTitle:TUIKitLocalizableString(TUIKitGroupProfileAdminApprove) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf.dataProvider setGroupAddOpt:V2TIM_GROUP_ADD_AUTH];
    }]];
    [ac tuitheme_addAction:[UIAlertAction actionWithTitle:TUIKitLocalizableString(TUIKitGroupProfileAutoApproval) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf.dataProvider setGroupAddOpt:V2TIM_GROUP_ADD_ANY];
    }]];
    [ac tuitheme_addAction:[UIAlertAction actionWithTitle:TUIKitLocalizableString(Cancel) style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)didSelectGroupNick:(TUICommonTextCell *)cell
{
    TUIModifyViewData *data = [[TUIModifyViewData alloc] init];
    data.title = TUIKitLocalizableString(TUIKitGroupProfileEditAlias);
    data.content = self.dataProvider.selfInfo.nameCard;
    data.desc = TUIKitLocalizableString(TUIKitGroupProfileEditAliasDesc);
    TUIModifyView *modify = [[TUIModifyView alloc] init];
    modify.tag = 2;
    modify.delegate = self;
    [modify setData:data];
    [modify showInWindow:self.view.window];
}

- (void)didSelectCommon
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    __weak typeof(self) weakSelf = self;
    if ([self.dataProvider.groupInfo isPrivate] || [TUIGroupInfoDataProvider_Minimalist isMeOwner:self.dataProvider.groupInfo]) {
        [ac tuitheme_addAction:[UIAlertAction actionWithTitle:TUIKitLocalizableString(TUIKitGroupProfileEditGroupName) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

            TUIModifyViewData *data = [[TUIModifyViewData alloc] init];
            data.title = TUIKitLocalizableString(TUIKitGroupProfileEditGroupName);
            data.content = weakSelf.dataProvider.profileCellData.name;
            data.desc = TUIKitLocalizableString(TUIKitGroupProfileEditGroupName);
            TUIModifyView *modify = [[TUIModifyView alloc] init];
            modify.tag = 0;
            modify.delegate = weakSelf;
            [modify setData:data];
            [modify showInWindow:weakSelf.view.window];

        }]];
    }
    if ([TUIGroupInfoDataProvider_Minimalist isMeOwner:self.dataProvider.groupInfo]) {
        [ac tuitheme_addAction:[UIAlertAction actionWithTitle:TUIKitLocalizableString(TUIKitGroupProfileEditAnnouncement) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

            TUIModifyViewData *data = [[TUIModifyViewData alloc] init];
            data.title = TUIKitLocalizableString(TUIKitGroupProfileEditAnnouncement);
            TUIModifyView *modify = [[TUIModifyView alloc] init];
            modify.tag = 1;
            modify.delegate = weakSelf;
            [modify setData:data];
            [modify showInWindow:weakSelf.view.window];
        }]];
    }

    if ([TUIGroupInfoDataProvider_Minimalist isMeOwner:self.dataProvider.groupInfo]) {
        @weakify(self)
        [ac tuitheme_addAction:[UIAlertAction actionWithTitle:TUIKitLocalizableString(TUIKitGroupProfileEditAvatar) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self)
            TUISelectAvatarController * vc = [[TUISelectAvatarController alloc] init];
            vc.selectAvatarType = TUISelectAvatarTypeGroupAvatar;
            vc.profilFaceURL = self.dataProvider.groupInfo.faceURL;
            [self.navigationController pushViewController:vc animated:YES];
            vc.selectCallBack = ^(NSString * _Nonnull urlStr) {
                if (urlStr.length > 0) {
                    V2TIMGroupInfo *info = [[V2TIMGroupInfo alloc] init];
                    info.groupID = self.groupId;
                    info.faceURL = urlStr;
                    [[V2TIMManager sharedInstance] setGroupInfo:info succ:^{
                        [self updateGroupInfo];
                    } fail:^(int code, NSString *msg) {
                        [TUITool makeToastError:code msg:msg];
                    }];
                }
            };
        }]];
    }
    
    [ac tuitheme_addAction:[UIAlertAction actionWithTitle:TUIKitLocalizableString(Cancel) style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:ac animated:YES completion:nil];
}

- (void)didSelectOnNotDisturb:(TUICommonSwitchCell *)cell
{
    V2TIMReceiveMessageOpt opt;
    if (cell.switcher.on) {
        opt = V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE;
    } else {
        opt = V2TIM_RECEIVE_MESSAGE;
    }
    @weakify(self)
    [V2TIMManager.sharedInstance markConversation:@[[NSString stringWithFormat:@"group_%@",self.groupId]] markType:@(V2TIM_CONVERSATION_MARK_TYPE_FOLD) enableMark:NO succ:nil fail:nil];
    
    [self.dataProvider setGroupReceiveMessageOpt:opt Succ:^{
        @strongify(self)
        [self updateGroupInfo];
    } fail:^(int code, NSString *desc) {}];
    
}

- (void)didSelectOnTop:(TUICommonSwitchCell *)cell
{
    if (cell.switcher.on) {
        [[TUIConversationPin sharedInstance] addTopConversation:[NSString stringWithFormat:@"group_%@",_groupId] callback:^(BOOL success, NSString * _Nonnull errorMessage) {
            if (success) {
                return;
            }
            cell.switcher.on = !cell.switcher.isOn;
            [TUITool makeToast:errorMessage];
        }];
    } else {
        [[TUIConversationPin sharedInstance] removeTopConversation:[NSString stringWithFormat:@"group_%@",_groupId] callback:^(BOOL success, NSString * _Nonnull errorMessage) {
            if (success) {
                return;
            }
            cell.switcher.on = !cell.switcher.isOn;
            [TUITool makeToast:errorMessage];
        }];
    }
}

- (void)didDeleteGroup:(TUIButtonCell *)cell
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:TUIKitLocalizableString(TUIKitGroupProfileDeleteGroupTips) preferredStyle:UIAlertControllerStyleActionSheet];

    @weakify(self)
    [ac tuitheme_addAction:[UIAlertAction actionWithTitle:TUIKitLocalizableString(Confirm) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {

        @strongify(self)
        @weakify(self)
        if ([self.dataProvider.groupInfo canDismissGroup]) {
            [self.dataProvider dismissGroup:^{
                @strongify(self)
                @weakify(self)
                dispatch_async(dispatch_get_main_queue(), ^{
                    @strongify(self)
                    UIViewController *vc = [self findConversationListViewController];
                    [[TUIConversationPin sharedInstance] removeTopConversation:[NSString stringWithFormat:@"group_%@",self.groupId] callback:nil];
                    [V2TIMManager.sharedInstance markConversation:@[[NSString stringWithFormat:@"group_%@",self.groupId]] markType:@(V2TIM_CONVERSATION_MARK_TYPE_FOLD) enableMark:NO succ:^(NSArray<V2TIMConversationOperationResult *> *result) {
                        [self.navigationController popToViewController:vc animated:YES];
                    } fail:^(int code, NSString *desc) {
                        [self.navigationController popToViewController:vc animated:YES];
                    }];
                    
                });
            } fail:^(int code, NSString *msg) {
                [TUITool makeToastError:code msg:msg];
            }];
        } else {
            [self.dataProvider quitGroup:^{
                @strongify(self)
                @weakify(self)
                dispatch_async(dispatch_get_main_queue(), ^{
                    @strongify(self)
                    UIViewController *vc = [self findConversationListViewController];
                    [[TUIConversationPin sharedInstance] removeTopConversation:[NSString stringWithFormat:@"group_%@",self.groupId] callback:nil];
                    [V2TIMManager.sharedInstance markConversation:@[[NSString stringWithFormat:@"group_%@",self.groupId]] markType:@(V2TIM_CONVERSATION_MARK_TYPE_FOLD) enableMark:NO succ:^(NSArray<V2TIMConversationOperationResult *> *result) {
                        [self.navigationController popToViewController:vc animated:YES];
                    } fail:^(int code, NSString *desc) {
                        [self.navigationController popToViewController:vc animated:YES];
                    }];
                });
            } fail:^(int code, NSString *msg) {
                [TUITool makeToastError:code msg:msg];
            }];
        }
    }]];

    [ac tuitheme_addAction:[UIAlertAction actionWithTitle:TUIKitLocalizableString(Cancel) style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}
- (UIViewController *)findConversationListViewController {
    UIViewController *vc = self.navigationController.viewControllers[0];
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isKindOfClass:NSClassFromString(@"TUIFoldListViewController")]) {
            return vc;
        }
    }
    return vc;
}

- (void)didSelectOnFoldConversation:(TUICommonSwitchCell *)cell {
   
    BOOL enableMark = NO;
    if (cell.switcher.on) {
        enableMark = YES;
    }
    cell.switchData.on = enableMark;

    @weakify(self)

    [V2TIMManager.sharedInstance markConversation:@[[NSString stringWithFormat:@"group_%@",self.groupId]] markType:@(V2TIM_CONVERSATION_MARK_TYPE_FOLD) enableMark:enableMark succ:nil fail:nil];

    [[TUIConversationPin sharedInstance] removeTopConversation:[NSString stringWithFormat:@"group_%@",self.groupId] callback:^(BOOL success, NSString * _Nonnull errorMessage) {
        @strongify(self)
        [self updateGroupInfo];
    }];
}

- (void)didSelectOnChangeBackgroundImage:(TUICommonTextCell *)cell {
    @weakify(self)
    NSString *conversationID = [NSString stringWithFormat:@"group_%@",self.groupId];
    TUISelectAvatarController * vc = [[TUISelectAvatarController alloc] init];
    vc.selectAvatarType = TUISelectAvatarTypeConversationBackGroundCover;
    vc.profilFaceURL =  [self getBackgroundImageUrlByConversationID:conversationID];
    [self.navigationController pushViewController:vc animated:YES];
    vc.selectCallBack = ^(NSString * _Nonnull urlStr) {
        @strongify(self)
        [self appendBackgroundImage:urlStr conversationID:conversationID];
        if (IS_NOT_EMPTY_NSSTRING(conversationID)) {
            [TUICore notifyEvent:TUICore_TUIGroupNotify subKey:TUICore_TUIGroupNotify_UpdateConversationBackgroundImageSubKey object:self param:@{TUICore_TUIGroupNotify_UpdateConversationBackgroundImageSubKey_ConversationID : conversationID}];
        }
    };
}

- (NSString *)getBackgroundImageUrlByConversationID:(NSString *)targerConversationID {
    if (targerConversationID.length == 0) {
        return nil;
    }
    NSDictionary *dict = [NSUserDefaults.standardUserDefaults objectForKey:@"conversation_backgroundImage_map"];
    if (dict == nil) {
        dict = @{};
    }
    NSString *conversationID_UserID = [NSString stringWithFormat:@"%@_%@",targerConversationID,[TUILogin getUserID]];
    if (![dict isKindOfClass:NSDictionary.class] || ![dict.allKeys containsObject:conversationID_UserID]) {
        return nil;
    }
    return [dict objectForKey:conversationID_UserID];
}

- (void)appendBackgroundImage:(NSString *)imgUrl conversationID:(NSString *)conversationID {
    if (conversationID.length == 0) {
        return;
    }
    NSDictionary *dict = [NSUserDefaults.standardUserDefaults objectForKey:@"conversation_backgroundImage_map"];
    if (dict == nil) {
        dict = @{};
    }
    if (![dict isKindOfClass:NSDictionary.class]) {
        return;
    }
    
    NSString *conversationID_UserID = [NSString stringWithFormat:@"%@_%@",conversationID,[TUILogin getUserID]];
    NSMutableDictionary *originDataDict = [NSMutableDictionary dictionaryWithDictionary:dict];
    if (imgUrl.length == 0) {
        [originDataDict removeObjectForKey:conversationID_UserID];
    }
    else {
        [originDataDict setObject:imgUrl forKey:conversationID_UserID];
    }
    
    [NSUserDefaults.standardUserDefaults setObject:originDataDict forKey:@"conversation_backgroundImage_map"];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (void)didTransferGroup:(TUIButtonCell *)cell {

    TUISelectGroupMemberViewController_Minimalist *vc = [[TUISelectGroupMemberViewController_Minimalist alloc] init];
    vc.optionalStyle = TUISelectMemberOptionalStyleTransferOwner;
    vc.groupId = self.groupId;
    vc.name = TUIKitLocalizableString(TUIKitGroupTransferOwner);
    @weakify(self);
    vc.selectedFinished = ^(NSMutableArray<TUIUserModel *> * _Nonnull modelList) {
        @strongify(self);
        TUIUserModel *userModel = modelList[0];
        NSString *groupId = self.groupId;
        NSString *member = userModel.userId;
        if (userModel && [userModel isKindOfClass:[TUIUserModel class]]) {
            @weakify(self);
            [self.dataProvider transferGroupOwner:groupId member:member succ:^{
                @strongify(self);
                [self updateGroupInfo];
                [TUITool makeToast:TUIKitLocalizableString(TUIKitGroupTransferOwnerSuccess)];
            } fail:^(int code, NSString *desc) {
                [TUITool makeToastError:code msg:desc];
            }];
        }
    };
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)didClearAllHistory:(TUIButtonCell *)cell
{
    @weakify(self)
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:TUIKitLocalizableString(TUIKitClearAllChatHistoryTips) preferredStyle:UIAlertControllerStyleAlert];
    [ac tuitheme_addAction:[UIAlertAction actionWithTitle:TUIKitLocalizableString(Confirm) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self)
        [self.dataProvider clearAllHistory:^{
            [TUICore notifyEvent:TUICore_TUIConversationNotify
                          subKey:TUICore_TUIConversationNotify_ClearConversationUIHistorySubKey
                          object:self
                           param:nil];
            [TUITool makeToast:@"success"];
        } fail:^(int code, NSString *desc) {
            [TUITool makeToastError:code msg:desc];
        }];
    }]];
    [ac tuitheme_addAction:[UIAlertAction actionWithTitle:TUIKitLocalizableString(Cancel) style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)didSelectGroupManage
{
    TUIGroupManageController_Minimalist *vc = [[TUIGroupManageController_Minimalist alloc] init];
    vc.groupID = self.groupId;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didSelectGroupNotice
{
    TUIGroupNoticeController_Minimalist *vc = [[TUIGroupNoticeController_Minimalist alloc] init];
    vc.groupID = self.groupId;
    __weak typeof(self) weakSelf = self;
    vc.onNoticeChanged = ^{
        [weakSelf updateGroupInfo];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark TUIProfileCardDelegate

-(void)didTapOnAvatar:(TUIProfileCardCell *)cell{
    TUISelectAvatarController * vc = [[TUISelectAvatarController alloc] init];
    vc.selectAvatarType = TUISelectAvatarTypeGroupAvatar;
    vc.profilFaceURL = self.dataProvider.groupInfo.faceURL;
    [self.navigationController pushViewController:vc animated:YES];
    @weakify(self)
    vc.selectCallBack = ^(NSString * _Nonnull urlStr) {
        @strongify(self)
        if (urlStr.length > 0) {
            V2TIMGroupInfo *info = [[V2TIMGroupInfo alloc] init];
            info.groupID = self.groupId;
            info.faceURL = urlStr;
            [[V2TIMManager sharedInstance] setGroupInfo:info succ:^{
                [self updateGroupInfo];
            } fail:^(int code, NSString *msg) {
                [TUITool makeToastError:code msg:msg];
            }];
        }
    };
}

#pragma mark TUIGroupMembersCellDelegate

- (void)didAddMemebers {
    
//    TUIGroupMemberCellData *mem = self.dataProvider.groupMembersCellData.members[index];
    NSMutableArray *ids = [NSMutableArray array];
    NSMutableDictionary *displayNames = [NSMutableDictionary dictionary];
    for (TUIGroupMemberCellData *cd in self.dataProvider.membersData) {
        if (![cd.identifier isEqualToString:[[V2TIMManager sharedInstance] getLoginUser]]) {
            [ids addObject:cd.identifier];
            [displayNames setObject:cd.name?:@"" forKey:cd.identifier?:@""];
        }
    }
    
    
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    param[TUICore_TUIContactService_GetContactSelectControllerMethod_TitleKey] = TUIKitLocalizableString(GroupAddFirend);
    param[TUICore_TUIContactService_GetContactSelectControllerMethod_DisableIdsKey] = ids;
    param[TUICore_TUIContactService_GetContactSelectControllerMethod_DisplayNamesKey] = displayNames;
    self.showContactSelectVC = [TUICore callService:TUICore_TUIContactService_Minimalist
                                             method:TUICore_TUIContactService_GetContactSelectControllerMethod
                                              param:param];
    [self.navigationController pushViewController:self.showContactSelectVC animated:YES];
    self.tag = 1;
}

- (void)didCurrentMemberAtCell:(TUIGroupMemberTableViewCell_Minimalist *)cell {
    TUIGroupMemberCellData_Minimalist *mem = (TUIGroupMemberCellData_Minimalist *)cell.data;
    NSMutableArray *ids = [NSMutableArray array];
    NSMutableDictionary *displayNames = [NSMutableDictionary dictionary];
    for (TUIGroupMemberCellData *cd in self.dataProvider.membersData) {
        if (![cd.identifier isEqualToString:[[V2TIMManager sharedInstance] getLoginUser]]) {
            [ids addObject:cd.identifier];
            [displayNames setObject:cd.name?:@"" forKey:cd.identifier?:@""];
        }
    }
    
    NSString *userID = mem.identifier;
    @weakify(self)
    [self getUserOrFriendProfileVCWithUserID:userID SuccBlock:^(UIViewController *vc) {
        @strongify(self)
        [self.navigationController pushViewController:vc animated:YES];
    } failBlock:^(int code, NSString *desc) {
        
    }];
}

- (void)getUserOrFriendProfileVCWithUserID:(NSString *)userID
                                 SuccBlock:(void(^)(UIViewController *vc))succ
                                 failBlock:(nullable V2TIMFail)fail {
    NSDictionary *param = @{
        TUICore_TUIContactService_GetUserOrFriendProfileVCMethod_UserIDKey: userID ? : @"",
        TUICore_TUIContactService_GetUserOrFriendProfileVCMethod_SuccKey: succ ? : ^(UIViewController *vc){},
        TUICore_TUIContactService_GetUserOrFriendProfileVCMethod_FailKey: fail ? : ^(int code, NSString * desc){}
    };
    [TUICore callService:TUICore_TUIContactService_Minimalist
                  method:TUICore_TUIContactService_GetUserOrFriendProfileVCMethod
                   param:param];
}

- (void)addGroupId:(NSString *)groupId memebers:(NSArray *)members
{
    @weakify(self)
    [[V2TIMManager sharedInstance] inviteUserToGroup:_groupId userList:members succ:^(NSArray<V2TIMGroupMemberOperationResult *> *resultList) {
        @strongify(self)
        [self updateData];
        [TUITool makeToast:TUIKitLocalizableString(add_success)];
    } fail:^(int code, NSString *desc) {
        [TUITool makeToastError:code msg:desc];
    }];
}

- (void)deleteGroupId:(NSString *)groupId memebers:(NSArray *)members
{
    @weakify(self)
    [[V2TIMManager sharedInstance] kickGroupMember:groupId memberList:members reason:@"" succ:^(NSArray<V2TIMGroupMemberOperationResult *> *resultList) {
        @strongify(self)
        [self updateData];
        [TUITool makeToast:TUIKitLocalizableString(delete_success)];
    } fail:^(int code, NSString *desc) {
        [TUITool makeToastError:code msg:desc];
    }];
}

#pragma mark TUIModifyViewDelegate

- (void)modifyView:(TUIModifyView *)modifyView didModiyContent:(NSString *)content
{
    @weakify(self)
    if(modifyView.tag == 0){
        [self.dataProvider setGroupName:content succ:^{
            @strongify(self)
            [self.tableView reloadData];
        } fail:^(int code, NSString *desc) {
        }];
    }
    else if(modifyView.tag == 1){
        [self.dataProvider setGroupNotification:content];
    }
    else if(modifyView.tag == 2){
        [self.dataProvider setGroupMemberNameCard:content];
    }
}

#pragma mark - TUICore
- (void)onNotifyEvent:(NSString *)key subKey:(NSString *)subKey object:(nullable id)anObject param:(NSDictionary *)param {
    if ([key isEqualToString:TUICore_TUIContactNotify]
        && [subKey isEqualToString:TUICore_TUIContactNotify_SelectedContactsSubKey]
        && anObject == self.showContactSelectVC) {

        NSArray<TUICommonContactSelectCellData *> *selectArray = [param tui_objectForKey:TUICore_TUIContactNotify_SelectedContactsSubKey_ListKey asClass:NSArray.class];
        if (![selectArray.firstObject isKindOfClass:TUICommonContactSelectCellData.class]) {
            NSAssert(NO, @"value type error");
        }
        
        if (self.tag == 1) {
            // add
            NSMutableArray *list = @[].mutableCopy;
            for (TUICommonContactSelectCellData *data in selectArray) {
                [list addObject:data.identifier];
            }
            [self.navigationController popToViewController:self animated:YES];
            [self addGroupId:_groupId memebers:list];
        } else if (self.tag == 2) {
            // delete
            NSMutableArray *list = @[].mutableCopy;
            for (TUICommonContactSelectCellData *data in selectArray) {
                [list addObject:data.identifier];
            }
            [self.navigationController popToViewController:self animated:YES];
            [self deleteGroupId:_groupId memebers:list];
        }
    }else if ([key isEqualToString:TUICore_TUIContactNotify]
              && [subKey isEqualToString:TUICore_TUIGroupNotify_SelectGroupMemberSubKey]
              && self.callingSelectGroupMemberVC == anObject) {
         
         NSArray<TUIUserModel *> *modelList = [param tui_objectForKey:TUICore_TUIGroupNotify_SelectGroupMemberSubKey_UserListKey asClass:NSArray.class];
         NSMutableArray *userIDs = [NSMutableArray arrayWithCapacity:modelList.count];
         for (TUIUserModel *user in modelList) {
             NSParameterAssert(user.userId);
             [userIDs addObject:user.userId];
         }
         
         // 显示通话VC
         NSDictionary *param = @{
             TUICore_TUICallingService_ShowCallingViewMethod_GroupIDKey : self.dataProvider.groupInfo.groupID,
             TUICore_TUICallingService_ShowCallingViewMethod_UserIDsKey : userIDs,
             TUICore_TUICallingService_ShowCallingViewMethod_CallTypeKey : self.callingType
         };
         [TUICore callService:TUICore_TUICallingService
                       method:TUICore_TUICallingService_ShowCallingViewMethod
                        param:param];
     }
}
@end

@interface IUGroupView_Minimalist : UIView
@property(nonatomic, strong) UIView *view;
@end

@implementation IUGroupView_Minimalist

- (instancetype)init {
    self = [super init];
    if (self) {
        self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        [self addSubview:self.view];
    }
    return self;
}
@end
