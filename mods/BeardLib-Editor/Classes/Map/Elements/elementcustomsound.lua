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
	self:StringCtrl("sound_path", {help = "Path to the custom sound that will play."})
	self:ComboCtrl("volume_choice", {"music", "sfx"}, {help = "Which volume to base yourself on?"})
	self:Text("Primary Channel")
	self:BooleanCtrl("loop", {help = "Does the sound should loop or play once?"})
	self:BooleanCtrl("force_stop", {help = "Stop all primary channel musics (custom and official)."})
	self:Text("Secondary Channel")
	self:BooleanCtrl("use_as_secondary", {help = "Use as secondary channel. This channel should be only used with voice over lines."})
	self:BooleanCtrl("use_subtitles", {help = "If enabled, then you're able to setup subtitles below."})
	self:StringCtrl("subtitle_id", {help = "Localized string id for the subtitle"})
	self:NumberCtrl("subtitle_duration", {min = 0, floats = 0, help = "Duration on-screen"})
	self:Text("Third Channel")
	self:BooleanCtrl("use_as_third", {help = "Use as third channel. This is used for background noises such as wind, rain..."})
	self:BooleanCtrl("third_loop", {help = "Does the sound should loop or play once?"})
end
