local debug = {}
debug.enabled = false


function debug.create_items (player)
   player.character.insert{name="prio-splitter", count=50}
   player.character.insert{name="prio-fast-splitter", count=50}
   player.character.insert{name="prio-express-splitter", count=50}

   player.character.insert{name="transport-belt", count=200}
   player.character.insert{name="fast-transport-belt", count=200}
   player.character.insert{name="express-transport-belt", count=200}

   player.character.insert{name="splitter", count=50}
   player.character.insert{name="fast-splitter", count=50}
   player.character.insert{name="express-splitter", count=50}

   player.character.insert{name="express-underground-belt", count=50}

   player.character.insert{name="raw-wood", count=50}
   player.character.insert{name="iron-plate", count=1000}
   player.character.insert{name="copper-plate", count=1000}

   player.character.insert{name="fast-inserter", count=50}
   player.character.insert{name="stack-inserter", count=50}
   player.character.insert{name="constant-combinator", count=10}
   player.character.insert{name="red-wire", count=100}

   player.character.insert{name="solar-panel", count=50}
   player.character.insert{name="small-electric-pole", count=50}
   player.character.insert{name="iron-chest", count=50}
end


function debug.all_the_things (game, player)
--   player.force.research_all_technologies()
   game.surfaces[1].always_day = true
   debug.create_items (player)
end

local printIndex=0

function timeprint(...)
	printIndex = printIndex + 1
	print(printIndex..":",...)
end

if debug.enabled then
   dprint = timeprint
else
   dprint = function(...) end
end

return debug
