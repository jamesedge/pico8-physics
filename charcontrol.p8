pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- character controller
--[[
this code demonstrates how to set up a dynamic character controller
]]

-->8

--[[

-- directions
RIGHT = 0x01
LEFT  = 0x02
UP    = 0x03
DOWN  = 0x04

-- states
STANDING  = 0x00
RIGHT     = 0x01
LEFT      = 0x02
JUMPING   = 0x04
FALLING   = 0x08
PUSHING   = 0x10

]]--

function charcontroller(scene, args)
  args = args or {}

  local listener, leftkey, rightkey, jumpkey =
    args.listener, args.leftkey or 0, args.rightkey or 1, args.jumpkey or 4
  local ground_speed, jump_speed = args.ground_speed or 5, args.jump_speed or 5
  local drift_speed = args.drift_speed or ground_speed/2
  local jump_count, ground_count, hang_count, contacts, directions, forward, px, py, mvx, mvy, bodyid =
    0, 0, 0, {}, { 0, 0, 0, 0 }, 0, 0, 0, 0, 0

  local function is_grounded() return ground_count<2 end
  local function is_hanging() return not is_grounded() and hang_count<2 end -- used for wall jumps

  -- move, dir=-1 (left), dir=1 (right)
  -- walk if grounded, drift if not
  local function move(dir)
    local vx, speed = scene.velocity(bodyid), is_grounded() and ground_speed or is_hanging() and 0 or drift_speed
    scene.apply_impulse(bodyid, dir*max(0, speed-dir*vx), 0, 0)
  end

  -- jump/double-jump/wall jump
  local function jump()
    local vx, vy = scene.velocity(bodyid)
    if is_grounded() then jump_count=1 scene.apply_impulse(bodyid, 0, jump_speed, 0)
    elseif is_hanging() then
      local dx, dy = directions[2]>0 and -0.3 or 0.3, 0.6
      local len = sqrt(dx*dx+dy*dy)
      dx /= len dy /= len
      jump_count += 1
      scene.apply_impulse(bodyid, dx*jump_speed, dy*jump_speed, 0)
    elseif vy<=0 and jump_count<2 then
      jump_count+=1
      scene.apply_impulse(bodyid, 0, jump_speed, 0)
    end
  end

  local self
  self = {
    id=function() return bodyid end,
    state=function() -- returns the state of the character
      if (abs(mvx)<0x0.01 and abs(mvy)<0x0.01) return 0x00
      return (forward>0 and 0x01 or 0x02)+
             (not is_grounded() and (mvy>0x0.01 and 0x04 or mvy<-0x0.01 and 0x08 or 0x00) or 0x00)+
             (((forward>0 and directions[2]>0) or (forward<0 and directions[1]>0)) and 0x10 or 0x00)
    end,
    contact=function() -- returns which directions the character is in contact
      return (direction[1]>0 and 0x01 or 0x00)+(direction[2]>0 and 0x02 or 0x00)+
             (direction[3]>0 and 0x04 or 0x00)+(direction[4]>0 and 0x08 or 0x00)
    end,
    left=function() move(-1) end, -- move left
    right=function() move(1) end, -- move right
    jump=jump,
    is_grounded=is_grounded,
    is_hanging=is_hanging,
    on_event=function(args) -- handle contacts
      if args.event==0x01 then
        local cid, nx, ny, maxv, dir = args.cid, args.nx, args.ny, 0x8000, 0
        for i,v in pairs({ nx, -nx, -ny, ny }) do if (v>maxv) maxv, contacts[cid] = v, i end
        directions[contacts[cid]] += 1
        if contacts[cid]==4 then ground_count=0 elseif contacts[cid]<3 then hang_count=0 end
      elseif args.event==0x02 then
        local cid = args.cid
        directions[contacts[cid]] -= 1
        contacts[cid] = nil
      end
      if (listener) listener.on_event(args) -- forward events to listener
    end,
    update=function() -- call once per frame
      local x, y = scene.position(bodyid)
      mvx, mvy, px, py = x-px, y-py, x, y

      if (directions[4]==0) ground_count = ground_count%0x7fff+1
      if (directions[1]+directions[2]==0) hang_count = hang_count%0x7fff+1

      -- set facing direction
      if (btn(0) or btn(1)) forward = (btn(0) and -1 or 0)+(btn(1) and 1 or 0)

      -- handle inputs
      if btnp(4) then jump()
      elseif btn(0) or btn(1) then move(forward) end
    end
  }

  bodyid = scene.add_body{ x=args.x or 0, y=args.y or 0, mass=args.mass, moi=0, rest=0, frict=1,
                           verts=args.verts or capsule(0.5, 0.5, 8), listener=self }
  px, py = scene.position(bodyid)

  return self
end
