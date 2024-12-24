# This script will automatically put the mods in the zomboid folder, change it for whatever path is your zomboid folder
# Necessary because the b42 version cannot understand symbolic path, something they changed breaked unfurtunally
rm -rf "/home/bobs/Zomboid/mods/Factions"
rm -rf "/home/bobs/Zomboid/mods/Factions Economy"
rm -rf "/home/bobs/Zomboid/mods/Factions Plus"
rm -rf "/home/bobs/Zomboid/mods/RA Smoke Flares"
rm -rf "/home/bobs/Zomboid/mods/Random Airdrops"
rm -rf "/home/bobs/Zomboid/mods/Safehouse Plus"

cp -r "./Factions" "/home/bobs/Zomboid/mods/"
cp -r "./Factions Economy" "/home/bobs/Zomboid/mods/"
cp -r "./Factions Plus" "/home/bobs/Zomboid/mods/"
cp -r "./Factions Weapons/Factions Weapons" "/home/bobs/Zomboid/mods/"
cp -r "./RA Smoke Flares/RA Smoke Flares" "/home/bobs/Zomboid/mods/"
cp -r "./Random Airdrops/Random Airdrops" "/home/bobs/Zomboid/mods/"
cp -r "./Safehouse Plus" "/home/bobs/Zomboid/mods/"