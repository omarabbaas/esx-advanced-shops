-- Open shop center for buying shops
function OpenShopCenter()
    ESX.TriggerServerCallback('esx_advanced_shops:getAvailableShops', function(shops)
        if #shops == 0 then
            ShowNotification(TranslateCap('no_shops_available'))
            return
        end
        
        if Config.UseOxLib then
            -- Use ox_lib menu
            local elements = {}
            
            for i = 1, #shops do
                local shop = shops[i]
                local categoryInfo = Config.ShopCategories[shop.category]
                
                table.insert(elements, {
                    title = TranslateCap('shop_name', shop.name),
                    description = TranslateCap('shop_price') .. ': $' .. FormatMoney(shop.price) .. '\n' ..
                                TranslateCap('shop_category') .. ': ' .. categoryInfo.label .. '\n' ..
                                TranslateCap('shop_size') .. ': ' .. TranslateCap(shop.size),
                    icon = 'store',
                    onSelect = function()
                        BuyShop(shop)
                    end
                })
            end
            
            -- Display the menu
            exports.ox_lib:registerContext({
                id = 'shop_center',
                title = TranslateCap('shop_center_title'),
                options = elements
            })
            
            exports.ox_lib:showContext('shop_center')
        else
            -- Use ESX menu
            local elements = {}
            
            for i = 1, #shops do
                local shop = shops[i]
                local categoryInfo = Config.ShopCategories[shop.category]
                
                table.insert(elements, {
                    label = TranslateCap('shop_name', shop.name) .. ' - $' .. FormatMoney(shop.price),
                    shop = shop
                })
            end
            
            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'shop_center', {
                title = TranslateCap('shop_center_title'),
                align = 'top-left',
                elements = elements
            }, function(data, menu)
                local shop = data.current.shop
                BuyShop(shop)
            end, function(data, menu)
                menu.close()
            end)
        end
    end)
end

-- Buy a shop
function BuyShop(shop)
    -- Check if the category has job restrictions
    local categoryInfo = Config.ShopCategories[shop.category]
    if categoryInfo.jobRestricted and not IsInJob(categoryInfo.allowedJobs) then
        ShowNotification(TranslateCap('job_restriction'))
        return
    end
    
    -- Check if the player has the required license
    if categoryInfo.license and not HasLicense(categoryInfo.license) then
        ShowNotification(TranslateCap('weapon_license_required'))
        return
    end
    
    -- Ask for shop name
    exports.ox_lib:dialog({
        id = 'shop_name_dialog',
        title = TranslateCap('enter_shop_name'),
        options = {
            {
                type = 'input',
                label = TranslateCap('shop_name_label'),
                default = shop.name,
                required = true
            }
        }
    }, function(data)
        if data then
            local shopName = data[1]
            
            if string.len(shopName) < 3 or string.len(shopName) > 30 then
                ShowNotification(TranslateCap('invalid_name'))
                return
            end
            
            -- Ask for payment method
            exports.ox_lib:dialog({
                id = 'payment_method_dialog',
                title = TranslateCap('payment_method'),
                options = {
                    {
                        type = 'select',
                        label = TranslateCap('payment_method'),
                        options = {
                            { label = TranslateCap('cash'), value = 'money' },
                            { label = TranslateCap('bank'), value = 'bank' }
                        },
                        default = 'bank'
                    }
                }
            }, function(data2)
                if data2 then
                    local paymentMethod = data2[1]
                    
                    -- Confirm purchase
                    exports.ox_lib:dialog({
                        id = 'confirm_shop_purchase',
                        title = TranslateCap('confirm_purchase'),
                        content = TranslateCap('shop_purchase_confirmation', shopName, FormatMoney(shop.price)),
                        options = {
                            {
                                type = 'check',
                                label = TranslateCap('confirm'),
                                required = true
                            }
                        }
                    }, function(data3)
                        if data3 and data3[1] then
                            -- Trigger server event to buy the shop
                            TriggerServerEvent('esx_advanced_shops:buyShop', shop.id, shopName, shop.price, paymentMethod)
                        end
                    end)
                end
            end)
        end
    end)
end

