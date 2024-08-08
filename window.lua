-- window.lua
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
    self.closeButtonSize = 16  -- Size of the close button
    if self.windowType == "editor" then
        self.editor = CodeEditor.new(font)
    elseif self.windowType == "terminal" then
        self.terminal = Terminal.new(font)
    end
    return self
end

function Window:draw()
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("fill", self.x, self.y, self.width, 20)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(self.title, self.x + 5, self.y + 2)
    
    -- Draw close button
    love.graphics.setColor(1, 0, 0)  -- Red color for close button
    love.graphics.rectangle("fill", self.x + self.width - self.closeButtonSize - 2, self.y + 2, self.closeButtonSize, self.closeButtonSize)
    love.graphics.setColor(1, 1, 1)  -- White color for X
    love.graphics.line(self.x + self.width - self.closeButtonSize, self.y + 4, self.x + self.width - 4, self.y + self.closeButtonSize)
    love.graphics.line(self.x + self.width - 4, self.y + 4, self.x + self.width - self.closeButtonSize, self.y + self.closeButtonSize)
    
    if self.windowType == "terminal" then
        self.terminal:draw(self.x, self.y + 25, self.width, self.height - 25)
    elseif self.windowType == "editor" then
        self.editor:draw(self.x + 5, self.y + 25, self.width - 10, self.height - 30)
    end
end

function Window:update(dt)
    if self.windowType == "terminal" then
        self.terminal:update(dt)
    elseif self.windowType == "editor" then
        self.editor:update(dt)
    end
end

function Window:keypressed(key)
    if self.windowType == "terminal" then
        self.terminal:keypressed(key)
    elseif self.windowType == "editor" then
        self.editor:keypressed(key)
    end
end

function Window:textinput(t)
    if self.windowType == "terminal" then
        self.terminal:textinput(t)
    elseif self.windowType == "editor" then
        self.editor:textinput(t)
    end
end

function Window:wheelmoved(x, y)
    if self.windowType == "terminal" then
        self.terminal:wheelmoved(x, y)
    elseif self.windowType == "editor" then
        self.editor:wheelmoved(x, y)
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

function Window:addContent(text, color)
    if self.windowType == "terminal" then
        self.terminal:addContent(text, color)
    end
end

return Window