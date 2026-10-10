Run from the repository root with Lua 5.1:

```sh
lua5.1 tests/run.lua
```

The suite exercises the production modules against mocked WoW APIs. It executes the actual secure state snippets and rejects ordinary Lua mutations of protected frames during combat. It covers combat visibility and actions across all display modes, frozen assignments, flyout interactions and cleanup, inventory refresh, grid capacity, enabling/disabling, positioning, rejuvenation classification, binding declarations, and that every translatable string has an English entry. GitHub Actions also checks Lua syntax.

The mock cannot reproduce Blizzard's taint system, hardware-event dispatch, client XML loading, or WoW Forever restrictions. Before merging, validate in both supported clients:

- Bind buttons through the DynamicBar section of Key Bindings. Confirm left-click and keypress consume one item, while right-click opens alternatives without consuming anything.
- Select an alternative from a flyout; confirm the correct item is consumed and the flyout closes.
- Carry more than six items for one slot (for example scrolls). Confirm the flyout shows Previous/Next arrows, the seventh item is reachable and usable, and the arrows do nothing in combat.
- Enter combat with a flyout open and with the positioning overlay unlocked. Confirm both close without blocked-action errors.
- Test FADE, HIDE, GREY, and ALWAYS in Smart, Static, and Dynamic modes. Prep slots must not execute in combat; battle items must remain usable. No button may move or switch items until combat ends.
- Consume items, acquire a different potion, and exhaust an alternative during combat. Confirm the bar updates immediately after combat ends.
- Disable through both slash commands and options, including during combat. Confirm deferred disabling clears the bar, bindings, and flyouts after combat.
- Use 13 buttons in a saved 2×5 grid, then remove slots in Dynamic mode. Confirm all retained buttons have valid positions and removed slots have no actions or flyouts.
- Open `/dbar builder`. Drag a category onto the middle of the bar, drag a slot to a new position, drag one off the bar, right-click one, and use the arrows. Confirm the bar updates live and the window closes when combat starts.
- Choose Position Now, trigger a bag update, and click Save & Lock. Repeat positioning after setup is complete.
