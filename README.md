# BeardLib-Editor

BeardLib-Editor is a mod that uses the amazing library called BeardLib to allow editor-like features!

## Help Needed
We're looking for developers that will work together on the editor. Either fixing bugs or following the project I've put a little ago to ease the development.

https://github.com/simon-wh/PAYDAY-2-BeardLib-Editor/projects/1 

Working on the editor is essentially taking the real editor code (Found in the decompiled lua scripts here https://github.com/ontrigger/pd2-luajit-decompile just search "editor" using some text editor like VSCode/Atom) and making it run in the public version of the game. Instead of EWS (Framwork for creating window GUI) we use a menu UI code from BeardLib called MenuUI (Documentation: https://github.com/simon-wh/PAYDAY-2-BeardLib/wiki/MenuUI) You might want to look at the editor's code and how it works.

If you're interested, talk with me in discord Luffy#1946 and I'll give you permissions to push commits.

## Plugin source
https://github.com/Luffyyy/BeardLib-Editor-SBLT-Plugin

## Editor? For what?
Currently the level and environment editor are present. There are plans for effect, unit, object and material config editors and many more.

## Multiplayer
The mod disables matchmaking with normal users, you cannot play with players that don't have the editor.
This is done to prevent playing with different physics settings which can mess up the game of the host/clients.
You can either disable the editor or rename supermod.xml (the physics settings fix) to be able to play with others, hopefully in the future there will be a better way to address this.

## Level Editor?
Yep! You can create new levels from scratch using BeardLib-Editor.
Don't know how to? Read the guide here: https://modworkshop.net/wiki.php?action=view&id=15
Help would be really appreciated in the wiki!

## Report a bug
https://github.com/simon-wh/PAYDAY-2-BeardLib-Editor/issues

## Request a feature
https://feathub.com/simon-wh/PAYDAY-2-BeardLib-Editor

## Before you stop reading!
This mod has two dependencies, [SuperBLT](https://superblt.znix.xyz) and [BeardLib](https://modworkshop.net/mydownloads.php?action=view_down&did=14924), without them the editor will not run, make sure you have both of them with their latest version.

Additionally, you should extract the game files using [Bundle Modder](https://modworkshop.net/mydownloads.php?action=view_down&did=197) this will let the editor to fully work without anything missing, if the extract path is different, you can set the correct directory through the options of the editor.

## FAQ

    Q: I have issues with the mod, what to do?
    A: Before opening an issue in https://github.com/simon-wh/PAYDAY-2-BeardLib-Editor/issues please check your BLT log(mods/logs and a txt file with a date as a name) and see if there are any conflicting mods. If you do report an issue, please give as much information as possible.
    Q: How do I make a level?
    A: Go to the beginner guide if you missed: https://modworkshop.net/wiki.php?action=view&id=15.
    Q: There isn't a guide for 'X'
    A: Since I'm more active on actually developing the editor, I cannot focus on making guides, any help would be appreciated.
