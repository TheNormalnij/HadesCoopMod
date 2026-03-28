
# Hades coop mod

Play Hades with a friend!
This mod adds local cooperative multiplayer to Hades, allowing two players to fight through the Underworld together on the same PC.

For online play: Use a streaming tool like [Parsec](https://parsec.app/) to share your game session with a remote friend.

The mod supports the **Steam** and **Epic Games Store** versions of the gamme

**Warning**

You need a gameplay to play this mod.

# Build

## Using CMake for Windows x64

```powershell
cmake -A x64 . -B build_msvc
cmake --build build_msvc --config Release
```

Binary files are located in the `bin` folder.

## Using [Visual Studio](https://visualstudio.microsoft.com/) GUI

You need to install cmake in the Visual Studio Installer to build the project.
Open the project in VS and click Build -> Build All in the top menu.
Check `bin` folder for `HadesCoopGame.dll`.

# How to load the mod from the repository folder

Follow these steps if you want to develop the mod and save changes in git:

1. Create the folder `Hades/Hades/Content/ModModules/TN_CoopMod/`
2. Copy the repository into `Hades/Hades/Content/ModModules/TN_CoopMod/dev`
3. Create `Hades/Hades/Content/ModModules/TN_CoopMod/init.lua` with the following content:
```lua
ModRequire "dev/game/scripts/init.lua"
```
4. Create `Hades/Hades/Content/ModModules/TN_CoopMod/meta.sjson` with the following content:
```sjson
{
	Name = "Coop mod"
	Library = "dev/bin/HadesCoopGame.dll"
	Author = "Uladzislau 'TheNormalnij' Nikalayevich"
}
```
5. Now you can make changes directly in the repository and load them in the game.

# Suppoort

You can support development using crypto. See [my page](https://thenormalnij.de/donate) for details
