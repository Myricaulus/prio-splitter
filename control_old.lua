require "math"
require "util"
local debug = require ".debug"


-- For configuration changes.
local modname = "hacked-splitters"

-- How big is a unit on a belt. Don't be dirty.
local UNIT_SIZE = 0.28125  -- Since Factorio 0.13
local INSERT_POS = 0.5 - UNIT_SIZE * 0.35

-- A little state machine indicating the order of transport
-- lines--both input and output--to check based on the last line
-- checked.
local transport_line = defines.transport_line
local transport_fsm = {
   -- Input lines.
   [ transport_line.left_line ] = transport_line.secondary_left_line,
   [ transport_line.secondary_left_line ] = transport_line.right_line,
   [ transport_line.right_line ] = transport_line.secondary_right_line,
   [ transport_line.secondary_right_line ] = transport_line.left_line,

   -- Output lines.
   [ transport_line.left_split_line ] = transport_line.secondary_left_split_line,
   [ transport_line.secondary_left_split_line ] = transport_line.right_split_line,
   [ transport_line.right_split_line ] = transport_line.secondary_right_split_line,
   [ transport_line.secondary_right_split_line ] = transport_line.left_split_line
}

-- Belts for the splitters, used to determine the splitters' speeds.
local hacked_splitter_belts = {
   ["hacked-splitter"] = "transport-belt",
   ["hacked-fast-splitter"] = "fast-transport-belt",
   ["hacked-express-splitter"] = "express-transport-belt",

   -- Bob's Logistics mod
   ["hacked-green-splitter"] = "green-transport-belt",
   ["hacked-purple-splitter"] = "purple-transport-belt",
}

