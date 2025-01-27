//
//  TContactsController.m
//  TUIKit
//
//  Created by annidyfeng on 2019/3/25.
//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "TUIContactController_Minimalist.h"
#import "TUIFindContactViewController_Minimalist.h"
#import "TUIFriendProfileController_Minimalist.h"
#import "TUIFriendRequestViewController_Minimalist.h"
#import "TUIUserProfileController_Minimalist.h"
#import "TUIBlackListController_Minimalist.h"
#import "TUINewFriendViewController_Minimalist.h"
#import "TUIGroupConversationListController_Minimalist.h"
#import "TUICommonContactCell_Minimalist.h"
#import "TUIContactActionCell_Minimalist.h"
#import "TUIThemeManager.h"
#import "TUIDefine.h"
#import "TUICore.h"
#import "ReactiveObjC.h"
#import "TUIContactFloatController.h"

#define kContactCellReuseId @"ContactCellReuseId"
#define kContactActionCellReuseId @"ContactActionCellReuseId"

@interface TUIContactController_Minimalist () <UITableViewDelegate, UITableViewDataSource, V2TIMFriendshipListener, TUIPopViewDelegate>
@property NSArray<TUIContactActionCellData_Minimalist *> *firstGroupData;
@end

@implementation TUIContactController_Minimalist

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    NSMutableArray *list = @[].mutableCopy;
    [list addObject:({
        TUIContactActionCellData_Minimalist *data = [[TUIContactActionCellData_Minimalist alloc] init];
        data.title = TUIKitLocalizableString(TUIKitContactsNewFriends);
        data.cselector = @selector(onAddNewFriend:);
        data;
    })];
    [list addObject:({
        TUIContactActionCellData_Minimalist *data = [[TUIContactActionCellData_Minimalist alloc] init];
        data.title = TUIKitLocalizableString(TUIKitContactsGroupChats);
        data.cselector = @selector(onGroupConversation:);
        data;
    })];
    [list addObject:({
        TUIContactActionCellData_Minimalist *data = [[TUIContactActionCellData_Minimalist alloc] init];
        data.title = TUIKitLocalizableString(TUIKitContactsBlackList);
        data.cselector = @selector(onBlackList:);
        data.needBottomLine = NO;
        data;
    })];
    self.firstGroupData = [NSArray arrayWithArray:list];
    
    [self setupNavigator];
    [self setupViews];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onFriendInfoChanged:) name:@"FriendInfoChangedNotification" object:nil];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)onFriendInfoChanged:(NSNotification *)notice
{
    [self.viewModel loadContacts];
}

- (void)setupNavigator {
    UIButton *moreButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [moreButton setImage:TUICoreDynamicImage(@"nav_more_img", [UIImage imageNamed:TUICoreImagePath(@"more")]) forState:UIControlStateNormal];
    [moreButton addTarget:self action:@selector(onRightItem:) forControlEvents:UIControlEventTouchUpInside];
    [moreButton.widthAnchor constraintEqualToConstant:24].active = YES;
    [moreButton.heightAnchor constraintEqualToConstant:24].active = YES;
    UIBarButtonItem *moreItem = [[UIBarButtonItem alloc] initWithCustomView:moreButton];
    self.navigationItem.rightBarButtonItem = moreItem;

    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.view.backgroundColor = TUICoreDynamicColor(@"", @"#FFFFFF");
}

- (void)setupViews {
    CGRect rect = self.view.bounds;
    if (![UINavigationBar appearance].isTranslucent && [[[UIDevice currentDevice] systemVersion] doubleValue]<15.0) {
        rect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height - TabBar_Height - NavBar_Height );
    }
    _tableView = [[UITableView alloc] initWithFrame:rect style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView setSectionIndexBackgroundColor:[UIColor clearColor]];
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, 8, 0);
    [_tableView setSectionIndexColor:[UIColor systemBlueColor]];
    [_tableView setBackgroundColor:self.view.backgroundColor];
    _tableView.delaysContentTouches = NO;
    if (@available(iOS 15.0, *)) {
        _tableView.sectionHeaderTopPadding = 0;
    }
    [self.view addSubview:_tableView];
    
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    [_tableView setTableFooterView:v];
    _tableView.separatorColor = [UIColor clearColor];
    _tableView.separatorInset = UIEdgeInsetsMake(0, 58, 0, 0);
    [_tableView registerClass:[TUICommonContactCell_Minimalist class] forCellReuseIdentifier:kContactCellReuseId];
    [_tableView registerClass:[TUIContactActionCell_Minimalist class] forCellReuseIdentifier:kContactActionCellReuseId];
    
    @weakify(self)
    [RACObserve(self.viewModel, isLoadFinished) subscribeNext:^(id finished) {
        @strongify(self)
        if ([(NSNumber *)finished boolValue]) {
            [self.tableView reloadData];
        }
    }];
    [RACObserve(self.viewModel, pendencyCnt) subscribeNext:^(NSNumber *x) {
        @strongify(self)
        self.firstGroupData[0].readNum = [x integerValue];
    }];
}

