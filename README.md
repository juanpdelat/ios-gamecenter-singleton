ios-gamecenter-singleton
========================

Singleton Implementation of Game Center for iOS, for managing Leaderboards, achievements and multi player.


How-to Use
========================
1. Include the files on your project
2. Include GameCenterManager.h in your App Delegate with #import "GameCenterManager.h"
3. Authenticate the user calling [[GameCenterManager sharedGameCenterManager] authenticateLocalUser]; on your applicationDidFinishLaunching: or applicationDidFinishLaunchingWithOptions: method.
	Note: If no local user is authenticated, a Game Center login window will appear
4. 