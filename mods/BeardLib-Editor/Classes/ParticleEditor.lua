core:import("CoreEngineAccess")
require("core/lib/utils/dev/tools/particle_editor/CoreParticleEditorUtil")
require("core/lib/utils/dev/tools/particle_editor/CoreParticleEditorProperties")
require("core/lib/utils/dev/tools/particle_editor/CoreParticleEditorEffect")
require("core/lib/utils/dev/tools/particle_editor/CoreParticleEditorInitializers")
require("core/lib/utils/dev/tools/particle_editor/CoreParticleEditorSimulators")
require("core/lib/utils/dev/tools/particle_editor/CoreParticleEditorVisualizers")
require("core/lib/utils/dev/tools/particle_editor/CoreParticleEditorPanel")


function collect_members(cls, m)
	for funcname, funcobj in pairs(cls) do
		if funcname:find("create_") then
			local fn = funcname:gsub("create_", "")
			m[fn] = funcobj
		end
	end
end

function collect_member_names(members, member_names)
	for k, v in pairs(members) do
		local vi = v()

		table.insert(member_names, {
			ui_name = vi:ui_name(),
			key = k
		})
	end

	table.sort(member_names, function (a, b)
		return a.ui_name < b.ui_name
	end)
end

stack_members = {
	initializer = {},
	simulator = {},
	visualizer = {}
}
stack_member_names = {
	initializer = {},
	simulator = {},
	visualizer = {}
}

collect_members(CoreParticleEditorInitializers, stack_members.initializer)
collect_members(CoreParticleEditorSimulators, stack_members.simulator)
collect_members(CoreParticleEditorVisualizers, stack_members.visualizer)
collect_member_names(stack_members.initializer, stack_member_names.initializer)
collect_member_names(stack_members.simulator, stack_member_names.simulator)
collect_member_names(stack_members.visualizer, stack_member_names.visualizer)

ParticleEditor = ParticleEditor or class(EditorPart)

function ParticleEditor:init(menu)
	if managers.editor then
	--	managers.editor:set_listener_enabled(true)
	end

	self._gizmo_movement = "NO_MOVE"
	self._gizmo_accum = 0
	self._gizmo_anchor = Vector3(0, 300, 100)
	self._effects = {}

	self:create_main_frame(menu)
end

