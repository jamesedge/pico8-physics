pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- core physics
--[[
core physics code
]]

-->8
-- aabb

function aabb(x1, y1, x2, y2)
  local self
  self = {
    x1=x1 or 0x7fff, y1=y1 or 0x7fff,
    x2=x2 or 0x8000, y2=y2 or 0x8000,
    set=function(x1, y1, x2, y2)
      self.x1, self.y1, self.x2, self.y2 =
        x1 or 0x7fff, y1 or 0x7fff, x2 or 0x8000, y2 or 0x8000
    end,
    overlaps=function(b)
      return self.x2>=b.x1 and self.x1<=b.x2 and
             self.y2>=b.y1 and self.y1<=b.y2
    end,
    contains=function(b)
      return b.x1>=self.x1 and b.y1>=self.y1 and
             b.x2<=self.x2 and b.y2<=self.y2
    end
  }
  return self
end

-->8
-- viewport
--[[
viewport allows transformations between world space (metres), and screen space (pixels)
params:
args - table of optional parameters
ox, oy - origin in screen space
scale - pixels per metre
]]

function viewport(args)
  args = args or {}

  local scale = args.scale or 16
  local m11, m12, m13, m21, m22, m23 =
    scale, 0, args.ox or 64,
    0, -scale, args.ox or 64

  return {
    translate=function(tx, ty)
      --tx/=scale ty/=scale
      m13, m23 = m11*tx+m12*ty+m13, m21*tx+m22*ty+m23
    end,
    scale=function(s) scale*=s m11*=s m12*=s m21*=s m22*=s end,
    to_screen=function(x, y) -- converts metres to pixels
      return m11*x+m12*y+m13, m21*x+m22*y+m23
    end
  }
end

-->8
-- scene
--[[
scene stores all information/functionality for a physics scene.
measurements in a scene are in SI units, metres/kg
params:
args - table of optional parameters
g - gravity
slop - allowed overlap before collision response
damp - damping
isteps - solver steps
sframes - frames before bodies are put to sleep
beta - for baumgarte stabilisation, proportion of positional correction
size - the size of the simulation area, bodies outside this region are killed
]]

--[[
-- ids for events
ON_COLLISION_ENTER  = 0x01
ON_COLLISION_EXIT   = 0x02
ON_BODY_SLEEP       = 0x03
ON_BODY_WAKE        = 0x04
ON_BODY_DEAD        = 0x05
]]--

