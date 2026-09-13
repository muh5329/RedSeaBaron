# Current vertical-slice architecture

`scenes/main.tscn` has one composition root, `scripts/main.gd`. It creates the systems and injects references; there are no autoloads or hard-coded node paths. Gameplay verification uses that same scene.

| System | Interface and ownership |
|---|---|
| Player | `PlayerController.set_controls`, `MovementConfig`, independent `PlayerVisual.animate`; stamina, grounding, coyote/buffer, dodge, recovery |
| Camera | `OrbitCamera.follow_target` switches between player and bike anchor; sphere SpringArm probes world collision; weapon FOV/shoulder offset reset on cancel; mounted heading follows smoothly after a manual-look grace period |
| Camera | `OrbitCamera` constrains the shoulder pivot against world geometry before its rear SpringArm sweep; lock-on uses the effective offset and pause stops pivot smoothing |
| Avatar | Shared `PlayerVisual` supplies stable weapon/riding joints for the traveler, worker and seated rider; opaque colors batch per joint |
| Weapon presentation | `WeaponVisual` owns geometry and rifle grip/bolt pose; PlayerCombat retains hits, timing and ammunition |
| Combat | `HealthComponent`, faction-aware `DamageSystem`, `WeaponConfig`, `PlayerCombat`; timed wrench windows, per-swing hit sets, rifle magazine/reserve/reload, camera + muzzle occlusion checks; injected panel gate cancels pending weapon actions while live orders/cargo retain movement |
| Hostiles | `EnemyActor` moves; `EnemyVisual` builds distinct human/quadruped silhouettes and per-joint color batches; `CombatBrain` executes reusable `StateMachine` at reduced decision rates; last-seen memory and throttled local paths support pursuit around cover; committed forward strikes use a visible sector cue and reset decision timing when interrupted |
| Vehicle | `BikeController` owns kinematic movement; `BikeFlightController` computes flight velocity; `VehicleTransformation` owns transition state, wings and expanded collision |
| Vehicle geometry | `VehicleMesh` builds rings, rods and a faceted tank. `BikeVisual` batches rigid parts while separate steering/spin pivots preserve wheel motion; shared batching normalizes custom unindexed triangles |
| Ground contact | `GroundPose` samples actual collision for visual pitch/roll/height on bike and cart; kinematic collision bodies stay upright |
| Seat | `VehicleSeat` transfers actor visibility, collision and camera. Main owns control gating for pause, seat and death. Seat runs before input consumers to avoid simultaneous fire/mount races |
| Cargo presentation | `CartVisual` shares mechanical wheel geometry and maintains three fixed MultiMesh pools for up to eight representative crates; exact contents remain in Inventory |
| Cargo | `CargoCart` solves its drawbar from the actual axle-to-hitch direction through world/bike collision. `VehicleClearance` rejects yaw changes that overlap the attached vehicle pair. Bike limits outward movement at 4.4 m separation. `HitchSystem` guards speed, range and flight, and routes pack transfers |
| Items | `ItemDefinition` Resource catalog. `Inventory` validates known items, positive quantities and mass capacity; transfers commit both sides before guarded notifications |
| Resources | `ResourceSource.stock` is an Inventory, so player and workers use the same stock transaction. Registered sources have stable IDs independent of item type; saves reject duplicate IDs and workers resolve sources by ID. `Storage` supplies a spatial inventory endpoint |
| Economy | `Shop` transfers real stock and money; `DeliveryContract` has guarded acceptance/delivery states and explicit completed-contract reissue. `LogisticsWorld` wires stations, player access and presentation |
| Food recovery | `ConsumableUse` latches X input after actor/seat processing, validates stopped on-foot state and commits health/food before notification with rollback and a recursion guard |
| Supplies | `FieldSupplies` trades market ore and crowns for rifle reserve rounds under the shared Shop transaction guard |
| Routes | `DeliveryRoute` defines destination/reward. Courier selection configures an inactive contract; saves retain the route ID and derive its spatial endpoint/payment from the catalog. Regional desk visuals activate individually |
| Jobs | `JobDefinition` Resource contains references/configuration. `JobExecutor` performs acquire/deliver transactions, independent of actor locomotion |
| Workers | `WorkerActor` executes Idle, MoveToTask, AcquireResource, PerformTask, DeliverResource, Return, Blocked and Failed through the shared StateMachine. `WorkerManager` builds reusable job definitions and exposes orders |
| Routines | `JobRoutine` configures a repeated sequence. `WorkerManager` dispatches the next step only at Idle; repetition and membership of the current job are independent persisted flags |
| Navigation | `NavigationController` incrementally samples a bounded 79 × 79 local grid from collision, routes with AStarGrid2D, refreshes nearby cells on blocked retries. It is not full-world navigation |
| World | `CoastalRegion` generates a 320 m slice with 25 terrain tiles and batched scenery. `WorldStreamer` maintains up to 25 outer 64 m chunks; `WorldManager` gates core geometry/physics and distant actors |
| Horizon | `WorldBackdrop` repositions one GPU-displaced mesh with no collision. Near/far terrain shares surface shading; the visual height approximation mirrors CPU terrain and requires coordinated updates |
| Water | Coastal visuals and `WaterSafety` share a `WaterBody` Resource. `RegionalLake` adds one inland basin with shared CPU/horizon parameters and an elliptical WaterBody; `WaterSurface` is visual-only, and regional foliage excludes submerged ground. Three bounded actor queries apply a separate wading multiplier and inventory-preserving recovery; pause freezes countdowns and unsafe water states cannot be saved |
| Regions | `RegionCatalog` resources describe biomes/landmarks; `RegionScenery` owns deterministic chunk decoration and camera-proximity foliage fading; `RegionManager` retains discoveries |
| Encounters | `SpawnManager` creates nearby hostiles with a bounded local grid, retires them before terrain unload and preserves health/death records |
| Persistence | `SaveSchema` validates the whole versioned snapshot before `SaveSystem` mutates live systems; temporary-file writes and explicit equipment/seat restoration |
| Vehicle instruments | `VehicleHUD` presents speed, takeoff readiness, low-airspeed warning, cargo weight and current controls; controller state remains authoritative |
| UI | `GameHUD` and `FieldMap` provide controls, local/world maps and picked waypoints; cargo/worker panels exclude each other; equipment markers track the actual bike/cart references at the existing HUD refresh rate |
| Audio | `GameAudio` listens to combat and gameplay signals; fixed eight-voice pool plus vehicle loop, gated by Begin/pause |
| Tests | `tests/suites.json` supplies dispatch and runner thresholds; main lazily loads only the requested script. Separate suites observe production state, drive real input, save native JSON and emit visible Web reports; integration physically joins combat, delivery and worker tasks |

