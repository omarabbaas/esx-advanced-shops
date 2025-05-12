// Management functions
function openStockManagement() {
    $.post('https://esx_advanced_shops/getStockManagement', {}, function(data) {
        // Handle response
        if (data.items) {
            showStockManagementDialog(data.items);
        }
    });
}

function openEmployeeManagement() {
    $.post('https://esx_advanced_shops/getEmployeeManagement', {}, function(data) {
        // Handle response
        if (data.employees) {
            showEmployeeManagementDialog(data.employees);
        }
    });
}

function openFinancesManagement() {
    $.post('https://esx_advanced_shops/getFinances', {}, function(data) {
        // Handle response
        if (data.finances) {
            showFinancesDialog(data.finances);
        }
    });
}

function openShopSettings() {
    $.post('https://esx_advanced_shops/getShopSettings', {}, function(data) {
        // Handle response
        if (data.settings) {
            showShopSettingsDialog(data.settings);
        }
    });
}

function openOrderManagement() {
    $.post('https://esx_advanced_shops/getOrderableItems', {}, function(data) {
        // Handle response
        if (data.items) {
            showOrderDialog(data.items, data.supplier);
        }
    });
}

// Management dialog functions
function showStockManagementDialog(items) {
    let content = `
        <div class="stock-management">
            <div class="search-container">
                <input type="text" id="search-stock" placeholder="Search items...">
            </div>
            <div class="items-list">
    `;
    
    items.forEach(item => {
        content += `
            <div class="stock-item" data-name="${item.name}">
                <div class="stock-item-info">
                    <img src="nui://ox_inventory/web/images/${item.name}.png" onerror="this.src='img/default.png'" class="stock-item-img">
                    <div>
                        <div class="stock-item-name">${item.label}</div>
                        <div class="stock-item-price">$${item.price.toLocaleString()}</div>
                        <div class="stock-item-stock">Stock: ${item.stock}/${item.max_stock}</div>
                    </div>
                </div>
                <div class="stock-item-actions">
                    <button class="stock-btn add-stock"><i class="fas fa-plus"></i> Add</button>
                    <button class="stock-btn remove-stock"><i class="fas fa-minus"></i> Remove</button>
                    <button class="stock-btn adjust-price"><i class="fas fa-tag"></i> Price</button>
                </div>
            </div>
        `;
    });
    
    content += `
            </div>
            <button class="add-new-item-btn"><i class="fas fa-plus-circle"></i> Add New Item</button>
        </div>
    `;
    
    const dialog = `
        <div class="dialog-overlay">
            <div class="dialog wide-dialog">
                <div class="dialog-header">
                    <h2>Stock Management</h2>
                </div>
                <div class="dialog-content">
                    ${content}
                </div>
                <div class="dialog-actions">
                    <button class="dialog-btn close">Close</button>
                </div>
            </div>
        </div>
    `;
    
    $('body').append(dialog);
    
    // Search functionality
    $('#search-stock').on('input', function() {
        const searchTerm = $(this).val().toLowerCase();
        
        $('.stock-item').each(function() {
            const itemName = $(this).find('.stock-item-name').text().toLowerCase();
            
            if (itemName.includes(searchTerm)) {
                $(this).show();
            } else {
                $(this).hide();
            }
        });
    });
    
    // Add stock button
    $('.add-stock').click(function() {
        const itemName = $(this).closest('.stock-item').data('name');
        const item = items.find(i => i.name === itemName);
        
        inputDialog('Add Stock', `How many ${item.label} would you like to add?`, '1', function(value) {
            const amount = parseInt(value);
            
            if (isNaN(amount) || amount <= 0) {
                showNotification('Invalid amount');
                return;
            }
            
            // Add stock
            $.post('https://esx_advanced_shops/addStock', JSON.stringify({
                item: itemName,
                amount: amount
            }));
            
            $('.dialog-overlay').remove();
        });
    });
    
    // Remove stock button
    $('.remove-stock').click(function() {
        const itemName = $(this).closest('.stock-item').data('name');
        const item = items.find(i => i.name === itemName);
        
        inputDialog('Remove Stock', `How many ${item.label} would you like to remove?`, '1', function(value) {
            const amount = parseInt(value);
            
            if (isNaN(amount) || amount <= 0 || amount > item.stock) {
                showNotification('Invalid amount');
                return;
            }
            
            // Remove stock
            $.post('https://esx_advanced_shops/removeStock', JSON.stringify({
                item: itemName,
                amount: amount
            }));
            
            $('.dialog-overlay').remove();
        });
    });
    
    // Adjust price button
    $('.adjust-price').click(function() {
        const itemName = $(this).closest('.stock-item').data('name');
        const item = items.find(i => i.name === itemName);
        
        inputDialog('Adjust Price', `Enter new price for ${item.label}:`, item.price, function(value) {
            const price = parseInt(value);
            
            if (isNaN(price) || price <= 0) {
                showNotification('Invalid price');
                return;
            }
            
            // Update price
            $.post('https://esx_advanced_shops/updatePrice', JSON.stringify({
                item: itemName,
                price: price
            }));
            
            $('.dialog-overlay').remove();
        });
    });
    
    // Add new item button
    $('.add-new-item-btn').click(function() {
        $.post('https://esx_advanced_shops/getAddableItems', {}, function(data) {
            if (data.items && data.items.length > 0) {
                showAddItemDialog(data.items);
            } else {
                showNotification('No items available to add');
            }
        });
    });
    
    // Close button
    $('.dialog-btn.close').click(function() {
        $('.dialog-overlay').remove();
    });
}

