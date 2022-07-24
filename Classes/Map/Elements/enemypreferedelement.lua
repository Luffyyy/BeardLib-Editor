EditorEnemyPreferedAdd = EditorEnemyPreferedAdd or class(MissionScriptEditor)
EditorEnemyPreferedAdd.SAVE_UNIT_POSITION = false
EditorEnemyPreferedAdd.SAVE_UNIT_ROTATION = false
EditorEnemyPreferedAdd.LINK_ELEMENTS = {
	"spawn_points",
	"spawn_groups"
}
function EditorEnemyPreferedAdd:create_element()
	self.super.create_element(self)
	self._element.class = "ElementEnemyPreferedAdd"
end

function EditorEnemyPreferedAdd:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("spawn_groups", nil, {"ElementSpawnEnemyGroup"}, ClassClbk(self, "nil_if_empty"))
	self:BuildElementsManage("spawn_points", nil, {"ElementSpawnEnemyDummy"}, ClassClbk(self, "nil_if_empty"))
end

function EditorEnemyPreferedAdd:update_selected(t, dt)
	if self._element.values.spawn_groups then
		for _, id in ipairs(self._element.values.spawn_groups) do
			local unit = self:GetPart('mission'):get_element_unit(id)

			if alive(unit) then
				local r, g, b = unit:mission_element():get_link_color()

				self:draw_link({
					from_unit = unit,
					to_unit = self._unit,
					r = r,
					g = g,
					b = b
				})
			end
		end
	end
	
	if self._element.values.spawn_points then
		for _, id in ipairs(self._element.values.spawn_points) do
			local unit = self:GetPart('mission'):get_element_unit(id)

			if alive(unit) then
				local r, g, b = unit:mission_element():get_link_color()

				self:draw_link({
					from_unit = unit,
					to_unit = self._unit,
					r = r,
					g = g,
					b = b
				})
			end
		end
	end
end

function EditorEnemyPreferedAdd:nil_if_empty(value_name)
	if self._element.values[value_name] and #self._element.values[value_name] == 0 then
		self._element.values[value_name] = nil
	end
end

function EditorEnemyPreferedAdd:link_managed(unit)
	if alive(unit) and unit:mission_element() then
		local element = unit:mission_element().element
		if element.class == "ElementSpawnEnemyGroup" then
			self:AddOrRemoveManaged("spawn_groups", {element = element}, nil, ClassClbk(self, "nil_if_empty"))
		elseif element.class == "ElementSpawnEnemyDummy" then
			self:AddOrRemoveManaged("spawn_points", {element = element}, nil, ClassClbk(self, "nil_if_empty"))
		end
	end
end

EditorEnemyPreferedRemove = EditorEnemyPreferedRemove or class(MissionScriptEditor)
EditorEnemyPreferedRemove.ELEMENT_FILTER = {"ElementEnemyPreferedAdd"}
function EditorEnemyPreferedRemove:create_element()
	self.super.create_element(self)
	self._element.values.elements = {}
	self._element.class = "ElementEnemyPreferedRemove"
end

function EditorEnemyPreferedRemove:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, self.ELEMENT_FILTER)
end