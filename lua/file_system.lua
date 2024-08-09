local FileSystem = {}

FileSystem.rootDirectory = "system"
FileSystem.currentDirectory = ""

function FileSystem.getFullPath(path)
    if path:sub(1, #FileSystem.rootDirectory) == FileSystem.rootDirectory then
        return path  -- Path already includes root directory
    elseif path:sub(1, 1) == "/" then
        return FileSystem.rootDirectory .. path
    else
        return FileSystem.rootDirectory .. "/" .. FileSystem.currentDirectory .. 
               (FileSystem.currentDirectory ~= "" and "/" or "") .. path
    end
end

function FileSystem.listDirectory(path)
    local fullPath = FileSystem.getFullPath(path)
    local items, err = love.filesystem.getDirectoryItems(fullPath)
    if err then
        return nil, "Error listing directory: " .. err
    end
    
    local result = {}
    for _, item in ipairs(items) do
        local itemPath = fullPath .. "/" .. item
        local info = love.filesystem.getInfo(itemPath)
        if info then
            table.insert(result, {name = item, type = info.type})
        end
    end
    return result
end

function FileSystem.changeDirectory(path)
    if path == ".." then
        FileSystem.currentDirectory = FileSystem.currentDirectory:match("(.+)/") or ""
    elseif path:sub(1, 1) == "/" then
        FileSystem.currentDirectory = path:sub(2)  -- Remove leading '/'
    else
        FileSystem.currentDirectory = FileSystem.currentDirectory .. (FileSystem.currentDirectory ~= "" and "/" or "") .. path
    end
    FileSystem.currentDirectory = FileSystem.currentDirectory:gsub("^/", ""):gsub("/$", "")
    return true
end

function FileSystem.readFile(filename)
    local path = FileSystem.getFullPath(filename)
    return love.filesystem.read(path)
end

function FileSystem.writeFile(filename, content)
    local path = FileSystem.getFullPath(filename)
    local success, err = love.filesystem.write(path, content)
    if not success then
        print("Error writing file: " .. path .. " - " .. (err or "Unknown error"))
    end
    return success, err
end

function FileSystem.makeDirectory(dirname)
    local path = FileSystem.getFullPath(dirname)
    return love.filesystem.createDirectory(path)
end

function FileSystem.removeFile(filename)
    local path = FileSystem.getFullPath(filename)
    return love.filesystem.remove(path)
end

return FileSystem