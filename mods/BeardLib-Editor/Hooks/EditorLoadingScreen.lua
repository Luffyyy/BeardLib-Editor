local es = class(LevelLoadingScreenGuiScript)
LevelLoadingScreenGuiScript = es
function es:init(gui, res, p, layer)
	self._gui = gui
	if arg.load_level_data.level_data.editor_load then
		self._is_editor = true
	else
		es.super.init(self, gui, res, p, layer)
	end
end

function es:update(...)
	if self._is_editor then
		self:do_editor_stuff() 
	else
		es.super.update(self, ...)
	end
end

function es:do_editor_stuff()
	if alive(self._gui) and self._gui:workspaces()[1] then
		local load = self._gui:workspaces()[1]:panel():child("Load")
		if alive(load) then
			for _, child in pairs(load:children()) do
				local mchild = getmetatable(child)
				if mchild == Text then
			        child:animate(function(o)
			            if alive(o) then
			                coroutine.yield()
			                o:set_text(tostring(o:name()))
			            end
			        end)
				end
			end
		end
	end
end