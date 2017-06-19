for index, force in pairs(game.forces) do
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
end
