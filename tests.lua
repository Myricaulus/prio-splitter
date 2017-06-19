-- Test routine for exploring the behavior
-- of `insert_at()` on a splitter outbound line.

function test_insert (tick, tout, belt_speed)
   -- tout => transport line we are testing
   local unit = 0.28125

   local stack1 = {name='copper-plate', count=1}
   local stack2 = {name='copper-plate', count=2}

   -- These test routines were written iteratively. Some
   -- of them were added to explore other results.

   trunc = function (num)
      return string.format ("%.6f", num)
   end

   result = function (test_num, desc, data)
      print (test_num, desc, serpent.line(data))
   end

   -- Check insert_at < 0 for small offets
   tout.remove_item (stack2)
   local data = nil
   for pos=-0.5,-.0001,.00001 do
      if tout.insert_at (pos, stack1) then
         data = trunc(pos)
         break
      end
   end
   result (0, "-0.5 <= x < 0", data)

   -- Check insert_at > 0.5 for small offsets
   tout.remove_item (stack2)
   local data = nil
   for pos=.5+.0001,1,.00001 do
      if tout.insert_at (pos, stack1) then
         data = trunc(pos)
         break
      end
   end
   result (1, "0.5 > x <= 1", data)

   -- insert_at(0) and find next closest insert
   tout.remove_item (stack2)
   local data = nil
   tout.insert_at (0, stack1)
   for pos=0,.5,.00001 do
      if tout.insert_at (pos, stack1) then
         data = trunc(pos)
         break
      end
   end
   result (2, "insert_at(0) + next nearest", data)

   -- insert_at(0.5) and find next closest insert
   tout.remove_item (stack2)
   local data = nil
   tout.insert_at (0.5, stack1)
   for pos=.5,0,-.00001 do
      if tout.insert_at (pos, stack1) then
         data = trunc(pos)
         break
      end
   end
   result (3, "insert_at(0.5) + next nearest", data)

   -- Starting left (0) search for the furthest left position
   -- that allows a second insert.
   local best = nil
   for left=0,.5,.0001 do
      tout.remove_item (stack2)
      if tout.insert_at (left, stack1) then
         for right=left,.5,.0001 do
            if tout.insert_at (right, stack1) then
               best = { trunc(left), trunc(right) }
               break
            end
         end
      end
   end
   result (4, "left-to-right boundary scan", best)

   -- Starting right (.5) search for the furthest right position
   -- that allows a second insert.
   local best = {}
   for right=.5,0,-.0001 do
      tout.remove_item (stack2)
      if tout.insert_at (right, stack1) then
         for left=right,0,-.0001 do
            if tout.insert_at (left, stack1) then
               best = { trunc(left), trunc(right) }
               break
            end
         end
      end
   end
   result (5, "right-to-left boundary scan", best)

   -- Okay, based on the previous two results we can see that there is
  -- a deadzone where if a single item is in that zone, a second item
   -- cannot be placed on the belt.

   -- Starting on the left side of the deadzone, try to
   -- insert up to the right side.

   local dzl = .2186999  -- taken from boundary scan 1
   local dzr = unit      -- taken from boundary scan 2

   local data = nil
   for i=dzl,dzr,.0001 do
      tout.remove_item (stack2)
      if tout.insert_at (i, stack1) then
         for j=i,dzr,.0001 do
            if tout.insert_at (j, stack1) then
               data = trunc(j)
            end
         end
      end
   end
   result (6, "left-to-right deadzone scan", data)

   -- Scan the deadzone the other way.

   local data = nil
   for i=dzl,dzl,-.0001 do
      tout.remove_item (stack2)
      if tout.insert_at (i, stack1) then
         for j=i,dzl,-.0001 do
            if tout.insert_at (j, stack1) then
               data = trunc(j)
            end
         end
      end
   end
   result (7, "right-to-left deadzone scan", data)


   -- Based on previous results, we know we can overlap
   -- plates if the right is placed first.

   local x = unit - .0001
   local y = unit

   tout.remove_item (stack2)
   local data = nil
   if (tout.insert_at (x, stack1) and
       tout.insert_at (y, stack1)) then
      data = {trunc(x), trunc(y)}
   end
   result (8, "overlap (left placed first)", data)

   tout.remove_item (stack2)
   if (tout.insert_at (y, stack1) and
       tout.insert_at (x, stack1)) then
      data = {trunc(x), trunc(y)}
   end
   result (9, "overlap (right placed left)", data)


   -- Since we know the maximum two item boundary going from the
   -- right is at pos=unit and we can overlap right-then-left
   -- plates by a .0001 position, what's the furthest left we
   -- can insert if we insert first at `unit`.

   local best = nil
   tout.remove_item (stack2)
   if tout.insert_at (unit, stack1) then
      for left=0,unit,.00001 do
         if tout.insert_at (left, stack1) then
            best = { trunc(left), trunc(unit) }
            break
         end
      end
   end
   result (10, "max gap from insert_at(unit)", best)
end