Collision layers: world 1, player 2, hostile 4, bike 8, cart 16 plus world bit, worker 32. World obstacles use solid BoxShape3D where box overlap semantics matter. Terrain uses concave mesh collision. Decorative foliage has no collision.

## State and transaction rules

- Pause gates movement, combat, riding, cargo, resources and workers. Mounting hides/disables the walking actor and gives vehicle controls to the seat. Dismount checks ground, slope, elevation, line of sight and capsule clearance; airborne or fast dismount is rejected.
- Flight folding is rejected in midair. Deployment needs clear space at both start and completion; obstruction during deployment folds safely. Fully deployed wing collision follows visual attitude and rejects a pose that intersects world geometry. A landing needs actual walkable support beneath a chassis axle, so a wing-only floor contact cannot enable folding or saving. A cart must be detached before deployment.
- Inventories expose independent snapshots. Failed transfers leave both inventories unchanged. Full destinations cannot consume source stock. Parcels cannot be sold as ordinary commodities. Contracts set intermediate states before inventory signals to reject reentrant acceptance/delivery.
- Worker jobs keep the acquired/delivered stage in JobExecutor. Retrying a blocked destination must not reacquire source stock. Recall returns carried goods to home storage. Failed workers retain cargo and expose their reason instead of silently dropping items.
- Stopping a routine leaves the active job intact. Its successful transaction advances the phase/cycle exactly once, even after stop/save/load; stopping prevents future automatic assignment. The schema checks saved routine membership against the executor phase.

## Scaling and persistence boundaries

Generated outer chunks are freed when retired. Authored core meshes are hidden and collision disabled at distance, while logical stock/job nodes remain resident. Workers switch to 1 Hz abstract movement and transaction execution; returning restores visible physics. Native and Web continuous-flight verifiers crossed 23.95 km with peak 25 outer chunks. This proves bounded traversal, not completed regional content.

Stock revision 2 extends save version 1 with independent regional resource depletion. Missing stock revision means legacy revision 1; only newly introduced sources initialize from configured stock, while malformed current data is rejected.

Save version 1 captures grounded/stopped player and vehicles, inventories/stocks, economy, survey flags, hostile health and each registered worker’s job stage, regional discoveries, regional encounter records, delivery route and each worker’s routine phase. Validation rejects malformed records before mutation. Browser persistence has a separate fresh-page reload verifier. Flight saves are not supported. Roster revision 2 adds independent worker records while migrating earlier Mara-only saves.

## Known limitations

Arcade bike/aircraft/trailer physics; no suspension or realistic aerodynamics. Geometric animation and placeholder models/sounds. Navigation is a coarse local grid, not full-world pathfinding. One authored village and a small catalog. Repeat courier contracts and market-ore ammunition supplies support continued play. No worker wages, touch/controller support or low-end hardware validation. The measured village rendering budget is 354 native draw calls in a pinned village view on one M4 Pro; hidden original meshes remain allocated after batching. Some verifier fixtures directly establish poses; passing them is not exhaustive human playtesting.


WorkerManager registers Mara and Ivo with stable IDs and separate WorkerRoutineState instances. N opens orders; Tab selects a worker, with combat blocked while the panel is open. Each actor retains its own executor, inventory, navigation path and routine counters. Shared warehouse transfers remain atomic through Inventory. WorkerRosterState serializes and validates the roster before restore: the original `worker` field retains Mara for legacy saves, while roster revision 2 requires the exact registered `other_workers` records keyed by ID. Revision 1 initializes only newly introduced Ivo; unknown, missing, duplicated or malformed current records reject the whole restore. Original single-worker routine properties still address Mara for older integrations.
