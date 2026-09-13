# Red Sea Baron

A playable Godot 4.7 action-RPG blockout in a 320 × 320 m Mediterranean coastal region. The reference images guide the red transforming motorcycle, warm village, farms and limestone cliffs. Geometry and animation are placeholders; this is an evolving vertical slice, not the completed 25 km world.

Open `project.godot` in Godot 4.7 and press F5, or run:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

For Web, run `tools/serve.sh` and open [the local game](http://127.0.0.1:8067/). The server must remain running. The build uses the Compatibility renderer, WebGL 2, matching Godot 4.7 templates and a single thread, with no external asset services.

## Controls and places

| Input | Action |
|---|---|
| WASD / arrows | Move; steer/throttle while riding |
| Shift | Sprint; reverse cargo/station action when held |
| Space | Jump; bike brake; aircraft takeoff/climb |
| Q / Ctrl | Dodge; descend while flying |
| Right drag / IJKL / wheel | Orbit / keyboard camera / zoom |
| 1 / 2 | Wrench / rifle |
| F or left click / G | Attack / heavy wrench attack |
| Alt / Tab / R | Aim / lock target / reload |
| E | Survey station or mount/dismount nearby bike |
| T | Deploy/fold wings on clear ground below 29 km/h |
| C | Hitch/detach nearby cart while stopped in bike mode |
| V / Shift+V | Load backpack into nearby cart / unload |
| U / Shift+U | Gather, deposit, trade, accept/deliver / withdraw or buy an olive |
| O at courier | Choose south quay or Longfield before accepting a parcel |
| B / P | Cargo and trade readout / buy rifle rounds at market |
| N | Worker orders; 0 harvest/sell routine, 3 ore, 4 olives, 5 courier, 6 market, 7 timber, 8 retry, 9 recall |
| M / Esc | Map / pause |
| H | Recover at checkpoint; recover bike and attached cargo while riding |
| X | Eat a carried olive for up to 25 HP while stopped on foot |
| F6 / F8 | Save / load while stopped and grounded |
| F9 | Traversal verifier |

Native play captures the mouse. Web uses right-drag/IJKL because the embedded browser rejected pointer lock.

The map shows the motorcycle, cargo cart, Mara and Ivo. Click a marker, or use Track bike / Track cargo / Follow Mara / Follow Ivo, to follow its current location in the field notes. Buttons keep overlapping markers individually selectable. Remote targets select the world map automatically. The Checkpoint button follows your selected recovery point, including changes made at survey boards or by loading a save. A ring marks it on the map. Clear removes the target; clicking elsewhere sets a fixed waypoint. Tracking is session-only, and follows the same actor when restoring a save in that session.

Olives can restore health: stop on foot and press X to consume one from your pack for up to 25 HP. Gather at the orchard or buy an olive with Shift+U at the market. Full health keeps your food; attacks, reloads, dodges and riding block eating.

Shallow coastal water slows you to a wade. Deep water returns the player to the survey checkpoint and submerged vehicles to the workshop, preserving pack and cargo contents. Saving is blocked during deep-water recovery. Swimming is not implemented.

The motorcycle and cart start at the workshop, east of the village center. Deploy wings, accelerate above 44 km/h, then hold Space to take off. Land and slow down before folding. Detach the ground cart before flight.

Use U at the courier desk near the workshop to accept a parcel. A nearby cart receives it; otherwise it goes into your backpack. Carry it to the south quay (39, 67) and press U while stopped to deliver for 75 crowns. B shows its status. Use C for the hitch and V to move backpack contents into the cart. After completing a delivery, Shift+U at the courier desk issues another parcel.

O at the courier cycles South quay (75 crowns), Longfield waystation at (900, 1116) (180 crowns), and Greenreach timber camp at (-3600, 716) (500 crowns). Its destination stays fixed after acceptance. For an air delivery, use Shift+V to unload the parcel into your pack and C to detach the cart before deploying wings. Fly southeast, land in clear terrain, fold, then ride to the desk south of the waystation. The map highlights your active delivery destination. Worker courier jobs still use the local south quay.

Olives are at the northwest farm (-48, -48), ore east of town (61, 29), and timber southwest (-27, 53). The warehouse is (-9, 8); the market is (-13, 1). Resources are finite; an exhausted orchard regrows after 15 seconds. Sold goods enter market stock. Buying costs twice their selling value. Mara and Ivo start by the warehouse. N opens work orders; Tab selects the worker. Jobs and routines apply to the selected worker. Press 0 to repeat harvesting and selling autonomously. Press 0 again to finish the current job and stop; blocked jobs retain cargo and can be retried with 8. Saves preserve routine progress, including a stopped job that is still finishing.

Hostiles are west of town. P at the market buys five rifle rounds for 12 crowns and consumes one stocked ore. Selling gathered ore replenishes this supply; reserve capacity is 100. Surveys establish recovery points. F6 saves a stopped, grounded session; F8 or the menu’s Load button restores it. Save data includes inventories, vehicles, contracts, enemy health, surveys and each worker’s cargo, active job and routine. Web saves use browser storage, so clearing site data removes them.

## Verification

The shared suite catalog is `tests/suites.json`. Optional test scripts load only when selected. `python3 tools/verify_startup_isolation.py` checks startup against a deliberately broken verifier in a temporary project copy.

Each suite runs production controllers in the main scene. Isolated fixtures reposition actors; integrated routes physically travel between locations. Reports include explicit pass/fail results; a successful launch alone is not a pass.

```sh
tools/verify.sh
```

Select suites with `tools/verify.sh --suites combat,feedback --no-export`; add `--long` for the roughly twelve-minute continuous flight test. Native flags follow `--`: `--verify` for traversal, or `--verify-SUITE`. Suites include combat, bike, flight, cart, logistics, worker, world, save, ui, integration, feedback, ai, economy, highland, region, recovery, encounter, routine, routine_stop, backdrop, routes, airmail, cargo_access, seat_safety, water, vehicle_ground, chase_camera, batching, equipment_map, enemy_strike, beast_strike, food, lock_framing, shoulder_clearance, panel_combat, wing_pose, touchdown, towing, forest_airmail, source_identity, forest_resource, lake, multi_worker, steering_clearance, quarry_resource, wing_transition, tail_clearance, worker_map, brook, rock_surface, flight_navigation, incoming_damage, water_camera, cart_recovery, logistics_prompt, roof_surface, regional_roof, terrain_seam, regional_survey, checkpoint_map, cart_wheel, cart_canopy, rider_clearance, ambience, audio_settings, worker_reach and vehicle_cover. Web uses `?verify=SUITE`, with `?verify=1` for traversal. A report appears as visible page text after completion. Leave controls idle during automated verification; reload the normal URL afterwards.

Rendered native runs accept `--capture` to save evidence at actual gameplay checkpoints. Headless runs cannot benchmark rendering. Evidence, failing attempts, current rubric scores and acceptance results live in `docs/GAUNTLET_PROGRESS.md` and `docs/evidence/`.

Native and Web evidence includes traversal, both weapons, driving and transformation, loaded cargo, worker contention, persistence across a browser reload, maps and a continuous 23.95 km flight. Each report identifies its exact assertions and platform. Consult the progress log for current regressions and pending acceptance; old passes do not automatically certify later changes.

The outer world streams a bounded 5 × 5 terrain window across a 25 km square domain. The authored core deactivates at distance; worker jobs continue in coarse simulation. Outer regions contain instanced woodland, dryland, grassland and highland scenery, with four discoverable landmarks. Red Mesa and Snowwatch have nearby hostile encounters whose health/deaths persist when the region retires. Most of the world is still procedural blockout scenery. Broad hardware testing, richer regional content and final art remain open. See `docs/ARCHITECTURE.md` for the current interfaces and `docs/PROJECT_BRIEF.txt` for the complete request.

The world map marks Greenreach timber camp (-3600, 700), Red Mesa quarry (4800, 1200), Snowwatch tower (-1060, -10000), and Longfield waystation (900, 1100). Close approaches record discoveries without changing your survey checkpoint. Each landmark has a survey board 12 m west and 8 m south of its center. Stop on foot beside the board and press E to set your recovery checkpoint; this keeps the village’s three-stamp route separate. Saving preserves the selected checkpoint. Red rings indicate hostile areas.

Create a preserved native regression checkpoint with `python3 tools/checkpoint.py NAME --long`. Each unique name stores a source copy, SHA-256 manifest, reports and a summary; an existing checkpoint cannot be overwritten. The long option adds continuous world flight.

Cargo and worker panels are live: movement and jobs continue, but weapon actions are blocked until the panel closes. Opening one cancels an unfinished swing or reload.

The vehicle display shows takeoff readiness and warns below flight lift speed. Greenreach is the longer western forest delivery: unload the parcel into your pack, detach the cart, fly west, then land and ride to the desk south of the timber shelter.

Greenreach also has a timber reserve just west of its delivery desk, at (-3613, 716). Use U to gather into your pack. Timber weighs 2 kg and sells for 5 crowns each at the Port Solis market. Its remaining stock is saved independently from the village timber yard; older saves initialize the new reserve.

Willowmere lake lies west of Longfield, centered at (620, 1150), and is marked on the world map. Its shallow shore allows slower wading; deep water recovers you to your survey checkpoint and waterlogged vehicles to the workshop, preserving goods.


Red Mesa's iron works is a short mine gallery near (4829,1223), east of the quarry landmark. Walk through its timber-framed opening to gather ore at (4829,1225); its 80-unit reserve depletes independently from the village outcrop. Nearby regional hostiles remain active in normal play. Sell the ore at the village market or use that market stock to buy rifle rounds. Stock revision 3 initializes this reserve when loading older saves and preserves their existing resource and worker state.


Wing panels carry collision while unfolding and folding. If an obstacle blocks their motion, the HUD says WINGS BLOCKED; reverse into open ground and the transition continues. A newly blocked final deployment area still triggers safe folding. Saving remains unavailable during a transition. Vehicle heading changes also check world clearance, including trailer corners, with a small bounded support adjustment for ground slopes.

Solis brook lies northwest of town around (-600,-500). Its timber bridge supports on-foot travel and a loaded bike/cart crossing. Deep water uses the same recovery rules as the coast and Willowmere. The bridge streams with its terrain chunk and is rebuilt before a saved crossing resumes.

In flight, the vehicle panel shows aircraft heading and vertical speed. An explicit map waypoint takes priority over the active delivery destination; Clear returns guidance to that delivery. Course cues use the shortest turn, with a small ON COURSE tolerance. Looking around changes the camera compass but leaves the aircraft heading unchanged. Low-airspeed warnings override navigation cues.

Incoming hits briefly tint the screen edges and play an impact cue. The effect keeps the aiming center and mouse input clear, and resets when pausing or recovering.

The coast, lake and brook share water ripples anchored to the world. Detached cargo that escapes the world bounds or falls far beneath the seabed returns to the workshop with its goods. A hitched recovery brings the motorcycle and rider with it; distant recovered carts stay suspended until nearby terrain is active.

Resource and desk action labels appear only for the nearest reachable station within use range. A closer source behind a wall no longer blocks a clear alternative, and pressing U refreshes the selection immediately. Physical signs and the map remain available for finding destinations.

Village, farm and regional shelter roofs now support landing and walking; saved rooftop sessions rebuild their owning terrain chunk before movement resumes. Travelers and workers share articulated knees, including a bent riding pose. Feet and hands still use procedural animation without terrain or handlebar IK.

The village houses use shared terracotta tile shading, eaves, shutters and door details. Cargo wheel animation follows signed travel along the ground, including reversing and slopes; vertical settling does not spin the tires.

The expedition cart has a fixed curved canvas cover over its cargo. Its upper collision follows the canopy on slopes and participates in towing and turning clearance, so low overhead obstacles can stop the loaded assembly.

Mounting requires room for the seated rider. While mounted, the rider contributes collision to driving, turning and visual banking; dismounting removes that envelope from the parked bike.

The start/pause menu includes master volume and mute, saved separately from journey progress. The Web ambience verifier waits for its visible “Start wind audio checks” button after loading; click it to activate browser audio. Its report checks real mixer samples and loop progression. After the Web audio_settings suite, audio_resume verifies those probe preferences across a fresh page.
