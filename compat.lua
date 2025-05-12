Locales = Locales or {}

-- Compatibility layer for TranslateCap
if not TranslateCap then
    TranslateCap = function(str, ...)
        if _U then
            return _U(str, ...)
        else
            -- Fallback if _U is also not defined
            local text = Locales[GetResourceState('es_extended') == 'started' and ESX.GetConfig().Locale or 'en'][str]
            if text then
                return string.format(text, ...)
            else
                return 'Translation not found: ' .. str
            end
        end
    end
end