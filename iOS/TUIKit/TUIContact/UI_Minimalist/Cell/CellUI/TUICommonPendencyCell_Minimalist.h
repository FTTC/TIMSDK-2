//
//  TCommonPendencyCell.h
//  TXIMSDK_TUIKit_iOS
//
//  Created by annidyfeng on 2019/5/7.
//

#import "TUICommonModel.h"
#import "TUICommonPendencyCellData_Minimalist.h"

NS_ASSUME_NONNULL_BEGIN

@interface TUICommonPendencyCell_Minimalist : TUICommonTableViewCell

@property UIImageView *avatarView;
@property UILabel *titleLabel;
@property UILabel *addSourceLabel;
@property UILabel *addWordingLabel;
@property UIButton *agreeButton;
@property UIButton *rejectButton;
@property UIStackView *stackView;

@property (nonatomic) TUICommonPendencyCellData_Minimalist *pendencyData;

- (void)fillWithData:(TUICommonPendencyCellData_Minimalist *)pendencyData;

@end

NS_ASSUME_NONNULL_END