- (void)onRightItem:(UIButton *)rightBarButton;
{
    NSMutableArray *menus = [NSMutableArray array];
    TUIPopCellData *friend = [[TUIPopCellData alloc] init];
    friend.image =
    TUIContactDynamicImage(@"pop_icon_add_friend_img", [UIImage imageNamed:TUIContactImagePath(@"add_friend")]);
    friend.title = TUIKitLocalizableString(ContactsAddFriends); //@"添加好友";
    [menus addObject:friend];

    TUIPopCellData *group = [[TUIPopCellData alloc] init];
    group.image =
    TUIContactDynamicImage(@"pop_icon_add_group_img", [UIImage imageNamed:TUIContactImagePath(@"add_group")]);

    group.title = TUIKitLocalizableString(ContactsJoinGroup);//@"添加群组";
    [menus addObject:group];

    CGFloat height = [TUIPopCell getHeight] * menus.count + TUIPopView_Arrow_Size.height;
    CGFloat orginY = StatusBar_Height + NavBar_Height;
    TUIPopView *popView = [[TUIPopView alloc] initWithFrame:CGRectMake(Screen_Width - 140, orginY, 130, height)];
    CGRect frameInNaviView = [self.navigationController.view convertRect:rightBarButton.frame fromView:rightBarButton.superview];
    popView.arrowPoint = CGPointMake(frameInNaviView.origin.x + frameInNaviView.size.width * 0.5, orginY);
    popView.delegate = self;
    [popView setData:menus];
    [popView showInWindow:self.view.window];
}

- (void)popView:(TUIPopView *)popView didSelectRowAtIndex:(NSInteger)index
{
    if (index == 0) {
        [self addToContacts];
    } else {
        [self addGroups];
    }
}

- (void)addToContacts {
    TUIFindContactViewController_Minimalist *add = [[TUIFindContactViewController_Minimalist alloc] init];
    add.type = TUIFindContactTypeC2C_Minimalist;
    @weakify(self)
    add.onSelect = ^(TUIFindContactCellModel_Minimalist * cellModel) {
        @strongify(self)
        [self dismissViewControllerAnimated:NO completion:^{
            TUIFriendRequestViewController_Minimalist *frc = [[TUIFriendRequestViewController_Minimalist alloc] init];
            frc.profile = cellModel.userInfo;
            
            TUIContactFloatController *bfloatVC = [[TUIContactFloatController alloc] init];
            [bfloatVC appendChildViewController:(id)frc topMargin:kScale390(87.5)];
            [bfloatVC.topGestureView setTitleText:TUIKitLocalizableString(Info) subTitleText:@"" leftBtnText:TUIKitLocalizableString(TUIKitCreateCancel) rightBtnText:@""];
            bfloatVC.topGestureView.rightButton.hidden = YES;
            bfloatVC.topGestureView.subTitleLabel.hidden = YES;
            [self presentViewController:bfloatVC animated:YES completion:nil];
            bfloatVC.topGestureView.leftButtonClickCallback = ^{
                [self dismissViewControllerAnimated:YES completion:^{}];
            };
        }];

    };
        
    TUIContactFloatController *floatVC = [[TUIContactFloatController alloc] init];
    [floatVC appendChildViewController:(id)add topMargin:kScale390(87.5)];
    [floatVC.topGestureView setTitleText:TUIKitLocalizableString(TUIKitAddFriend) subTitleText:@"" leftBtnText:TUIKitLocalizableString(TUIKitCreateCancel) rightBtnText:@""];
    floatVC.topGestureView.rightButton.hidden = YES;
    floatVC.topGestureView.subTitleLabel.hidden = YES;
    floatVC.topGestureView.leftButtonClickCallback = ^{
        [self dismissViewControllerAnimated:YES completion:^{}];
    };
    [self presentViewController:floatVC animated:YES completion:nil];
}

