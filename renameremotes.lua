local Fsys = require(game.ReplicatedStorage:WaitForChild("Fsys")).load

-- Get the init function from RouterClient
local initFunction = Fsys("RouterClient").init

-- Folder containing the remotes to track
local remoteFolder = game.ReplicatedStorage:WaitForChild("API")

-- A flag to ensure we print only once during the initial scan
local printedOnce = false

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
                -- Check for RemoteEvents, RemoteFunctions, BindableEvents, and BindableFunctions
                if typeof(v) == "Instance" then
                    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") or v:IsA("BindableEvent") or v:IsA("BindableFunction") then
                        -- Log the key, type of value, and value
                        table.insert(remotes, {key = k, remote = v})
                        -- If it's the first time scanning, print remote information
                        if not printedOnce then
                            print("Key: " .. k .. " Type: " .. typeof(k) .. ", Value Type: " .. typeof(v))
                            print("Found remote: " .. v:GetFullName())
                        end
                    end
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
end

-- Function to display dehashed message
local function displayDehashedMessage()
    local uiElement = game:GetService("Players").LocalPlayer.PlayerGui.HintApp.LargeTextLabel
    uiElement.Text = "Remotes has been Dehashed!"
    uiElement.TextColor3 = Color3.fromRGB(0, 255, 0)  -- Set text color to green
    wait(3)
    uiElement.Text = ""
    uiElement.TextColor3 = Color3.fromRGB(255, 255, 255)  -- Reset text color to default (white)
end

-- Monitor for new remotes added to the folder
local function monitorForNewRemotes()
    remoteFolder.ChildAdded:Connect(function(child)
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") or child:IsA("BindableEvent") or child:IsA("BindableFunction") then
            print("New remote added: " .. child:GetFullName())
            -- Check and rename the new remote
            local remotes = inspectUpvalues()
            for _, entry in ipairs(remotes) do
                rename(entry.remote, entry.key)
            end
        end
    end)
end

-- Coroutine for periodic check without freezing
local function periodicCheck()
    while true do
        task.wait(10)  -- Check every 10 seconds (can adjust based on your needs)
        -- Scan and rename existing remotes periodically
        pcall(renameExistingRemotes)
    end
end

-- Start the periodic check in a coroutine (non-blocking)
coroutine.wrap(periodicCheck)()

-- Initial scan and rename for all existing remotes (print once)
renameExistingRemotes()

-- Display dehashed message
displayDehashedMessage()

-- Set the flag to prevent printing more than once
printedOnce = true

print("Script initialized and monitoring remotes.")
