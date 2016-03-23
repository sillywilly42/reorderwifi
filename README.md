ReorderWiFi
===========
Standard user accounts on OS X do not have permission to edit the list of preferred Wi-Fi networks. They can neither remove nor re-order them, as either operation requires admin priviledges.
![ReorderWiFi 1.0](http://sillywilly42.github.io/images/reorderwifi.png)

When run as root, ReorderWiFi will display a simple GUI allowing users to re-order/remove networks. The app can be deployed in a managed environment via eg. Casper's Self-Service or from a [Munki](https://github.com/munki/munki) package postflight.

Sometimes it's desirable to prevent users removing certain networks. Any arguments passed to the app on the command line are treated as SSIDs which cannot be removed:
```
/path/to/ReorderWiFi.app/Contents/MacOS/ReorderWiFi "MegaCorpWiFi" "MegaCorpGuest"
```
Saved WiFi passwords are removed from the System keychain when removed from the list.

Requirements / Limitations
--------------------------
* Minimum OS: 10.11
* Passwords are not removed from the user's keychain, only the System keychain.

Download
--------
The latest release is on the [release page](https://github.com/sillywilly42/reorderwifi/releases).
