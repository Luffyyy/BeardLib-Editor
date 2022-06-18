ToolEditor = ToolEditor or class(EditorPart)
function ToolEditor:init(parent, name, opt)
    self:init_basic(parent, name)
    self._holder = parent._holder:holder(name.."Tab", table.merge({visible = false}, opt))
    self._parent = parent
end

function ToolEditor:set_visible(visible)
    self._holder:SetVisible(visible)
end

function ToolEditor:active()
	return self._holder:Visible()
end