function ParticleEditor:create_main_frame(menu)
	menu = menu or self._menu
	self._menu = menu
	ItemExt:add_funcs(self, menu)
	menu:ClearItems()
	--self._main_frame = EWS:Frame("Tsar Bomba Particle Editor", Vector3(-1, -1, -1), Vector3(1000, 800, -1), "DEFAULT_FRAME_STYLE,FRAME_FLOAT_ON_PARENT", Global.frame)
	--local menu_bar = EWS:MenuBar()
	--local file_menu = EWS:Menu("")

	local file = self:popup("File")
	file:SButton("NewEffect", ClassClbk(self, "on_new"))
	file:SButton("OpenEffect", ClassClbk(self, "on_open"))
	file:SButton("SaveEffect(Ctrl+S)", ClassClbk(self, "on_save"))
	file:SButton("SaveEffectAs", ClassClbk(self, "on_save_as"))
	file:SButton("CloseEffect", ClassClbk(self, "on_close_effect"))
	--menu_bar:append(file_menu, "File")

	local edit = self:popup("Edit")

	edit:SButton("Undo(Ctrl-Z)", ClassClbk(self, "on_undo"))
	edit:SButton("Redo(Ctrl-Y)", ClassClbk(self, "on_redo"))

	local effect = self:popup("Effect")

	effect:SButton("Play(F1)", ClassClbk(self, "on_play"))
	effect:SButton("Play Lowest Quality Once\tF2", ClassClbk(self, "on_play_lowest"))
	effect:SButton("Play Highest Quality Once\tF3", ClassClbk(self, "on_play_highest"))

	local gizmo = self:popup("Effect Gizmo")

	self._gizmo_menu = gizmo

	gizmo:SButton("Move Effect Gizmo To Origin", ClassClbk(self, "on_move_gizmo_to_origo"))
	gizmo:SButton("Move Effect Gizmo In Front Of Camera", ClassClbk(self, "on_move_gizmo_to_camera"))
	gizmo:SButton("Move Effect Gizmo To Player", ClassClbk(self, "on_move_gizmo_to_player"))
	gizmo:separator()
	gizmo:tickbox("PARENT_NO_MOVE", ClassClbk(self, "on_automove_gizmo_no_move"), true, {text = "Do Not Move Effect Gizmo"})
	gizmo:tickbox("PARENT_JUMP", ClassClbk(self, "on_automove_gizmo_jump"), false, {text = "Move Effect Gizmo In Jump Pattern"})
	gizmo:tickbox("PARENT_SMOOTH", ClassClbk(self, "on_automove_gizmo_smooth"), false, {text = "Move Effect Gizmo In Smooth Pattern"})
	gizmo:tickbox("PARENT_CIRCLE", ClassClbk(self, "on_automove_gizmo_circle"), false, {text = "Move Effect Gizmo In Circle Pattern"})
	gizmo:separator()
	gizmo:SButton("Zero Effect Gizmo Rotation", ClassClbk(self, "on_reset_gizmo_rotation"))
	gizmo:SButton("Effect Gizmo Rotation Z To Positive Y", ClassClbk(self, "on_set_gizmo_rotation", Rotation(Vector3(1, 0, 0), -90)))
	gizmo:SButton("Effect Gizmo Rotation Z To Negative Y", ClassClbk(self, "on_set_gizmo_rotation", Rotation(Vector3(1, 0, 0), 90)))
	gizmo:SButton("Effect Gizmo Rotation Z To Positive X", ClassClbk(self, "on_set_gizmo_rotation", Rotation(Vector3(0, 1, 0), 90)))
	gizmo:SButton("Effect Gizmo Rotation Z To Negative X", ClassClbk(self, "on_set_gizmo_rotation", Rotation(Vector3(0, 1, 0), -90)))

	self._view_menu = self:popup("View")

	self._view_menu:tickbox("Enable Debug Drawing (atom bounding volumes etc.)", false, ClassClbk(self, "on_debug_draw"))
	self._view_menu:tickbox("Performance And Analysis Stats", false, ClassClbk(self, "on_effect_stats"))
	self._view_menu:separator()
	self._view_menu:tickbox("Show a graph of all operation stacks and channel reads/writes", false, ClassClbk(self, "on_show_stack_overview"))

	local batch_menu = self:popup("Batch")

	batch_menu:SButton("Batch all effects, remove update_render policy for effects not screen aligned", ClassClbk(self, "on_batch_all_remove_update_render"))
	batch_menu:SButton("Load and unload all effects", ClassClbk(self, "on_batch_all_load_unload"))

	local top_panel = self:create_top_bar(self._main_frame)
	self._effects_notebook = self:notebook("effects", {page_changed = ClassClbk(self, "on_effect_changed")}) 
end

function ParticleEditor:on_undo()
	local cur_effect = self:current_effect()

	if cur_effect then
		cur_effect:undo()
	end
end

