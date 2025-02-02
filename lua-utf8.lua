local module = {}
module.utf8_invalid = function(code)
    -- Implement your UTF-8 validation logic here
    return code < 0 or code > 0x10FFFF
end
    
-- Function to decode a UTF-8 codepoint
module.utf8_safe_decode = function(str, pos)
    local code = str:byte(pos)
    if code then
        return code, pos + 1
    else
        return nil, pos
    end
end
    
-- Function to get the next UTF-8 character
module.utf8_next = function(str, pos, len)
    pos = pos or 1
    len = len or #str
    if pos <= len then
        return pos + 1
    else
        return len + 1
    end
end
    
-- iter_aux function
module.iter_aux = function(s, n, strict)
    local e = #s
    local p = n <= 0 and 1 or module.utf8_next(s, n, e)
    if p <= e then
        local code, next_pos = module.utf8_safe_decode(s, p)
        if strict and module.utf8_invalid(code) then
            error("invalid UTF-8 code")
        end
        return p, code
    end
end
    
-- iter_auxstrict function
module.iter_auxstrict = function(s, n)
    return module.iter_aux(s, n, true)
end
    
-- iter_auxlax function
module.iter_auxlax = function(s, n)
    return module.iter_aux(s, n, false)
end
    
-- utf8_codes function
module.codes = function(s, lax)
    local lax = lax or false
    if not s then
        error("bad argument #1 to 'utf8_codes' (string expected, got nil)")
    end
    
    local iter_function = lax and module.iter_auxlax or module.iter_auxstrict
    return iter_function, s, 0
end
return module