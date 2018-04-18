DummyItem = DummyItem or class()
function DummyItem:init(name, v)
	self.name = name
	self.value = v
end
function DummyItem:Value()
	return self.value
end
function DummyItem:SetValue(v)
	self.value = v
end

--Dumb class, but helpful.

MenuUtils = MenuUtils or class()
function MenuUtils:init(this, menu)
	this = this or self
	menu = menu or this._menu
	local color = BeardLibEditor.Options:GetValue("AccentColor")
	function this:GetMenu()
		return menu
	end

	function this:WorkMenuUtils(opt, override_panel)
	    opt = opt or {}
	    opt = clone(opt)
		local m = opt.group or menu

		override_panel = override_panel or opt.override_panel
		if override_panel then
			if override_panel.menu_type then
				m = override_panel
			elseif opt.group then
				m = override_panel.parent
			end
		end

	    opt.group = nil
	    return m, opt
	end

	function this:Divider(name, o)
	    local m, opt = self:WorkMenuUtils(o)
	    return m:Divider(table.merge({
	        name = name,
	        text = name,
	        offset = {8, 4},
	        color = color,
	    }, opt))
	end	

	function this:Group(name, o)
	    local m, opt = self:WorkMenuUtils(o)
	    return m:ItemsGroup(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        color = color
	    }, opt))
	end	

	function this:DivGroup(name, o)
	    local m, opt = self:WorkMenuUtils(o)
	    return m:DivGroup(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        color = color,
	        auto_height = true,
	        background_visible = false
	    }, opt))
	end

	function this:Menu(name, o)
		local m, opt = self:WorkMenuUtils(o)
	    opt.background_visible = opt.background_visible ~= nil and opt.background_visible or false
	    opt.auto_height = opt.auto_height == nil and true or opt.auto_height
	    return m:Menu(table.merge({
	        name = name,
	        text = string.pretty2(name),
	    }, opt))
	end

	function this:CloseButton()
		self:Button("Close", callback(menu.menu, menu.menu, "disable"))
	end

	function this:Button(name, callback, o)
	    local m, opt = self:WorkMenuUtils(o)
	    return m:Button(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        on_callback = callback,
	    }, opt))
	end

	function this:KeyBind(name, callback, value, o)
		local m, opt = self:WorkMenuUtils(o)
		return m:KeyBind(table.merge({
			name = name,
			value = value,
			supports_additional = true,
			on_callback = callback
		}, opt))
	end

	function this:CenterRight(item)
		if not item.override_panel then
			return
		end
		item:SetPosition("CenterRight")
		local prev = item.override_panel._prev_aligned
		if alive(prev) and not (prev:Index() < item:Index()) then
			item:Panel():set_righttop(prev:Panel():left() - item:OffsetX(), item:Panel():top())
		else
			item:Panel():move(-item:OffsetX())
			item.override_panel._prev_aligned = item
		end
	end

	function this:SmallButton(name, callback, parent, o)    
		local m, opt = self:WorkMenuUtils(o, parent)
		local s = parent:TextHeight()
	    return m:Button(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        on_callback = callback,
	        size_by_text = true,
	        min_width = s,
	        min_height = s,
	        max_width = s,
			max_height = s,
			offset = 2,
			foreground = parent.foreground,
			highlight_color = parent.foreground:with_alpha(0.25),
			auto_foreground = false,
			foreground_highlight = false,
	        position = ClassClbk(self, "CenterRight"),
	        text_align = "center",
	        text_vertical = "center",
	        override_panel = parent,
	    }, opt))
	end	

	function this:SmallImageButton(name, callback, texture, rect, parent, o)
	    local m, opt = self:WorkMenuUtils(o, parent)
		if not parent then
			log(debug.traceback())
		end
		opt.help = string.pretty2(name)
		local s = parent:TextHeight()
	    return m:ImageButton(table.merge({
	        name = name,
			on_callback = callback,
			foreground = parent.foreground,
			highlight_color = parent.foreground:with_alpha(0.25),
			auto_foreground = false,
	        position = ClassClbk(self, "CenterRight"),
	        w = s,
			h = s,
			offset = 2,
			img_offset = 4,
	        texture = texture,
	        texture_rect = rect,
	        override_panel = parent,
	    }, opt))
	end

	function this:ComboBox(name, callback, items, value, o)
	    local m, opt = self:WorkMenuUtils(o)
	    return m:ComboBox(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        value = value,
	        items = items,
	        bigger_context_menu = true,
	        on_callback = callback,
	    }, opt))
	end

	function this:TextBox(name, callback, value, o)
	    local m, opt = self:WorkMenuUtils(o)
	    return m:TextBox(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        on_callback = callback,
	        value = value
	    }, opt))
	end

	function this:Slider(name, callback, value, o)
	    local m, opt = self:WorkMenuUtils(o)
	    return m:Slider(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        value = value,
	        on_callback = callback,
	    }, opt))
	end

	function this:NumberBox(name, callback, value, opt)
	    local m, opt = self:WorkMenuUtils(opt)
	    return m:NumberBox(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        value = value,
	        on_callback = callback,
	    }, opt))
	end

	function this:Toggle(name, callback, value, o)
	    local m, opt = self:WorkMenuUtils(o)
	    return m:Toggle(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        value = value,
	        on_callback = callback,
	    }, opt))
	end

	function this:SetAxisControls(pos, rot, name)
		name = name or ""
	    for i, control in pairs(self._axis_controls) do
	        if alive(self[name..control]) and ((i < 4 and pos) or (i > 3 and rot)) then
				self[name..control]:SetValue(i < 4 and pos[control] or rot[control](rot))
	        end
	    end
	end

	function this:SetShapeControls(shape, name)
		name = name or ""
	    for _, control in pairs(self._shape_controls) do
	        if alive(self[name..control]) then
	            self[name..control]:SetValue(shape and shape[control] or 0)
	        end
	    end
	end

	function this:SetAxisControlsEnabled(enabled, name)
		name = name or ""
		local translate = self:GetItem("Translate"..name)
		if translate then
			translate:SetEnabled(enabled)
		end
		local rotate = self:GetItem("Rotate"..name)
		if rotate then
			rotate:SetEnabled(enabled)
		end
	end

	function this:AxisControlsPosition(name)
		name = name or ""
	    return Vector3(self[name.."x"].value, self[name.."y"].value, self[name.."z"].value)
	end

	function this:AxisControlsRotation(name)
		name = name or ""
	    return Rotation(self[name.."yaw"].value, self[name.."pitch"].value, self[name.."roll"].value)
	end

	function this:SetShapeControlsEnabled(enabled, name)
		name = name or ""
		local shape = self:GetItem("Shape"..name)
		if shape then
			shape:SetEnabled(enabled)
		end
	end

	function this:CopyAxis(item)
		Application:set_clipboard(tostring(self["AxisControls"..item.override_panel.value_type](self, item.override_panel.axis_name)))
	end
	
	function this:PasteAxis(item)
		local menu = item.override_panel
		local paste = Application:get_clipboard()
		local result
		pcall(function()
            result = loadstring("return " .. paste)()
		end)
		if type_name(result) == "Vector3" and menu.value_type == "Position" then
			self:SetAxisControls(result, nil, menu.axis_name)
		end
		if type_name(result) == "Rotation" and menu.value_type == "Rotation" then
			self:SetAxisControls(nil, result, menu.axis_name)
		end
		if menu.on_callback then
			menu.on_callback(item)
		end
	end

	function this:AxisControls(clbk, opt, name, pos, rot)
		name = name or ""
	    opt = opt or {}
		opt.align_method = "grid"
		opt.axis_name = name
		opt.on_callback = clbk
	    local translation
	    local rotation
	    local group = opt.group
	    if not opt.no_pos then
			opt.text = opt.translate_text
			opt.value_type = "Position"
			translation = self:DivGroup("Translate"..name, opt)
			local copy = self:SmallButton("p", callback(self, self, "PasteAxis"), translation, {position = "RightTop"})
			self:SmallButton("c", callback(self, self, "CopyAxis"), translation, {position = function(item) 
				item:Panel():set_righttop(copy:Panel():x() - 4, copy:Panel():y()) 
			end})
	    end
	    if not opt.no_rot then
	    	opt.group = group
			opt.text = opt.rotate_text
			opt.value_type = "Rotation"
			rotation = self:DivGroup("Rotate"..name, opt)
			local copy = self:SmallButton("p", callback(self, self, "PasteAxis"), rotation, {position = "RightTop"})
			self:SmallButton("c", callback(self, self, "CopyAxis"), rotation, {position = function(item) 
				item:Panel():set_righttop(copy:Panel():x() - 4, copy:Panel():y()) 
			end})
		end
	   	opt.text = nil
	   	opt.color = false
	    opt.w = translation.w / 3
	    opt.offset = 0
	    opt.control_slice = 0.6
	    for i, control in pairs(self._axis_controls) do
	    	opt.group = i < 4 and translation or rotation
	    	if alive(opt.group) then
	        	self[name..control] = self:NumberBox(control, clbk, 0, opt)
	        end
		end
	   	if pos or rot then
	   		self:SetAxisControls(pos, rot, name)
	   	end
	end

	function this:ShapeControls(callback, opt, name, shape, no_radius)
		name = name or ""
	    opt = opt or {}
	    opt.floats = 0
	    opt.align_method = "grid"
	    local shapegroup = self:DivGroup("Shape"..name, opt)
	    opt.color = false
	    opt.w = (shapegroup.w / 2)
	    opt.offset = 0
	    opt.group = shapegroup
	    for i, control in pairs(self._shape_controls) do
	    	if not no_radius or control ~= "radius" then
				self[control..name] = self:NumberBox(control, callback, 0, opt)
	    	end    
	    end
	    if shape then
	    	self:SetShapeControls(shape)
	    end
	end

	function this:PathItem(name, callback, value, typ, loaded, check, not_close, opt)
		opt = opt or {}
		opt.on_callback = opt.callback or callback
	    local t = self:TextBox(name, nil, value, opt)
	    opt.text = "Browse " .. tostring(typ).."s"
		opt.offset = {t.offset[1] * 4, t.offset[2]}
		opt.on_callback = nil
		opt.on_callback = opt.btn_callback
		local btn = self:Button("SelectPath"..name, function()
			local list = BeardLibEditor.Utils:GetEntries({type = typ, loaded = loaded, filenames = false, check = check})
			if opt.sort_func then
				opt.sort_func(list)
			end
	       	BeardLibEditor.ListDialog:Show({
				list = list,
				sort = opt.sort_func == nil,
		        callback = function(path) 
		        	t:SetValue(path, true)
		        	if not not_close then
		        		BeardLibEditor.ListDialog:Hide()
		        	end
		        end
		    })
	    end, opt)
	    t.SetEnabled = function(this, enabled)
	    	BeardLib.Items.TextBox.SetEnabled(this, enabled)
	    	btn:SetEnabled(enabled)
	    end
	    return t
	end

	function this:ColorEnvItem(name, opt)
		local col = DummyItem:new(name, Vector3(1,1,1))
		local btn = self:Button("SetColor"..name, function()
			local vc = col:Value()
			BeardLibEditor.ColorDialog:Show({color = Color(vc.x, vc.y, vc.z), callback = function(color)
		    	col:SetValue(Vector3(color.red, color.green, color.blue))
		    end})
		end, opt)
		return col
	end

	function this:ClearItems(lbl)
		menu:ClearItems(lbl)
	end	

	function this:GetItem(name)
		return menu:GetItem(name)
	end

	function this:RemoveItem(item)
		return menu:RemoveItem(item)
	end
end