function ParticleEditor:on_batch_all_remove_update_render()
	local ret = EWS:message_box(self._main_frame, "You are about to batch all effects of project database and remove update_render\nfor atoms that do not have a visualizer with screen_aligned set.\nAre you sure you want to continue?", "Are you sure you wish to continue?", "YES_NO", Vector3(-1, -1, 0))

	if ret ~= "YES" then
		return false
	end

	local any_saved = false

	for _, name in ipairs(managers.database:list_entries_of_type("effect")) do
		local n = DB:load_node("effect", name)
		local effect = CoreEffectDefinition:new()

		effect:load(n)

		local should_save = false

		for _, atom in ipairs(effect._atoms) do
			local cull_policy = atom:get_property("cull_policy")

			if cull_policy._value == "update_render" then
				local had_screen_aligned = false

				for _, visualizer in ipairs(atom._stacks.visualizer._stack) do
					if visualizer:name() == "billboard" and visualizer:get_property("billboard_type")._value == "screen_aligned" then
						had_screen_aligned = true
					end
				end

				if not had_screen_aligned then
					cull_policy._value = "freeze"
					should_save = true
				end
			end
		end

		if should_save then
			Application:error("FIXME: ParticleEditor:on_batch_all_remove_update_render(), (using Database:save_node())")
		end
	end

	if any_saved then
		cat_debug("debug", "Saved entries, saving database...")
	else
		cat_debug("debug", "Nothing modified, not saving database")
	end
end

function ParticleEditor:on_batch_all_load_unload()
	local ret = EWS:message_box(self._main_frame, "You are about to batch all effects of project database and load and unload them.\nAre you sure you want to continue?", "Are you sure you wish to continue?", "YES_NO", Vector3(-1, -1, 0))

	if ret ~= "YES" then
		return false
	end

	cat_debug("debug", "Loading all effects once...")

	for _, name in ipairs(managers.database:list_entries_of_type("effect")) do
		local n = DB:load_node("effect", name)
		local effect = CoreEffectDefinition:new()

		effect:load(n)

		local valid = effect:validate()

		if not valid.valid then
			cat_debug("debug", "Skipping engine load of", name, " since validation failed:", valid.message)
		else
			cat_debug("debug", "Loading", name)
			CoreEngineAccess._editor_reload_node(n, Idstring("effect"), Idstring("unique_test_effect_name"))
		end
	end

	cat_debug("debug", "Done!")
end

function ParticleEditor:on_redo()
	local cur_effect = self:current_effect()

	if cur_effect then
		cur_effect:redo()
	end
end

function ParticleEditor:on_effect_changed(new_page)
	local old_page = self._old_page

	if old_page and old_page <= #self._effects then
		self._effects[old_page]:on_lose_focus()
	end

	if new_page <= #self._effects then
		local new_effect = self._effects[new_page]

		new_effect:update_view(false)

		--if self._view_menu:is_checked("SHOW_STACK_OVERVIEW") then
		--	new_effect:show_stack_overview(true)
		--end
	end

	self._old_page = new_page
	--event:skip()
end

function ParticleEditor:on_play()
	local cur_effect = self:current_effect()

	if cur_effect then
		cur_effect:update_effect_instance()
	end
end

function ParticleEditor:on_play_lowest()
	local cur_effect = self:current_effect()

	if cur_effect then
		cur_effect:update_effect_instance(0)
	end
end

function ParticleEditor:on_play_highest()
	local cur_effect = self:current_effect()

	if cur_effect then
		cur_effect:update_effect_instance(1)
	end
end

function ParticleEditor:on_debug_draw()
	local b = "true"

	if not self._view_menu:is_checked("DEBUG_DRAWING") then
		b = "false"
	end

	Application:console_command("set show_tngeffects " .. b)
end

function ParticleEditor:on_effect_stats()
	Application:console_command("stats tngeffects")
end

function ParticleEditor:on_show_stack_overview()
	local cur_effect = self:current_effect()

	if cur_effect then
		cur_effect:show_stack_overview(self._view_menu:is_checked("SHOW_STACK_OVERVIEW"))
	end
end

function ParticleEditor:on_automove_gizmo_no_move()
	self._gizmo_menu:SetChecked("PARENT_JUMP", false)
	self._gizmo_menu:SetChecked("PARENT_SMOOTH", false)
	self._gizmo_menu:SetChecked("PARENT_CIRCLE", false)

	self._gizmo_movement = "NO_MOVE"
end

