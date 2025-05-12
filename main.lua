-- Variables
local shopUpdates = {}
local robberies = {}

-- Initialize
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    
    -- Initialize database
    InitializeShopSystem()
    
    -- Register callbacks
    RegisterShopCallbacks()
    
    -- Start order processing thread
    StartOrderProcessingThread()
    
    print("[^2ESX_ADVANCED_SHOPS^7] Resource started successfully.")
end)

-- Player loaded
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    -- Nothing needed here for now
end)

-- Buy shop
RegisterNetEvent('esx_advanced_shops:buyShop')
AddEventHandler('esx_advanced_shops:buyShop', function(shopId, name, price, paymentMethod)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Check if player has enough money
    local canPay = false
    
    if paymentMethod == 'money' then
        canPay = xPlayer.getMoney() >= price
    else
        canPay = xPlayer.getAccount('bank').money >= price
    end
    
    if not canPay then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_enough_money_shop'))
        return
    end
    
    -- Buy the shop
    local success = BuyShop(shopId, xPlayer.identifier, name, price)
    
    if success then
        -- Remove money
        if paymentMethod == 'money' then
            xPlayer.removeMoney(price)
        else
            xPlayer.removeAccountMoney('bank', price)
        end
        
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('shop_bought', name, FormatMoney(price)))
        TriggerClientEvent('esx_advanced_shops:ownershipChanged', -1)
        
        -- Log purchase
        if Config.WebhookURL ~= "" then
            local message = {
                embeds = {
                    {
                        title = "Shop Purchased",
                        description = GetPlayerName(source) .. " has purchased a shop named " .. name .. " for $" .. FormatMoney(price),
                        color = 3066993,
                        footer = {
                            text = "ESX Advanced Shops • " .. os.date("%Y-%m-%d %H:%M:%S")
                        }
                    }
                }
            }
            
            PerformHttpRequest(Config.WebhookURL, function(err, text, headers) end, 'POST', json.encode(message), { ['Content-Type'] = 'application/json' })
        end
    else
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('already_owned'))
    end
end)

-- Sell shop
RegisterNetEvent('esx_advanced_shops:sellShop')
AddEventHandler('esx_advanced_shops:sellShop', function(shopId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Sell the shop
    local success, sellPrice = SellShop(shopId, xPlayer.identifier)
    
    if success then
        -- Add money
        xPlayer.addMoney(sellPrice)
        
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('shop_sold', FormatMoney(sellPrice)))
        TriggerClientEvent('esx_advanced_shops:ownershipChanged', -1)
        
        -- Log sale
        if Config.WebhookURL ~= "" then
            local message = {
                embeds = {
                    {
                        title = "Shop Sold",
                        description = GetPlayerName(source) .. " has sold a shop for $" .. FormatMoney(sellPrice),
                        color = 15158332,
                        footer = {
                            text = "ESX Advanced Shops • " .. os.date("%Y-%m-%d %H:%M:%S")
                        }
                    }
                }
            }
            
            PerformHttpRequest(Config.WebhookURL, function(err, text, headers) end, 'POST', json.encode(message), { ['Content-Type'] = 'application/json' })
        end
    else
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_owner'))
    end
end)

