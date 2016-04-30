local ui = {}

local toggleDebugDraw = iup.toggle { title="Debug Drawing" }
ui.toggleDebugDraw = toggleDebugDraw

local box = iup.vbox{
    toggleDebugDraw
}

local dialog = iup.dialog
{
    box;
    title="Ngin Console",
    size="200x200",
    margin="5x5",
    gap="5"
}

dialog:show()

return ui
