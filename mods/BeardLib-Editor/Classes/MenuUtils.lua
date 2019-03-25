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
--To be removed/moved to MenuUIExt

MenuUtils = MenuUtils or class()
function MenuUtils:init(this, menu)
	this = this or self
	menu = menu or this._menu
	local color = BeardLibEditor.Options:GetValue("AccentColor")
	function this:GetMenu()
		return menu
	end

	function this:WorkMenuUtils(opt)
	    return (opt and opt.group) or menu, opt or {}
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
		self:Button("Close", ClassClbk(menu.menu, "disable"))
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
			local is_pos = (i < 4 and pos)
			local is_rot = (i > 3 and rot)
			local item = self[name..control]
			if alive(item) and (is_pos or is_rot) then
				if is_pos then
					item:SetValue(pos[control])
				else
					item:SetValue(rot[control](rot))
				end
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
		local menu = item.parent.parent
		Application:set_clipboard(tostring(self["AxisControls"..menu.value_type](self, menu.axis_name)))
	end
	
	function this:PasteAxis(item)
		local menu = item.parent.parent
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
		menu:RunCallback()
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
			translation = self:DivGroup("Translate"..name, opt)
			translation.value_type = "Position"
			local TB = translation:GetToolbar()
			TB:SqButton("p", ClassClbk(self, "PasteAxis"), {offset = 0})
			TB:SqButton("c", ClassClbk(self, "CopyAxis"), {offset = 0})
	    end
	    if not opt.no_rot then
	    	opt.group = group
			opt.text = opt.rotate_text
			rotation = self:DivGroup("Rotate"..name, opt)
			rotation.value_type = "Rotation"
			local TB = rotation:GetToolbar()
			TB:SqButton("p", ClassClbk(self, "PasteAxis"), {offset = 0})
			TB:SqButton("c", ClassClbk(self, "CopyAxis"), {offset = 0})
		end
	   	opt.text = nil
	   	opt.color = false
	    opt.w = (translation or rotation).w / 3
	    opt.offset = 0
	    opt.control_slice = 0.6
		for i, control in pairs(self._axis_controls) do
			if i < 4 then
				opt.group = translation
			else
				opt.group = rotation
			end
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

	function this:ColorBox(name, callback, value, o)
	    local m, opt = self:WorkMenuUtils(o)
	    local item = m:ColorTextBox(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        on_callback = callback,
	        value = value or Color.white
		}, opt))
		if opt.ret_vec then
			function item:Value()
				local v = BeardLib.Items.ColorTextBox.Value(self)
				return Vector3(v.r, v.g, v.b)
			end
		end
		return item
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