-- bridge: build a mined, 3-wide path with support
-- Usage: bridge <length>
-- CC:Tweaked for 1.20.1

local args = {...}
local length = tonumber(args[1] or "")
if not length or length < 1 then
  print("Usage: bridge <length>")
  return
end

-- Preferred building blocks for supports/rails
local preferredBlocks = {
  "minecraft:cobblestone",
  "minecraft:netherrack",
  "cobblestone",
  "netherrack",
}

local function sleepShort() sleep(0.15) end

-- Try to refuel enough to finish (or at least the next few steps)
local function refuelIfNeeded(needed)
  local fuel = turtle.getFuelLevel()
  if fuel == "unlimited" then return true end
  if fuel >= needed then return true end

  -- Try every slot for fuel
  for i = 1, 16 do
    local detail = turtle.getItemDetail(i)
    if detail then
      turtle.select(i)
      -- turtle.refuel(0) checks if it is fuel
      if turtle.refuel(0) then
        turtle.refuel() -- eat the stack
        if turtle.getFuelLevel() >= needed then
          return true
        end
      end
    end
  end

  print("Out of fuel! Put fuel in inventory and rerun.")
  return false
end

-- Select an item slot by (partial) name match
local function findItemByName(part)
  for i = 1, 16 do
    local d = turtle.getItemDetail(i)
    if d and d.name and (d.name == part or string.find(d.name, part, 1, true)) then
      return i
    end
  end
  return nil
end

-- Try to place using preferred blocks, else any placeable
local function tryPlace(placeFn)
  local back = turtle.getSelectedSlot()

  -- First, try preferred
  for _, name in ipairs(preferredBlocks) do
    local slot = findItemByName(name)
    if slot then
      turtle.select(slot)
      if placeFn() then
        turtle.select(back)
        return true
      end
    end
  end

  -- Fallback: try everything that can place
  for i = 1, 16 do
    local d = turtle.getItemDetail(i)
    if d then
      turtle.select(i)
      if placeFn() then
        turtle.select(back)
        return true
      end
    end
  end

  turtle.select(back)
  return false
end

-- Dig/attack until front is clear
local function clearFront()
  local tries = 0
  while turtle.detect() do
    turtle.dig()
    sleepShort()
    tries = tries + 1
    if tries > 50 then break end
  end
end

-- Move forward, dealing with blocks/mobs
local function forwardSafe()
  local tries = 0
  while not turtle.forward() do
    if turtle.detect() then
      turtle.dig()
    else
      turtle.attack()
    end
    sleepShort()
    tries = tries + 1
    if tries > 100 then return false end
  end
  return true
end

-- Clear above block(s)
local function clearUp()
  local tries = 0
  while turtle.detectUp() do
    turtle.digUp()
    sleepShort()
    tries = tries + 1
    if tries > 30 then break end
  end
end

-- Clear one side (left or right), then place a block there if empty (acts like a side rail)
local function clearAndRail(side)
  if side == "left" then turtle.turnLeft() else turtle.turnRight() end

  -- Clear the side at turtle level
  local c = 0
  while turtle.detect() do
    turtle.dig()
    sleepShort()
    c = c + 1
    if c > 30 then break end
  end

  -- If still empty, place a block (creates a side wall/rail)
  if not turtle.detect() then
    -- Place onto the side face of the floor under us (ensure floor exists first)
    tryPlace(function() return turtle.place() end)
  end

  if side == "left" then turtle.turnRight() else turtle.turnLeft() end
end

-- Ensure there's a block under the turtle
local function ensureFloor()
  if not turtle.detectDown() then
    if not tryPlace(function() return turtle.placeDown() end) then
      print("No blocks to place for floor! Put cobble/netherrack in inventory.")
      error("stopping")
    end
  end
end

-- One repeatable step: mine forward, move, make floor, clear up, clear/rail sides
local function step()
  clearFront()
  if not forwardSafe() then
    error("Can't move forward.")
  end

  -- Put a block under us (for bridging)
  ensureFloor()

  -- Clear space above for walking
  clearUp()

  -- Clear left/right and add side blocks if empty
  clearAndRail("left")
  clearAndRail("right")
end

-- MAIN
if not refuelIfNeeded(length + 5) then return end

for i = 1, length do
  -- Keep topping up fuel just in case
  if not refuelIfNeeded(length - i + 3) then return end

  local ok, err = pcall(step)
  if not ok then
    print("Stopped at step " .. i .. ": " .. tostring(err))
    return
  end
end

print("Done! Built " .. length .. " blocks.")
