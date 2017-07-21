Hooks:PreHook(Setup, "start_loading_screen", "BeardLibEditorStartLoadingScreen", function()
	Global.level_data.editor_load = nil
	if Global.level_data and Global.editor_mode then
		local level_tweak_data = tweak_data.levels[Global.level_data.level_id]
		if level_tweak_data then
			local gui_data = CoreGuiDataManager.GuiDataManager:new(LoadingEnvironmentScene:gui())
			local ws = gui_data:create_fullscreen_workspace()
			local panel = ws:panel():panel({name = "Load", layer = 50})
			local bgcolor = BeardLibEditor.Options:GetValue("BackgroundColor")
			panel:rect({
				name = "Background",
		       	color = bgcolor:with_alpha(1),
			})
			Global.LoadingText = panel:text({
				name = "Loading",
				font = "fonts/font_large_mf",
				font_size = 32,
				color = bgcolor:contrast(),
				align = "center",
				vertical = "center",
			})
			Global.LoadingText:set_text(BeardLibEditor:SetLoadingText("Waiting For Response"))
			Global.level_data.editor_load = true
		end
	end
end)

Hooks:PreHook(Setup, "stop_loading_screen", "BeardLibEditorStopLoading", function()
	if managers.editor then
		managers.editor:animate_bg_fade()
	end
	Global.LoadingText = nil
end)

Hooks:PreHook(Setup, "init_managers", "BeardLibEditorInitManagersPre", function()
	if managers.editor then
		BeardLibEditor:SetLoadingText("Starting Loading Managers")
	end
end)

Hooks:PostHook(Setup, "init_managers", "BeardLibEditorInitManagers", function()
	if managers.editor then
		BeardLibEditor:SetLoadingText("Done Loading Managers")
	end
end)