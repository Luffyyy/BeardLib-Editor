MenuUtils = MenuUtils or class()
function MenuUtils:init(this, menu_key)
	menu_key = menu_key or "_menu"
	function this:Divider(name, opt)
	    opt = opt or {}
	    return self[menu_key]:Divider(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        color = self[menu_key].marker_highlight_color,
	    }, opt))
	end

	function this:Group(name, opt)
	    opt = opt or {}
	    return self[menu_key]:ItemsGroup(table.merge({
	        name = name,
	        text = string.pretty2(name),
	    }, opt))
	end

	function this:Button(name, callback, opt)
	    opt = opt or {}
	    return self[menu_key]:Button(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        callback = callback,
	    }, opt))
	end

	function this:SmallButton(name, callback, parent, opt)    
	    opt = opt or {}
	    return self[menu_key]:Button(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        callback = callback,
	        size_by_text = true,
	        position = "CenterRight",
	        align = "center",
	        override_parent = parent,
	    }, opt))
	end

	function this:ComboBox(name, callback, items, value, opt)
	    opt = opt or {}
	    return self[menu_key]:ComboBox(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        value = value,
	        items = items,
	        callback = callback,
	    }, opt))
	end

	function this:TextBox(name, callback, value, opt)
	    opt = opt or {}
	    return self[menu_key]:TextBox(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        callback = callback,
	        value = value
	    }, opt))
	end

	function this:Slider(name, callback, value, opt)
	    opt = opt or {}
	    return self[menu_key]:Slider(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        value = value,
	        callback = callback,
	    }, opt))
	end

	function this:NumberBox(name, callback, value, opt)
	    opt = opt or {}
	    return self[menu_key]:NumberBox(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        value = value,
	        callback = callback,
	    }, opt))
	end

	function this:Toggle(name, callback, value, opt)    
	    opt = opt or {}
	    return self[menu_key]:Toggle(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        value = value,
	        callback = callback,
	    }, opt))
	end

	function this:SetAxisControls(pos, rot)    
	    for i, control in pairs(self._axis_controls) do
	        if alive(self[control]) then
	            self[control]:SetValue(i < 4 and pos[control] or rot[control](rot))
	        end
	    end
	end

	function this:SetShapeControls(shape)    
	    for _, control in pairs(self._shape_controls) do
	        if alive(self[control]) then
	            self[control]:SetValue(shape and shape[control] or 0)
	        end
	    end
	end

	function this:SetAxisControlsEnabled(enabled)    
	    for _, control in pairs(self._axis_controls) do
	        if alive(self[control]) then
	            self[control]:SetEnabled(enabled)
	        end
	    end
	end

	function this:AxisControlsPosition()    
	    return Vector3(self.x.value, self.x.value, self.x.value)
	end

	function this:AxisControlsRotation()    
	    return Rotation(self.yaw.value, self.pitch.value, self.roll.value)
	end

	function this:SetShapeControlsEnabled(enabled)    
	    for _, control in pairs(self._shape_controls) do
	        if alive(self[control]) then
	            self[control]:SetEnabled(enabled)
	        end
	    end
	end

	function this:AxisControls(callback, opt)    
	    opt = opt or {}
	    for _, control in pairs(self._axis_controls) do
	        self[control] = self:NumberBox(control, callback, 0, table.merge({floats = 0}, opt))
	    end
	end

	function this:ShapeControls(callback, opt)    
	    opt = opt or {}
	    for _, control in pairs(self._shape_controls) do
	        self[control] = self:NumberBox(control, callback, 0, table.merge({floats = 0}, opt))
	    end
	end	

	function this:ClearItems(lbl)
		self[menu_key]:ClearItems(lbl)
	end
end