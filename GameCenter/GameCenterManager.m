//
//  GameCenterManager.m
//  Ribbit
//
//  Created by Juan de la Torre on 12-08-30.
//  Copyright (c) 2012 Brisk Mobile. All rights reserved.
//

#import "GameCenterManager.h"
#import "GKAchievementHandler.h"

@implementation GameCenterManager

static GameCenterManager* _sharedGameCenterManager = nil;
@synthesize gameCenterAvailable = _gameCenterAvailable;
@synthesize earnedAchievementCache = _earnedAchievementCache;
@synthesize playerAlias = _playerAlias;

//=========================================================
#pragma mark - Singleton
//=========================================================

+(GameCenterManager*)sharedGameCenterManager
{
    @synchronized([GameCenterManager class])
    {
        if (!_sharedGameCenterManager)
        {
            [[self alloc] init];
        }
        return _sharedGameCenterManager;
    }
    return nil;
}

+(id) alloc
{
    @synchronized ([GameCenterManager class])
    {
        NSAssert((_sharedGameCenterManager == nil), @"Attempted to allocate a second instance of the Game Manager Singleton");
        _sharedGameCenterManager = [super alloc];
        return _sharedGameCenterManager;
    }
    return nil;
}

- (BOOL)isGameCenterAvailable {
    // check for presence of GKLocalPlayer API
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
    
    // check if the device is running iOS 4.1 or later
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer
                                           options:NSNumericSearch] != NSOrderedAscending);
    
    return (gcClass && osVersionSupported);
}

-(id) init
{
    self = [super init];
    if (self != nil)
    {
        _gameCenterAvailable = [self isGameCenterAvailable];
        if (_gameCenterAvailable) {
            NSNotificationCenter *nc =
            [NSNotificationCenter defaultCenter];
            [nc addObserver:self
                   selector:@selector(authenticationChanged)
                       name:GKPlayerAuthenticationDidChangeNotificationName
                     object:nil];
        }
    }
    return self;
}

-(void) dealloc
{
    [super dealloc];
}

//=========================================================
#pragma mark - Authentication
//=========================================================

- (void)authenticationChanged {
//    NSLog(@"authenticationChanged.");
    if ([GKLocalPlayer localPlayer].isAuthenticated && !_userAuthenticated) {
//        NSLog(@"Authentication changed: player authenticated.");
        _userAuthenticated = TRUE;
        
//        [self registerInvites];
        
    } else if (![GKLocalPlayer localPlayer].isAuthenticated && _userAuthenticated) {
//        NSLog(@"Authentication changed: player not authenticated");
        _userAuthenticated = FALSE;
    }
    
}

- (void)authenticateLocalUser {
    
    if (!_gameCenterAvailable) return;
    
//    NSLog(@"Authenticating local user...");
    if ([GKLocalPlayer localPlayer].authenticated == NO) {
        [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:nil];
    } else {
        NSLog(@"Already authenticated!");
    }
}

//=========================================================
#pragma mark - Main Thread dispatch
//=========================================================

// NOTE:  GameCenter does not guarantee that callback blocks will be execute on the main thread.
// As such, your application needs to be very careful in how it handles references to view
// controllers.  If a view controller is referenced in a block that executes on a secondary queue,
// that view controller may be released (and dealloc'd) outside the main queue.  This is true
// even if the actual block is scheduled on the main thread.  In concrete terms, this code
// snippet is not safe, even though viewController is dispatching to the main queue:
//
//	[object doSomethingWithCallback:  ^()
//	{
//		dispatch_async(dispatch_get_main_queue(), ^(void)
//		{
//			[viewController doSomething];
//		});
//	}];
//
// UIKit view controllers should only be accessed on the main thread, so the snippet above may
// lead to subtle and hard to trace bugs.  Many solutions to this problem exist.  In this sample,
// I'm bottlenecking everything through  "callDelegateOnMainThread" which calls "callDelegate".
// Because "callDelegate" is the only method to access the delegate, I can ensure that delegate
// is not visible in any of my block callbacks.

