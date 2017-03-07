MenuUtils = MenuUtils or class()
function MenuUtils:init(this, menu)
	menu = menu or this._menu
	function this:Divider(name, opt)
	    opt = opt or {}
	    return menu:Divider(table.merge({
	        name = name,
	        text = name,
	        color = menu.marker_highlight_color,
	    }, opt))
	end

	function this:Group(name, opt)
	    opt = opt or {}
	    return menu:ItemsGroup(table.merge({
	        name = name,
	        text = string.pretty2(name),
	    }, opt))
	end

	function this:CloseButton()
		self:Button("Close", callback(menu.menu, menu.menu, "disable"))
	end

	function this:Button(name, callback, opt)
	    opt = opt or {}
	    return menu:Button(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        callback = callback,
	    }, opt))
	end

	function this:SmallButton(name, callback, parent, opt)    
	    opt = opt or {}
	    return menu:Button(table.merge({
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
	    return menu:ComboBox(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        value = value,
	        items = items,
	        callback = callback,
	    }, opt))
	end

	function this:TextBox(name, callback, value, opt)
	    opt = opt or {}
	    return menu:TextBox(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        callback = callback,
	        value = value
	    }, opt))
	end

	function this:Slider(name, callback, value, opt)
	    opt = opt or {}
	    return menu:Slider(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        value = value,
	        callback = callback,
	    }, opt))
	end

	function this:NumberBox(name, callback, value, opt)
	    opt = opt or {}
	    return menu:NumberBox(table.merge({
	        name = name,
	        text = string.pretty2(name),
	        value = value,
	        callback = callback,
	    }, opt))
	end

	function this:Toggle(name, callback, value, opt)    
	    opt = opt or {}
	    return menu:Toggle(table.merge({
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
	    return Vector3(self.x.value, self.y.value, self.z.value)
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
		menu:ClearItems(lbl)
	end	

	function this:GetItem(name)
		return menu:GetItem(name)
	end
end