function showAddItemDialog(items) {
    let content = `
        <div class="add-item-dialog">
            <div class="search-container">
                <input type="text" id="search-add-items" placeholder="Search items...">
            </div>
            <div class="add-items-list">
    `;
    
    items.forEach(item => {
        content += `
            <div class="add-item" data-name="${item.name}" data-price="${item.price}">
                <div class="add-item-info">
                    <img src="nui://ox_inventory/web/images/${item.name}.png" onerror="this.src='img/default.png'" class="add-item-img">
                    <div>
                        <div class="add-item-name">${item.label}</div>
                        <div class="add-item-type">${item.type}</div>
                    </div>
                </div>
                <button class="add-this-item-btn"><i class="fas fa-plus"></i></button>
            </div>
        `;
    });
    
    content += `
            </div>
        </div>
    `;
    
    const dialog = `
        <div class="dialog-overlay">
            <div class="dialog wide-dialog">
                <div class="dialog-header">
                    <h2>Add New Item</h2>
                </div>
                <div class="dialog-content">
                    ${content}
                </div>
                <div class="dialog-actions">
                    <button class="dialog-btn cancel">Cancel</button>
                </div>
            </div>
        </div>
    `;
    
    $('body').append(dialog);
    
    // Search functionality
    $('#search-add-items').on('input', function() {
        const searchTerm = $(this).val().toLowerCase();
        
        $('.add-item').each(function() {
            const itemName = $(this).find('.add-item-name').text().toLowerCase();
            
            if (itemName.includes(searchTerm)) {
                $(this).show();
            } else {
                $(this).hide();
            }
        });
    });
    
    // Add item button
    $('.add-this-item-btn').click(function() {
        const itemElement = $(this).closest('.add-item');
        const itemName = itemElement.data('name');
        const suggestedPrice = itemElement.data('price');
        const item = items.find(i => i.name === itemName);
        
        // Show config dialog
        configureNewItemDialog(item, suggestedPrice);
    });
    
    // Cancel button
    $('.dialog-btn.cancel').click(function() {
        $('.dialog-overlay').remove();
    });
}

function configureNewItemDialog(item, suggestedPrice) {
    const content = `
        <div class="configure-item-form">
            <div class="form-group">
                <label>Item: ${item.label}</label>
            </div>
            <div class="form-group">
                <label>Selling Price:</label>
                <input type="number" id="new-item-price" min="1" value="${suggestedPrice}">
            </div>
            <div class="form-group">
                <label>Max Stock:</label>
                <input type="number" id="new-item-max-stock" min="1" value="20">
            </div>
        </div>
    `;
    
    $('.dialog-overlay').remove();
    
    const dialog = `
        <div class="dialog-overlay">
            <div class="dialog">
                <div class="dialog-header">
                    <h2>Configure Item</h2>
                </div>
                <div class="dialog-content">
                    ${content}
                </div>
                <div class="dialog-actions">
                    <button class="dialog-btn cancel">Cancel</button>
                    <button class="dialog-btn confirm">Add Item</button>
                </div>
            </div>
        </div>
    `;
    
    $('body').append(dialog);
    
    // Cancel button
    $('.dialog-btn.cancel').click(function() {
        $('.dialog-overlay').remove();
    });
    
    // Confirm button
    $('.dialog-btn.confirm').click(function() {
        const price = parseInt($('#new-item-price').val());
        const maxStock = parseInt($('#new-item-max-stock').val());
        
        if (isNaN(price) || price <= 0) {
            showNotification('Invalid price');
            return;
        }
        
        if (isNaN(maxStock) || maxStock <= 0) {
            showNotification('Invalid max stock');
            return;
        }
        
        // Add item
        $.post('https://esx_advanced_shops/addNewItem', JSON.stringify({
            item: item.name,
            price: price,
            maxStock: maxStock
        }));
        
        $('.dialog-overlay').remove();
    });
}