script.on_init (function() initialize() end)
script.on_configuration_changed (
   function (data)
      local rebuild = false
      local changes = data.mod_changes

      if changes then
         print ('CONFIG:', serpent.line (changes, {comment=false}))
      end

      if changes and changes[modname] then
         local mod = changes[modname]
         if mod.old_version == nil then
            -- It's being added. Create skeleton data structures.
            initialize()
         elseif mod.old_version ~= mod.new_version then
            -- Migrations not covered in `migrations/*.lua'
            print (modname, "migration", mod.old_version, mod.new_version)

            local rescan = function()
               initialize()
               for i, surface in pairs (game.surfaces) do
                  local s = surface.find_entities_filtered{type="splitter"}

                  for i, entity in pairs (s) do
                     if entity.valid and is_splitter (entity) then
                        -- Use the hammer, recreate them all.
                        add_splitter (entity)
                     end
                  end
               end
            end

            if mod.old_version == "1.1.0" then
               -- Down-revving.
               print (modname, "migrating", "old == 1.1.0")
               rescan()
            elseif mod.new_version >= "1.0.6" then
               -- There was a problem with Upgrade Planner where
               -- updating items that tracked state on buit/mined
               -- would not trigger those events. Try and fix this.
               --
               -- This also has the benefit of updating all the
               -- hacked splitters to the new data format.
               print (modname, "migrating", "new > 1.0.6")
               rescan()
            end
         end
      end

      if changes and changes["upgrade-planner"] then
         local mod = changes["upgrade-planner"]

         if mod.new_version == nil or mod.new_version >= "1.2.7" then
            global.upgrade_planner_bad_install = false
         else
            -- Until we see a change event, how can we know?
            global.upgrade_planner_bad_install = true
         end
      end

      if changes and changes["base"] then
         rebuild = true
      end

      if changes and changes["boblogistics"] then
         rebuild = true
      end

      if rebuild then
         recalculate_speeds()
      end
   end
)


script.on_event (
   defines.events.on_player_created,
   function (event)
      if debug.enabled then
         dprint (event.tick, "DEBUG:", "enabled")
         local player = game.players[event.player_index]
         debug.all_the_things (game, player)
      end
   end
)


script.on_event (
   defines.events.on_tick,
   function (event)
      process_splitters (event.tick)
   end
)


script.on_event (
   {
      defines.events.on_built_entity,
      defines.events.on_robot_built_entity
   },
   function (event)
      local entity = event.created_entity
      if is_splitter (entity) then
         -- Now we'll do the same-ol' creation logic for all of our
         -- splitters irrespective of type.
         local splitter = add_splitter (entity)
         dprint (event.tick, "BUILT:", splitter.key, entity.name)
      end
   end
)


script.on_event (
   {
      defines.events.on_entity_died,
      defines.events.on_preplayer_mined_item,
      defines.events.on_robot_pre_mined
   },
   function (event)
      local entity = event.entity
      if is_splitter (entity) then
         local _, key = remove_splitter (entity)
         dprint (event.tick, "MINED:", key, entity.name)
      end
   end
)


function initialize()
   -- The hacked splitters that have been placed in the world.
   global.splitter_id = 0
   global.splitters = {
      id = 0,           -- monotonic splitter id
      by_key = {},      -- main table by world position
      by_id = {},       -- reference table by splitter id
   }

   -- Used so we don't have to check `entity.valid`.
   global.upgrade_planner_bad_install = true
end


function create_splitter (entity)
   global.splitter_id = global.splitter_id + 1

   --[[--
      The state data for a splitter. The fields are:
        id      - monotonic id
        key     - position key
        entity  - the hacked splitter game object
        speed   - cached speed of this splitter
        tpu     - ticks per UNIT_SIZE
        backoff - backoff count; don't poll lines
        input   - state tracking for inbound lines
        output  - state tracking for outbound lines
        line    - LuaEntity.get_transport_line cache
   --]]--
   local speed = splitter_belt_speed (entity.name)
   local splitter = {
      -- Table indices.
      id=global.splitter_id,
      key=poskey (entity),

      entity=entity,
      speed=speed,
      tpu=UNIT_SIZE / speed,
      backoff=0,

      input=transport_line.left_line,
      output=transport_line.left_split_line,

      lines = {
         -- Tracks the last time an item was placed/removed and
         -- tracks the predicted positions thereof.
         [ transport_line.left_line ] = 0,
         [ transport_line.right_line ] = 0,
         [ transport_line.secondary_left_line ] = 0,
         [ transport_line.secondary_right_line ] = 0,
         [ transport_line.left_split_line ] = 0,
         [ transport_line.right_split_line ] = 0,
         [ transport_line.secondary_left_split_line ] = 0,
         [ transport_line.secondary_right_split_line ] = 0
      },
   }

   for i, _ in pairs (splitter.lines) do
      splitter.lines[i] = entity.get_transport_line (i)
   end

   return splitter
end


function add_splitter (tick, entity)
   local splitter = create_splitter (tick, entity)

   global.splitters.by_key[splitter.key] = splitter
   global.splitters.by_id[splitter.id] = splitter

   return splitter
end


function remove_splitter (entity, key)
   if key == nil then
      key = poskey (entity)
   end

   -- This can get called multiple times with robot removal.
   -- Gotta protect against the second one.
   local splitter = global.splitters.by_key[key]
   if splitter == nil or splitter.id == nil then
      return nil, key
   end

   global.splitters.by_key[key] = nil
   global.splitters.by_id[splitter.id] = nil

   return splitter.id, key
end


function poskey (entity)
   -- Create our own location index into the `splitters` table.  It
   -- requires the surface since multiple surfaces can have the same
   -- position coordinates.
   local surface = entity.surface
   if surface == nil then return nil end

   local name = entity.surface.name
   local pos = entity.position

   return name .. ":" .. tostring (pos.x) .. ":" .. tostring (pos.y)
end


function transport_iter (initial)
   -- A special property of this iterator is that it will iterate
   -- through all lines on a side of the splitter, once.
   local transport_fsm = transport_fsm
   local curr = nil
   return function()
      if curr ~= initial then
         curr = curr or initial
         curr = transport_fsm[curr]
         return curr
      end
   end
end


function first (t)
   -- Simple routine to give only the first item
   -- found in a table.
   for k, v in pairs (t) do return k, v end
end


function process_splitter (tick, splitter, key)
   local entity = splitter.entity

   splitter.backoff = splitter.backoff - 1
   if splitter.backoff > 1 then
      return
   end

   -- We create the iterator here because the number of outbound lanes
   -- is finite. There's no point in looping on all of them for each
   -- inbound lane. I'm vice versa, your vices are my verses, and
   -- versa vice.

   local input_iter = transport_iter (splitter.input)
   local output_iter = transport_iter (splitter.output)

   -- For backoff calculation.
   local inserts = 0

   -- Optimization bindings.
   local INSERT_POS = INSERT_POS
   local first = first
   local lines = splitter.lines

   for input in input_iter do
      -- The hack to the splitter created a bit of the Schrodinger
      -- Splitter--you really can't tell which item on the
      -- transport line will come out first.
      local tin = lines[input]
      local item, count = first (tin.get_contents())
      local stack = { name=item }

      while item do
         local output = output_iter()

         -- Nothing more to do for any input line.
         if output == nil then goto done end

         local tout = lines[output]
         local success = tout.insert_at (INSERT_POS, stack)
         if success then
            tin.remove_item (stack)
            item = nil

            -- Update the last lines that were successfully used.
            splitter.input = input
            splitter.output = output
            inserts = inserts + 1
         end
      end
   end

   -- Jumping to here means that even though there was more input
   -- lines to process, there were no output lines to place.
   ::done::

   if inserts > 0 then
      splitter.backoff = 0
   else
      splitter.backoff = splitter.tpu
   end

end


function process_splitters (tick)
   local test_valid = global.upgrade_planner_bad_install

   for key, splitter in pairs (global.splitters.by_key) do
      -- I1: update-planner was a bad actor. It has since
      --     been fixed, but we still need to check for
      --     brokenness in players' games.
      --
      -- Calling `valid` for 1000 entities takes .8ms for me.
      if test_valid and not splitter.entity.valid then
         dprint (tick, "splitter", key, "invalid!")
         remove_splitter (splitter, key)
      else
         process_splitter (tick, splitter, key)
      end
   end
end


function is_splitter (entity)
   -- Or more specifically, a hacked splitter.
   if entity.type ~= "splitter" then
      return false
   else
      -- And do we support it.
      return hacked_splitter_belts[entity.name]
   end
end


function splitter_belt_speed (splitter_name)
   local belt_name = hacked_splitter_belts[splitter_name]
   if not belt_name then return nil end

   local belt_entity = game.entity_prototypes[belt_name]
   if not belt_entity then return nil end

   return belt_entity.belt_speed
end


function recalculate_speeds()
   -- Whenever a mod changes that has splitters, they may have updated
   -- the belt speed. Need to recalculate the speeds.
   for key, splitter in pairs (global.splitters.by_key) do
      local entity = splitter.entity
      if entity.valid then
         local belt_speed = splitter_belt_speed (entity.name)
         if belt_speed then
            splitter.speed = belt_speed
         else
            -- This path shouldn't happen.
            remove_splitter (splitter, key)
         end
      else
         remove_splitter (splitter, key)
      end
   end
end
