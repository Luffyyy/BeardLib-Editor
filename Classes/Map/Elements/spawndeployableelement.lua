EditorSpawnDeployable = EditorSpawnDeployable or class(MissionScriptEditor)
function EditorSpawnDeployable:create_element()
	self.super.create_element(self)
	self._element.class = "ElementSpawnDeployable"
	self._element.values.deployable_id = "none"
end
function EditorSpawnDeployable:_build_panel()
	self:_create_panel()
	self:ComboCtrl("deployable_id", {
		"none",
		"doctor_bag",
		"ammo_bag",
		"grenade_crate",
		"bodybags_bag"
	}, {help = "Select a deployable_id to be spawned."})
end

function EditorSpawnDeployable:test_element() 
	self:stop_test_element()

	if self._element.values.deployable_id ~= "none" then
		if self._element.values.deployable_id == "doctor_bag" then
			self._asset = DoctorBagBase.spawn(self._element.values.position, self._element.values.rotation, 0)
		elseif self._element.values.deployable_id == "ammo_bag" then
			self._asset = AmmoBagBase.spawn(self._element.values.position, self._element.values.rotation, 0)
		elseif self._element.values.deployable_id == "grenade_crate" then
			self._asset = GrenadeCrateBase.spawn(self._element.values.position, self._element.values.rotation, 0)
		elseif self._element.values.deployable_id == "bodybags_bag" then
			self._asset =BodyBagsBagBase.spawn(self._element.values.position, self._element.values.rotation, 0)
		end
	end
end

function EditorSpawnDeployable:stop_test_element()
	if self._asset and alive(self._asset) then self._asset:set_slot(0) end
	self._asset = nil
end

function EditorSpawnDeployable:destroy()
	self:stop_test_element()
end

