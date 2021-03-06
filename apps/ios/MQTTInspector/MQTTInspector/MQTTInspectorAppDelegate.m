//
//  MQTTInspectorAppDelegate.m
//  MQTTInspector
//
//  Created by Christoph Krey on 09.11.13.
//  Copyright © 2013-2016 Christoph Krey. All rights reserved.
//

#import "MQTTInspectorAppDelegate.h"
#import "MQTTInspectorMasterViewController.h"

#import "Model.h"

@interface MQTTInspectorAppDelegate ()
@property (nonatomic) UIBackgroundTaskIdentifier bgTask;
@end

@implementation MQTTInspectorAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:ddLogLevel];
    DDLogVerbose(@"didFinishLaunchingWithOptions");
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:TRUE];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    DDLogVerbose(@"applicationDidBecomeActive");
    [[UIApplication sharedApplication] setIdleTimerDisabled:TRUE];

}

- (void)applicationWillResignActive:(UIApplication *)application {
    DDLogVerbose(@"applicationWillResignActive");
    [self saveContext];
    [[UIApplication sharedApplication] setIdleTimerDisabled:FALSE];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    DDLogVerbose(@"applicationDidEnterBackground");

    self.bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
                           {
                               DDLogVerbose(@"BackgroundTaskExpirationHandler");
                               [self connectionClosed];
                           }];
}

- (void)connectionClosed {
    DDLogVerbose(@"connectionClosed");
    
    if (self.bgTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    DDLogVerbose(@"applicationWillTerminate");
    [self saveContext];
}

- (void)saveContext {
    DDLogVerbose(@"saveContext");

    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            DDLogError(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"MQTTInspector" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"MQTTInspector.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                             NSInferMappingModelAutomaticallyOption: @YES};

    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        DDLogError(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    DDLogVerbose(@"UIApplication openURL:%@ sourceApplication:%@ annotation:%@",
                 url, sourceApplication, annotation);
    
    if (url) {
        NSError *error;
        NSInputStream *input = [NSInputStream inputStreamWithURL:url];
        if ([input streamError]) {
            DDLogError(@"Error inputStreamWithURL %@ %@", [input streamError], url);
            return FALSE;
        }
        [input open];
        if ([input streamError]) {
            DDLogError(@"Error open %@ %@", [input streamError], url);
            return FALSE;
        }
        
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithStream:input options:0 error:&error];
        if (dictionary) {
            for (NSString *key in [dictionary allKeys]) {
                DDLogVerbose(@"Init %@:%@", key, dictionary[key]);
            }
            
            if ([dictionary[@"_type"] isEqualToString:@"MQTTInspector-Session"]) {
                NSString *name = dictionary[@"name"];
                Session *session = [Session existSessionWithName:name
                                          inManagedObjectContext:_managedObjectContext];
                if (!session) {
                    session = [Session sessionWithName:name
                                                  host:@"host"
                                                  port:1883
                                                   tls:NO
                                                  auth:NO
                                                  user:@""
                                                passwd:@""
                                              clientid:@""
                                          cleansession:YES
                                             keepalive:60
                                           autoconnect:NO
                                                dnssrv:NO
                                             dnsdomain:@""
                                         protocolLevel:4
                                       attributefilter:@""
                                           topicfilter:@""
                                            datafilter:@""
                                         includefilter:YES
                                             sizelimit:0
                                inManagedObjectContext:_managedObjectContext];
                }
                
                NSString *string;
                string = dictionary[@"host"];
                if (string) session.host = string;
                
                string = dictionary[@"port"];
                if (string) session.port = @([string integerValue]);
                
                string = dictionary[@"tls"];
                if (string) session.tls = @([string boolValue]);
                
                string = dictionary[@"auth"];
                if (string) session.auth = @([string boolValue]);
                
                string = dictionary[@"user"];
                if (string) session.user = string;
                
                string = dictionary[@"passwd"];
                if (string) session.passwd = string;
                
                string = dictionary[@"clientid"];
                if (string) session.clientid = string;
                
                string = dictionary[@"cleansession"];
                if (string) session.cleansession = @([string boolValue]);
                
                string = dictionary[@"keepalive"];
                if (string) session.keepalive = @([string integerValue]);
                
                string = dictionary[@"autoconnect"];
                if (string) session.autoconnect = @([string boolValue]);
                
                string = dictionary[@"websocket"];
                if (string) session.websocket = @([string boolValue]);
                
                string = dictionary[@"allowUntrustedCertificates"];
                if (string) session.allowUntrustedCertificates = @([string boolValue]);
                
                string = dictionary[@"protocollevel"];
                if (string) session.protocolLevel = @([string integerValue]);
                
                string = dictionary[@"sizelimit"];
                if (string) session.sizelimit = @([string integerValue]);
                
                string = dictionary[@"includefilter"];
                if (string) session.includefilter = @([string boolValue]);
                
                string = dictionary[@"attributefilter"];
                if (string) session.attributefilter = string;
                
                string = dictionary[@"datafilter"];
                if (string) session.datafilter = string;
                
                string = dictionary[@"topicfilter"];
                if (string) session.topicfilter = string;

                NSArray *subs = dictionary[@"subs"];
                if (subs) for (NSDictionary *subDict in subs) {
                    NSString *topic = subDict[@"topic"];
                    Subscription *sub = [Subscription existsSubscriptionWithTopic:topic
                                                                          session:session
                                                           inManagedObjectContext:_managedObjectContext];
                    if (!sub) {
                        sub = [Subscription subscriptionWithTopic:topic
                                                              qos:0
                                                          session:session
                                           inManagedObjectContext:_managedObjectContext];
                    }
                    string = subDict[@"qos"];
                    if (string) sub.qos = @([string integerValue]);
                }
                NSArray *pubs = dictionary[@"pubs"];
                if (pubs) for (NSDictionary *pubDict in pubs) {
                    NSString *name = pubDict[@"name"];
                    Publication *pub = [Publication existsPublicationWithName:name
                                                                      session:session
                                                       inManagedObjectContext:_managedObjectContext];
                    if (!pub) {
                        pub = [Publication publicationWithName:name
                                                         topic:@"topic"
                                                           qos:0
                                                      retained:NO
                                                          data:[[NSData alloc] init]
                                                       session:session
                                        inManagedObjectContext:_managedObjectContext];
                    }
                    string = pubDict[@"topic"];
                    if (string) pub.topic = string;

                    string = pubDict[@"qos"];
                    if (string) pub.qos = @([string integerValue]);

                    string = pubDict[@"retained"];
                    if (string) pub.retained = @([string boolValue]);

                    NSData *data = pubDict[@"data"];
                    if (string) pub.data = data;
                }
            } else {
                DDLogError(@"Error invalid init file %@)", dictionary[@"_type"]);
                return FALSE;
            }
        } else {
            DDLogError(@"Error illegal json in init file %@)", error);
            return FALSE;
        }
        
        DDLogError(@"Init file %@ successfully processed)", [url lastPathComponent]);
        
    }
    [self saveContext];
    return TRUE;
}

@end
