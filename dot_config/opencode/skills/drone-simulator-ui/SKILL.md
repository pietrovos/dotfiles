---
name: drone-simulator-ui
description: Use when creating, improving, or debugging the Java Swing UI of Pietro's firefighting-drone-simulator, including RuntimeGUI, map painting, fire and water animations, fleet tables, dropdowns, telemetry, and dashboard layout. Preserve simulation behavior and verify the rendered UI.
---

# Firefighting simulator Swing UI

This skill applies to the firefighting drone simulator, normally located at
`~/projects/firefighting-drone-simulator`. Find the current repository location
if it has moved. Read its instructions and live source before assuming these
notes still describe the implementation. Do not apply browser, React, JavaFX,
Spring, or Java 21 patterns to this Java 17 Swing application by default.

## Start with the live application

Read the relevant files before editing:

- `src/main/java/DroneSwarmSim/ui/RuntimeGUI.java`: layout, fleet inspection,
  resource gauges, dropdowns, tables, faults, and log controls.
- `src/main/java/DroneSwarmSim/ui/GUI.java`: grid coordinates, terrain, zones,
  drone movement, fire spread, water effects, and shared UI callbacks.
- `src/main/java/DroneSwarmSim/ui/TileTypes.java`: terrain and overlay colors.
- `src/main/java/DroneSwarmSim/scheduler/Scheduler.java`: telemetry callbacks,
  remaining water, mission completion, and fault handling.
- `src/main/java/DroneSwarmSim/scheduler/SchedulerMain.java`: startup and Swing
  construction.
- `pom.xml`, `README.md`, and relevant tests under `src/test/java`.

Inspect `git status` and the current diff to preserve work already in progress.
Use the smallest coherent change that delivers the requested improvement.
Treat visual presentation and simulation coordinates as separate concerns.
Do not change scheduling, water consumption, UDP messages, or timing solely to
make an animation look better.

## Swing threading and lifecycle

- Construct and mutate Swing components, table models, selectors, and timers
  on the event-dispatch thread (EDT).
- Use `SwingUtilities.invokeLater` for asynchronous UI updates. Use
  `invokeAndWait` only from a non-EDT thread when initialization needs to finish
  before execution continues.
- Use Swing `Timer` for animation. Keep timer callbacks and painting quick;
  perform network I/O, builds, and expensive work outside the EDT.
- Shared simulation data needs a defined owner, synchronization, or immutable
  snapshots. A concurrent map does not make its mutable list values safe.
- Avoid creating duplicate timers. Stop animation timers when their effects
  end, and stop UI timers on window close or disposal.
- Preserve headless guards so model tests can run without a display.

## Layout and the user's preferences

Preserve these preferences unless the user changes them:

- Inspect Drone, Mission State, and resource cards are at the top.
- The title and telemetry subtitle sit at the bottom-left.
- Show logs / Hide logs stays at the bottom-right.
- The log panel and its Events, Queue, Telemetry, Assignments, and Metrics tabs
  start hidden. Logs continue collecting while hidden.
- The grid fills the full map panel as the window or dividers resize.
- Initial divider placement gives the map square proportions when the actual
  window dimensions permit it, while leaving a usable fleet sidebar.
- HQ sits outside the response-zone outlines in a presentation-only staging
  margin. It has the same grey fill as the civilian cells beside it.
- Civilian building tiles sit immediately right of and below HQ.

Use layout managers and component insets instead of fixed screen coordinates.
Calculate initial divider positions after the window has valid dimensions.
Allow the user to resize split panes afterward. Account for desktop tiling and
display scaling: requested frame dimensions may differ from actual dimensions.
Do not claim a size check passed unless the actual rendered bounds were checked.

## Styling and inspection

- Keep the navy dashboard palette, readable text, and consistent spacing.
- Give dropdowns a dark closed state and popup, a visible chevron, selection
  contrast, and a keyboard-focus indicator. Keep keyboard navigation working.
- Use clear table outlines, subtle row separators, and consistent headers.
  Show selection and sorting direction. Sort resource values numerically.
- Preserve fleet filtering, stable selection during telemetry updates, and
  inspection through the table, selector, and map.
- Keep tooltips meaningful and accessibility names on unlabeled controls.
- Resource bars should communicate low supplies through color and numeric text.
- Keep long logs bounded. Preserve the user's scroll position and separate
  clearing the view from deleting recorded log files.

## Terrain, markers, and transparency

- Neutral cells are forest terrain with varied greens and stable canopy
  texture. Restoring a cell should restore the same terrain appearance.
- Preserve contrast for zone outlines, drone IDs, HQ, fires, and faults.
- Fire colors currently use about 40% opacity. Render the terrain first and
  composite the fire over it; setting an alpha background on an opaque Swing
  panel alone is insufficient.
- Draw using a copied `Graphics2D`, set the required rendering hints, and dispose
  the copy. Avoid expensive allocations, random changes, or I/O in painting.
- Fit compact labels to their cells without exposing HTML markup as literal
  text. Keep full details in tooltips or the inspection panel.
- Keep coordinate conversion, zone boundaries, fire spread, map clicking, and
  tooltips consistent when a display offset is introduced.

## Water effects must match the drop

Use authoritative scheduler values for the incident's remaining water,
original water requirement, and the drone's available water. Do not infer all
three from the severity label when those values are available.

- Water splashes belong only on fire cells that the current drop will clear.
- Untargeted cells continue burning during a partial drop.
- Determine the removal footprint and splash targets using the same rule.
  Base cumulative fire shrinkage on the original footprint, not the already
  shrunken footprint.
- Retain the center until the fire is fully extinguished. A final drop can
  clear the entire remaining footprint.
- An empty tank must not splash any fire cells.
- Clear stale targets on completion, fault, cancellation, and reassignment;
  restore the appropriate terrain or active fire beneath the animation.

Check `FireDropVisualizationTest` and the scheduler's water-drop callbacks
before changing this behavior.

## Verification

1. Compile the affected source with `mvn -DskipTests compile`.
2. For UI-only changes, run the relevant GUI tests. For animation semantics,
   include `FireDropVisualizationTest`. Use
   `mvn -Djava.awt.headless=true test` when scheduler callbacks, concurrency,
   or mission behavior changes justify the full suite.
3. Verify actual rendering in a desktop session. Prefer a temporary Swing
   preview with representative telemetry when launching the full simulation
   would interfere with an active run. Temporary preview files belong outside
   the repository, such as `/tmp/opencode`.
4. Check actual bounds at more than one window size. Inspect the open dropdown,
   table header, selection, map, and footer, not just a successful compilation.
5. Exercise the affected interactions: log toggle, filtering, resource sorting,
   map selection, fault cleanup, or partial and final water drops.
6. Report which tests and rendered checks ran. Do not claim a GUI was visually
   verified when only headless tests ran.

The normal launcher is `./run-demo.sh`. It starts a 20-drone final scenario by
default; read the script before running it because its cleanup uses `pkill`
with the simulation's main-class names. Update the README when user-facing
behavior changes. Commit or push only when requested, following `github-push`.
