pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- broadphase collision detection
--[[
broadphase collision detection using sweep and prune with axis aligned bounding boxes
]]

-->8
-- sweep and prune

function sweep_and_prune()
  local nump, x_id, y_id, x_val, y_val, x_minmax, y_minmax, x_spans, y_spans, count, cand, iter =
    2, { -1, -1 }, { -1, -1 }, { 0x8000, 0x7fff }, { 0x8000, 0x7fff }, { 0, 1 }, { 0, 1 }, {}, {}, {}, {}

  return {
    add_body=function(id, box)
      local function insert(len, ids, vals, minmaxs, spans, id, val, minmax)
        ids[len+1], vals[len+1], minmaxs[len+1] = ids[len], vals[len], minmaxs[len]
        local idx, prev_id, cid, pidx = len
        while vals[idx-1]>val do
          pidx = idx-1
          prev_id = ids[pidx]
          cid = shl(min(id, prev_id), 8)+max(id, prev_id)
          count[cid] = (count[cid] and count[cid] or 0) + (minmaxs[pidx]-minmax)
          cand[cid] = count[cid]==2 and true or nil
          ids[idx], vals[idx], minmaxs[idx], spans[prev_id*2+minmaxs[pidx]] =
            ids[pidx], vals[pidx], minmaxs[pidx], idx
          idx -= 1
        end
        ids[idx], vals[idx], minmaxs[idx], spans[id*2+minmax] = id, val, minmax, idx
      end

      insert(nump, x_id, x_val, x_minmax, x_spans, id, box.x1, 0)
      insert(nump+1, x_id, x_val, x_minmax, x_spans, id, box.x2, 1)
      insert(nump, y_id, y_val, y_minmax, y_spans, id, box.y1, 0)
      insert(nump+1, y_id, y_val, y_minmax, y_spans, id, box.y2, 1)
      nump += 2
    end,
    remove_body=function(id)
      local function remove(len, ids, vals, minmaxs, spans, idx)
        for i=idx+1, len do
          if (ids[i]>0) spans[ids[i]*2+minmaxs[i]] = i-1
          ids[i-1], vals[i-1], minmaxs[i-1] = ids[i], vals[i], minmaxs[i]
        end
      end
      remove(nump, x_id, x_val, x_minmax, x_spans, x_spans[id*2])
      remove(nump-1, x_id, x_val, x_minmax, x_spans, x_spans[id*2+1])
      remove(nump, y_id, y_val, y_minmax, y_spans, y_spans[id*2])
      remove(nump-1, y_id, y_val, y_minmax, y_spans, y_spans[id*2+1])
      nump -= 2

      local id1, id2 = shl(id, 8), id
      for cid in pairs(count) do
        if (band(cid, 0xff00)==id1 or band(cid, 0x00ff)==id2) count[cid] = nil
      end
      for cid in pairs(cand) do
        if (band(cid, 0xff00)==id1 or band(cid, 0x00ff)==id2) cand[cid] = nil
      end
    end,
    update_body=function(id, box)
      local function update(ids, vals, minmaxs, spans, idx, val)
        local off, id1, id2, cid, nidx
        vals[idx] = val
        while mid(vals[idx-1], val, vals[idx+1])!=val do
          off = vals[idx+1]<val and 1 or -1
          nidx = idx+off
          id1, id2 = ids[idx], ids[nidx]
          if id1!=id2 then
            cid = shl(min(id1, id2), 8)+max(id1, id2)
            count[cid] = (count[cid] and count[cid] or 0) - off*(minmaxs[nidx]-minmaxs[idx])
            cand[cid] = count[cid]==2 and true or nil
          end

          ids[idx], vals[idx], minmaxs[idx], spans[id1*2+minmaxs[idx]],
            ids[nidx], vals[nidx], minmaxs[nidx], spans[id2*2+minmaxs[nidx]] =
            ids[nidx], vals[nidx], minmaxs[nidx], nidx,
            ids[idx], vals[idx], minmaxs[idx], idx
          idx += off
        end
      end
      update(x_id, x_val, x_minmax, x_spans, x_spans[id*2], box.x1)
      update(x_id, x_val, x_minmax, x_spans, x_spans[id*2+1], box.x2)
      update(y_id, y_val, y_minmax, y_spans, y_spans[id*2], box.y1)
      update(y_id, y_val, y_minmax, y_spans, y_spans[id*2+1], box.y2)
    end,
    has_more=function() iter = next(cand, iter) return iter end,
    next=function() if(iter) return shr(band(iter, 0xff00), 8), band(iter, 0xff) end
  }
end
