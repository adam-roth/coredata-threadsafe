### Thread-safe Core Data, an Overview

As its name implies, this project provides a thread-safe extension to the iOS Core Data framework.  It is drop-in compatible with existing Core Data projects (insomuch as is practical), requiring only that references to `NSManagedObject` and `NSManagedObjectContext` be replaced with references to their thread-safe counterparts.


### Building

This project creates a universal iOS framework when built within XCode.  To build it, you need to install the excellent [XCode project template](https://github.com/kstenerud/iOS-Universal-Framework) available here:

https://github.com/kstenerud/iOS-Universal-Framework

Note that this only applies when building this project as a standalone library/framework.  No special project templates are required if you prefer to just embed the project source files within your own project instead. 


### Usage

To use this framework, you must do two things:

1.  Update every class that you have that derives from `NSManagedObject` so that it derives from `IAThreadSafeManagedObject` instead.  To accomplish this, do:<pre>
\#import &lt;IAThreadSafeCoreData/IAThreadSafeManagedObject.h&gt;
@interface MyManagedObjectSubclass : IAThreadSafeManagedObject</pre>  Note that because `IAThreadSafeManagedObject` is derived directly from `NSManagedObject` no further modification is necessary to your code.

2.  Replace every instance of `[[NSManagedObjectContext alloc] init]` in your project with `[[IAThreadSafeContext alloc] init]`.  Again note that as `IAThreadSafeContext` is a subclass of `NSManagedObjectContext` none of your other code needs to be changed.
    

### Limitations

If you use this code, you should be aware that *at least* the following caveats/limitations have been identified.  It is in your own best interest to heed them:

1.  All entities in the data model **must** inherit from `IAThreadSafeManagedObject`.  Inheriting directly from `NSManagedObject` is not acceptable and **will** crash the app.  Either every entity is thread-safe, or none of them are.

2.  You **must** use `IAThreadSafeContext` instead of `NSManagedObjectContext`.  If you don't do this then there is no point in using `IAThreadSafeManagedObject` (and vice-versa).  You need to use the two classes together, or not at all.  

3.  You **should not** give any `IAThreadSafeManagedObject` a custom setter implementation.  If you implement a custom setter, then `IAThreadSafeManagedObject` will not be able to synchronize it, and the data model will no longer be thread-safe.  Note that you can work around the limitation by implementing your custom setters in the following pattern:<pre>
    \- (void) setMyField:(NSObject*)theValueToSet{
        if (myThread && [NSThread currentThread] != myThread) {
            [self performSelector:@selector(setMyField:) onThread:myThread withObject:theValueToSet waitUntilDone:YES];
            return;
        }
        //[your custom setter code here...]
    }</pre>

4.  You **should not** add any additional `@dynamic` properties to your object, or any additional dynamic methods named like 'set...'.  If you do the `IAThreadSafeManagedObject` superclass may attempt to override and synchronize your dynamic method.

5.  If you implement `awakeFromInsert` or `awakeFromFetch` in your data model class(es), then you **must** call the superclass implementation of these methods before you do anything else.

6.  You **should not** directly invoke `setPrimitiveValue:forKey:` or any variant thereof.  As above, you can work around this by ensuring that the invocation will be made on the correct thread by inspecting the value of `myThread`.

7.  This library **has not** been tested with `NSUndoManager` functionality.  It is not known if it will work in this context.  Use 'undo' at your own risk. 

### FAQ

**_Why create a thread-safe extension to Core Data?_**<br />
Because I was tired of the absurd concurrency rules associated with `NSManagedObjectContext` and the needless workarounds (`NSOperationQueue`'s and `dispatch_async()` calls) that are always suggested for dealing with the problem.  At the end of the day Core Data is just a place to store information.  I want to be able to put things in and then get them back out again, that's it.  I don't want to have to set up a separate context on each thread that needs access to my information.  I shouldn't have to pass around all my code in blocks just so that it can get access to the data on the correct thread.  I don't want to have to manually synchronize concurrent accesses to the data set.  I need to store data and read data, and I want it to _just work_.

**_Why should I use this library?_**<br />
Use this library if you've got a Core Data app and better things to do with your time than worry about whether or not you are accessing your data "correctly".  This code will give you a data layer that just works, freeing you up to focus on things that actually matter, like building your app.

**_Why should I NOT use this library?_**<br />
Don't use this library if your app is performance-limited by its data layer.  Such cases are probably rare with iOS apps, but you should be aware that synchronizing every access to the data layer is relatively costly and could conceivably degrade performance in a data-intensive app.  

You may also want to avoid this code if your app has a particularly large or complex data model.  I'm not saying that it won't work for you (and I can't even point to any specific reason why it _might_ not work for you), but so far it has only been tested and validated in simpler apps with not more than moderately complex data models.  If you need to be absolutely sure that things are going to work, stick to the old-fashioned way.

Also, if you like setting up `NSOperationQueue`'s and `dispatch_async()` calls are the only sunshine in your day then you probably don't want to use this code.

**_What are your license terms?_**<br />
License terms?  Really???  Look, this is public code in a public repository.  I put it here knowing that.  It would be absurd for me to assert that I have any right to set conditions on how people may use this code after I have knowingly made it publicly available to anyone who might stumble across it.  I know some other people like to do that, but let's try not to stoop to their level, shall we?

So my license terms are simple.  Use this code if you want, otherwise don't.  That's it.  


### Miscellaneous

Another excellent project that makes Core Data _much_ easier to work with can be found here:

https://github.com/halostatue/coredata-easyfetch
