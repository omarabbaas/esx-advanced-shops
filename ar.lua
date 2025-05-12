Locales = {}

Locales['ar'] = {
    -- General
    ['shop_blip'] = 'متجر',
    ['shop_center'] = 'مركز المتاجر',
    ['press_to_open'] = 'اضغط ~INPUT_CONTEXT~ لفتح المتجر',
    ['press_to_rob'] = 'اضغط ~INPUT_CONTEXT~ لسرقة المتجر',
    ['press_to_manage'] = 'اضغط ~INPUT_CONTEXT~ لإدارة متجرك',
    ['not_enough_money'] = 'ليس لديك ما يكفي من المال',
    ['not_enough_space'] = 'ليس لديك مساحة كافية في مخزونك',
    ['not_enough_stock'] = 'ليس لدى هذا المتجر مخزون كافٍ',
    ['inventory_full'] = 'مخزونك ممتلئ',
    ['purchase_success'] = 'لقد اشتريت %s ×%d مقابل $%s',
    ['cannot_carry'] = 'لا يمكنك حمل المزيد من %s',
    
    -- Shop Center
    ['shop_center_title'] = 'مركز المتاجر',
    ['buy_shop'] = 'شراء متجر',
    ['shop_name'] = 'اسم المتجر: %s',
    ['shop_price'] = 'السعر: $%s',
    ['shop_category'] = 'الفئة: %s',
    ['shop_location'] = 'الموقع: %s',
    ['shop_size'] = 'الحجم: %s',
    ['shop_bought'] = 'لقد اشتريت المتجر %s مقابل $%s',
    ['not_enough_money_shop'] = 'ليس لديك ما يكفي من المال لشراء هذا المتجر',
    ['already_owned'] = 'هذا المتجر مملوك بالفعل',
    ['enter_shop_name'] = 'أدخل اسم المتجر',
    ['invalid_name'] = 'اسم متجر غير صالح',
    
    -- Shop Management
    ['management_title'] = 'إدارة المتجر',
    ['stock_management'] = 'إدارة المخزون',
    ['employee_management'] = 'إدارة الموظفين',
    ['finances'] = 'الشؤون المالية',
    ['shop_settings'] = 'إعدادات المتجر',
    ['order_stock'] = 'طلب مخزون',
    ['current_stock'] = 'المخزون الحالي',
    ['sell_shop'] = 'بيع المتجر',
    ['close_shop'] = 'إغلاق المتجر',
    ['open_shop'] = 'فتح المتجر',
    ['shop_sold'] = 'لقد بعت المتجر مقابل $%s',
    ['shop_closed'] = 'المتجر مغلق الآن',
    ['shop_opened'] = 'المتجر مفتوح الآن',
    
    -- Stock Management
    ['stock_title'] = 'إدارة المخزون',
    ['add_item'] = 'إضافة عنصر',
    ['remove_item'] = 'إزالة عنصر',
    ['adjust_price'] = 'تعديل السعر',
    ['current_items'] = 'العناصر الحالية',
    ['item_name'] = 'العنصر: %s',
    ['item_stock'] = 'المخزون: %d/%d',
    ['item_price'] = 'السعر: $%s',
    ['adjust_price_prompt'] = 'أدخل سعرًا جديدًا لـ %s (الحد الأدنى: $%s، الحد الأقصى: $%s):',
    ['invalid_price'] = 'سعر غير صالح',
    ['price_updated'] = 'تم تحديث السعر إلى $%s',
    ['add_stock_prompt'] = 'كم عدد %s الذي ترغب في إضافته؟ (الحد الأقصى: %d)',
    ['remove_stock_prompt'] = 'كم عدد %s الذي ترغب في إزالته؟ (الحد الأقصى: %d)',
    ['stock_added'] = 'تمت إضافة %d %s إلى المخزون',
    ['stock_removed'] = 'تمت إزالة %d %s من المخزون',
    
    -- Employee Management
    ['employee_title'] = 'إدارة الموظفين',
    ['add_employee'] = 'إضافة موظف',
    ['remove_employee'] = 'إزالة موظف',
    ['current_employees'] = 'الموظفين الحاليين',
    ['employee_name'] = 'الاسم: %s',
    ['employee_permission'] = 'الإذن: %s',
    ['enter_employee_id'] = 'أدخل معرّف الموظف',
    ['invalid_id'] = 'معرّف غير صالح',
    ['employee_added'] = 'تمت إضافة الموظف',
    ['employee_removed'] = 'تمت إزالة الموظف',
    ['already_employee'] = 'هذا الشخص موظف بالفعل',
    ['not_employee'] = 'هذا الشخص ليس موظفاً',
    
    -- Finances
    ['finances_title'] = 'الشؤون المالية',
    ['total_sales'] = 'إجمالي المبيعات: $%s',
    ['total_profit'] = 'إجمالي الربح: $%s',
    ['sales_today'] = 'مبيعات اليوم: $%s',
    ['profit_today'] = 'أرباح اليوم: $%s',
    ['withdraw_money'] = 'سحب المال',
    ['deposit_money'] = 'إيداع المال',
    ['withdraw_prompt'] = 'كم ترغب في سحب؟ (المتاح: $%s)',
    ['deposit_prompt'] = 'كم ترغب في إيداع؟',
    ['invalid_amount'] = 'مبلغ غير صالح',
    ['money_withdrawn'] = 'لقد سحبت $%s',
    ['money_deposited'] = 'لقد أودعت $%s',
    
    -- Ordering
    ['order_title'] = 'طلب مخزون',
    ['supplier'] = 'المورد: %s',
    ['discount'] = 'خصم بالجملة: %s%%',
    ['min_order'] = 'الحد الأدنى للطلب: %d',
    ['order_prompt'] = 'كم عدد %s الذي ترغب في طلبه؟ (الحد الأدنى: %d)',
    ['order_cost'] = 'تكلفة الطلب: $%s',
    ['order_confirm'] = 'تأكيد الطلب: %d × %s مقابل $%s؟',
    ['order_placed'] = 'تم تقديم الطلب. التسليم المتوقع خلال %d دقائق',
    ['not_enough_shop_money'] = 'لا يوجد ما يكفي من المال في حساب المتجر',
    ['order_cancelled'] = 'تم إلغاء الطلب',
    
    -- Robbery
    ['robbery_started'] = 'بدأت سرقة المتجر. تم إخطار الشرطة!',
    ['robbery_cancelled'] = 'تم إلغاء السرقة',
    ['robbery_complete'] = 'اكتملت السرقة! لقد سرقت $%s',
    ['police_notify'] = 'سرقة متجر قيد التنفيذ في %s',
    ['min_police'] = 'لا يوجد ما يكفي من الشرطة في المدينة',
    ['cooldown_active'] = 'تمت سرقة هذا المتجر مؤخرًا. حاول مرة أخرى لاحقًا',
    ['shop_empty'] = 'ليس لدى هذا المتجر أموال للسرقة',
    ['stay_close'] = 'ابق قريبًا من الصندوق!',
    
    -- Permissions
    ['no_permission'] = 'ليس لديك إذن للقيام بذلك',
    ['must_be_owner'] = 'يجب أن تكون المالك للقيام بذلك',
    ['weapon_license_required'] = 'تحتاج إلى رخصة سلاح لشراء هذا',
    
    -- Jobs
    ['job_restriction'] = 'هذا الإجراء مقيد بوظائف معينة',
    
    -- Custom items
    ['customize_item'] = 'تخصيص العنصر',
    ['base_price'] = 'السعر الأساسي: $%s',
    ['customization_options'] = 'خيارات التخصيص',
    ['add_ingredient'] = 'إضافة %s (+$%s)',
    ['total_price'] = 'السعر الإجمالي: $%s',
    
    -- Misc
    ['yes'] = 'نعم',
    ['no'] = 'لا',
    ['confirm'] = 'تأكيد',
    ['cancel'] = 'إلغاء',
    ['back'] = 'رجوع',
    ['small'] = 'صغير',
    ['medium'] = 'متوسط',
    ['large'] = 'كبير',
}