function showEmployeeManagementDialog(employees) {
    let content = `
        <div class="employee-management">
            <div class="employees-list">
    `;
    
    if (employees.length === 0) {
        content += `<p>No employees</p>`;
    } else {
        employees.forEach(employee => {
            content += `
                <div class="employee-item" data-identifier="${employee.identifier}">
                    <div class="employee-info">
                        <div class="employee-name">${employee.name}</div>
                        <div class="employee-grade">Grade: ${employee.grade === 1 ? 'Cashier' : 'Manager'}</div>
                    </div>
                    <div class="employee-actions">
                        <button class="employee-btn change-grade"><i class="fas fa-user-cog"></i></button>
                        <button class="employee-btn remove-employee"><i class="fas fa-user-minus"></i></button>
                    </div>
                </div>
            `;
        });
    }
    
    content += `
            </div>
            <button class="add-employee-btn"><i class="fas fa-user-plus"></i> Add Employee</button>
        </div>
    `;
    
    const dialog = `
        <div class="dialog-overlay">
            <div class="dialog">
                <div class="dialog-header">
                    <h2>Employee Management</h2>
                </div>
                <div class="dialog-content">
                    ${content}
                </div>
                <div class="dialog-actions">
                    <button class="dialog-btn close">Close</button>
                </div>
            </div>
        </div>
    `;
    
    $('body').append(dialog);
    
    // Change grade button
    $('.change-grade').click(function() {
        const identifier = $(this).closest('.employee-item').data('identifier');
        const employee = employees.find(e => e.identifier === identifier);
        
        const grades = [
            { value: 1, label: 'Cashier' },
            { value: 2, label: 'Manager' }
        ];
        
        let gradesContent = '';
        
        grades.forEach(grade => {
            gradesContent += `
                <div class="grade-option${employee.grade === grade.value ? ' selected' : ''}" data-value="${grade.value}">
                    <div class="grade-name">${grade.label}</div>
                    <div class="grade-description">Permission level: ${grade.value}</div>
                </div>
            `;
        });
        
        const gradeDialog = `
            <div class="dialog-overlay">
                <div class="dialog">
                    <div class="dialog-header">
                        <h2>Change Grade</h2>
                    </div>
                    <div class="dialog-content">
                        <div class="grades-list">
                            ${gradesContent}
                        </div>
                    </div>
                    <div class="dialog-actions">
                        <button class="dialog-btn cancel">Cancel</button>
                        <button class="dialog-btn confirm">Confirm</button>
                    </div>
                </div>
            </div>
        `;
        
        $('.dialog-overlay').remove();
        $('body').append(gradeDialog);
        
       // Select grade
        $('.grade-option').click(function() {
            $('.grade-option').removeClass('selected');
            $(this).addClass('selected');
        });
        
        // Cancel button
        $('.dialog-btn.cancel').click(function() {
            $('.dialog-overlay').remove();
            showEmployeeManagementDialog(employees);
        });
        
        // Confirm button
        $('.dialog-btn.confirm').click(function() {
            const grade = $('.grade-option.selected').data('value');
            
            // Update grade
            $.post('https://esx_advanced_shops/updateEmployeeGrade', JSON.stringify({
                identifier: identifier,
                grade: grade
            }));
            
            $('.dialog-overlay').remove();
        });
    });
    
    // Remove employee button
    $('.remove-employee').click(function() {
        const identifier = $(this).closest('.employee-item').data('identifier');
        const employee = employees.find(e => e.identifier === identifier);
        
        confirmDialog('Remove Employee', `Are you sure you want to remove ${employee.name}?`, function() {
            // Remove employee
            $.post('https://esx_advanced_shops/removeEmployee', JSON.stringify({
                identifier: identifier
            }));
            
            $('.dialog-overlay').remove();
        });
    });
    
    // Add employee button
    $('.add-employee-btn').click(function() {
        $.post('https://esx_advanced_shops/getNearbyPlayers', {}, function(data) {
            if (data.players && data.players.length > 0) {
                showAddEmployeeDialog(data.players);
            } else {
                showNotification('No players nearby');
            }
        });
    });
    
    // Close button
    $('.dialog-btn.close').click(function() {
        $('.dialog-overlay').remove();
    });
}