-- Buy items
RegisterNetEvent('esx_advanced_shops:buyItems')
AddEventHandler('esx_advanced_shops:buyItems', function(shopId, items, paymentMethod)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if #items == 0 then
        return
    end
    
    -- Get shop
    local shop = GetShopById(shopId)
    
    if not shop or not shop.open then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('shop_closed'))
        return
    end
    
    -- Calculate total
    local totalPrice = 0
    
    for i = 1, #items do
        totalPrice = totalPrice + (items[i].price * items[i].amount)
    end
    
    -- Check if player has enough money
    local canPay = false
    
    if paymentMethod == 'money' then
        canPay = xPlayer.getMoney() >= totalPrice
    else
        canPay = xPlayer.getAccount('bank').money >= totalPrice
    end
    
    if not canPay then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_enough_money'))
        return
    end
    
    -- Check shop items and stock
    local shopItems = GetShopItems(shopId)
    local shopItemsMap = {}
    
    for i = 1, #shopItems do
        shopItemsMap[shopItems[i].name] = shopItems[i]
    end
    
    -- Process items
    local purchaseSuccess = true
    local purchasedItems = {}
    
    for i = 1, #items do
        local item = items[i]
        local shopItem = shopItemsMap[item.name]
        
        if not shopItem then
            TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('item_not_available', item.label))
            purchaseSuccess = false
            break
        end
        
        if shopItem.stock < item.amount then
            TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_enough_stock_specific', item.label))
            purchaseSuccess = false
            break
        end
        
        -- Check if player can carry
        if not CanPlayerCarryItem(source, item.name, item.amount) then
            TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('cannot_carry', item.label))
            purchaseSuccess = false
            break
        end
        
        -- Add to purchased items
        table.insert(purchasedItems, {
            name = item.name,
            label = item.label,
            amount = item.amount,
            price = shopItem.price,
            supplierPrice = shopItem.supplier_price
        })
    end
    
    if not purchaseSuccess then
        return
    end
    
    -- Process payment
    if paymentMethod == 'money' then
        xPlayer.removeMoney(totalPrice)
    else
        xPlayer.removeAccountMoney('bank', totalPrice)
    end
    
    -- Process items
    for i = 1, #purchasedItems do
        local item = purchasedItems[i]
        
        -- Remove from stock
        local newStock = shopItemsMap[item.name].stock - item.amount
        UpdateItemStock(shopId, item.name, newStock)
        
        -- Add to player inventory
        AddItemToPlayer(source, item.name, item.amount)
        
        -- Add transaction record
        AddShopTransaction(shopId, xPlayer.identifier, item.name, item.amount, item.price, item.supplierPrice)
        
        -- Add shop money
        if shop.owner then
            local shopMoney = shop.money + (item.price * item.amount)
            UpdateShopMoney(shopId, shopMoney)
        end
        
        -- Show notification
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('purchase_success', item.label, item.amount, FormatMoney(item.price * item.amount)))
    end
    
    -- Notify shop owner if online
    if shop.owner then
        local owner = ESX.GetPlayerFromIdentifier(shop.owner)
        
        if owner then
            TriggerClientEvent('esx_advanced_shops:showNotification', owner.source, _U('sale_made', FormatMoney(totalPrice)))
        end
    end
    
    -- Update shop menu
    TriggerClientEvent('esx_advanced_shops:shopStockUpdated', -1, shopId)
end)

-- Buy single item
RegisterNetEvent('esx_advanced_shops:buyItem')
AddEventHandler('esx_advanced_shops:buyItem', function(shopId, itemName, amount, price)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Get shop
    local shop = GetShopById(shopId)
    
    if not shop or not shop.open then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('shop_closed'))
        return
    end
    
    -- Calculate total
    local totalPrice = price * amount
    
    -- Check if player has enough money
    if xPlayer.getMoney() < totalPrice then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_enough_money'))
        return
    end
    
    -- Check shop item and stock
    local shopItems = GetShopItems(shopId)
    local shopItem = nil
    
    for i = 1, #shopItems do
        if shopItems[i].name == itemName then
            shopItem = shopItems[i]
            break
        end
    end
    
    if not shopItem then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('item_not_available', GetItemLabel(itemName)))
        return
    end
    
    if shopItem.stock < amount then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_enough_stock'))
        return
    end
    
    -- Check if player can carry
    if not CanPlayerCarryItem(source, itemName, amount) then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('cannot_carry', GetItemLabel(itemName)))
        return
    end
    
    -- Process payment
    xPlayer.removeMoney(totalPrice)
    
    -- Remove from stock
    local newStock = shopItem.stock - amount
    UpdateItemStock(shopId, itemName, newStock)
    
    -- Add to player inventory
    AddItemToPlayer(source, itemName, amount)
    
    -- Add transaction record
    AddShopTransaction(shopId, xPlayer.identifier, itemName, amount, shopItem.price, shopItem.supplier_price)
    
    -- Add shop money
    if shop.owner then
        local shopMoney = shop.money + totalPrice
        UpdateShopMoney(shopId, shopMoney)
    end
    
    -- Show notification
    TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('purchase_success', GetItemLabel(itemName), amount, FormatMoney(totalPrice)))
    
    -- Notify shop owner if online
    if shop.owner then
        local owner = ESX.GetPlayerFromIdentifier(shop.owner)
        
        if owner then
            TriggerClientEvent('esx_advanced_shops:showNotification', owner.source, _U('sale_made', FormatMoney(totalPrice)))
        end
    end
    
    -- Update shop menu
    TriggerClientEvent('esx_advanced_shops:shopStockUpdated', -1, shopId)
