EditorCustomSound = EditorCustomSound or class(MissionScriptEditor)
function EditorCustomSound:create_element()
	self.super.create_element(self)
	self._element.class = "ElementCustomSound"
	self._element.values.sound_path = ""
	self._element.values.volume_choice = "music"
end

function EditorCustomSound:_build_panel()
	self:_create_panel()
	self:Text("Basic Parameters")
	self:StringCtrl("sound_path", {help = "Path to the custom sound that will play. This should match with the AddFiles 'path' key in your main.xml file. Example: sfx/intro1"})
	self:ComboCtrl("volume_choice", {"music", "sfx"}, {help = "Which volume to base yourself on?"})
	self:NumberCtrl("volume_override", {min = 0, floats = 2, help = "Optional: Override the volume (as modifier) by setting this value. Example: 2.0 would amplify the sound by 200% of it's original"})
	self:BooleanCtrl("instigator_only", {help = "Play the sound only for the player that executes the element"})
	self:Text("Primary Channel")
	self:BooleanCtrl("loop", {help = "Should the sound loop or play once?"})
	self:BooleanCtrl("force_stop", {help = "Stops all primary channel music (custom and official)."})
	self:Text("Secondary Channel")
	self:BooleanCtrl("use_as_secondary", {help = "Use as secondary channel. This channel should be only used with voice over lines."})
	self:BooleanCtrl("use_subtitles", {help = "If enabled, then you're able to setup subtitles below."})
	self:StringCtrl("subtitle_id", {help = "Localized string id for the subtitle"})
	self:NumberCtrl("subtitle_duration", {min = 0, floats = 0, help = "Duration on-screen"})
	self:BooleanCtrl("override_others", {help = "Force termination of the entire secondary channel, so that only this sound plays on this layer. Useful for voicelines which can quickly overlap."})
	self:Text("Third Channel")
	self:BooleanCtrl("use_as_third", {help = "Use as third channel. This is used for background noises such as wind, rain..."})
	self:BooleanCtrl("third_loop", {help = "Should the sound loop or play once?"})
end
