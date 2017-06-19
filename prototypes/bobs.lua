-- Support for Bob's Logistics

local prio = require "prio"


-- Entity definitions
splitters = {"green-splitter", "purple-splitter"}
for i, name in ipairs (splitters) do
   prio.make_prio_entity (name)
end


-- Item definitions
data:extend({
      {
         type = "item",
         name = "prio-green-splitter",
         icon = prio.moddir.."/graphics/icons/prio-green-splitter.png",
         flags = {"goes-to-quickbar"},
         subgroup = "bob-belt",
         order = "c[splitter]-d[green-splitter]-e[prio-green-splitter]",
         place_result = "prio-green-splitter",
         stack_size = 50
      },
      {
         type = "item",
         name = "prio-purple-splitter",
         icon = prio.moddir.."/graphics/icons/prio-purple-splitter.png",
         flags = {"goes-to-quickbar"},
         subgroup = "bob-belt",
         order = "c[splitter]-e[purple-splitter]-f[prio-purple-splitter]",
         place_result = "prio-purple-splitter",
         stack_size = 50
      },
})


-- Recipe definitions
data:extend({
      {
         type = "recipe",
         name = "prio-green-splitter",
         enabled = false,
         energy_required = 1,
         ingredients =
            {
               {"green-splitter", 1},
               {"copper-cable", 1},
               {"advanced-circuit", 1}
            },
         result = "prio-green-splitter",
         requester_paste_multiplier = 4
      },
      {
         type = "recipe",
         name = "prio-purple-splitter",
         enabled = false,
         energy_required = 2,
         ingredients =
            {
               {"purple-splitter", 1},
               {"copper-cable", 1},
               {"processing-unit", 1}
            },
         result = "prio-purple-splitter",
         requester_paste_multiplier = 4
      },
})


-- Technology definitions
table.insert(
   data.raw["technology"]["bob-logistics-4"].effects,
   {
      type="unlock-recipe",
      recipe="prio-green-splitter"
   }
)

table.insert(
   data.raw["technology"]["bob-logistics-5"].effects,
   {
      type="unlock-recipe",
      recipe="prio-purple-splitter"
   }
)
