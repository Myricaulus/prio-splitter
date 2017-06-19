require "util"

local prio = {}
prio.moddir = "__prio-splitters__"

-- The prio variants of the splitters share all of the
-- characteristics of their baser counterparts. Instead of
-- copy-pasting the entity data that is subject to change, we'll
-- procedurally build the prio splitters, updating the entity name
-- and generating new animations.

function make_anim (lst, dir)
   -- This is the default splitter animation.
   local t1 = util.table.deepcopy (lst)

   -- This is the prio layer animation.
   local t2 = util.table.deepcopy (lst)
   --t2.filename = prio.moddir.."/graphics/prio-layer-"..dir..".png"
   --t2.filename = prio.moddir.."/graphics/prio-layer-"..dir..".png"

   return { layers = {t1} }
end


function prio.make_prio_entity (name)
   if data.raw["splitter"][name] ~= nil then
      local prio = "prio-"..name
      local template = util.table.deepcopy (data.raw["splitter"][name])

      template.name = prio
      template.minable.result = prio

      template.structure.north = make_anim (template.structure.north, "north")
      template.structure.east = make_anim (template.structure.east, "east")
      template.structure.south = make_anim (template.structure.south, "south")
      template.structure.west = make_anim (template.structure.west, "west")

      data:extend({template})
   end
end

return prio