function ParticleEditor:on_automove_gizmo_jump()
	self._gizmo_menu:SetChecked("PARENT_NO_MOVE", false)
	self._gizmo_menu:SetChecked("PARENT_SMOOTH", false)
	self._gizmo_menu:SetChecked("PARENT_CIRCLE", false)

	self._gizmo_movement = "JUMP"
	self._gizmo_anchor = self:effect_gizmo():position()
	self._gizmo_accum = 0
end

function ParticleEditor:on_automove_gizmo_smooth()
	self._gizmo_menu:SetChecked("PARENT_NO_MOVE", false)
	self._gizmo_menu:SetChecked("PARENT_JUMP", false)
	self._gizmo_menu:SetChecked("PARENT_CIRCLE", false)

	self._gizmo_movement = "SMOOTH"
	self._gizmo_anchor = self:effect_gizmo():position()
	self._gizmo_accum = 0
end

function ParticleEditor:on_automove_gizmo_circle()
	self._gizmo_menu:SetChecked("PARENT_NO_MOVE", false)
	self._gizmo_menu:SetChecked("PARENT_SMOOTH", false)
	self._gizmo_menu:SetChecked("PARENT_JUMP", false)

	self._gizmo_movement = "CIRCLE"
	self._gizmo_anchor = self:effect_gizmo():position()
	self._gizmo_accum = 0
end

function ParticleEditor:on_move_gizmo_to_origo()
	local gizmo = self:effect_gizmo()

	gizmo:set_position(Vector3(0, 0, 0))
	gizmo:set_rotation(Rotation())
end

function ParticleEditor:on_move_gizmo_to_camera()
	local gizmo = self:effect_gizmo()
	local camera_rot = Application:last_camera_rotation()
	local camera_pos = Application:last_camera_position()

	gizmo:set_position(camera_pos + camera_rot:y() * 400)
end

function ParticleEditor:on_move_gizmo_to_player()
	local gizmo = self:effect_gizmo()
	local pos = gizmo:position()
	local rot = gizmo:rotation()

	gizmo:set_position(pos)
end

function ParticleEditor:on_set_gizmo_rotation(rot)
	local gizmo = self:effect_gizmo()

	self:effect_gizmo():set_rotation(rot)
end

function ParticleEditor:on_reset_gizmo_rotation()
	self:effect_gizmo():set_rotation(Rotation())
end

function ParticleEditor:create_top_bar(parent)
	--local panel = self:pan("TopBar")
	--panel:button("Play", ClassClbk(self, "on_play"))
	--panel:button("PlayLowestQualityOnce", ClassClbk(self, "on_play_lowest"))
	--panel:button("PlayHighestQualityOnce", ClassClbk(self, "on_play_highest"))
	--panel:divider("Click on parameters and container names for usage hints")

	return panel
end

function ParticleEditor:effect_gizmo()
	if not self._effect_gizmo or not alive(self._effect_gizmo) then
		self._effect_gizmo = World:spawn_unit(Idstring("core/units/effect_gizmo/effect_gizmo"), Vector3(0, 300, 100), Rotation())

		if managers.editor then
			--managers.editor:add_special_unit(self._effect_gizmo, "Statics")
		end
	end

	return self._effect_gizmo
end

function ParticleEditor:update(t, dt)
	local cur_effect = self:current_effect()

	if cur_effect then
		cur_effect:update(t, dt)
	end

	if self._gizmo_movement == "SMOOTH" then
		local gizmo = self:effect_gizmo()
		self._gizmo_accum = self._gizmo_accum + dt * 360 / 4
		local a = self._gizmo_accum
		local r = 500

		gizmo:set_position(self._gizmo_anchor + Vector3(r, 0, 0) * math.cos(a) + Vector3(0, r, 0) * math.sin(a) + Vector3(0, 0, r / 5) * math.cos(5 * a))
		local res = Rotation(Vector3(1, 0, 0), 45 * math.cos(5 * a))
		mvector3.add(res, res, Rotation(Vector3(1, 0, 0), -90))
		gizmo:set_rotation(Rotation(Vector3(0, 0, 1), a) * res)
	elseif self._gizmo_movement == "JUMP" then
		local gizmo = self:effect_gizmo()
		self._gizmo_accum = self._gizmo_accum + dt
		local s = math.round(self._gizmo_accum)
		s = math.fmod(s, 15)

		gizmo:set_position(self._gizmo_anchor + Vector3(100 * s, 0, 0))
	elseif self._gizmo_movement == "CIRCLE" then
		local gizmo = self:effect_gizmo()
		self._gizmo_accum = self._gizmo_accum + dt * 360 / 16
		local a = self._gizmo_accum
		local r = 500

		gizmo:set_position(self._gizmo_anchor + Vector3(r, 0, 0) * math.cos(a) + Vector3(0, r, 0) * math.sin(a))
		gizmo:set_rotation(Rotation(Vector3(0, 0, 1), a) * Rotation(Vector3(1, 0, 0), -90))
	end
