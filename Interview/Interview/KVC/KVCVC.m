//
//  KVCVC.m
//  Interview
//
//  Created by 一鸿温 on 8/13/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import "KVCVC.h"

#import <objc/runtime.h>

@interface KVCVC ()
{
    NSString *_key;     //ivar:1
    NSString *_isKey;   //ivar:2
    NSString *key;      //ivar:3
    NSString *isKey;    //ivar:4
}

@end

@implementation KVCVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
     
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.textLabel.text isEqualToString:@"1.setter"]) {
        [self setValue:@"aaa" forKey:@"key"];
        NSLog(@"3.\n_key:%@", _key);
        NSLog(@"4.\n_isKey:%@", _isKey);
        NSLog(@"5.\nkey:%@", key);
        NSLog(@"6.\nisKey:%@", isKey);
    }
    else if ([cell.textLabel.text isEqualToString:@"2.getter"]) {
        _key = @"_key";
        _isKey = @"_isKey";
        key = @"key";
        isKey = @"isKey";
        NSLog(@"%@", [self valueForKey:@"key"]);
    }
}

//setter:1
- (void)setKey:(NSString *)akey {
    _key = akey;
    NSLog(@"1.\n%@%@", NSStringFromSelector(_cmd), akey);
}

//setter:2
- (void)_setKey:(NSString *)akey {
    _key = akey;
    NSLog(@"2.\n%@%@", NSStringFromSelector(_cmd), akey);
}

//getter:1
- (NSString *)getKey {
    NSLog(@"\n%@:%@", NSStringFromSelector(_cmd), _key);
    return _key;
}

//getter:2
- (NSString *)key {
    NSLog(@"\n%@:%@", NSStringFromSelector(_cmd), _key);
    return _key;
}

//getter:3
- (NSString *)isKey {
    NSLog(@"\n%@:%@", NSStringFromSelector(_cmd), _key);
    return _key;
}

//getter:4
- (NSString *)_key {
    NSLog(@"\n%@:%@", NSStringFromSelector(_cmd), _key);
    return _key;
}



@end
