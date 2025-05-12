let isShopOpen = false;
let shopData = null;
let cartItems = [];
let isOwner = false;

$(document).ready(function() {
    // Listen for NUI messages
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        if (data.type === 'shop') {
            // Open shop UI
            shopData = data.result;
            isOwner = data.owner;
            
            // Initialize shop
            initializeShop();
            
            // Show UI
            $('#shop-ui').fadeIn(300);
            isShopOpen = true;
        }
    });
    
    // Close button
    $('#close-btn').click(function() {
        closeShop();
    });
    
    // Tab switching
    $('.tab-btn').click(function() {
        const tab = $(this).data('tab');
        
        // Update active tab
        $('.tab-btn').removeClass('active');
        $(this).addClass('active');
        
        // Show tab content
        $('.tab-content').hide();
        $(`#${tab}-tab`).show();
    });
    
    // Search functionality
    $('#search-items').on('input', function() {
        const searchTerm = $(this).val().toLowerCase();
        
        $('.item').each(function() {
            const itemName = $(this).find('.item-name').text().toLowerCase();
            
            if (itemName.includes(searchTerm)) {
                $(this).show();
            } else {
                $(this).hide();
            }
        });
    });
    
    // Empty cart button
    $('#empty-cart-btn').click(function() {
        confirmDialog(
            'Empty Cart',
            'Are you sure you want to empty your cart?',
            function() {
                cartItems = [];
                updateCart();
                $.post('https://esx_advanced_shops/emptycart');
            }
        );
    });
    
    // Checkout button
    $('#checkout-btn').click(function() {
        if (cartItems.length === 0) {
            showNotification('Cart is empty');
            return;
        }
        
        confirmDialog(
            'Checkout',
            `Total: $${calculateTotal()}`,
            function() {
                // Process purchase
                $.post('https://esx_advanced_shops/buy', JSON.stringify({
                    items: cartItems
                }));
                
                // Clear cart
                cartItems = [];
                updateCart();
            }
        );
    });
    
    // Management buttons
    $('.management-options button').click(function() {
        const action = $(this).data('action');
        
        // Handle management actions
        switch (action) {
            case 'stock':
                openStockManagement();
                break;
            case 'employees':
                openEmployeeManagement();
                break;
            case 'finances':
                openFinancesManagement();
                break;
            case 'settings':
                openShopSettings();
                break;
            case 'orders':
                openOrderManagement();
                break;
        }
    });
    
    // Close on ESC key
    $(document).keyup(function(e) {
        if (e.key === "Escape" && isShopOpen) {
            closeShop();
        }
    });
});

$(document).ready(function() {
    // Listen for NUI messages
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        if (data.type === 'shop') {
            // Open shop UI
            shopData = data.result;
            isOwner = data.owner;
            
            // Initialize shop
            initializeShop();
            
            // Show UI
            $('#shop-ui').fadeIn(300);
            isShopOpen = true;
        }
    });
    
    // Close button
    $('#close-btn').click(function() {
        closeShop();
    });
    
    // Tab switching
    $('.tab-btn').click(function() {
        const tab = $(this).data('tab');
        
        // Update active tab
        $('.tab-btn').removeClass('active');
        $(this).addClass('active');
        
        // Show tab content
        $('.tab-content').hide();
        $(`#${tab}-tab`).show();
    });
    
    // Search functionality
    $('#search-items').on('input', function() {
        const searchTerm = $(this).val().toLowerCase();
        
        $('.item').each(function() {
            const itemName = $(this).find('.item-name').text().toLowerCase();
            
            if (itemName.includes(searchTerm)) {
                $(this).show();
            } else {
                $(this).hide();
            }
        });
    });
    
    // Empty cart button
    $('#empty-cart-btn').click(function() {
        confirmDialog(
            'Empty Cart',
            'Are you sure you want to empty your cart?',
            function() {
                cartItems = [];
                updateCart();
                $.post('https://esx_advanced_shops/emptycart');
            }
        );
    });
    
    // Checkout button
    $('#checkout-btn').click(function() {
        if (cartItems.length === 0) {
            showNotification('Cart is empty');
            return;
        }
        
        confirmDialog(
            'Checkout',
            `Total: $${calculateTotal()}`,
            function() {
                // Process purchase
                $.post('https://esx_advanced_shops/buy', JSON.stringify({
                    items: cartItems
                }));
                
                // Clear cart
                cartItems = [];
                updateCart();
            }
        );
    });
    
    // Management buttons
    $('.management-options button').click(function() {
        const action = $(this).data('action');
        
        // Handle management actions
        switch (action) {
            case 'stock':
                openStockManagement();
                break;
            case 'employees':
                openEmployeeManagement();
                break;
            case 'finances':
                openFinancesManagement();
                break;
            case 'settings':
                openShopSettings();
                break;
            case 'orders':
                openOrderManagement();
                break;
        }
    });
    
    // Close on ESC key
    $(document).keyup(function(e) {
        if (e.key === "Escape" && isShopOpen) {
            closeShop();
        }
    });
});

