local Desktop = {}

local icons = {
    {
        name = "Terminal",
        x = 20,
        y = 20,
        width = 64,
        height = 64,
        image = nil,  -- We'll load this in the init function
        action = function() launchTerminal() end
    },
    {
        name = "Code Editor",
        x = 20,
        y = 104,  -- 20 + 64 + 20
        width = 64,
        height = 64,
        image = nil,  -- We'll load this in the init function
        action = function() launchEditor("New File.txt") end
    }
}

function Desktop.init()
    -- Load icon images
    icons[1].image = love.graphics.newImage("assets/terminal_icon.png")
    icons[2].image = love.graphics.newImage("assets/editor_icon.png")
end

function Desktop.draw()
    for _, icon in ipairs(icons) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(icon.image, icon.x, icon.y)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(icon.name, icon.x, icon.y + icon.height + 5, icon.width, "center")
    end
end

function Desktop.mousepressed(x, y, button)
    if button == 1 then  -- Left mouse button
        for _, icon in ipairs(icons) do
            if x >= icon.x and x <= icon.x + icon.width and
               y >= icon.y and y <= icon.y + icon.height + 20 then  -- +20 for text area
                icon.action()
                return true
            end
        end
    end
    return false
end

return Desktop