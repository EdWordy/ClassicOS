require "window"
require "code_editor"
require "file_system"
require "terminal"
require "boot_sequence"
local Desktop = require "desktop"

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
    keyPressSound = love.audio.newSource("sounds/keypress.wav", "static")
    bootSound = love.audio.newSource("sounds/boot.wav", "static")
    errorSound = love.audio.newSource("sounds/error.wav", "static")
    backgroundHum = love.audio.newSource("sounds/hum.wav", "stream")
    backgroundHum:setLooping(true)
    love.audio.play(backgroundHum)

    -- Create the root directory if it doesn't exist
    love.filesystem.createDirectory(rootDirectory)
    
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
        for i, window in ipairs(windows) do
            window:draw()
        end
    end
    
    -- Draw clock if enabled
    if clockEnabled then
        love.graphics.setColor(1, 1, 1)  -- White color for clock
        love.graphics.print(os.date("%H:%M:%S"), love.graphics.getWidth() - 100, 10)
    end
end

function love.mousepressed(x, y, button)
    if isBooting() then return end

    if Desktop.mousepressed(x, y, button) then
        return  -- If the desktop handled the click, we're done
    end

    if button == 1 then  -- Left mouse button
        for i = #windows, 1, -1 do
            local window = windows[i]
            if window:checkCloseButtonHover(x, y) then
                table.remove(windows, i)
                if #windows > 0 then
                    activeWindow = windows[#windows]
                else
                    activeWindow = nil
                end
                return  -- Exit the function after closing a window
            elseif window:checkTitleBarHover(x, y) then
                window.isDragging = true
                window.dragOffsetX = x - window.x
                window.dragOffsetY = y - window.y
                
                -- Move this window to the end of the list (top of the draw order)
                table.remove(windows, i)
                table.insert(windows, window)
                
                activeWindow = window
                break
            elseif window:checkHover(x, y) then
                activeWindow = window
                break
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
    font = love.graphics.newFont("fonts/courier.ttf", fontSize)
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

function launchEditor(filename)
    local editorWindow = Window.new("Editor - " .. filename, 150, 150, 500, 400, "editor", font)
    table.insert(windows, editorWindow)
    activeWindow = editorWindow
    activeWindow.editor:load(filename)
end

-- Make these functions global so they can be called from desktop.lua
_G.launchTerminal = launchTerminal
_G.launchEditor = launchEditor