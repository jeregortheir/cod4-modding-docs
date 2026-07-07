// =============================================================================
//  TEMPLATE FOR MAP MAKERS - mp_dr_yourmap.gsc
// =============================================================================
//  This file is a working example you COPY and edit. The patterns here cover
//  ~95% of what a Deathrun map needs, written defensively so the server does
//  not crash when a player disconnects, an entity is missing, or the
//  activator slot is empty.
//
//  If you are new to GSC scripting: read the whole header (Quick Start -
//  Glossary - Debug - Radiant bridge - Rules) BEFORE you start copying code.
//  That takes 10 minutes and saves hours.
// =============================================================================
//
//  QUICK START - 5 STEPS
//  -------------------------------------------------------------------
//   1. Copy this file and rename:
//         maps\mp\_TEMPLATE_FOR_MAPPERS.gsc  ->  maps\mp\mp_dr_YOURNAME.gsc
//
//   2. Open it. Scroll to main(). Delete the thread lines for features you
//      do NOT want (e.g. remove `thread combat_room_sniper();` if your map
//      has no sniper room). Keep `maps\mp\_load::main();` at the top.
//
//   3. For each feature you keep, find its section below and edit the
//      Radiant targetnames (getEnt("...")) to match what you put in Radiant.
//
//   4. Compile your .bsp in Radiant (Compile > BSP + Light + Link). Your
//      .gsc will be baked into the .ff when linkMap runs.
//
//   5. Test: `/map mp_dr_YOURNAME` in the console. Tail qconsole.log after
//      every test for script errors - search for "script runtime error".
//      (See HOW TO DEBUG section below for full error-reading guide.)
//
// =============================================================================
//
//  GLOSSARY - plain English definitions for GSC terms
//  -------------------------------------------------------------------
//   self              The entity this function is currently running on.
//                     For `player thread X()` -> inside X(), self = player.
//                     For `trig thread Y()`   -> inside Y(), self = trig.
//
//   level             Global shared state. `level.foo` is visible from any
//                     function in any file on the server. Use for things
//                     shared between players / threads.
//
//   entity            Anything in the 3D world: a player, a brush, a
//                     script_origin marker, an FX anchor, a trigger.
//                     Has .origin (position) and .angles (rotation).
//
//   thread X()        Start function X in the background. Caller keeps going
//                     without waiting for X to finish. Essential for
//                     anything that loops forever (traps, triggers).
//
//   waittill("foo")   Pause this function (not the whole server) until
//                     someone calls notify("foo") on the same entity/level.
//                     Used to react to events: round start, player death,
//                     trigger fired, move finished, etc.
//
//   notify("foo")     Send a signal. Any function sitting on waittill("foo")
//                     on this entity/level wakes up. Any function with
//                     endon("foo") here gets killed.
//
//   endon("foo")      If notify("foo") fires, immediately kill this thread.
//                     Use at the top of loops so they stop cleanly on
//                     round end / player death / disconnect.
//
//   getEnt(name,"targetname")
//                     Find ONE entity by the `targetname` KVP you set in
//                     Radiant. Returns the entity, or undefined if none.
//                     Crashes if MORE THAN ONE entity shares the name -
//                     use getentarray() + [0] in that case.
//
//   dvar              A named server variable (like a Windows environment
//                     variable). setDvar("foo", 1) / getDvar("foo"). Used
//                     for config and for client<->server communication.
//
//   precache          Tell the engine "I will use this asset", done ONCE at
//                     map load in main() (or helper called from main()).
//                     If you use an asset without precaching it crashes.
//
//   allies / axis     Team names. In Deathrun:
//                       allies = jumpers (green, the majority)
//                       axis   = activator (red, exactly one player)
//
//   level.activ       The player currently on axis team (the activator).
//                     CAN BE THE STRING "Noactivator" when no one is axis -
//                     ALWAYS check `isplayer(level.activ)` before use.
//                     EDIT (Blade):  better use isdefined(level.activ) to be 
//                     really sure this entity is defined and prevent crashs
//
//   module::function  The `::` is "from file X, call function Y". Example:
//                     `maps\mp\_load::main()` means "in file
//                     maps/mp/_load.gsc, call its main() function".
//
//   KVP               Key-Value Pair in Radiant's Entity Inspector (N key).
//                     You add `targetname` / `classname` / custom keys in
//                     Radiant, you read them in GSC via .targetname etc.
//
//   vector            Three numbers in parens: (x, y, z). Positions,
//                     angles, colors all use this. Example: (100, 200, 50).
//
// =============================================================================
//
//  HOW TO DEBUG
//  -------------------------------------------------------------------
//   * Add `iprintln("foo")` to print something visible to ALL players.
//     Quick+dirty but spammy.
//
//   * Add `println("foo")` to print to qconsole.log ONLY (server-only).
//     Quiet+clean. Good for development.
//
//   * Better: flip `level.debug = true;` at the top of main() and use the
//     `debugPrint("foo")` helper (see Section 0.5). One line to silence
//     all debug output before shipping: change true -> false.
//
//   * Script errors appear in qconsole.log looking like:
//         ^1******* script runtime error *******
//         undefined is not a field object: (file 'maps/mp/X.gsc', line 123)
//             player.camo_preview.model
//                   *
//     The `*` points at which thing was undefined. The function stack that
//     follows shows WHAT called this line - trace it back to find the root.
//
//   * To test a specific feature, give the TRIGGER a huge `wait 0.05; foo();`
//     at the top of main() so it runs without you having to reach the
//     trigger in game:
//         main() { maps\mp\_load::main(); thread my_test(); }
//         my_test() { wait 5; iprintln("test fires"); }
//
//   * Common quick-reference errors (see qconsole.log):
//       "undefined is not a field object"   -> your .X was on undefined
//       "undefined is not an entity"         -> entity got deleted mid-loop
//       "type string is not an entity"       -> used level.activ as entity
//                                                without isplayer() check
//       "getent used with more than one"     -> duplicate targetname in
//                                                Radiant, rename or use arr
//       "potential infinite loop"            -> missing `wait` in a loop
//
// =============================================================================
//
//  RADIANT <-> GSC BRIDGE
//  -------------------------------------------------------------------
//   How what you place in Radiant maps to what you type in GSC:
//
//      In Radiant (Entity Inspector):        In GSC code:
//      -------------------------------        ----------------------------------
//      trigger_multiple                       getEnt("X", "targetname")
//        targetname: X                           - returns the trigger entity
//
//      script_origin                          ent = getEnt("X", "targetname");
//        targetname: X                        ent.origin  -> (x, y, z) vector
//        origin: 100 200 50                   ent.angles  -> (pitch, yaw, roll)
//        angles: 0 90 0
//
//      script_brushmodel                      door = getEnt("door", ...)
//        targetname: door                     door moveZ(200, 2);    // slide
//        (select brush + Ctrl-T)              door rotateYaw(90, 1); // rotate
//
//      script_model                           fx = getEnt("fx1", ...)
//        targetname: fx1                      playfx(level._effect["fire"],
//        model: <tag_origin>                         fx.origin);
//
//      spawn-point                            (handled by engine automatically)
//        classname: mp_jumper_spawn
//        classname: mp_activator_spawn
//
//   GOLDEN RULES:
//    * Every `targetname` you type in Radiant must match EXACTLY in
//      getEnt("...") in GSC - case sensitive, no typos.
//    * If two things in Radiant have the same targetname, getEnt() crashes.
//      Use getentarray() + [0] or safeGetEnt() helper instead.
//    * New entity in Radiant = RECOMPILE the map or it will not appear.
//
// =============================================================================
//
//  RULES OF SURVIVAL (the 8 rules that prevent 90% of bugs)
//  -------------------------------------------------------------------
//   1. ALWAYS guard `getEnt`/`getent` results with `if(!isdefined(...)) return;`
//      at the TOP of the function. If a brush is named wrong, the function
//      returns instead of crashing later when you try `.origin` on undefined.
//
//   2. ALWAYS check `if(!isValidPlayer(player)) continue;` AFTER
//      `waittill("trigger", player)`. The player can disconnect or die
//      between firing the trigger and your code running.
//
//   3. NEVER call methods on `level.activ` without `isplayer(level.activ)`.
//      When no one is on axis (activator team), GetActivator() returns the
//      STRING "Noactivator" - calling `level.activ setOrigin(...)` on a
//      string is a runtime error and floods the log.
//
//   4. NEVER use `setmovespeed(N)` or `setgravity(N)` - these are NOT valid
//      CoD4X functions. They will crash the entire server in some builds.
//      Use `setMoveSpeedScale(float)` where 1.0 = default speed (210 in this
//      mod), 0.95 = slow (190), 1.5 = fast.
//
//   5. NEVER write an empty-body while/for loop without a `wait`. The CoD4X
//      opcode killer will kill the thread; in a busy moment it can hang the
//      server. Bad: `while(condition) if(other) wait 1;` (no wait when
//      condition fails). Good: always include `wait` in the loop body.
//
//   6. NEVER use `getEnt("foo", "targetname")` when more than one entity in
//      Radiant has that targetname - it errors with "getent used with more
//      than one entity". Use `safeGetEnt("foo")` (Section 0.5) or
//      `getentarray("foo", "targetname")[0]`.
//
//   7. ALL strings printed to players (iPrintLn, iPrintLnBold, hint strings,
//      HUD text) MUST be in ENGLISH. The server is international.
//
//   8. NEVER use the em-dash character (U+2014) anywhere in a .gsc file.
//      The CoD4 engine cannot render it - it shows as garbage. Use "-"
//      or "--".
//
// =============================================================================
//
//  DO NOT - real bugs we have hit in shipped maps
//  -------------------------------------------------------------------
//   DO NOT: empty-body loop without wait when the inner condition is false.
//       while(isalive(player))
//           if(isdefined(level.activ))
//               wait 1;
//       // When level.activ is undefined the inner if is false, no wait
//       // runs, CPU spins until the engine kills the thread. FIX: always
//       // have a wait inside the loop body, even on the false branch.
//
//   DO NOT: `level.activ X(...)` without checking isplayer().
//       level.activ setOrigin(p.origin);
//       // Crashes when no axis player - level.activ is the STRING
//       // "Noactivator". FIX: `if(isplayer(level.activ)) level.activ setOrigin(...)`
//
//   DO NOT: synchronous call to a function that waittills internally.
//       player respawnLater();       // blocks current thread until death
//       // This is almost always a mistake - you meant:
//       player thread respawnLater();
//
//   DO NOT: getEnt with duplicate targetname.
//       door = getEnt("door", "targetname");
//       // If two brushes share targetname "door" -> engine errors and
//       // door is undefined. Either rename one, or use:
//       door = safeGetEnt("door");     // Section 0.5 helper
//
//   DO NOT: delete an already-deleted entity.
//       level.trig delete();
//       // Second call (e.g. from another room's chain delete) crashes.
//       // FIX: `if(isdefined(level.trig)) level.trig delete();`
//
//   DO NOT: use Polish / non-English strings or em-dash in .gsc files.
//       // Pulapka aktywujaca sie po wejsciu gracza    <- WRONG (Polish)
//       // Trap that fires when the player enters      <- RIGHT (English)
//       // CoD4X engine cannot render special characters consistently.
//
// =============================================================================
//
//  COMMON MISTAKES (one-minute scan before you commit)
//  -------------------------------------------------------------------
//   * Missing `wait` in a loop body       -> thread killed / server hang
//   * `level.activ setOrigin(...)` raw    -> crash when no axis player
//   * `getEnt("name", ...)` on duplicate  -> "used with more than one entity"
//   * Accessing `.origin` on undefined    -> "undefined is not a field object"
//   * Calling a function synchronously    -> caller blocks until it returns
//     that does `waittill("death")`          (meant it as `thread` call?)
//   * Forgetting `addTriggerToList(...)`  -> activator gets no reward for
//     for your activator triggers             pressing your trap's button
//   * Hardcoded Polish / non-English      -> garbage glyphs + looks
//     strings or em-dash                     unprofessional to players
//
// =============================================================================
//
//  NAMING CONVENTION (follow this, other mappers will thank you)
//  -------------------------------------------------------------------
//     trig_<what>                -> trigger_multiple in Radiant
//     origin_<what>               -> script_origin used as a position marker
//     door_<what>                 -> brushmodel door
//     brush_<what>                -> misc brushmodel (mover, platform)
//     fx_<what>                   -> script_model used for FX anchor
//     tp_<what>                   -> teleporter destination
//     secret_<where>_<what>       -> secret-route entities
//     lever_<what>                -> shootable/usable lever
//
//  Examples: trig_trap_crusher, origin_combat_sniper_jumper,
//            secret_easy_enter_trig, brush_trap_wall.
// =============================================================================


