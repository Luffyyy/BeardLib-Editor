EditUnitEditableGui = EditUnitEditableGui or class(EditorPart)
function EditUnitEditableGui:init()
end
function EditUnitEditableGui:is_editable(parent, menu, name)
	local units = parent._selected_units
	if alive(units[1]) and units[1]:editable_gui() then
		self._selected_units = units
	else
		return nil
	end
	self.super.init_basic(self, parent, menu, name)
	self._menu = parent._menu
	local gui_options = self:Group("EditableGui")

	self._element_guis = {}
	self._fonts = {
		"core/fonts/diesel",
		"fonts/font_medium_shadow_mf",
		"fonts/font_small_shadow_mf",
		"fonts/font_eroded",
		"fonts/font_large_mf",
		"fonts/font_medium_mf",
		"fonts/font_small_mf"
	}
	self._aligns = {
		horizontal = {
			"left",
			"center",
			"right",
			"justified"
		},
		vertical = {
			"top",
			"center",
			"bottom"
		}
	}
	self._blend_modes = {
		"normal",
		"add",
		"mul",
		"mulx2",
		"sub",
		"darken",
		"lighten"
	}
	self._render_templates = {
		"diffuse_vc_decal",
		"Text",
		"TextDistanceField",
		"diffuse_vc_decal_distance_field"
	}
	local font_options = clone(self._fonts)
	local default_font = units[1]:editable_gui():default_font()
	if not table.contains(self._fonts, default_font) then
		BeardLibEditor:Log("Detected new font in editable gui!")
		table.insert(self._fonts, default_font)
	end
	self._colour_btn = self:Button("ChooseColor", callback(self, self, "show_color_dialog"), {group = light_options})
	self._text = self:TextBox("Text", callback(self, self, "update_gui_text"), units[1]:editable_gui():text())
	self._font = self:ComboBox("Font", callback(self, self, "update_font"), self._fonts, table.get_key(self._fonts, units[1]:editable_gui():font()), {help = "Select a font from the combobox"})
	self._font_size = self:Slider("FontSize", callback(self, self, "update_font_size"), units[1]:editable_gui():font_size(), {floats = 2, min = 0.1, max = 10, help = "Set the font size using the slider"})
	self._horizontal_align = self:ComboBox("HorizontalAlign", callback(self, self, "update_align"), self._aligns.horizontal, table.get_key(self._aligns.horizontal, units[1]:editable_gui():align()), {help = "Select an align from the combobox"})
	self._vertical_align = self:ComboBox("VerticalAlign", callback(self, self, "update_vertical"), self._aligns.vertical, table.get_key(self._aligns.vertical, units[1]:editable_gui():vertical()), {help = "Select an align from the combobox"})
	self._wrapping = self:Toggle("TextWrapping", callback(self, self, "update_text_wrap"), units[1]:editable_gui():wrap())
	self._word_wrapping = self:Toggle("TextWordWrapping", callback(self, self, "update_text_word_wrap"), units[1]:editable_gui():word_wrap(), {enabled = units[1]:editable_gui():wrap()}) --
	self._debug = self:Toggle("Debug", callback(self, self, "update_debug"))
	self._render_template = self:ComboBox("RenderTemplate", callback(self, self, "update_render_template"), self._render_templates, table.get_key(self._render_templates, units[1]:editable_gui():blend_mode()), {help = "Select a Render Template from the combobox"})
	self._blend_mode = self:ComboBox("BlendMode", callback(self, self, "update_blend_mode"), self._blend_modes, table.get_key(self._blend_modes, units[1]:editable_gui():blend_mode()), {
		help = "Select a Blend Mode from the combobox", 
		enabled = units[1]:editable_gui():render_template() == "Text",
	})
	self._alpha = self:Slider("Alpha", callback(self, self, "update_alpha"), units[1]:editable_gui():alpha(), {floats = 2, min = 0, max = 1, help = "Set the alpha using the slider"})
	self._shapes = {}
	for i, s in ipairs({"x", "y", "w", "h"}) do
		local shape = units[1]:editable_gui():shape()
		self._shapes[i] = self:Slider(s:upper(), callback(self, self, "update_shape"), shape[i], {floats = 2, min = 0, max = 1, help = "Set shape using the slider"})
	end
	return self
end

