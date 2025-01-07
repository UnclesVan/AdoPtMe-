local Fsys = require(game.ReplicatedStorage:WaitForChild("Fsys")).load

-- Get the init function from RouterClient
local initFunction = Fsys("RouterClient").init

-- Function to inspect upvalues and identify remotes
local function inspectUpvalues()
    local remotes = {}  -- Table to collect remotes

    for i = 1, math.huge do
        local success, upvalue = pcall(getupvalue, initFunction, i)
        if not success then
            break
        end
        
        -- Print upvalue index and its type
        print("Upvalue index " .. i .. ": Type = " .. typeof(upvalue) .. ", Value = " .. tostring(upvalue))
        
        -- If the upvalue is a table, let's check its contents
        if typeof(upvalue) == "table" then
            print("  Table found, inspecting contents...")
            for k, v in pairs(upvalue) do
                -- Print the key and value types to understand the structure better
                print("    Key: " .. tostring(k) .. " Type: " .. typeof(k) .. ", Value Type: " .. typeof(v))
                
                -- If the value is an Instance (likely a RemoteEvent or RemoteFunction), collect it
                if typeof(v) == "Instance" and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
                    print("    Found remote: " .. v:GetFullName())
                    table.insert(remotes, {key = k, remote = v})  -- Add the remote instance with key to the remotes table
                end
            end
        end
    end

    return remotes
end

-- Call the inspect function to log upvalues and collect remotes
local remotes = inspectUpvalues()

-- Function to rename remotes based on their key
local function rename(remote, key)
    local nameParts = string.split(key, "/")  -- Split the key by "/"
    if #nameParts == 2 then
        local remotename = nameParts[2]
        remote.Name = remotename
    else
        warn("Invalid key format for remote: " .. key)
    end
end

-- Now rename all collected remotes based on the key
for _, entry in ipairs(remotes) do
    rename(entry.remote, entry.key)
end

print("Renaming complete.")