-- Open shop management menu
function OpenManagementMenu(shopId, shopData)
    -- Fetch the latest shop data
    ESX.TriggerServerCallback('esx_advanced_shops:getShopData', function(shop)
        if shop.owner ~= PlayerData.identifier then
            ShowNotification(TranslateCap('not_owner'))
            return
        end
        
        if Config.UseOxLib then
            -- Use ox_lib menu
            local elements = {
                {
                    title = TranslateCap('stock_management'),
                    description = TranslateCap('manage_stock_description'),
                    icon = 'box',
                    onSelect = function()
                        OpenStockManagement(shopId, shop)
                    end
                },
                {
                    title = TranslateCap('employee_management'),
                    description = TranslateCap('manage_employees_description'),
                    icon = 'users',
                    onSelect = function()
                        OpenEmployeeManagement(shopId, shop)
                    end
                },
                {
                    title = TranslateCap('finances'),
                    description = TranslateCap('manage_finances_description'),
                    icon = 'money-bill',
                    onSelect = function()
                        OpenFinancesMenu(shopId, shop)
                    end
                },
                {
                    title = TranslateCap('order_stock'),
                    description = TranslateCap('order_stock_description'),
                    icon = 'truck',
                    onSelect = function()
                        OpenOrderMenu(shopId, shop)
                    end
                },
                {
                    title = TranslateCap('shop_settings'),
                    description = TranslateCap('manage_settings_description'),
                    icon = 'cogs',
                    onSelect = function()
                        OpenShopSettings(shopId, shop)
                    end
                }
            }
            
            -- Add open/close option
            if shop.open then
                table.insert(elements, {
                    title = TranslateCap('close_shop'),
                    description = TranslateCap('close_shop_description'),
                    icon = 'door-closed',
                    onSelect = function()
                        TriggerServerEvent('esx_advanced_shops:setShopStatus', shopId, false)
                    end
                })
            else
                table.insert(elements, {
                    title = TranslateCap('open_shop'),
                    description = TranslateCap('open_shop_description'),
                    icon = 'door-open',
                    onSelect = function()
                        TriggerServerEvent('esx_advanced_shops:setShopStatus', shopId, true)
                    end
                })
            end
            
            -- Add sell shop option
            table.insert(elements, {
                title = TranslateCap('sell_shop'),
                description = TranslateCap('sell_shop_description', FormatMoney(shop.price * 0.7)),
                icon = 'hand-holding-usd',
                onSelect = function()
                    SellShop(shopId, shop)
                end
            })
            
            -- Display the menu
            exports.ox_lib:registerContext({
                id = 'shop_management',
                title = shop.name or TranslateCap('shop_management'),
                options = elements
            })
            
            exports.ox_lib:showContext('shop_management')
        else
            -- Use ESX menu
            local elements = {
                {label = TranslateCap('stock_management'), value = 'stock'},
                {label = TranslateCap('employee_management'), value = 'employees'},
                {label = TranslateCap('finances'), value = 'finances'},
                {label = TranslateCap('order_stock'), value = 'order'},
                {label = TranslateCap('shop_settings'), value = 'settings'}
            }
            
            if shop.open then
                table.insert(elements, {label = TranslateCap('close_shop'), value = 'close'})
            else
                table.insert(elements, {label = TranslateCap('open_shop'), value = 'open'})
            end
            
            table.insert(elements, {label = TranslateCap('sell_shop') .. ' ($' .. FormatMoney(shop.price * 0.7) .. ')', value = 'sell'})
            
            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'shop_management', {
                title = shop.name or TranslateCap('shop_management'),
                align = 'top-left',
                elements = elements
            }, function(data, menu)
                local action = data.current.value
                
                if action == 'stock' then
                    OpenStockManagement(shopId, shop)
                elseif action == 'employees' then
                    OpenEmployeeManagement(shopId, shop)
                elseif action == 'finances' then
                    OpenFinancesMenu(shopId, shop)
                elseif action == 'order' then
                    OpenOrderMenu(shopId, shop)
                elseif action == 'settings' then
                    OpenShopSettings(shopId, shop)
                elseif action == 'close' then
                    TriggerServerEvent('esx_advanced_shops:setShopStatus', shopId, false)
                    menu.close()
                elseif action == 'open' then
                    TriggerServerEvent('esx_advanced_shops:setShopStatus', shopId, true)
                    menu.close()
                elseif action == 'sell' then
                    SellShop(shopId, shop)
                end
            end, function(data, menu)
                menu.close()
            end)
        end
    end, shopId)
end