function EditUnitEditableGui:show_color_dialog() --
	local colordlg = EWS:ColourDialog(Global.frame, true, self._ctrls.color_button:background_colour() / 255)
	if colordlg:show_modal() then
		self._ctrls.color_button:set_background_colour(colordlg:get_colour().x * 255, colordlg:get_colour().y * 255, colordlg:get_colour().z * 255)
		for _, unit in ipairs(self._selected_units) do
			if alive(unit) and unit:editable_gui() then
				unit:editable_gui():set_font_color(Vector3(colordlg:get_colour().x, colordlg:get_colour().y, colordlg:get_colour().z))
			end
		end
	end
end

function EditUnitEditableGui:update_debug(menu, item)
	for _, unit in ipairs(self._selected_units) do
		if alive(unit) and unit:editable_gui() then
			unit:editable_gui():set_debug(item:Value())
		end
	end
	self._parent:set_unit_data()	
end

function EditUnitEditableGui:update_shape()
	local shape = {
		self._shapes[1]:Value(),
		self._shapes[2]:Value(),
		self._shapes[3]:Value(),
		self._shapes[4]:Value()
	}
	for _, unit in ipairs(self._selected_units) do
		if alive(unit) and unit:editable_gui() then
			unit:editable_gui():set_shape(shape)
		end
	end
	self._parent:set_unit_data()
end

function EditUnitEditableGui:update_alpha(menu, item)
	for _, unit in ipairs(self._selected_units) do
		if alive(unit) and unit:editable_gui() then
			unit:editable_gui():set_alpha(item:Value())
		end
	end
	self._parent:set_unit_data()
end

function EditUnitEditableGui:update_render_template(menu, item)
	local render_template = item:SelectedItem()
	self._blend_mode:SetEnabled(render_template == "Text")
	for _, unit in ipairs(self._selected_units) do
		if alive(unit) and unit:editable_gui() then
			unit:editable_gui():set_render_template(render_template)
		end
	end
	self._parent:set_unit_data()
end

function EditUnitEditableGui:update_blend_mode(menu, item)
	for _, unit in ipairs(self._selected_units) do
		if alive(unit) and unit:editable_gui() then
			unit:editable_gui():set_blend_mode(item:SelectedItem())
		end
	end
	self._parent:set_unit_data()
end

function EditUnitEditableGui:update_text_wrap(menu, item)
	local enabled = item:Value()
	self._word_wrapping:SetEnabled(enabled)
	for _, unit in ipairs(self._selected_units) do
		if alive(unit) and unit:editable_gui() then
			unit:editable_gui():set_wrap(enabled)
		end
	end
	self._parent:set_unit_data()
end

function EditUnitEditableGui:update_text_word_wrap(menu, item)
	for _, unit in ipairs(self._selected_units) do
		if alive(unit) and unit:editable_gui() then
			unit:editable_gui():set_word_wrap(item:Value())
		end
	end
	self._parent:set_unit_data()
end

function EditUnitEditableGui:update_align(menu, item)
	for _, unit in ipairs(self._selected_units) do
		if alive(unit) and unit:editable_gui() then
			unit:editable_gui():set_align(item:SelectedItem())
		end
	end
	self._parent:set_unit_data()
end

function EditUnitEditableGui:update_vertical(menu, item)
	for _, unit in ipairs(self._selected_units) do
		if alive(unit) and unit:editable_gui() then
			unit:editable_gui():set_vertical(item:SelectedItem())
		end
	end
	self._parent:set_unit_data()
end

function EditUnitEditableGui:update_font(menu, item)
	for _, unit in ipairs(self._selected_units) do
		if alive(unit) and unit:editable_gui() then
			unit:editable_gui():set_font(item:SelectedItem())
		end
	end
	self._parent:set_unit_data()
end

function EditUnitEditableGui:update_gui_text(menu, item)
	for _, unit in ipairs(self._selected_units) do
		if alive(unit) and unit:editable_gui() then
			unit:editable_gui():set_text(utf8.from_latin1(item:Value()))
		end
	end
	self._parent:set_unit_data()
end

function EditUnitEditableGui:update_font_size(menu, item)
	for _, unit in ipairs(self._selected_units) do
		if alive(unit) and unit:editable_gui() then
			unit:editable_gui():set_font_size(item:Value())
		end
	end
	self._parent:set_unit_data()
end
 