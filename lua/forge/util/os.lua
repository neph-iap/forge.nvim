local public = {}

-- Gets the current operating system.
--
---@return string os the operating system
function public.get_os()
	if package.config:sub(1, 1) == '\\' then return "windows" else return "unix" end
end

-- Checks whether a shell command can be found
--
---@param command_name string
--
---@return boolean exists whether the command can be found
function public.command_exists(command_name)
	if public.get_os() == "windows" then
		local exit_code = os.execute(("where %s > nul 2>&1"):format(command_name))
		return exit_code == 0
	end

	local exit_code = os.execute(("command -v %s"):format(command_name))
	return exit_code == 0
end

-- Checks if a compiler/interpreter is installed.
--
---@return boolean is_installed whether the compiler is installed
function public.language_is_installed(language)
	for _, command in ipairs(language.compilers) do
		if public.command_exists(command) then return true end
	end
	return false
end

-- Checks if the current user is an admin.
--
---@return boolean is_admin whether the current user is an admin
function public.is_admin()
	if public.get_os() == "windows" and vim.fn.getenv("ADMIN") then
		return true
	elseif public.get_os() == "unix" and vim.fn.getenv("SUDO_USER") then
		return true
	else
		return false
	end
end

return public
