local Terminal = require "lua/terminal"
local CodeEditor = require "lua/code_editor"
local FileBrowser = require "lua/file_browser"

Window = {}
Window.__index = Window

function Window.new(title, x, y, width, height, windowType, font)
    local self = setmetatable({}, Window)
    self.title = title
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.content = {}
    self.isDragging = false
    self.dragOffsetX = 0
    self.dragOffsetY = 0
    self.isActive = false
    self.scrollOffset = 0
    self.windowType = windowType or "terminal"
    self.font = font
    self.closeButtonSize = 16
    self.minimizeButtonSize = 16
    self.isMinimized = false

    if self.windowType == "editor" then
        self.editor = CodeEditor.new(font)
    elseif self.windowType == "terminal" then
        self.terminal = Terminal.new(font)
    elseif self.windowType == "file_browser" then
        self.fileBrowser = FileBrowser.new(font)
    end

    return self
end

function Window:draw()
    if self.isMinimized then return end

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("fill", self.x, self.y, self.width, 20)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(self.title, self.x + 5, self.y + 2)
    
    -- Draw close button
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", self.x + self.width - self.closeButtonSize - 2, self.y + 2, self.closeButtonSize, self.closeButtonSize)
    love.graphics.setColor(1, 1, 1)
    love.graphics.line(self.x + self.width - self.closeButtonSize, self.y + 4, self.x + self.width - 4, self.y + self.closeButtonSize)
    love.graphics.line(self.x + self.width - 4, self.y + 4, self.x + self.width - self.closeButtonSize, self.y + self.closeButtonSize)
    
    -- Draw minimize button
    love.graphics.setColor(1, 1, 0)
    love.graphics.rectangle("fill", self.x + self.width - self.closeButtonSize - self.minimizeButtonSize - 6, self.y + 2, self.minimizeButtonSize, self.minimizeButtonSize)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", self.x + self.width - self.closeButtonSize - self.minimizeButtonSize - 4, self.y + 12, self.minimizeButtonSize - 4, 2)
    
    if self.windowType == "terminal" and self.terminal then
        self.terminal:draw(self.x, self.y + 25, self.width, self.height - 25)
    elseif self.windowType == "editor" and self.editor then
        self.editor:draw(self.x, self.y + 25, self.width - 10, self.height - 30)
    elseif self.windowType == "file_browser" and self.fileBrowser then
        self.fileBrowser:draw(self.x, self.y + 25, self.width - 10, self.height - 30)
    end
end

function Window:update(dt)
    if self.windowType == "terminal" and self.terminal and self.terminal.update then
        self.terminal:update(dt)
    elseif self.windowType == "editor" and self.editor and self.editor.update then
        self.editor:update(dt)
    elseif self.windowType == "file_browser" and self.fileBrowser and self.fileBrowser.update then
        self.fileBrowser:update(dt)
    end
end

function Window:keypressed(key)
    if self.windowType == "terminal" and self.terminal then
        self.terminal:keypressed(key)
    elseif self.windowType == "editor" and self.editor then
        self.editor:keypressed(key)
    elseif self.windowType == "file_browser" and self.fileBrowser then
        self.fileBrowser:keypressed(key)
    end
end

function Window:textinput(t)
    if self.windowType == "terminal" and self.terminal then
        self.terminal:textinput(t)
    elseif self.windowType == "editor" and self.editor then
        self.editor:textinput(t)
    elseif self.windowType == "file_browser" and self.fileBrowser then
        self.fileBrowser:textinput(t)
    end
end

function Window:wheelmoved(x, y)
    if self.windowType == "terminal" and self.terminal then
        self.terminal:wheelmoved(x, y)
    elseif self.windowType == "editor" and self.editor then
        self.editor:wheelmoved(x, y)
    elseif self.windowType == "file_browser" and self.fileBrowser then
        self.fileBrowser:wheelmoved(x, y)
    end
end

function Window:mousepressed(x, y, button)
    if self.windowType == "editor" and self.editor then
        self.editor:mousepressed(x - self.x, y - self.y, button)
    elseif self.windowType == "file_browser" and self.fileBrowser then
        self.fileBrowser:mousepressed(x - self.x, y - self.y, button)
    end
end

function Window:checkHover(x, y)
    return x >= self.x and x <= self.x + self.width and
           y >= self.y and y <= self.y + self.height
end

function Window:checkTitleBarHover(x, y)
    return x >= self.x and x <= self.x + self.width and
           y >= self.y and y <= self.y + 20
end

function Window:checkCloseButtonHover(x, y)
    return x >= self.x + self.width - self.closeButtonSize - 2 and 
           x <= self.x + self.width - 2 and
           y >= self.y + 2 and 
           y <= self.y + self.closeButtonSize + 2
end

function Window:checkMinimizeButtonHover(x, y)
    return x >= self.x + self.width - self.closeButtonSize - self.minimizeButtonSize - 6 and 
           x <= self.x + self.width - self.closeButtonSize - 6 and
           y >= self.y + 2 and 
           y <= self.y + self.minimizeButtonSize + 2
end

function Window:addContent(text, color)
    if self.windowType == "terminal" and self.terminal then
        self.terminal:addContent(text, color)
    end
end

return Window