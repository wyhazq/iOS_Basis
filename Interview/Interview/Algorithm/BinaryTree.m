//
//  BinaryTree.m
//  Interview
//
//  Created by 一鸿温 on 8/16/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import "BinaryTree.h"

TreeNode *treeNodeInit(int value) {
    TreeNode *node = (TreeNode *)malloc(sizeof(TreeNode));
    node->left = NULL;
    node->right = NULL;
    node->value = value;
    return node;
}

TreeNode *binaryTreeInit(int value, int count) {
    TreeNode *root;
    
    if (value < count) {
        root = treeNodeInit(value);
        root->left = binaryTreeInit(2 * value + 1, count);
        root->right = binaryTreeInit(2 * value + 2, count);
    }
    else {
        root = NULL;
    }
    
    return root;
}

void preOrderBinaryTree(TreeNode *root) {
    if (root == NULL) {
        return;
    }
    printf("\n%d", root->value);
    preOrderBinaryTree(root->left);
    preOrderBinaryTree(root->right);
}

void inOrderBinaryTree(TreeNode *root) {
    if (root == NULL) {
        return;
    }
    preOrderBinaryTree(root->left);
    printf("\n%d", root->value);
    preOrderBinaryTree(root->right);
}

void postOrderBinaryTree(TreeNode *root) {
    if (root == NULL) {
        return;
    }
    preOrderBinaryTree(root->left);
    preOrderBinaryTree(root->right);
    printf("\n%d", root->value);
}

typedef struct LinkedQueueNode {
    TreeNode *treeNode;
    struct LinkedQueueNode *next;
} LinkedQueueNode;

typedef struct LinkedQueue {
    LinkedQueueNode *front;
    LinkedQueueNode *rear;
} LinkedQueue;

LinkedQueue *linkedQueueInit(void) {
    LinkedQueue *linkedQueue = (LinkedQueue *)malloc(sizeof(LinkedQueue));
    linkedQueue->front = linkedQueue->rear = (LinkedQueueNode *)malloc(sizeof(LinkedQueueNode));
    linkedQueue->front->next = NULL;
    return linkedQueue;
}

bool isQueueEmpty(LinkedQueue *linkedQueue) {
    return linkedQueue->front == linkedQueue->rear ? true : false;
}

void enqueue(LinkedQueue *linkedQueue, TreeNode *treeNode) {
    LinkedQueueNode *queueNode = (LinkedQueueNode *)malloc(sizeof(LinkedQueueNode));
    queueNode->treeNode = treeNode;
    queueNode->next = NULL;
    linkedQueue->rear->next = queueNode;
    linkedQueue->rear = queueNode;
}

LinkedQueueNode *dequeue(LinkedQueue *linkedQueue) {
    if (!isQueueEmpty(linkedQueue)) {
        LinkedQueueNode *dequeueNode = linkedQueue->front->next;
        linkedQueue->front->next = dequeueNode->next;
        //出队最后一个元素时，队尾=队头
        if (linkedQueue->rear == dequeueNode) {
            linkedQueue->rear = linkedQueue->front;
        }
        return dequeueNode;
    }
    return linkedQueue->front;
}

void layerOrderBinaryTree(TreeNode *root) {
    LinkedQueue *queue = linkedQueueInit();
    enqueue(queue, root);
    while (!isQueueEmpty(queue)) {
        LinkedQueueNode *dequeueNode = dequeue(queue);
        TreeNode *treeNode = dequeueNode->treeNode;
        printf("\n%d", treeNode->value);
        if (treeNode->left != NULL) {
            enqueue(queue, treeNode->left);
        }
        if (treeNode->right != NULL) {
            enqueue(queue, treeNode->right);
        }
        free(dequeueNode);
    }
}

void mirrorBinaryTree(TreeNode *root) {
    if (root == NULL) {
        return;
    }
    if (root->left == NULL && root->right == NULL) {
        return;
    }
    
    TreeNode *temp = root->left;
    root->left = root->right;
    root->right = temp;
    
    mirrorBinaryTree(root->left);
    mirrorBinaryTree(root->right);
}

void logArr(int arr[], int count) {
    for (int i = 0; i < count; i++) {
        printf("\n%d", arr[i]);
    }
}

void swap(int arr[], int left, int right) {
    int temp = arr[left];
    arr[left] = arr[right];
    arr[right] = temp;
}

int root(int child) {
    return (child - 1) / 2;
}

int left(int root) {
    return 2 * root + 1;
}

int right(int root) {
    return 2 * root + 2;
}

void maxHeap(int arr[], int count) {
    if (count < 2) {
        return;
    }
    //当前数量下构造最大堆
    for (int i = 1; i < count; i++) {
        for (int j = i; j > 0 && arr[root(j)] < arr[j]; j = root(j)) {
            swap(arr, root(j), j);
        }
    }
    
}

void heapSort(int arr[], int count) {
    do {
        maxHeap(arr, count);
        swap(arr, 0, count - 1); //最大数移动到最后
    } while (count-- > 2);
}


void minHeap(int arr[], int count) {
    for (int i = 1; i < count; i++) {
        for (int j = i; arr[root(j)] > arr[j]; j = root(j)) {
            swap(arr, root(j), j);
        }
    }
}

void adjustMinHeap(int arr[], int count) {
    int j = 0;
    while ((left(j) < count && arr[left(j)] < arr[j]) || (right(j) < count && arr[right(j)] < arr[j])) {
        if (arr[left(j)] < arr[right(j)]) {
            swap(arr, left(j), j);
            j = left(j);
        }
        else {
            swap(arr, right(j), j);
            j = right(j);
        }
    }
}

void topK(int arr[], int k, int count) {
    minHeap(arr, k);
    for (int i = k; i < count; i++) {
        if (arr[0] < arr[i]) {
            swap(arr, 0, i);
            adjustMinHeap(arr, k);
        }
    }
}

//@implementation BinaryTree
//
//@end
