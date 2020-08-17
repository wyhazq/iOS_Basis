//
//  NSObject+KVO.h
//  Interview
//
//  Created by 一鸿温 on 8/11/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (KVO)

- (void)kvo_keyPath:(NSString *)keyPath block:(void(^)(id newValue))block;

- (void)kvo_remove;

- (void)mykvo_keyPath:(NSString *)keyPath block:(void(^)(id newValue))block;

@end

NS_ASSUME_NONNULL_END
