EditUnitEditableGui = EditUnitEditableGui or class(EditUnit)
function EditUnitEditableGui:editable(unit)	
	return self.super.editable(self, unit) and unit:editable_gui() ~= nil
end

function EditUnitEditableGui:build_menu(units)
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
		BeardLibEditor:log("Detected new font in editable gui! font name = %s", default_font)
		table.insert(self._fonts, default_font)
	end
	self._colour_btn = self:Button("ChooseColor", callback(self, self, "show_color_dialog"), {group = light_options})
	self._text = self:TextBox("Text", callback(self._parent, self._parent, "set_unit_data"), units[1]:editable_gui():text())
	self._font = self:ComboBox("Font", callback(self._parent, self._parent, "set_unit_data"), self._fonts, table.get_key(self._fonts, units[1]:editable_gui():font()), {help = "Select a font from the combobox"})
	self._font_size = self:Slider("FontSize", callback(self._parent, self._parent, "set_unit_data"), units[1]:editable_gui():font_size(), {floats = 2, min = 0.1, max = 10, help = "Set the font size using the slider"})
	self._horizontal_align = self:ComboBox("HorizontalAlign", callback(self._parent, self._parent, "set_unit_data"), self._aligns.horizontal, table.get_key(self._aligns.horizontal, units[1]:editable_gui():align()), {help = "Select an align from the combobox"})
	self._vertical_align = self:ComboBox("VerticalAlign", callback(self._parent, self._parent, "set_unit_data"), self._aligns.vertical, table.get_key(self._aligns.vertical, units[1]:editable_gui():vertical()), {help = "Select an align from the combobox"})
	self._wrapping = self:Toggle("TextWrapping", callback(self._parent, self._parent, "set_unit_data"), units[1]:editable_gui():wrap())
	self._word_wrapping = self:Toggle("TextWordWrapping", callback(self._parent, self._parent, "set_unit_data"), units[1]:editable_gui():word_wrap(), {enabled = units[1]:editable_gui():wrap()}) --
	self._debug = self:Toggle("Debug", callback(self._parent, self._parent, "set_unit_data"))
	self._render_template = self:ComboBox("RenderTemplate", callback(self._parent, self._parent, "set_unit_data"), self._render_templates, table.get_key(self._render_templates, units[1]:editable_gui():blend_mode()), {help = "Select a Render Template from the combobox"})
	self._blend_mode = self:ComboBox("BlendMode", callback(self._parent, self._parent, "set_unit_data"), self._blend_modes, table.get_key(self._blend_modes, units[1]:editable_gui():blend_mode()), {
		help = "Select a Blend Mode from the combobox", 
		enabled = units[1]:editable_gui():render_template() == "Text",
	})
	self._alpha = self:Slider("Alpha", callback(self._parent, self._parent, "set_unit_data"), units[1]:editable_gui():alpha(), {floats = 2, min = 0, max = 1, help = "Set the alpha using the slider"})
	self._shapes = {}
	for i, s in ipairs({"x", "y", "w", "h"}) do
		local shape = units[1]:editable_gui():shape()
		self._shapes[i] = self:Slider(s:upper(), callback(self._parent, self._parent, "set_unit_data"), shape[i], {floats = 2, min = 0, max = 1, help = "Set shape using the slider"})
	end
end

function EditUnitEditableGui:set_unit_data()	
	local unit = self:selected_unit()
	unit:editable_gui():set_debug(self._debug:Value())
	unit:editable_gui():set_shape({self._shapes[1]:Value(),self._shapes[2]:Value(),self._shapes[3]:Value(),self._shapes[4]:Value()})
	unit:editable_gui():set_alpha(self._alpha:Value())
	local render_template = self._render_template:SelectedItem()
	self._blend_mode:SetEnabled(render_template == "Text")
	unit:editable_gui():set_render_template(render_template)
	unit:editable_gui():set_blend_mode(self._blend_mode:SelectedItem())
	local wrap = self._wrapping:Value()
	self._word_wrapping:SetEnabled(wrap)	
	unit:editable_gui():set_wrap(wrap)
	unit:editable_gui():set_word_wrap(self._word_wrapping:Value())
	unit:editable_gui():set_align(self._horizontal_align:SelectedItem())
	unit:editable_gui():set_vertical(self._vertical_align:SelectedItem())
	unit:editable_gui():set_font(self._font:SelectedItem())
	unit:editable_gui():set_text(utf8.from_latin1(self._text:Value()))
	unit:editable_gui():set_font_size(self._font_size:Value())
end

function EditUnitEditableGui:update_positions() 
	self:set_unit_data()
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