-- Open stock management menu
function OpenStockManagement(shopId, shop)
    ESX.TriggerServerCallback('esx_advanced_shops:getShopItems', function(items)
        if #items == 0 then
            ShowNotification(TranslateCap('no_items'))
            return
        end
        
        if Config.UseOxLib then
            -- Use ox_lib menu
            local elements = {}
            
            for i = 1, #items do
                local item = items[i]
                
                table.insert(elements, {
                    title = item.label,
                    description = TranslateCap('item_price') .. ': $' .. FormatMoney(item.price) .. '\n' ..
                                TranslateCap('item_stock') .. ': ' .. item.stock .. '/' .. item.maxStock,
                    icon = 'box',
                    onSelect = function()
                        OpenItemManagement(shopId, shop, item)
                    end
                })
            end
            
            -- Add new item option
            table.insert(elements, {
                title = TranslateCap('add_new_item'),
                description = TranslateCap('add_new_item_description'),
                icon = 'plus',
                onSelect = function()
                    OpenAddNewItemMenu(shopId, shop)
                end
            })
            
            -- Display the menu
            exports.ox_lib:registerContext({
                id = 'stock_management',
                title = TranslateCap('stock_management'),
                menu = 'shop_management',
                options = elements
            })
            
            exports.ox_lib:showContext('stock_management')
        else
            -- Use ESX menu
            local elements = {}
            
            for i = 1, #items do
                local item = items[i]
                
                table.insert(elements, {
                    label = item.label .. ' - $' .. FormatMoney(item.price) .. ' (' .. TranslateCap('stock') .. ': ' .. item.stock .. '/' .. item.maxStock .. ')',
                    item = item
                })
            end
            
            table.insert(elements, {label = TranslateCap('add_new_item'), value = 'add'})
            
            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stock_management', {
                title = TranslateCap('stock_management'),
                align = 'top-left',
                elements = elements
            }, function(data, menu)
                if data.current.value == 'add' then
                    OpenAddNewItemMenu(shopId, shop)
                else
                    OpenItemManagement(shopId, shop, data.current.item)
                end
            end, function(data, menu)
                menu.close()
                OpenManagementMenu(shopId, shop)
            end)
        end
    end, shopId)
end

-- Open item management menu
function OpenItemManagement(shopId, shop, item)
    if Config.UseOxLib then
        -- Use ox_lib menu
        local elements = {
            {
                title = TranslateCap('adjust_price'),
                description = TranslateCap('current_price') .. ': $' .. FormatMoney(item.price),
                icon = 'money-bill',
                onSelect = function()
                    AdjustItemPrice(shopId, shop, item)
                end
            },
            {
                title = TranslateCap('add_stock'),
                description = TranslateCap('current_stock') .. ': ' .. item.stock .. '/' .. item.maxStock,
                icon = 'plus',
                onSelect = function()
                    AddItemStock(shopId, shop, item)
                end
            },
            {
                title = TranslateCap('remove_stock'),
                description = TranslateCap('current_stock') .. ': ' .. item.stock,
                icon = 'minus',
                onSelect = function()
                    RemoveItemStock(shopId, shop, item)
                end
            },
            {
                title = TranslateCap('remove_item'),
                description = TranslateCap('remove_item_description'),
                icon = 'trash',
                onSelect = function()
                    RemoveItem(shopId, shop, item)
                end
            }
        }
        
        -- Display the menu
        exports.ox_lib:registerContext({
            id = 'item_management',
            title = item.label,
            menu = 'stock_management',
            options = elements
        })
        
        exports.ox_lib:showContext('item_management')
    else
        -- Use ESX menu
        local elements = {
            {label = TranslateCap('adjust_price') .. ' ($' .. FormatMoney(item.price) .. ')', value = 'price'},
            {label = TranslateCap('add_stock') .. ' (' .. item.stock .. '/' .. item.maxStock .. ')', value = 'add'},
            {label = TranslateCap('remove_stock') .. ' (' .. item.stock .. ')', value = 'remove'},
            {label = TranslateCap('remove_item'), value = 'delete'}
        }
        
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'item_management', {
            title = item.label,
            align = 'top-left',
            elements = elements
        }, function(data, menu)
            local action = data.current.value
            
            if action == 'price' then
                AdjustItemPrice(shopId, shop, item)
            elseif action == 'add' then
                AddItemStock(shopId, shop, item)
            elseif action == 'remove' then
                RemoveItemStock(shopId, shop, item)
            elseif action == 'delete' then
                RemoveItem(shopId, shop, item)
            end
        end, function(data, menu)
            menu.close()
            OpenStockManagement(shopId, shop)
        end)
    end
