//
//  IAThreadSafeContext.m
//
//  Created by Adam Roth on 14/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import "IAThreadSafeContext.h"

@implementation IAThreadSafeContext

//XXX:  the following methods are not remapped to the originating thread
//          concurrencyType
//          mergePolicy
//          parentContext
//          persistentStoreCoordinator
//          propagatesDeletesAtEndOfEvent
//          retainsRegisteredObjects
//          setStalenessInterval
//          undoManager
//          userInfo


//constructors
- (id) init {
    if (self = [super init]) {
        myThread = [NSThread currentThread];
    }
    
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        myThread = [NSThread currentThread];
    }
    
    return self;
}

- (id) initWithConcurrencyType:(NSManagedObjectContextConcurrencyType)ct {
    if (self = [super initWithConcurrencyType:ct]) {
        myThread = [NSThread currentThread];
    }
    
    return self;
}

//utilities/extensions
- (NSInvocation*) invocationWithSelector:(SEL)selector {
    NSMethodSignature* sig = [self methodSignatureForSelector:selector];    
    NSInvocation* call = [NSInvocation invocationWithMethodSignature:sig];
    [call retainArguments];
    call.target = self;
    
    call.selector = selector;
    
    return call;
}

- (NSInvocation*) invocationWithSelector:(SEL)selector andArg:(id)arg1 {
    NSInvocation* call = [self invocationWithSelector:selector];
    [call setArgument:&arg1 atIndex:2];
    
    return call;
}

- (NSInvocation*) invocationWithSelector:(SEL)selector andArg:(id)arg1 andArg: (id)arg2 {
    NSInvocation* call = [self invocationWithSelector:selector andArg:arg1];
    [call setArgument:&arg2 atIndex:3];
    
    return call;
}

- (void) runInvocationOnContextThread:(NSInvocation*)invocation {
    NSThread* currentThread = [NSThread currentThread];
    if (currentThread != myThread) {
        //call over to the correct thread
        [self performSelector:@selector(runInvocationOnContextThread:) onThread:myThread withObject:invocation waitUntilDone:YES];
    }
    else {
        //we're okay to invoke the target now
        [invocation invoke];
    }
}

- (void) runInvocationIgnoringResult:(NSInvocation*) call {
    //ignores return value
    [self runInvocationOnContextThread:call];
}

- (void*) runInvocation:(NSInvocation*) call {
    //returns primitive types only
    void* lastResult = NULL;
    NSUInteger length = [[call methodSignature] methodReturnLength];
    
    if (length > 0) {
        //only malloc if we have a non-zero size
        lastResult = (void*)malloc(length);
    }
    [self runInvocationOnContextThread:call];
    if (length <= 0) {
        //if there's nothing to return, just return NULL
        return NULL;
    }
    
    
    [call getReturnValue:lastResult];
    
    //now copy off the result (the next operation on this context will overwrite it)
    void* result = lastResult;
    free((void*)lastResult);
    return result;
}

- (id) runInvocationReturningObject:(NSInvocation*) call {
    //returns object types only
    [self runInvocationOnContextThread:call];
    
    //now copy off the result (the next operation on this context will overwrite it)
    __unsafe_unretained id result = nil;
    [call getReturnValue:&result];
    
    return result;
}

//NSManagedObject API
- (NSArray*) executeFetchRequest:(NSFetchRequest *)request error:(NSError *__autoreleasing *)error {
    if ([NSThread currentThread] == myThread) {
        return [super executeFetchRequest:request error:error];
    }
    
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(executeFetchRequest:error:) andArg:request];
        [call setArgument:&error atIndex:3];
        return [self runInvocationReturningObject:call];
    }
}

- (NSUInteger) countForFetchRequest:(NSFetchRequest *)request error:(NSError *__autoreleasing *)error {
    if ([NSThread currentThread] == myThread) {
        return [super countForFetchRequest:request error:error];
    }
    
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(countForFetchRequest:error:) andArg:request];
        [call setArgument:&error atIndex:3];
        return (NSUInteger)[self runInvocation:call];
    }
}

- (NSManagedObject*) objectRegisteredForID:(NSManagedObjectID *)objectID {
    if ([NSThread currentThread] == myThread) {
        return [super objectRegisteredForID:objectID];
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(objectRegisteredForID:) andArg:objectID];
        return [self runInvocationReturningObject:call];
    }
}

- (NSManagedObject*) objectWithID:(NSManagedObjectID *)objectID {
    if ([NSThread currentThread] == myThread) {
        return [super objectWithID:objectID];
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(objectWithID:) andArg:objectID];
        return [self runInvocationReturningObject:call];
    }
}