- (void) callMethod: (SEL) selector withArg: (id) arg error: (NSError*) err {
	assert([NSThread isMainThread]);
	if([self respondsToSelector: selector]) {
		if(arg != NULL) {
			[self performSelector: selector withObject: arg withObject: err];
		} else {
			[self performSelector: selector withObject: err];
		}
	} else {
		NSLog(@"GameCenterManager doesn't respond to method");
	}
}

- (void) callMethodOnMainThread: (SEL) selector withArg: (id) arg error: (NSError*) err
{
	dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self callMethod: selector withArg: arg error: err];
    });
}

//=========================================================
#pragma mark - Score submission
//=========================================================

- (void) submitScore:(int64_t)score forLeaderboard:(NSString*)leaderboard {
	GKScore *scoreReporter = [[[GKScore alloc] initWithCategory:leaderboard] autorelease];
	scoreReporter.value = score;
	[scoreReporter reportScoreWithCompletionHandler: ^(NSError *error)
	 {
         [self callMethodOnMainThread: @selector(scoreReportResponse:) withArg: NULL error: error];
	 }];
}

- (void) scoreReportResponse:(NSError*)error {
    if(error == NULL) {
//        NSLog(@"Score sucessfully reported");
    } else {
        NSLog(@"Error submitting score:%@", error.description);
    }
}

//=========================================================
#pragma mark - Achievement submission
//=========================================================

- (void) submitAchievement: (NSString*) identifier percentComplete: (double) percentComplete
{
	//GameCenter check for duplicate achievements when the achievement is submitted, but if you only want to report
	// new achievements to the user, then you need to check if it's been earned
	// before you submit.  Otherwise you'll end up with a race condition between loadAchievementsWithCompletionHandler
	// and reportAchievementWithCompletionHandler.  To avoid this, we fetch the current achievement list once,
	// then cache it and keep it updated with any new achievements.
	if(self.earnedAchievementCache == NULL) {
		[GKAchievement loadAchievementsWithCompletionHandler: ^(NSArray *scores, NSError *error) {
             if(error == NULL) {
                 NSMutableDictionary* tempCache= [NSMutableDictionary dictionaryWithCapacity: [scores count]];
                 for (GKAchievement* score in scores) {
                     [tempCache setObject: score forKey: score.identifier];
                 }
                 self.earnedAchievementCache= tempCache;
                 [self submitAchievement: identifier percentComplete: percentComplete];
             } else {
                 //Something broke loading the achievement list.  Error out, and we'll try again the next time achievements submit.
                 [self callMethodOnMainThread: @selector(achievementReportResponse:error:) withArg: NULL error: error];
             }
             
         }];
	} else {
        //Search the list for the ID we're using...
		GKAchievement* achievement= [self.earnedAchievementCache objectForKey: identifier];
		if(achievement != NULL) {
			if((achievement.percentComplete >= 100.0) || (achievement.percentComplete >= percentComplete)) {
				//Achievement has already been earned so we're done.
				achievement= NULL;
			}
			achievement.percentComplete= percentComplete;
		} else {
			achievement= [[[GKAchievement alloc] initWithIdentifier: identifier] autorelease];
			achievement.percentComplete= percentComplete;
			//Add achievement to achievement cache...
			[self.earnedAchievementCache setObject: achievement forKey: achievement.identifier];
		}
		
        if(achievement!= NULL) {
			//Submit the Achievement...
			[achievement reportAchievementWithCompletionHandler: ^(NSError *error) {
                [self callMethodOnMainThread: @selector(achievementReportResponse:error:) withArg: achievement error: error];
            }];
		}
	}
}

- (void) achievementReportResponse:(GKAchievement*)achievement error:(NSError*)error {
    if(error == NULL) {
        if(self.earnedAchievementCache != NULL) {
            NSString *identifier = achievement.identifier;
            
            GKAchievement* achievement = [self.earnedAchievementCache objectForKey: identifier];
            if(achievement != NULL) {
                float percentComplete = achievement.percentComplete;
                
                if(percentComplete >= 100.0) {
                    [[GKAchievementHandler defaultHandler] notifyAchievementTitle:NSLocalizedString(@"kAchievement_Title", "kAchievement_Title") andMessage:NSLocalizedString(identifier, "Achievement description")];
                }
            }
        }
    } else {
        NSLog(@"Error submitting Achievement:%@", error.description);
    }    
}

@end