- (void)addGroups {
    TUIFindContactViewController_Minimalist *add = [[TUIFindContactViewController_Minimalist alloc] init];
    add.type = TUIFindContactTypeGroup_Minimalist;
    @weakify(self)
    add.onSelect = ^(TUIFindContactCellModel_Minimalist * cellModel) {
        @strongify(self)
        
        [self dismissViewControllerAnimated:YES completion:^{
            
            NSDictionary *param = @{
                TUICore_TUIGroupService_GetGroupRequestViewControllerMethod_GroupInfoKey: cellModel.groupInfo
            };
            UIViewController *vc = [TUICore callService:TUICore_TUIGroupService_Minimalist
                                                 method:TUICore_TUIGroupService_GetGroupRequestViewControllerMethod
                                                  param:param];
            
            TUIContactFloatController *bfloatVC = [[TUIContactFloatController alloc] init];
            [bfloatVC appendChildViewController:(id)vc topMargin:kScale390(87.5)];
            [bfloatVC.topGestureView setTitleText:TUIKitLocalizableString(Info) subTitleText:@"" leftBtnText:TUIKitLocalizableString(TUIKitCreateCancel) rightBtnText:@""];
            bfloatVC.topGestureView.rightButton.hidden = YES;
            bfloatVC.topGestureView.subTitleLabel.hidden = YES;
            [self presentViewController:bfloatVC animated:YES completion:nil];
            bfloatVC.topGestureView.leftButtonClickCallback = ^{
                [self dismissViewControllerAnimated:YES completion:^{}];
            };
            
        }];
    };
    
    TUIContactFloatController *floatVC = [[TUIContactFloatController alloc] init];
    [floatVC appendChildViewController:(id)add topMargin:kScale390(87.5)];
    [floatVC.topGestureView setTitleText:TUIKitLocalizableString(TUIKitAddGroup) subTitleText:@"" leftBtnText:TUIKitLocalizableString(TUIKitCreateCancel) rightBtnText:@""];
    floatVC.topGestureView.rightButton.hidden = YES;
    floatVC.topGestureView.subTitleLabel.hidden = YES;
    floatVC.topGestureView.leftButtonClickCallback = ^{
        [self dismissViewControllerAnimated:YES completion:^{}];
    };
    [self presentViewController:floatVC animated:YES completion:nil];
}

- (TUIContactViewDataProvider_Minimalist *)viewModel
{
    if (_viewModel == nil) {
        _viewModel = [TUIContactViewDataProvider_Minimalist new];
        [_viewModel loadContacts];
    }
    return _viewModel;
}

- (void)onFriendListChanged {
    [_viewModel loadContacts];
}

- (void)onFriendApplicationListChanged {
    [_viewModel loadFriendApplication];
}

#pragma mark - UITableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
    return self.viewModel.groupList.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.firstGroupData.count;
    } else {
        NSString *group = self.viewModel.groupList[section-1];
        NSArray *list = self.viewModel.dataDict[group];
        return list.count;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return nil;

#define TEXT_TAG 1
    static NSString *headerViewId = @"ContactDrawerView";
    UITableViewHeaderFooterView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerViewId];
    if (!headerView)
    {
        headerView = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:headerViewId];
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        textLabel.tag = TEXT_TAG;
        textLabel.font = [UIFont systemFontOfSize:16];
        textLabel.textColor = [UIColor tui_colorWithHex:@"#000000"];
        [headerView addSubview:textLabel];
        textLabel.mm_fill().mm_left(12);
        textLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    UILabel *label = [headerView viewWithTag:TEXT_TAG];
    label.text = self.viewModel.groupList[section-1];
    headerView.backgroundColor = [UIColor whiteColor];
    headerView.contentView.backgroundColor = [UIColor whiteColor];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return kScale390(52);
    }
    return kScale390(52);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return 0;

    return 33;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    NSMutableArray *array = [NSMutableArray arrayWithObject:@""];
    [array addObjectsFromArray:self.viewModel.groupList];
    return array;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        TUIContactActionCell_Minimalist *cell = [tableView dequeueReusableCellWithIdentifier:kContactActionCellReuseId forIndexPath:indexPath];
        [cell fillWithData:self.firstGroupData[indexPath.row]];
        cell.changeColorWhenTouched = YES;
        return cell;
    } else {
        TUICommonContactCell_Minimalist *cell = [tableView dequeueReusableCellWithIdentifier:kContactCellReuseId forIndexPath:indexPath];
        NSString *group = self.viewModel.groupList[indexPath.section-1];
        NSArray *list = self.viewModel.dataDict[group];
        TUICommonContactCellData_Minimalist *data = list[indexPath.row];
        data.cselector = @selector(onSelectFriend:);
        [cell fillWithData:data];
        cell.changeColorWhenTouched = YES;
        cell.separtorView.hidden = YES;
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

}

