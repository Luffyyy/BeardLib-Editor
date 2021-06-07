import "base/api/TweakControl" for TweakControl
import "base/native" for IO
TweakControl.set_control_key("editor-fix-physics", IO.info("mods/saves/BLEDisablePhysicsFix") == "none")
