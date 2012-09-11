ios-gamecenter-singleton
========================

Singleton Implementation of Game Center for iOS, for managing Leaderboards, achievements and multi player.

In the instructions below I assume you have an app already configured on the iOS Provisioning Portal and iTunes Connect:

## How-to Use
1. Include the files on your project
2. Import GameCenterManager.h in your App Delegate and in all the classes you need to use Leaderboards or Achievements with 
	<pre>#import "GameCenterManager.h"</pre>
3. Authenticate the user on your applicationDidFinishLaunching: or applicationDidFinishLaunchingWithOptions: method by calling 
	<pre>[[GameCenterManager sharedGameCenterManager] authenticateLocalUser];</pre>
Note: If no local user is authenticated, a Game Center login window will appear.
4. Modify your achievements and leaderboards accordingly on GameCenterConstants.h
5. Report an achievement by using:
	<pre>[[GameCenterManager sharedGameCenterManager] submitAchievement:kAchievement_FlySwatter percentComplete:100.0f];</pre>
6. To submit a score to a Leaderboard:
	<pre>[[GameCenterManager sharedGameCenterManager] submitScore:self.totalBugs forLeaderboard:kLeaderboard_EatenBugs];</pre>

## To Do
- Implement Multi-player

## Extras
Added Game Center styled UI notifications, thanks to Benjamin Borowski for [GKAchievementNotification](https://github.com/typeoneerror/GKAchievementNotification)

## Contact

[Juan de la Torre](http://github.com/juanpdelat)  
[@juanpdelat](http://twitter.com/juanpdelat)
