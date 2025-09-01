-- bridge.lua
-- Usage: bridge <steps>
-- Builds a straight bridge: places blocks below, left, and right of the turtle.

if not turtle then
  print("This program must be run on a Turtle.")
  return
end

local function sleepCompat(t)  -- CC/Tweaked has sleep(); old CC uses os.sleep()
  if sleep then sleep(t) else os.sleep(t or 0.05) end
end

-- Pick any inventory slot that has something in it
local function selectNextItemSlot()
  for s = 1, 16 do
    if turtle.getItemCount(s) > 0 then
      turtle.select(s)
      return true
    end
  end
  return false
end

-- Try to refuel a bit if we're low, using any burnable in inventory.
local function ensureFuel(minNeeded)
  local lvl = turtle.getFuelLevel()
  if lvl == "unlimited" then return true end
  if lvl >= minNeeded then return true end

  -- hunt for fuel
  for s = 1, 16 do
    if turtle.getItemCount(s) > 0 then
      local detail = turtle.getItemDetail(s)
      if detail and detail.name then
        -- very permissive: try to refuel with anything; ignore errors
        turtle.select(s)
        local ok = turtle.refuel(1)  -- eat one item at a time
        if ok then
          if turtle.getFuelLevel() >= minNeeded then return true end
        end
      end
    end
  end
  return turtle.getFuelLevel() >= minNeeded
end

-- Place a block in a given direction if air.
-- placeFn: turtle.place / placeDown; detectFn: turtle.detect / detectDown
local function placeIfAir(placeFn, detectFn)
  -- If something is already there, do nothing.
  if detectFn() then return true end

  -- We need an item selected that is placeable. Iterate inventory if needed.
  local tries = 0
  while tries < 16 do
    if turtle.getItemCount() == 0 then
      if not selectNextItemSlot() then return false end
    end
    local ok, err = placeFn()
    if ok then return true end

    -- If we had no items or they weren't placeable, switch slot and try again.
    if err == "No items to place" or err == "Item is not placeable" or turtle.getItemCount() == 0 then
      if not selectNextItemSlot() then return false end
    else
      -- Some other transient issue (entity/liquid), just give up gracefully.
      return false
    end
    tries = tries + 1
  end
  return false
end

local function placeBelowLeftRight()
  -- below
  placeIfAir(turtle.placeDown, turtle.detectDown)

  -- left
  turtle.turnLeft()
  placeIfAir(turtle.place, turtle.detect)
  turtle.turnRight()

  -- right
  turtle.turnRight()
  placeIfAir(turtle.place, turtle.detect)
  turtle.turnLeft()
end

local function forwardDigSafe()
  local n = 0
  while not turtle.forward() do
    if turtle.detect() then turtle.dig() end
    turtle.attack()
    n = n + 1
    if n > 20 then return false end
    sleepCompat(0.1)
  end
  return true
end

-- ===== main =====
local args = { ... }
local steps = tonumber(args[1] or "")
if not steps or steps < 1 then
  print("Usage: bridge <steps>")
  return
end

-- Make sure we have enough fuel (roughly: steps + some turns/overhead)
if not ensureFuel(steps + 10) then
  print("Warning: low fuel. Attempting anyway…")
end

-- Place around the starting tile too
placeBelowLeftRight()

for i = 1, steps do
  if not forwardDigSafe() then
    print(("Stopped: couldn't move forward at step %d."):format(i))
    break
  end
  ensureFuel(steps - i + 5)  -- top up opportunistically
  placeBelowLeftRight()
end

print("Done.")