// -----------------------------------------------------------------------------
//  main() - REQUIRED in every map. Engine calls this automatically on map
//  load. THIS IS YOUR "STARTER KIT" - replace the example threads with your
//  own. Every thread call must match a function defined below.
//
//  IMPORTANT: if you paste a `thread foo();` line but do NOT also define the
//  function `foo()` somewhere in this file, the map WILL NOT COMPILE.
// -----------------------------------------------------------------------------
main()
{
    // -- ALWAYS first: loads engine systems (spawnpoints, gametype hooks,
    //    weapons). Without this call the map will not run at all. --
    //    The `maps\mp\_load` bit means "from file maps/mp/_load.gsc".
    //    The `::main()` bit means "call its main() function".
    maps\mp\_load::main();

    // -- Fall damage off (Deathrun convention: falling should only kill via
    //    map traps, not the vanilla CoD fall-damage formula) --
    SetDvar("bg_falldamagemaxheight", 99999);
    SetDvar("bg_falldamageminheight", 99998);

    // -- Secret count for the leaderboard system --
    //    Set `vlct_secret_count` to how many secret routes your map has
    //    (0, 1, 2, or 3). Each secret needs a matching _name dvar.
    setDvar("vlct_secret_count", 1);
    setDvar("vlct_secret_1_name", "Cut");
    // setDvar("vlct_secret_2_name", "Hard");
    // setDvar("vlct_secret_3_name", "Pro");

    // -- Debug toggle. Flip to `true` during development to see debugPrint()
    //    messages in qconsole.log. Flip back to `false` before you ship. --
    level.debug = false;

    // -- Threads --
    //    `thread X()` = "start X() in the background, don't wait for it".
    //    Every persistent system (trap loop, trigger watcher, HUD updater)
    //    needs its own thread so it can run forever without blocking others.
    //
    //    DELETE thread lines you do not need, ADD one line for every new
    //    feature function you write below. Each line here must have a
    //    matching function definition later in this file.
    thread simple_door_example();   // Hello-world - Section 1
    thread startdoor();              // Section 2
    // thread trap_crusher();           // Section 3  <- uncomment if used
    // thread trap_lava();              // Section 4
    // thread combat_room_sniper();     // Section 7
    // thread secret_easy();            // Section 9
    // thread reset_traps_on_round_end();   // Section 11

    // -- REGISTER TRAP TRIGGERS WITH THE MOD --
    //    Every trigger that an activator presses (crusher lever, lava
    //    button, spinner arm, etc.) MUST be registered here. The mod reads
    //    `level.trapTriggers[]` in zec/_main.gsc to:
    //       1. Build `level.activator_traps[]` so admins/VIPs can fire the
    //          trap remotely from the shop's "Activate Trap" menu.
    //       2. Spawn the per-trigger XP/coin reward thread for the
    //          activator.
    //    If you forget to add a trigger here, the trap still works for
    //    jumpers, but the activator gets NO XP/coins for using it AND it
    //    does not appear in the shop. List EVERY activator-facing trigger
    //    targetname below. (Do NOT register secret triggers, teleporters,
    //    or jumper-only buttons.)
    // addTriggerToList("trig_trap_crusher");
    // addTriggerToList("trig_trap_lava_button");
    // addTriggerToList("trig_trap_spinner");
}


// =============================================================================
//  SECTION 0 - addTriggerToList HELPER (REQUIRED)
// =============================================================================
//  This is a convention helper - the mod itself does not define it, every
//  map must include this exact function (or copy from any existing map).
//
//  It just appends the trigger entity to `level.trapTriggers[]`. The mod
//  reads that array in zec/_main.gsc::_init() right after the map's main()
//  finishes, then wires up XP/coin rewards for the activator and adds the
//  trap to the shop's "Activate Trap" menu.
// =============================================================================
addTriggerToList(targetname)
{
    if(!isdefined(level.trapTriggers))
        level.trapTriggers = [];

    ent = getEnt(targetname, "targetname");
    if(!isdefined(ent)) return;       // silently skip typos / removed brushes

    level.trapTriggers[level.trapTriggers.size] = ent;
}


// =============================================================================
//  UTILITY HELPERS - copy these verbatim, use everywhere
// =============================================================================
//  These short functions exist to kill the most common boilerplate. Using
//  them makes your map 2x more readable AND harder to screw up.
//
//  NOTE: the examples further down (Sections 1-14) still use inline guards
//  like `if(!isdefined(player) || !isalive(player))` for educational clarity
//  - so you see what each helper is replacing. Once you have internalized
//  the patterns, use the helpers below instead.
// =============================================================================

// -- isValidPlayer(p) - single-call guard for any player reference -------------
//  Replaces:
//     if(!isdefined(p) || !isplayer(p) || !isalive(p)) continue;
//  With:
//     if(!isValidPlayer(p)) continue;
//  Use it on every waittill("trigger", player) result, every level.activ
//  check, every level.players[i] loop iteration.
isValidPlayer(p)
{
    return isdefined(p) && isplayer(p) && isalive(p);
}


// -- safeGetEnt(name) - getEnt that never crashes on duplicates ---------------
//  `getEnt("foo", "targetname")` errors if >1 entity in Radiant shares that
//  name. This wrapper falls back to `getentarray()[0]` in that case. Return
//  is undefined when no entity exists - caller MUST still isdefined-check.
safeGetEnt(targetname)
{
    // Try the single-entity fast path first. If it errors (dup names), the
    // exception is fatal for this call - we cannot catch in GSC. So just use
    // getentarray unconditionally, safer.
    arr = getentarray(targetname, "targetname");
    if(!isdefined(arr) || arr.size == 0) return undefined;
    return arr[0];
}


// -- canUse(ent, delay_sec) - cooldown gate for trap/switch reuse -------------
//  Anti-spam for activator-controlled traps. First call returns true and
//  stamps the entity with getTime(). Subsequent calls within `delay_sec`
//  return false. After the window expires it resets automatically.
//  Typical use:
//     while(true) {
//         trig waittill("trigger", user);
//         if(!isValidPlayer(user)) continue;
//         if(!canUse(trig, 10)) {
//             user iPrintln("^1Trap on cooldown");
//             continue;
//         }
//         // ...fire trap...
//     }
canUse(ent, delay_sec)
{
    if(!isdefined(ent)) return false;
    now = getTime();
    if(isdefined(ent.lastUseTime) && (now - ent.lastUseTime) < (delay_sec * 1000))
        return false;
    ent.lastUseTime = now;
    return true;
}


// -- debugPrint(msg) - console-only logging for map testing -------------------
//  Flip `level.debug = true;` at the top of main() to see your messages in
//  qconsole.log during playtest. Flip back to false before shipping so
//  players do not see your dev noise. Uses `println()` which only goes to
//  the server console, not the client.
debugPrint(msg)
{
    if(isdefined(level.debug) && level.debug)
        println("[MAP] " + msg);
}