#pragma mark -
- (void)onSelectFriend:(TUICommonContactCell_Minimalist *)cell
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onSelectFriend:)]) {
        [self.delegate onSelectFriend:cell];
        return;
    }
    TUICommonContactCellData_Minimalist *data = cell.contactData;
    TUIFriendProfileController_Minimalist *vc = [[TUIFriendProfileController_Minimalist alloc] init];
    vc.friendProfile = data.friendProfile;
    [self.navigationController pushViewController:(UIViewController *)vc animated:YES];
}

- (void)onAddNewFriend:(TUICommonTableViewCell *)cell
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onAddNewFriend:)]) {
        [self.delegate onAddNewFriend:cell];
        return;
    }
    TUINewFriendViewController_Minimalist *vc = TUINewFriendViewController_Minimalist.new;
    vc.cellClickBlock = ^(TUICommonPendencyCell_Minimalist * _Nonnull cell) {
        TUIUserProfileController_Minimalist *controller = [[TUIUserProfileController_Minimalist alloc] init];
        [[V2TIMManager sharedInstance] getUsersInfo:@[cell.pendencyData.identifier] succ:^(NSArray<V2TIMUserFullInfo *> *profiles) {
            controller.userFullInfo = profiles.firstObject;
            controller.pendency = cell.pendencyData;
            controller.actionType = PCA_PENDENDY_CONFIRM_MINI;
            [self.navigationController pushViewController:(UIViewController *)controller animated:YES];
        } fail:nil];
    };
    [self.navigationController pushViewController:vc animated:YES];
    [self.viewModel clearApplicationCnt];
}

- (void)onGroupConversation:(TUICommonTableViewCell *)cell
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onGroupConversation:)]) {
        [self.delegate onGroupConversation:cell];
        return;
    }
    TUIGroupConversationListController_Minimalist *vc = TUIGroupConversationListController_Minimalist.new;
    @weakify(self)
    vc.onSelect = ^(TUICommonContactCellData_Minimalist * _Nonnull cellData) {
        @strongify(self)
        
        NSDictionary *param = @{
            TUICore_TUIChatService_GetChatViewControllerMethod_GroupIDKey : cellData.identifier ?: @"",
            TUICore_TUIChatService_GetChatViewControllerMethod_TitleKey:cellData.title?:@"",
            TUICore_TUIChatService_GetChatViewControllerMethod_AvatarImageKey:cellData.avatarImage,
            TUICore_TUIChatService_GetChatViewControllerMethod_AvatarUrlKey:[cellData.avatarUrl absoluteString]?:@"",
        };
        
        UIViewController *chatVC = (UIViewController *)[TUICore callService:TUICore_TUIChatService_Minimalist
                                                                     method:TUICore_TUIChatService_GetChatViewControllerMethod
                                                                      param:param];
        [self.navigationController pushViewController:(UIViewController *)chatVC animated:YES];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onBlackList:(TUICommonContactCell_Minimalist *)cell
{
    TUIBlackListController_Minimalist *vc = TUIBlackListController_Minimalist.new;
    @weakify(self);
    vc.didSelectCellBlock = ^(TUICommonContactCell_Minimalist * _Nonnull cell) {
        @strongify(self);
        [self onSelectFriend:cell];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)runSelector:(SEL)selector withObject:(id)object{
    if([self respondsToSelector:selector]){
        IMP imp = [self methodForSelector:selector];
        void (*func)(id, SEL, id) = (void *)imp;
        func(self, selector, object);
    }

}

@end

@interface IUContactView_Minimalist : UIView
@property(nonatomic, strong) UIView *view;
@end

@implementation IUContactView_Minimalist

- (instancetype)init {
    self = [super init];
    if (self) {
        self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        [self addSubview:self.view];
    }
    return self;
}
@end