- (NSManagedObject*)existingObjectWithID:(NSManagedObjectID *)objectID error:(NSError *__autoreleasing *)error {
    if ([NSThread currentThread] == myThread) {
        return [super existingObjectWithID:objectID error:error];
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(existingObjectWithID:error:) andArg:objectID];
        [call setArgument:&error atIndex:3];
        return [self runInvocationReturningObject:call];
    }
}

- (NSSet*)registeredObjects {
    if ([NSThread currentThread] == myThread) {
        return [super registeredObjects];
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(registeredObjects)];
        return [self runInvocationReturningObject:call];
    }
}

- (void) assignObject:(id)object toPersistentStore:(NSPersistentStore *)store {
    if ([NSThread currentThread] == myThread) {
        [super assignObject:object toPersistentStore:store];
        return;
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(assignObject:toPersistentStore:) andArg:object andArg:store];
        [self runInvocationIgnoringResult:call];
    }
}

- (NSSet*) deletedObjects {
    if ([NSThread currentThread] == myThread) {
        return [super deletedObjects];
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(deletedObjects)];
        return [self runInvocationReturningObject:call];
    }
}

- (void) deleteObject:(NSManagedObject *)object {
    if ([NSThread currentThread] == myThread) {
        [super deleteObject:object];
        return;
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(deleteObject:) andArg:object];
        [self runInvocationIgnoringResult:call];
    }
}

- (void) detectConflictsForObject:(NSManagedObject *)object {
    if ([NSThread currentThread] == myThread) {
        [super detectConflictsForObject:object];
        return;
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(detectConflictsForObject:) andArg:object];
        [self runInvocationIgnoringResult:call];
    }
}

- (NSSet*) insertedObjects {
    if ([NSThread currentThread] == myThread) {
        return [super insertedObjects];
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(insertedObjects)];
        return [self runInvocationReturningObject:call];
    }
}

- (void) insertObject:(NSManagedObject *)object {
    if ([NSThread currentThread] == myThread) {
        [super insertObject:object];
        return;
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(insertObject:) andArg:object];
        [self runInvocationIgnoringResult:call];
    }
}

- (void) mergeChangesFromContextDidSaveNotification:(NSNotification *)notification {
    if ([NSThread currentThread] == myThread) {
        [super mergeChangesFromContextDidSaveNotification:notification];
        return;
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(mergeChangesFromContextDidSaveNotification:) andArg:notification];
        [self runInvocationIgnoringResult:call];
    }
}

- (BOOL) obtainPermanentIDsForObjects:(NSArray *)objects error:(NSError *__autoreleasing *)error {
    if ([NSThread currentThread] == myThread) {
        return [super obtainPermanentIDsForObjects:objects error:error];
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(obtainPermanentIDsForObjects:error:) andArg:objects];
        [call setArgument:&error atIndex:3];
        return (BOOL)[self runInvocation:call];
    }
}

- (void) performBlock:(void (^)())block {
    if ([NSThread currentThread] == myThread) {
        [super performBlock:block];
        return;
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(performBlock:) andArg:block];
        [self runInvocationIgnoringResult:call];
    }
}

- (void) performBlockAndWait:(void (^)())block {
    if ([NSThread currentThread] == myThread) {
        [super performBlockAndWait:block];
        return;
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(performBlockAndWait:) andArg:block];
        [self runInvocationIgnoringResult:call];
    }
}

- (void) processPendingChanges {
    if ([NSThread currentThread] == myThread) {
        [super processPendingChanges];
        return;
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(processPendingChanges)];
        [self runInvocationIgnoringResult:call];
    }
}

- (void) redo {
    if ([NSThread currentThread] == myThread) {
        [super redo];
        return;
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(redo)];
        [self runInvocationIgnoringResult:call];
    }
}

- (void) refreshObject:(NSManagedObject *)object mergeChanges:(BOOL)flag {
    if ([NSThread currentThread] == myThread) {
        [super refreshObject:object mergeChanges:flag];
        return;
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(refreshObject:mergeChanges:) andArg:object];
        [call setArgument:&flag atIndex:3];
        [self runInvocationIgnoringResult:call];
    }
}

- (void) reset {
    if ([NSThread currentThread] == myThread) {
        [super reset];
        return;
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(reset)];
        [self runInvocationIgnoringResult:call];
    }
}

- (void) rollback {
    if ([NSThread currentThread] == myThread) {
        [super rollback];
        return;
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(rollback)];
        [self runInvocationIgnoringResult:call];
    }
}