// -- freeze_on_tps(time) - kill momentum after a teleport ---------------------
//  After a setOrigin the player keeps their pre-teleport velocity. Freezing
//  controls for a fraction of a second (then unfreezing in a worker thread)
//  cleanly stops them at the destination. Use after every setOrigin.
//  For PvP arena countdowns use a longer freeze (3-4 sec) that matches the
//  countdown_timer_string() duration.
freeze_on_tps(time)
{
    self freezeControls(true);
    self thread _unfreeze_after(time);
}

_unfreeze_after(time)
{
    self endon("disconnect");
    wait time;
    if(isalive(self))
        self freezeControls(false);
}


// -- countdown_timer_string(time, end_string, color) - 3..2..1..GO ------------
//  Reusable countdown banner using iPrintLnBold. Pair with freeze_on_tps()
//  before a fight starts so players cannot move during the count.
countdown_timer_string(time, end_string, color)
{
    if(!isdefined(color)) color = "^3";
    for(i = time; i > 0; i--) {
        iPrintLnBold(color + i);
        wait 1;
    }
    iPrintLnBold(end_string);
}


// -- GetActivator() - safe override that never returns "Noactivator" string ---
//  level.activ (set by the mod's built-in GetActivator) is the STRING
//  "Noactivator" when no one is on axis. That breaks every
//      if(isdefined(level.activ)) level.activ setOrigin(...)
//  call (string passes isdefined, then crashes on the method).
//  This local override iterates players and returns undefined when no axis
//  player is alive - so a single `if(!isplayer(activator))` guard is enough.
//  Defining your own GetActivator() shadows the built-in ONLY inside this
//  map's .gsc - other files keep using the original. That is what we want.
GetActivator()
{
    players = getentarray("player", "classname");
    for(i = 0; i < players.size; i++)
    {
        p = players[i];
        if(isdefined(p) && isplayer(p) && isalive(p) && p.pers["team"] == "axis")
            return p;
    }
    return undefined;
}


// =============================================================================
//  SECTION 1 - HELLO WORLD (the simplest possible example)
// =============================================================================
//  Read this first. It is 6 lines of actual code. Once you understand what
//  each line does, every other section in this file will make sense.
//
//  What it does: when a player walks into a trigger named "hello_trig",
//  print "Hello, <playername>!" to everyone.
//
//  In Radiant you need:
//    * a brush made into a `trigger_multiple`
//    * with KVP `targetname` = `hello_trig`
// =============================================================================
simple_door_example()
{
    // 1. Find the trigger by its Radiant targetname.
    trig = getEnt("hello_trig", "targetname");

    // 2. If the trigger does not exist (wrong targetname / removed brush),
    //    quietly stop. Better than crashing later.
    if(!isdefined(trig)) return;

    // 3. Wait forever, reacting to each trigger fire.
    while(true)
    {
        // 4. Pause until a player walks into the trigger. The player
        //    entity is returned in `player`.
        trig waittill("trigger", player);

        // 5. The player may have disconnected / died between triggering
        //    and us getting the CPU back. `isValidPlayer` catches all
        //    three bad cases (undefined / not-a-player / dead).
        if(!isValidPlayer(player)) continue;

        // 6. Print the greeting to all players.
        iPrintlnBold("^5Hello, " + player.name + "!");
    }
}


// =============================================================================
//  SECTION 2 - START DOOR
// =============================================================================
//  Opens the start door at round begin. Most Deathrun maps have a barrier
//  that opens when the round actually starts (jumpers and activator placed).
//  Uses `level waittill("round_started")` to react to that engine event.
// =============================================================================
startdoor()
{
    door = getEnt("startdoor", "targetname");
    if(!isdefined(door)) return;        // RULE 1: guard

    // Wait for the round to actually begin (jumpers + activator placed).
    level waittill("round_started");

    door moveZ(200, 2);  // open up by 200 units over 2 seconds
}


// =============================================================================
//  SECTION 3 - TRAP: ONE-SHOT BRUSH MOVER
// =============================================================================
//  Activator hits trigger once -> brush slams down -> trap consumed.
//  Pattern: trigger.delete() AFTER first use so it cannot fire again.
// =============================================================================
trap_crusher()
{
    trig  = getEnt("trig_trap_crusher", "targetname");
    brush = getEnt("brush_trap_crusher", "targetname");
    if(!isdefined(trig) || !isdefined(brush)) return;

    trig setHintString("Press [USE] to crush");

    trig waittill("trigger", user);

    // Optional: only let activators trigger it (block jumpers from killing
    // themselves with their own trap).
    // Reminder: "axis" = activator (red), "allies" = jumpers (green).
    if(!isdefined(user) || !isplayer(user)) return;
    if(user.team != "axis") {
        user iPrintlnBold("^1Only the activator can use this trap");
        return;
    }

    if(isdefined(trig)) trig delete();   // single-use

    brush moveZ(-200, 0.3);
    wait 2;
    brush moveZ(200, 1);
}


// =============================================================================
//  SECTION 4 - TRAP: CONTINUOUS DAMAGE ZONE (lava/water/spikes)
// =============================================================================
//  A volume that kills any jumper inside it. Loop runs forever, sampling
//  every 0.1s for any player touching the brush.
// =============================================================================
trap_lava()
{
    lava_brush = getEnt("trap_lava_volume", "targetname");
    if(!isdefined(lava_brush)) return;

    while(true)
    {
        // Sample all players. RULE 5: this loop ALWAYS waits, so it cannot
        // hang the server even if there are zero players.
        players = getentarray("player", "classname");
        for(i = 0; i < players.size; i++)
        {
            // RULE 2: skip dead/disconnected players defensively.
            if(!isdefined(players[i]) || !isalive(players[i])) continue;

            // Only kill jumpers (allies). Activator (axis) walks through it.
            if(players[i].team != "allies") continue;

            if(players[i] istouching(lava_brush))
            {
                // Inflict instant kill. The "MOD_BURNED" mean-of-death gives a
                // proper death message + scoreboard icon.
                players[i] suicide();
            }
        }
        wait 0.1;
    }
}


// =============================================================================
//  SECTION 5 - TRAP: PERIODIC SPINNING/MOVING OBSTACLE
// =============================================================================
//  Pattern for traps that move on their own without trigger. Use endon to
//  cleanly stop them at round end.
// =============================================================================
trap_spinner()
{
    obj = getEnt("trap_spinner_obj", "targetname");
    if(!isdefined(obj)) return;

    level endon("endround");  // stop loop when round ends

    while(true)
    {
        if(!isdefined(obj)) return;
        obj rotateYaw(360, 3);            // full spin in 3 sec
        wait 3;
        // No need for another wait - rotateYaw blocks the thread for its
        // duration. The endon above kills the thread cleanly mid-rotation
        // if round ends.
    }
}


// =============================================================================
//  SECTION 6 - TELEPORTER
// =============================================================================
//  Player walks into trigger -> teleports to a script_origin entity placed
//  in Radiant. setOrigin moves position, setPlayerAngles sets view direction.
// =============================================================================
teleport_skip()
{
    trig = getEnt("trig_teleport_skip", "targetname");
    dest = getEnt("origin_teleport_skip", "targetname");
    if(!isdefined(trig) || !isdefined(dest)) return;

    trig setHintString("Press [USE] to skip ahead");

    while(true)
    {
        trig waittill("trigger", player);

        if(!isdefined(player) || !isalive(player)) continue;

        player setOrigin(dest.origin);
        player setPlayerAngles(dest.angles);

        // Optional: small visual feedback so the player knows they teleported.
        player playLocalSound("teleport_blink");
    }
}


// =============================================================================
//  SECTION 7 - COMBAT ROOM (sniper/knife/AK end-room)
// =============================================================================
//  Player triggers a "weapon room" volume -> player and activator are
//  teleported to fight zones, given matching weapons, frozen briefly for
//  countdown, then released to fight. THIS IS THE MOST CRASH-PRONE PATTERN
//  IN DEATHRUN MAPS - copy it carefully.
//
//  CRITICAL: every line that touches `activator` or `player` is guarded.
//  When you copy this, do NOT remove the guards.
// =============================================================================
combat_room_sniper()
{
    trig    = getEnt("trig_combat_sniper",  "targetname");
    jp_pos  = getEnt("origin_combat_sniper_jumper", "targetname");
    ac_pos  = getEnt("origin_combat_sniper_acti",   "targetname");
    if(!isdefined(trig) || !isdefined(jp_pos) || !isdefined(ac_pos)) return;

    trig setHintString("Press [USE] to enter Sniper Room");

    while(true)
    {
        trig waittill("trigger", player);

        // Guard 1: player vanished between trigger and now.
        if(!isdefined(player) || !isalive(player)) continue;

        // Guard 2: GetActivator() returns the string "Noactivator" when no
        // one is on axis. isplayer() returns false for strings, so this
        // catches both cases (undefined + Noactivator string).
        activator = GetActivator();
        if(!isplayer(activator)) {
            player iPrintlnBold("^1No activator - room unavailable");
            continue;
        }

        // -- Setup both players --
        player    setOrigin       (jp_pos.origin);
        player    setPlayerAngles (jp_pos.angles);
        activator setOrigin       (ac_pos.origin);
        activator setPlayerAngles (ac_pos.angles);

        player    takeAllWeapons();
        activator takeAllWeapons();
        player    giveWeapon("m40a3_mp");
        activator giveWeapon("m40a3_mp");
        player    giveMaxAmmo("m40a3_mp");
        activator giveMaxAmmo("m40a3_mp");
        player    switchToWeapon("m40a3_mp");
        activator switchToWeapon("m40a3_mp");

        player    freezeControls(true);
        activator freezeControls(true);

        iPrintLnBold("^5" + player.name + " ^7vs ^5" + activator.name + " ^7- Sniper Room");

        // Countdown 3..2..1..GO. Re-check isalive/isplayer EVERY second
        // because either party can die during the countdown (e.g. trap kill
        // by another activator action).
        for(c = 3; c >= 1; c--) {
            if(isalive(player))                              player    iPrintLnBold("^5" + c);
            if(isplayer(activator) && isalive(activator))    activator iPrintLnBold("^5" + c);
            wait 1;
        }
        if(isalive(player))                              player    iPrintLnBold("^7FIGHT!");
        if(isplayer(activator) && isalive(activator))    activator iPrintLnBold("^7FIGHT!");

        if(isalive(player))                              player    freezeControls(false);
        if(isplayer(activator) && isalive(activator))    activator freezeControls(false);

        // Wait until player dies or leaves before allowing a new entry.
        while(isdefined(player) && isalive(player))
            wait 1;
    }
}