function showAddEmployeeDialog(players) {
    let content = `
        <div class="add-employee-dialog">
            <div class="players-list">
    `;
    
    players.forEach(player => {
        content += `
            <div class="player-item" data-id="${player.id}" data-identifier="${player.identifier}" data-name="${player.name}">
                <div class="player-name">${player.name}</div>
                <button class="add-player-btn"><i class="fas fa-plus"></i></button>
            </div>
        `;
    });
    
    content += `
            </div>
        </div>
    `;
    
    const dialog = `
        <div class="dialog-overlay">
            <div class="dialog">
                <div class="dialog-header">
                    <h2>Add Employee</h2>
                </div>
                <div class="dialog-content">
                    ${content}
                </div>
                <div class="dialog-actions">
                    <button class="dialog-btn cancel">Cancel</button>
                </div>
            </div>
        </div>
    `;
    
    $('.dialog-overlay').remove();
    $('body').append(dialog);
    
    // Add player button
    $('.add-player-btn').click(function() {
        const player = {
            id: $(this).closest('.player-item').data('id'),
            identifier: $(this).closest('.player-item').data('identifier'),
            name: $(this).closest('.player-item').data('name')
        };
        
        // Show grade selection dialog
        selectEmployeeGradeDialog(player);
    });
    
    // Cancel button
    $('.dialog-btn.cancel').click(function() {
        $('.dialog-overlay').remove();
    });
}

function selectEmployeeGradeDialog(player) {
    const grades = [
        { value: 1, label: 'Cashier', description: 'Can sell items' },
        { value: 2, label: 'Manager', description: 'Can manage stock and employees' }
    ];
    
    let content = `
        <div class="select-grade-dialog">
            <div class="player-info">
                <div class="player-name">${player.name}</div>
            </div>
            <div class="grades-list">
    `;
    
    grades.forEach(grade => {
        content += `
            <div class="grade-option" data-value="${grade.value}">
                <div class="grade-name">${grade.label}</div>
                <div class="grade-description">${grade.description}</div>
            </div>
        `;
    });
    
    content += `
            </div>
        </div>
    `;
    
    const dialog = `
        <div class="dialog-overlay">
            <div class="dialog">
                <div class="dialog-header">
                    <h2>Select Grade</h2>
                </div>
                <div class="dialog-content">
                    ${content}
                </div>
                <div class="dialog-actions">
                    <button class="dialog-btn cancel">Cancel</button>
                    <button class="dialog-btn confirm">Add Employee</button>
                </div>
            </div>
        </div>
    `;
    
    $('.dialog-overlay').remove();
    $('body').append(dialog);
    
    // Select grade
    $('.grade-option').click(function() {
        $('.grade-option').removeClass('selected');
        $(this).addClass('selected');
    });
    
    // Auto-select first grade
    $('.grade-option').first().addClass('selected');
    
    // Cancel button
    $('.dialog-btn.cancel').click(function() {
        $('.dialog-overlay').remove();
    });
    
    // Confirm button
    $('.dialog-btn.confirm').click(function() {
        const grade = $('.grade-option.selected').data('value');
        
        if (!grade) {
            showNotification('Please select a grade');
            return;
        }
        
        // Add employee
        $.post('https://esx_advanced_shops/addEmployee', JSON.stringify({
            identifier: player.identifier,
            name: player.name,
            grade: grade
        }));
        
        $('.dialog-overlay').remove();
    });
}

