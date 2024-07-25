local selected = ya.sync(function()
    local result = {}
    for _, f in pairs(cx.active.selected) do
        table.insert(result, f:name())
    end
    return result
end)
local getcwd = ya.sync(function() return tostring(cx.active.current.cwd) end)
local hovered = ya.sync(function() return cx.active.current.hovered.name end)

local function fail(s, ...) ya.notify { title = "command_palette", content = string.format(s, ...), timeout = 5, level = "error" } end

local select_command = function()
    local command_palette_filepath = "%DotConfig%/yazi_command_palette.txt"

    local child, err =
        Command("cmd"):args({'/c', 'cat', command_palette_filepath, '|', 'fzf'}):cwd(getcwd()):stdin(Command.INHERIT):stdout(Command.PIPED):stderr(Command.INHERIT):spawn()

    if not child then
        return fail("Spawn `command_palette` failed with error code %s. Do you have it installed?", err)
    end

    local output, err = child:wait_with_output()
    if not output then
        return fail("Cannot read `command_palette` output, error code %s", err)
    elseif not output.status.success and output.status.code ~= 130 then
        return fail("`command_palette` exited with error code %s", output.status.code)
    end

    return output.stdout:gsub("\n$", "")
end

local function entry(self, args)
    local _permit = ya.hide()
    local target = table.concat(args, ' ')

    if target == nil then
        target = select_command()
    end
    if target ~= "" then
        local selected = selected()
        target = target:gsub('%%0', hovered())
        for i = 1,9 do
            if selected[i] == nil then break end
            target = target:gsub('%%' .. tostring(i), selected[i])
        end
        -- ya.manager_emit('shell', { target })
        Command("cmd"):args({'/c', target }):cwd(getcwd()):spawn():wait_with_output()
    end
end

return { entry = entry }