end)

-- Update item price
RegisterNetEvent('esx_advanced_shops:updateItemPrice')
AddEventHandler('esx_advanced_shops:updateItemPrice', function(shopId, itemName, price)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Check if player is owner or manager
    local shop = GetShopById(shopId)
    
    if not shop or (shop.owner ~= xPlayer.identifier and not IsManager(source, shopId)) then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_owner'))
        return
    end
    
    -- Update price
    local success = UpdateItemPrice(shopId, itemName, price)
    
    if success then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('price_updated', FormatMoney(price)))
        TriggerClientEvent('esx_advanced_shops:shopStockUpdated', -1, shopId)
    else
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('update_failed'))
    end
end)

-- Add item stock
RegisterNetEvent('esx_advanced_shops:addItemStock')
AddEventHandler('esx_advanced_shops:addItemStock', function(shopId, itemName, amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Check if player is owner or manager
    local shop = GetShopById(shopId)
    
    if not shop or (shop.owner ~= xPlayer.identifier and not IsManager(source, shopId)) then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_owner'))
        return
    end
    
    -- Check if player has the item
    local playerItemCount = GetPlayerItem(source, itemName)
    
    if playerItemCount < amount then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_enough_items'))
        return
    end
    
    -- Get current stock and max stock
    local shopItems = GetShopItems(shopId)
    local currentStock = 0
    local maxStock = 50
    
    for i = 1, #shopItems do
        if shopItems[i].name == itemName then
            currentStock = shopItems[i].stock
            maxStock = shopItems[i].max_stock
            break
        end
    end
    
    -- Check if adding would exceed max stock
    if currentStock + amount > maxStock then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('stock_would_exceed_max'))
        return
    end
    
    -- Remove from player
    RemoveItemFromPlayer(source, itemName, amount)
    
    -- Add to shop stock
    local newStock = currentStock + amount
    UpdateItemStock(shopId, itemName, newStock)
    
    TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('stock_added', amount, GetItemLabel(itemName)))
    TriggerClientEvent('esx_advanced_shops:shopStockUpdated', -1, shopId)
end)

-- Remove item stock
RegisterNetEvent('esx_advanced_shops:removeItemStock')
AddEventHandler('esx_advanced_shops:removeItemStock', function(shopId, itemName, amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Check if player is owner or manager
    local shop = GetShopById(shopId)
    
    if not shop or (shop.owner ~= xPlayer.identifier and not IsManager(source, shopId)) then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_owner'))
        return
    end
    
    -- Get current stock
    local shopItems = GetShopItems(shopId)
    local currentStock = 0
    
    for i = 1, #shopItems do
        if shopItems[i].name == itemName then
            currentStock = shopItems[i].stock
            break
        end
    end
    
    -- Check if there's enough stock
    if currentStock < amount then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_enough_stock'))
        return
    end
    
    -- Check if player can carry the item
    if not CanPlayerCarryItem(source, itemName, amount) then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('cannot_carry', GetItemLabel(itemName)))
        return
    end
    
    -- Remove from shop stock
    local newStock = currentStock - amount
    UpdateItemStock(shopId, itemName, newStock)
    
    -- Add to player inventory
    AddItemToPlayer(source, itemName, amount)
    
    TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('stock_removed', amount, GetItemLabel(itemName)))
    TriggerClientEvent('esx_advanced_shops:shopStockUpdated', -1, shopId)
end)

