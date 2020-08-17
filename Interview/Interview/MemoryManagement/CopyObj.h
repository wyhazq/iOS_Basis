//
//  CopyObj.h
//  Interview
//
//  Created by 一鸿温 on 8/6/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CopyObj : NSObject <NSCopying, NSMutableCopying>

+ (instancetype)obj;

@end

NS_ASSUME_NONNULL_END