function showFinancesDialog(finances) {
    const content = `
        <div class="finances-dialog">
            <div class="finances-summary">
                <div class="finance-item">
                    <div class="finance-label">Balance</div>
                    <div class="finance-value">$${finances.balance.toLocaleString()}</div>
                </div>
                <div class="finance-item">
                    <div class="finance-label">Total Sales</div>
                    <div class="finance-value">$${finances.totalSales.toLocaleString()}</div>
                </div>
                <div class="finance-item">
                    <div class="finance-label">Total Profit</div>
                    <div class="finance-value">$${finances.totalProfit.toLocaleString()}</div>
                </div>
                <div class="finance-item">
                    <div class="finance-label">Today's Sales</div>
                    <div class="finance-value">$${finances.todaySales.toLocaleString()}</div>
                </div>
                <div class="finance-item">
                    <div class="finance-label">Today's Profit</div>
                    <div class="finance-value">$${finances.todayProfit.toLocaleString()}</div>
                </div>
            </div>
            <div class="finances-actions">
                <button class="finance-btn withdraw"><i class="fas fa-hand-holding-usd"></i> Withdraw Money</button>
                <button class="finance-btn deposit"><i class="fas fa-money-bill-wave"></i> Deposit Money</button>
            </div>
        </div>
    `;
    
    const dialog = `
        <div class="dialog-overlay">
            <div class="dialog">
                <div class="dialog-header">
                    <h2>Finances</h2>
                </div>
                <div class="dialog-content">
                    ${content}
                </div>
                <div class="dialog-actions">
                    <button class="dialog-btn close">Close</button>
                </div>
            </div>
        </div>
    `;
    
    $('body').append(dialog);
    
    // Withdraw button
    $('.finance-btn.withdraw').click(function() {
        if (finances.balance <= 0) {
            showNotification('No money to withdraw');
            return;
        }
        
        inputDialog('Withdraw Money', 'Amount:', finances.balance, function(value) {
            const amount = parseInt(value);
            
            if (isNaN(amount) || amount <= 0 || amount > finances.balance) {
                showNotification('Invalid amount');
                return;
            }
            
            // Withdraw money
            $.post('https://esx_advanced_shops/withdrawMoney', JSON.stringify({
                amount: amount
            }));
            
            $('.dialog-overlay').remove();
        });
    });
    
    // Deposit button
    $('.finance-btn.deposit').click(function() {
        inputDialog('Deposit Money', 'Amount:', '1000', function(value) {
            const amount = parseInt(value);
            
            if (isNaN(amount) || amount <= 0) {
                showNotification('Invalid amount');
                return;
            }
            
            // Deposit money
            $.post('https://esx_advanced_shops/depositMoney', JSON.stringify({
                amount: amount
            }));
            
            $('.dialog-overlay').remove();
        });
    });
    
    // Close button
    $('.dialog-btn.close').click(function() {
        $('.dialog-overlay').remove();
    });
}