-- Add new item to shop
RegisterNetEvent('esx_advanced_shops:addNewItem')
AddEventHandler('esx_advanced_shops:addNewItem', function(shopId, itemName, price, maxStock, supplierPrice)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Check if player is owner
    local shop = GetShopById(shopId)
    
    if not shop or shop.owner ~= xPlayer.identifier then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_owner'))
        return
    end
    
    -- Add item
    local success = AddNewItem(shopId, itemName, price, maxStock, supplierPrice or math.floor(price * 0.8))
    
    if success then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('item_added', GetItemLabel(itemName)))
        TriggerClientEvent('esx_advanced_shops:shopStockUpdated', -1, shopId)
    else
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('item_already_exists'))
    end
end)

-- Remove item from shop
RegisterNetEvent('esx_advanced_shops:removeItem')
AddEventHandler('esx_advanced_shops:removeItem', function(shopId, itemName)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Check if player is owner
    local shop = GetShopById(shopId)
    
    if not shop or shop.owner ~= xPlayer.identifier then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_owner'))
        return
    end
    
    -- Remove item
    local success = RemoveItem(shopId, itemName)
    
    if success then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('item_removed', GetItemLabel(itemName)))
        TriggerClientEvent('esx_advanced_shops:shopStockUpdated', -1, shopId)
    else
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('item_not_found'))
    end
end)

-- Withdraw money from shop
RegisterNetEvent('esx_advanced_shops:withdrawMoney')
AddEventHandler('esx_advanced_shops:withdrawMoney', function(shopId, amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Check if player is owner
    local shop = GetShopById(shopId)
    
    if not shop or shop.owner ~= xPlayer.identifier then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_owner'))
        return
    end
    
    -- Check if shop has enough money
    if shop.money < amount then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_enough_shop_money'))
        return
    end
    
    -- Update shop money
    local newMoney = shop.money - amount
    UpdateShopMoney(shopId, newMoney)
    
    -- Add money to player
    xPlayer.addMoney(amount)
    
    TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('money_withdrawn', FormatMoney(amount)))
end)

-- Deposit money to shop
RegisterNetEvent('esx_advanced_shops:depositMoney')
AddEventHandler('esx_advanced_shops:depositMoney', function(shopId, amount)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Check if player is owner
    local shop = GetShopById(shopId)
    
    if not shop or shop.owner ~= xPlayer.identifier then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_owner'))
        return
    end
    
    -- Check if player has enough money
    if xPlayer.getMoney() < amount then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_enough_money'))
        return
    end
    
    -- Remove money from player
    xPlayer.removeMoney(amount)
    
    -- Update shop money
    local newMoney = shop.money + amount
    UpdateShopMoney(shopId, newMoney)
    
    TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('money_deposited', FormatMoney(amount)))
end)

-- Order item from supplier
RegisterNetEvent('esx_advanced_shops:orderItem')
AddEventHandler('esx_advanced_shops:orderItem', function(shopId, itemName, amount, price)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Check if player is owner or manager
    local shop = GetShopById(shopId)
    
    if not shop or (shop.owner ~= xPlayer.identifier and not IsManager(source, shopId)) then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_owner'))
        return
    end
    
    -- Check if shop has enough money
    local totalCost = amount * price
    
    if shop.money < totalCost then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_enough_shop_money'))
        return
    end
    
    -- Update shop money
    local newMoney = shop.money - totalCost
    UpdateShopMoney(shopId, newMoney)
    
    -- Create the order
    local success, deliveryTime = CreateShopOrder(shopId, itemName, amount, price)
    
    if success then
        -- Calculate delivery time
        local minutes = math.ceil((deliveryTime - os.time()) / 60)
        
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('order_placed', minutes))
    else
        -- Refund the money
        UpdateShopMoney(shopId, shop.money)
        
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('order_failed'))
    end
end)

-- Add employee
RegisterNetEvent('esx_advanced_shops:addEmployee')
AddEventHandler('esx_advanced_shops:addEmployee', function(shopId, identifier, name, grade)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Check if player is owner
    local shop = GetShopById(shopId)
    
    if not shop or shop.owner ~= xPlayer.identifier then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_owner'))
        return
    end
    
    -- Add employee
    local success = AddShopEmployee(shopId, identifier, name, grade)
    
    if success then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('employee_added'))
    else
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('already_employee'))
    end
