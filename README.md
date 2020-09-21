# BeardLib-Editor

BeardLib-Editor is a mod that uses the amazing library called BeardLib to allow editor-like features!

## Editor? For what?
Currently there's an editor for maps, environment and effects.

## Level Editor?
Yep! You can create new levels from scratch using BeardLib-Editor.
Don't know how to? Read the guide here: https://wiki.modworkshop.net/books/payday-2/chapter/beardlib-editor
Help would be really appreciated in the wiki!

## Report a bug/Request a feature
https://github.com/simon-wh/PAYDAY-2-BeardLib-Editor/issues

## Installation
This mod has two dependencies, [SuperBLT](https://superblt.znix.xyz) and [BeardLib](https://github.com/simon-wh/PAYDAY-2-BeardLib). Without them the editor will not run. Make sure you have both fully updated. **We ask you to download the GitHub version of BeardLib since the editor uses the latest features of BeardLib that may not be in the public/MWS version. The link we provided is the repo of BeardLib.**

Then install the mod as any BLT mod, drop to mods folder.

After that download these files https://modworkshop.net/mod/25270
And drop them to your BeardLib-Editor folder in mods.

Additionally, you **must** extract the game files using [Diesel Bundle Viewer](https://modworkshop.net/mod/27741). Currently, the editor cannot fully function without having the game files extracted. If the extract path is different, you can set the correct directory through the options of the editor.

## FAQ
* **Q:** I have issues with the mod, what to do?\
  **A:** Before opening an issue in https://github.com/simon-wh/PAYDAY-2-BeardLib-Editor/issues please check your BLT 
    log(mods/logs and a txt file with a date as a name) and see if there are any conflicting mods. If you do report an issue, 
    please give as much information as possible.
* **Q:** How do I make a level?\
  **A:** Go to the beginner guide if you missed: https://wiki.modworkshop.net/books/payday-2/chapter/beardlib-editor.
* **Q:** There isn't a guide for 'X'\
  **A:** Since I'm more active on actually developing the editor, I cannot focus on making guides. Any help would be appreciated.
* **Q:** Why can't I play multiplayer when using the mod?\
  **A:** The mod disables matchmaking with normal users. You cannot play with players that don't have the editor. This is done to 
    prevent playing with different physics settings which can mess up the game of the host/clients. You can either disable the 
    editor or rename supermod.xml (the physics settings fix) to be able to play with others, hopefully in the future there will 
    be a better way to address this.

## Help Needed
We're looking for developers that will work together on the editor. 

Working on the editor is essentially taking the real editor code (Found in the decompiled lua scripts here https://github.com/ontrigger/pd2-luajit-decompile just search "editor" using some text editor like VSCode/Atom) and making it run in the public version of the game. Instead of EWS (Framwork for creating window GUI) we use a menu UI code from BeardLib called MenuUI (Documentation: https://github.com/simon-wh/PAYDAY-2-BeardLib/wiki/MenuUI) You might want to look at the editor's code and how it works. The editor uses its own class to simplify the menu builiding found here https://github.com/Luffyyy/BeardLib-Editor/blob/master/Classes/MenuUIExt.lua 
Make sure you have developer.txt and you run blt.forcepcalls(true) these are important for developing the editor.
developer.txt enables the console and the code refresher for the editor. And forcepcalls makes it so you won't crash for each small error (potentially slowing down development)

If you're interested, talk with me in discord Luffy#1946 and I'll give you permissions to push commits.
Pull requests are appreciated too!

## Generating the data files
If the hashlist/game gets updated you can update the data files yourself by doing the following:

1. Get DieselBundleViewer (1.1.1 and up)
2. Install the PackageOutputter script from https://github.com/Luffyyy/DieselBundleViewer-Scripts
3. Open DieselBundleViewer and open the BLB file from PAYDAY 2's assets directory.
4. Once the load is complete, run the script from File > Scripts > Package Hashlist Outputter
5. This should create a file named packages.txt.
6. Drop the file to BeardLib Editor's root directory and run the following command in lua: BeardLibEditor:GeneratePackageData() the editor will do the rest.

## Plugins source
https://github.com/Luffyyy/BeardLib-Editor-SBLT-Plugin

https://github.com/Luffyyy/LuaFileSystem-SBLT