// Variant: knife room. Same skeleton, different weapon.
combat_room_knife()
{
    trig    = getEnt("trig_combat_knife",  "targetname");
    jp_pos  = getEnt("origin_combat_knife_jumper", "targetname");
    ac_pos  = getEnt("origin_combat_knife_acti",   "targetname");
    if(!isdefined(trig) || !isdefined(jp_pos) || !isdefined(ac_pos)) return;

    trig setHintString("Press [USE] to enter Knife Room");

    while(true)
    {
        trig waittill("trigger", player);
        if(!isdefined(player) || !isalive(player)) continue;

        activator = GetActivator();
        if(!isplayer(activator)) {
            player iPrintlnBold("^1No activator - room unavailable");
            continue;
        }

        player    setOrigin       (jp_pos.origin);
        player    setPlayerAngles (jp_pos.angles);
        activator setOrigin       (ac_pos.origin);
        activator setPlayerAngles (ac_pos.angles);

        player    takeAllWeapons();
        activator takeAllWeapons();
        player    giveWeapon("knife_mp");
        activator giveWeapon("knife_mp");
        player    switchToWeapon("knife_mp");
        activator switchToWeapon("knife_mp");

        iPrintLnBold("^6" + player.name + " ^7entered the Knife Room");

        while(isdefined(player) && isalive(player))
            wait 1;
    }
}


// =============================================================================
//  SECTION 8 - SECRET ROUTE WITH XP REWARD
// =============================================================================
//  Player finds the secret entrance, triggers it once -> teleport to secret
//  start + tag for the leaderboard. Reaching the secret end gives bonus XP.
// =============================================================================
secret_easy()
{
    enter_trig = getEnt("trig_secret_enter",  "targetname");
    enter_pos  = getEnt("origin_secret_start", "targetname");
    end_trig   = getEnt("trig_secret_end",     "targetname");
    end_pos    = getEnt("origin_secret_end",   "targetname");
    if(!isdefined(enter_trig) || !isdefined(enter_pos)) return;

    // Spawn a thread that handles the END trigger separately (so multiple
    // players can be in the secret simultaneously).
    if(isdefined(end_trig) && isdefined(end_pos))
        thread secret_easy_end(end_trig, end_pos);

    while(true)
    {
        enter_trig waittill("trigger", player);
        if(!isdefined(player) || !isalive(player)) continue;
        if(player.team != "allies") continue;   // only jumpers

        player setOrigin(enter_pos.origin);
        player setPlayerAngles(enter_pos.angles);

        // tagSecret(N) marks the player's run as having taken secret route N.
        // Required for the per-route leaderboard. N = 1, 2, or 3 (matches
        // vlct_secret_count and vlct_secret_N_name set in main()).
        player zec\_secrets::tagSecret(1);

        iPrintlnBold("^5" + player.name + " ^7entered the easy secret");
    }
}

secret_easy_end(end_trig, end_pos)
{
    while(true)
    {
        end_trig waittill("trigger", player);
        if(!isdefined(player) || !isalive(player)) continue;

        player setOrigin(end_pos.origin);
        player setPlayerAngles(end_pos.angles);
        player braxi\_rank::giveRankXP("", 500);   // 500 XP for completing secret
        iPrintlnBold("^5" + player.name + " ^7completed the easy secret!");
    }
}


// =============================================================================
//  SECTION 9 - MAP CREDITS (one-time message at round start)
// =============================================================================
map_credits()
{
    wait 8;   // let players spawn first
    iPrintln("^3Map by ^5YourName ^7- thanks for playing!");
    wait 5;
    iPrintln("^3Tested by: ^5tester1, tester2");
}


// =============================================================================
//  SECTION 10 - RESET TRAPS ON ROUND END (best practice)
// =============================================================================
//  If your traps mutate brush positions or delete things, on the next round
//  Radiant will RE-create the entities (entities reset every round_restart).
//  But if you have level.X variables tracking state, reset them here.
// =============================================================================
reset_traps_on_round_end()
{
    while(true)
    {
        level waittill("endround");

        // Clear any flags we set during the round.
        // Example:
        // level.crusher_used = undefined;
    }
}


// =============================================================================
//  ADVANCED TECHNIQUES - copy as needed
// =============================================================================
//  These are patterns used in shipped maps. They cover effects, sound,
//  custom HUDs, multi-stage sequences, and gotchas you will hit when your
//  map gets bigger.
// =============================================================================


// -----------------------------------------------------------------------------
//  ADVANCED 1 - FX (visual effects: fire, sparks, smoke, blood)
// -----------------------------------------------------------------------------
//  Three-step pattern:
//    a) loadfx() in main() - precaches the effect (must be in main, NOT a
//       per-trigger function, otherwise it crashes the asset loader).
//    b) playfx() to spawn a one-shot effect at a position.
//    c) spawnFx() + triggerFx() for a persistent looping effect.
//
//  FX paths are relative to fx/ folder. The .efx files live there.
// -----------------------------------------------------------------------------
fx_setup_in_main()
{
    // Add these calls TO YOUR main() function, before any thread starts:
    //   level._effect["fire"]      = loadfx("fire/firelp_med_pm");
    //   level._effect["explosion"] = loadfx("explosions/default_explosion");
    //   level._effect["sparks"]    = loadfx("misc/light_marker_red_blink");
    //
    // Then the helpers below use level._effect["..."] to spawn instances.
}

// One-shot FX at a position (e.g. trap explosion when triggered).
play_fx_explosion_at(origin)
{
    if(!isdefined(level._effect) || !isdefined(level._effect["explosion"])) return;
    playfx(level._effect["explosion"], origin);
}

// Persistent looping FX (e.g. eternal flame next to a torch). Place a
// script_origin in Radiant where you want the effect.
spawn_eternal_fire()
{
    pos = getEnt("origin_torch_fire", "targetname");
    if(!isdefined(pos) || !isdefined(level._effect) || !isdefined(level._effect["fire"])) return;

    fx_ent = spawnfx(level._effect["fire"], pos.origin);
    triggerfx(fx_ent);   // start the loop
    // To stop: fx_ent delete();   (engine destroys the FX with the entity)
}


// -----------------------------------------------------------------------------
//  ADVANCED 2 - SOUND: 3D positional, looping ambient, music change
// -----------------------------------------------------------------------------
//  Sound aliases come from your map's .csv soundfile. Common patterns:
//    a) playSoundAtPosition  - one-shot 3D sound at a coordinate
//    b) playLoopSound        - persistent loop attached to an entity
//    c) ambientPlay          - background music (replaces previous)
//    d) playLocalSound       - one player only (e.g. teleport blink)
// -----------------------------------------------------------------------------
sound_examples()
{
    // a) One-shot sound at a brush's center (e.g. trap activation):
    //     trap_brush = getEnt("trap_brush", "targetname");
    //     playSoundAtPosition("trap_crusher_smash", trap_brush.origin);

    // b) Looping sound attached to an entity (e.g. waterfall, machinery):
    //     waterfall = getEnt("waterfall_sound_origin", "targetname");
    //     waterfall playLoopSound("amb_waterfall");
    //     // To stop:  waterfall stopLoopSound();

    // c) Background music (fades out previous, plays new):
    //     ambientStop(2);                    // fade out current music in 2 sec
    //     ambientPlay("music_combat_room");  // start new track

    // d) One player only (does not bother others):
    //     player playLocalSound("teleport_blink");
}


// -----------------------------------------------------------------------------
//  ADVANCED 3 - CUSTOM HUD ELEMENT (countdown timer, banner)
// -----------------------------------------------------------------------------
//  newHudElem() creates a level-wide HUD that all players see.
//  newClientHudElem(player) creates a private HUD only that player sees.
//
//  WARNING: each player has a hard cap of ~31 client HUDs. Going over
//  silently fails (the HUD is created but never renders). If you need
//  a per-player HUD, prefer dvar-driven .menu overlays - ask the mod
//  maintainer.
// -----------------------------------------------------------------------------
show_event_countdown(seconds_left, message)
{
    hud = newHudElem();
    hud.x             = 0;
    hud.y             = 100;
    hud.alignX        = "center";
    hud.alignY        = "middle";
    hud.horzAlign     = "center";
    hud.vertAlign     = "top";
    hud.font          = "objective";
    hud.fontScale     = 2.0;
    hud.color         = (1, 0.7, 0);
    hud.alpha         = 1;
    hud.foreground    = true;

    while(seconds_left > 0)
    {
        hud setText("^3" + message + ": ^7" + seconds_left);
        wait 1;
        seconds_left--;
    }
    hud setText("^2GO!");
    wait 1.5;
    hud destroy();   // ALWAYS destroy when done - HUDs leak otherwise
}