end)

-- Update employee grade
RegisterNetEvent('esx_advanced_shops:updateEmployeeGrade')
AddEventHandler('esx_advanced_shops:updateEmployeeGrade', function(shopId, identifier, grade)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Check if player is owner
    local shop = GetShopById(shopId)
    
    if not shop or shop.owner ~= xPlayer.identifier then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_owner'))
        return
    end
    
    -- Update employee grade
    local success = UpdateEmployeeGrade(shopId, identifier, grade)
    
    if success then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('employee_updated'))
    else
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_employee'))
    end
end)

-- Remove employee
RegisterNetEvent('esx_advanced_shops:removeEmployee')
AddEventHandler('esx_advanced_shops:removeEmployee', function(shopId, identifier)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Check if player is owner
    local shop = GetShopById(shopId)
    
    if not shop or shop.owner ~= xPlayer.identifier then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_owner'))
        return
    end
    
    -- Remove employee
    local success = RemoveShopEmployee(shopId, identifier)
    
    if success then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('employee_removed'))
    else
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_employee'))
    end
end)

-- Update shop name
RegisterNetEvent('esx_advanced_shops:updateShopName')
AddEventHandler('esx_advanced_shops:updateShopName', function(shopId, name)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Check if player is owner
    local shop = GetShopById(shopId)
    
    if not shop or shop.owner ~= xPlayer.identifier then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_owner'))
        return
    end
    
    -- Update shop name
    local success = UpdateShopName(shopId, name)
    
    if success then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('shop_name_updated'))
        TriggerClientEvent('esx_advanced_shops:ownershipChanged', -1)
    else
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('update_failed'))
    end
end)

-- Update blip color
RegisterNetEvent('esx_advanced_shops:updateBlipColor')
AddEventHandler('esx_advanced_shops:updateBlipColor', function(shopId, color)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Check if player is owner
    local shop = GetShopById(shopId)
    
    if not shop or shop.owner ~= xPlayer.identifier then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_owner'))
        return
    end
    
    -- Update blip color
    local success = UpdateShopBlipColor(shopId, color)
    
    if success then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('blip_color_updated'))
        TriggerClientEvent('esx_advanced_shops:ownershipChanged', -1)
    else
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('update_failed'))
    end
end)

-- Set shop open/closed status
RegisterNetEvent('esx_advanced_shops:setShopStatus')
AddEventHandler('esx_advanced_shops:setShopStatus', function(shopId, isOpen)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Check if player is owner
    local shop = GetShopById(shopId)
    
    if not shop or shop.owner ~= xPlayer.identifier then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('not_owner'))
        return
    end
    
    -- Update shop status
    local success = UpdateShopStatus(shopId, isOpen)
    
    if success then
        if isOpen then
            TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('shop_opened'))
        else
            TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('shop_closed'))
        end
        
        TriggerClientEvent('esx_advanced_shops:shopStatusChanged', -1, shopId, isOpen)
    else
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('update_failed'))
    end
end)

