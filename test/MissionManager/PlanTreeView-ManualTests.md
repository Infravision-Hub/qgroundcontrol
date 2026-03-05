# PlanTreeView — Manual Test Plan

Manual verification for the PlanTreeView branch changes that replace the tab-bar + flat-list plan panel with a unified TreeView.

---

## Prerequisites

- Build QGroundControl from the **PlanTreeView** branch
- Have at least one saved `.plan` file with mission items, a geofence, and rally points
- No vehicle connection required (offline editing mode)

---

## 1. Initial State

| # | Step | Expected |
|---|------|----------|
| 1.1 | Launch QGC → Plan View | Right panel shows the tree view with three collapsible groups: **Mission Items**, **GeoFence**, **Rally Points** |
| 1.2 | Observe default state | "Mission Items" group is expanded; GeoFence and Rally Points are collapsed |
| 1.3 | Verify MissionSettingsItem | The first item under Mission Items is the home/launch position settings editor |

## 2. Group Expand / Collapse (Exclusive)

| # | Step | Expected |
|---|------|----------|
| 2.1 | Click the **GeoFence** group header | GeoFence expands; Mission Items collapses; the map editing layer switches to fence mode |
| 2.2 | Click the **Rally Points** header | Rally Points expands; GeoFence collapses; map switches to rally editing mode |
| 2.3 | Click the **Mission Items** header | Mission Items expands; Rally Points collapses; map switches back to mission editing mode |
| 2.4 | Click the currently-expanded header | It should collapse all and re-expand itself (stays expanded) |

## 3. Group Header Styling

| # | Step | Expected |
|---|------|----------|
| 3.1 | Observe the active group header | Active group has highlighted background (`buttonHighlight`) and contrasting text |
| 3.2 | Observe inactive group headers | Inactive headers use `windowShade` background with normal text color |
| 3.3 | Observe expand/collapse indicator | Expanded group shows ▾ (down); collapsed groups show ▸ (right) |

## 4. Mission Item Operations

| # | Step | Expected |
|---|------|----------|
| 4.1 | Click on the map to add 3–5 waypoints | Each waypoint appears in the tree under Mission Items in the correct order |
| 4.2 | Click a waypoint editor in the tree | That waypoint is selected (highlighted on map, sequence number matches) |
| 4.3 | Remove a middle waypoint via its editor's delete button | Item disappears from tree; remaining items re-sequence correctly; map updates |
| 4.4 | Add a waypoint between two existing items | New item appears at the correct position in the tree |
| 4.5 | Add a complex item (Survey, Corridor Scan) | Complex item appears in the tree with its editor |
| 4.6 | Remove all items (hamburger menu → Remove All) | Tree resets to show only MissionSettingsItem under Mission Items |
| 4.7 | Undo item removal if undo is available | Items reappear in tree at correct positions |

## 5. GeoFence Editing

| # | Step | Expected |
|---|------|----------|
| 5.1 | Expand GeoFence group | GeoFence editor loads as the single child |
| 5.2 | Add an inclusion/exclusion polygon via the editor | Polygon appears on the map; tree structure unchanged (single fence editor child) |
| 5.3 | Toggle fence parameters | Editor controls respond correctly; no layout glitches |
| 5.4 | Collapse and re-expand GeoFence | Editor state is preserved; no duplicate children |

## 6. Rally Point Operations

| # | Step | Expected |
|---|------|----------|
| 6.1 | Expand Rally Points group | Rally header/instructions shown as first child |
| 6.2 | Click on map to add 3 rally points | Each rally point appears as a child below the header in the tree |
| 6.3 | Remove a rally point | Item removed from tree; remaining rally items still shown correctly |
| 6.4 | Remove all rally points | Only the header child remains under Rally Points |
| 6.5 | Collapse and re-expand Rally Points | Tree state is correct; no orphaned items |

## 7. Plan File Load / Save

| # | Step | Expected |
|---|------|----------|
| 7.1 | Save current plan to a `.plan` file | File saves normally |
| 7.2 | Clear mission (Remove All), then load the saved plan | Mission Items repopulate in tree; GeoFence and Rally children repopulate; all three groups present |
| 7.3 | Load a second different `.plan` file | Tree rebuilds with new plan contents; Mission Items group auto-expands |
| 7.4 | Load an empty plan | Tree shows only MissionSettingsItem under Mission Items; Fence/Rally have their default marker children |

## 8. Scrolling

| # | Step | Expected |
|---|------|----------|
| 8.1 | Add enough waypoints to overflow the panel (~15+) | Vertical scroll indicator appears; tree scrolls smoothly |
| 8.2 | Scroll to the bottom, then scroll back up | Scroll indicators show/hide correctly; no visual artifacts |
| 8.3 | Resize the QGC window smaller | Tree adapts; editors don't overflow horizontally; horizontal scroll indicator appears if needed |

## 9. Panel Open / Close

| # | Step | Expected |
|---|------|----------|
| 9.1 | Click the panel close button (> arrow on left edge) | Panel slides off-screen to the right |
| 9.2 | Click the panel open button (< arrow) | Panel slides back; tree state is preserved |
| 9.3 | Close panel, add waypoints on map, re-open panel | New waypoints appear in the tree |

## 10. Edge Cases

| # | Step | Expected |
|---|------|----------|
| 10.1 | Rapidly click between group headers | No crashes; only one group expanded at a time; no visual glitches |
| 10.2 | Add ~50 waypoints, then Remove All | Tree handles large item count; clear is clean; no stale delegates visible |
| 10.3 | Load a plan with only mission items (no fence/rally) | GeoFence and Rally groups present but empty (just their default marker children) |
| 10.4 | Switch between Plan View and Fly View repeatedly | Returning to Plan View preserves tree state |
| 10.5 | Check the console/log output for warnings | No unexpected warnings about model indexes, null objects, or QML binding errors |

## 11. Vehicle Connection (if available)

| # | Step | Expected |
|---|------|----------|
| 11.1 | Connect to a vehicle (real or MockLink/SITL) | Plan View tree functions the same as offline mode |
| 11.2 | Upload a mission with fence and rally points | Upload completes normally |
| 11.3 | Download mission from vehicle | Tree repopulates with downloaded items |
| 11.4 | Disconnect vehicle while in Plan View | Tree remains functional with offline editing |

---

## Pass Criteria

- All group expand/collapse transitions are exclusive and correct
- Tree children always match the flat `visualItems` list contents and order
- No crashes, assertion failures, or unexpected console warnings
- All editors (mission item, fence, rally) load and function identically to the previous tab-bar UI
