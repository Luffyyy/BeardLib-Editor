# BeardLib-Editor

BeardLib-Editor is a tool that allows you to edit and create things like maps & environments.

## Installation
1. (Required to use the massunits tool) https://dotnet.microsoft.com/download/dotnet/5.0/runtime Download the x64 version runtime.
2. Install [SuperBLT](https://superblt.znix.xyz)
3. Install [BeardLib](https://modworkshop.net/mod/14924)
4. After downloading the editor by clicking `Code` -> `Download ZIP`, unzip the contents of the ZIP file in the mods folder of the game.
5. Launch the game and click `Yes` on the dialog that pops up. These files are required.

If you install the dev branch, make sure you have the latest BeardLib commit https://github.com/simon-wh/PAYDAY-2-BeardLib it's possible that branch uses unreleased features not found in the public (MWS) version.

## Matchmaking
Matchmaking is **disabled** by default due to having to edit the physics settings of the game.
Playing with people with said edit can cause issues if not everyone has the said fix. 

In order to enable matchmaking, you must disable the physics fix through the editor's options menu. Do note that without that fix, the editor will not work properly.

## Guides
https://www.youtube.com/playlist?list=PLRSASA7UrjTsX1WWG6kStRTK51DKSEDPn
https://wiki.modworkshop.net/books/payday-2/chapter/beardlib-editor

## Report a Bug/Request a Feature
https://github.com/simon-wh/PAYDAY-2-BeardLib-Editor/issues

## Ask a Question
Payday 2 Maps Discord Server - https://discord.gg/fn62qaq \
Painday 2 (maker of the video tutorials) Discord Server - https://discord.gg/RNBUnrN7 \
ModWorkshop Discord Server - https://discord.gg/Eear4JW \
GitHub Discussion - https://github.com/Luffyyy/BeardLib-Editor/discussions

## Help Needed
We're looking for developers that will work together on the editor. 

Your best friend in all of this is knowing how to look for the pieces of code that correspond to parts of the editor. Be it in the decompiled files of the game or the editor's code.

Make sure you are using a good code editor like VSCode. This will allow you to quickly search the code and the decompiled code of the game https://github.com/mwSora/payday-2-luajit.

Make sure you have an empty file called developer.txt in the mods folder (turns on the console) and run the following command: blt.forcepcalls(true) - this let's you not crash the moment you hit a random error. 

The editor is equipped with a code refresher, editing any file will refresh parts of the editor.

The real editor uses what is called in the decompiled code 'EWS' (really just search). Unfortunately we don't have access to this kind of GUI and porting it is easier said than done. Instead of that we use https://github.com/simon-wh/PAYDAY-2-BeardLib/wiki/MenuUI and have a class that simplfies the process of creation a little https://github.com/Luffyyy/BeardLib-Editor/blob/master/Classes/MenuUIExt.lua 

## Generating the Data Files
If the hashlist/game gets updated you can update the data files yourself by doing the following:

1. Get DieselBundleViewer (1.1.1 and up)
2. Install the PackageOutputter script from https://github.com/Luffyyy/DieselBundleViewer-Scripts
3. Open DieselBundleViewer and open the BLB file from PAYDAY 2's assets directory.
4. Once the load is complete, run the script from File > Scripts > Package Hashlist Outputter
5. This should create a file named packages.txt.
6. Drop the file to BeardLib Editor's root directory and run the game. The editor will do the rest.

## Plugin Source
https://github.com/Luffyyy/LuaFileSystem-SBLT
