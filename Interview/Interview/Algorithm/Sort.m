//
//  Sort.m
//  Interview
//
//  Created by 一鸿温 on 8/17/20.
//  Copyright © 2020 wyh. All rights reserved.
//

#import "Sort.h"

int partition(int arr[], int left, int right) {
    int index = arr[left];
    
    while (left < right) {
        while (left < right && arr[right] > index) {
            right--;
        }
        arr[left] = arr[right];
        
        while (left < right && arr[left] < index) {
            left++;
        }
        arr[right] = arr[left];
    }
    arr[left] = index;
    
    return left;
}

void _quickSort(int arr[], int left, int right) {
    if (left < right) {
        int mid = partition(arr, left, right);
        _quickSort(arr, left, mid - 1);
        _quickSort(arr, mid + 1, right);
    }
}

void quickSort(int arr[], int count) {
    _quickSort(arr, 0, count - 1);
}

void merge(int *arr, int left, int right) {
    int mid = (left + right) / 2;
    int lLen = mid - left + 1;
    int rLen = right - mid;
    
    int lArr[lLen], rArr[rLen];
    
    memcpy(lArr, arr + left, sizeof(int) * lLen);
    memcpy(rArr, arr + mid + 1, sizeof(int) * rLen);
    
    int i = 0, j = 0;
    while (i < lLen && j < rLen) {
        arr[left++] = lArr[i] < rArr[j] ? lArr[i++] : rArr[j++];
    }
    
    while (i < lLen) {
        arr[left++] = lArr[i++];
    }
    
    while (j < rLen) {
        arr[left++] = rArr[j++];
    }
}

void _mergeSort(int *arr, int left, int right) {

    if (left < right) {
        int mid = (left + right) / 2;
        
        _mergeSort(arr, left, mid);
        _mergeSort(arr, mid + 1, right);
        merge(arr, left, right);
    }
    
}


/*
 *0
 5 ---- 3 --- 1 -- 2 --- 4 - 8 ---- 6 --- 9 -- 0 --- 7

 *1
 3 5 --- 1 -- 2 --- 4 - 6 8 --- 9 -- 0 --- 7

 *2
 1 3 5 -- 2 4 - 6 8 9 -- 0 7

 *3
 1 2 3 4 5 - 0 6 7 8 9

 *4
 0 1 2 3 4 5 6 7 8 9
 */
void mergeSort(int *arr, int count) {
    _mergeSort(arr, 0, count - 1);
}

void shellSort(int arr[], int count) {
    int increment = count / 2;
    int i, j, temp;
    
    for (; increment > 0; increment /= 2) {
        
        for (i = increment; i < count; i++) {
            temp = arr[i];
            
            for (j = i - increment; j >= 0 && temp < arr[j]; j -= increment) {
                arr[j + increment] = arr[j];
            }
            arr[j + increment] = temp;
        }
    }
}

//@implementation Sort
//
//@end
