//
//  AYReadWriteLock.m
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2021/1/21.
//  Copyright © 2021年 深圳市哎吖科技有限公司. All rights reserved.
//
#import "AYReadWriteLock.h"
#import <pthread.h>

@interface AYReadWriteLock () {
    pthread_rwlock_t rwlock;
}

@end

@implementation AYReadWriteLock

- (instancetype)init {
    self = [super init];
    if (self) {
        pthread_rwlock_init(&rwlock, NULL);
        _readLock = [[AYReadLock alloc] initWithLock:&rwlock];
        _writeLock = [[AYWriteLock alloc] initWithLock:&rwlock];
    }
    return self;
}

- (AYReadLock *)readLock {
    return _readLock;
}

- (AYWriteLock *)writeLock {
    return _writeLock;
}

@end

@interface AYReadLock () {
    pthread_rwlock_t *rwlock;
}

@end

@implementation AYReadLock

- (instancetype)initWithLock:(pthread_rwlock_t *)lock
{
    self = [super init];
    if (self) {
        rwlock = lock;
    }
    return self;
}

- (void)lock {
    pthread_rwlock_rdlock(self->rwlock);
}

- (void)unlock {
    pthread_rwlock_unlock(self->rwlock);
}

@end

@interface AYWriteLock () {
    pthread_rwlock_t *rwlock;
}

@end

@implementation AYWriteLock

- (instancetype)initWithLock:(pthread_rwlock_t *)lock
{
    self = [super init];
    if (self) {
        rwlock = lock;
    }
    return self;
}

- (void)lock {
    pthread_rwlock_wrlock(self->rwlock);
}

- (void)unlock {
    pthread_rwlock_unlock(self->rwlock);
}

@end