end

function ParticleEditor:set_position(pos)
end

function ParticleEditor:destroy()
	if alive(self._main_frame) then
		self._main_frame:destroy()

		self._main_frame = nil
	end
end

function ParticleEditor:close()
	self._main_frame:destroy()
end

function ParticleEditor:on_close_effect()
	local curi = self:current_effect_index()
	if curi > 0 then
		if not self:current_effect():close() then
			return
		end

		self._effects_notebook:RemovePage(curi)
		table.remove(self._effects, curi)
	end

	self:remove_gizmo()
end

function ParticleEditor:on_close()
	for _, e in ipairs(self._effects) do
		if not e:close() then
			return
		end
	end

	self:remove_gizmo()
--	managers.toolhub:close("Particle Editor")

--	if managers.editor then
	--	managers.editor:set_listener_enabled(false)
--	end
end

function ParticleEditor:remove_gizmo()
	if alive(self._effect_gizmo) then
		--managers.editor:remove_special_unit(self._effect_gizmo)
		World:delete_unit(self._effect_gizmo)
	end
end

function ParticleEditor:add_effect(effect)
	--self._menu:ClearItems()

	local effect_panel = CoreParticleEditorPanel:new(self, self._effects_notebook, effect)

	table.insert(self._effects, effect_panel)

	local n = effect:name()

	if n == "" then
		n = "New Effect"
	else
		n = BLE.Utils:ShortPath(base_path(n), 3)
	end

	self._effects_notebook:AddItemPage(n, effect_panel:panel())
	
	effect_panel:set_init_positions()
end

function ParticleEditor:current_effect()
	return self._effects[self:current_effect_index()]
end

function ParticleEditor:current_effect_index()
	return self._effects_notebook:GetCurrentPage()
end

function ParticleEditor:effect_for_page(page)
	for _, e in ipairs(self._effects) do
		if e:panel() == page then
			return e
		end
	end

	return nil
end

function ParticleEditor:set_page_name(page, name)
	--[[local i = 0

	while i < self._effects_notebook:GetPageCount() do
		if self._effects_notebook:get_page(i) == page:panel() and self._effects_notebook:get_page_text(i) ~= name then
			self._effects_notebook:set_page_text(i, name)
		end

		i = i + 1
	end]]
end

function ParticleEditor:on_new()
	self:add_effect(CoreEffectDefinition:new(""))
end

function ParticleEditor:on_open()
	BLE.FBD:Show({where = string.gsub(Application:base_path(), "\\", "/"), extensions = {"effect"}, file_click = function(f)
	    if not f then
			return
		end

	--	self._last_used_dir = dir_name(f)
		local n = SystemFS:parse_xml(f, "r")
		local effect = CoreEffectDefinition:new()
	
		effect:load(n)
		effect:set_name(f)
		self:add_effect(effect)
		BLE.FBD:Hide()
	end})
end

function ParticleEditor:on_save()
	local cur = self:current_effect()

	if cur then
		cur:on_save()
	end
end

function ParticleEditor:on_save_as()
	local cur = self:current_effect()

	if cur then
		cur:on_save_as()
	end
end
