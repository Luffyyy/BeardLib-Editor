EditorXAudio = EditorXAudio or class(MissionScriptEditor)
function EditorXAudio:create_element()
	self.super.create_element(self)
	self._element.class = "ElementXAudio"

	self._element.values.sound_type = "sfx"
	self._element.values.override_volume = -1
end

function EditorXAudio:_build_panel()
	self:_create_panel()
	self:StringCtrl("file_name", {help = "Bring with .ogg extension"})
	self:StringCtrl("custom_dir", {help = "Directories between assets and the sound file.\nEg: assets/ <your directories here> /file.ogg\nNo additional slashes required."})
	self:ComboCtrl("sound_type", {"sfx", "music"}, {help = "Volume Slider Based on"})
	self:BooleanCtrl("is_relative", {help = "Is it relative ?"})
	self:BooleanCtrl("is_loop", {help = "Is the sound looping ?"})
	self:BooleanCtrl("is_3d", {help = "Use the current element's position as sound point"})
	self:NumberCtrl("override_volume", {min = -1, floats = 2, max = 1, help = "Overrides the volume. -1 to disable it. Max 1, min 0."})
end

EditorXAudioOperator = EditorXAudioOperator or class(MissionScriptEditor)
function EditorXAudioOperator:create_element()
	EditorXAudioOperator.super.create_element(self)
	self._element.class = "ElementXAudioOperator"
	self._element.values.operation = "none"
	self._element.values.volume_override = 1
	self._element.values.elements = {}
end

function EditorXAudioOperator:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementXAudio"})
	self:ComboCtrl("operation", {"none","stop","set_looping","set_relative","set_volume"}, {help = "Select an operation for the selected elements"})
	self:BooleanCtrl("state", {help = "Used for set_looping, set_relative operations."})
	self:NumberCtrl("volume_override", {floats = 2, min = 0, max = 1, help = "Used to override the volume of the selected XAudio elements"})
	self:Text("This element can modify the XAudio elements.")
end