// -----------------------------------------------------------------------------
//  ADVANCED 4 - MULTI-STAGE TRAP (chained sequence with timing)
// -----------------------------------------------------------------------------
//  Common pattern: pull lever -> rumble -> 2 sec delay -> wall slides ->
//  spikes drop -> reset after 30 sec. Each stage is a separate move that
//  blocks until done; use waittill("movedone") for accurate timing.
// -----------------------------------------------------------------------------
trap_chain_sequence()
{
    trig    = getEnt("trig_trap_chain", "targetname");
    lever   = getEnt("lever_trap_chain", "targetname");
    wall    = getEnt("wall_trap_chain", "targetname");
    spikes  = getEnt("spikes_trap_chain", "targetname");
    if(!isdefined(trig) || !isdefined(lever) || !isdefined(wall) || !isdefined(spikes)) return;

    trig setHintString("Press [USE] to start the chain trap");

    while(true)
    {
        trig waittill("trigger", user);
        if(!isdefined(user) || !isplayer(user)) continue;
        if(user.team != "axis") continue;

        // Stage 1: lever pulls down
        lever rotatePitch(80, 0.3);
        lever waittill("rotatedone");

        // Stage 2: rumble pause
        wait 1;
        playSoundAtPosition("rumble_low", wall.origin);

        // Stage 3: wall slides into corridor
        wall moveX(-200, 1.5);
        wall waittill("movedone");

        // Stage 4: spikes drop
        spikes moveZ(-100, 0.4);
        spikes waittill("movedone");

        // Stage 5: hold for 5 sec to give jumpers time to die
        wait 5;

        // Stage 6: reset
        spikes moveZ(100, 1);
        wall   moveX(200, 2);
        lever  rotatePitch(-80, 0.5);
        wait 3;
        // ready for next activation
    }
}


// -----------------------------------------------------------------------------
//  ADVANCED 5 - TRAP COOLDOWN (prevent activator spam)
// -----------------------------------------------------------------------------
//  Without a cooldown, an activator can mash [USE] and re-fire a trap every
//  frame. Pattern: track last-fired time on the trigger entity itself, only
//  re-allow after N seconds.
// -----------------------------------------------------------------------------
trap_with_cooldown()
{
    trig = getEnt("trig_trap_cooldown", "targetname");
    if(!isdefined(trig)) return;
    trig setHintString("Press [USE] to fire (10s cooldown)");

    while(true)
    {
        trig waittill("trigger", user);
        if(!isdefined(user) || !isplayer(user)) continue;

        // Check cooldown
        if(isdefined(trig.last_fired)) {
            elapsed = (getTime() - trig.last_fired) / 1000;
            if(elapsed < 10) {
                user iPrintln("^1Trap on cooldown - " + int(10 - elapsed) + "s left");
                continue;
            }
        }
        trig.last_fired = getTime();

        // ...do the trap action here...
        iPrintlnBold("^3" + user.name + " ^7fired the trap!");
    }
}


// -----------------------------------------------------------------------------
//  ADVANCED 6 - SHOOT-TO-ACTIVATE (button you fire at, not press)
// -----------------------------------------------------------------------------
//  For shootable buttons / breakable glass / hidden secrets. Use
//  waittill("damage", ...) instead of "trigger". The damage hook fires when
//  the brush takes ANY damage above threshold.
//
//  In Radiant: brush must be a script_brushmodel with `health` set to a
//  positive number (e.g. 100). When health reaches 0 it fires "damage".
// -----------------------------------------------------------------------------
shootable_secret_button()
{
    btn = getEnt("button_shoot_secret", "targetname");
    if(!isdefined(btn)) return;

    btn waittill("damage", amount, attacker);
    if(!isdefined(attacker) || !isplayer(attacker)) return;

    iPrintlnBold("^5" + attacker.name + " ^7found the shootable secret!");
    btn delete();   // remove the button so it cannot be re-shot

    // Open hidden door
    door = getEnt("door_shoot_secret", "targetname");
    if(isdefined(door)) door moveZ(150, 1.5);
}


// -----------------------------------------------------------------------------
//  ADVANCED 7 - JUMP PAD (bouncing trigger that boosts the player up)
// -----------------------------------------------------------------------------
//  Touch trigger -> add upward velocity. The braxi\_common::bounce helper
//  does the math. Jump pads chain (you can have many on one map, all using
//  the same handler).
// -----------------------------------------------------------------------------
jump_pad()
{
    pads = getentarray("trig_jumppad", "targetname");   // multiple by same name
    for(i = 0; i < pads.size; i++)
        pads[i] thread jump_pad_handler(450);            // 450 = bounce strength
}

jump_pad_handler(strength)
{
    while(true)
    {
        self waittill("trigger", player);
        if(!isdefined(player) || !isalive(player)) continue;

        // Push the player straight up with given strength.
        // Direction (0,0,1) = pure vertical. For diagonal pads, change vector.
        player braxi\_common::bounce((0, 0, 1), strength);
    }
}


// -----------------------------------------------------------------------------
//  ADVANCED 8 - ANTI-GLITCH ZONE (kill players who escape map bounds)
// -----------------------------------------------------------------------------
//  Place a big trigger_multiple covering all out-of-bounds areas. Anyone
//  inside it dies. Use trigger_hurt in Radiant if you want it always-on,
//  or this script pattern if you want conditional kill (e.g. only if not
//  in spectator).
// -----------------------------------------------------------------------------
anti_glitch_zone()
{
    trig = getEnt("trig_antiglitch", "targetname");
    if(!isdefined(trig)) return;

    while(true)
    {
        trig waittill("trigger", player);
        if(!isdefined(player) || !isalive(player)) continue;
        if(player.sessionstate != "playing") continue;

        player iPrintln("^1Out of bounds - respawning");
        player suicide();
    }
}


// -----------------------------------------------------------------------------
//  ADVANCED 9 - FIRST-FINISHER ANNOUNCEMENT (banner notification)
// -----------------------------------------------------------------------------
//  notifyMessage is the big banner that pops up at the top of the screen
//  with title + subtitle + duration. Use for important map events
//  (first finisher, secret completed, special weapon picked up).
// -----------------------------------------------------------------------------
announce_to_all(title, subtitle, duration)
{
    noti = SpawnStruct();
    noti.titleText  = title;
    noti.notifyText = subtitle;
    noti.glowColor  = (1, 0.5, 0);     // orange glow
    noti.duration   = duration;
    // No icon: leave noti.iconName unset.

    players = getentarray("player", "classname");
    for(i = 0; i < players.size; i++) {
        if(!isdefined(players[i])) continue;
        players[i] thread maps\mp\gametypes\_hud_message::notifyMessage(noti);
    }
}

// Example use:
//   thread announce_to_all("^3SECRET ROOM", "^7Found by " + player.name, 5);


// -----------------------------------------------------------------------------
//  ADVANCED 10 - PLAYER POSITION TRACKING (proximity event)
// -----------------------------------------------------------------------------
//  Sometimes you cannot use a trigger (e.g. no Radiant access, dynamic zone).
//  Sample player positions on a timer and react when one is in range of a
//  point. KEEP THE TIMER GENEROUS (>=0.5 sec) - this loop runs forever.
// -----------------------------------------------------------------------------
proximity_watcher()
{
    target_pos = getEnt("origin_proximity_target", "targetname");
    if(!isdefined(target_pos)) return;

    radius_squared = 100 * 100;   // 100 units. Squared so we skip sqrt() in loop.

    while(true)
    {
        wait 0.5;

        players = getentarray("player", "classname");
        for(i = 0; i < players.size; i++)
        {
            p = players[i];
            if(!isdefined(p) || !isalive(p)) continue;
            if(p.team != "allies") continue;

            // distance2() is the squared distance - cheaper than distance().
            if(distance2(p.origin, target_pos.origin) < radius_squared)
            {
                if(!isdefined(p.in_proximity_zone))
                {
                    p.in_proximity_zone = true;
                    p iPrintln("^5You feel something nearby...");
                    // Trigger the event ONCE per player per round.
                }
            }
        }
    }
}


// -----------------------------------------------------------------------------
//  ADVANCED 11 - RANDOM TRAP SELECTOR (different trap each round)
// -----------------------------------------------------------------------------
//  At round start, pick one trap variant from a pool. Use randomInt() and
//  switch on the result. Variation keeps the map fresh.
// -----------------------------------------------------------------------------
random_trap_choice()
{
    level waittill("round_started");

    pick = randomInt(3);   // 0, 1, or 2

    switch(pick)
    {
        case 0:  thread trap_variant_fire();     break;
        case 1:  thread trap_variant_water();    break;
        case 2:  thread trap_variant_spikes();   break;
    }
}

// Stub variants - fill in like a normal trap.
trap_variant_fire()   { /* getEnt + thread loop */ }
trap_variant_water()  { /* getEnt + thread loop */ }
trap_variant_spikes() { /* getEnt + thread loop */ }


// -----------------------------------------------------------------------------
//  ADVANCED 12 - VIP / MAPPER-ONLY DOOR
// -----------------------------------------------------------------------------
//  Restrict a trigger to specific Steam GUIDs (yourself, friends). Useful
//  for hidden maker-only rooms that show off behind-the-scenes stuff.
// -----------------------------------------------------------------------------
mapper_only_door()
{
    trig = getEnt("trig_mapper_door", "targetname");
    door = getEnt("door_mapper", "targetname");
    if(!isdefined(trig) || !isdefined(door)) return;

    // Replace with your real Steam GUIDs.
    allowed_guids = strtok("76561198000000001;76561198000000002", ";");

    while(true)
    {
        trig waittill("trigger", player);
        if(!isdefined(player) || !isalive(player)) continue;

        ok = false;
        for(i = 0; i < allowed_guids.size; i++) {
            if(isdefined(player.guid) && player.guid == allowed_guids[i]) {
                ok = true;
                break;
            }
        }
        if(!ok) {
            player iPrintlnBold("^1Mapper only");
            continue;
        }

        if(isdefined(door)) door moveZ(150, 1);
        wait 5;
        if(isdefined(door)) door moveZ(-150, 1);
    }
}


