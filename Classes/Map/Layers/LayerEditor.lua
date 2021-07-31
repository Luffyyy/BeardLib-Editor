LayerEditor = LayerEditor or class(EditorPart)
LayerEditor._created_units = {}
function LayerEditor:init(parent, name, opt)
    self:init_basic(parent, name)
    self._holder = parent._holder:holder(name.."Tab", table.merge({visible = false}, opt))
    self._parent = parent
end

function LayerEditor:set_visible(visible)
    self._holder:SetVisible(visible)
end

function LayerEditor:loaded_continents()
    self:destroy_units_temp()
end

function LayerEditor:destroy_units_temp()
    for _, unit in pairs(clone(self._created_units)) do
        local ud = unit:unit_data()
        local obj = ud.environment_area or ud.emitter or ud.occ_shape
        if obj then
            obj._unit = nil --Doesn't fully fix issue #300 but fixes when doing the same in SoundEnvironmentManager.lua
        end
        unit:set_slot(0)
        World:delete_unit(unit)
        table.delete(self._created_units, unit)
    end
end

function LayerEditor:destroy()
    self:destroy_units_temp()
end


function LayerEditor:active()
	return self._holder:Visible()
end