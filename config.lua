Config = {}

-- General settings
Config.Locale = GetConvar('esx:locale', 'en')
Config.Debug = true 
Config.UseOxInventory = false-- Set to false if using default ESX inventory
Config.UseOxTarget = false-- Set to false to use proximity markers instead
Config.UseOxLib = false-- UI interactions and notifications
Config.MaxSlotsPerShop = 40 -- Max number of different items a shop can sell

-- Shops center (where players can buy their shops)
Config.ShopsCenter = {
    coords = vector3(-31.92, -1113.67, 26.42),
    blip = {
        sprite = 605,
        color = 2,
        scale = 0.8,
        label = "Shop Center"
    }
}

-- Shop purchase
Config.ShopPrices = {
    small = 100000,
    medium = 250000,
    large = 500000
}

-- Shop categories and their max item capacities
Config.ShopCategories = {
    general = {
        label = "General Store",
        maxItems = 40,
        blip = {
            sprite = 59,
            color = 2,
            scale = 0.7
        }
    },
    electronics = {
        label = "Electronics Store",
        maxItems = 30,
        blip = {
            sprite = 521,
            color = 5,
            scale = 0.7
        }
    },
    weapons = {
        label = "Weapon Store",
        maxItems = 20,
        blip = {
            sprite = 110,
            color = 1,
            scale = 0.7
        },
        license = "weapon", -- Required license to purchase
        jobRestricted = true, -- only specified jobs can own this shop
        allowedJobs = {'police'}
    },
    pharmacies = {
        label = "Pharmacy",
        maxItems = 25,
        blip = {
            sprite = 51,
            color = 2,
            scale = 0.7
        }
    },
    liquor = {
        label = "Liquor Store",
        maxItems = 25,
        blip = {
            sprite = 93,
            color = 27,
            scale = 0.7
        }
    }
}

-- Shop locations that are available for purchase
Config.AvailableShops = {
    {
        id = 1,
        category = "general",
        coords = vector3(26.18, -1347.13, 29.5),
        size = "small",
        name = "Strawberry Ave",
        price = Config.ShopPrices.small,
    },
    {
        id = 2,
        category = "general",
        coords = vector3(373.55, 325.52, 103.57),
        size = "medium",
        name = "Downtown Vinewood",
        price = Config.ShopPrices.medium,
    },
    {
        id = 3,
        category = "electronics",
        coords = vector3(-657.18, -854.4, 24.5),
        size = "medium",
        name = "Little Seoul Electronics",
        price = Config.ShopPrices.medium,
    },
    -- Add more shops here
}

-- Inventory settings
Config.MaxItemsPerRestock = 100 -- maximum amount of items to restock at once
Config.RestockCooldown = 30 -- minutes between restocks
Config.ProfitMargin = {
    min = 1.1, -- minimum markup (10%)
    max = 2.0  -- maximum markup (100%)
}

-- Robbery settings
Config.MinPoliceForRobbery = 2 -- minimum police online to start a robbery
Config.RobberyBasePayout = 1000 -- base payout for robberies
Config.RobberyPayoutMultiplier = {
    small = 1.0,
    medium = 1.5,
    large = 2.0
}
Config.RobberyCooldown = 60 -- minutes before a shop can be robbed again
Config.RobberyDuration = {
    min = 60, -- seconds
    max = 120 -- seconds
}
Config.RobberyBlipDuration = 180 -- seconds the robbery blip stays on the map

-- Supplier settings (for shop owners to order inventory)
Config.Suppliers = {
    general = {
        name = "General Goods Supplier",
        discount = 0.2, -- 20% discount on bulk orders
        minOrderQuantity = 10
    },
    electronics = {
        name = "Tech Hub Distributors",
        discount = 0.15,
        minOrderQuantity = 5
    },
    weapons = {
        name = "Ammu-Nation Wholesale",
        discount = 0.1,
        minOrderQuantity = 3
    },
    pharmacies = {
        name = "Medical Supplies Inc.",
        discount = 0.25,
        minOrderQuantity = 15
    },
    liquor = {
        name = "Liquid Gold Distributors",
        discount = 0.2,
        minOrderQuantity = 12
    }
}

-- Default items that can be sold in shops by category
Config.DefaultItems = {
    general = {
        {name = "bread", price = 10, label = "Bread", maxStock = 50},
        {name = "water", price = 5, label = "Water", maxStock = 50},
        {name = "sandwich", price = 15, label = "Sandwich", maxStock = 35},
        {name = "chocolate", price = 8, label = "Chocolate", maxStock = 30},
        {name = "cola", price = 12, label = "Cola", maxStock = 40},
        {name = "phone", price = 250, label = "Phone", maxStock = 10},
        {name = "cigarette", price = 10, label = "Cigarette", maxStock = 25},
        {name = "lighter", price = 15, label = "Lighter", maxStock = 15},
    },
    electronics = {
        {name = "phone", price = 200, label = "Phone", maxStock = 20},
        {name = "radio", price = 150, label = "Radio", maxStock = 15},
        {name = "laptop", price = 1000, label = "Laptop", maxStock = 5},
        {name = "binoculars", price = 120, label = "Binoculars", maxStock = 10},
        {name = "camera", price = 180, label = "Camera", maxStock = 10},
    },
    weapons = {
        {name = "WEAPON_KNIFE", price = 1000, label = "Knife", maxStock = 5},
        {name = "WEAPON_BAT", price = 1000, label = "Bat", maxStock = 5},
        {name = "WEAPON_PISTOL", price = 10000, label = "Pistol", maxStock = 2},
        {name = "pistol_ammo", price = 100, label = "Pistol Ammo", maxStock = 20},
    },
    pharmacies = {
        {name = "bandage", price = 50, label = "Bandage", maxStock = 30},
        {name = "medikit", price = 200, label = "Medikit", maxStock = 15},
        {name = "firstaid", price = 100, label = "First Aid Kit", maxStock = 20},
        {name = "painkillers", price = 75, label = "Painkillers", maxStock = 25},
    },
    liquor = {
        {name = "beer", price = 25, label = "Beer", maxStock = 40},
        {name = "vodka", price = 90, label = "Vodka", maxStock = 20},
        {name = "whiskey", price = 120, label = "Whiskey", maxStock = 15},
        {name = "tequila", price = 100, label = "Tequila", maxStock = 15},
        {name = "wine", price = 80, label = "Wine", maxStock = 25},
    }
}

-- Analytics and metrics
Config.EnableMetrics = true
Config.WebhookURL = "" -- Discord webhook for important shop events

-- Item metadata support (for ox_inventory)
Config.UseItemMetadata = true
Config.CustomizableItems = {
    sandwich = {
        basePrice = 15,
        options = {
            ingredients = {
                {name = "cheese", label = "Cheese", price = 2},
                {name = "tomato", label = "Tomato", price = 1},
                {name = "lettuce", label = "Lettuce", price = 1},
                {name = "bacon", label = "Bacon", price = 3},
                {name = "egg", label = "Egg", price = 2},
            }
        }
    },
    coffee = {
        basePrice = 10,
        options = {
            extras = {
                {name = "sugar", label = "Sugar", price = 1},
                {name = "milk", label = "Milk", price = 1},
                {name = "vanilla", label = "Vanilla Flavor", price = 2},
                {name = "caramel", label = "Caramel Flavor", price = 2},
            }
        }
    }
}