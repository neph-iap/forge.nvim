local public = {}

function public.contains(tab, val)
    for _, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

-- Removes the given value from the given array
--
---@param tab any[] The array of values to remove from
---@param to_remove any The element to remove
function public.remove(tab, to_remove)
	local index_to_remove = nil
	for index, value in ipairs(tab) do
		if value == to_remove then
			index_to_remove = index
			break
		end
	end

	if index_to_remove ~= nil then
		table.remove(tab, index_to_remove)
	end
end

-- Checks whether the given string is a hex color.
--
---@param color string The string to check
--
---@return boolean is_hex_color Whether the given string is a hex color
function public.is_hex_color(color)
	if not color then return false end
	return color:match("^#%x%x%x%x%x%x$")
end

---@param str string
function public.snake_case_to_title_case(str)
    local words = {}
    for word in str:gmatch("([^_]+)") do
        word = word:gsub("^%l", string.upper)
        table.insert(words, word)
    end
    return table.concat(words, " ")
end

return public