-- Start robbery
RegisterNetEvent('esx_advanced_shops:startRobbery')
AddEventHandler('esx_advanced_shops:startRobbery', function(shopId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local shop = GetShopById(shopId)
    
    if not shop then
        return
    end
    
    -- Check if shop can be robbed
   if not CanShopBeRobbed(shopId) then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('cooldown_active'))
        return
    end
    
    -- Check if there's enough police
    local policeCount = 0
    local xPlayers = ESX.GetPlayers()
    
    for i = 1, #xPlayers do
        local xTarget = ESX.GetPlayerFromId(xPlayers[i])
        
        if xTarget.job.name == 'police' then
            policeCount = policeCount + 1
        end
    end
    
    if policeCount < Config.MinPoliceForRobbery then
        TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('min_police', Config.MinPoliceForRobbery))
        return
    end
    
    -- Add to active robberies
    robberies[shopId] = {
        robber = source,
        startTime = os.time(),
        shopMoney = shop.money
    }
    
    -- Update last robbed time
    UpdateShopLastRobbed(shopId)
    
    -- Notify police
    for i = 1, #xPlayers do
        local xTarget = ESX.GetPlayerFromId(xPlayers[i])
        
        if xTarget.job.name == 'police' then
            TriggerClientEvent('esx_advanced_shops:showNotification', xTarget.source, _U('police_notify', shop.name))
            
            -- Add blip for police
            TriggerClientEvent('esx_advanced_shops:addRobberyBlip', xTarget.source, shopId, shop.coords)
        end
    end
    
    -- Notify shop owner if online
    if shop.owner then
        local owner = ESX.GetPlayerFromIdentifier(shop.owner)
        
        if owner then
            TriggerClientEvent('esx_advanced_shops:showNotification', owner.source, _U('shop_being_robbed', shop.name))
        end
    end
    
    -- Log robbery
    if Config.WebhookURL ~= "" then
        local message = {
            embeds = {
                {
                    title = "Shop Robbery Started",
                    description = GetPlayerName(source) .. " has started robbing " .. shop.name,
                    color = 15158332,
                    footer = {
                        text = "ESX Advanced Shops • " .. os.date("%Y-%m-%d %H:%M:%S")
                    }
                }
            }
        }
        
        PerformHttpRequest(Config.WebhookURL, function(err, text, headers) end, 'POST', json.encode(message), { ['Content-Type'] = 'application/json' })
    end
end)

-- Cancel robbery
RegisterNetEvent('esx_advanced_shops:cancelRobbery')
AddEventHandler('esx_advanced_shops:cancelRobbery', function(shopId)
    local source = source
    
    if not robberies[shopId] or robberies[shopId].robber ~= source then
        return
    end
    
    -- Remove from active robberies
    robberies[shopId] = nil
    
    -- Notify police
    local xPlayers = ESX.GetPlayers()
    
    for i = 1, #xPlayers do
        local xTarget = ESX.GetPlayerFromId(xPlayers[i])
        
        if xTarget.job.name == 'police' then
            TriggerClientEvent('esx_advanced_shops:showNotification', xTarget.source, _U('robbery_cancelled'))
            TriggerClientEvent('esx_advanced_shops:removeRobberyBlip', xTarget.source, shopId)
        end
    end
end)

-- Complete robbery
RegisterNetEvent('esx_advanced_shops:completeRobbery')
AddEventHandler('esx_advanced_shops:completeRobbery', function(shopId)
    local source = source
    
    if not robberies[shopId] or robberies[shopId].robber ~= source then
        return
    end
    
    local robbery = robberies[shopId]
    local shop = GetShopById(shopId)
    
    if not shop then
        return
    end
    
    -- Calculate payout based on shop size and money
    local basePayout = Config.RobberyBasePayout
    local multiplier = Config.RobberyPayoutMultiplier[shop.size] or 1.0
    local shopMoney = robbery.shopMoney
    
    -- Calculate robbery success chance
    local robberyTime = os.time() - robbery.startTime
    local minTime = Config.RobberyDuration.min
    local maxTime = Config.RobberyDuration.max
    local successChance = (robberyTime - minTime) / (maxTime - minTime)
    
    if successChance < 0.3 then
        -- Robbery was too quick, lower payout
        multiplier = multiplier * 0.5
    end
    
    -- Calculate final payout
    local payout = math.floor(basePayout * multiplier)
    
    -- Add money to robber
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.addAccountMoney('black_money', payout)
    
    -- Update shop money (take half of the money from shop)
    if shop.owner then
        local takenMoney = math.floor(shopMoney * 0.5)
        local newMoney = math.max(0, shop.money - takenMoney)
        UpdateShopMoney(shopId, newMoney)
        
        -- Add to payout
        payout = payout + takenMoney
    end
    
    TriggerClientEvent('esx_advanced_shops:showNotification', source, _U('robbery_complete', FormatMoney(payout)))
    
    -- Remove from active robberies
    robberies[shopId] = nil
    
    -- Notify police
    local xPlayers = ESX.GetPlayers()
    
    for i = 1, #xPlayers do
        local xTarget = ESX.GetPlayerFromId(xPlayers[i])
        
        if xTarget.job.name == 'police' then
            TriggerClientEvent('esx_advanced_shops:showNotification', xTarget.source, _U('robbery_completed', shop.name))
        end
    end
    
    -- Notify shop owner if online
    if shop.owner then
        local owner = ESX.GetPlayerFromIdentifier(shop.owner)
        
        if owner then
            TriggerClientEvent('esx_advanced_shops:showNotification', owner.source, _U('shop_robbed', shop.name, FormatMoney(payout)))
        end
    end
    
    -- Log robbery
    if Config.WebhookURL ~= "" then
        local message = {
            embeds = {
                {
                    title = "Shop Robbery Completed",
                    description = GetPlayerName(source) .. " has completed robbing " .. shop.name .. " and stole $" .. FormatMoney(payout),
                    color = 15158332,
                    footer = {
                        text = "ESX Advanced Shops • " .. os.date("%Y-%m-%d %H:%M:%S")
                    }
                }
            }
        }
        
        PerformHttpRequest(Config.WebhookURL, function(err, text, headers) end, 'POST', json.encode(message), { ['Content-Type'] = 'application/json' })
    end
end)

