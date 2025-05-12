-- Register callbacks
function RegisterShopCallbacks()
    -- Get all shops
    ESX.RegisterServerCallback('esx_advanced_shops:getAllShops', function(source, cb)
        cb(GetAllShops())
    end)
    
    -- Get available shops for purchase
    ESX.RegisterServerCallback('esx_advanced_shops:getAvailableShops', function(source, cb)
        cb(GetAvailableShops())
    end)
    
    -- Get shop by ID
    ESX.RegisterServerCallback('esx_advanced_shops:getShopData', function(source, cb, shopId)
        cb(GetShopById(shopId))
    end)
    
    -- Get shop items
    ESX.RegisterServerCallback('esx_advanced_shops:getShopItems', function(source, cb, shopId)
        local items = GetShopItems(shopId)
        
        -- Add item labels
        for i = 1, #items do
            items[i].label = GetItemLabel(items[i].name)
        end
        
        cb(items)
    end)
    
    -- Get shop owned by player
    ESX.RegisterServerCallback('esx_advanced_shops:getOwnedShop', function(source, cb, shopId)
        local xPlayer = ESX.GetPlayerFromId(source)
        local shop = GetShopById(shopId)
        
        if shop and shop.owner == xPlayer.identifier then
            cb(shop)
        else
            cb(nil)
        end
    end)
    
    -- Check if player is shop employee
    ESX.RegisterServerCallback('esx_advanced_shops:isShopEmployee', function(source, cb, shopId)
        local xPlayer = ESX.GetPlayerFromId(source)
        local isEmployee, grade = IsShopEmployee(shopId, xPlayer.identifier)
        
        cb(isEmployee, grade)
    end)
    
    -- Get shop finances
    ESX.RegisterServerCallback('esx_advanced_shops:getFinances', function(source, cb, shopId)
        local xPlayer = ESX.GetPlayerFromId(source)
        local shop = GetShopById(shopId)
        
        -- Check if player is owner or manager
        if not shop or (shop.owner ~= xPlayer.identifier and not IsManager(source, shopId)) then
            cb(nil)
            return
        end
        
        cb(GetShopFinances(shopId))
    end)
    
    -- Get shop employees
    ESX.RegisterServerCallback('esx_advanced_shops:getEmployees', function(source, cb, shopId)
        local xPlayer = ESX.GetPlayerFromId(source)
        local shop = GetShopById(shopId)
        
        -- Check if player is owner
        if not shop or shop.owner ~= xPlayer.identifier then
            cb({})
            return
        end
        
        cb(GetShopEmployees(shopId))
    end)
    
    -- Get nearby players for employee management
    ESX.RegisterServerCallback('esx_advanced_shops:getNearbyPlayers', function(source, cb)
        local xPlayer = ESX.GetPlayerFromId(source)
        local players = ESX.GetPlayers()
        local nearby = {}
        
        for i = 1, #players do
            local targetId = players[i]
            local targetPlayer = ESX.GetPlayerFromId(targetId)
            
            if targetPlayer and targetId ~= source then
                table.insert(nearby, {
                    id = targetId,
                    identifier = targetPlayer.identifier,
                    name = GetPlayerName(targetId)
                })
            end
        end
        
        cb(nearby)
    end)
    
    -- Get addable items
    ESX.RegisterServerCallback('esx_advanced_shops:getAddableItems', function(source, cb, shopId, category)
        local xPlayer = ESX.GetPlayerFromId(source)
        local shop = GetShopById(shopId)
        
        -- Check if player is owner or manager
        if not shop or (shop.owner ~= xPlayer.identifier and not IsManager(source, shopId)) then
            cb({})
            return
        end
        
        -- Get current shop items
        local shopItems = GetShopItems(shopId)
        local currentItems = {}
        
        for i = 1, #shopItems do
            currentItems[shopItems[i].name] = true
        end
        
        -- Get all available items
        local items = GetAllItems()
        local addableItems = {}
        
        -- Filter items by category and check if already in shop
        for name, item in pairs(items) do
            if not currentItems[name] and IsItemInCategory(name, category) then
                local price = GetDefaultItemPrice(name, category)
                
                table.insert(addableItems, {
                    name = name,
                    label = item.label or GetItemLabel(name),
                    price = price,
                    type = item.type or 'item'
                })
            end
        end
        
        cb(addableItems)
    end)
    
    -- Get orderable items
    ESX.RegisterServerCallback('esx_advanced_shops:getOrderableItems', function(source, cb, shopId, category)
        local xPlayer = ESX.GetPlayerFromId(source)
        local shop = GetShopById(shopId)
        
        -- Check if player is owner or manager
        if not shop or (shop.owner ~= xPlayer.identifier and not IsManager(source, shopId)) then
            cb({})
            return
        end
        
        -- Get all items from this category
        local categoryItems = Config.DefaultItems[category] or {}
        local orderableItems = {}
        
        for i = 1, #categoryItems do
            local item = categoryItems[i]
            
            table.insert(orderableItems, {
                name = item.name,
                label = GetItemLabel(item.name),
                price = item.price * 0.8, -- Default supplier price is 80% of retail
                maxStock = item.maxStock
            })
        end
        
        cb(orderableItems)
    end)
    
    -- Get item max stock
    ESX.RegisterServerCallback('esx_advanced_shops:getItemMaxStock', function(source, cb, shopId, itemName)
        local xPlayer = ESX.GetPlayerFromId(source)
        local shop = GetShopById(shopId)
        
        -- Check if player is owner or manager
        if not shop or (shop.owner ~= xPlayer.identifier and not IsManager(source, shopId)) then
            cb(0, 0)
            return
        end
        
        -- Get item stock info
        local item = MySQL.query.await("SELECT stock, max_stock FROM shop_items WHERE shop_id = ? AND name = ?", {
            shopId,
            itemName
        })
        
        if item[1] then
            cb(item[1].stock, item[1].max_stock)
        else
            -- Item doesn't exist, check category defaults
            local categoryItems = Config.DefaultItems[shop.category] or {}
            local maxStock = 20 -- Default if not found
            
            for i = 1, #categoryItems do
                if categoryItems[i].name == itemName then
                    maxStock = categoryItems[i].maxStock
                    break
                end
            end
            
            cb(0, maxStock)
        end
    end)
    
    -- Get inventory item count
    ESX.RegisterServerCallback('esx_advanced_shops:getInventoryItem', function(source, cb, itemName)
        cb(GetPlayerItem(source, itemName))
    end)
    
    -- Check if shop can be robbed
    ESX.RegisterServerCallback('esx_advanced_shops:checkRobberyCooldown', function(source, cb, shopId)
        cb(CanShopBeRobbed(shopId))
    end)
    
    -- Get shop money for robbery
    ESX.RegisterServerCallback('esx_advanced_shops:getShopMoney', function(source, cb, shopId)
        local shop = GetShopById(shopId)
        
        if shop then
            cb(shop.money)
        else
            cb(0)
        end
    end)
    
    -- Get police count
    ESX.RegisterServerCallback('esx_advanced_shops:getPoliceCount', function(source, cb)
        local policeCount = 0
        local players = ESX.GetPlayers()
        
        for i = 1, #players do
            local player = ESX.GetPlayerFromId(players[i])
            
            if player.job.name == 'police' then
                policeCount = policeCount + 1
            end
        end
        
        cb(policeCount)
    end)
end

-- Check if player is shop manager
function IsManager(source, shopId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local isEmployee, grade = IsShopEmployee(shopId, xPlayer.identifier)
    
    return isEmployee and grade >= 2
end

-- Check if item is in category
function IsItemInCategory(itemName, category)
    if not category or not Config.DefaultItems[category] then
        return true -- If no category specified or category not found, allow all items
    end
    
    local categoryItems = Config.DefaultItems[category]
    
    for i = 1, #categoryItems do
        if categoryItems[i].name == itemName then
            return true
        end
    end
    
    -- Weapons are special case, check if it starts with WEAPON_
    if category == 'weapons' and string.find(itemName, 'WEAPON_') == 1 then
        return true
    end
    
    return false
end

-- Get default item price
function GetDefaultItemPrice(itemName, category)
    if not category or not Config.DefaultItems[category] then
        return 100 -- Default price if category not found
    end
    
    local categoryItems = Config.DefaultItems[category]
    
    for i = 1, #categoryItems do
        if categoryItems[i].name == itemName then
            return categoryItems[i].price
        end
    end
    
    return 100 -- Default price if item not found in category
end