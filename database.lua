local MySQL = MySQL

-- Initialize shop system
function InitializeShopSystem()
    print("[^2ESX_ADVANCED_SHOPS^7] Initializing shop system...")
    
    -- Ensure all required tables exist
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `shops` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `name` VARCHAR(50) NOT NULL,
            `owner` VARCHAR(60) NULL DEFAULT NULL,
            `money` INT(11) NOT NULL DEFAULT 0,
            `category` VARCHAR(50) NOT NULL,
            `coords` LONGTEXT NOT NULL,
            `size` VARCHAR(10) NOT NULL,
            `price` INT(11) NOT NULL,
            `blip_color` INT(11) NOT NULL DEFAULT 2,
            `open` TINYINT(1) NOT NULL DEFAULT 1,
            `last_robbed` TIMESTAMP NULL DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `shop_items` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `shop_id` INT(11) NOT NULL,
            `name` VARCHAR(100) NOT NULL,
            `price` INT(11) NOT NULL,
            `stock` INT(11) NOT NULL DEFAULT 0,
            `max_stock` INT(11) NOT NULL DEFAULT 50,
            `supplier_price` INT(11) NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`),
            UNIQUE INDEX `shop_item_idx` (`shop_id`, `name`),
            CONSTRAINT `fk_shop_items_shop` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `shop_employees` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `shop_id` INT(11) NOT NULL,
            `identifier` VARCHAR(60) NOT NULL,
            `name` VARCHAR(50) NOT NULL,
            `grade` TINYINT(1) NOT NULL DEFAULT 1,
            `added_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE INDEX `shop_employee_idx` (`shop_id`, `identifier`),
            CONSTRAINT `fk_shop_employees_shop` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `shop_orders` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `shop_id` INT(11) NOT NULL,
            `item_name` VARCHAR(100) NOT NULL,
            `amount` INT(11) NOT NULL,
            `price` INT(11) NOT NULL,
            `status` VARCHAR(20) NOT NULL DEFAULT 'pending',
            `delivery_time` TIMESTAMP NULL DEFAULT NULL,
            `ordered_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            CONSTRAINT `fk_shop_orders_shop` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `shop_transactions` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `shop_id` INT(11) NOT NULL,
            `buyer` VARCHAR(60) NOT NULL,
            `item_name` VARCHAR(100) NOT NULL,
            `amount` INT(11) NOT NULL,
            `price` INT(11) NOT NULL,
            `supplier_price` INT(11) NOT NULL,
            `profit` INT(11) NOT NULL,
            `transaction_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            CONSTRAINT `fk_shop_transactions_shop` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    print("[^2ESX_ADVANCED_SHOPS^7] Database initialization complete.")
    
    -- Set up available shops
    InitializeAvailableShops()
end

