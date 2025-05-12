local robberyActive = false
local robberyTime = 0
local robberyShop = nil
local robberyBlip = nil

-- Start robbery
RegisterNetEvent('esx_advanced_shops:startRobbery')
AddEventHandler('esx_advanced_shops:startRobbery', function(shopId, shop)
    -- Check if player is armed
    local playerPed = PlayerPedId()
    
    if not IsPedArmed(playerPed, 4) then
        ShowNotification(TranslateCap('need_weapon'))
        return
    end
    
    -- Check if minimum police is online
    ESX.TriggerServerCallback('esx_advanced_shops:getPoliceCount', function(policeCount)
        if policeCount < Config.MinPoliceForRobbery then
            ShowNotification(TranslateCap('min_police', Config.MinPoliceForRobbery))
            return
        end
        
        -- Check cooldown
        ESX.TriggerServerCallback('esx_advanced_shops:checkRobberyCooldown', function(canRob)
            if not canRob then
                ShowNotification(TranslateCap('cooldown_active'))
                return
            end
            
            -- Check if shop has money
            ESX.TriggerServerCallback('esx_advanced_shops:getShopMoney', function(money)
                if money <= 0 then
                    ShowNotification(TranslateCap('shop_empty'))
                    return
                end
                
                -- Start robbery
                TriggerServerEvent('esx_advanced_shops:startRobbery', shopId)
                
                -- Set up local variables
                robberyActive = true
                robberyShop = shopId
                robberyTime = math.random(Config.RobberyDuration.min, Config.RobberyDuration.max)
                
                -- Create robbery blip
                local coords = shop.coords
                robberyBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
                SetBlipSprite(robberyBlip, 161)
                SetBlipScale(robberyBlip, 2.0)
                SetBlipColour(robberyBlip, 1)
                PulseBlip(robberyBlip)
                
                -- Start robbery thread
                StartRobberyThread(shop)
            end, shopId)
        end, shopId)
    end)
end)

-- Robbery thread
function StartRobberyThread(shop)
    Citizen.CreateThread(function()
        -- Show notification
        ShowAdvancedNotification(TranslateCap('robbery'), TranslateCap('robbery_started'), TranslateCap('stay_close'), 'CHAR_LESTER', 1)
        
        -- Start robbery animation
        local playerPed = PlayerPedId()
        TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
        
        -- Wait for robbery to complete
        local startTime = GetGameTimer()
        local endTime = startTime + (robberyTime * 1000)
        local lastUpdate = startTime
        local updateInterval = 1000 -- Update every second
        
        while GetGameTimer() < endTime do
            Citizen.Wait(0)
            
            -- Check if player is still in the shop
            local playerCoords = GetEntityCoords(playerPed)
            local shopCoords = vector3(shop.coords.x, shop.coords.y, shop.coords.z)
            local distance = #(playerCoords - shopCoords)
            
            if distance > 5.0 then
                -- Player left the shop, cancel robbery
                TriggerServerEvent('esx_advanced_shops:cancelRobbery', robberyShop)
                ClearPedTasks(playerPed)
                
                if DoesBlipExist(robberyBlip) then
                    RemoveBlip(robberyBlip)
                    robberyBlip = nil
                end
                
                robberyActive = false
                robberyShop = nil
                ShowNotification(TranslateCap('robbery_cancelled'))
                
                return
            end
            
            -- Update timer
            local currentTime = GetGameTimer()
            if currentTime - lastUpdate >= updateInterval then
                lastUpdate = currentTime
                local timeLeft = math.ceil((endTime - currentTime) / 1000)
                ESX.ShowHelpNotification(TranslateCap('robbery_progress', timeLeft))
            end
        end
        
        -- Robbery complete
        if robberyActive then
            TriggerServerEvent('esx_advanced_shops:completeRobbery', robberyShop)
            ClearPedTasks(playerPed)
            
            -- Remove robbery blip after some time
            Citizen.SetTimeout(Config.RobberyBlipDuration * 1000, function()
                if DoesBlipExist(robberyBlip) then
                    RemoveBlip(robberyBlip)
                    robberyBlip = nil
                end
            end)
            
            robberyActive = false
            robberyShop = nil
        end
    end)
end

-- Add robbery blip for police
RegisterNetEvent('esx_advanced_shops:addRobberyBlip')
AddEventHandler('esx_advanced_shops:addRobberyBlip', function(shopId, coords)
    -- Create robbery blip for police
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)
    SetBlipScale(blip, 2.0)
    SetBlipColour(blip, 1)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(TranslateCap('shop_robbery'))
    EndTextCommandSetBlipName(blip)
    PulseBlip(blip)
    
    -- Remove blip after cooldown
    Citizen.SetTimeout(Config.RobberyBlipDuration * 1000, function()
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end)

-- Remove robbery blip for police
RegisterNetEvent('esx_advanced_shops:removeRobberyBlip')
AddEventHandler('esx_advanced_shops:removeRobberyBlip', function(shopId)
    -- Just update blips for simplicity
    RefreshBlips()
end)