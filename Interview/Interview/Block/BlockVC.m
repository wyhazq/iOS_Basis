//
//  BlockVC.m
//  Interview
//
//  Created by 一鸿温 on 8/7/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import "BlockVC.h"

@interface BlockVC ()

@property (nonatomic, weak) void(^stackBlock)(void);
@property (nonatomic, copy) void(^mallocBlock)(void);

@end

@implementation BlockVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.textLabel.text isEqualToString:@"1.Block类型"]) {
        int a;
        void(^block)(void) = [self blockType:^{
            a;
        }];
        NSLog(@"---%@", block);
    }
    else if ([cell.textLabel.text isEqualToString:@"2.__block"]) {
        [self blockModifier];
    }
}

int globalBlock1_a;
void(^globalBlock1)(void) = ^{globalBlock1_a;};

- (void(^)(void))blockType:(void(^)(void))stackBlock1 {
    int a;
    __weak void(^stackBlock)(void) = ^{a;};
    self.stackBlock = ^{a;};
    NSLog(@"%@", stackBlock);
    NSLog(@"%@", stackBlock1);
    NSLog(@"%@", self.stackBlock);
    
    void(^mallocBlock)(void) = ^{a;};
    self.mallocBlock = ^{a;};
    NSLog(@"%@", mallocBlock);
    NSLog(@"%@", self.mallocBlock);
    
    void(^globalBlock)(void) = ^{};
    NSLog(@"%@", globalBlock);
    NSLog(@"%@", globalBlock1);
    
    return stackBlock;
}

- (void)blockModifier {
    __block int a = 1;
    NSLog(@"init:%p", &a);
    void(^block)(void) = ^{
        a = 2;
        NSLog(@"block:%p", &a);
    };
    block();
    NSLog(@"end:%p", &a);
}



@end