// -----------------------------------------------------------------------------
//  ADVANCED 13 - WAIT FOR ALL JUMPERS DEAD (round-end hook)
// -----------------------------------------------------------------------------
//  Fire an event the moment the LAST jumper dies (e.g. play victory sound,
//  spawn a celebration FX for the activator). Built on level.players +
//  isalive sampling.
// -----------------------------------------------------------------------------
last_jumper_watcher()
{
    level endon("endround");

    while(true)
    {
        wait 1;

        alive_jumpers = 0;
        players = getentarray("player", "classname");
        for(i = 0; i < players.size; i++) {
            if(!isdefined(players[i])) continue;
            if(players[i].team == "allies" && isalive(players[i]))
                alive_jumpers++;
        }

        if(alive_jumpers == 0) {
            // All jumpers dead. Fire your event, then break.
            iPrintlnBold("^1All jumpers eliminated");
            // ...spawn FX, play sound, give activator XP, etc.
            return;
        }
    }
}


// -----------------------------------------------------------------------------
//  ADVANCED 14 - SCRIPT-SPAWNED MOVING PLATFORM (no Radiant needed)
// -----------------------------------------------------------------------------
//  Sometimes you want a moving brush that does not exist in Radiant - e.g.
//  a chase platform that only spawns when a secret is unlocked. Use
//  spawn() with classname "script_model" + a precached model.
//
//  Model paths come from xmodel/ in your CoD4 install.
// -----------------------------------------------------------------------------
spawn_chase_platform()
{
    // The model MUST be precached in main() with:
    //   precacheModel("ad_sign_diner");

    plat = spawn("script_model", (0, 0, 200));
    plat setModel("ad_sign_diner");
    plat.angles = (0, 90, 0);

    // Move along a path
    plat moveX(500, 4);
    plat waittill("movedone");
    plat moveY(300, 2);
    plat waittill("movedone");

    // Clean up - removes the entity from the world.
    plat delete();
}


// =============================================================================
//  SECTION 15 - TRAP: ONE-SHOT BOOST WITH DEBOUNCE FLAG
// =============================================================================
//  "Single fire while inside the trigger, re-arm when player leaves." Used
//  for any boost / jump-pad / wind-tunnel that should NOT spam every frame.
//  The flag attribute name should be unique - either a long random suffix
//  (player.boost_active_jzx91) or a descriptive prefix (player.boost_speed).
//  Two traps using the same flag name will fight each other.
// =============================================================================
trap_speed_boost_example()
{
    trig = getEnt("trig_speed_boost", "targetname");
    if(!isdefined(trig)) return;

    while(true)
    {
        trig waittill("trigger", player);
        if(!isValidPlayer(player)) continue;
        if(isdefined(player.boost_speed_active)) continue;     // already boosted

        player.boost_speed_active = true;
        player thread _reset_boost_speed(trig);

        vel = player getVelocity();
        player setVelocity((vel[0] * 1.5, vel[1] * 1.5, vel[2]));
        player playLocalSound("speed_boost");
    }
}

_reset_boost_speed(trigger)
{
    self endon("disconnect");
    while(self isTouching(trigger))
        wait 0.05;
    self.boost_speed_active = undefined;
}


// =============================================================================
//  SECTION 16 - TRAP: CONTINUOUS BOOST WHILE TOUCHING
// =============================================================================
//  Variant of Section 15 for effects applied EVERY frame the player is inside,
//  not just once. Common for upward shafts, wind tunnels, antigravity columns.
//  The wait 0.05 inside _wind_tunnel_maintain is critical - without it the
//  loop trips the CoD4X opcode killer.
// =============================================================================
trap_wind_tunnel_example()
{
    trig = getEnt("trig_wind_tunnel", "targetname");
    if(!isdefined(trig)) return;

    while(true)
    {
        trig waittill("trigger", player);
        if(!isValidPlayer(player)) continue;
        if(isdefined(player.in_wind_tunnel)) continue;

        player.in_wind_tunnel = true;
        player thread _wind_tunnel_maintain(trig);
    }
}

_wind_tunnel_maintain(trigger)
{
    self endon("disconnect");
    while(self isTouching(trigger))
    {
        vel = self getVelocity();
        self setVelocity((vel[0], vel[1], 600));     // sustained upward Z
        wait 0.05;
    }
    self.in_wind_tunnel = undefined;
}


// =============================================================================
//  SECTION 17 - TRAP: MULTI-TRY FALL TRAP (N lives before suicide)
// =============================================================================
//  Friendlier than instant death. Player gets N tries - each fail teleports
//  them back to a safe origin. Counter resets on death.
// =============================================================================
trap_fall_with_lives_example()
{
    trig    = getEnt("trig_fall_zone",    "targetname");
    safe_at = getEnt("origin_safe_spawn", "targetname");
    if(!isdefined(trig) || !isdefined(safe_at)) return;

    while(true)
    {
        trig waittill("trigger", player);
        if(!isValidPlayer(player)) continue;

        // First entry this life - grant 2 tries.
        if(!isdefined(player.fall_tries)) {
            player.fall_tries = 2;
            player thread _reset_fall_tries_on_death();
        }

        if(player.fall_tries > 0) {
            player setVelocity((0, 0, 0));
            player setOrigin(safe_at.origin);
            player setPlayerAngles(safe_at.angles);
            player iPrintln("Tries left: ^2" + player.fall_tries);
            player.fall_tries--;
        } else {
            player iPrintln("^1No more tries");
            player suicide();
            player.fall_tries = undefined;
        }
    }
}

_reset_fall_tries_on_death()
{
    self endon("disconnect");
    self waittill("death");
    self.fall_tries = undefined;
}


// =============================================================================
//  SECTION 18 - TRAP: ANTI-STUCK NUDGE
// =============================================================================
//  When a complex collider can wedge a player in place, count ticks they
//  spend touching the trigger. After a threshold, push them toward a known
//  clear point with a calculated velocity vector.
// =============================================================================
trap_antistuck_zone_example()
{
    trig   = getEnt("trig_stuck_zone",     "targetname");
    center = getEnt("origin_stuck_escape", "targetname");
    if(!isdefined(trig) || !isdefined(center)) return;

    while(true)
    {
        trig waittill("trigger", player);
        if(!isValidPlayer(player)) continue;
        if(isdefined(player.stuck_watch_active)) continue;

        player.stuck_watch_active = 1;
        player thread _stuck_watcher(trig, center);
    }
}

_stuck_watcher(trigger, center)
{
    self endon("disconnect");
    while(self isTouching(trigger))
    {
        wait 0.1;
        self.stuck_watch_active++;
        if(self.stuck_watch_active > 10)
        {
            dir = vectorNormalize((center.origin + (0, 0, 800)) - self.origin);
            self setVelocity(dir * 600);
            self iPrintln("^3Unstuck");
            wait 1;     // give the velocity a moment to clear the volume
            break;
        }
    }
    self.stuck_watch_active = undefined;
}


// =============================================================================
//  SECTION 19 - TRAP DIRECTION ARROW (visual hint, only for players in zone)
// =============================================================================
//  Many maps spawn floating arrows pointing at the trap button. Showing them
//  only to players currently inside the trigger zone keeps the screen clean
//  for everyone else.
//
//  In Radiant: create one or more script_model entities (any arrow model)
//  named "<trap_name>_arrow" near the trigger. They will be hidden by
//  default, then ShowToPlayer per touching player.
//
//  Wiring:
//      trap_crusher() {
//          trig  = getEnt("trig_trap_crusher",  "targetname");
//          brush = getEnt("brush_trap_crusher", "targetname");
//          thread arrow_logic("trap_crusher", trig);   // <-- shows arrows
//          trig waittill("trigger", user);
//          arrow_kill_notify("trap_crusher");          // <-- hides + deletes
//          // ...rest of trap...
//      }
// =============================================================================
arrow_logic(trap_name, trigger)
{
    level endon(trap_name);

    arrows = getentarray(trap_name + "_arrow", "targetname");
    for(i = 0; i < arrows.size; i++)
        arrows[i] thread _arrow_bob();

    while(true)
    {
        wait 0.05;
        players = getentarray("player", "classname");
        touching = [];
        for(i = 0; i < players.size; i++) {
            if(isValidPlayer(players[i]) && players[i] isTouching(trigger))
                touching[touching.size] = players[i];
        }
        for(j = 0; j < arrows.size; j++) {
            if(!isdefined(arrows[j])) continue;
            arrows[j] hide();
            for(k = 0; k < touching.size; k++)
                arrows[j] showToPlayer(touching[k]);
        }
    }
}

_arrow_bob()
{
    self endon("death");
    forward    = anglesToForward(self.angles);
    initial    = self.origin;
    moveto_pos = self.origin + (forward * 30);
    while(true) {
        self moveTo(moveto_pos, 1.5, 0.5, 0.5);   wait 1.6;
        self moveTo(initial,    1.5, 0.5, 0.5);   wait 1.6;
    }
}

arrow_kill_notify(trap_name)
{
    level notify(trap_name);
    arrows = getentarray(trap_name + "_arrow", "targetname");
    for(i = 0; i < arrows.size; i++)
        if(isdefined(arrows[i])) arrows[i] delete();
}