function showShopSettingsDialog(settings) {
    const content = `
        <div class="settings-dialog">
            <div class="setting-item">
                <div class="setting-label">Shop Name</div>
                <div class="setting-value">${settings.name}</div>
                <button class="setting-btn rename"><i class="fas fa-edit"></i></button>
            </div>
            <div class="setting-item">
                <div class="setting-label">Shop Status</div>
                <div class="setting-value">${settings.open ? 'Open' : 'Closed'}</div>
                <button class="setting-btn toggle-status">${settings.open ? '<i class="fas fa-door-closed"></i> Close' : '<i class="fas fa-door-open"></i> Open'}</button>
            </div>
            <div class="setting-item">
                <div class="setting-label">Blip Color</div>
                <div class="setting-value">Color: ${settings.blipColor}</div>
                <button class="setting-btn change-blip"><i class="fas fa-palette"></i></button>
            </div>
            <div class="setting-item">
                <div class="setting-label">Sell Shop</div>
                <div class="setting-value">Sell Value: $${Math.floor(settings.price * 0.7).toLocaleString()}</div>
                <button class="setting-btn sell-shop"><i class="fas fa-dollar-sign"></i></button>
            </div>
        </div>
    `;
    
    const dialog = `
        <div class="dialog-overlay">
            <div class="dialog">
                <div class="dialog-header">
                    <h2>Shop Settings</h2>
                </div>
                <div class="dialog-content">
                    ${content}
                </div>
                <div class="dialog-actions">
                    <button class="dialog-btn close">Close</button>
                </div>
            </div>
        </div>
    `;
    
    $('body').append(dialog);
    
    // Rename button
    $('.setting-btn.rename').click(function() {
        inputDialog('Rename Shop', 'New Name:', settings.name, function(value) {
            if (!value || value.length < 3) {
                showNotification('Name too short');
                return;
            }
            
            // Rename shop
            $.post('https://esx_advanced_shops/renameShop', JSON.stringify({
                name: value
            }));
            
            $('.dialog-overlay').remove();
        });
    });
    
    // Toggle status button
    $('.setting-btn.toggle-status').click(function() {
        const newStatus = !settings.open;
        
        // Update status
        $.post('https://esx_advanced_shops/setShopStatus', JSON.stringify({
            open: newStatus
        }));
        
        $('.dialog-overlay').remove();
    });
    
    // Change blip button
    $('.setting-btn.change-blip').click(function() {
        showBlipColorDialog(settings.blipColor);
    });
    
    // Sell shop button
    $('.setting-btn.sell-shop').click(function() {
        const sellValue = Math.floor(settings.price * 0.7);
        
        confirmDialog('Sell Shop', `Are you sure you want to sell your shop for $${sellValue.toLocaleString()}?`, function() {
            // Sell shop
            $.post('https://esx_advanced_shops/sellShop');
            
            $('.dialog-overlay').remove();
            closeShop();
        });
    });
    
    // Close button
    $('.dialog-btn.close').click(function() {
        $('.dialog-overlay').remove();
    });
}

function showBlipColorDialog(currentColor) {
    let content = `
        <div class="blip-color-dialog">
            <div class="blip-colors">
    `;
    
    // Add color options
    for (let i = 0; i <= 85; i++) {
        content += `
            <div class="blip-color${currentColor === i ? ' selected' : ''}" data-color="${i}" style="background-color: ${getBlipColorHex(i)}"></div>
        `;
    }
    
    content += `
            </div>
        </div>
    `;
    
    const dialog = `
        <div class="dialog-overlay">
            <div class="dialog wide-dialog">
                <div class="dialog-header">
                    <h2>Change Blip Color</h2>
                </div>
                <div class="dialog-content">
                    ${content}
                </div>
                <div class="dialog-actions">
                    <button class="dialog-btn cancel">Cancel</button>
                    <button class="dialog-btn confirm">Confirm</button>
                </div>
            </div>
        </div>
    `;
    
    $('.dialog-overlay').remove();
    $('body').append(dialog);
    
    // Select color
    $('.blip-color').click(function() {
        $('.blip-color').removeClass('selected');
        $(this).addClass('selected');
    });
    
    // Cancel button
    $('.dialog-btn.cancel').click(function() {
        $('.dialog-overlay').remove();
    });
    
    // Confirm button
    $('.dialog-btn.confirm').click(function() {
        const color = $('.blip-color.selected').data('color');
        
        // Update blip color
        $.post('https://esx_advanced_shops/updateBlipColor', JSON.stringify({
            color: color
        }));
        
        $('.dialog-overlay').remove();
    });
}