end

-- Adjust item price
function AdjustItemPrice(shopId, shop, item)
    -- Calculate min and max price based on supplier price
    local minPrice = math.ceil(item.supplierPrice * Config.ProfitMargin.min)
    local maxPrice = math.ceil(item.supplierPrice * Config.ProfitMargin.max)
    
    exports.ox_lib:dialog({
        id = 'adjust_price_dialog',
        title = TranslateCap('adjust_price'),
        content = TranslateCap('adjust_price_prompt', item.label, minPrice, maxPrice),
        options = {
            {
                type = 'number',
                label = TranslateCap('new_price'),
                default = item.price,
                min = minPrice,
                max = maxPrice,
                required = true
            }
        }
    }, function(data)
        if data then
            local newPrice = math.floor(data[1])
            
            if newPrice < minPrice or newPrice > maxPrice then
                ShowNotification(TranslateCap('invalid_price'))
                return
            end
            
            TriggerServerEvent('esx_advanced_shops:updateItemPrice', shopId, item.name, newPrice)
            ShowNotification(TranslateCap('priceTranslateCappdated', FormatMoney(newPrice)))
        end
    end)
end

-- Add item stock
function AddItemStock(shopId, shop, item)
    -- Calculate max amount that can be added
    local maxAdd = item.maxStock - item.stock
    
    if maxAdd <= 0 then
        ShowNotification(TranslateCap('stock_full'))
        return
    end
    
    -- First check how many of this item the player has
    ESX.TriggerServerCallback('esx_advanced_shops:getInventoryItem', function(count)
        local maxPlayerCanGive = count
        local maxToAdd = math.min(maxAdd, maxPlayerCanGive)
        
        if maxToAdd <= 0 then
            ShowNotification(TranslateCap('no_items_to_add'))
            return
        end
        
        exports.ox_lib:dialog({
            id = 'add_stock_dialog',
            title = TranslateCap('add_stock'),
            content = TranslateCap('add_stock_prompt', item.label, maxToAdd),
            options = {
                {
                    type = 'number',
                    label = TranslateCap('amount'),
                    default = 1,
                    min = 1,
                    max = maxToAdd,
                    required = true
                }
            }
        }, function(data)
            if data then
                local amount = math.floor(data[1])
                
                if amount < 1 or amount > maxToAdd then
                    ShowNotification(TranslateCap('invalid_amount'))
                    return
                end
                
                TriggerServerEvent('esx_advanced_shops:addItemStock', shopId, item.name, amount)
            end
        end)
    end, item.name)
end

-- Remove item stock
function RemoveItemStock(shopId, shop, item)
    if item.stock <= 0 then
        ShowNotification(TranslateCap('no_stock'))
        return
    end
    
    exports.ox_lib:dialog({
        id = 'remove_stock_dialog',
        title = TranslateCap('remove_stock'),
        content = TranslateCap('remove_stock_prompt', item.label, item.stock),
        options = {
            {
                type = 'number',
                label = TranslateCap('amount'),
                default = 1,
                                min = 1,
                max = item.stock,
                required = true
            }
        }
    }, function(data)
        if data then
            local amount = math.floor(data[1])
            
            if amount < 1 or amount > item.stock then
                ShowNotification(TranslateCap('invalid_amount'))
                return
            end
            
            TriggerServerEvent('esx_advanced_shops:removeItemStock', shopId, item.name, amount)
        end
    end)
end

-- Remove item from shop
function RemoveItem(shopId, shop, item)
    exports.ox_lib:dialog({
        id = 'remove_item_dialog',
        title = TranslateCap('remove_item'),
        content = TranslateCap('remove_item_confirmation', item.label),
        options = {
            {
                type = 'check',
                label = TranslateCap('confirm'),
                required = true
            }
        }
    }, function(data)
        if data and data[1] then
            TriggerServerEvent('esx_advanced_shops:removeItem', shopId, item.name)
        end
    end)
end

