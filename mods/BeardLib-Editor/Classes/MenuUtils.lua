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

MenuUtils = MenuUtils or class()
function MenuUtils:init(this, menu)
	menu = menu or this._menu
	local color = BeardLibEditor.Options:GetValue("AccentColor")
	function this:GetMenu()
		return menu
	end

	function this:WorkMenuUtils(opt)
	    opt = opt or {}
	    opt = clone(opt)
	    local m = opt.group or menu
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
	        offset = {8, 4},
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
	        callback = callback,
	    }, opt))
	end

	function this:KeyBind(name, callback, value, o)
		local m, opt = self:WorkMenuUtils(o)
		return m:KeyBind(table.merge({
			name = name,
			value = value,
			supports_additional = true,
			callback = callback
		}, opt))
	end

	function this:SmallButton(name, callback, parent, o)    
	    local m, opt = self:WorkMenuUtils(o)
	    return m:Button(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        callback = callback,
	        size_by_text = true,
	        min_width = parent.items_size,
	        min_height = parent.items_size,
	        text_offset = 2,
			text_highlight_color = false,
	        position = function(item)
	        	item:SetPositionByString("CenterRight")
	        	item:Panel():move(-1)
	        end,
	        text_align = "center",
	        text_vertical = "center",
	        override_parent = parent,
	    }, opt))
	end	

	function this:SmallImageButton(name, callback, texture, rect, parent, o)    
	    local m, opt = self:WorkMenuUtils(o)
		if not parent then
			log(debug.traceback())
		end
	    m = parent.type_name == "Menu" and parent or m
	    opt.help = string.pretty2(name)
	    return m:ImageButton(table.merge({
	        name = name,
	        callback = callback,
	        position = "TopRight",
	        items_size = parent.items_size,
	        size_by_text = true,
	        texture = texture,
	        texture_rect = rect,
	        override_parent = parent,
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
	        callback = callback,
	    }, opt))
	end

	function this:TextBox(name, callback, value, o)
	    local m, opt = self:WorkMenuUtils(o)
	    return m:TextBox(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        callback = callback,
	        value = value
	    }, opt))
	end

	function this:Slider(name, callback, value, o)
	    local m, opt = self:WorkMenuUtils(o)
	    return m:Slider(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        value = value,
	        callback = callback,
	    }, opt))
	end

	function this:NumberBox(name, callback, value, opt)
	    local m, opt = self:WorkMenuUtils(opt)
	    return m:NumberBox(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        value = value,
	        callback = callback,
	    }, opt))
	end

	function this:Toggle(name, callback, value, o)
	    local m, opt = self:WorkMenuUtils(o)
	    return m:Toggle(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        value = value,
	        callback = callback,
	    }, opt))
	end

	function this:SetAxisControls(pos, rot, name)
		name = name or ""
	    for i, control in pairs(self._axis_controls) do
	        if alive(self[name..control]) then
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

	function this:AxisControls(callback, opt, name, pos, rot)
		name = name or ""
	    opt = opt or {}
	    opt.align_method = "grid"
	    local translation
	    local rotation
	    local group = opt.group
	    if not opt.no_pos then
			opt.text = opt.translate_text
			translation = self:DivGroup("Translate"..name, opt)
	    end
	    if not opt.no_rot then
	    	opt.group = group
			opt.text = opt.rotate_text
	    	rotation = self:DivGroup("Rotate"..name, opt)
	    end
	   	opt.text = nil
	   	opt.color = false
	    opt.w = translation.w / 3
	    opt.offset = 0
	    opt.control_slice = 1.75
	    for i, control in pairs(self._axis_controls) do
	    	opt.group = i < 4 and translation or rotation
	    	if alive(opt.group) then
	        	self[name..control] = self:NumberBox(control, callback, 0, opt)
	        end
	    end
	   	if pos and rot then
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
		opt.control_slice = opt.control_slice or 1.5
		opt.callback = opt.callback or callback
	    local t = self:TextBox(name, nil, value, opt)
	    opt.text = "Browse " .. tostring(typ).."s"
		opt.offset = {t.offset[1] * 4, t.offset[2]}
		opt.callback = nil
		opt.callback = opt.btn_callback
	    local btn = self:Button("SelectPath"..name, function()
	       BeardLibEditor.managers.ListDialog:Show({
		        list = BeardLibEditor.Utils:GetEntries({type = typ, loaded = loaded, filenames = false, check = check}),
		        callback = function(path) 
		        	t:SetValue(path, true)
		        	if not not_close then
		        		BeardLibEditor.managers.ListDialog:Hide()
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
			BeardLibEditor.managers.ColorDialog:Show({color = Color(vc.x, vc.y, vc.z), callback = function(color)
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