function showOrderDialog(items, supplier) {
    let content = `
        <div class="order-dialog">
            <div class="supplier-info">
                <div class="supplier-name">${supplier.name}</div>
                <div class="supplier-discount">Discount: ${Math.floor(supplier.discount * 100)}%</div>
                <div class="supplier-min-order">Minimum Order: ${supplier.minOrderQuantity}</div>
            </div>
            <div class="search-container">
                <input type="text" id="search-order-items" placeholder="Search items...">
            </div>
            <div class="orderable-items">
    `;
    
    items.forEach(item => {
        const discountedPrice = Math.floor(item.price * (1 - supplier.discount));
        
        content += `
            <div class="orderable-item" data-name="${item.name}" data-price="${discountedPrice}" data-label="${item.label}">
                <div class="orderable-item-info">
                    <img src="nui://ox_inventory/web/images/${item.name}.png" onerror="this.src='img/default.png'" class="orderable-item-img">
                    <div>
                        <div class="orderable-item-name">${item.label}</div>
                        <div class="orderable-item-price">Price: $${discountedPrice.toLocaleString()} (${Math.floor(supplier.discount * 100)}% off)</div>
                    </div>
                </div>
                <button class="order-item-btn"><i class="fas fa-truck"></i> Order</button>
            </div>
        `;
    });
    
    content += `
            </div>
        </div>
    `;
    
    const dialog = `
        <div class="dialog-overlay">
            <div class="dialog wide-dialog">
                <div class="dialog-header">
                    <h2>Order Stock</h2>
                </div>
                <div class="dialog-content">
                    ${content}
                </div>
                <div class="dialog-actions">
                    <button class="dialog-btn close">Close</button>
                </div>
            </div>
        </div>
    `;
    
    $('body').append(dialog);
    
    // Search functionality
    $('#search-order-items').on('input', function() {
        const searchTerm = $(this).val().toLowerCase();
        
        $('.orderable-item').each(function() {
            const itemName = $(this).find('.orderable-item-name').text().toLowerCase();
            
            if (itemName.includes(searchTerm)) {
                $(this).show();
            } else {
                $(this).hide();
            }
        });
    });
    
    // Order button
    $('.order-item-btn').click(function() {
        const itemElement = $(this).closest('.orderable-item');
        const itemName = itemElement.data('name');
        const itemPrice = itemElement.data('price');
        const itemLabel = itemElement.data('label');
        
        orderItemDialog(itemName, itemLabel, itemPrice, supplier.minOrderQuantity);
    });
    
    // Close button
    $('.dialog-btn.close').click(function() {
        $('.dialog-overlay').remove();
    });
}

function orderItemDialog(itemName, itemLabel, price, minQuantity) {
    const content = `
        <div class="order-item-form">
            <div class="form-group">
                <label>Item: ${itemLabel}</label>
            </div>
            <div class="form-group">
                <label>Price per Unit: $${price.toLocaleString()}</label>
            </div>
            <div class="form-group">
                <label>Quantity (min: ${minQuantity}):</label>
                <input type="number" id="order-quantity" min="${minQuantity}" value="${minQuantity}">
            </div>
            <div class="form-group">
                <label>Total Cost: $<span id="order-total-cost">${(price * minQuantity).toLocaleString()}</span></label>
            </div>
        </div>
    `;
    
    const dialog = `
        <div class="dialog-overlay">
            <div class="dialog">
                <div class="dialog-header">
                    <h2>Order Item</h2>
                </div>
                <div class="dialog-content">
                    ${content}
                </div>
                <div class="dialog-actions">
                    <button class="dialog-btn cancel">Cancel</button>
                    <button class="dialog-btn confirm">Place Order</button>
                </div>
            </div>
        </div>
    `;
    
    $('.dialog-overlay').remove();
    $('body').append(dialog);
    
    // Update total cost when quantity changes
    $('#order-quantity').on('input', function() {
        const quantity = parseInt($(this).val());
        
        if (!isNaN(quantity) && quantity >= minQuantity) {
            const totalCost = price * quantity;
            $('#order-total-cost').text(totalCost.toLocaleString());
        }
    });
    
    // Cancel button
    $('.dialog-btn.cancel').click(function() {
        $('.dialog-overlay').remove();
    });
    
    // Confirm button
    $('.dialog-btn.confirm').click(function() {
        const quantity = parseInt($('#order-quantity').val());
        
        if (isNaN(quantity) || quantity < minQuantity) {
            showNotification(`Minimum order quantity is ${minQuantity}`);
            return;
        }
        
        // Place order
        $.post('https://esx_advanced_shops/orderItem', JSON.stringify({
            item: itemName,
            quantity: quantity,
            price: price
        }));
        
        $('.dialog-overlay').remove();
    });
}

// Helper function to get color hex for blip color
function getBlipColorHex(colorId) {
    const colors = [
        '#FFFFFF', // 0
        '#FF0000', // 1
        '#00FF00', // 2
        '#0000FF', // 3
        '#FFFF00', // 4
        '#FF00FF', // 5
        '#00FFFF', // 6
        '#FF8000', // 7
        '#FF0080', // 8
        '#8000FF', // 9
        '#0080FF', // 10
        // Add more colors as needed
    ];
    
    if (colorId < colors.length) {
        return colors[colorId];
    }
    
    // Generate a color based on id if not predefined
    const hue = (colorId * 37) % 360;
    return `hsl(${hue}, 80%, 50%)`;
}