local Fsys = require(game.ReplicatedStorage:WaitForChild("Fsys")).load

-- Get the init function from RouterClient
local initFunction = Fsys("RouterClient").init

-- Folder containing the remotes to track
local remoteFolder = game.ReplicatedStorage:WaitForChild("API")

-- Function to inspect upvalues and identify remotes
local function inspectUpvalues()
    local remotes = {}  -- Table to collect remotes

    for i = 1, math.huge do
        local success, upvalue = pcall(getupvalue, initFunction, i)
        if not success then
            break
        end
        
        -- If the upvalue is a table, let's check its contents
        if typeof(upvalue) == "table" then
            for k, v in pairs(upvalue) do
                -- If the value is an Instance (likely a RemoteEvent or RemoteFunction), collect it
                if typeof(v) == "Instance" and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
                    -- Log each remote found
                    table.insert(remotes, {key = k, remote = v})  -- Add the remote instance with key to the remotes table
                end
            end
        end
    end

    return remotes
end

-- Function to rename remotes based on their key
local function rename(remote, key)
    local nameParts = string.split(key, "/")  -- Split the key by "/"
    if #nameParts == 2 then
        local remotename = nameParts[2]
        remote.Name = remotename
    else
        warn("Invalid key format for remote: " .. key)  -- Notify if the key format is incorrect
    end
end

-- Function to rename all existing remotes in the folder
local function renameExistingRemotes()
    local remotes = inspectUpvalues()

    -- Rename all collected remotes based on the key
    for _, entry in ipairs(remotes) do
        rename(entry.remote, entry.key)
    end
    print("Renaming complete.")
end

-- Monitor for new remotes added to the folder
local function monitorForNewRemotes()
    remoteFolder.ChildAdded:Connect(function(child)
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            print("New remote added: " .. child:GetFullName())
            -- Check and rename the new remote
            local remotes = inspectUpvalues()
            for _, entry in ipairs(remotes) do
                rename(entry.remote, entry.key)
            end
        end
    end)
end

-- Start monitoring for new remotes
monitorForNewRemotes()

-- Coroutine for periodic check without freezing
local function periodicCheck()
    while true do
        task.wait(10)  -- Check every 10 seconds (can adjust based on your needs)
        pcall(renameExistingRemotes)  -- Check and rename any existing remotes periodically
    end
end

-- Start the periodic check in a coroutine (non-blocking)
coroutine.wrap(periodicCheck)()

-- Initial rename for all existing remotes
renameExistingRemotes()

print("Script initialized and monitoring remotes.")