-- Open add new item menu
function OpenAddNewItemMenu(shopId, shop)
    -- Get items that can be added
    ESX.TriggerServerCallback('esx_advanced_shops:getAddableItems', function(items)
        if #items == 0 then
            ShowNotification(TranslateCap('no_items_to_add'))
            return
        end
        
        local elements = {}
        
        for i = 1, #items do
            local item = items[i]
            
            table.insert(elements, {
                title = item.label,
                description = TranslateCap('supplier_price') .. ': $' .. FormatMoney(item.price),
                metadata = {
                    {label = TranslateCap('item_type'), value = item.type}
                },
                icon = 'box',
                onSelect = function()
                    ConfigureNewItem(shopId, shop, item)
                end
            })
        end
        
        -- Display the menu
        exports.ox_lib:registerContext({
            id = 'add_item_menu',
            title = TranslateCap('add_new_item'),
            menu = 'stock_management',
            options = elements
        })
        
        exports.ox_lib:showContext('add_item_menu')
    end, shopId, shop.category)
end

-- Configure new item before adding
function ConfigureNewItem(shopId, shop, item)
    -- Calculate min and max price based on supplier price
    local minPrice = math.ceil(item.price * Config.ProfitMargin.min)
    local maxPrice = math.ceil(item.price * Config.ProfitMargin.max)
    local suggestedPrice = math.ceil(item.price * ((Config.ProfitMargin.min + Config.ProfitMargin.max) / 2))
    
    -- Get default max stock for this category
    local categoryItems = Config.DefaultItems[shop.category]
    local defaultMaxStock = 20 -- Default if not found
    
    for i = 1, #categoryItems do
        if categoryItems[i].name == item.name then
            defaultMaxStock = categoryItems[i].maxStock
            break
        end
    end
    
    exports.ox_lib:dialog({
        id = 'configure_item_dialog',
        title = TranslateCap('configure_item', item.label),
        options = {
            {
                type = 'number',
                label = TranslateCap('selling_price'),
                description = TranslateCap('price_range', minPrice, maxPrice),
                default = suggestedPrice,
                min = minPrice,
                max = maxPrice,
                required = true
            },
            {
                type = 'number',
                label = TranslateCap('max_stock'),
                description = TranslateCap('max_stock_description'),
                default = defaultMaxStock,
                min = 1,
                max = 100,
                required = true
            }
        }
    }, function(data)
        if data then
            local sellingPrice = math.floor(data[1])
            local maxStock = math.floor(data[2])
            
            if sellingPrice < minPrice or sellingPrice > maxPrice then
                ShowNotification(TranslateCap('invalid_price'))
                return
            end
            
            if maxStock < 1 or maxStock > 100 then
                ShowNotification(TranslateCap('invalid_max_stock'))
                return
            end
            
            TriggerServerEvent('esx_advanced_shops:addNewItem', shopId, item.name, sellingPrice, maxStock, item.price)
        end
    end)
end

-- Open employee management menu
function OpenEmployeeManagement(shopId, shop)
    ESX.TriggerServerCallback('esx_advanced_shops:getEmployees', function(employees)
        local elements = {
            {
                title = TranslateCap('add_employee'),
                description = TranslateCap('add_employee_description'),
                icon = 'user-plus',
                onSelect = function()
                    AddEmployee(shopId, shop)
                end
            }
        }
        
        for i = 1, #employees do
            local employee = employees[i]
            
            table.insert(elements, {
                title = employee.name,
                description = TranslateCap('permission_level') .. ': ' .. employee.grade,
                icon = 'user',
                onSelect = function()
                    ManageEmployee(shopId, shop, employee)
                end
            })
        end
        
        -- Display the menu
        exports.ox_lib:registerContext({
            id = 'employee_management',
            title = TranslateCap('employee_management'),
            menu = 'shop_management',
            options = elements
        })
        
        exports.ox_lib:showContext('employee_management')
    end, shopId)
end

-- Add employee
function AddEmployee(shopId, shop)
    -- Get nearby players
    ESX.TriggerServerCallback('esx_advanced_shops:getNearbyPlayers', function(players)
        if #players == 0 then
            ShowNotification(TranslateCap('no_players_nearby'))
            return
        end
        
        local elements = {}
        
        for i = 1, #players do
            local player = players[i]
            
            table.insert(elements, {
                title = player.name,
                description = TranslateCap('id') .. ': ' .. player.id,
                icon = 'user',
                onSelect = function()
                    SelectEmployeeGrade(shopId, shop, player)
                end
            })
        end
        
        -- Display the menu
        exports.ox_lib:registerContext({
            id = 'add_employee_menu',
            title = TranslateCap('select_employee'),
            menu = 'employee_management',
            options = elements
        })
        
        exports.ox_lib:showContext('add_employee_menu')
    end)
