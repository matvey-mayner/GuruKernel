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

function bootloader.initLibs(libPath)
    if not bootloader.fs.exists(libPath) or not bootloader.fs.isDirectory(libPath) then
        error("Libraries directory not found: " .. libPath)
    end

    for _, file in ipairs(bootloader.fs.list(libPath)) do
        local fullPath = libPath .. "/" .. file
        if not bootloader.fs.isDirectory(fullPath) then
            print("Loading library: " .. fullPath)
            bootloader.runFile(fullPath)
        end
    end
end

function bootloader.boot()
    local libPath = "/GuruKernel/lib"
    local mainScriptPath = "SYS/main.lua"

    bootloader.initLibs(libPath) -- lib init

    if bootloader.fs.exists(mainScriptPath) then
        bootloader.runFile(mainScriptPath)
    else
        error("Main script not found: " .. mainScriptPath)
    end
end

bootloader.boot()