// =============================================================================
//  SECTION 20 - GENERIC TELEPORTER HELPER
// =============================================================================
//  Replaces ~20 lines of teleport boilerplate with one parametrised function.
//  Optional freeze, optional callback fired on the player after arrival
//  (function pointer via [[ ]]() syntax).
//
//  Wiring in main():
//      trig = getEnt("trig_teleport_skip",   "targetname");
//      dest = getEnt("origin_teleport_skip", "targetname");
//      thread teleporter_logic(trig, dest, true, undefined, undefined);
//
//      // Teleporter into a secret with per-player init callback:
//      trig = getEnt("trig_secret_enter", "targetname");
//      dest = getEnt("origin_secret",     "targetname");
//      thread teleporter_logic(trig, dest, true, 0.05, ::on_enter_secret);
//
//      on_enter_secret() {
//          self setVelocity((180, 180, 0));
//          self.secret_streak = 0;
//          self iPrintln("^5Secret entered");
//      }
//
//  ::function_name creates a function pointer; [[ptr]]() calls it. Pointers
//  can be passed as parameters - this is the foundation for reusable
//  abstractions in GSC.
// =============================================================================
teleporter_logic(trigger, exit_ent, set_angles, freeze, on_arrive)
{
    if(!isdefined(trigger) || !isdefined(exit_ent)) return;

    while(true)
    {
        trigger waittill("trigger", player);
        if(!isValidPlayer(player)) continue;

        player setVelocity((0, 0, 0));
        player setOrigin(exit_ent.origin);
        if(isdefined(set_angles) && set_angles)
            player setPlayerAngles(exit_ent.angles);

        if(isdefined(freeze))
            player freeze_on_tps(freeze);

        if(isdefined(on_arrive))
            player thread [[on_arrive]]();
    }
}


// =============================================================================
//  SECTION 21 - SINGLE-INSTANCE THREAD PATTERN (notify-cancellation)
// =============================================================================
//  When a function should have AT MOST ONE instance per entity running at a
//  time - HUDs, ammo refill loops, status timers - start with a notify and
//  an endon on the same name. Any later call cancels the previous one.
//
//  Real-world example: keep one weapon's ammo topped up until the player
//  dies, disconnects, or the function is re-called.
//
//  Each call replaces the previous one - safe to call twice in a row:
//      activator thread keep_ammo_topped("h2_m79a_mp", 1);
// =============================================================================
keep_ammo_topped(weapon, refresh_sec)
{
    self notify("ammo_topup_active");      // cancel any prior instance
    self endon("ammo_topup_active");        // get cancelled by next start
    self endon("disconnect");
    self endon("death");

    while(true)
    {
        self setWeaponAmmoStock(weapon, 200);
        wait refresh_sec;
    }
}


// =============================================================================
//  SECTION 22 - MULTI-ROOM EXCLUSIVITY (one PvP room at a time)
// =============================================================================
//  Many maps have several end-rooms (sniper / knife / jump / launcher) and
//  want to lock the others while a fight is in progress.
//
//  Setup in main() - save trigger refs once so any room can see them:
//      level.knife_trigger    = getEnt("trig_combat_knife",  "targetname");
//      level.sniper_trigger   = getEnt("trig_combat_sniper", "targetname");
//      level.jump_trigger     = getEnt("trig_combat_jump",   "targetname");
//      level.launcher_trigger = getEnt("trig_combat_rpg",    "targetname");
//
//  Then each room calls `player thread disable_triggers_untill_death()`
//  AFTER the activator/player guards pass. Triggers re-open when the player
//  dies or disconnects (whichever fires first).
// =============================================================================
disable_triggers_untill_death()
{
    if(isdefined(level.knife_trigger))    level.knife_trigger    thread maps\mp\_utility::triggerOff();
    if(isdefined(level.sniper_trigger))   level.sniper_trigger   thread maps\mp\_utility::triggerOff();
    if(isdefined(level.jump_trigger))     level.jump_trigger     thread maps\mp\_utility::triggerOff();
    if(isdefined(level.launcher_trigger)) level.launcher_trigger thread maps\mp\_utility::triggerOff();

    self common_scripts\utility::waittill_any("death", "disconnect");

    if(isdefined(level.knife_trigger))    level.knife_trigger    thread maps\mp\_utility::triggerOn();
    if(isdefined(level.sniper_trigger))   level.sniper_trigger   thread maps\mp\_utility::triggerOn();
    if(isdefined(level.jump_trigger))     level.jump_trigger     thread maps\mp\_utility::triggerOn();
    if(isdefined(level.launcher_trigger)) level.launcher_trigger thread maps\mp\_utility::triggerOn();
}


// =============================================================================
//  SECTION 23 - FIGHT HUD BANNER (Player vs Activator - Sniper Room)
// =============================================================================
//  Big top-of-screen banner shown for ~3 sec when a fight starts.
//  Self-cancelling - a second fight replaces the first banner via the
//  notify-cancellation pattern from Section 21.
//
//  Note: level.hud_fight and level.hud_fight2 slots are SHARED across all
//  rooms - intentional, two fights cannot show their banner simultaneously.
//  For per-room HUDs, use unique level slot names per room.
// =============================================================================
fightHUD(room_name, jumper, activ)
{
    self endon("disconnect");
    self notify("fightHUD_active");
    self endon("fightHUD_active");

    jumper_name = "?";
    activ_name  = "?";
    if(isplayer(jumper)) jumper_name = jumper.name;
    if(isplayer(activ))  activ_name  = activ.name;

    duration = 3;

    if(isdefined(level.hud_fight))  level.hud_fight  destroy();
    if(isdefined(level.hud_fight2)) level.hud_fight2 destroy();

    level.hud_fight = newHudElem();
    level.hud_fight.x = 0;            level.hud_fight.y = 85;
    level.hud_fight.alignX = "center";  level.hud_fight.alignY = "top";
    level.hud_fight.horzAlign = "center"; level.hud_fight.vertAlign = "top";
    level.hud_fight.font = "objective"; level.hud_fight.fontScale = 1.5;
    level.hud_fight.alpha = 1;
    level.hud_fight setText("^3" + room_name);

    level.hud_fight2 = newHudElem();
    level.hud_fight2.x = 0;            level.hud_fight2.y = 100;
    level.hud_fight2.alignX = "center";  level.hud_fight2.alignY = "top";
    level.hud_fight2.horzAlign = "center"; level.hud_fight2.vertAlign = "top";
    level.hud_fight2.font = "objective"; level.hud_fight2.fontScale = 1.5;
    level.hud_fight2.alpha = 1;
    level.hud_fight2 setText("^3" + jumper_name + " ^7VS ^3" + activ_name);

    wait duration;

    if(isdefined(level.hud_fight))  level.hud_fight  destroy();
    if(isdefined(level.hud_fight2)) level.hud_fight2 destroy();
}


// =============================================================================
//  SECTION 24 - POLISHED COMBAT-ROOM TEMPLATE (with helpers)
// =============================================================================
//  Tighter combat-room version that uses the helpers from this file:
//  GetActivator(), freeze_on_tps(), countdown_timer_string(),
//  disable_triggers_untill_death(), fightHUD().
//
//  Behavior is identical to combat_room_sniper() in Section 7. This version
//  is half the size because all the boilerplate moved into helpers.
// =============================================================================
combat_room_sniper_v2()
{
    trig    = getEnt("trig_combat_sniper",          "targetname");
    jp_pos  = getEnt("origin_combat_sniper_jumper", "targetname");
    ac_pos  = getEnt("origin_combat_sniper_acti",   "targetname");
    if(!isdefined(trig) || !isdefined(jp_pos) || !isdefined(ac_pos)) return;

    trig setHintString("Press [USE] to enter Sniper Room");

    while(true)
    {
        trig waittill("trigger", player);
        if(!isValidPlayer(player)) continue;

        activator = GetActivator();
        if(!isplayer(activator)) {
            player iPrintln("^1No Activator Detected");
            continue;
        }
        if(player == activator) {
            player iPrintln("^1Activator Can't Enter Room");
            continue;
        }

        player thread disable_triggers_untill_death();
        thread fightHUD("Sniper Room", player, activator);

        player    setOrigin       (jp_pos.origin);
        activator setOrigin       (ac_pos.origin);
        player    setPlayerAngles (jp_pos.angles);
        activator setPlayerAngles (ac_pos.angles);

        player    freeze_on_tps(4);
        activator freeze_on_tps(4);
        thread countdown_timer_string(4, "^1FIGHT!", "^3");

        player    takeAllWeapons();
        activator takeAllWeapons();
        player    giveWeapon("m40a3_mp");
        activator giveWeapon("m40a3_mp");
        player    switchToWeapon("m40a3_mp");
        activator switchToWeapon("m40a3_mp");

        player.health    = player.maxhealth;
        activator.health = activator.maxhealth;

        while(isdefined(player) && isalive(player))
            wait 0.05;
    }
}


// =============================================================================
//  SECTION 25 - JUMP-BOUNCE ROOM WITH CHECKPOINT PROGRESSION
// =============================================================================
//  Jump-puzzle room where the player respawns at the LAST checkpoint they
//  reached instead of the start. Implemented with per-player progress
//  (player.jump_room_pos) and dynamic targetname lookup.
//
//  In Radiant:
//   - Bounce-pad targets named bounce_jumper_1 / _2 / _3 / ...
//     (script_origin entities marking respawn pos)
//   - Checkpoint triggers named bounce_jumper_2_trig / _3_trig / ...
//     at the entrance to each higher level
//   - A fail trigger bounce_fail_jumper covering the death pit
//
//  Wiring in main():
//      thread jump_room_setup_example();
// =============================================================================
jump_room_setup_example()
{
    cp_2 = getEnt("bounce_jumper_2_trig", "targetname");
    cp_3 = getEnt("bounce_jumper_3_trig", "targetname");
    cp_4 = getEnt("bounce_jumper_4_trig", "targetname");
    if(isdefined(cp_2)) cp_2 thread jump_room_checkpoint(2);
    if(isdefined(cp_3)) cp_3 thread jump_room_checkpoint(3);
    if(isdefined(cp_4)) cp_4 thread jump_room_checkpoint(4);

    fail = getEnt("bounce_fail_jumper", "targetname");
    if(isdefined(fail)) fail thread jump_room_fail("jumper");
}

