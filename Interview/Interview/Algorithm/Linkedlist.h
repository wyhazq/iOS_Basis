//
//  Linkedlist.h
//  Interview
//
//  Created by 一鸿温 on 8/15/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct ListNode {
    struct ListNode *next;
    int value;
} ListNode;

ListNode *listNodeInit(int i);

ListNode *linkedlistInit(void);

void logLinkedList(ListNode *head);

ListNode *addListNodeAtIndex(int i, ListNode *head, ListNode *listNode);

ListNode *delListNode(ListNode *head, ListNode *listNode);

ListNode *reverseLinkedList(ListNode *head);

ListNode *delListNodeAtReverseIndex(ListNode *head, int i);

ListNode *midListNode(ListNode *head);

ListNode *delRepeatListNodeInSortLinkedList(ListNode *head);


//@interface Linkedlist : NSObject
//
//@end

NS_ASSUME_NONNULL_END