end

-- Select employee permission grade
function SelectEmployeeGrade(shopId, shop, player)
    local elements = {
        {
            title = TranslateCap('cashier'),
            description = TranslateCap('cashier_description'),
            icon = 'cash-register',
            onSelect = function()
                TriggerServerEvent('esx_advanced_shops:addEmployee', shopId, player.identifier, player.name, 1)
            end
        },
        {
            title = TranslateCap('manager'),
            description = TranslateCap('manager_description'),
            icon = 'user-tie',
            onSelect = function()
                TriggerServerEvent('esx_advanced_shops:addEmployee', shopId, player.identifier, player.name, 2)
            end
        }
    }
    
    -- Display the menu
    exports.ox_lib:registerContext({
        id = 'employee_grade_menu',
        title = TranslateCap('select_permission_level', player.name),
        menu = 'add_employee_menu',
        options = elements
    })
    
    exports.ox_lib:showContext('employee_grade_menu')
end

-- Manage employee
function ManageEmployee(shopId, shop, employee)
    local elements = {
        {
            title = TranslateCap('change_permission'),
            description = TranslateCap('current_permission') .. ': ' .. employee.grade,
            icon = 'user-cog',
            onSelect = function()
                ChangeEmployeeGrade(shopId, shop, employee)
            end
        },
        {
            title = TranslateCap('remove_employee'),
            description = TranslateCap('remove_employee_confirmation', employee.name),
            icon = 'user-minus',
            onSelect = function()
                TriggerServerEvent('esx_advanced_shops:removeEmployee', shopId, employee.identifier)
            end
        }
    }
    
    -- Display the menu
    exports.ox_lib:registerContext({
        id = 'manage_employee_menu',
        title = employee.name,
        menu = 'employee_management',
        options = elements
    })
    
    exports.ox_lib:showContext('manage_employee_menu')
end

-- Change employee grade
function ChangeEmployeeGrade(shopId, shop, employee)
    local elements = {
        {
            title = TranslateCap('cashier'),
            description = TranslateCap('cashier_description'),
            icon = 'cash-register',
            onSelect = function()
                TriggerServerEvent('esx_advanced_shops:updateEmployeeGrade', shopId, employee.identifier, 1)
            end
        },
        {
            title = TranslateCap('manager'),
            description = TranslateCap('manager_description'),
            icon = 'user-tie',
            onSelect = function()
                TriggerServerEvent('esx_advanced_shops:updateEmployeeGrade', shopId, employee.identifier, 2)
            end
        }
    }
    
    -- Display the menu
    exports.ox_lib:registerContext({
        id = 'change_grade_menu',
        title = TranslateCap('change_permission_level', employee.name),
        menu = 'manage_employee_menu',
        options = elements
    })
    
    exports.ox_lib:showContext('change_grade_menu')
end

-- Open finances menu
function OpenFinancesMenu(shopId, shop)
    ESX.TriggerServerCallback('esx_advanced_shops:getFinances', function(finances)
        local elements = {
            {
                title = TranslateCap('shop_balance'),
                description = '$' .. FormatMoney(finances.balance),
                icon = 'money-bill-wave',
                disabled = true
            },
            {
                title = TranslateCap('total_sales'),
                description = '$' .. FormatMoney(finances.totalSales),
                icon = 'shopping-cart',
                disabled = true
            },
            {
                title = TranslateCap('total_profit'),
                description = '$' .. FormatMoney(finances.totalProfit),
                icon = 'chart-line',
                disabled = true
            },
            {
                title = TranslateCap('withdraw_money'),
                description = TranslateCap('withdraw_money_description'),
                icon = 'hand-holding-usd',
                onSelect = function()
                    WithdrawMoney(shopId, shop, finances.balance)
                end
            },
            {
                title = TranslateCap('deposit_money'),
                description = TranslateCap('deposit_money_description'),
                icon = 'donate',
                onSelect = function()
                    DepositMoney(shopId, shop)
                end
            }
        }
        
        -- Display the menu
        exports.ox_lib:registerContext({
            id = 'finances_menu',
            title = TranslateCap('finances'),
            menu = 'shop_management',
            options = elements
        })
        
        exports.ox_lib:showContext('finances_menu')
    end, shopId)