jump_room_checkpoint(index)
{
    while(true)
    {
        self waittill("trigger", player);
        if(!isValidPlayer(player)) continue;
        if(!isdefined(player.jump_room_pos)) player.jump_room_pos = 1;

        if(player.jump_room_pos < index) {
            player iPrintln("^3Checkpoint ^2" + (index - 1));
            player.jump_room_pos = index;
        }
    }
}

jump_room_fail(side)         // side = "jumper" or "acti"
{
    fallback = getEnt("bounce_" + side + "_1", "targetname");
    while(true)
    {
        self waittill("trigger", player);
        if(!isValidPlayer(player)) continue;
        if(!isdefined(player.jump_room_pos)) player.jump_room_pos = 1;

        // Look up the spawn for the player's current checkpoint.
        ent = getEnt("bounce_" + side + "_" + player.jump_room_pos, "targetname");
        if(!isdefined(ent)) ent = fallback;     // safety net for missing entities
        if(!isdefined(ent)) continue;

        player setVelocity((0, 0, 0));
        player setOrigin(ent.origin);
        player setPlayerAngles(ent.angles);
        player freeze_on_tps(0.05);
    }
}


// =============================================================================
//  SECTION 26 - GATE THAT OPENS ONLY FOR TAGGED PLAYERS
// =============================================================================
//  A brush that becomes walk-through (notSolid) only when AT LEAST ONE
//  player with a specific flag is touching the sense volume. Used for
//  "ghost mode passthrough" doors, secret-route gates, VIP barriers.
// =============================================================================
flag_gated_door_example()
{
    door  = getEnt("door_ghost_only",         "targetname");
    sense = getEnt("trig_ghost_sense_volume", "targetname");
    if(!isdefined(door) || !isdefined(sense)) return;

    while(true)
    {
        wait 0.1;
        any_ghost_touching = false;

        players = getentarray("player", "classname");
        for(i = 0; i < players.size; i++) {
            p = players[i];
            if(!isValidPlayer(p)) continue;
            if(isdefined(p.is_ghost) && p isTouching(sense)) {
                any_ghost_touching = true;
                break;
            }
        }

        if(any_ghost_touching) door notSolid();
        else                   door solid();
    }
}


// =============================================================================
//  SECTION 27 - SIDE-DETECTION RESPAWN (which side did they fall on?)
// =============================================================================
//  Common in PvP rooms: activator's pit teleports them back to acti spawn,
//  jumper's pit to jumper spawn. Place a script_origin at the dividing line
//  and compare X (or Y, depending on your map's axis).
// =============================================================================
fall_pit_side_aware_example()
{
    pit       = getEnt("trig_pvproom_pit",    "targetname");
    midpoint  = getEnt("origin_pvproom_mid",  "targetname");
    acti_pos  = getEnt("origin_pvproom_acti", "targetname");
    jump_pos  = getEnt("origin_pvproom_jump", "targetname");
    if(!isdefined(pit) || !isdefined(midpoint) || !isdefined(acti_pos) || !isdefined(jump_pos)) return;

    while(true)
    {
        pit waittill("trigger", player);
        if(!isValidPlayer(player)) continue;

        // Compare on whichever axis splits the room (X here).
        if(player.origin[0] > midpoint.origin[0]) {
            player setOrigin(acti_pos.origin);
            player setPlayerAngles(acti_pos.angles);
        } else {
            player setOrigin(jump_pos.origin);
            player setPlayerAngles(jump_pos.angles);
        }
        player freeze_on_tps(0.05);
    }
}


// =============================================================================
//  SECTION 28 - VELOCITY-CONDITIONAL BOUNCE PAD
// =============================================================================
//  Default jump pads fire even when a player is just standing on them, which
//  can softlock or look glitchy. Gating on getVelocity()[2] makes the pad
//  react to FALLING or JUMPING, not standing.
// =============================================================================
bounce_pad_smart_example()
{
    pad = getEnt("trig_bounce_smart", "targetname");
    if(!isdefined(pad)) return;

    while(true)
    {
        pad waittill("trigger", player);
        if(!isValidPlayer(player)) continue;

        vz = player getVelocity()[2];

        // vz < -15  = currently falling - bounce them like a trampoline
        // vz >  30  = currently jumping  - amplify their upward push
        // -15..30   = roughly stationary - ignore
        if(vz < -15) {
            player setVelocity((0, 0, 700));
            player playLocalSound("bounce_sound");
        }
        else if(vz > 30) {
            v = player getVelocity();
            player setVelocity((v[0], v[1], v[2] + 400));
            player playLocalSound("bounce_sound");
        }
    }
}


// =============================================================================
//  SECTION 29 - BANNER WITH DELAY OR ROUND-START WAIT
// =============================================================================
//  Extension of notifyMessage for banners that fire at a specific time:
//   - wait_time          - sleep this many seconds before showing the banner
//   - wait_round_started - block until level notify("round_started") fires
//                          (engine event when both teams ready and door opens)
//
//  Welcome banner that shows 1 sec AFTER the round actually starts:
//      thread notify_message("^3Welcome to Atlantis", "^7Map by YourName",
//                            5, (1, 0.7, 0), 1, true);
// =============================================================================
notify_message(title, text, duration, color, wait_time, wait_round_started)
{
    if(isdefined(wait_round_started))
        level waittill("round_started");

    if(isdefined(wait_time))
        wait wait_time;

    noti = SpawnStruct();
    noti.titleText  = title;
    noti.notifyText = text;
    noti.duration   = duration;
    if(isdefined(color)) noti.glowColor = color;

    players = getentarray("player", "classname");
    for(i = 0; i < players.size; i++) {
        if(!isdefined(players[i])) continue;
        players[i] thread maps\mp\gametypes\_hud_message::notifyMessage(noti);
    }
}


// =============================================================================
//  COMMON BUILTIN PATTERNS REFERENCE (copy as needed)
// =============================================================================

// --- Wait until ANY of multiple notifies, whichever fires first ---
//     self common_scripts\utility::waittill_any("death", "disconnect", "spawned");

// --- Make a brush walk-through but still visible (for visual-only fences) ---
//     mybrush notsolid();

// --- Make a brush solid that started notsolid ---
//     mybrush solid();

// --- Hide / show a brush (visual only, not collision) ---
//     mybrush hide();
//     mybrush show();

// --- Move/rotate primitives (all are async - return immediately, finish over time) ---
//     ent moveZ(distance, time);
//     ent moveY(distance, time);
//     ent moveX(distance, time);
//     ent rotateYaw(degrees, time);
//     ent rotatePitch(degrees, time);
//     ent rotateRoll(degrees, time);
//
// To wait for a movement to finish:
//     ent moveZ(100, 2);
//     ent waittill("movedone");

// --- Play a sound from a specific position ---
//     playSoundAtPosition("sound_alias", entity.origin);

// --- Play a sound only the player hears ---
//     player playLocalSound("sound_alias");

// --- Stop and start ambient music ---
//     ambientStop(2);                 // fade-out in 2 sec
//     ambientPlay("music_alias");

// --- Player movement speed (1.0 = default 210, 0.95 = 190, 1.5 = fast) ---
//     player setMoveSpeedScale(1.5);
//
// !!! DO NOT use setmovespeed() or setgravity() - those crash the server.

// --- Spawn a script entity at runtime (rare, usually use Radiant) ---
//     ent = spawn("script_origin", (0, 0, 0));
//     ent.angles = (0, 90, 0);

// --- Disable / re-enable a trigger from script ---
//     trig thread maps\mp\_utility::triggerOff();
//     trig thread maps\mp\_utility::triggerOn();

// --- Print to all players ---
//     iPrintln("plain message");
//     iPrintlnBold("BIG centered message");

// --- Print to one player only ---
//     player iPrintln("for you only");
//     player iPrintlnBold("for you only - bold");


// =============================================================================
//  ANTI-PATTERNS (real bugs we have hit in shipped maps - DO NOT REPEAT)
// =============================================================================
//
//  BAD: empty-body loop without wait when condition is false
//      while(isalive(player))
//          if(isdefined(level.activ))
//              wait 1;
//      // When level.activ is undefined the inner if is false, no wait runs,
//      // CPU spins until the engine kills the thread. Fix: always have a
//      // wait inside the loop body, even on the false branch.
//
//  BAD: `level.activ X(...)` without checking isplayer()
//      level.activ setOrigin(p.origin);
//      // Crashes when no axis player exists - level.activ is the STRING
//      // "Noactivator". Fix: `if(isplayer(level.activ)) level.activ setOrigin(...)`
//
//  BAD: synchronous call to a function that waittills
//      player respawnLater();           // blocks current thread until death
//      // Almost always you want: player thread respawnLater();
//
//  BAD: getEnt with duplicate targetname
//      door = getEnt("door", "targetname");
//      // If two brushes in Radiant share targetname "door" -> engine errors
//      // and door is undefined. Either rename one, or use:
//      arr = getentarray("door", "targetname");
//      if(arr.size > 0) door = arr[0];
//
//  BAD: deleting an already-deleted entity
//      level.trig delete();
//      // Second call (e.g. from another room's delete chain) crashes.
//      // Fix: `if(isdefined(level.trig)) level.trig delete();`

