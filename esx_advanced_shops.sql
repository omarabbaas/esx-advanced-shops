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

-- Insert default shops
INSERT INTO `shops` (`id`, `name`, `category`, `coords`, `size`, `price`) VALUES
(1, 'Strawberry Ave', 'general', '{"x":26.18,"y":-1347.13,"z":29.5}', 'small', 100000),
(2, 'Downtown Vinewood', 'general', '{"x":373.55,"y":325.52,"z":103.57}', 'medium', 250000),
(3, 'Little Seoul Electronics', 'electronics', '{"x":-657.18,"y":-854.4,"z":24.5}', 'medium', 250000),
(4, 'Sandy Shores', 'general', '{"x":1960.07,"y":3741.95,"z":32.34}', 'small', 100000),
(5, 'Grapeseed', 'general', '{"x":1698.09,"y":4924.11,"z":42.06}', 'small', 100000),
(6, 'Paleto Bay', 'general', '{"x":1729.72,"y":6414.47,"z":35.04}', 'medium', 200000),
(7, 'Mirror Park', 'general', '{"x":1159.46,"y":-323.68,"z":69.21}', 'small', 150000),
(8, 'Downtown Pharmacy', 'pharmacies', '{"x":318.5,"y":-1076.54,"z":29.48}', 'small', 200000),
(9, 'Davis Liquor', 'liquor', '{"x":-1486.59,"y":-378.13,"z":40.16}', 'small', 150000),
(10, 'Vespucci Beach', 'general', '{"x":-1222.33,"y":-907.25,"z":12.33}', 'small', 200000);