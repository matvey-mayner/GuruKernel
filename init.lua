local bootfs = component.proxy(computer.getBootAddress())
local tmpfs = component.proxy(computer.tmpAddress())

local function readFile(fs, path)
    local file, err = fs.open(path, "rb")
    if not file then return nil, err end

    local buffer = ""
    repeat
        local data = fs.read(file, math.huge)
        buffer = buffer .. (data or "")
    until not data
    fs.close(file)

    return buffer
end

local function loadfile(fs, path, mode, env)
    local data, err = readFile(fs, path)
    if not data then return nil, err end
    return load(data, "=" .. path, mode or "bt", env or _G)
end

local function unserialize(str)
    local code = load("return " .. str, "=unserialize", "t", {math={huge=math.huge}})
    if code then
        local result = {pcall(code)}
        if result[1] and type(result[2]) == "table" then
            return result[2]
        end
    end
end

local bootloaderSettingsPath = "/boot"
local bootmanagerfile = "/bootmanager/main.lua"
if bootfs.exists(bootmanagerfile) and not tmpfs.exists(bootloaderSettingsPath) then
    assert(loadfile(bootfs, bootmanagerfile))()
end


local bootloaderSettingsPath_bootfile = bootloaderSettingsPath .. "/bootfile"
local bootfile
if tmpfs.exists(bootloaderSettingsPath_bootfile) then
    bootfile = assert(readFile(tmpfs, bootloaderSettingsPath_bootfile))
else
    bootfile = "/GuruKernel/boot.lua"
end

local bootloaderSettingsPath_bootaddr = bootloaderSettingsPath .. "/bootaddr"
local bootproxy
if tmpfs.exists(bootloaderSettingsPath_bootaddr) then
    local bootaddr = assert(readFile(tmpfs, bootloaderSettingsPath_bootaddr))
    computer.getBootAddress = function()
        return bootaddr
    end
    bootproxy = assert(component.proxy(bootaddr))
else
    bootproxy = bootfs
end

tmpfs.remove(bootloaderSettingsPath)
