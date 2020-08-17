//
//  KVOVC.m
//  Interview
//
//  Created by 一鸿温 on 8/11/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import "KVOVC.h"
#import "NSObject+KVO.h"

@interface TestKVO : NSObject
@property (nonatomic, copy) NSString *kvoKey0;
@property (nonatomic, copy) NSString *kvoKey1;
@property (nonatomic, copy) NSString *kvoKey2;

@end

@implementation TestKVO

@end

@interface KVOVC ()

@property (nonatomic, strong) TestKVO *testKVO;


@end

@implementation KVOVC

- (void)dealloc {
    [self.testKVO kvo_remove];
    [self.testKVO removeObserver:self forKeyPath:@"kvoKey0"];

    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _testKVO = [[TestKVO alloc] init];

    [self.testKVO addObserver:self forKeyPath:@"kvoKey0" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.textLabel.text isEqualToString:@"1.KVO"]) {
        [self.testKVO addObserver:self forKeyPath:@"kvoKey0" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
        self.testKVO.kvoKey0 = cell.textLabel.text;
    }
    else if ([cell.textLabel.text isEqualToString:@"2.ManualTriggerKVO"]) {
        [self.testKVO willChangeValueForKey:@"kvoKey0"];
        [self.testKVO didChangeValueForKey:@"kvoKey0"];
    }
    else if ([cell.textLabel.text isEqualToString:@"3.PackageKVO"]) {
        [self.testKVO kvo_keyPath:@"kvoKey1" block:^(id  _Nonnull newValue) {
            NSLog(@"kvoKey1:%@", newValue);
        }];
        self.testKVO.kvoKey1 = cell.textLabel.text;
    }
    else if ([cell.textLabel.text isEqualToString:@"4.MyKVO"]) {
        [self.testKVO mykvo_keyPath:@"kvoKey2" block:^(id  _Nonnull newValue) {
            NSLog(@"kvoKey2:%@", newValue);
        }];
        self.testKVO.kvoKey2 = cell.textLabel.text;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"kvoKey0"]) {
        NSLog(@"kvoKey0:%@", change[NSKeyValueChangeNewKey]);
    }
}

@end
