//
//  IAThreadSafeManagedObject.m
//  CampsAustralia
//
//  Created by Adam Roth on 15/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IAThreadSafeManagedObject.h"
#import <objc/runtime.h>

void dynamicSetter(id self, SEL _cmd, id obj);

@implementation IAThreadSafeManagedObject

- (id) init {
    if (self = [super init]) {
        //myThread = nil;
    }
    
    return self;
}

- (id) initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context {
    if (self = [super initWithEntity:entity insertIntoManagedObjectContext:context]) {
        if (myThread != [NSThread currentThread]) {
            //myThread = nil;
        }
    }
    
    return self;
}

- (void) awakeFromInsert {
    myThread = [NSThread currentThread];
}

- (void) awakeFromFetch {
    myThread = [NSThread currentThread];
}

- (NSThread*) myThread {
    return myThread;
}

- (void) recallDynamicSetter:(SEL)sel withObject:(id)obj {
    dynamicSetter(self, sel, obj);
}

- (void) runInvocationOnCorrectThread:(NSInvocation*)call {
    if (! [self myThread] || [NSThread currentThread] == [self myThread]) {
        //okay to invoke
        [call invoke];
    }
    else {
        //remap to the correct thread
        [self performSelector:@selector(runInvocationOnCorrectThread:) onThread:myThread withObject:call waitUntilDone:YES];
    }
}

void dynamicSetter(id self, SEL _cmd, id obj) {
    if (! [self myThread] || [NSThread currentThread] == [self myThread]) {
        //okay to execute
        //XXX:  clunky way to get the property name, but meh...
        NSString* targetSel = NSStringFromSelector(_cmd);
        NSString* propertyNameUpper = [targetSel substringFromIndex:3];  //remove the 'set'
        NSString* firstLetter = [[propertyNameUpper substringToIndex:1] lowercaseString];
        NSString* propertyName = [NSString stringWithFormat:@"%@%@", firstLetter, [propertyNameUpper substringFromIndex:1]];
        propertyName = [propertyName substringToIndex:[propertyName length] - 1];
        
        //NSLog(@"Setting property:  name=%@", propertyName);
        
        [self willChangeValueForKey:propertyName];
        [self setPrimitiveValue:obj forKey:propertyName];
        [self didChangeValueForKey:propertyName];
        
    }
    else {
        //call back on the correct thread
        NSMethodSignature* sig = [self methodSignatureForSelector:@selector(recallDynamicSetter:withObject:)];
        NSInvocation* call = [NSInvocation invocationWithMethodSignature:sig];
        [call retainArguments];
        call.target = self;
        call.selector = @selector(recallDynamicSetter:withObject:);
        [call setArgument:&_cmd atIndex:2];
        [call setArgument:&obj atIndex:3];
        
        [self runInvocationOnCorrectThread:call];
    }
}

+ (BOOL) resolveInstanceMethod:(SEL)sel {
    NSString* targetSel = NSStringFromSelector(sel);
    if ([targetSel hasPrefix:@"set"] && [targetSel rangeOfString:@"Primitive"].location == NSNotFound) {
        NSLog(@"Overriding selector:  %@", targetSel);
        class_addMethod([self class], sel, (IMP)dynamicSetter, "v@:@");
        return YES;
    }
    
    return [super resolveInstanceMethod:sel];
}

@end
