local FileSystem = require "lua/file_system"

Terminal = {}
Terminal.__index = Terminal

local terminalColors = {
    {0, 1, 0},    -- Green (default)
    {1, 1, 1},    -- White
    {1, 1, 0},    -- Yellow
    {1, 0, 0},    -- Red
    {0, 0, 1},    -- Blue
    {1, 0, 1},    -- Magenta
    {0, 1, 1},    -- Cyan
}

function Terminal.new(font)
    local self = setmetatable({}, Terminal)
    self.content = {}
    self.promptLine = "> "
    self.commandHistory = {}
    self.historyIndex = 0
    self.maxLines = 1000
    self.maxColumns = 80
    self.scrollOffset = 0
    self.currentColor = 1
    self.font = font
    return self
end

function Terminal:draw(x, y, width, height)
    love.graphics.setColor(1, 1, 1)
    local lineHeight = self.font:getHeight()
    local visibleLines = math.floor(height / lineHeight)
    
    for i = 1, visibleLines do
        local contentIndex = i + self.scrollOffset
        if contentIndex <= #self.content then
            love.graphics.setColor(terminalColors[self.content[contentIndex].color])
            local text = self.content[contentIndex].text
            local wrappedText = self:wrapText(text, width - 10)
            for j, line in ipairs(wrappedText) do
                love.graphics.print(line, x + 5, y + ((i-1)+j-1)*lineHeight)
            end
        end
    end
    
    -- Draw prompt line
    love.graphics.setColor(terminalColors[self.currentColor])
    love.graphics.print(self.promptLine, x + 5, y + height - lineHeight - 5)
    
    -- Draw cursor
    if math.floor(love.timer.getTime() * 2) % 2 == 0 then
        love.graphics.rectangle("fill", x + 5 + self.font:getWidth(self.promptLine), y + height - lineHeight - 5, self.font:getWidth("W"), lineHeight)
    end
end

function Terminal:update(dt)
    -- Add any necessary update logic here
end

function Terminal:keypressed(key)
    if key == "backspace" then
        if #self.promptLine > 2 then
            self.promptLine = self.promptLine:sub(1, -2)
        end
    elseif key == "return" then
        local command = self.promptLine:sub(3)
        table.insert(self.commandHistory, command)
        self.historyIndex = #self.commandHistory + 1
        self:addContent(self.promptLine)
        self:executeCommand(command)
        self.promptLine = "> "
    elseif key == "up" then
        if self.historyIndex > 1 then
            self.historyIndex = self.historyIndex - 1
            self.promptLine = "> " .. self.commandHistory[self.historyIndex]
        end
    elseif key == "down" then
        if self.historyIndex < #self.commandHistory then
            self.historyIndex = self.historyIndex + 1
            self.promptLine = "> " .. self.commandHistory[self.historyIndex]
        elseif self.historyIndex == #self.commandHistory then
            self.historyIndex = #self.commandHistory + 1
            self.promptLine = "> "
        end
    end
end

function Terminal:textinput(t)
    if #self.promptLine < self.maxColumns then
        self.promptLine = self.promptLine .. t
    end
end

function Terminal:wheelmoved(x, y)
    self.scrollOffset = math.max(0, math.min(self.scrollOffset - y, #self.content - 10))
end

function Terminal:addContent(text, color)
    table.insert(self.content, {text = text, color = color or self.currentColor})
    if #self.content > self.maxLines then
        table.remove(self.content, 1)
    end
    -- Adjust scroll offset to show the new content
    self.scrollOffset = math.max(0, #self.content - 10)  -- Assuming 10 visible lines
end

function Terminal:wrapText(text, maxWidth)
    local wrappedLines = {}
    local line = ""
    for word in text:gmatch("%S+") do
        local testLine = line .. (line:len() > 0 and " " or "") .. word
        if self.font:getWidth(testLine) <= maxWidth then
            line = testLine
        else
            table.insert(wrappedLines, line)
            line = word
        end
    end
    table.insert(wrappedLines, line)
    return wrappedLines
end

function Terminal:executeCommand(cmd)
    local args = {}
    for arg in cmd:gmatch("%S+") do
        table.insert(args, arg)
    end
    
    if args[1] == "help" then
        self:addContent("Available commands:", 2)
        self:addContent("help, clear, echo, exit, date, time, color, ls, cd, pwd, cat, mkdir, touch, rm", 2)
    elseif args[1] == "clear" then
        self.content = {}
        self.scrollOffset = 0
    elseif args[1] == "echo" then
        self:addContent(table.concat(args, " ", 2))
    elseif args[1] == "exit" then
        love.event.quit()
    elseif args[1] == "date" then
        self:addContent(os.date("%Y-%m-%d"))
    elseif args[1] == "time" then
        self:addContent(os.date("%H:%M:%S"))
    elseif args[1] == "color" then
        local newColor = tonumber(args[2])
        if newColor and newColor >= 1 and newColor <= #terminalColors then
            self.currentColor = newColor
            self:addContent("Color changed.", newColor)
        else
            self:addContent("Invalid color. Choose a number between 1 and " .. #terminalColors, 4)
        end
    elseif args[1] == "ls" then
        local items, err = FileSystem.listDirectory(args[2] or FileSystem.currentDirectory)
        if items then
            for _, item in ipairs(items) do
                if item.type == "directory" then
                    self:addContent("  [DIR] " .. item.name, 5)
                else
                    self:addContent("  " .. item.name, 1)
                end
            end
        else
            self:addContent(err, 4)
        end
    elseif args[1] == "cd" then
        local success, err = FileSystem.changeDirectory(args[2] or "/")
        if success then
            self:addContent("Current directory: " .. FileSystem.currentDirectory, 2)
        else
            self:addContent(err, 4)
        end
    elseif args[1] == "pwd" then
        self:addContent(FileSystem.currentDirectory, 2)
    elseif args[1] == "cat" then
        if args[2] then
            local content, err = FileSystem.readFile(args[2])
            if content then
                self:addContent("Contents of " .. args[2] .. ":", 2)
                self:addContent(content)
            else
                self:addContent("Error reading file: " .. (err or "File not found"), 4)
            end
        else
            self:addContent("Usage: cat <filename>", 4)
        end
    elseif args[1] == "mkdir" then
        if args[2] then
            local success, err = FileSystem.makeDirectory(args[2])
            if success then
                self:addContent("Directory created: " .. args[2], 2)
            else
                self:addContent("Error creating directory: " .. (err or "Unknown error"), 4)
            end
        else
            self:addContent("Usage: mkdir <directory>", 4)
        end
    elseif args[1] == "touch" then
        if args[2] then
            local success, err = FileSystem.writeFile(args[2], "")
            if success then
                self:addContent("File created: " .. args[2], 2)
            else
                self:addContent("Error creating file: " .. (err or "Unknown error"), 4)
            end
        else
            self:addContent("Usage: touch <filename>", 4)
        end
    elseif args[1] == "rm" then
        if args[2] then
            local success, err = FileSystem.removeFile(args[2])
            if success then
                self:addContent("File removed: " .. args[2], 2)
            else
                self:addContent("Error removing file: " .. (err or "File not found"), 4)
            end
        else
            self:addContent("Usage: rm <filename>", 4)
        end
    else
        self:addContent("Unknown command: " .. args[1], 4)
    end
end


return Terminal