// Initialize shop
function initializeShop() {
    // Set shop name
    $('#shop-name').text(shopData.shopName || 'Shop');
    
    // Clear existing items
    $('.items-container').empty();
    
    // Show/hide management tab
    if (isOwner) {
        $('#management-tab').show();
    } else {
        $('#management-tab').hide();
    }
    
    // Populate items
    if (shopData.length > 0) {
        shopData.forEach(item => {
            if (item.stock > 0) {
                addItemToShop(item);
            }
        });
    } else {
        $('.items-container').html('<p>No items available</p>');
    }
    
    // Clear cart
    cartItems = [];
    updateCart();
}

// Add item to shop display
function addItemToShop(item) {
    const itemElement = `
        <div class="item" data-name="${item.name}" data-price="${item.price}" data-stock="${item.stock}">
            <img src="nui://ox_inventory/web/images/${item.name}.png" onerror="this.src='img/default.png'" class="item-img">
            <div class="item-name">${item.label}</div>
            <div class="item-price">$${item.price.toLocaleString()}</div>
            <div class="item-stock">Stock: ${item.stock}</div>
            <div class="item-actions">
                <div class="quantity-control">
                    <button class="quantity-btn minus-btn"><i class="fas fa-minus"></i></button>
                    <input type="number" min="1" max="${item.stock}" value="1" class="quantity-input">
                    <button class="quantity-btn plus-btn"><i class="fas fa-plus"></i></button>
                </div>
                <button class="add-to-cart-btn"><i class="fas fa-cart-plus"></i></button>
            </div>
        </div>
    `;
    
    $('.items-container').append(itemElement);
    
    // Item quantity buttons
    const $item = $(`.item[data-name="${item.name}"]`);
    
    $item.find('.minus-btn').click(function() {
        const $input = $(this).siblings('.quantity-input');
        const value = parseInt($input.val());
        
        if (value > 1) {
            $input.val(value - 1);
        }
    });
    
    $item.find('.plus-btn').click(function() {
        const $input = $(this).siblings('.quantity-input');
        const value = parseInt($input.val());
        const max = parseInt($input.attr('max'));
        
        if (value < max) {
            $input.val(value + 1);
        }
    });
    
    // Add to cart button
    $item.find('.add-to-cart-btn').click(function() {
        const itemName = $item.data('name');
        const itemPrice = $item.data('price');
        const itemStock = $item.data('stock');
        const quantity = parseInt($item.find('.quantity-input').val());
        
        // Add to cart
        addToCart(itemName, item.label, itemPrice, quantity, itemStock);
        
        // Show notification
        showNotification(`Added ${item.label} x${quantity} to cart`);
    });
}

// Add item to cart
function addToCart(name, label, price, quantity, stock) {
    // Check if item already in cart
    const existingItem = cartItems.find(item => item.name === name);
    
    if (existingItem) {
        // Update quantity
        const newQuantity = existingItem.quantity + quantity;
        
        if (newQuantity > stock) {
            showNotification(`Cannot add more than ${stock} of this item`);
            return;
        }
        
        existingItem.quantity = newQuantity;
    } else {
        // Add new item
        cartItems.push({
            name: name,
            label: label,
            price: price,
            quantity: quantity
        });
    }
    
    // Update cart display
    updateCart();
}

