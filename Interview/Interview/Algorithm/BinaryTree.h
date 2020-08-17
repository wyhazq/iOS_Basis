//
//  BinaryTree.h
//  Interview
//
//  Created by 一鸿温 on 8/16/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import <Foundation/Foundation.h>

//NS_ASSUME_NONNULL_BEGIN

typedef struct TreeNode {
    struct TreeNode *left;
    struct TreeNode *right;
    int value;
} TreeNode;

TreeNode *treeNodeInit(int value);

TreeNode *binaryTreeInit(int value, int count);

void preOrderBinaryTree(TreeNode *root);
void inOrderBinaryTree(TreeNode *root);
void postOrderBinaryTree(TreeNode *root);
void layerOrderBinaryTree(TreeNode *root);

void mirrorBinaryTree(TreeNode *root);

void logArr(int arr[], int count);

void heapSort(int arr[], int count);

void topK(int arr[], int k, int count);

//@interface BinaryTree : NSObject
//
//@end

//NS_ASSUME_NONNULL_END
