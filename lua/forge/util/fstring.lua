-- http://lua-users.org/wiki/VarExpand
return function(s, ...)
	local args = {...};
	args = #args == 1 and type(args[1]) == "table" and args[1] or args;
	local function DoExpand (iscode)
		local was = false;
		local mask = iscode and "()%$(%b{})" or "()%$([%a%d_]*)";
		local drepl = iscode and "\\$" or "\\\\$";
		s = s:gsub(mask, function (pos, code)
			if s:sub(pos-1, pos-1) == "\\" then return "$"..code;
			else was = true; local v, err;
				if iscode then code = code:sub(2, -2);
				else local n = tonumber(code);
					if n then v = args[n]; end;
				end;
				if not v then
					v, err = loadstring("return "..code); if not v then error(err); end;
					v = v();
				end;
				if v == nil then v = ""; end;
				v = tostring(v):gsub("%$", drepl);
				return v;
			end;
		end);
		if not (iscode or was) then s = s:gsub("\\%$", "$"); end;
		return was;
	end;

	repeat DoExpand(true); until not DoExpand(false);
	return s;
end
