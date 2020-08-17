//
//  AlgorithmVC.m
//  Interview
//
//  Created by 一鸿温 on 8/15/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import "AlgorithmVC.h"

#import "Linkedlist.h"
#import "BinaryTree.h"
#import "Sort.h"

@interface AlgorithmVC ()

@end

@implementation AlgorithmVC
{
    ListNode * _head;
    TreeNode *_root;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSString *text = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
    NSLog(@"%@", text);
    if (indexPath.section == 0) {
        if ([text isEqualToString:@"1.linkedListInit"]) {
            _head = linkedlistInit();
            logLinkedList(_head);
        }
        else if ([text isEqualToString:@"2.addListNodeAtIndex"]) {
            ListNode *listNode = listNodeInit(9);
            _head = addListNodeAtIndex(9, _head, listNode);
            logLinkedList(_head);
        }
        else if ([text isEqualToString:@"3.O(1)delListNode"]) {
            ListNode *temp = _head;
            int i = 6;
            while (i-- > 0) {
                temp = temp->next;
            }
            //获取到第N个listNode
            _head = delListNode(_head, temp);
            logLinkedList(_head);
        }
        else if ([text isEqualToString:@"4.reverseListNode"]) {
            _head = reverseLinkedList(_head);
            logLinkedList(_head);
        }
        else if ([text isEqualToString:@"5.delListNodeAtReverse"]) {
            _head = delListNodeAtReverseIndex(_head, 3);
            logLinkedList(_head);
        }
        else if ([text isEqualToString:@"6.midListNode"]) {
            ListNode *mid = midListNode(_head);
            NSLog(@"%d", mid->value);
        }
        else if ([text isEqualToString:@"7.delRepeatListNode"]) {
            _head = delRepeatListNodeInSortLinkedList(_head);
            logLinkedList(_head);
        }
    }
    else if (indexPath.section == 1) {
        if ([text isEqualToString:@"1.binaryTreeInit"]) {
            _root = binaryTreeInit(0, 10);
        }
        else if ([text isEqualToString:@"2.preOrder"]) {
            preOrderBinaryTree(_root);
        }
        else if ([text isEqualToString:@"3.inOrder"]) {
            inOrderBinaryTree(_root);
        }
        else if ([text isEqualToString:@"4.postOrder"]) {
            postOrderBinaryTree(_root);
        }
        else if ([text isEqualToString:@"5.layerOrder"]) {
            layerOrderBinaryTree(_root);
        }
        else if ([text isEqualToString:@"6.mirrorBinaryTree"]) {
            mirrorBinaryTree(_root);
            layerOrderBinaryTree(_root);
        }
        else if ([text isEqualToString:@"7.heapSort"]) {
            int arr[] = { 5, 3, 1, 2, 4, 8, 6, 9, 0, 7 };
            int count = sizeof(arr) / sizeof(arr[0]);
            heapSort(arr, count);
            logArr(arr, count);
        }
        else if ([text isEqualToString:@"8.topK"]) {
            int arr[] = { 5, 3, 1, 2, 4, 8, 6, 9, 0, 7 };
            int count = sizeof(arr) / sizeof(arr[0]);
            topK(arr, 5, count);
            logArr(arr, 5);
        }
    }
    else if (indexPath.section == 2) {
        if ([text isEqualToString:@"1.quickSort"]) {
            int arr[] = { 5, 3, 1, 2, 4, 8, 6, 9, 0, 7 };
            int count = sizeof(arr) / sizeof(arr[0]);
            quickSort(arr, count);
            logArr(arr, count);
        }
        else if ([text isEqualToString:@"2.mergeSort"]) {
            int arr[] = { 5, 3, 1, 2, 4, 8, 6, 9, 0, 7 };
            int count = sizeof(arr) / sizeof(arr[0]);
            mergeSort(arr, count);
            logArr(arr, count);
        }
        else if ([text isEqualToString:@"3.shellSort"]) {
            int arr[] = { 5, 3, 1, 2, 4, 8, 6, 9, 0, 7 };
            int count = sizeof(arr) / sizeof(arr[0]);
            shellSort(arr, count);
            logArr(arr, count);
        }

    }
    
}



@end
