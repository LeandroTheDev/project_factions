# Factions

Forked from [SSR: Safehouse](https://steamcommunity.com/sharedfiles/filedetails/?id=1178772929&searchtext=Safehouse) to create a complete new system to safehouse claim and capture

- UI to show the safehouse informations
- Capture safehouse system
- Multiple Safehouses (Need server configuration)
- Chat alert for actions (capturing, losing, captured, lost)
- Configurable time to enable safehouse capture invasion, also timezone
- Configurable zombie kills to earn points
- Configurable player construction health while in capture mode
- Players can only try to capture safehouse one time per game day

Consider downloading the safehouse limit remover in the folder [Server Configuration](https://github.com/LeandroTheDev/project_factions/tree/main/Server%20Configuration) and place it in the main project zomboid dedicated server folder

# Factions Economy

Shop Forked from [Server Points](https://steamcommunity.com/sharedfiles/filedetails/?id=2823055977&searchtext=Server+Points), Trade system to the game, including Loot Boxes

- Shop UI
- Trade UI
- Lootboxes
- Trade Money can be returned to get points for the shop and trade

# Factions Plus

Add new features and adjustments for playing with Factions Mode, require the Factions Economy

- New economy item
- Sell vegetables/fruits
- Scrap Weapons to earn Trade Money
- Increase crop grow speed
- Reduced seed drop by crops
- Reduced water need for fully watered crop
- Connections/Disconnections/Death player messages events
- Random hordes
- Special hordes for special locations (Lua/HordeSpecialPositions.ini)

# Safehouse Plus

Add several new mechanics to safehouses, with the upgrader you can increase the house level to gain more Points in the Server, you can easily create keys for your safehouse, and new
respawn mechanics forked from [Keep Inventory](https://steamcommunity.com/sharedfiles/filedetails/?id=2879960829)

- Create key in Safehouse (Need Factions Mod)
- Upgrade Safehouse (Need Factions Economy Mod)
- Reedem points (Need Factions Economy Mod)
- Respawn in safehouse bed
- Safehouse Protection Item (Need Factions Mod)

#

### Questions
- Can i use in my server? yes
- Can i reupload this to workshop? yes
- Can i modify this project? yes
- Can i share this project? yes
- Can i steal this project? only if the name is changed
- Can i charge for this project? only if the name is changed

### Submodules
External very useful mods to make the factions better
- [Random Airdrops](https://github.com/LeandroTheDev/random_airdrops), add random airdrops to the server
- [RA Smoke Flares](https://github.com/LeandroTheDev/ra_smoke_flares), add smoke flares to call any airdrop
- [Factions Weapons](https://github.com/LeandroTheDev/factions_weapons), overhaul the weapons to make it more immersive and fun to play with

- > To download the submodules you can use "git submodule init", "git submodule update" in your terminal

### Using the project in the Server
- Install git in your operational system (Or you can simple clone the repository and the submodules)
- In your terminal type: git clone --recurse-submodules https://github.com/LeandroTheDev/project_factions
- Copy all mods from the new folder created, and paste on your project zomboid mods folder
- > You can also upload to workshop to automatically users download this project
- Now you can open the game, enable the mods and change the sandbox configurations
- > Some mods require special configurations in Lua, after starting the server take a look in the Lua folder, all mods also have a Logs folder in Lua to manage players actions, you can view templates in [Server Configuration](https://github.com/LeandroTheDev/project_factions/tree/main/Server%20Configuration) folder
- > Also some mods needs modifications in the java class to work propertly, consider checking the [Server Configuration](https://github.com/LeandroTheDev/project_factions/tree/main/Server%20Configuration) folder

Load Order:
- Factions
- Factions Economy
- Factions Plus
- Safehouse Plus
- Random Airdrops
- RA Smoke Flares
- Factions Weapons

FTM License