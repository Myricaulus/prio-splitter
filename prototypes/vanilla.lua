local prio = require "prio"
local debug = require "..debug"


if debug.enabled then
   local fmt = prio.moddir.."/graphics/debug/%s.png"

   for i, plate in ipairs ({"copper-plate", "iron-plate"}) do
      data.raw["item"][plate].icon = string.format (fmt, plate)
   end
end


-- Entity definitions
splitters = {"splitter", "fast-splitter", "express-splitter"}
for i, name in ipairs (splitters) do
   prio.make_prio_entity (name)
end


-- Item definitions
data:extend({
      {
         type = "item",
         name = "prio-splitter",
         icon = "__prio-splitters__/graphics/icons/prio-splitter.png",
         flags = {"goes-to-quickbar"},
         subgroup = "belt",
         order = "c[splitter]-a[splitter]-b[prio-splitter]",
         place_result = "prio-splitter",
         stack_size = 50
      },
      {
         type = "item",
         name = "prio-fast-splitter",
         icon = "__prio-splitters__/graphics/icons/prio-fast-splitter.png",
         flags = {"goes-to-quickbar"},
         subgroup = "belt",
         order = "c[splitter]-b[fast-splitter]-c[prio-fast-splitter]",
         place_result = "prio-fast-splitter",
         stack_size = 50
      },
      {
         type = "item",
         name = "prio-express-splitter",
         icon = "__prio-splitters__/graphics/icons/prio-express-splitter.png",
         flags = {"goes-to-quickbar"},
         subgroup = "belt",
         order = "c[splitter]-c[express-splitter]-d[prio-express-splitter]",
         place_result = "prio-express-splitter",
         stack_size = 50
      }
})


-- Recipe definitions
data:extend({
      {
         type = "recipe",
         name = "prio-splitter",
         enabled = false,
         energy_required = 1,
         ingredients =
            {
               {"splitter", 1},
               {"copper-cable", 1},
               {"electronic-circuit", 1}
            },
         result = "prio-splitter",
         requester_paste_multiplier = 4
      },
      {
         type = "recipe",
         name = "prio-fast-splitter",
         enabled = false,
         energy_required = 2,
         ingredients =
            {
               {"fast-splitter", 1},
               {"copper-cable", 1},
               {"electronic-circuit", 1}
            },
         result = "prio-fast-splitter",
         requester_paste_multiplier = 4
      },
      {
         type = "recipe",
         name = "prio-express-splitter",
         enabled = false,
         energy_required = 2,
         ingredients =
            {
               {"express-splitter", 1},
               {"copper-cable", 1},
               {"advanced-circuit", 1}
            },
         result = "prio-express-splitter"
      }
})


-- Technology definitions
table.insert(
   data.raw["technology"]["logistics"].effects,
   {
      type="unlock-recipe",
      recipe="prio-splitter"
   }
)

table.insert(
   data.raw["technology"]["logistics-2"].effects,
   {
      type="unlock-recipe",
      recipe="prio-fast-splitter"
   }
)

table.insert(
   data.raw["technology"]["logistics-3"].effects,
   {
      type="unlock-recipe",
      recipe="prio-express-splitter"
   }
)
