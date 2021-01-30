//
//  AYReadWriteLock.h
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2021/1/21.
//  Copyright © 2021年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <pthread.h>

@interface AYReadLock : NSObject

- (instancetype)initWithLock:(pthread_rwlock_t *)lock;

- (void)lock;

- (void)unlock;

@end

@interface AYWriteLock : NSObject

- (instancetype)initWithLock:(pthread_rwlock_t *)lock;

- (void)lock;

- (void)unlock;

@end

@interface AYReadWriteLock : NSObject

@property (nonatomic, strong) AYReadLock *readLock;

@property (nonatomic, strong) AYWriteLock *writeLock;

@end
