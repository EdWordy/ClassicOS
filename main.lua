local FileSystem = require "lua/file_system"
require "lua/window"
require "lua/code_editor"
require "lua/terminal"
require "lua/boot_sequence"
local Desktop = require "lua/desktop"
local FileBrowser = require "lua/file_browser"

-- Global variables
local windows = {}
local activeWindow = nil
local font
local fontSize = 14
local clockEnabled = false
local clockTimer = 0

-- Sound effect variables
local keyPressSound
local bootSound
local errorSound
local backgroundHum

function love.load()
    love.window.setMode(800, 600, {resizable=true, minwidth=400, minheight=300})
    love.graphics.setBackgroundColor(0, 0, 0)  -- Set to black for boot sequence
    
    updateFont()
    
    -- Load sound effects
    keyPressSound = love.audio.newSource("assets/sounds/keypress.wav", "static")
    bootSound = love.audio.newSource("assets/sounds/boot.wav", "static")
    errorSound = love.audio.newSource("assets/sounds/error.wav", "static")
    backgroundHum = love.audio.newSource("assets/sounds/hum.wav", "stream")
    backgroundHum:setLooping(true)
    love.audio.play(backgroundHum)

    -- Create the root directory if it doesn't exist
    if not love.filesystem.getInfo(FileSystem.rootDirectory) then
        local success, message = love.filesystem.createDirectory(FileSystem.rootDirectory)
        if not success then
            error("Failed to create root directory: " .. message)
        end
    end
    
    -- Play boot sound
    love.audio.play(bootSound)

    startBootSequence()
    Desktop.init()
end

function love.update(dt)
    if isBooting() then
        if updateBootSequence(dt) then
            love.graphics.setBackgroundColor(0.2, 0.4, 0.6)  -- Set a blue background color for the desktop
        end
    else
        for _, window in ipairs(windows) do
            window:update(dt)
        end
        
        -- Update clock if enabled
        if clockEnabled then
            clockTimer = clockTimer + dt
            if clockTimer >= 1 then
                clockTimer = 0
                updateClock()
            end
        end
    end
end

function love.draw()
    if isBooting() then
        drawBootSequence(font)
    else
        Desktop.draw()
        -- Draw windows
        for i = 1, #windows do
            windows[i]:draw()
        end
        Desktop.drawTaskbarItems(windows)
    end
    
    -- Draw clock if enabled
    if clockEnabled then
        love.graphics.setColor(1, 1, 1)  -- White color for clock
        love.graphics.print(os.date("%H:%M:%S"), love.graphics.getWidth() - 100, 10)
    end
end

function love.mousepressed(x, y, button)
    if isBooting() then return end

    local desktopAction = Desktop.mousepressed(x, y, button)
    if type(desktopAction) == "number" then
        -- Taskbar item clicked
        if windows[desktopAction] then
            windows[desktopAction].isMinimized = false
            activeWindow = windows[desktopAction]
            -- Move window to top
            table.insert(windows, table.remove(windows, desktopAction))
        end
        return
    elseif desktopAction then
        return  -- If the desktop handled the click, we're done
    end

    if button == 1 then  -- Left mouse button
        for i = #windows, 1, -1 do
            local window = windows[i]
            if not window.isMinimized then
                if window:checkCloseButtonHover(x, y) then
                    table.remove(windows, i)
                    if #windows > 0 then
                        activeWindow = windows[#windows]
                    else
                        activeWindow = nil
                    end
                    return
                elseif window:checkMinimizeButtonHover(x, y) then
                    window.isMinimized = true
                    if activeWindow == window then
                        activeWindow = #windows > 1 and windows[#windows - 1] or nil
                    end
                    return
                elseif window:checkTitleBarHover(x, y) then
                    window.isDragging = true
                    window.dragOffsetX = x - window.x
                    window.dragOffsetY = y - window.y
                    
                    -- Move this window to the end of the list (top of the draw order)
                    table.insert(windows, table.remove(windows, i))
                    
                    activeWindow = window
                    break
                elseif window:checkHover(x, y) then
                    activeWindow = window
                    -- Move this window to the end of the list (top of the draw order)
                    table.insert(windows, table.remove(windows, i))
                    window:mousepressed(x, y, button)
                    break
                end
            end
        end
    end
end

function love.mousereleased(x, y, button)
    if isBooting() then return end

    if button == 1 then  -- Left mouse button
        for _, window in ipairs(windows) do
            window.isDragging = false
        end
    end
end

function love.mousemoved(x, y, dx, dy)
    if isBooting() then return end

    for _, window in ipairs(windows) do
        if window.isDragging then
            window.x = x - window.dragOffsetX
            window.y = y - window.dragOffsetY
        end
    end
end

function love.keypressed(key)
    if isBooting() then return end  -- Ignore key presses during boot sequence
    
    love.audio.play(keyPressSound)  -- Play key press sound
    
    if activeWindow then
        activeWindow:keypressed(key)
    end
end

function love.textinput(t)
    if isBooting() then return end  -- Ignore text input during boot sequence
    
    love.audio.play(keyPressSound)  -- Play key press sound
    
    if activeWindow then
        activeWindow:textinput(t)
    end
end

function love.wheelmoved(x, y)
    if isBooting() then return end  -- Ignore scrolling during boot sequence
    
    if activeWindow then
        activeWindow:wheelmoved(x, y)
    end
end

function updateFont()
    font = love.graphics.newFont("assets/fonts/courier.ttf", fontSize)
    love.graphics.setFont(font)
end

function launchTerminal()
    local terminalWindow = Window.new("Terminal", 100, 100, 500, 400, "terminal", font)
    table.insert(windows, terminalWindow)
    activeWindow = terminalWindow
end

function updateClock()
    -- Update the last line of the screen with the current time
    if activeWindow and activeWindow.windowType == "terminal" then
        activeWindow:addContent(os.date("%H:%M:%S"), 2)
    end
end

function launchEditor(filename, content)
    local editorWindow = Window.new("Editor - " .. filename, 150, 150, 500, 400, "editor", font)
    table.insert(windows, editorWindow)
    activeWindow = editorWindow
    
    if editorWindow.editor then
        editorWindow.editor:loadContent(filename, content or "")
    else
        print("Error: Editor not initialized properly")
    end
end

function launchFileBrowser()
    local fileBrowserWindow = Window.new("File Browser", 200, 200, 400, 300, "file_browser", font)
    table.insert(windows, fileBrowserWindow)
    activeWindow = fileBrowserWindow
end

-- Make these functions global so they can be called from desktop.lua
_G.launchTerminal = launchTerminal
_G.launchEditor = launchEditor
_G.launchFileBrowser = launchFileBrowser