- (BOOL)save:(NSError *__autoreleasing *)error {
    if ([NSThread currentThread] == myThread) {
        return [super save:error];
    }
    @synchronized(self) {
        NSInvocation* call = [self invocationWithSelector:@selector(save:)];
        [call setArgument:&error atIndex:2];
        return (BOOL)[self runInvocation:call];
    }
}

- (void) setMergePolicy:(id)mergePolicy {
    if ([NSThread currentThread] == myThread) {
        [super setMergePolicy:mergePolicy];
        return;
    }
    @synchronized(self) {
        NSInvocation* call = [self invocationWithSelector:@selector(setMergePolicy:) andArg:mergePolicy];
        [self runInvocationIgnoringResult:call];
    }
}

- (void) setParentContext:(NSManagedObjectContext *)parent {
    if ([NSThread currentThread] == myThread) {
        [super setParentContext:parent];
        return;
    }
    @synchronized(self) {
        NSInvocation* call = [self invocationWithSelector:@selector(setParentContext:) andArg:parent];
        [self runInvocationIgnoringResult:call];
    }
}

- (void) setPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator {
    if ([NSThread currentThread] == myThread) {
        [super setPersistentStoreCoordinator:coordinator];
        return;
    }
    @synchronized(self) {
        NSInvocation* call = [self invocationWithSelector:@selector(setPersistentStoreCoordinator:) andArg:coordinator];
        [self runInvocationIgnoringResult:call];
    }
}

- (void) setPropagatesDeletesAtEndOfEvent:(BOOL)flag {
    if ([NSThread currentThread] == myThread) {
        [super setPropagatesDeletesAtEndOfEvent:flag];
        return;
    }
    @synchronized(self) {
        NSInvocation* call = [self invocationWithSelector:@selector(setPropagatesDeletesAtEndOfEvent:)];
        [call setArgument:&flag atIndex:2];
        [self runInvocationIgnoringResult:call];
    }
}

- (void) setRetainsRegisteredObjects:(BOOL)flag {
    if ([NSThread currentThread] == myThread) {
        [super setRetainsRegisteredObjects:flag];
        return;
    }
    @synchronized(self) {
        NSInvocation* call = [self invocationWithSelector:@selector(setRetainsRegisteredObjects:)];
        [call setArgument:&flag atIndex:2];
        [self runInvocationIgnoringResult:call];
    }
}

- (void) setStalenessInterval:(NSTimeInterval)expiration {
    if ([NSThread currentThread] == myThread) {
        [super setStalenessInterval:expiration];
        return;
    }
    @synchronized(self) {
        NSInvocation* call = [self invocationWithSelector:@selector(setStalenessInterval:)];
        [call setArgument:&expiration atIndex:2];
        [self runInvocationIgnoringResult:call];
    }
}

- (void) setUndoManager:(NSUndoManager *)undoManager {
    if ([NSThread currentThread] == myThread) {
        [super setUndoManager:undoManager];
        return;
    }
    @synchronized(self) {
        NSInvocation* call = [self invocationWithSelector:@selector(setUndoManager:) andArg:undoManager];
        [self runInvocationIgnoringResult:call];
    }
}

- (void) undo {
    if ([NSThread currentThread] == myThread) {
        [super undo];
        return;
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(undo)];
        [self runInvocationIgnoringResult:call];
    }
}

- (NSSet*) updatedObjects {
    if ([NSThread currentThread] == myThread) {
        return [super updatedObjects];
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(updatedObjects)];
        return [self runInvocationReturningObject:call];
    }
}

- (void) lock {
    if ([NSThread currentThread] == myThread) {
        [super lock];
        return;
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(lock)];
        [self runInvocationIgnoringResult:call];
    }
}

- (void) unlock {
    if ([NSThread currentThread] == myThread) {
        [super unlock];
        return;
    }
    @synchronized(self) {
        //execute the call on the correct thread for this context
        NSInvocation* call = [self invocationWithSelector:@selector(unlock)];
        [self runInvocationIgnoringResult:call];
    }
}

- (BOOL)tryLock {
    if ([NSThread currentThread] == myThread) {
        return [super tryLock];
    }
    @synchronized(self) {
        NSInvocation* call = [self invocationWithSelector:@selector(tryLock)];
        return (BOOL)[self runInvocation:call];
    }
}

- (BOOL) hasChanges {
    if ([NSThread currentThread] == myThread) {
        return [super hasChanges];
    }
    @synchronized(self) {
        NSInvocation* call = [self invocationWithSelector:@selector(hasChanges)];
        return (BOOL)[self runInvocation:call];
    }
}

@end
