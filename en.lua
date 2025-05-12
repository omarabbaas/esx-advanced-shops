Locales = {}

Locales['en'] = {
    -- General
    ['shop_blip'] = 'Shop',
    ['shop_center'] = 'Shop Center',
    ['press_to_open'] = 'Press ~INPUT_CONTEXT~ to open the shop',
    ['press_to_rob'] = 'Press ~INPUT_CONTEXT~ to rob the shop',
    ['press_to_manage'] = 'Press ~INPUT_CONTEXT~ to manage your shop',
    ['not_enough_money'] = 'You don\'t have enough money',
    ['not_enough_space'] = 'You don\'t have enough space in your inventory',
    ['not_enough_stock'] = 'This shop doesn\'t have enough stock',
    ['inventory_full'] = 'Your inventory is full',
    ['purchase_success'] = 'You purchased %s x%d for $%s',
    ['cannot_carry'] = 'You cannot carry any more %s',
    
    -- Shop Center
    ['shop_center_title'] = 'Shop Center',
    ['buy_shop'] = 'Buy a shop',
    ['shop_name'] = 'Shop Name: %s',
    ['shop_price'] = 'Price: $%s',
    ['shop_category'] = 'Category: %s',
    ['shop_location'] = 'Location: %s',
    ['shop_size'] = 'Size: %s',
    ['shop_bought'] = 'You bought the shop %s for $%s',
    ['not_enough_money_shop'] = 'You don\'t have enough money to buy this shop',
    ['already_owned'] = 'This shop is already owned',
    ['enter_shop_name'] = 'Enter shop name',
    ['invalid_name'] = 'Invalid shop name',
    
    -- Shop Management
    ['management_title'] = 'Shop Management',
    ['stock_management'] = 'Stock Management',
    ['employee_management'] = 'Employee Management',
    ['finances'] = 'Finances',
    ['shop_settings'] = 'Shop Settings',
    ['order_stock'] = 'Order Stock',
    ['current_stock'] = 'Current Stock',
    ['sell_shop'] = 'Sell Shop',
    ['close_shop'] = 'Close Shop',
    ['open_shop'] = 'Open Shop',
    ['shop_sold'] = 'You sold the shop for $%s',
    ['shop_closed'] = 'Shop is now closed',
    ['shop_opened'] = 'Shop is now open',
    
    -- Stock Management
    ['stock_title'] = 'Stock Management',
    ['add_item'] = 'Add Item',
    ['remove_item'] = 'Remove Item',
    ['adjust_price'] = 'Adjust Price',
    ['current_items'] = 'Current Items',
    ['item_name'] = 'Item: %s',
    ['item_stock'] = 'Stock: %d/%d',
    ['item_price'] = 'Price: $%s',
    ['adjust_price_prompt'] = 'Enter new price for %s (min: $%s, max: $%s):',
    ['invalid_price'] = 'Invalid price',
    ['price_updated'] = 'Price updated to $%s',
    ['add_stock_prompt'] = 'How many %s would you like to add? (max: %d)',
    ['remove_stock_prompt'] = 'How many %s would you like to remove? (max: %d)',
    ['stock_added'] = 'Added %d %s to stock',
    ['stock_removed'] = 'Removed %d %s from stock',
    
    -- Employee Management
    ['employee_title'] = 'Employee Management',
    ['add_employee'] = 'Add Employee',
    ['remove_employee'] = 'Remove Employee',
    ['current_employees'] = 'Current Employees',
    ['employee_name'] = 'Name: %s',
    ['employee_permission'] = 'Permission: %s',
    ['enter_employee_id'] = 'Enter employee ID',
    ['invalid_id'] = 'Invalid ID',
    ['employee_added'] = 'Employee added',
    ['employee_removed'] = 'Employee removed',
    ['already_employee'] = 'This person is already an employee',
    ['not_employee'] = 'This person is not an employee',
    
    -- Finances
    ['finances_title'] = 'Finances',
    ['total_sales'] = 'Total Sales: $%s',
    ['total_profit'] = 'Total Profit: $%s',
    ['sales_today'] = 'Sales Today: $%s',
    ['profit_today'] = 'Profit Today: $%s',
    ['withdraw_money'] = 'Withdraw Money',
    ['deposit_money'] = 'Deposit Money',
    ['withdraw_prompt'] = 'How much would you like to withdraw? (Available: $%s)',
    ['deposit_prompt'] = 'How much would you like to deposit?',
    ['invalid_amount'] = 'Invalid amount',
    ['money_withdrawn'] = 'You withdrew $%s',
    ['money_deposited'] = 'You deposited $%s',
    
    -- Ordering
    ['order_title'] = 'Order Stock',
    ['supplier'] = 'Supplier: %s',
    ['discount'] = 'Bulk Discount: %s%%',
    ['min_order'] = 'Minimum Order: %d',
    ['order_prompt'] = 'How many %s would you like to order? (min: %d)',
    ['order_cost'] = 'Order Cost: $%s',
    ['order_confirm'] = 'Confirm order: %d x %s for $%s?',
    ['order_placed'] = 'Order placed. Delivery expected in %d minutes',
    ['not_enough_shop_money'] = 'Not enough money in shop account',
    ['order_cancelled'] = 'Order cancelled',
    
    -- Robbery
    ['robbery_started'] = 'Shop robbery started. Police have been notified!',
    ['robbery_cancelled'] = 'The robbery was cancelled',
    ['robbery_complete'] = 'Robbery complete! You stole $%s',
    ['police_notify'] = 'Shop robbery in progress at %s',
    ['min_police'] = 'Not enough police in the city',
    ['cooldown_active'] = 'This shop was recently robbed. Try again later',
    ['shop_empty'] = 'This shop has no money to steal',
    ['stay_close'] = 'Stay close to the register!',
    
    -- Permissions
    ['no_permission'] = 'You don\'t have permission to do this',
    ['must_be_owner'] = 'You must be the owner to do this',
    ['weapon_license_required'] = 'You need a weapon license to buy this',
    
    -- Jobs
    ['job_restriction'] = 'This action is restricted to certain jobs',
    
    -- Custom items
    ['customize_item'] = 'Customize item',
    ['base_price'] = 'Base price: $%s',
    ['customization_options'] = 'Customization options',
    ['add_ingredient'] = 'Add %s (+$%s)',
    ['total_price'] = 'Total price: $%s',
    
    -- Misc
    ['yes'] = 'Yes',
    ['no'] = 'No',
    ['confirm'] = 'Confirm',
    ['cancel'] = 'Cancel',
    ['back'] = 'Back',
    ['small'] = 'Small',
    ['medium'] = 'Medium',
    ['large'] = 'Large',
}