-- bridge.lua - CC:Tweaked (MC 1.20.1)
-- Usage: bridge [length]
-- Builds a straight path: dig forward, move, put floor,
-- clear above, clear left/right and place side blocks if empty.

local tArgs = { ... }
local LENGTH = tonumber(tArgs[1]) or 25

-- Preferred building blocks
local preferred = {
  "minecraft:cobblestone",
  "minecraft:netherrack",
  "cobblestone",
  "netherrack",
}

local function haveUnlimitedFuel()
  return turtle.getFuelLevel() == "unlimited"
end

local function ensureFuel(minFuel)
  if haveUnlimitedFuel() then return true end
  if turtle.getFuelLevel() >= minFuel then return true end
  for i = 1, 16 do
    if turtle.getItemCount(i) > 0 then
      turtle.select(i)
      if turtle.refuel(0) then
        turtle.refuel()
        if turtle.getFuelLevel() >= minFuel then return true end
      end
    end
  end
  print("Out of fuel. Add fuel and rerun.")
  return false
end

local function findPlaceableSlot()
  -- try preferred names first
  for _, name in ipairs(preferred) do
    for i = 1, 16 do
      local d = turtle.getItemDetail(i)
      if d and d.name and (d.name == name or string.find(d.name, name, 1, true)) then
        return i
      end
    end
  end
  -- fallback: any item that can place
  for i = 1, 16 do
    if turtle.getItemCount(i) > 0 then return i end
  end
  return nil
end

local function digFrontAll()
  while turtle.detect() do
    turtle.dig()
    sleep(0)
  end
end

local function forwardSafe()
  local tries = 0
  while not turtle.forward() do
    if turtle.detect() then turtle.dig() else turtle.attack() end
    tries = tries + 1
    if tries > 50 then return false end
    sleep(0)
  end
  return true
end

local function digUpAll()
  while turtle.detectUp() do
    turtle.digUp()
    sleep(0)
  end
end

local function ensureFloor()
  if turtle.detectDown() then return true end
  local slot = findPlaceableSlot()
  if not slot then return false end
  turtle.select(slot)
  return turtle.placeDown()
end

local function clearAndPlaceSide(side)
  if side == "left" then turtle.turnLeft() else turtle.turnRight() end

  -- clear side block at head level
  while turtle.detect() do
    turtle.dig()
    sleep(0)
  end

  -- if side is empty, place a block (acts like a rail/wall)
  if not turtle.detect() then
    local slot = findPlaceableSlot()
    if slot then
      turtle.select(slot)
      turtle.place()
    end
  end

  if side == "left" then turtle.turnRight() else turtle.turnLeft() end
end

-- MAIN
if not ensureFuel(LENGTH + 5) then return end

for i = 1, LENGTH do
  digFrontAll()
  if not forwardSafe() then
    print("Blocked moving forward at step " .. i)
    return
  end

  if not ensureFloor() then
    print("No blocks to place for floor at step " .. i)
    return
  end

  digUpAll()
  clearAndPlaceSide("left")
  clearAndPlaceSide("right")

  -- keep topping up if we find fuel later in inventory
  if not ensureFuel(LENGTH - i + 3) then return end
end

print("Done: built " .. LENGTH .. " blocks.")
