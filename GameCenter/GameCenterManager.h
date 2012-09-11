//
//  GameCenterManager.h
//  Ribbit
//
//  Created by Juan de la Torre on 12-08-30.
//  Copyright (c) 2012 Brisk Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "GameCenterConstants.h"

@interface GameCenterManager : NSObject
{
    BOOL                                        _gameCenterAvailable;
    BOOL                                        _userAuthenticated;

	NSMutableDictionary                         *_earnedAchievementCache;
    NSString                                    *_playerAlias;
}

@property (assign, readonly) BOOL gameCenterAvailable;

//This property must be attomic to ensure that the cache is always in a viable state...
@property (retain) NSMutableDictionary* earnedAchievementCache;
@property (nonatomic, retain) NSString* playerAlias;

+(GameCenterManager*)sharedGameCenterManager;

- (void) authenticateLocalUser;
- (void) submitScore:(int64_t)score forLeaderboard:(NSString*)leaderboard;
- (void) submitAchievement:(NSString*)achievement percentComplete:(double)percentComplete;

@end
