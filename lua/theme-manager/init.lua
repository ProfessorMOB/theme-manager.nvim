local M = {}

M.setup = function(opts)
	opts = opts or {}
	
	if opts.json_path then
		M.JSON_path = vim.fs.normalize(opts.json_path)
	else
		M.JSON_path = vim.fs.normalize("$HOME/.config/themes.json")
	end
	opts.enable_lualine = M.enable_lualine
	M.enable_theming()
end

M.set_theme = function() 

	M.JSON_file = io.open(M.JSON_path, "r")
	if (M.JSON_file) then JSON = M.JSON_file:read("*a") M.JSON_file:close() end

	JSON = vim.json.decode(JSON)

	local neovim = JSON.default
	local lualine = JSON.default
	
	if (JSON[JSON.default]) then 

		neovim=JSON[JSON.default].rest or neovim
		lualine=JSON[JSON.default].rest or lualine

		if (JSON[JSON.default]).neovim then
			neovim = JSON[JSON.default].neovim 
		end
		if (JSON[JSON.default].lualine) then
			lualine = JSON[JSON.default].lualine
		end
	end

	vim.cmd.colorscheme(neovim)
	if M.enable_lualine then require("lualine").setup({ options = { theme = lualine } }) end
end

M.disable_autoreload = function()
	M.themes_file_handler:stop()
end

M.enable_autoreload = function()

	if (not M.themes_file_handler:is_active()) then
		M.themes_file_handler:start(
			M.JSON_path,
			{}, 
			vim.schedule_wrap(M.set_theme)
		)
	end
	if (M.themes_file_handler:is_closing()) then 
		print("Enable theming first")
	end
end

M.disable_theming = function()

	if (M.themes_file_handler:is_closing()) then 
		print("Theming is already disabled")
		return
	end

	M.themes_file_handler:close()
end

M.enable_theming = function()

	M.set_theme()

	M.themes_file_handler = vim.uv.new_fs_event()

	M.themes_file_handler:start(
		M.JSON_path,
		{}, 
		vim.schedule_wrap(M.set_theme)
	)

	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = M.disable_theming
	})
end

return M
