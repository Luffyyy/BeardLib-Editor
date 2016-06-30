
EditorRandom = EditorRandom or class(MissionScriptEditor)
EditorRandom.SAVE_UNIT_POSITION = false
EditorRandom.SAVE_UNIT_ROTATION = false
function EditorRandom:create_element()
	EditorRandom.super.create_element(self)
    self._element.class = "ElementRandom"
	self._element.values.amount = 1
	self._element.values.amount_random = 0
	self._element.values.ignore_disabled = true
	self._element.values.counter_id = nil
end
function EditorRandom:show_all_elements_dialog()
    BeardLibEditor.managers.Dialog:show({
        title = "Decide what counter element this element should handle",
        items = {},
        yes = "Apply",
        no = "Cancel",
        w = 600,
        h = 600,
    })
    self:load_all_elements(BeardLibEditor.managers.Dialog._menu)
end
function EditorRandom:select_element(element, menu)
	self._element.values.counter_id = element and element.id or nil
	BeardLibEditor.managers.Dialog:hide()	  
end
function EditorRandom:load_all_elements(menu, item)
    menu:ClearItems("select_buttons")
    local searchbox = menu:GetItem("searchbox") or menu:TextBox({
        name = "searchbox",
        text = "Search what: ",
        callback = callback(self, self, "load_all_elements")         
    })     
    local selected_divider = menu:GetItem("selected_divider") or menu:Divider({
        name = "selected_divider",
        text = "Selected: ",
        size = 30,    
    })        
    local unselected_divider = menu:GetItem("unselected_divider") or menu:Divider({
        name = "unselected_divider",
        text = "Unselected: ",
        size = 30,    
    })     
    menu:Button({
        name = "no_element",
        text = "None",
        label = "select_buttons",
        callback = callback(self, self, "select_element", {})
    })    
 	for _, script in pairs(managers.mission._missions) do
        for _, tbl in pairs(script) do
            if tbl.elements then
                for i, element in pairs(tbl.elements) do            
                    if #menu._items < 120 and (not searchbox.value or searchbox.value == "" or string.match(element.editor_name, searchbox.value) or string.match(element.id, searchbox.value)) or string.match(element.class, searchbox.value) then
                    	if not menu:GetItem(element.id) and (not params.classes or table.contains(params.classes, element.class)) then
	                        menu:Button({
	                            name = element.editor_name, 
	                            text = element.editor_name .. " [" .. element.id .."]",
	                            label = "select_buttons",
	                            color = element.values.enabled and Color.green or Color.red,
	                            callback = callback(self, self, "select_element", element)
	                        })    
	                    end        
                    end
                end
            end
        end
    end 	
end
function EditorRandom:_build_panel(panel, panel_sizer)
	self:_create_panel()
    self._elements_menu:Button({
        name = "choose_counter_element",
        text = "Choose counter element",
        help = "Decide what counter element this element should handle",
        callback = callback(self, self, "show_all_elements_dialog")
    })    	
	self:_build_value_number("amount", {floats = 0, min = 1}, "Specifies the amount of elements to be executed")
	self:_build_value_number("amount_random", {floats = 0, min = 0}, "Add a random amount to amount")
	self:_build_value_checkbox("ignore_disabled")
	self:_add_help_text("Use 'Amount' only to specify an exact amount of elements to execute. Use 'Amount Random' to add a random amount to 'Amount' ('Amount' + random('Amount Random').")
end
