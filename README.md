
# Hades coop mod

# Build

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
4. Create `Hades/Hades/Content/ModModules/TN_CoopMod/init.xml` with the following content:
```xml
<?xml version="1.0" encoding="UTF-8" ?>
<mod>
	<Name value="Coop mod"/>
	<Library value="dev/bin/HadesCoopGame.dll" />
	<Author value="Uladzislau 'TheNormalnij' Nikalayevich" />
</mod>
```
5. Now you can make changes directly in the repository and load them in the game.