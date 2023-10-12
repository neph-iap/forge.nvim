local util = require("forge.util")
local registry = require("forge.registry")
local symbols = require("forge.ui.symbols")

-- The public exports of forge-ui
local public = {}

---@alias line_type "language" | "compiler"

---@type { type: line_type, language: string }[]
public.lines = { {}, {}, {}, {}, }
local function reset_lines()
	public.lines = { {}, {}, {}, {}, }
	for _, language_key in ipairs(registry.language_keys) do
		table.insert(public.lines, { language = registry.languages[language_key].name, type = "language" })
	end
	table.insert(public.lines, {})
end

---@type string[]
public.expanded_languages = {}

---@type string[]
public.expanded_compilers = {}

local highlight_groups = {}

-- Returns the associated highlight group for a given hex color, or creates and returns a new one if none
-- currently exists.
--
---@param options { foreground?: string, background?: string, italicize?: boolean, bold?: boolean }?
--
---@return string highlight_group The name of the highlight group corresponding to the given color.
local function get_highlight_group_for_color(options)
	if not options then options = {} end

	local name = "ForgeColor"
	if options.foreground then name = name .. "Fg" .. options.foreground:sub(2) end
	if options.background then name = name .. "Bg" .. options.background:sub(2) end

	if options.italicize then name = name .. "Italics" end
	if options.bold then name = name .. "Bold" end

	if highlight_groups[name] then return highlight_groups[name] end
	highlight_groups[name] = name

	local guifg = nil
	if options.foreground then guifg = "guifg=" .. options.foreground end

	local guibg = nil
	if options.background then guibg = "guibg=" .. options.background end

	local gui = "gui="
	if options.italicize then
		gui = gui .. "italic"
		if options.bold then gui = gui .. ",bold" end
	elseif options.bold then
		gui = gui .. "bold"
	end

	local highlight_command = ("highlight %s"):format(name)
	if guifg then highlight_command = highlight_command .. " " .. guifg end
	if guibg then highlight_command = highlight_command .. " " .. guibg end
	if gui ~= "gui=" then highlight_command = highlight_command .. " " .. gui end
	vim.cmd(highlight_command)

	return name
end

