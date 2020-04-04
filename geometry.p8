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
  local tvx, tvy, nx, ny, tnx, tny, maxp, box, x, y, len, idx = {}, {}, {}, {}, {}, {}, {}, aabb()

  for i=1,numv do
    idx, x, y =  i%numv+1, vx[i], vy[i]
    tvx[i], tvy[i], nx[i], ny[i] = x, y, y-vy[idx], vx[idx]-x
    len = sqrt(nx[i]^2+ny[i]^2)
    nx[i] /= len ny[i] /= len
  end

  return {
    numv=numv,
    x=tvx, y=tvy,
    nx=tnx, ny=tny,
    maxp=maxp,
    aabb=box,
    collides=function(g)
      local function sat(nv1, x1, y1, nx1, ny1, maxp, nv2, x2, y2, nx2, ny2)
        local cid, dist, nrmx, nrmy, rx, ry, minp, p, idx, d,
          px, py, p1x, p1y, p2x, p2y, p3x, p3y, p4x, p4y, p1, p2, p3, p4,
          lidx, ridx, ldot, rdot, ex, ey, minn, maxn, mine, maxe, alpha = -1, 0x7fff
        for i=1,nv1 do
          minp, idx = 0x7fff, -1
          for j=1,nv2 do
            p = x2[j]*nx1[i]+y2[j]*ny1[i]
            if (p<minp) minp, idx, px, py = p, j, x2[j], y2[j]
          end

          if (minp>maxp[i]) return nil

          d = maxp[i]-minp
          if d<dist then
            dist, nrmx, nrmy = d, nx1[i], ny1[i]

            lidx, ridx = (idx-2)%nv2+1, idx
            ldot, rdot = nx2[lidx]*nx1[i]+ny2[lidx]*ny1[i],
                         nx2[ridx]*nx1[i]+ny2[ridx]*ny1[i]

            if min(ldot, rdot)<0xffff.0008 then
              idx = ldot<rdot and lidx or ridx
              ex, ey, p1x, p1y, p2x, p2y, p3x, p3y, p4x, p4y =
                -ny2[idx], nx2[idx],
                x1[i], y1[i], x1[i%nv1+1], y1[i%nv1+1],
                x2[idx], y2[idx], x2[idx%nv2+1], y2[idx%nv2+1]
              p1, p2, p3, p4 =
                ex*(p1x-px)+ey*(p1y-py), ex*(p2x-px)+ey*(p2y-py),
                ex*(p3x-px)+ey*(p3y-py), ex*(p4x-px)+ey*(p4y-py)

              minn, maxn = minmax(p1, p2)
              mine, maxe = minmax(p3, p4)

              alpha = 0.5*(mid(mine, minn, maxe)+mid(minn, maxe, maxn))

              cid, rx, ry = (shl(i+nv1, 8)+idx+nv2), px+alpha*ex, py+alpha*ey
            else
              cid, rx, ry = (shl(i+nv1, 8)+idx), px, py
            end
          end
        end
        return cid, dist, -nrmx, -nrmy, rx+nrmx*dist, ry+nrmy*dist, rx, ry
      end

      local id1, dist1, nx1, ny1, xA1, yA1, xB1, yB1 = sat(numv, tvx, tvy, tnx, tny, maxp, g.numv, g.x, g.y, g.nx, g.ny)
      local id2, dist2, nx2, ny2, xB2, yB2, xA2, yA2 = sat(g.numv, g.x, g.y, g.nx, g.ny, g.maxp, numv, tvx, tvy, tnx, tny)
      if (not(id1 and id2)) return nil
      if (dist1<dist2) return id1, dist1, nx1, ny1, xA1, yA1, xB1, yB1
      return id2, dist2, -nx2, -ny2, xA2, yA2, xB2, yB2
    end,
    transform=function(x, y, a)
      box.set()
      for i=1,numv do
        tvx[i], tvy[i] = transform(vx[i], vy[i], x, y, a)
        tnx[i], tny[i] = transform(nx[i], ny[i], 0, 0, a)
        maxp[i], box.x1, box.y1, box.x2, box.y2 =
          tnx[i]*tvx[i]+tny[i]*tvy[i],
          min(tvx[i], box.x1), min(tvy[i], box.y1),
          max(tvx[i], box.x2), max(tvy[i], box.y2)
      end
    end,
    draw=function(vp)
      local v1x, v1y, v2x, v2y, idx = vp.to_screen(tvx[1], tvy[1])
      for i=1,numv do
        idx = i%numv+1
        v2x, v2y = vp.to_screen(tvx[idx], tvy[idx])
        line(v1x, v1y, v2x, v2y)
        v1x, v1y = v2x, v2y
      end
    end
  }
end
