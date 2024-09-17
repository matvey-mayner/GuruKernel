local computer = computer
local component = component

local bootloader = {}

bootloader.eeprom = component.list("eeprom")()
bootloader.bootAddress = computer.getBootAddress()
bootloader.fs = component.proxy(bootloader.bootAddress)

function bootloader.loadFile(path)
    local file, err = bootloader.fs.open(path, "r")
    if not file then
        error("Failed to open file: " .. err)
    end
    
    local buffer = ""
    repeat
        local chunk = bootloader.fs.read(file, math.huge)
        buffer = buffer .. (chunk or "")
    until not chunk
    bootloader.fs.close(file)
    
    return buffer
end

function bootloader.runFile(path)
    local code, err = bootloader.loadFile(path)
    if not code then
        error("Failed to load file: " .. err)
    end
    
    local program, loadErr = load(code, "="..path, "t", _G)
    if not program then
        error("Failed to load program: " .. loadErr)
    end

    return program()
end

function bootloader.boot()
    local shellPath = "/GuruKernel/System/main.lua"
    
    if bootloader.fs.exists(shellPath) then
        bootloader.runFile(shellPath)
    else
        error("No bootable systems found at " .. shellPath)
    end
end

bootloader.boot()
