local FileSystem = require "lua/file_system"

FileBrowser = {}
FileBrowser.__index = FileBrowser

function FileBrowser.new(font)
    local self = setmetatable({}, FileBrowser)
    self.font = font
    self.currentPath = ""
    self.items = {}
    self.selectedItem = nil
    self.scrollOffset = 0
    self.lastHeight = 0
    self:updateFileList()
    return self
end

function FileBrowser:updateFileList()
    self.items = {}
    local items, err = FileSystem.listDirectory(self.currentPath)
    if err then
        print("Error listing directory: " .. err)
        return
    end
    if self.currentPath ~= "" then
        table.insert(self.items, {name = "..", type = "directory"})
    end
    for _, item in ipairs(items) do
        table.insert(self.items, item)
    end
    self.selectedItem = 1
    self.scrollOffset = 0
end

function FileBrowser:draw(x, y, width, height)
    self.lastHeight = height
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Current path: /" .. self.currentPath, x, y, width, "left")
    
    local lineHeight = self.font:getHeight() + 5
    local visibleItems = math.floor((height - 30) / lineHeight)
    
    for i = 1, visibleItems do
        local index = i + self.scrollOffset
        local item = self.items[index]
        if item then
            local itemY = y + 30 + (i-1) * lineHeight
            if index == self.selectedItem then
                love.graphics.setColor(0.2, 0.4, 0.8)
                love.graphics.rectangle("fill", x, itemY, width, lineHeight)
            end
            love.graphics.setColor(1, 1, 1)
            local icon = item.type == "directory" and "[D] " or "[F] "
            love.graphics.print(icon .. item.name, x + 5, itemY)
        end
    end
end

function FileBrowser:mousepressed(x, y, button)
    if button == 1 then  -- Left mouse button
        local lineHeight = self.font:getHeight() + 5
        local index = math.floor((y - 30) / lineHeight) + 1 + self.scrollOffset
        if self.items[index] then
            self.selectedItem = index
            self:openItem(self.items[index])
        end
    end
end

function FileBrowser:openItem(item)
    if item.type == "directory" then
        if item.name == ".." then
            -- Go up one directory
            self.currentPath = self.currentPath:match("(.+)/") or ""
        else
            -- Enter the directory
            self.currentPath = self.currentPath .. (self.currentPath ~= "" and "/" or "") .. item.name
        end
        self:updateFileList()
    else
        -- Open file in editor
        local filePath = self.currentPath .. (self.currentPath ~= "" and "/" or "") .. item.name
        print("Attempting to open file: " .. filePath)
        local content = FileSystem.readFile(filePath)
        if content then
            print("File read successfully. Size: " .. #content .. " bytes")
            launchEditor(filePath, content)
        else
            print("Failed to read file: " .. filePath)
            launchEditor(filePath, "")
        end
    end
end

function FileBrowser:wheelmoved(x, y)
    local visibleItems = math.floor((self.lastHeight - 30) / (self.font:getHeight() + 5))
    self.scrollOffset = math.max(0, math.min(self.scrollOffset - y, #self.items - visibleItems))
end

function FileBrowser:keypressed(key)
    if key == "up" and self.selectedItem > 1 then
        self.selectedItem = self.selectedItem - 1
        if self.selectedItem < self.scrollOffset + 1 then
            self.scrollOffset = self.selectedItem - 1
        end
    elseif key == "down" and self.selectedItem < #self.items then
        self.selectedItem = self.selectedItem + 1
        local visibleItems = math.floor((self.lastHeight - 30) / (self.font:getHeight() + 5))
        if self.selectedItem > self.scrollOffset + visibleItems then
            self.scrollOffset = self.selectedItem - visibleItems
        end
    elseif key == "return" then
        self:openItem(self.items[self.selectedItem])
    end
end

function FileBrowser:update(dt)
    -- Add any necessary update logic here
end

function FileBrowser:textinput(t)
    -- Add any necessary text input logic here
end

return FileBrowser