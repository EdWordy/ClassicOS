local FileSystem = require "lua/file_system"

CodeEditor = {}
CodeEditor.__index = CodeEditor

function CodeEditor.new(font)
    local self = setmetatable({}, CodeEditor)
    self.content = {""}
    self.cursorX = 1
    self.cursorY = 1
    self.scrollY = 0
    self.filename = ""
    self.font = font
    self.lineNumberWidth = 30
    self.statusMessage = ""
    self.statusMessageTimer = 0
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    return self
end

function CodeEditor:draw(x, y, width, height)
    love.graphics.setColor(1, 1, 1)
    local lineHeight = self.font:getHeight()
    local visibleLines = math.floor(height / lineHeight)
    
    -- Draw line numbers background
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", x, y, self.lineNumberWidth, height)
    
    -- Draw line numbers
    love.graphics.setColor(0.5, 0.5, 0.5)
    for i = 1, visibleLines do
        local lineNumber = i + self.scrollY
        love.graphics.print(tostring(lineNumber), x + 5, y + (i-1)*lineHeight)
    end
    
    -- Draw content
    love.graphics.setColor(1, 1, 1)
    local contentX = x + self.lineNumberWidth
    for i = 1, visibleLines do
        local lineIndex = i + self.scrollY
        if lineIndex <= #self.content then
            love.graphics.print(self.content[lineIndex], contentX, y + (i-1)*lineHeight)
        end
    end
    
    -- Draw cursor
    if math.floor(love.timer.getTime() * 2) % 2 == 0 then
        love.graphics.rectangle("fill", 
            contentX + self.font:getWidth(self.content[self.cursorY]:sub(1, self.cursorX - 1)), 
            y + (self.cursorY - self.scrollY - 1) * lineHeight, 
            2, lineHeight)
    end

    -- Draw status message
    if self.statusMessageTimer > 0 then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(self.statusMessage, x, y + height - 25, width, "center")
    end
end

function CodeEditor:update(dt)
    if self.statusMessageTimer > 0 then
        self.statusMessageTimer = self.statusMessageTimer - dt
        if self.statusMessageTimer <= 0 then
            self.statusMessage = ""
        end
    end
end

function CodeEditor:keypressed(key)
    if key == "backspace" then
        self:backspace()
    elseif key == "return" then
        self:newLine()
    elseif key == "left" then
        if self.cursorX > 1 then
            self.cursorX = self.cursorX - 1
        elseif self.cursorY > 1 then
            self.cursorY = self.cursorY - 1
            self.cursorX = #self.content[self.cursorY] + 1
        end
    elseif key == "right" then
        if self.cursorX <= #self.content[self.cursorY] then
            self.cursorX = self.cursorX + 1
        elseif self.cursorY < #self.content then
            self.cursorY = self.cursorY + 1
            self.cursorX = 1
        end
    elseif key == "up" and self.cursorY > 1 then
        self.cursorY = self.cursorY - 1
        self.cursorX = math.min(self.cursorX, #self.content[self.cursorY] + 1)
    elseif key == "down" and self.cursorY < #self.content then
        self.cursorY = self.cursorY + 1
        self.cursorX = math.min(self.cursorX, #self.content[self.cursorY] + 1)
    elseif love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
        if key == "s" then
            self:save()
        end
    end
end

function CodeEditor:textinput(t)
    self:insertChar(t)
end

function CodeEditor:wheelmoved(x, y)
    self.scrollY = math.max(0, math.min(self.scrollY - y, #self.content - 10))
end

function CodeEditor:insertChar(char)
    local line = self.content[self.cursorY]
    self.content[self.cursorY] = line:sub(1, self.cursorX - 1) .. char .. line:sub(self.cursorX)
    self.cursorX = self.cursorX + 1
end

function CodeEditor:newLine()
    local line = self.content[self.cursorY]
    local restOfLine = line:sub(self.cursorX)
    self.content[self.cursorY] = line:sub(1, self.cursorX - 1)
    table.insert(self.content, self.cursorY + 1, restOfLine)
    self.cursorY = self.cursorY + 1
    self.cursorX = 1
end

function CodeEditor:backspace()
    local line = self.content[self.cursorY]
    if self.cursorX > 1 then
        self.content[self.cursorY] = line:sub(1, self.cursorX - 2) .. line:sub(self.cursorX)
        self.cursorX = self.cursorX - 1
    elseif self.cursorY > 1 then
        local previousLine = self.content[self.cursorY - 1]
        self.cursorX = #previousLine + 1
        self.content[self.cursorY - 1] = previousLine .. line
        table.remove(self.content, self.cursorY)
        self.cursorY = self.cursorY - 1
    end
end

function CodeEditor:save()
    local content = table.concat(self.content, "\n")
    local success, err = FileSystem.writeFile(self.filename, content)
    if success then
        self.statusMessage = "File saved successfully!"
        self.statusMessageTimer = 3
        print("File saved successfully: " .. self.filename)
    else
        self.statusMessage = "Error saving file: " .. (err or "Unknown error")
        self.statusMessageTimer = 3
        print("Error saving file: " .. self.filename .. " - " .. (err or "Unknown error"))
    end
end

function CodeEditor:loadContent(filename, content)
    self.filename = filename
    self.content = {}
    for line in (content .. "\n"):gmatch("([^\r\n]*)[\r\n]") do
        table.insert(self.content, line)
    end
    if #self.content == 0 then
        self.content = {""}
    end
    self.cursorX = 1
    self.cursorY = 1
    self.scrollY = 0
    print("CodeEditor loaded content for: " .. filename)
    print("Number of lines: " .. #self.content)
end

return CodeEditor