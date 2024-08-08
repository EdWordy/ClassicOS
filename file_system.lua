rootDirectory = "system"
currentDirectory = "/"

function getFullPath(path)
    if path:sub(1, 1) == "/" then
        return rootDirectory .. path
    else
        return rootDirectory .. currentDirectory .. "/" .. path
    end
end

function listDirectory(path)
    local fullPath = getFullPath(path)
    local items, err = love.filesystem.getDirectoryItems(fullPath)
    if err then
        return nil, "Error listing directory: " .. err
    end
    
    local result = {}
    for _, item in ipairs(items) do
        local info = love.filesystem.getInfo(fullPath .. "/" .. item)
        if info.type == "directory" then
            table.insert(result, {name = item, type = "directory"})
        else
            table.insert(result, {name = item, type = "file"})
        end
    end
    return result
end

function changeDirectory(path)
    local newPath
    if path == ".." then
        newPath = currentDirectory:match("(.+)/[^/]+$") or "/"
    elseif path:sub(1, 1) == "/" then
        newPath = path
    else
        newPath = currentDirectory .. "/" .. path
    end
    
    newPath = newPath:gsub("//", "/")  -- Remove any double slashes
    
    if love.filesystem.getInfo(getFullPath(newPath), "directory") then
        currentDirectory = newPath
        return true
    else
        return false, "Directory not found: " .. newPath
    end
end

function readFile(filename)
    local path = getFullPath(currentDirectory .. "/" .. filename)
    return love.filesystem.read(path)
end

function writeFile(filename, content)
    local path = getFullPath(currentDirectory .. "/" .. filename)
    return love.filesystem.write(path, content)
end

function makeDirectory(dirname)
    local path = getFullPath(currentDirectory .. "/" .. dirname)
    return love.filesystem.createDirectory(path)
end

function removeFile(filename)
    local path = getFullPath(currentDirectory .. "/" .. filename)
    return love.filesystem.remove(path)
end