-- Shop items cache
local ShopItems = {}
local Cart = {}

-- Open the shop menu
function OpenShopMenu(shopId, shopData)
    if isShopOpen then return end
    
    ESX.TriggerServerCallback('esx_advanced_shops:getShopItems', function(items)
        if not items or #items == 0 then
            ShowNotification(TranslateCap('shop_empty'))
            return
        end
        
        ShopItems = items
        Cart = {}
        isShopOpen = true

        if Config.UseOxLib then
            -- Use ox_lib context menu
            local elements = {}
            
            for i = 1, #items do
                local item = items[i]
                if item.stock > 0 then
                    table.insert(elements, {
                        title = item.label,
                        description = TranslateCap('item_price') .. ': $' .. FormatMoney(item.price) .. ' | ' .. TranslateCap('item_stock') .. ': ' .. item.stock,
                        icon = 'shopping-basket',
                        onSelect = function()
                            AddToCart(item)
                        end
                    })
                end
            end
            
            -- Add view cart option
            table.insert(elements, {
                title = TranslateCap('view_cart'),
                description = TranslateCap('view_cart_description'),
                icon = 'shopping-cart',
                onSelect = function()
                    ViewCart()
                end
            })
            
            -- Display the menu
            exports.ox_lib:registerContext({
                id = 'shop_menu',
                title = shopData.name or TranslateCap('shop'),
                options = elements
            })
            
            exports.ox_lib:showContext('shop_menu')
        else
            -- Use ESX menu
            local elements = {}
            
            for i = 1, #items do
                local item = items[i]
                if item.stock > 0 then
                    table.insert(elements, {
                        label = item.label .. ' - $' .. FormatMoney(item.price) .. ' (' .. TranslateCap('stock') .. ': ' .. item.stock .. ')',
                        item = item.name,
                        price = item.price,
                        label_real = item.label,
                        stock = item.stock,
                        value = 1
                    })
                end
            end

            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'shop_menu', {
                title = shopData.name or TranslateCap('shop'),
                align = 'top-left',
                elements = elements
            }, function(data, menu)
                local item = data.current
                local itemName = data.current.item
                local itemPrice = data.current.price
                local itemLabel = data.current.label_real
                local amount = data.current.value
                local stock = data.current.stock
                
                ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'shop_item_amount', {
                    title = TranslateCap('amount')
                }, function(data2, menu2)
                    local amount = tonumber(data2.value)
                    
                    if amount == nil or amount < 1 then
                        ShowNotification(TranslateCap('invalid_amount'))
                    elseif amount > stock then
                        ShowNotification(TranslateCap('not_enough_stock'))
                    else
                        menu2.close()
                        
                        TriggerServerEvent('esx_advanced_shops:buyItem', shopId, itemName, amount, itemPrice)
                    end
                end, function(data2, menu2)
                    menu2.close()
                end)
            end, function(data, menu)
                menu.close()
                isShopOpen = false
            end)
        end
    end, shopId)
end

-- Add item to cart (for ox_lib implementation)
function AddToCart(item)
    exports.ox_lib:dialog({
        id = 'shop_amount_dialog',
        title = TranslateCap('amount'),
        options = {
            {
                type = 'number',
                label = TranslateCap('amount'),
                min = 1,
                max = item.stock,
                default = 1
            }
        }
    }, function(data)
        if data then
            local amount = data[1]
            
            if amount > 0 and amount <= item.stock then
                -- Check if item already in cart
                local found = false
                for i = 1, #Cart do
                    if Cart[i].name == item.name then
                        -- Update quantity
                        Cart[i].amount = Cart[i].amount + amount
                        if Cart[i].amount > item.stock then
                            Cart[i].amount = item.stock
                        end
                        found = true
                        break
                    end
                end
                
                -- Add new item to cart
                if not found then
                    table.insert(Cart, {
                        name = item.name,
                        label = item.label,
                        price = item.price,
                        amount = amount,
                        stock = item.stock
                    })
                end
                
                ShowNotification(TranslateCap('added_to_cart', item.label, amount))
            else
                ShowNotification(TranslateCap('invalid_amount'))
            end
        end
    end)
