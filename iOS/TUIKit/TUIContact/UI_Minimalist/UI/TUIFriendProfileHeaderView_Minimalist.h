//
//  TUIFriendProfileHeaderView_Minimalist.h
//  TUIContact
//
//  Created by wyl on 2022/12/14.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface TUIFriendProfileHeaderItemView : UIView
@property (nonatomic, strong) UIImageView * iconView;
@property (nonatomic, strong) UILabel * textLabel;
@property (nonatomic, copy) void(^messageBtnClickBlock)(void);
@end

@interface TUIFriendProfileHeaderView_Minimalist : UIView
@property (nonatomic, strong) UIImageView *headImg;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) TUIFriendProfileHeaderItemView * itemMessage;
@property (nonatomic, strong) TUIFriendProfileHeaderItemView * itemAudio;
@property (nonatomic, strong) TUIFriendProfileHeaderItemView * itemVideo;

@end

NS_ASSUME_NONNULL_END