end

-- Withdraw money from shop
function WithdrawMoney(shopId, shop, balance)
    if balance <= 0 then
        ShowNotification(TranslateCap('no_money_to_withdraw'))
        return
    end
    
    exports.ox_lib:dialog({
        id = 'withdraw_money_dialog',
        title = TranslateCap('withdraw_money'),
        content = TranslateCap('withdraw_prompt', FormatMoney(balance)),
        options = {
            {
                type = 'number',
                label = TranslateCap('amount'),
                default = balance,
                min = 1,
                max = balance,
                required = true
            }
        }
    }, function(data)
        if data then
            local amount = math.floor(data[1])
            
            if amount < 1 or amount > balance then
                ShowNotification(TranslateCap('invalid_amount'))
                return
            end
            
            TriggerServerEvent('esx_advanced_shops:withdrawMoney', shopId, amount)
        end
    end)
end

-- Deposit money to shop
function DepositMoney(shopId, shop)
    -- Get player money
    local playerMoney = ESX.GetPlayerData().money
    
    if playerMoney <= 0 then
        ShowNotification(TranslateCap('no_money'))
        return
    end
    
    exports.ox_lib:dialog({
        id = 'deposit_money_dialog',
        title = TranslateCap('deposit_money'),
        content = TranslateCap('deposit_prompt'),
        options = {
            {
                type = 'number',
                label = TranslateCap('amount'),
                default = 1000,
                min = 1,
                max = playerMoney,
                required = true
            }
        }
    }, function(data)
        if data then
            local amount = math.floor(data[1])
            
            if amount < 1 or amount > playerMoney then
                ShowNotification(TranslateCap('invalid_amount'))
                return
            end
            
            TriggerServerEvent('esx_advanced_shops:depositMoney', shopId, amount)
        end
    end)
end

-- Open order menu
function OpenOrderMenu(shopId, shop)
    -- Get supplier info for this shop
    local supplierInfo = Config.Suppliers[shop.category]
    
    if not supplierInfo then
        ShowNotification(TranslateCap('no_supplier'))
        return
    end
    
    -- Get finances
    ESX.TriggerServerCallback('esx_advanced_shops:getFinances', function(finances)
        local shopBalance = finances.balance
        
        -- Get items that can be ordered
        ESX.TriggerServerCallback('esx_advanced_shops:getOrderableItems', function(items)
            if #items == 0 then
                ShowNotification(TranslateCap('no_items_to_order'))
                return
            end
            
            local elements = {
                {
                    title = supplierInfo.name,
                    description = TranslateCap('discount', math.floor(supplierInfo.discount * 100)) .. '\n' ..
                                TranslateCap('min_order', supplierInfo.minOrderQuantity),
                    icon = 'truck',
                    disabled = true
                }
            }
            
            for i = 1, #items do
                local item = items[i]
                local maxAffordable = math.floor(shopBalance / (item.price * (1 - supplierInfo.discount)))
                
                table.insert(elements, {
                    title = item.label,
                    description = TranslateCap('price') .. ': $' .. FormatMoney(item.price) .. '\n' ..
                                TranslateCap('discounted_price') .. ': $' .. FormatMoney(item.price * (1 - supplierInfo.discount)),
                    icon = 'box',
                    disabled = maxAffordable < supplierInfo.minOrderQuantity,
                    onSelect = function()
                        OrderItem(shopId, shop, item, supplierInfo, shopBalance)
                    end
                })
            end
            
            -- Display the menu
            exports.ox_lib:registerContext({
                id = 'order_menu',
                title = TranslateCap('order_stock'),
                menu = 'shop_management',
                options = elements
            })
            
            exports.ox_lib:showContext('order_menu')
        end, shopId, shop.category)
    end, shopId)
end

