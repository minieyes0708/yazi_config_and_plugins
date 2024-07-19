local state = ya.sync(function() return cx.active.current.cwd end)

local function fail(s, ...) ya.notify { title = "command_palette", content = string.format(s, ...), timeout = 5, level = "error" } end

local function entry()
    local _permit = ya.hide()
    local cwd = tostring(state())
    local command_palette_filepath = "%DotConfig%/yazi_command_palette.txt"

    local child, err =
        Command("cmd"):args({'/c', 'cat', command_palette_filepath, '|', 'fzf'}):cwd(cwd):stdin(Command.INHERIT):stdout(Command.PIPED):stderr(Command.INHERIT):spawn()

    if not child then
        return fail("Spawn `command_palette` failed with error code %s. Do you have it installed?", err)
    end

    local output, err = child:wait_with_output()
    if not output then
        return fail("Cannot read `command_palette` output, error code %s", err)
    elseif not output.status.success and output.status.code ~= 130 then
        return fail("`command_palette` exited with error code %s", output.status.code)
    end

    local target = output.stdout:gsub("\n$", "")
    if target ~= "" then
        ya.manager_emit('shell', { target })
    end
end

return { entry = entry }