LoadLevelMenu = LoadLevelMenu or class()
function LoadLevelMenu:init()
	self._main_menu = MenuUI:new({
        alpha = 0.4,
        text_color = Color.white,
        highlight_color = Color("33476a"),
        background_color = Color(0.2, 0.2, 0.2),
		create_items = callback(self, self, "create_items"),
	})	
end

function LoadLevelMenu:create_items(menu)
	self._menu = menu:NewMenu({
		name = "LoadLevel",
        visible = true,
        position = "Center",
        w = 750,
	})
	self._menu:Button({
		name = "close_button",
		text = "Close",
		callback = function()
			menu:disable()
		end
	})
	for _, job_id in ipairs(tweak_data.narrative:get_jobs_index()) do
		if not tweak_data.narrative.jobs[job_id].wrapped_to_job then
			local text_id = tweak_data.narrative:create_job_name(job_id)
			self._menu:Button({
				name = job_id,
				text = string.pretty(text_id, true) .. "[" .. job_id .. "]",
				callback = callback(self, self, "load_level", job_id)
			})				
		end
	end	
    local i =  #self._menu.items
    i = (i % 3 == 0) and i or i + 1
    self._menu:SetMaxRow(math.max(1, i / 3))
end

function LoadLevelMenu:load_level(level_id)
    QuickMenu:new( "Load level?", "",
        {[1] = {text = "Yes", callback = function()
        	Global.editor_mode = true
			MenuCallbackHandler:play_single_player()
			MenuCallbackHandler:start_single_player_job({job_id = level_id, difficulty = "normal"})            
        end
    },[2] = {text = "No", is_cancel_button = true}}, true)
end

function LoadLevelMenu:BuildNode(main_node)
	MenuCallbackHandler.BeardLibMpaEditorMenuOpen = function(this, item)
      	self._main_menu:enable()
	end
    MenuHelperPlus:AddButton({
        id = "BeardLibEditorLoadLevel",
        title = "BeardLibEditorLoadLevel_title",
        node = main_node,
        callback = "BeardLibMpaEditorMenuOpen"
    })
end
 