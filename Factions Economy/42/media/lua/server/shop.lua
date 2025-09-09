ShopItems = {};

local function LoadShopItems()
    local path = "FactionsEconomyShopItems.ini"
    local fileReader = getFileReader(path, true)

    local lines = {}
    if fileReader then
        local line = fileReader:readLine()
        while line do
            table.insert(lines, line)
            line = fileReader:readLine()
        end
        fileReader:close()
    end

    -- Default value if not exist
    if #lines == 0 then
        local defaultContent = [[
return {
    lootbox = {
        {
            type = "ITEM",
            target = "Base.LootBoxAmmo",
            quantity = 1,
            price = 5
        },
		{
            type = "ITEM",
            target = "Base.LootBoxSpecialWeapon",
            quantity = 1,
            price = 25
        },
		{
            type = "ITEM",
            target = "Base.LootBoxWeapon",
            quantity = 1,
            price = 15
        },
		{
            type = "ITEM",
            target = "Base.LootBoxMelee",
            quantity = 1,
            price = 5
        },
		{
            type = "ITEM",
            target = "Base.LootBoxClip",
            quantity = 1,
            price = 5
        },
		{
            type = "ITEM",
            target = "Base.LootBoxAttachment",
            quantity = 1,
            price = 5
        },
		{
            type = "ITEM",
            target = "Base.LootBoxClothes",
            quantity = 1,
            price = 5
        }
    },
	survival = {
		{
            type = "ITEM",
            target = "Base.Wire",
            quantity = 1,
            price = 10
        },
		{
            type = "ITEM",
            target = "Base.NailsBox",
            quantity = 1,
            price = 30
        },
        {
            type = "ITEM",
            target = "Base.ScrewsBox",
            quantity = 1,
            price = 45
        },
		{
            type = "ITEM",
            target = "Base.Plank",
            quantity = 1,
            price = 4
        },
        {
            type = "ITEM",
            target = "Base.Log",
            quantity = 1,
            price = 12
        },
		{
            type = "ITEM",
            target = "Base.Glue",
            quantity = 1,
            price = 15
        },
		{
            type = "ITEM",
            target = "Base.BucketConcreteFull",
            quantity = 1,
            price = 20
        },
        {
            type = "ITEM",
            target = "Base.Generator",
            quantity = 1,
            price = 150
        }
    },
	faction = {
        {
            type = "ITEM",
            target = "Base.FactionsEconomy_Currency",
            quantity = 1,
            price = 1
        }
    },
    farm = {
        {
            type = "ITEM",
            target = "Base.GardenHoe",
            quantity = 1,
            price = 30
        },
		{
            type = "ITEM",
            target = "Base.WateredCan",
            quantity = 1,
            price = 40
        },
        {
            type = "ITEM",
            target = "Base.GardeningSprayEmpty",
            quantity = 1,
            price = 25
        },
		{
            type = "ITEM",
            target = "Base.RoseBagSeed",
            quantity = 1,
            price = 5
        },
		{
            type = "ITEM",
            target = "Base.PoppyBagSeed",
            quantity = 1,
            price = 5
        },
		{
            type = "ITEM",
            target = "Base.LavenderBagSeed",
            quantity = 1,
            price = 5
        },
		{
            type = "ITEM",
            target = "Base.CarrotBagSeed2",
            quantity = 1,
            price = 5
        },
		{
            type = "ITEM",
            target = "Base.BroccoliBagSeed2",
            quantity = 1,
            price = 5
        },
		{
            type = "ITEM",
            target = "Base.RedRadishBagSeed2",
            quantity = 1,
            price = 5
        },
		{
            type = "ITEM",
            target = "Base.StrewberrieBagSeed2",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.TomatoBagSeed2",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.PotatoBagSeed2",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.CabbageBagSeed2",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.BarleyBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.CornBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.KaleBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.RyeBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.SweetPotatoBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.GreenpeasBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.OnionBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.GarlicBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.SoybeansBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.SugarBeetBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.WheatBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.BasilBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.ChamomileBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.ChivesBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.CilantroBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.MarigoldBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.OreganoBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.ParsleyBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.SageBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.RosemaryBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.ThymeBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.LettuceBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.BellPepperBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.CauliflowerBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.CucumberBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.LeekBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.LemonGrassBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.ZucchiniBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.WatermelonBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.HabaneroBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.JalapenoBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.BlackSageBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.BroadleafPlantainBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.ComfreyBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.CommonMallowBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.HempBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.HopsBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.MintBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.TurnipBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.WatermelonBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.WildGarlicBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.PumpkinBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.FlaxBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.SpinachBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.TobaccoBagSeed",
            quantity = 1,
            price = 5
        },
        {
            type = "ITEM",
            target = "Base.SunflowerBagSeed",
            quantity = 1,
            price = 5
        }
    }
}
]]
        local writer = getFileWriter(path, true, false)
        if writer then
            writer:write(defaultContent)
            writer:close()
        end

        ShopItems = loadstring(defaultContent)()
        DebugPrintFactionsEconomy("Shop items file created with default content")
    else
        ShopItems = loadstring(table.concat(lines, "\n"))() or { ["missing"] = {} }
        DebugPrintFactionsEconomy("Shop items has been loaded")
    end
end

-- args.rowIndex, example: 1,2,3
-- args.rowId, example: "survival", "farming"
local function buyItem(module, command, player, args)
    local rowId = args.rowId;
    local index = args.rowIndex;

    local category = ShopItems[rowId]
    if not category then
        DebugPrintFactionsEconomy("Row not found: " .. tostring(rowId) .. ", for player: " .. player:getUsername());
        return
    end

    --type
    --target
    --quantity
    --price
    local item = category[index]
    if not item then
        DebugPrintFactionsEconomy("Item not found on index: " .. tostring(index) .. ", for player: " .. player:getUsername());
        return
    end

    if item.type == "ITEM" then
        -- No currency registered for the player
        if not FactionsEconomyCurrencyData[player:getUsername()] then
            DebugPrintFactionsEconomy("No currency registered for player: " .. player:getUsername());
            return
        end

        -- Check if player have currency available to buy the item
        if FactionsEconomyCurrencyData[player:getUsername()] >= item.price then
            FactionsEconomyCurrencyData[player:getUsername()] = FactionsEconomyCurrencyData[player:getUsername()] -
                item.price;

            DebugPrintFactionsEconomy(player:getUsername() ..
                ", bought: " .. item.target .. " for " .. item.price);

            player:getInventory():AddItems(item.target, item.quantity);
        else -- Nope
            DebugPrintFactionsEconomy("Not enough currency for player: " ..
                player:getUsername() .. ", " .. FactionsEconomyCurrencyData[player:getUsername()] .. "/" .. item.price);
            return
        end
    end
end

local function getShopItems(module, command, player, args)
    sendServerCommand(player, "FactionsEconomyShop", "receiveShopItems",
        ShopItems)
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "FactionsEconomyShop" and command == "buyItem" then
        buyItem(module, command, player, args);
    elseif module == "FactionsEconomyShop" and command == "getShopItems" then
        getShopItems(module, command, player, args);
    end
end)

LoadShopItems();