-- Order specific item
function OrderItem(shopId, shop, item, supplierInfo, shopBalance)
    -- Calculate max affordable and max stock space
    local discountedPrice = item.price * (1 - supplierInfo.discount)
    local maxAffordable = math.floor(shopBalance / discountedPrice)
    
    ESX.TriggerServerCallback('esx_advanced_shops:getItemMaxStock', function(currentStock, maxStock)
        local maxSpace = maxStock - currentStock
        
        if maxSpace <= 0 then
            ShowNotification(TranslateCap('no_space_for_item'))
            return
        end
        
        local maxOrder = math.min(maxAffordable, maxSpace)
        
        if maxOrder < supplierInfo.minOrderQuantity then
            ShowNotification(TranslateCap('cannot_order_min_quantity', supplierInfo.minOrderQuantity))
            return
        end
        
        exports.ox_lib:dialog({
            id = 'order_item_dialog',
            title = TranslateCap('order_item', item.label),
            content = TranslateCap('order_prompt', item.label, supplierInfo.minOrderQuantity),
            options = {
                {
                    type = 'number',
                    label = TranslateCap('amount'),
                    default = supplierInfo.minOrderQuantity,
                    min = supplierInfo.minOrderQuantity,
                    max = maxOrder,
                    required = true
                }
            }
        }, function(data)
            if data then
                local amount = math.floor(data[1])
                
                if amount < supplierInfo.minOrderQuantity or amount > maxOrder then
                    ShowNotification(TranslateCap('invalid_amount'))
                    return
                end
                
                local totalCost = amount * discountedPrice
                
                -- Confirm order
                exports.ox_lib:dialog({
                    id = 'confirm_order_dialog',
                    title = TranslateCap('confirm_order'),
                    content = TranslateCap('order_confirm', amount, item.label, FormatMoney(totalCost)),
                    options = {
                        {
                            type = 'check',
                            label = TranslateCap('confirm'),
                            required = true
                        }
                    }
                }, function(data2)
                    if data2 and data2[1] then
                        TriggerServerEvent('esx_advanced_shops:orderItem', shopId, item.name, amount, discountedPrice)
                    end
                end)
            end
        end)
    end, shopId, item.name)
end

-- Open shop settings
function OpenShopSettings(shopId, shop)
    local elements = {
        {
            title = TranslateCap('shop_name'),
            description = shop.name,
            icon = 'pencil-alt',
            onSelect = function()
                ChangeShopName(shopId, shop)
            end
        },
        {
            title = TranslateCap('shop_blip'),
            description = TranslateCap('change_blip_color_description'),
            icon = 'map-marker-alt',
            onSelect = function()
                ChangeBlipColor(shopId, shop)
            end
        }
    }
    
    -- Display the menu
    exports.ox_lib:registerContext({
        id = 'shop_settings_menu',
        title = TranslateCap('shop_settings'),
        menu = 'shop_management',
        options = elements
    })
    
    exports.ox_lib:showContext('shop_settings_menu')
end

-- Change shop name
function ChangeShopName(shopId, shop)
    exports.ox_lib:dialog({
        id = 'change_name_dialog',
        title = TranslateCap('change_shop_name'),
        options = {
            {
                type = 'input',
                label = TranslateCap('shop_name'),
                default = shop.name,
                required = true
            }
        }
    }, function(data)
        if data then
            local name = data[1]
            
            if string.len(name) < 3 or string.len(name) > 30 then
                ShowNotification(TranslateCap('invalid_name'))
                return
            end
            
            TriggerServerEvent('esx_advanced_shops:updateShopName', shopId, name)
        end
    end)
end

-- Change blip color
function ChangeBlipColor(shopId, shop)
    local elements = {}
    
    for i = 0, 85 do
        table.insert(elements, {
            title = TranslateCap('color') .. ' ' .. i,
            icon = 'circle',
            onSelect = function()
                TriggerServerEvent('esx_advanced_shops:updateBlipColor', shopId, i)
            end
        })
    end
    
    -- Display the menu
    exports.ox_lib:registerContext({
        id = 'blip_color_menu',
        title = TranslateCap('select_blip_color'),
        menu = 'shop_settings_menu',
        options = elements
    })
    
    exports.ox_lib:showContext('blip_color_menu')
end

-- Sell shop
function SellShop(shopId, shop)
    local sellPrice = math.floor(shop.price * 0.7)
    
    exports.ox_lib:dialog({
        id = 'sell_shop_dialog',
        title = TranslateCap('sell_shop'),
        content = TranslateCap('sell_shop_confirmation', shop.name, FormatMoney(sellPrice)),
        options = {
            {
                type = 'check',
                label = TranslateCap('confirm'),
                required = true
            }
        }
    }, function(data)
        if data and data[1] then
            TriggerServerEvent('esx_advanced_shops:sellShop', shopId)
        end
    end)
end