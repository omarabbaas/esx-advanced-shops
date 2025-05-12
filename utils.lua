-- Cache variables to optimize performance
local ESX = nil
local PlayerData = {}
local ShopBlips = {}
local isInMarker = false
local currentZone = nil
local hasAlreadyEnteredMarker = false
local isShopOpen = false 
local insideOwnedShop = false
local canOpenShopMenu = true
local isRobbingShop = false
local currentActionData = {}

-- Define key mappings
local Keys = {
    ['ESC'] = 322, ['F1'] = 288, ['F2'] = 289, ['F3'] = 170, ['F5'] = 166, ['F6'] = 167, ['F7'] = 168, ['F8'] = 169, ['F9'] = 56, ['F10'] = 57,
    ['~'] = 243, ['1'] = 157, ['2'] = 158, ['3'] = 160, ['4'] = 164, ['5'] = 165, ['6'] = 159, ['7'] = 161, ['8'] = 162, ['9'] = 163, ['-'] = 84, ['='] = 83, ['BACKSPACE'] = 177,
    ['TAB'] = 37, ['Q'] = 44, ['W'] = 32, ['E'] = 38, ['R'] = 45, ['T'] = 245, ['Y'] = 246, ['U'] = 303, ['P'] = 199, ['['] = 39, [']'] = 40, ['ENTER'] = 18,
    ['CAPS'] = 137, ['A'] = 34, ['S'] = 8, ['D'] = 9, ['F'] = 23, ['G'] = 47, ['H'] = 74, ['K'] = 311, ['L'] = 182,
    ['LEFTSHIFT'] = 21, ['Z'] = 20, ['X'] = 73, ['C'] = 26, ['V'] = 0, ['B'] = 29, ['N'] = 249, ['M'] = 244, [','] = 82, ['.'] = 81,
    ['LEFTCTRL'] = 36, ['LEFTALT'] = 19, ['SPACE'] = 22, ['RIGHTCTRL'] = 70,
    ['HOME'] = 213, ['PAGEUP'] = 10, ['PAGEDOWN'] = 11, ['DELETE'] = 178,
    ['LEFT'] = 174, ['RIGHT'] = 175, ['TOP'] = 27, ['DOWN'] = 173,
    ['NENTER'] = 201, ['N4'] = 108, ['N5'] = 60, ['N6'] = 107, ['N+'] = 96, ['N-'] = 97, ['N7'] = 117, ['N8'] = 61, ['N9'] = 118
}

-- Wait for ESX to be ready
Citizen.CreateThread(function()
    while ESX == nil do
        ESX = exports['es_extended']:getSharedObject()
        Citizen.Wait(0)
    end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end

    PlayerData = ESX.GetPlayerData()
    RefreshBlips()
end)

-- Update player data when job changes
RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

-- Refresh blips function
function RefreshBlips()
    for k, v in pairs(ShopBlips) do
        RemoveBlip(v)
    end
    
    ShopBlips = {}
    
    -- Create shop center blip
    local centerBlip = AddBlipForCoord(Config.ShopsCenter.coords)
    SetBlipSprite(centerBlip, Config.ShopsCenter.blip.sprite)
    SetBlipDisplay(centerBlip, 4)
    SetBlipScale(centerBlip, Config.ShopsCenter.blip.scale)
    SetBlipColour(centerBlip, Config.ShopsCenter.blip.color)
    SetBlipAsShortRange(centerBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(TranslateCap('shop_center'))
    EndTextCommandSetBlipName(centerBlip)
    table.insert(ShopBlips, centerBlip)
    
    -- Create blips for owned shops
    ESX.TriggerServerCallback('esx_advanced_shops:getOwnedShops', function(shops)
        for i = 1, #shops do
            local shop = shops[i]
            local category = Config.ShopCategories[shop.category]
            
            if category then
                local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
                SetBlipSprite(blip, category.blip.sprite)
                SetBlipDisplay(blip, 4)
                SetBlipScale(blip, category.blip.scale)
                SetBlipColour(blip, category.blip.color)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(shop.name)
                EndTextCommandSetBlipName(blip)
                table.insert(ShopBlips, blip)
            end
        end
    end)
end

-- Draw 3D text on screen
function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local pX, pY, pZ = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

-- Check if player has required license
function HasLicense(license)
    local hasLicense = false
    
    ESX.TriggerServerCallback('esx_license:checkLicense', function(has)
        hasLicense = has
    end, GetPlayerServerId(PlayerId()), license)
    
    return hasLicense
end

-- Check if player has enough money
function HasEnoughMoney(price, account)
    account = account or 'money'
    
    if account == 'money' then
        return ESX.GetPlayerData().money >= price
    else
        for i = 1, #ESX.GetPlayerData().accounts do
            if ESX.GetPlayerData().accounts[i].name == account then
                return ESX.GetPlayerData().accounts[i].money >= price
            end
        end
    end
    
    return false
end

-- Format money
function FormatMoney(amount)
    local formatted = amount
    
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then
            break
        end
    end
    
    return formatted
end

-- Check if player is in any job
function IsInJob(jobs)
    if type(jobs) == 'string' then
        return PlayerData.job.name == jobs
    elseif type(jobs) == 'table' then
        for i = 1, #jobs do
            if PlayerData.job.name == jobs[i] then
                return true
            end
        end
    end
    
    return false
end

-- Show notification
function ShowNotification(msg)
    if Config.UseOxLib then
        exports.ox_lib:notify({
            title = 'Shop System',
            description = msg,
            type = 'info'
        })
    else
        ESX.ShowNotification(msg)
    end
end

-- Show advanced notification
function ShowAdvancedNotification(title, subject, msg, icon, iconType)
    if Config.UseOxLib then
        exports.ox_lib:notify({
            title = title,
            description = msg,
            type = 'info',
            icon = icon or 'shop'
        })
    else
        ESX.ShowAdvancedNotification(title, subject, msg, icon, iconType)
    end
end

-- Debug logging
function DebugLog(msg)
    if Config.Debug then
        print('[ESX_ADVANCED_SHOPS] [DEBUG]: ' .. msg)
    end
end