end

-- View and checkout cart
function ViewCart()
    if #Cart == 0 then
        ShowNotification(TranslateCap('cart_empty'))
        return
    end
    
    local elements = {}
    local total = 0
    
    for i = 1, #Cart do
        local item = Cart[i]
        local itemTotal = item.price * item.amount
        total = total + itemTotal
        
        table.insert(elements, {
            title = item.label .. ' x' .. item.amount,
            description = TranslateCap('item_price') .. ': $' .. FormatMoney(item.price) .. ' | ' .. TranslateCap('total') .. ': $' .. FormatMoney(itemTotal),
            icon = 'trash',
            onSelect = function()
                -- Remove item from cart
                table.remove(Cart, i)
                ViewCart()
            end
        })
    end
    
    -- Add checkout option
    table.insert(elements, {
        title = TranslateCap('checkout'),
        description = TranslateCap('total') .. ': $' .. FormatMoney(total),
        icon = 'cash-register',
        onSelect = function()
            CheckoutCart(CurrentShopId)
        end
    })
    
    -- Add empty cart option
    table.insert(elements, {
        title = TranslateCap('empty_cart'),
        icon = 'trash-alt',
        onSelect = function()
            Cart = {}
            ShowNotification(TranslateCap('cart_emptied'))
            exports.ox_lib:showContext('shop_menu') -- Go back to main shop menu
        end
    })
    
    -- Display the menu
    exports.ox_lib:registerContext({
        id = 'cart_menu',
        title = TranslateCap('your_cart'),
        menu = 'shop_menu',
        options = elements
    })
    
    exports.ox_lib:showContext('cart_menu')
end

-- Process checkout
function CheckoutCart(shopId)
    if #Cart == 0 then
        ShowNotification(TranslateCap('cart_empty'))
        return
    end
    
    -- Calculate total
    local total = 0
    for i = 1, #Cart do
        total = total + (Cart[i].price * Cart[i].amount)
    end
    
    -- Confirm purchase
    exports.ox_lib:dialog({
        id = 'confirm_purchase',
        title = TranslateCap('confirm_purchase'),
        content = TranslateCap('purchase_confirmation', FormatMoney(total)),
        options = {
            {
                type = 'select',
                label = TranslateCap('payment_method'),
                options = {
                    { label = TranslateCap('cash'), value = 'money' },
                    { label = TranslateCap('bank'), value = 'bank' }
                },
                default = 'money'
            }
        }
    }, function(data)
        if data then
            local paymentMethod = data[1]
            
            TriggerServerEvent('esx_advanced_shops:buyItems', shopId, Cart, paymentMethod)
            Cart = {}
            isShopOpen = false
        end
    end)
end

-- Refresh shop menu (when stock changes)
function RefreshShopMenu(items)
    ShopItems = items
    
    if Config.UseOxLib then
        -- Refresh ox_lib context menu
        local elements = {}
        
        for i = 1, #items do
            local item = items[i]
            if item.stock > 0 then
                table.insert(elements, {
                    title = item.label,
                    description = TranslateCap('item_price') .. ': $' .. FormatMoney(item.price) .. ' | ' .. TranslateCap('item_stock') .. ': ' .. item.stock,
                    icon = 'shopping-basket',
                    onSelect = function()
                        AddToCart(item)
                    end
                })
            end
        end
        
        -- Add view cart option
        table.insert(elements, {
            title = TranslateCap('view_cart'),
            description = TranslateCap('view_cart_description'),
            icon = 'shopping-cart',
            onSelect = function()
                ViewCart()
            end
        })
        
        -- Display the menu
        exports.ox_lib:registerContext({
            id = 'shop_menu',
            title = CurrentShopData.name or TranslateCap('shop'),
            options = elements
        })
        
        if exports.ox_lib:getOpenContext() == 'shop_menu' then
            exports.ox_lib:showContext('shop_menu')
        end
    else
        -- Update ESX menu
        ESX.UI.Menu.CloseAll()
        OpenShopMenu(CurrentShopId, CurrentShopData)
    end
end