---@param option_list { text: string, foreground?: string, background?: string, italicize?: boolean, bold?: boolean }[]
---@param is_centered? boolean
local function write_table(option_list, is_centered)
	local text = ""
	for _, options in ipairs(option_list) do
		text = text .. options.text
	end

	local shift = 0
	if is_centered then
		shift = math.floor(public.width / 2) - math.floor(text:len() / 2)
		text = (' '):rep(shift) .. text
	end

	local line = vim.api.nvim_buf_line_count(public.buffer)
	if is_first_draw_call then line = 0 end

	local start = -1
	if is_first_draw_call then start = 0 end
	is_first_draw_call = false
	vim.api.nvim_buf_set_lines(public.buffer, start, -1, false, { text })

	text = ""
	for _, options in ipairs(option_list) do
		text = text .. options.text
		if options.foreground or options.background then
			local highlight_group
			if util.is_hex_color(options.foreground) or util.is_hex_color(options.background) then highlight_group = get_highlight_group_for_color(options)
			else highlight_group = options.foreground or options.background end
			---@cast highlight_group string
			vim.api.nvim_buf_add_highlight(public.buffer, -1, highlight_group, line, #text - #options.text + shift, #text + shift)
		end
	end
end

-- Draws the compiler info to the screen
--
---@param language language the language to draw the compiler of 
---@param tool_name "compilers" | "highlighters" | "linters" | "formatters" | "debuggers" | "additional_tools"
--
---@return nil
local function draw_tool(language, tool_name)
	local strings = { { text = "      " } }

	local proper_tool_name = util.snake_case_to_title_case(tool_name)
	if tool_name ~= "additional_tools" then proper_tool_name = proper_tool_name:sub(1, -2) end

	-- Icon, compiler name, compiler command
	if language["installed_" .. tool_name][1] then
		table.insert(strings, { text = "", foreground = "#00FF00" })
		table.insert(strings, { text = " " .. proper_tool_name .. ": "})
		table.insert(strings, { text = language["installed_" .. tool_name][1].name, foreground = "#00FF00" })
		table.insert(strings, { text = " (" .. language["installed_" .. tool_name][1].internal_name .. ")", foreground = "Comment" })
	elseif #language[tool_name] > 0 then
		table.insert(strings, { text = "", foreground = "#FF0000" })
		table.insert(strings, { text = " " .. proper_tool_name .. ": "})
		table.insert(strings, { text = "None Installed", foreground = "#FF0000" })
		table.insert(strings, { text = " (" .. #language[tool_name] .. " available)", foreground = "Comment" })
	else
		table.insert(strings, { text = "", foreground = "#FFFF00" })
		table.insert(strings, { text = " " .. proper_tool_name .. ": "})
		table.insert(strings, { text = "Not Supported", foreground = "#FFFF00" })
	end

	table.insert(strings, { text = " ▸" })

	-- Prompt
	-- if public.lines[public.cursor_row].type == "compiler" and public.lines[public.cursor_row].language == language.name then
		-- table.insert(strings, { text = "   (Press e to expand, i to install recommended, or u to uninstall)", foreground = "Comment" })
	-- end

	write_table(strings)
end

---@param language language
local function draw_expanded_language(language)
	if language.name == public.get_language_under_cursor() then
		write_table({
			{ text = "    " .. symbols.progress_icons[language.total][language.installed_total], foreground = symbols.progress_colors[language.total][language.installed_total] },
			{ text = " " .. language.name },
			{ text = " ▾", foreground = "Comment" },
			{ text = "   (Press ", foreground = "Comment" },
			{ text = "e", foreground = "#AAAA77"},
			{ text = " to ", foreground = "Comment" },
			{ text = "collapse", foreground = "#AAAA77" },
			{ text = ", ", foreground = "Comment" },
			{ text = "i", foreground = "#77AAAA" },
			{ text = " to ", foreground = "Comment" },
			{ text = "install all", foreground = "#77AAAA" },
			{ text = ", or ", foreground = "Comment"},
			{ text = "u", foreground = "#AA77AA" },
			{ text = " to ", foreground = "Comment" },
			{ text = "uninstall all", foreground = "#AA77AA" },
			{ text = ")", foreground = "Comment" }
		})
	else
		write_table({
			{ text = "    " },
			{ text = symbols.progress_icons[language.total][language.installed_total], foreground = symbols.progress_colors[language.total][language.installed_total] },
			{ text = " " },
			{ text = language.name },
			{ text = " ▾", foreground = "Comment" }
		})
	end
end

-- Draws the languages onto the forge buffer.
--
---@return nil
local function draw_languages()
	write_table({ { text = "  Languages"} })

	for _, key in ipairs(registry.language_keys) do
		local language = registry.languages[key]

		if util.contains(public.expanded_languages, language.name) then
			draw_expanded_language(language)
			draw_tool(language, "compilers")
			draw_tool(language, "highlighters")
			draw_tool(language, "linters")
			draw_tool(language, "formatters")
			draw_tool(language, "debuggers")
			draw_tool(language, "additional_tools")
		else
			if language.name == public.get_language_under_cursor() then
				write_table({
					{ text = "    " .. symbols.progress_icons[language.total][language.installed_total], foreground = symbols.progress_colors[language.total][language.installed_total] },
					{ text = " " .. language.name },
					{ text = " ▸", foreground = "Comment" },
					{ text = "   (Press ", foreground = "Comment" },
					{ text = "e", foreground = "#AAAA77"},
					{ text = " to ", foreground = "Comment" },
					{ text = "expand", foreground = "#AAAA77" },
					{ text = ", ", foreground = "Comment" },
					{ text = "i", foreground = "#77AAAA" },
					{ text = " to ", foreground = "Comment" },
					{ text = "install all", foreground = "#77AAAA" },
					{ text = ", or ", foreground = "Comment"},
					{ text = "u", foreground = "#AA77AA" },
					{ text = " to ", foreground = "Comment" },
					{ text = "uninstall all", foreground = "#AA77AA" },
					{ text = ")", foreground = "Comment" }
				})
			else
				write_table({
					{ text = "    " },
					{ text = symbols.progress_icons[language.total][language.installed_total], foreground = symbols.progress_colors[language.total][language.installed_total] },
					{ text = " " },
					{ text = language.name },
					{ text = " ▸", foreground = "Comment" }
				})
			end
		end
	end
end

-- The row that the cursor is on, used to keep the cursor in the same spot when reloading the window.
---@type integer
public.cursor_row = 1

is_first_draw_call = true

-- Updates the forge buffer.
--
---@return nil
function public.update_view()
	is_first_draw_call = true
	vim.api.nvim_buf_set_option(public.buffer, 'modifiable', true)
	write_table({ { text = " Forge ", background = "#CC99FF", foreground = "#000000" } }, true)
	write_table({ { text = "" } })
	write_table({
		{ text = " Expand (e) ", background = "#99FFFF", foreground = "#000000" },
		{ text = "   " },
		{ text = " Install (i) ", background = "#99FFFF", foreground = "#000000" },
		{ text = "   " },
		{ text = " Uninstall (u) ", background = "#99FFFF", foreground = "#000000" },
		{ text = "   " },
		{ text = " Refresh (r) ", background = "#99FFFF", foreground = "#000000"},
		{ text = "   " },
		{ text = " Quit (q) ", background = "#99FFFF", foreground = "#000000" }
	}, true)
	draw_languages()
	write_table({ { text = "" } })
	vim.fn.cursor({ public.cursor_row, 0 })
	vim.api.nvim_buf_set_option(public.buffer, 'modifiable', false)
end

-- Returns the langauge at the given line number, or `nil` if there is no language at the line
--
---@param line_number integer The line number in the forge buffer to get the language at
--
---@return string? language_name The name of the language found
local function get_language_at_line(line_number)
	if public.lines[line_number].type == "language" then return public.lines[line_number].language else return nil end
end

-- Returns the language that the cursor is under, or `nil` if the cursor is not under a language
--
---@return string? language_name The name of the language found
function public.get_language_under_cursor()
	return get_language_at_line(public.cursor_row)
end

-- Opens the forge buffer.
--
---@return nil
function public.open_window()
	reset_lines()
	public.buffer = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(public.buffer, 'bufhidden', 'wipe')

	local vim_width = vim.api.nvim_get_option("columns")
	local vim_height = vim.api.nvim_get_option("lines")

	public.height = math.ceil(vim_height * 0.8 - 4)
	public.width = math.ceil(vim_width * 0.8)

	local window_options = {
		style = "minimal",
		relative = "editor",
		width = public.width,
		height = public.height,
		row = math.ceil((vim_height - public.height) / 2 - 1),
		col = math.ceil((vim_width - public.width) / 2)
	}

	local mappings = {
		q = "close_window",
		e = "expand",
		j = "move_cursor_down",
		k = "move_cursor_up",
		gg = "set_cursor_to_top",
		G = "set_cursor_to_bottom",
		["<Up>"] = "move_cursor_up",
		["<Down>"] = "move_cursor_down"
	}

	for key, action in pairs(mappings) do
		vim.api.nvim_buf_set_keymap(public.buffer, 'n', key, (":lua require('forge.ui.actions').%s()<CR>"):format(action), {
			nowait = true, noremap = true, silent = true,
		})
	end
	public.window = vim.api.nvim_open_win(public.buffer, true, window_options)
end

return public