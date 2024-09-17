local component = component
local computer = computer
local eeprom = component.eeprom

local bootAddress = computer.getBootAddress()
local fs = component.proxy(bootAddress)

local bootFilePath = "GuruKernel/boot.lua"

local function loadBootFile(path)
    local file, err = fs.open(path, "r")
    if not file then
        error("Failed to open boot file: " .. err)
    end
    
    local data = ""
    repeat
        local chunk = fs.read(file, math.huge)
        data = data .. (chunk or "")
    until not chunk
    
    fs.close(file)
    return data
end

local function runBoot()
    local code, err = loadBootFile(bootFilePath)
    if not code then
        error("Failed to load boot file: " .. err)
    end
    
    local bootProgram, loadErr = load(code, "="..bootFilePath, "t", _G)
    if not bootProgram then
        error("Failed to load boot program: " .. loadErr)
    end

    bootProgram()
end

runBoot()
