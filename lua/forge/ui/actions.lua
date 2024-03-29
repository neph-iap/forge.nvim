local ui = require("forge.ui")
local registry = require("forge.registry")
local treesitter_parsers = require("nvim-treesitter.parsers")
local lock = require("forge.lock")
local mason_utils = require("forge.util.mason_utils")
local os_utils = require("forge.util.os")

local public = Table({})

function public.do_nothing() end

-- Closes the forge buffer
function public.close_window()
	ui.expanded_languages = Table({})
	ui.expanded_compilers = Table({})
	ui.expanded_highlighters = Table({})
	ui.expanded_linters = Table({})
	ui.expanded_formatters = Table({})
	ui.expanded_debuggers = Table({})
	ui.expanded_additional_tools = Table({})
	vim.api.nvim_win_close(ui.window, true)
end

function public.toggle_install() -- TODO: this causes the physical cursor to be misaligned with the visual cursor
	local line = ui.lines[ui.cursor_row]

	---@type Language
	local language = nil
	for _, registered_language in pairs(registry.languages) do
		if registered_language.name == line.language then
			language = registered_language
			break
		end
	end

	-- Compiler
	if line.type == "compiler_listing" then
		-- Uninstall compiler
		if os_utils.command_exists(line.internal_name) then

		-- Install compiler
		else
			os_utils.install_package(line.name, line.internal_name)
			table.insert(language.installed_compilers, { name = line.name, internal_name = line.internal_name })
			registry.refresh_installed_totals(language)
			registry.sort_languages()
		end

	-- Highlighter
	elseif line.type == "highlighter_listing" then -- TODO: refactor this mess
		if treesitter_parsers.has_parser(line.internal_name) then
			vim.cmd(("TSUninstall %s"):format(line.internal_name))

			local index = nil
			for linter_index, linter in ipairs(language.installed_linters) do
				if linter.internal_name == line.internal_name then
					index = linter_index
					break
				end
			end

			table.remove(language.installed_highlighters, index)
			registry.refresh_installed_totals(language)
			registry.sort_languages()
			ui.update_view()
		else
			vim.cmd(("TSInstall %s"):format(line.internal_name))
			table.insert(language.installed_highlighters, { name = line.name, internal_name = line.internal_name })
			registry.refresh_installed_totals(language)
			registry.sort_languages()
			ui.update_view()
		end

	-- Linter
	elseif line.type == "linter_listing" then
		if mason_utils.package_is_installed(line.internal_name) then
			print("Uninstalling " .. line.internal_name .. "...")
			vim.cmd(("MasonUninstall %s"):format(line.internal_name))
			vim.schedule(function()
				vim.cmd("bdelete")
			end)
			print(("%s was successfully uninstalled"):format(line.internal_name))

			local index = nil
			for linter_index, linter in ipairs(language.installed_linters) do
				if linter.internal_name == line.internal_name then
					index = linter_index
					break
				end
			end

			table.remove(language.installed_linters, index)
			for _, language_key in ipairs(registry.language_keys) do
				local other_language = registry.languages[language_key]
				for linter_index, linter in ipairs(other_language.installed_linters) do
					if linter.internal_name == line.internal_name then
						table.remove(other_language.installed_linters, linter_index)
						break
					end
				end
			end

			registry.refresh_installed_totals(language)
			registry.sort_languages()

			---@type integer
			index = nil
			for line_index, ui_line in ipairs(ui.lines) do
				if ui_line.internal_name == line.internal_name then
					index = line_index
					break
				end
			end

			ui.cursor_row = index
			ui.update_view()
		else
			print("Installing " .. line.internal_name .. "...")
			vim.cmd(("MasonInstall %s"):format(line.internal_name))
			vim.schedule(function()
				vim.cmd("bdelete")
			end)
			table.insert(language.installed_linters, { name = line.name, internal_name = line.internal_name })

			for _, language_key in ipairs(registry.language_keys) do
				local other_language = registry.languages[language_key]
				for _, linter in ipairs(other_language.installed_linters) do
					if linter.internal_name == line.internal_name then
						table.insert(
							other_language.installed_linters,
							{ name = line.name, internal_name = line.internal_name }
						)
						break
					end
				end
			end

			registry.refresh_installed_totals(language)
			registry.sort_languages()

			---@type integer
			local index = nil
			for line_index, ui_line in ipairs(ui.lines) do
				if ui_line.internal_name == line.internal_name then
					index = line_index
					break
				end
			end

			ui.cursor_row = index
			ui.update_view()
		end

	-- Formatter
	elseif line.type == "formatter_listing" then
		if mason_utils.package_is_installed(line.internal_name) then
			print("Installing " .. line.internal_name .. "...")
			vim.cmd(("MasonUninstall %s"):format(line.internal_name))
			vim.schedule(function()
				vim.cmd("bdelete")
			end)
			print(("%s was successfully uninstalled"):format(line.internal_name))

			local index = nil
			for formatter_index, formatter in ipairs(language.installed_formatters) do
				if formatter.internal_name == line.internal_name then
					index = formatter_index
					break
				end
			end

			-- Remove the formatter from the list of installed formatters
			table.remove(language.installed_formatters, index)
			for _, language_key in ipairs(registry.language_keys) do
				local other_language = registry.languages[language_key]
				for formatter_index, formatter in ipairs(other_language.installed_formatters) do
					if formatter.internal_name == line.internal_name then
						table.remove(other_language.installed_formatters, formatter_index)
						break
					end
				end
			end

			registry.refresh_installed_totals(language)
			registry.sort_languages()

			---@type integer
			index = nil
			for line_index, ui_line in ipairs(ui.lines) do
				if ui_line.internal_name == line.internal_name then
					index = line_index
					break
				end
			end

			ui.cursor_row = index
			ui.update_view()
		else
			print("Installing " .. line.internal_name .. "...")
			vim.cmd(("MasonInstall %s"):format(line.internal_name))
			vim.schedule(function()
				vim.cmd("bdelete")
			end)

			-- Add the formatter to the list of installed formatters
			table.insert(language.installed_formatters, { name = line.name, internal_name = line.internal_name })
			for _, language_key in ipairs(registry.language_keys) do
				local other_language = registry.languages[language_key]
				for _, formatter in ipairs(other_language.installed_formatters) do
					if formatter.internal_name == line.internal_name then
						table.insert(
							other_language.installed_formatters,
							{ name = line.name, internal_name = line.internal_name }
						)
						break
					end
				end
			end

			registry.refresh_installed_totals(language)
			registry.sort_languages()

			---@type integer
			local index = nil
			for line_index, ui_line in ipairs(ui.lines) do
				if ui_line.internal_name == line.internal_name then
					index = line_index
					break
				end
			end

			ui.cursor_row = index
			ui.update_view()
		end

	-- Debugger
	elseif line.type == "debugger_listing" then
		-- Uninstall debugger
		if mason_utils.package_is_installed(line.internal_name) then
			print("Uninstalling " .. line.internal_name .. "...")
			vim.cmd(("MasonUninstall %s"):format(line.internal_name))
			vim.schedule(function()
				vim.cmd("bdelete")
			end)
			print(("%s was successfully uninstalled"):format(line.internal_name))

			local index = nil
			for debugger_index, debugger in ipairs(language.installed_debuggers) do
				if debugger.internal_name == line.internal_name then
					index = debugger_index
					break
				end
			end

			-- Remove the debugger from the list of installed debuggers
			table.remove(language.installed_debuggers, index)
			for _, language_key in ipairs(registry.language_keys) do
				local other_language = registry.languages[language_key]
				for debugger_index, debugger in ipairs(other_language.installed_debuggers) do
					if debugger.internal_name == line.internal_name then
						table.remove(other_language.installed_debuggers, debugger_index)
						break
					end
				end
			end

			registry.refresh_installed_totals(language)
			registry.sort_languages()

			---@type integer
			index = nil
			for line_index, ui_line in ipairs(ui.lines) do
				if ui_line.internal_name == line.internal_name then
					index = line_index
					break
				end
			end

			ui.cursor_row = index
			ui.update_view()

		-- Install debugger
		else
			print("Installing " .. line.internal_name .. "...")
			vim.cmd(("MasonInstall %s"):format(line.internal_name))
			vim.schedule(function()
				vim.cmd("bdelete")
			end)

			-- Add the debugger to the list of installed debuggers
			table.insert(language.installed_debuggers, { name = line.name, internal_name = line.internal_name })
			for _, language_key in ipairs(registry.language_keys) do
				local other_language = registry.languages[language_key]
				for _, debugger in ipairs(other_language.installed_debuggers) do
					if debugger.internal_name == line.internal_name then
						table.insert(
							other_language.installed_debuggers,
							{ name = line.name, internal_name = line.internal_name }
						)
						break
					end
				end
			end

			registry.refresh_installed_totals(language)
			registry.sort_languages()

			---@type integer
			local index = nil
			for line_index, ui_line in ipairs(ui.lines) do
				if ui_line.internal_name == line.internal_name then
					index = line_index
					break
				end
			end

			ui.cursor_row = index
			ui.update_view()
		end

	-- Additional Tools
	elseif line.type == "additional_tools_listing" then
		print("Installing " .. line.internal_name .. "...")

		local plugin_name = line.internal_name:match("([^/]+)$")
		local local_repo_path = vim.fn.stdpath("data") .. "/lazy/" .. plugin_name

		vim.fn.system(("git clone 'https://github.com/%s.git' '%s'"):format(line.internal_name, local_repo_path))
		local branch = vim.fn.system(("git -C '%s' branch --show-current"):format(local_repo_path)):gsub("\n$", "")
		local commit = vim.fn.system(("git -C '%s' rev-parse HEAD"):format(local_repo_path)):gsub("\n$", "")

		-- TODO: allow configuring lazy lockfile, because lazy allows configuring it
		-- ideally I would actually just like to do this through lazy, and then lazy
		-- could handle the cloning, lockfile, etc. It also would prevent the plugin
		-- from being marked as needing to be cleaned.

		-- Write to lockfile
		local lazy_lock = vim.fn.stdpath("config") .. "/lazy-lock.json"
		local plugins = assert(vim.fn.json_decode(vim.fn.readfile(lazy_lock)))
		plugins[plugin_name] = { branch = branch, commit = commit }
		local lazy_lock_file = assert(io.open(lazy_lock, "w"))

		-- Pretty print the lockfile
		local has_plugins = false
		local json = "{"
		for json_plugin_name, plugin_data in pairs(plugins) do
			has_plugins = true
			json = json .. ('\n\t"%s": %s,'):format(json_plugin_name, vim.fn.json_encode(plugin_data))
		end
		if has_plugins then
			json = json:sub(1, #json - 1)
		end
		json = json .. "\n}"
		lazy_lock_file:write(json)
		lazy_lock_file:close()

		-- Add the additional tool to the list of installed additional tools
		table.insert(language.installed_additional_tools, { name = line.name, internal_name = line.internal_name })
		for _, language_key in ipairs(registry.language_keys) do
			local other_language = registry.languages[language_key]
			for _, additional_tool in ipairs(other_language.installed_additional_tools) do
				if additional_tool.internal_name == line.internal_name then
					table.insert(
						other_language.installed_additional_tools,
						{ name = line.name, internal_name = line.internal_name }
					)
					break
				end
			end
		end

		registry.sort_languages()

		---@type integer
		local index = nil
		for line_index, ui_line in ipairs(ui.lines) do
			if ui_line.internal_name == line.internal_name then
				index = line_index
				break
			end
		end

		ui.cursor_row = index
		ui.update_view()
	end

	lock.save()
end

-- Expands a folder under the cursor.
--
---@return nil
function public.expand()
	if ui.lines[ui.cursor_row].type == "language" then
		local index_of_language = ui.cursor_row
		local language_name = ui.lines[ui.cursor_row].language

		if ui.expanded_languages:contains(language_name) then
			ui.expanded_languages:remove_value(language_name)
			ui.lines:remove(index_of_language + 1)
			ui.lines:remove(index_of_language + 1)
			ui.lines:remove(index_of_language + 1)
			ui.lines:remove(index_of_language + 1)
			ui.lines:remove(index_of_language + 1)
			ui.lines:remove(index_of_language + 1)
		else
			ui.expanded_languages:insert(language_name)
			ui.lines:insert(index_of_language + 1, { type = "compiler", language = language_name })
			ui.lines:insert(index_of_language + 2, { type = "highlighter", language = language_name })
			ui.lines:insert(index_of_language + 3, { type = "linter", language = language_name })
			ui.lines:insert(index_of_language + 4, { type = "formatter", language = language_name })
			ui.lines:insert(index_of_language + 5, { type = "debugger", language = language_name })
			ui.lines:insert(index_of_language + 6, { type = "additional_tools", language = language_name })
		end
	else
		for _, tool in ipairs({ "compiler", "highlighter", "linter", "formatter", "debugger", "additional_tools" }) do
			if ui.lines[ui.cursor_row].type == tool then
				local plural_tool = tool .. "s"
				if tool == "additional_tools" then
					plural_tool = tool
				end

				local index_of_tool = ui.cursor_row
				local language_name = ui.lines[ui.cursor_row].language

				---@type Language
				local language = nil
				for _, registry_language in pairs(registry.languages) do
					if registry_language.name == language_name then
						language = registry_language
						break
					end
				end

				if ui["expanded_" .. plural_tool]:contains(language_name) then
					for _, _ in ipairs(language[plural_tool]) do
						ui.lines:remove(index_of_tool + 1)
					end
					ui["expanded_" .. plural_tool]:remove_value(language_name)
				else
					for index, language_tool in ipairs(language[plural_tool]) do
						ui.lines:insert(index_of_tool + index, {
							type = tool .. "_listing",
							language = language_name,
							name = language_tool.name,
							internal_name = language_tool.internal_name,
							tool = language_tool,
						})
					end
					ui["expanded_" .. plural_tool]:insert(language_name)
				end
			end
		end
	end

	ui.update_view()
end

-- PERF: these move cursor functions lag a lot when holding the button down

-- Moves the cursor down one row in the buffer.
--
---@return nil
function public.move_cursor_down()
	ui.cursor_row = math.min(ui.cursor_row + 1, vim.api.nvim_buf_line_count(ui.buffer))
	ui.update_view()
end

-- Moves the cursor up one row in the buffer.
--
---@return nil
function public.move_cursor_up()
	ui.cursor_row = math.max(ui.cursor_row - 1, 1)
	ui.update_view()
end

-- Moves the cursor to the top of the buffer.
--
---@return nil
function public.set_cursor_to_top()
	ui.cursor_row = 1
	ui.update_view()
end

-- Moves the cursor to the bottom of the buffer.
--
---@return nil
function public.set_cursor_to_bottom()
	ui.cursor_row = vim.api.nvim_buf_line_count(ui.buffer)
	ui.update_view()
end

-- Refreshes installations
--
---@return nil
function public.refresh()
	ui.is_refreshing = true -- TODO: this doesn't show
	ui.update_view()
	vim.schedule(function()
		registry.refresh_installations()
		lock.save()
		ui.is_refreshing = false
		ui.update_view()
		print("[forge.nvim] Refresh complete")
	end)
end

return public
