```C:\Users\wkapl\ComputerCraft Copilot\main.lua#L1-260
-- main.lua
-- Strip Miner: Automates making 1-wide, 2-high tunnels for a set distance,
-- returns to start, shifts over, and repeats for multiple tunnels.
--
-- Save this as main.lua on your turtle and run it with optional arguments:
--   lua main.lua <length> <numTunnels> <gap> <torchInterval> <torchSlot>
-- Example:
--   lua main.lua 30 6 3 12 16
--
-- Defaults:
local DEFAULT_LENGTH     = 20   -- blocks per tunnel
local DEFAULT_TUNNELS    = 4    -- number of parallel tunnels to dig
local DEFAULT_GAP        = 3    -- blocks to move right between tunnel starts
local DEFAULT_TORCH_INT  = 12   -- place a torch every N blocks (0 to disable)
local DEFAULT_TORCH_SLOT = 16   -- inventory slot to hold torches (1..16)
local MAX_SLOT           = 16


-- Utility helpers

-- Sleep compatibility for CC (sleep) and CC:Tweaked (os.sleep)
local function pause(sec)
  sec = sec or 0.05
  if os and os.sleep then
    os.sleep(sec)
  elseif type(sleep) == "function" then
    sleep(sec)
  else
    -- very short busy-wait fallback
    local t0 = os.clock and os.clock() or 0
    while (os.clock and (os.clock() - t0) < (sec or 0.05)) do end
  end
end


local function selectSlotWithItem(startSlot)
  startSlot = startSlot or 1
  for s = startSlot, MAX_SLOT do
    if turtle.getItemCount(s) > 0 then
      turtle.select(s)
      return s
    end
  end
  for s = 1, startSlot - 1 do
    if turtle.getItemCount(s) > 0 then
      turtle.select(s)
      return s
    end
  end
  return nil
end

local function isInventoryFull()
  for s = 1, MAX_SLOT do
    if turtle.getItemCount(s) == 0 then
      return false
    end
  end
  return true
end

local function ensureFuel(minNeeded)
  minNeeded = minNeeded or 1
  local level = turtle.getFuelLevel()
  if level == "unlimited" or level >= minNeeded then return true end
  -- try to refuel from inventory
  local cur = turtle.getSelectedSlot()
  for s = 1, MAX_SLOT do
    if turtle.getItemCount(s) > 0 then
      turtle.select(s)
      -- try refuel with one item at a time until level sufficient or slot empty
      while turtle.getItemCount(s) > 0 and turtle.getFuelLevel() < minNeeded do
        if not turtle.refuel(1) then break end
      end
      if turtle.getFuelLevel() >= minNeeded then
        turtle.select(cur or 1)
        return true
      end
    end
  end
  turtle.select(cur or 1)
  return turtle.getFuelLevel() >= minNeeded
end


local function safeForward()
  while not turtle.forward() do
    if turtle.detect() then

      turtle.dig()

      pause(0.1)
    else
      -- Possibly a mob/entity blocking the way; try attacking then wait briefly
      turtle.attack()
      pause(0.2)
    end
  end
  return true
end



local function safeUp()

  while not turtle.up() do

    if turtle.detectUp() then

      turtle.digUp()

      pause(0.1)
    else
      turtle.attackUp()
      pause(0.2)
    end
  end
  return true
end



local function safeDown()

  while not turtle.down() do

    if turtle.detectDown() then

      turtle.digDown()

      pause(0.1)
    else
      turtle.attackDown()
      pause(0.2)
    end
  end
  return true
end


local function turnAround()
  turtle.turnLeft()
  turtle.turnLeft()
end

-- Torch placement
local function placeTorchIfConfigured(step, torchInterval, torchSlot)
  if torchInterval <= 0 then return end
  if torchSlot < 1 or torchSlot > MAX_SLOT then return end
  if (step % torchInterval) ~= 0 then return end
  if turtle.getItemCount(torchSlot) == 0 then return end
  local cur = turtle.getSelectedSlot()
  turtle.select(torchSlot)

    -- Prefer placing on the ground (down). If that fails, try left wall, then right wall.
    if not turtle.placeDown() then

      turtle.turnLeft()
      if not turtle.place() then
        turtle.turnRight()
        turtle.turnRight()
        turtle.place()
        turtle.turnLeft()
      else
        turtle.turnRight()
      end
    end
    turtle.select(cur)

end

-- Mine a 1x2 tunnel forward for `length` blocks.
-- Assumptions:
--   - Turtle starts at the tunnel's start cell, standing on floor, facing forward.
-- After completion:
--   - Turtle ends at the far end of the tunnel (having moved `length` steps forward).
-- Returns true if finished, false if stopped due to out-of-fuel or full-inventory.
local function mineTunnel(length, torchInterval, torchSlot)
  for i = 1, length do
    -- Ensure headroom is clear
    if turtle.detectUp() then turtle.digUp() end
    if turtle.detect() then turtle.dig() end

    if not safeForward() then
      print("Unable to move forward at step", i)
      return false
    end

    -- clear above in the new cell too (in case something fell after moving)
    if turtle.detectUp() then turtle.digUp() end

    placeTorchIfConfigured(i, torchInterval, torchSlot)

    -- periodic checks
    if not ensureFuel(1) then
      print("Out of fuel while tunneling at step", i)
      return false
    end
    if isInventoryFull() then
      print("Inventory full while tunneling at step", i)
      return false
    end
  end
  return true
end


local function returnToStart(length)
  turnAround()
  for i = 1, length do
    if not ensureFuel(1) then
      print("Out of fuel while returning to start at step", i)
      turnAround()
      return false
    end
    if turtle.detect() then turtle.dig() end

    safeForward()

  end

  turnAround() -- face original direction

  return true
end



local function moveRight(gap)
  if gap <= 0 then return true end
  turtle.turnRight()
  for i = 1, gap do
    if not ensureFuel(1) then
      print("Out of fuel while moving to next tunnel at step", i)
      turtle.turnLeft()
      return false
    end
    if turtle.detect() then turtle.dig() end

    safeForward()

  end

  turtle.turnLeft()

  return true
end


-- Print usage
local function usage()
  print("Usage: lua main.lua <length> <numTunnels> <gap> [torchInterval] [torchSlot]")
  print("  length: blocks per tunnel (>=1)")
  print("  numTunnels: number of tunnels to dig (>=1)")
  print("  gap: lateral gap (blocks) to move right between tunnel starts (>=0)")
  print("  torchInterval: place torch every N blocks (0 to disable) (optional)")
  print("  torchSlot: inventory slot with torches (1..16) (optional)")
end

-- Parse args
local args = { ... }
local length = tonumber(args[1]) or DEFAULT_LENGTH
local numTunnels = tonumber(args[2]) or DEFAULT_TUNNELS
local gap = tonumber(args[3]) or DEFAULT_GAP
local torchInterval = tonumber(args[4]) or DEFAULT_TORCH_INT
local torchSlot = tonumber(args[5]) or DEFAULT_TORCH_SLOT

-- validate
if length < 1 or numTunnels < 1 or gap < 0 or torchSlot < 1 or torchSlot > MAX_SLOT then
  usage()
  return
end

-- Check basic fuel
if not ensureFuel(1) then
  print("No fuel available. Please add fuel to the turtle inventory and try again.")
  return
end

print(string.format("Strip miner starting: length=%d, tunnels=%d, gap=%d, torchEvery=%d (slot %d)",
      length, numTunnels, gap, torchInterval, torchSlot))
print("Place the turtle at the first start position, facing the direction you want tunnels to go.")
print("Press Enter to begin, or Ctrl+T to cancel.")
read() -- wait for player to start

-- Main loop
for t = 1, numTunnels do
  print(string.format("Starting tunnel %d of %d...", t, numTunnels))
  local ok = mineTunnel(length, torchInterval, torchSlot)
  if not ok then
    print("Stopping early. Tunnel:", t)
    break
  end


  -- At far end; return to start

  print("Returning to start...")

  local backOk = returnToStart(length)

  if not backOk then

    print("Stopped while returning to start.")
    break
  end

  -- If more tunnels remain, move right by gap and continue

  if t < numTunnels then

    print(string.format("Moving right %d blocks to next start...", gap))

    local moved = moveRight(gap)

    if not moved then
      print("Stopped while shifting to next tunnel.")
      break
    end
  end

end

print("Completed (or stopped). Turtle located at final start position, facing original direction.")
print("Remember to collect items and refuel as needed.")