-- Initialize available shops
function InitializeAvailableShops()
    -- Check if we have shops in the database
    local shopCount = MySQL.scalar.await("SELECT COUNT(*) FROM shops")
    
    if shopCount == 0 then
        print("[^2ESX_ADVANCED_SHOPS^7] Setting up available shops...")
        
        -- Add all shops from config
        for i = 1, #Config.AvailableShops do
            local shop = Config.AvailableShops[i]
            
            MySQL.insert.await("INSERT INTO shops (id, name, category, coords, size, price) VALUES (?, ?, ?, ?, ?, ?)",
                {
                    shop.id,
                    shop.name,
                    shop.category,
                    json.encode({x = shop.coords.x, y = shop.coords.y, z = shop.coords.z}),
                    shop.size,
                    shop.price
                }
            )
        end
        
        print("[^2ESX_ADVANCED_SHOPS^7] Added " .. #Config.AvailableShops .. " shops.")
    else
        print("[^2ESX_ADVANCED_SHOPS^7] Found " .. shopCount .. " shops in the database.")
    end
end

-- Get all shops
function GetAllShops()
    local result = MySQL.query.await("SELECT * FROM shops")
    
    -- Parse coords
    for i = 1, #result do
        result[i].coords = json.decode(result[i].coords)
    end
    
    return result
end

-- Get shop by ID
function GetShopById(shopId)
    local result = MySQL.query.await("SELECT * FROM shops WHERE id = ?", {shopId})
    
    if result[1] then
        result[1].coords = json.decode(result[1].coords)
        return result[1]
    end
    
    return nil
end

-- Get available shops for purchase
function GetAvailableShops()
    local result = MySQL.query.await("SELECT * FROM shops WHERE owner IS NULL")
    
    -- Parse coords
    for i = 1, #result do
        result[i].coords = json.decode(result[i].coords)
    end
    
    return result
end

-- Buy a shop
function BuyShop(shopId, identifier, name, price)
    local shop = GetShopById(shopId)
    
    if not shop or shop.owner then
        return false
    end
    
    local success = MySQL.update.await("UPDATE shops SET owner = ?, name = ? WHERE id = ? AND owner IS NULL", {
        identifier,
        name,
        shopId
    })
    
    if success > 0 then
        -- Add default items for this shop's category
        local categoryItems = Config.DefaultItems[shop.category]
        
        if categoryItems then
            for i = 1, #categoryItems do
                local item = categoryItems[i]
                
                MySQL.insert.await("INSERT INTO shop_items (shop_id, name, price, max_stock, supplier_price) VALUES (?, ?, ?, ?, ?)",
                    {
                        shopId,
                        item.name,
                        item.price,
                        item.maxStock,
                        math.floor(item.price * 0.8) -- Default supplier price is 80% of retail
                    }
                )
            end
        end
        
        return true
    end
    
    return false
end

-- Sell a shop
function SellShop(shopId, identifier)
    local shop = GetShopById(shopId)
    
    if not shop or shop.owner ~= identifier then
        return false, 0
    end
    
    local sellPrice = math.floor(shop.price * 0.7)
    
    local success = MySQL.update.await("UPDATE shops SET owner = NULL WHERE id = ? AND owner = ?", {
        shopId,
        identifier
    })
    
    if success > 0 then
        -- Clear all shop data
        MySQL.query.await("DELETE FROM shop_items WHERE shop_id = ?", {shopId})
        MySQL.query.await("DELETE FROM shop_employees WHERE shop_id = ?", {shopId})
        
        return true, sellPrice
    end
    
    return false, 0
end

-- Get shop owner
function GetShopOwner(shopId)
    return MySQL.scalar.await("SELECT owner FROM shops WHERE id = ?", {shopId})
end

-- Check if player is shop employee
function IsShopEmployee(shopId, identifier)
    local result = MySQL.query.await("SELECT grade FROM shop_employees WHERE shop_id = ? AND identifier = ?", {
        shopId,
        identifier
    })
    
    if result[1] then
        return true, result[1].grade
    end
    
    return false, 0
end

-- Get shop items
function GetShopItems(shopId)
    return MySQL.query.await("SELECT * FROM shop_items WHERE shop_id = ?", {shopId})
end

-- Get shop finances
function GetShopFinances(shopId)
    local shop = GetShopById(shopId)
    
    if not shop then
        return nil
    end
    
    -- Get total sales and profit
    local result = MySQL.query.await("SELECT SUM(price * amount) as totalSales, SUM(profit) as totalProfit FROM shop_transactions WHERE shop_id = ?", {shopId})
    
    local totalSales = result[1].totalSales or 0
    local totalProfit = result[1].totalProfit or 0
    
    -- Get today's sales and profit
    local today = os.date("%Y-%m-%d")
    local todayResult = MySQL.query.await("SELECT SUM(price * amount) as todaySales, SUM(profit) as todayProfit FROM shop_transactions WHERE shop_id = ? AND DATE(transaction_at) = ?", {
        shopId,
        today
    })
    
    local todaySales = todayResult[1].todaySales or 0
    local todayProfit = todayResult[1].todayProfit or 0
    
    return {
        balance = shop.money,
        totalSales = totalSales,
        totalProfit = totalProfit,
        todaySales = todaySales,
        todayProfit = todayProfit
    }
end

-- Get shop employees
function GetShopEmployees(shopId)
    return MySQL.query.await("SELECT * FROM shop_employees WHERE shop_id = ?", {shopId})
end

-- Add shop employee
function AddShopEmployee(shopId, identifier, name, grade)
    local exists = MySQL.scalar.await("SELECT COUNT(*) FROM shop_employees WHERE shop_id = ? AND identifier = ?", {
        shopId,
        identifier
    })
    
    if exists > 0 then
        return false
    end
    
    local success = MySQL.insert.await("INSERT INTO shop_employees (shop_id, identifier, name, grade) VALUES (?, ?, ?, ?)", {
        shopId,
        identifier,
        name,
        grade
    })
    
    return success > 0
end

-- Update shop employee grade
function UpdateEmployeeGrade(shopId, identifier, grade)
    local success = MySQL.update.await("UPDATE shop_employees SET grade = ? WHERE shop_id = ? AND identifier = ?", {
        grade,
        shopId,
        identifier
    })
    
    return success > 0
end

-- Remove shop employee
function RemoveShopEmployee(shopId, identifier)
    local success = MySQL.delete.await("DELETE FROM shop_employees WHERE shop_id = ? AND identifier = ?", {
        shopId,
        identifier
    })
    
    return success > 0
end

-- Update shop item price
function UpdateItemPrice(shopId, itemName, price)
    local success = MySQL.update.await("UPDATE shop_items SET price = ? WHERE shop_id = ? AND name = ?", {
        price,
        shopId,
        itemName
    })
    
    return success > 0
end

-- Update shop item stock
function UpdateItemStock(shopId, itemName, stock)
    local success = MySQL.update.await("UPDATE shop_items SET stock = ? WHERE shop_id = ? AND name = ?", {
        stock,
        shopId,
        itemName
    })
    
    return success > 0
end

-- Add new item to shop
function AddNewItem(shopId, itemName, price, maxStock, supplierPrice)
    local exists = MySQL.scalar.await("SELECT COUNT(*) FROM shop_items WHERE shop_id = ? AND name = ?", {
        shopId,
        itemName
    })
    
    if exists > 0 then
        return false
    end
    
    local success = MySQL.insert.await("INSERT INTO shop_items (shop_id, name, price, max_stock, supplier_price) VALUES (?, ?, ?, ?, ?)", {
        shopId,
        itemName,
        price,
        maxStock,
        supplierPrice
    })
    
    return success > 0
end

-- Remove item from shop
function RemoveItem(shopId, itemName)
    local success = MySQL.delete.await("DELETE FROM shop_items WHERE shop_id = ? AND name = ?", {
        shopId,
        itemName
    })
    
    return success > 0
end

-- Update shop money
function UpdateShopMoney(shopId, money)
    local success = MySQL.update.await("UPDATE shops SET money = ? WHERE id = ?", {
        money,
        shopId
    })
    
    return success > 0
end

-- Update shop name
function UpdateShopName(shopId, name)
    local success = MySQL.update.await("UPDATE shops SET name = ? WHERE id = ?", {
        name,
        shopId
    })
    
    return success > 0
end

-- Update shop blip color
function UpdateShopBlipColor(shopId, color)
    local success = MySQL.update.await("UPDATE shops SET blip_color = ? WHERE id = ?", {
        color,
        shopId
    })
    
    return success > 0
end

-- Update shop open status
function UpdateShopStatus(shopId, isOpen)
    local success = MySQL.update.await("UPDATE shops SET open = ? WHERE id = ?", {
        isOpen and 1 or 0,
        shopId
    })
    
    return success > 0
end

-- Add shop transaction
function AddShopTransaction(shopId, buyer, itemName, amount, price, supplierPrice)
    local profit = (price - supplierPrice) * amount
    
    local success = MySQL.insert.await("INSERT INTO shop_transactions (shop_id, buyer, item_name, amount, price, supplier_price, profit) VALUES (?, ?, ?, ?, ?, ?, ?)", {
        shopId,
        buyer,
        itemName,
        amount,
        price,
        supplierPrice,
        profit
    })
    
    return success > 0
end

-- Create shop order
function CreateShopOrder(shopId, itemName, amount, price)
    local deliveryTime = os.time() + (60 * math.random(5, 15)) -- Random delivery time between 5-15 minutes
    
    local success = MySQL.insert.await("INSERT INTO shop_orders (shop_id, item_name, amount, price, delivery_time) VALUES (?, ?, ?, ?, FROM_UNIXTIME(?))", {
        shopId,
        itemName,
        amount,
        price,
        deliveryTime
    })
    
    return success > 0, deliveryTime
end

-- Get pending shop orders
function GetPendingOrders()
    local currentTime = os.time()
    
    return MySQL.query.await("SELECT * FROM shop_orders WHERE status = 'pending' AND UNIX_TIMESTAMP(delivery_time) <= ?", {currentTime})
end

-- Complete shop order
function CompleteShopOrder(orderId, shopId, itemName, amount)
    -- Get current stock and max stock
    local item = MySQL.query.await("SELECT stock, max_stock FROM shop_items WHERE shop_id = ? AND name = ?", {
        shopId,
        itemName
    })
    
    if not item[1] then
        -- Item doesn't exist in shop, create it with default values
        local defaultItems = {}
        local shop = GetShopById(shopId)
        
        if shop then
            defaultItems = Config.DefaultItems[shop.category] or {}
        end
        
        local defaultMaxStock = 20
        local defaultPrice = 0
        
        for i = 1, #defaultItems do
            if defaultItems[i].name == itemName then
                defaultMaxStock = defaultItems[i].maxStock
                defaultPrice = defaultItems[i].price
                break
            end
        end
        
        -- Add the item to the shop
        AddNewItem(shopId, itemName, defaultPrice, defaultMaxStock, defaultPrice * 0.8)
        
        -- Update the stock
        UpdateItemStock(shopId, itemName, amount)
    else
        -- Update existing item stock
        local newStock = math.min(item[1].stock + amount, item[1].max_stock)
        UpdateItemStock(shopId, itemName, newStock)
    end
    
    -- Update order status
    MySQL.update.await("UPDATE shop_orders SET status = 'completed' WHERE id = ?", {orderId})
    
    return true
end

-- Update shop last robbed time
function UpdateShopLastRobbed(shopId)
    MySQL.update.await("UPDATE shops SET last_robbed = CURRENT_TIMESTAMP WHERE id = ?", {shopId})
end

-- Check if shop can be robbed (cooldown)
function CanShopBeRobbed(shopId)
    local result = MySQL.query.await("SELECT last_robbed FROM shops WHERE id = ?", {shopId})
    
    if not result[1] or not result[1].last_robbed then
        return true
    end
    
    local lastRobbed = result[1].last_robbed
    local currentTime = os.time()
    local lastRobbedTime = MySQL.prepare.await("SELECT UNIX_TIMESTAMP(?)", {lastRobbed})
    local cooldownEnd = lastRobbedTime + (Config.RobberyCooldown * 60)
    
    return currentTime >= cooldownEnd
end