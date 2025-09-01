-- bridge.lua
-- Usage: bridge <steps>
-- Example: bridge 20

-- slot with building blocks
local BLOCK_SLOT = 1

-- ensure turtle has block in slot
local function selectBlock()
    if turtle.getItemCount(BLOCK_SLOT) == 0 then
        print("Out of blocks in slot " .. BLOCK_SLOT)
        return false
    end
    turtle.select(BLOCK_SLOT)
    return true
end

-- place block if no block is present
local function placeIfAir(placeFunc, detectFunc)
    if not detectFunc() then
        if selectBlock() then
            placeFunc()
        end
    end
end

-- main
local tArgs = { ... }
if #tArgs < 1 then
    print("Usage: bridge <steps>")
    return
end

local steps = tonumber(tArgs[1])
if steps == nil then
    print("Steps must be a number")
    return
end

for i = 1, steps do
    -- dig forward if blocked
    while turtle.detect() do
        turtle.dig()
        sleep(0.2)
    end

    -- move forward
    if not turtle.forward() then
        print("Blocked, stopping at step " .. i)
        break
    end

    -- place below
    placeIfAir(turtle.placeDown, turtle.detectDown)

    -- place left
    turtle.turnLeft()
    placeIfAir(turtle.place, turtle.detect)
    turtle.turnRight()

    -- place right
    turtle.turnRight()
    placeIfAir(turtle.place, turtle.detect)
    turtle.turnLeft()
end

print("Done!")
