-- Cache for player inventories
local PlayerInventories = {}

-- Get item from player inventory
function GetPlayerItem(source, itemName)
    -- Check if using ox_inventory
    if Config.UseOxInventory then
        local count = exports.ox_inventory:GetItem(source, itemName, nil, true)
        return count or 0
    else
        -- ESX inventory
        local xPlayer = ESX.GetPlayerFromId(source)
        
        if xPlayer.getInventoryItem then
            local item = xPlayer.getInventoryItem(itemName)
            return item and item.count or 0
        end
        
        return 0
    end
end

-- Add item to player inventory
function AddItemToPlayer(source, itemName, count, metadata)
    -- Check if using ox_inventory
    if Config.UseOxInventory then
        return exports.ox_inventory:AddItem(source, itemName, count, metadata)
    else
        -- ESX inventory
        local xPlayer = ESX.GetPlayerFromId(source)
        
        if xPlayer.addInventoryItem then
            return xPlayer.addInventoryItem(itemName, count)
        end
        
        return false
    end
end

-- Remove item from player inventory
function RemoveItemFromPlayer(source, itemName, count, metadata)
    -- Check if using ox_inventory
    if Config.UseOxInventory then
        return exports.ox_inventory:RemoveItem(source, itemName, count, metadata)
    else
        -- ESX inventory
        local xPlayer = ESX.GetPlayerFromId(source)
        
        if xPlayer.removeInventoryItem then
            return xPlayer.removeInventoryItem(itemName, count)
        end
        
        return false
    end
end

-- Check if player can carry item
function CanPlayerCarryItem(source, itemName, count)
    -- Check if using ox_inventory
    if Config.UseOxInventory then
        return exports.ox_inventory:CanCarryItem(source, itemName, count)
    else
        -- ESX inventory
        local xPlayer = ESX.GetPlayerFromId(source)
        
        if xPlayer.canCarryItem then
            return xPlayer.canCarryItem(itemName, count)
        end
        
        -- If canCarryItem is not available, check weight system
        if xPlayer.getWeight and xPlayer.getMaxWeight then
            local item = xPlayer.getInventoryItem(itemName)
            if not item then return false end
            
            local weight = item.weight * count
            return (xPlayer.getWeight() + weight) <= xPlayer.getMaxWeight()
        end
        
        return true
    end
end

-- Get all items with their metadata
function GetAllItems()
    -- Check if using ox_inventory
    if Config.UseOxInventory then
        return exports.ox_inventory:Items()
    else
        -- ESX inventory - this is a simplified version, actual implementation would depend on ESX version
        return ESX.Items
    end
end

-- Get item label
function GetItemLabel(itemName)
    -- Check if using ox_inventory
    if Config.UseOxInventory then
        local item = exports.ox_inventory:Items()[itemName]
        return item and item.label or itemName
    else
        -- ESX inventory
        return ESX.GetItemLabel(itemName) or itemName
    end
end

-- Handle item customization
function HandleItemCustomization(source, itemName, options)
    if not Config.UseItemMetadata or not Config.CustomizableItems[itemName] then
        return nil
    end
    
    local itemConfig = Config.CustomizableItems[itemName]
    local metadata = {customized = true}
    local extraPrice = 0
    
    -- Process each option category (ingredients, extras, etc)
    for category, items in pairs(itemConfig.options) do
        metadata[category] = {}
        
        for _, option in pairs(options[category] or {}) do
            for _, availableOption in pairs(items) do
                if option == availableOption.name then
                    table.insert(metadata[category], option)
                    extraPrice = extraPrice + availableOption.price
                    break
                end
            end
        end
    end
    
    -- If no customizations were added, return nil
    if not next(metadata.customized) then
        return nil, 0
    end
    
    return metadata, extraPrice
end