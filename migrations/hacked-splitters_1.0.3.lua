for index, force in pairs (game.forces) do
   local technologies = force.technologies;
   local recipes = force.recipes;

   if technologies["logistics"].researched then
      recipes["prio-splitter"].enabled = true
   end
   if technologies["logistics-2"].researched then
      recipes["prio-fast-splitter"].enabled = true
   end
   if technologies["logistics-3"].researched then
      recipes["prio-express-splitter"].enabled = true
   end

   -- Bob's Logistics
   if (technologies["bob-logistics-4"] and
       technologies["bob-logistics-4"].researched) then
      recipes["prio-green-splitter"].enabled = true
   end
   if (technologies["bob-logistics-5"] and
       technologies["bob-logistics-5"].researched) then
      recipes["prio-purple-splitter"].enabled = true
   end
end
