local M = {}

M.setup = function(opts)
	opts = opts or {}
	
	if opts.json_path then
		M.JSON_path = vim.fs.normalize(opts.json_path)
	else
		M.JSON_path = vim.fs.normalize("$HOME/.config/themes.json")
	end
	M.enable_lualine = opts.enable_lualine
	if opts.hooks then
		M.set_theme_pre = opts.hooks.set_theme_pre
		M.set_theme_post = opts.hooks.set_theme_post
		M.watchpre = opts.hooks.watchpre
		M.watchpost = opts.hooks.watchpost
		M.autoreloadpre = opts.hooks.autoreloadpre
		M.autoreloadpost = opts.hooks.autoreloadpost
		M.deautoreloadpre = opts.hooks.deautoreloadpre
		M.deautoreloadpost = opts.hooks.deautoreloadpost
		M.togglepre = opts.hooks.togglepre
		M.togglepost = opts.hooks.togglepost
		M.on_error = opts.hooks.on_error
		M.integrate = opts.hooks.integrate
	end
end

M.set_theme = function() 

	if type(M.set_theme_pre) == "function" then
		M.set_theme_pre()
	end

	M.JSON_file = io.open(M.JSON_path, "r")
	if (M.JSON_file) then JSON = M.JSON_file:read("*a") M.JSON_file:close()
	else M.error="Failed to open JSON file" return end

	JSON = vim.json.decode(JSON)
	if not JSON then M.error="Failed to parse JSON" return end

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

	if (type(M.integrate) == "function") then 
		M.integrate(JSON)
	end

	if not pcall(vim.cmd.colorscheme, neovim) then
		vim.print("warning: neovim not set/not working in themes file")
	end

	if M.enable_lualine then
		if lualine then require("lualine").setup({ options = { theme = lualine } }) 
		else print("warning: lualine not set in themes file") end
	end

end

M.disable_autoreload = function()

	if type(M.deautoreloadpre) == "function" then
		M.deautoreloadpre()
	end
	
	if (not M.themes_file_handler or M.themes_file_handler:is_closing()) then 
		print("Enable theming first")
		return false
	end

	M.themes_file_handler:stop()
	
	if type(M.deautoreloadpost) == "function" then 
		M.deautoreloadpost()
	end

	return true
end

M.enable_autoreload = function()
	if type(M.autoreloadpre) == "function" then 
		M.autoreloadpre()
	end

	--> check if theming is disabled

	if (not M.themes_file_handler or M.themes_file_handler:is_closing()) then 
		print("Enable theming first")
		return false
	end
	if (not M.themes_file_handler:is_active()) then
		M.themes_file_handler:start(
			M.JSON_path,
			{}, 
			vim.schedule_wrap(M.set_theme)
		)
	end

	if type(M.autoreloadpost) == "function" then 
		M.autoreloadpost()
	end

	return true
end

M.toggle_autoreload = function() 

	if (not M.themes_file_handler or M.themes_file_handler:is_closing()) then 
		print("Enable theming first")
		return false
	end

	if type(M.togglepre) == "function" then 
		M.togglepre()
	end

	if (M.themes_file_handler:is_active()) then
		M.themes_file_handler:stop()
	else 
		M.themes_file_handler:start(
			M.JSON_path,
			{}, 
			vim.schedule_wrap(M.set_theme)
		)
	end
	
	if type(M.togglepost) == "function" then 
		M.togglepost()
	end

	return true
end

M.disable_theming = function()

	if type(M.unwatchpre) == "function" then 
		M.unwatchpre()
	end

	if (not M.themes_file_handler or M.themes_file_handler:is_closing()) then 
		print("Theming is already disabled")
		return
	end

	M.themes_file_handler:close()

	if type(M.unwatchpost) == "function" then 
		M.unwatchpost()
	end
end

M.enable_theming = function()

	if type(M.watchpre) == "function" then 
		M.watchpre()
	end

	M.set_theme()

	if (M.error) then 
		
		if type(M.on_error) == "function" then 
			M.on_error()
		end

		vim.print(M.error)
		M.error = false

		return
	end

	M.themes_file_handler = vim.uv.new_fs_event()

	M.themes_file_handler:start(
		M.JSON_path,
		{}, 
		vim.schedule_wrap(M.set_theme)
	)

	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = M.disable_theming
	})

	if type(M.watchpost) == "function" then 
		M.watchpost()
	end
end

return M
