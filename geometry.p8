pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- geometry
--[[
geometry for collision detection, uses SAT for collisions
]]

-->8
-- convex geometry collider

function geometry(numv, vx, vy)
  local tvx, tvy, nx, ny, tnx, tny, maxp, box =
    {}, {}, {}, {}, {}, {}, {}, aabb()

  for i=1,numv do tvx[i], tvy[i] = vx[i], vy[i] end

  local x1, y1, x2, y2, len = vx[1], vy[1]
  for i=1,numv do
    x2, y2 = vx[i%numv+1], vy[i%numv+1]
    nx[i], ny[i] = -(y2-y1), x2-x1
    len = sqrt(nx[i]*nx[i]+ny[i]*ny[i])
    nx[i] /= len ny[i] /= len
    x1, y1, idx1 = x2, y2, idx2
  end

  return {
    x=tvx, y=tvy,
    nx=tnx, ny=tny,
    maxp=maxp,
    num_vertex=function() return numv end,
    aabb=function() return box end,
    collides=function(g)
      local function sat(nv1, x1, y1, nx1, ny1, maxp, nv2, x2, y2, nx2, ny2)
        local cid, dist, nrmx, nrmy, rx, ry, minp, p, idx, vx, vy, d,
          px, py, p1x, p1y, p2x, p2y, p3x, p3y, p4x, p4y, p1, p2, p3, p4,
          lidx, ridx, lnx, lny, rnx, rny, ldot, rdot, ex, ey,
          minn, maxn, mine, maxe, alpha = -1, 0x7fff
        for i=1,nv1 do
          minp, idx = 0x7fff, -1
          for j=1,nv2 do
            vx, vy = x2[j], y2[j]
            p = vx*nx1[i]+vy*ny1[i]
            if p<minp then minp, idx, px, py = p, j, vx, vy end
          end

          if minp>maxp[i] then return nil end

          d = maxp[i]-minp
          if d<dist then
            dist, nrmx, nrmy = d, nx1[i], ny1[i]

            lidx, ridx = (idx-2)%nv2+1, idx
            lnx, lny = nx2[lidx], ny2[lidx] --g.normal(lidx)
            rnx, rny = nx2[ridx], ny2[ridx] --g.normal(ridx)
            ldot, rdot = lnx*nx1[i]+lny*ny1[i], rnx*nx1[i]+rny*ny1[i]

            if min(abs(1+ldot), abs(1+rdot))<0x0.0008 then
              ex, ey = ldot<rdot and -lny or -rny, ldot<rdot and lnx or rnx

              p1x, p1y = x1[i], y1[i]
              p2x, p2y = x1[i%nv1+1], y1[i%nv1+1]
              p3x, p3y = x2[ldot<rdot and lidx or ridx], y2[ldot<rdot and lidx or ridx]
              p4x, p4y = x2[ldot<rdot and lidx%nv2+1 or ridx%nv2+1], y2[ldot<rdot and lidx%nv2+1 or ridx%nv2+1]
              p1, p2, p3, p4 =
                ex*(p1x-px)+ey*(p1y-py), ex*(p2x-px)+ey*(p2y-py),
                ex*(p3x-px)+ey*(p3y-py), ex*(p4x-px)+ey*(p4y-py)

              minn, maxn = minmax(p1, p2)
              mine, maxe = minmax(p3, p4)

              alpha = 0.5*(mid(mine, minn, maxe)+mid(minn, maxe, maxn))

              cid, rx, ry = (shl(i+nv1, 8)+(ldot<rdot and lidx or ridx)+nv2),
                px+alpha*ex, py+alpha*ey
            else
              cid, rx, ry = (shl(i+nv1, 8)+idx), px, py
            end
          end
        end
        return cid, dist, -nrmx, -nrmy, rx+nrmx*dist, ry+nrmy*dist, rx, ry
      end

      local id1, dist1, nx1, ny1, xA1, yA1, xB1, yB1 = sat(numv, tvx, tvy, tnx, tny, maxp, g.num_vertex(), g.x, g.y, g.nx, g.ny)
      local id2, dist2, nx2, ny2, xB2, yB2, xA2, yA2 = sat(g.num_vertex(), g.x, g.y, g.nx, g.ny, g.maxp, numv, tvx, tvy, tnx, tny)
      if (not(id1 and id2)) return nil
      if (dist1<dist2) return id1, dist1, nx1, ny1, xA1, yA1, xB1, yB1
      return id2, dist2, -nx2, -ny2, xA2, yA2, xB2, yB2
    end,
    transform=function(x, y, a)
      local ca, sa = cos_sin(a)
      box.set()
      for i=1,numv do
        tvx[i], tvy[i], tnx[i], tny[i] =
          vx[i]*ca-vy[i]*sa+x, vx[i]*sa+vy[i]*ca+y,
          ca*nx[i]-sa*ny[i], sa*nx[i]+ca*ny[i]
        maxp[i] = tnx[i]*tvx[i]+tny[i]*tvy[i]
        box.x1, box.y1, box.x2, box.y2 =
          min(tvx[i], box.x1), min(tvy[i], box.y1),
          max(tvx[i], box.x2), max(tvy[i], box.y2)
      end
    end,
    draw=function(vp)
      local v1x, v1y, v2x, v2y
      v1x, v1y = vp.to_screen(tvx[1], tvy[1])
      for i=1,numv do
        v2x, v2y = vp.to_screen(tvx[i%numv+1], tvy[i%numv+1])
        line(v1x, v1y, v2x, v2y)
        v1x, v1y = v2x, v2y
      end
    end
  }
end
