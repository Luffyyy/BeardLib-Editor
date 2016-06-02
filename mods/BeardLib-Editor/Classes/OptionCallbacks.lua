BeardLibEditor.callbacks = {}

function BeardLibEditor.callbacks:UpdateSliderSpeed(key, value)
    if BeardLibEditor.managers.MapEditor then
        BeardLibEditor.managers.MapEditor:toggle_slider_speed_main()
    end
end
