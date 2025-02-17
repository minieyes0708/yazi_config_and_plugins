local hovered = ya.sync(function()
    if cx.active.current.hovered == nil then return '' end
    return cx.active.current.hovered.name
end)
local selected = ya.sync(function()
    local result = {}
    if cx.active.selected == nil then return result end

    for _, f in pairs(cx.active.selected) do
        table.insert(result, f:name())
    end
    return result
end)
local getcwd = ya.sync(function() return tostring(cx.active.current.cwd) end)

local function fail(s, ...) ya.notify { title = "command_palette", content = string.format(s, ...), timeout = 5, level = "error" } end

local select_command = function()
    local command_palette_filepath = os.getenv('DotConfig') .. "\\yazi_command_palette.txt"

    local child, err =
        Command("cmd"):args({'/c', 'type', command_palette_filepath, '|', 'fzf'}):cwd(getcwd()):stdin(Command.INHERIT):stdout(Command.PIPED):stderr(Command.INHERIT):spawn()

    if not child then
        return fail("Spawn `command_palette` failed with error code %s. Do you have it installed?", err)
    end

    local output, err = child:wait_with_output()
    if not output then
        return fail("Cannot read `command_palette` output, error code %s", err)
    elseif not output.status.success and output.status.code ~= 130 then
        return fail("`command_palette` exited with error code %s", output.status.code)
    end

    local result = {}
    local command = output.stdout:gsub("\n$", "")
    for token in string.gmatch(command, "[^%s]+") do
        table.insert(result, token)
    end
    return result
end

local replace_args = function(arg)
    local selected = selected()
    arg = arg:gsub('%%0', hovered())
    for i = 1,9 do
        if selected[i] == nil then break end
        arg = arg:gsub('%%' .. tostring(i), selected[i])
    end
    return arg
end

local function entry(self, job)
    local _permit = ya.hide()

    if #job.args == 0 then
        job.args = select_command()
    end
    local arguments = {'/c'}
    if job.args[1] ~= "" then
        for _, target in ipairs(job.args) do
            table.insert(arguments, replace_args(target))
        end
        -- ya.manager_emit('shell', { tostring(table.concat(arguments, ' ')) })
        Command("cmd"):args(arguments):cwd(getcwd()):spawn():wait_with_output()
    end
end

return { entry = entry }