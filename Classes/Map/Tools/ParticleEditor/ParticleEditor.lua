core:import("CoreEngineAccess")
require("core/lib/utils/dev/tools/particle_editor/CoreParticleEditorUtil")
require("core/lib/utils/dev/tools/particle_editor/CoreParticleEditorProperties")
require("core/lib/utils/dev/tools/particle_editor/CoreParticleEditorEffect")
require("core/lib/utils/dev/tools/particle_editor/CoreParticleEditorInitializers")
require("core/lib/utils/dev/tools/particle_editor/CoreParticleEditorSimulators")
require("core/lib/utils/dev/tools/particle_editor/CoreParticleEditorVisualizers")
require("core/lib/utils/dev/tools/particle_editor/CoreParticleEditorPanel")


local function collect_members(cls, m)
	for funcname, funcobj in pairs(cls) do
		if funcname:find("create_") then
			local fn = funcname:gsub("create_", "")
			m[fn] = funcobj
		end
	end
end

local function collect_member_names(members, member_names)
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

local stack_members = {
	initializer = {},
	simulator = {},
	visualizer = {}
}
local stack_member_names = {
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

function ParticleEditor:init(editor, menu)
	self._parent = editor
	self._triggers = {}

	self._menu = menu:Menu({
		auto_foreground = true,
		align_method = "grid",
		background_color = BLE.Options:GetValue("BackgroundColor"),
		visible = false,
		w = BLE.Options:GetValue("ParticleEditorPanelWidth"),
	})

	self._gizmo_movement = "NO_MOVE"
	self._gizmo_accum = 0
	self._gizmo_anchor = Vector3(0, 300, 100)
	self._effects = {}

	self:create_main_frame()
end

function ParticleEditor:disable()
	ParticleEditor.super.disable(self)
	self._menu:SetVisible(false)
end

function ParticleEditor:enable()
	ParticleEditor.super.enable(self)
	self._menu:SetVisible(true)
	self:bind_opt("Undo", ClassClbk(self, "on_undo"))
    self:bind_opt("Redo", ClassClbk(self, "on_redo"))
    self:bind_opt("SaveMap", ClassClbk(self, "on_save"))
end

function ParticleEditor:create_main_frame()
	ItemExt:add_funcs(self)
	self._menu:ClearItems()
	--self._main_frame = EWS:Frame("Tsar Bomba Particle Editor", Vector3(-1, -1, -1), Vector3(1000, 800, -1), "DEFAULT_FRAME_STYLE,FRAME_FLOAT_ON_PARENT", Global.frame)
	--local menu_bar = EWS:MenuBar()
	--local file_menu = EWS:Menu("")

	local file = self:popup("File")
	file:tb_btn("NewEffect", ClassClbk(self, "on_new"))
	file:tb_btn("OpenEffect", ClassClbk(self, "on_open"))
	file:tb_btn("SaveEffect(Ctrl+S)", ClassClbk(self, "on_save"))
	file:tb_btn("SaveEffectAs", ClassClbk(self, "on_save_as"))
	file:tb_btn("CloseEffect", ClassClbk(self, "on_close_effect"))
	file:tb_btn("Exit", ClassClbk(self, "on_close"))

	--menu_bar:append(file_menu, "File")

	local edit = self:popup("Edit")

	edit:tb_btn("Undo(Ctrl-Z)", ClassClbk(self, "on_undo"))
	edit:tb_btn("Redo(Ctrl-Y)", ClassClbk(self, "on_redo"))

	local effect = self:popup("Effect")

	effect:tb_btn("Play", ClassClbk(self, "on_play"))
	effect:tb_btn("Play Lowest Quality Once", ClassClbk(self, "on_play_lowest"))
	effect:tb_btn("Play Highest Quality Once", ClassClbk(self, "on_play_highest"))

	local gizmo = self:popup("Effect Gizmo")

	self._gizmo_menu = gizmo

	gizmo:tb_btn("Move Effect Gizmo To Origin", ClassClbk(self, "on_move_gizmo_to_origo"))
	gizmo:tb_btn("Move Effect Gizmo In Front Of Camera", ClassClbk(self, "on_move_gizmo_to_camera"))
	gizmo:tb_btn("Move Effect Gizmo To Player", ClassClbk(self, "on_move_gizmo_to_player"))
	gizmo:separator()
	gizmo:tickbox("PARENT_NO_MOVE", ClassClbk(self, "on_automove_gizmo_no_move"), true, {text = "Do Not Move Effect Gizmo"})
	gizmo:tickbox("PARENT_JUMP", ClassClbk(self, "on_automove_gizmo_jump"), false, {text = "Move Effect Gizmo In Jump Pattern"})
	gizmo:tickbox("PARENT_SMOOTH", ClassClbk(self, "on_automove_gizmo_smooth"), false, {text = "Move Effect Gizmo In Smooth Pattern"})
	gizmo:tickbox("PARENT_CIRCLE", ClassClbk(self, "on_automove_gizmo_circle"), false, {text = "Move Effect Gizmo In Circle Pattern"})
	gizmo:separator()
	gizmo:tb_btn("Zero Effect Gizmo Rotation", ClassClbk(self, "on_reset_gizmo_rotation"))
	gizmo:tb_btn("Effect Gizmo Rotation Z To Positive Y", ClassClbk(self, "on_set_gizmo_rotation", Rotation(Vector3(1, 0, 0), -90)))
	gizmo:tb_btn("Effect Gizmo Rotation Z To Negative Y", ClassClbk(self, "on_set_gizmo_rotation", Rotation(Vector3(1, 0, 0), 90)))
	gizmo:tb_btn("Effect Gizmo Rotation Z To Positive X", ClassClbk(self, "on_set_gizmo_rotation", Rotation(Vector3(0, 1, 0), 90)))
	gizmo:tb_btn("Effect Gizmo Rotation Z To Negative X", ClassClbk(self, "on_set_gizmo_rotation", Rotation(Vector3(0, 1, 0), -90)))

	--self._view_menu = self:popup("View")

	--self._view_menu:tickbox("Enable Debug Drawing (atom bounding volumes etc.)", false, ClassClbk(self, "on_debug_draw"))
	--self._view_menu:tickbox("Performance And Analysis Stats", false, ClassClbk(self, "on_effect_stats"))
	--self._view_menu:separator()
	--self._view_menu:tickbox("Show a graph of all operation stacks and channel reads/writes", false, ClassClbk(self, "on_show_stack_overview"))

	--local batch_menu = self:popup("Batch")

	--batch_menu:tb_btn("Batch all effects, remove update_render policy for effects not screen aligned", ClassClbk(self, "on_batch_all_remove_update_render"))
	--batch_menu:tb_btn("Load and unload all effects", ClassClbk(self, "on_batch_all_load_unload"))

	self._effects_notebook = self:notebook("effects", {page_changed = ClassClbk(self, "on_effect_changed"), offset = 4}) 
end

function ParticleEditor:on_undo()
	local cur_effect = self:current_effect()

	if cur_effect then
		cur_effect:undo()
	end
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
	ParticleEditor.super.update(self, t, dt)
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
	local effect = self:current_effect()

	if effect then
		self._effects_notebook:RemovePageWithItem(effect:panel())
		effect:close()
		table.delete(self._effects, effect)
	end

	self:remove_gizmo()
end

function ParticleEditor:on_close()
	for _, e in ipairs(self._effects) do
		if not e:close() then
			return
		end
	end
	self._effects_notebook:RemoveAllPages()
	self._effects = {}
	self:remove_gizmo()
	self._parent._particle_editor_active = false
	self._parent:set_enabled()
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
	local i = self._effects_notebook:GetItemPage(page:panel())
	if i then
		self._effects_notebook:SetPageName(i, name)
	end
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