// Update cart display
function updateCart() {
    // Update count
    $('#cart-count').text(cartItems.length);
    
    // Clear cart container
    $('.cart-container').empty();
    
    if (cartItems.length === 0) {
        $('.cart-container').html('<p>Your cart is empty</p>');
        $('#cart-total').text('0');
        return;
    }
    
    // Add items to cart
    cartItems.forEach((item, index) => {
        const cartItemElement = `
            <div class="cart-item" data-index="${index}">
                <div class="cart-item-info">
                    <img src="nui://ox_inventory/web/images/${item.name}.png" onerror="this.src='img/default.png'" class="cart-item-img">
                    <div>
                        <div class="cart-item-name">${item.label}</div>
                        <div class="cart-item-price">$${item.price.toLocaleString()} each</div>
                    </div>
                </div>
                <div class="cart-item-quantity">
                    <div>Quantity: ${item.quantity}</div>
                    <button class="remove-item-btn"><i class="fas fa-trash"></i></button>
                </div>
            </div>
        `;
        
        $('.cart-container').append(cartItemElement);
    });
    
    // Remove item buttons
    $('.remove-item-btn').click(function() {
        const index = $(this).closest('.cart-item').data('index');
        cartItems.splice(index, 1);
        updateCart();
    });
    
    // Update total
    $('#cart-total').text(calculateTotal().toLocaleString());
}

// Calculate cart total
function calculateTotal() {
    return cartItems.reduce((total, item) => total + (item.price * item.quantity), 0);
}

// Close shop
function closeShop() {
    $('#shop-ui').fadeOut(300);
    isShopOpen = false;
    
    // Reset
    shopData = null;
    cartItems = [];
    
    // Reset UI
    $('.tab-btn[data-tab="buy"]').click();
    
    // Post NUI message
    $.post('https://esx_advanced_shops/close');
}

// Show notification
function showNotification(message) {
    const notification = `
        <div class="notification">
            <div class="notification-content">${message}</div>
        </div>
    `;
    
    $('body').append(notification);
    
    $('.notification').animate({
        right: '20px',
        opacity: 1
    }, 300);
    
    setTimeout(() => {
        $('.notification').animate({
            right: '-400px',
            opacity: 0
        }, 300, function() {
            $(this).remove();
        });
    }, 3000);
}

// Show dialog
function showDialog(title, content, onConfirm, onCancel) {
    const dialog = `
        <div class="dialog-overlay">
            <div class="dialog">
                <div class="dialog-header">
                    <h2>${title}</h2>
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
    
    $('body').append(dialog);
    
    $('.dialog-btn.cancel').click(function() {
        if (onCancel) onCancel();
        $('.dialog-overlay').remove();
    });
    
    $('.dialog-btn.confirm').click(function() {
        if (onConfirm) onConfirm();
        $('.dialog-overlay').remove();
    });
}

// Show confirmation dialog
function confirmDialog(title, message, onConfirm) {
    showDialog(title, `<p>${message}</p>`, onConfirm);
}

// Show input dialog
function inputDialog(title, label, defaultValue, onConfirm) {
    const content = `
        <div class="form-group">
            <label>${label}</label>
            <input type="text" class="dialog-input" value="${defaultValue || ''}">
        </div>
    `;
    
    showDialog(title, content, function() {
        const value = $('.dialog-input').val();
        onConfirm(value);
    });
}

// Create context menu
function createContextMenu(items, x, y) {
    // Remove existing context menu
    $('.context-menu').remove();
    
    // Create menu
    const menu = $('<div class="context-menu"></div>');
    
    // Add items
    items.forEach(item => {
        const menuItem = $(`<div class="context-menu-item">${item.label}</div>`);
        
        menuItem.click(function() {
            item.action();
            menu.remove();
        });
        
        menu.append(menuItem);
    });
    
    // Position menu
    menu.css({
        top: y,
        left: x
    });
    
    // Add to body
    $('body').append(menu);
    
    // Close on click outside
    $(document).one('click', function() {
        menu.remove();
    });
}