//
//  TUIContactProfileCardCellData_Minimalist.m
//  TUIContact
//
//  Created by cologne on 2023/2/1.
//

#import "TUIContactProfileCardCellData_Minimalist.h"
#import "TUIDefine.h"
#import "TUIThemeManager.h"

@implementation TUIContactProfileCardCellData_Minimalist

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.avatarImage = DefaultAvatarImage;
    }
    return self;
}

- (CGFloat)heightOfWidth:(CGFloat)width
{
    return kScale390(86);
}


@end
