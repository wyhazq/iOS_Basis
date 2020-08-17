//
//  Linkedlist.m
//  Interview
//
//  Created by 一鸿温 on 8/15/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import "Linkedlist.h"

ListNode *listNodeInit(int i) {
    ListNode *node = (ListNode *)malloc(sizeof(ListNode));
    node->next = NULL;
    node->value = i;
    return node;
}

ListNode *linkedlistInit(void) {
    ListNode *head = (ListNode *)malloc(sizeof(ListNode));
    
    ListNode *temp = head; //游标
    for (int i = 0; i < 10; i++) {
        ListNode* listNode = listNodeInit(i);
        temp->next = listNode;
        temp = listNode; //游标后移
    }
    
    return head;
}

void logLinkedList(ListNode *head) {
    ListNode *temp = head;
    temp = temp->next;
    while (temp != NULL) {
        printf("\n%d", temp->value);
        temp = temp->next;
    }
    printf("\n");
}

ListNode *addListNodeAtIndex(int i, ListNode *head, ListNode *listNode) {
    if (head == NULL) {
        return head;
    }
    ListNode *temp = head;
    while (i-- > 0) {
        temp = temp->next;
        if (temp == NULL) {
            return head;
        }
    }
    listNode->next = temp->next;
    temp->next = listNode;
    return head;
}

ListNode *delListNode(ListNode *head, ListNode *listNode) {
    if (head == NULL || listNode == NULL) {
        return head;
    }
    if (listNode->next == NULL) {
        ListNode *temp = head;
        while (temp->next != listNode) {
            temp = temp->next;
        }
        temp->next = NULL;
        free(listNode);
        listNode = NULL;
        return head;
    }
    listNode->value = listNode->next->value; //将next覆盖自己
    ListNode *cur = listNode->next;
    listNode->next = cur->next; //删除next
    free(cur);
    cur = NULL;
    
    return head;
}

ListNode *reverseLinkedList(ListNode *head) {
    if (head == NULL) {
        return head;
    }
    
    ListNode *pre = NULL;
    ListNode *cur = head->next;
    ListNode *suf = cur->next;
    
    while (suf != NULL) {
        cur->next = pre;
        pre = cur;
        cur = suf;
        suf = cur->next;
    }
    cur->next = pre;
    head->next = cur;
    
    return head;
}

/* 例：倒数第2
         *
 h 1 2 3 4 5
       p   s
 */
ListNode *delListNodeAtReverseIndex(ListNode *head, int i) {
    ListNode *pre = head;
    ListNode *suf = head;
    
    while (i-- > 0) {
        suf = suf->next;
    }
    
    while (suf->next != NULL) {
        suf = suf->next;
        pre = pre->next;
    }
    
    ListNode *cur = pre->next;
    pre->next = cur->next; //删除
    free(cur);
    cur = NULL;
    
    return head;
}

ListNode *midListNode(ListNode *head) {
    if (head == NULL) {
        return head;
    }
    
    ListNode *slow = head;
    ListNode *fast = head;
    while (fast != NULL && fast->next != NULL) {
        fast = fast->next->next;
        slow = slow->next;
    }
    return slow;
}

ListNode *delRepeatListNodeInSortLinkedList(ListNode *head) {
    if (head == NULL) {
        return head;
    }
    
    ListNode *pre = head;
    ListNode *suf = head->next;
        
    bool isRepeat = false;

    while (suf->next != NULL) {
        if (suf->value == suf->next->value) { //重复了
            ListNode *temp = suf;
            suf = suf->next;
            free(temp);
            temp = NULL;
            isRepeat = true;
        }
        else {
            if (isRepeat) {
                pre->next = suf; //重复切换到不重复的时候，需要将pre和suf链起来
                isRepeat = false;
            }
            pre = suf;
            suf = suf->next;
        }
    }
    if (isRepeat) {
        pre->next = suf; //最后的node重复
    }
    
    return head;
}

//@implementation Linkedlist
//
//@end