-- Player died during robbery
AddEventHandler('esx:onPlayerDeath', function(data)
    local source = data.victim
    
    -- Check if player was robbing a shop
    for shopId, robbery in pairs(robberies) do
        if robbery.robber == source then
            -- Cancel robbery
            TriggerEvent('esx_advanced_shops:cancelRobbery', shopId)
            
            -- Notify police
            local xPlayers = ESX.GetPlayers()
            
            for i = 1, #xPlayers do
                local xTarget = ESX.GetPlayerFromId(xPlayers[i])
                
                if xTarget.job.name == 'police' then
                    TriggerClientEvent('esx_advanced_shops:showNotification', xTarget.source, _U('robber_died'))
                    TriggerClientEvent('esx_advanced_shops:removeRobberyBlip', xTarget.source, shopId)
                end
            end
        end
    end
end)

-- Player disconnected during robbery
AddEventHandler('playerDropped', function()
    local source = source
    
    -- Check if player was robbing a shop
    for shopId, robbery in pairs(robberies) do
        if robbery.robber == source then
            -- Cancel robbery
            robberies[shopId] = nil
            
            -- Notify police
            local xPlayers = ESX.GetPlayers()
            
            for i = 1, #xPlayers do
                local xTarget = ESX.GetPlayerFromId(xPlayers[i])
                
                if xTarget.job.name == 'police' then
                    TriggerClientEvent('esx_advanced_shops:showNotification', xTarget.source, _U('robber_left'))
                    TriggerClientEvent('esx_advanced_shops:removeRobberyBlip', xTarget.source, shopId)
                end
            end
        end
    end
end)

-- Order processing thread
function StartOrderProcessingThread()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(60000) -- Check every minute
            
            -- Get pending orders
            local pendingOrders = GetPendingOrders()
            
            for i = 1, #pendingOrders do
                local order = pendingOrders[i]
                
                -- Complete the order
                CompleteShopOrder(order.id, order.shop_id, order.item_name, order.amount)
                
                -- Notify shop owner if online
                local shop = GetShopById(order.shop_id)
                
                if shop and shop.owner then
                    local owner = ESX.GetPlayerFromIdentifier(shop.owner)
                    
                    if owner then
                        TriggerClientEvent('esx_advanced_shops:showNotification', owner.source, _U('order_delivered', order.amount, GetItemLabel(order.item_name)))
                    end
                    
                    -- Notify shop employees if online
                    local employees = GetShopEmployees(order.shop_id)
                    
                    for j = 1, #employees do
                        local employee = ESX.GetPlayerFromIdentifier(employees[j].identifier)
                        
                        if employee and employee.source ~= owner.source then
                            TriggerClientEvent('esx_advanced_shops:showNotification', employee.source, _U('order_delivered', order.amount, GetItemLabel(order.item_name)))
                        end
                    end
                end
                
                -- Update shop menu
                TriggerClientEvent('esx_advanced_shops:shopStockUpdated', -1, order.shop_id)
            end
        end
    end)
end

-- Format money
function FormatMoney(amount)
    local formatted = tostring(amount)
    
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then
            break
        end
    end
    
    return formatted
end