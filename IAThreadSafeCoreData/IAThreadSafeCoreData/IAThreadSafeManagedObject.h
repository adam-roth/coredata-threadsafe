//
//  IAThreadSafeManagedObject.h
//
//  Created by Adam Roth on 15/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

/**
 * This class, when used in conjunction with 'IAThreadSafeContext', provides a completely thread-safe implementation of 
 * Core Data.  This allows for a single NSManagedObjectContext to be freely shared across multiple threads, and permits 
 * each thread to read and modify data as if it holds exclusive ownership of the context.  No manual synchronization 
 * is needed between threads, and it is not necessary to create an independent context for each thread.  
 *
 * Note that there are still cases in which it may be useful to have two or more independent contexts.  For instance, 
 * if you have an editing component that allows the user to modify some state, but you do not want other sections of 
 * the app to display the modified state until the user formally comits the change.  However, with this extension to 
 * Core Data you are never *required* to create a second context just because you want to run more than one thread.  You 
 * can defer the creation of additional contexts until you encounter a use-case that legitimately requires it.  
 *
 * Also note that using this tool carries several small caveats:
 *
 *      1.  All entities in the data model MUST inherit from 'IAThreadSafeManagedObject'.  Inheriting directly from 
 *          NSManagedObject is not acceptable and WILL crash the app.  Either every entity is thread-safe, or none 
 *          of them are.
 *
 *      2.  You MUST use 'IAThreadSafeContext' instead of 'NSManagedObjectContext'.  If you don't do this then there 
 *          is no point in using 'IAThreadSafeManagedObject' (and vice-versa).  You need to use the two classes together, 
 *          or not at all.  Note that to "use" IAthreadSafeContext, all you have to do is replace every [[NSManagedObjectContext alloc] init]
 *          with an [[IAthreadSafeContext alloc] init].
 *
 *      3.  You SHOULD NOT give any 'IAThreadSafeManagedObject' a custom setter implementation.  If you implement a custom 
 *          setter, then IAThreadSafeManagedObject will not be able to synchronize it, and the data model will no longer 
 *          be thread-safe.  
 *
 *          Note that you can work around the limitation by implementing your custom setters in the following pattern:
 *
 *              if (myThread && [NSThread currentThread] != myThread) {
 *                  [self performSelector:@selector(setMyField:) onThread:myThread withObject:theValueToSet waitUntilDone:YES];
 *                  return;
 *              }
 *              //<your custom setter code here>
 *
 *      4.  You SHOULD NOT add any additional @dynamic properties to your object, or any additional dynamic methods named
 *          like 'set...'.  If you do the 'IAThreadSafeManagedObject' superclass may attempt to override and synchronize 
 *          your implementation.
 *
 *      5.  If you implement 'awakeFromInsert' or 'awakeFromFetch' in your data model class(es), then you MUST call 
 *          the superclass implementation of these methods before you do anything else.
 *
 *      6.  You SHOULD NOT directly invoke 'setPrimitiveValue:forKey:' or any variant thereof.  
 *
 */
@interface IAThreadSafeManagedObject : NSManagedObject {
    NSThread* myThread;
}

@end
