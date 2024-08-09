local Desktop = {}

local icons = {
    {
        name = "Terminal",
        x = 20,
        y = 20,
        width = 64,
        height = 64,
        image = nil,
        action = function() launchTerminal() end
    },
    {
        name = "Editor",
        x = 20,
        y = 104,
        width = 64,
        height = 64,
        image = nil,
        action = function() launchEditor("New File.txt") end
    },
    {
        name = "Files",
        x = 20,
        y = 188,
        width = 64,
        height = 64,
        image = nil,
        action = function() launchFileBrowser() end
    }
}

local taskbarHeight = 40
local taskbarColor = {0.2, 0.2, 0.2}
local taskbarItemWidth = 150
local taskbarItemHeight = 30
local taskbarItemPadding = 5

function Desktop.init()
    icons[1].image = love.graphics.newImage("assets/terminal_icon.png")
    icons[2].image = love.graphics.newImage("assets/editor_icon.png")
    icons[3].image = love.graphics.newImage("assets/file_browser_icon.png")
end

function Desktop.draw()
    for _, icon in ipairs(icons) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(icon.image, icon.x, icon.y)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(icon.name, icon.x, icon.y + icon.height + 5, icon.width, "center")
    end
    
    -- Draw taskbar
    love.graphics.setColor(unpack(taskbarColor))
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - taskbarHeight, love.graphics.getWidth(), taskbarHeight)
end

function Desktop.drawTaskbarItems(windows)
    local x = taskbarItemPadding
    for _, window in ipairs(windows) do
        love.graphics.setColor(0.3, 0.3, 0.3)
        if window.isMinimized then
            love.graphics.setColor(0.2, 0.2, 0.2)  -- Darker color for minimized windows
        end
        love.graphics.rectangle("fill", x, love.graphics.getHeight() - taskbarHeight + taskbarItemPadding, taskbarItemWidth, taskbarItemHeight)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(window.title, x, love.graphics.getHeight() - taskbarHeight + taskbarItemPadding + 5, taskbarItemWidth, "center")
        x = x + taskbarItemWidth + taskbarItemPadding
    end
end

function Desktop.mousepressed(x, y, button)
    if button == 1 then  -- Left mouse button
        for _, icon in ipairs(icons) do
            if x >= icon.x and x <= icon.x + icon.width and
               y >= icon.y and y <= icon.y + icon.height + 20 then
                icon.action()
                return true
            end
        end
        
        -- Check taskbar item clicks
        if y > love.graphics.getHeight() - taskbarHeight then
            local itemIndex = math.floor(x / (taskbarItemWidth + taskbarItemPadding)) + 1
            return itemIndex  -- Return the index of the clicked taskbar item
        end
    end
    return false
end

return Desktop