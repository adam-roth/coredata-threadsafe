//
//  IAThreadSafeContext.h
//
//  Created by Adam Roth on 14/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

/**
 * A thread-safe managed object context implementation.  Please see IAThreadSafeManagedObject.h for details and caveats.
 */
@interface IAThreadSafeContext : NSManagedObjectContext {
    NSThread* myThread;
}

@end