function scene(args)
  args = args or {}

  local size = args.size or 10
  local g, slop, damp, isteps, sframes, beta, cmanager, box, constraints, forces =
    args.g or -9.8, args.slop or 0x0.08, args.damp or 1, args.isteps or 4, args.sframes or 100, args.beta or 0.2,
    sweep_and_prune(), aabb(-size, -size, size, size), {}, {}
  local nextid, alive, dead, awake, dynamic, x, y, a, vx, vy, va, mass, imass, imoi,
    geom, layer, rest, frict, contact_ids, listeners,
    island, island_vx, island_vy, island_va, island_count, island_sframes =
    1, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}

  local function send_messages(args)
    foreach(args, function(evt)
      if (listeners[evt.id]) listeners[evt.id].on_event(evt)
    end)
  end
  local function find(id) return id==island[id] and id or find(island[id]) end
  local function union(id1, id2) id2, id1 = minmax(find(id1), find(id2)) island[id1] = id2 end

  --[[
  removes a body from the system
  params:
  id - id of the body
  ]]
  local function remove_body(id)
    send_messages{ { id=id, event=0x05 } }
    dead[id], alive[id], geom[id], listeners[id] = true
    for cid in pairs(contact_ids) do -- remove contact ids
      if (id==shr(band(cid, 0xff00), 8) or id==band(cid, 0xff)) contact_ids[cid] = nil
    end
    cmanager.remove_body(id)
  end

  --[[
  identifies if a body is awake
  params:
  id - id of the body
  ]]
  local function is_awake(id) return dynamic[id] and awake[find(id)] end

  local function sleep(id)
    local isle = island[id]
    if awake[isle] then
      island_sframes[isle], awake[isle] = 0
      for id in pairs(alive) do if (island[id]==isle) send_messages{ { id=id, event=0x03 } } end
    end
  end

  local function wake(id)
    local isle = island[id]
    if not awake[isle] and dynamic[isle] then
      awake[isle] = true
      for id in pairs(alive) do if (island[id]==isle) send_messages{ { id=id, event=0x04 } } end
    end
  end

  --[[
  apply a force to a body
  params:
  id - id of the body
  dt - time step
  fx, fy - force in x, y direction
  px, py - point at which force is applied
  ]]
  local function apply_force(id, dt, fx, fy, px, py)
    wake(id)
    px, py = px and px-x[id] or 0, py and py-y[id] or 0
    vx[id] += fx*imass[id]*dt
    vy[id] += fy*imass[id]*dt
    va[id] -= (fx*py-fy*px)*imoi[id]*dt
    return vx[id], vy[id], va[id]
  end

  --[[
  apply an impulse to a body
  params:
  id - id of the body
  px, py, pa - x, y, angular components of the impulse
  ]]
  local function apply_impulse(id, px, py, pa)
    wake(id)
    vx[id] += px*imass[id]
    vy[id] += py*imass[id]
    va[id] += pa*imoi[id]
    return vx[id], vy[id], va[id]
  end

  -- contact solver
  local function contact(id1, id2, nx, ny)
    local lambdan, lambdat, r, f, jn3, jn6, jmn, b, jt3, jt6, jmt =
      0, 0, 0.5*(rest[id1]+rest[id2]), sqrt(frict[id1]*frict[id2])

    return {
      eval=function(dt, dist, px1, py1, px2, py2)
        local rx1, ry1, rx2, ry2, vx1, vy1, va1, vx2, vy2, va2, imass1, imoi1, imass2, imoi2 =
          zero(px1-x[id1]), zero(py1-y[id1]), zero(px2-x[id2]), zero(py2-y[id2]),
          vx[id1], vy[id1], va[id1], vx[id2], vy[id2], va[id2],
          imass[id1], imoi[id1], imass[id2], imoi[id2]

        jn3, jn6 = rx1*ny-ry1*nx, ry2*nx-rx2*ny

        if (nx*vx1+ny*vy1+jn3*va1-nx*vx2-ny*vy2+jn6*va2>=0) return false

        -- warmstart
        if abs(lambdan)+abs(lambdat)>0 then
          local px, py = nx*lambdan-ny*lambdat, ny*lambdan+nx*lambdat
          vx1, vy1, va1 = apply_impulse(id1, px, py, rx1*py-ry1*px)
          vx2, vy2, va2 = apply_impulse(id2, -px, -py, ry2*px-rx2*py)
        end

        local nx2, ny2 = nx^2, ny^2
        jmn, b = nx2*imass1+ny2*imass1+jn3*imoi1*jn3+nx2*imass2+ny2*imass2+jn6*imoi2*jn6,
                 -(beta/dt)*dist+r*min(0, ((vx1-py1*va1)-(vx2-py2*va2))*nx+
                                          ((vy1+px1*va1)-(vy2-px2*va2))*ny)

        jt3, jt6 = rx1*nx+ry1*ny, -(rx2*nx+ry2*ny)
        jmt = ny2*imass1+nx2*imass1+jt3*imoi1*jt3+ny2*imass2+nx2*imass2+jt6*imoi2*jt6

        return true
      end,
      solve=function()
        local vx1, vy1, va1, vx2, vy2, va2, deln, delt =
          vx[id1], vy[id1], va[id1], vx[id2], vy[id2], va[id2]

        deln = max(lambdan-(nx*vx1+ny*vy1+jn3*va1-nx*vx2-ny*vy2+jn6*va2+b)/jmn, 0)-lambdan
        lambdan += deln

        delt = mid(-f*lambdan, lambdat-(-ny*vx1+nx*vy1+jt3*va1+ny*vx2-nx*vy2+jt6*va2)/jmt, f*lambdan)-lambdat
        lambdat += delt

        apply_impulse(id1, deln*nx-delt*ny, deln*ny+delt*nx, deln*jn3+delt*jt3)
        apply_impulse(id2, delt*ny-deln*nx, -deln*ny-delt*nx, deln*jn6+delt*jt6)

        return deln^2+delt^2<0x0.001
      end
    }
  end

  local contacts, prev_contacts = {}, {}

  return {
    --[[
    adds a body to the system
    params:
    args - table of optional parameters
    x, y, a - position and rotation of the body
    mass - mass of the body, 0 indicates infinite mass
    moi - inertia of the body, 0 indicates infinite inertia
    rest - restitution
    frict - friction
    layer - which layer/layers the object is present in
    verts - table containing geometry
    listener - table containing an on_event(args) method for events
    ]]
    add_body=function(args)
      args = args or {}

      local id = next(dead)
      if (id) dead[id] = nil else id = nextid nextid += 1

      local verts = args.verts and args.verts or rectangle(1, 1)
      mass[id], geom[id] = args.mass or 1, geometry(verts.numv, verts.x, verts.y)
      local moi = args.moi

      if not moi then
        moi = 0
        if mass[id]>0 then
          local nv, vx, vy = geom[id].numv
          for i=1,nv do
            vx, vy = geom[id].x[i], geom[id].y[i]
            moi += vx^2+vy^2
          end
          moi *= mass[id]/nv
        end
      end

      dynamic[id] = mass[id]>0 or moi>0

      alive[id], awake[id], island[id], island_sframes[id],
        x[id], y[id], a[id], vx[id], vy[id], va[id],
        imass[id], imoi[id], layer[id], rest[id], frict[id], listeners[id] =
        true, dynamic[id] or nil, id, 0,
        args.x or 0, args.y or 0, args.a or 0, 0, 0, 0,
        mass[id]>0 and 1/mass[id] or 0, moi>0 and 1/moi or 0,
        args.layer or 255, args.rest or 0.1, args.frict or 1,
        args.listener or nil

      geom[id].transform(x[id], y[id], a[id])
      cmanager.add_body(id, geom[id].aabb)

      return id
    end,
    remove_body=remove_body,
    position=function(id) return x[id], y[id], a[id] end, -- returns position/angle of a body
    velocity=function(id) return vx[id], vy[id], va[id] end, -- returns velocity of a body
    mass=function(id) return mass[id] end,
    inv_mass=function(id) return imass[id], imoi[id] end, -- returns inverse mass/inertia of a body
    is_dynamic=function(id) return dynamic[id] end, -- returns true if the body reacts to forces
    add_constraint=function(c) constraints[#constraints+1] = c end,
    add_force=function(f) forces[#forces+1] = f end,
    apply_force=apply_force,
    apply_impulse=apply_impulse,
    update=function(dt) -- update function called once per frame
      dt = dt or 1/stat(7)
      local solvers, id1, id2, cid, rid, dist, nx, ny, x1, y1, x2, y2 = {}

      -- apply gravity and initialise islands
      for id in pairs(alive) do
        if is_awake(id) then
          awake[id], island[id], island_vx[id], island_vy[id], island_va[id], island_count[id] =
            true, id, 0, 0, 0, 0
          apply_force(id, dt, 0, g*mass[id])
        end
      end

      -- apply forces
      foreach(forces, function(f) f.apply(dt) end)

      -- initialise constraints
      foreach(constraints, function(c)
        if(c.eval(dt)) solvers[#solvers+1] = c
      end)

      -- compute contacts, create solvers (including warmstarting)
      contacts, prev_contacts = prev_contacts, contacts
      while cmanager.has_more() do
        id1, id2 = cmanager.next()
        if band(layer[id1], layer[id2])>0 and (is_awake(id1) or is_awake(id2)) then
          rid, dist, nx, ny, x1, y1, x2, y2 = geom[id1].collides(geom[id2])
          if rid then
            wake(id1) wake(id2)
            if (dynamic[id1] and dynamic[id2]) union(id1, id2)
            cid = shl(id1, 8)+id2+shr(rid, 16)
            contacts[cid], prev_contacts[cid] = prev_contacts[cid]
            if dist>slop then
              if not contacts[cid] then
                contacts[cid] = contact(id1, id2, nx, ny)
                if not contact_ids[cid] then
                  contact_ids[cid] = true
                  send_messages{ { id=id1, event=0x01, cid=cid, body=id2, x=x1, y=y1, nx=nx, ny=ny },
                                 { id=id2, event=0x01, cid=cid, body=id1, x=x2, y=y2, nx=-nx, ny=-ny } }
                end
              end
              if (contacts[cid].eval(dt, dist-slop, x1, y1, x2, y2)) solvers[#solvers+1] = contacts[cid]
            end
          end
        end
      end

      -- free all old contacts
      for cid,c in pairs(prev_contacts) do
        id1, id2 = shr(band(cid, 0xff00), 8), band(cid, 0xff)
        if is_awake(id1) or is_awake(id2) then
          contact_ids[cid] = nil
          send_messages{ { id=id1, cid=cid, event=0x02, body=id2 },
                         { id=id2, cid=cid, event=0x02, body=id1 } }
        end
        prev_contacts[cid] = nil
      end

      -- solve all constraints
      for i=1,isteps do
        for j,s in pairs(solvers) do if (s.solve()) solvers[j] = nil end
        if (#solvers==0) break -- if no constraints remain end early
      end

      -- integrate velocities, transform bodies, compute island information
      -- remove bodies outside of simulation area
      for id in pairs(alive) do
        if is_awake(id) then
          local isle = find(id)
          awake[id], island[id] = id==isle and true or nil, isle
          x[id] += vx[id]*dt
          y[id] += vy[id]*dt
          a[id] += va[id]*dt
          island_vx[isle] += vx[id]^2
          island_vy[isle] += vy[id]^2
          island_va[isle] += va[id]^2
          island_count[isle] += 1
          vx[id] *= damp
          vy[id] *= damp
          va[id] *= damp
          geom[id].transform(x[id], y[id], a[id])

          if (box.overlaps(geom[id].aabb)) cmanager.update_body(id, geom[id].aabb) else remove_body(id)
        end
      end

      -- sleep islands with low movement
      for id in pairs(awake) do
        local count = island_count[id]
        local ivx, ivy, iva = island_vx[id]/count, island_vy[id]/count, island_va[id]/count
        island_sframes[id] = ivx+ivy+iva<0x0.4 and island_sframes[id]+1 or 0
        if (island_sframes[id]>sframes) sleep(id)
      end
    end,
    draw=function(vp)
      for id in pairs(alive) do
        color(island[id]%7+8)
        local cx, cy = vp.to_screen(x[id], y[id])
        local upy, upx = cos_sin(a[id])
        upx *= 2 upy *= 2
        line(cx-upx, cy-upy, cx+upx, cy+upy)
        line(cx-upy, cy+upx, cx+upy, cy-upx)
        geom[id].draw(vp)
      end
    end
  }
end

-->8
-- shape functions

--[[
creates an ngon
params:
r - radius
nv - num vertices
sx, sy - scale in x/y directions
ox, oy - offset
]]
function ngon(r, nv, sx, sy, ox, oy)
  sx, sy, ox, oy = r*(sx or 1), r*(sy or 1), ox or 0, oy or 0
  local x, y, angle, da = {}, {}, (nv==4) and 0x0.c90c or 0, -0x6.487e/nv
  for i=1,nv do
    x[i], y[i] = transform(1, 0, ox, oy, angle)
    x[i] *= sx y[i] *= sy
    angle += da
  end
  return { numv=nv, x=x, y=y }
end

function triangle(w, h, ox, oy) return ngon(0x1.6109, 3, w/2, h/2, ox, oy) end
function rectangle(w, h, ox, oy) return ngon(0x1.6109, 4, w/2, h/2, ox, oy) end

function capsule(w, h, nv, ox, oy)
  nv += nv%2

  local sphere = ngon(w/2, nv, 1, 1, ox, oy)
  local numv, sx, sy, x, y = sphere.numv, sphere.x, sphere.y, {}, {}

  for i=1,nv/2+1 do x[#x+1], y[#y+1] = sx[i], sy[i]-h/2 end
  x[#x+1], y[#y+1] =  sx[nv/2+1], sy[nv/2+1]+h/2
  for i=nv/2+2,nv do x[#x+1], y[#y+1] = sx[i], sy[i]+h/2 end
  x[#x+1], y[#y+1] =  sx[1], sy[1]+h/2

  return { numv=nv+2, x=x, y=y }
end
