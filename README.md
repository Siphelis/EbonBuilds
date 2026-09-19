# 🔮 EbonOrbReroll

**An Orb of Lost Memories draw is no longer a dead end.**

The server refuses to reroll an Orb draw. EbonOrbReroll performs, on your behalf,
the two moves a player would make by hand to get around that, then repeats them
until the Echo you are after is dealt. All of it in a panel that slots in under
the cards and leaves the moment it has nothing to do there.

[English](README.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

## Table of Contents

- [Why this addon](#-why-this-addon)
- [Features](#-features)
- [Installation](#-installation)
- [Quick start](#️-quick-start)
- [Code anatomy](#-code-anatomy--how-it-works)
- [License & credits](#-license--credits)

---

## 🔥 Why this addon

On an Orb draw the server refuses reroll, banish and freeze — which is why
ProjectEbonhold hides its own *Reroll* button there. Nothing in the protocol
rerolls that draw, and this addon does not pretend otherwise. It performs two
ordinary actions, back to back:

1. **Take a card** off the table. The stack is granted.
2. **Spend one orb to forget it again**, which is what pushes a fresh Echo
   choice.

Net effect: three new cards, one orb gone, exactly the same Echoes owned as
before. Nothing new is sent and nothing is decided locally — the server validates
ownership, lock state and the charge on step 2, as it always has.

The one way this differs from a real reroll: between the two steps you genuinely
own the sacrificed Echo. If the server refuses step 2, it stays. That is why the
card is chosen to be the cheapest thing to be stuck with, and why the tooltip
names it **before** the click.

## ✨ Features

- **A "Reroll (Orb)" button** under the three cards, carrying the number of orbs
  you hold. It only appears on an Orb draw: a level-up draw already has a real
  reroll button of its own, which is never touched.
- **The sacrificed card is chosen, not suffered.** Lowest quality first. Never a
  permanent Echo (the server would refuse step 2), never a full stack (it would
  refuse step 1), never an Echo you are hunting for. The build-slot guaranteed
  card, frozen cards and carried cards are last resorts: they were held for a
  purpose.
- **The hunt.** Arm Echoes from the game's own journal, set how many orbs you are
  willing to spend, and the addon rerolls until one of them is dealt. It
  **never picks the card for you**: two wanted Echoes can land together, and
  choosing between them is your business. It stops and says so.
- **The cost follows the game's own quality slider**, read from your last orb
  spend. Not a second control beside the one that already exists.
- **A budget slider** bounded by what you actually hold. A budget that cannot pay
  for a single draw is refused up front, naming the number that has to move,
  rather than starting a hunt that would stop on the same tick.
- **Refusals that explain themselves.** A greyed button and a tooltip that says
  why: out of orbs, count not in yet, nothing armed, auto-accept on. And when no
  card on the table can be forgotten, the button is removed rather than greyed —
  a disabled "Reroll (0)" would read as "you are out of rerolls", which is a
  different statement, and a false one.
- **No loop.** Everything hangs off functions ProjectEbonhold already calls when
  its state changes, plus timers that arm and disarm themselves. Between two
  draws the addon executes no Lua at all.
- **Nothing to clean up.** The list of hunted Echoes lives for one session and
  dies with it: no SavedVariables, nothing to migrate, nothing stale to explain
  away three patches from now.

## 📦 Installation

1. [**EbonOrbReroll**](https://github.com/Siphelis/EbonOrbReroll/releases/latest) — download the latest version.
2. Unzip the `EbonOrbReroll` folder into
   `Interface/AddOns/`.
3. Check the AddOns selection screen to make sure **EbonOrbReroll** is ticked.

## 🕹️ Quick start

No slash commands: everything lives in the panel that appears under the cards.

**For a single reroll** there is nothing to set up — click **Reroll (Orb)**. The
tooltip names the card that will be sacrificed, and the cost.

**For a hunt:**

1. Open the Echo journal and **Ctrl+click** the icons you want. A golden ring
   marks the armed ones, a second Ctrl+click takes them off. Both grids answer —
   the catalog on the right and this run's Echoes on the left — so asking for
   another stack of something you already own stays possible.
2. Turn Ebonhold's **"auto-accept loadout echoes"** off. The hunt refuses to
   start while it is on: it would take the card for you.
3. On an Orb draw, set the slider to the number of orbs you are willing to
   spend. The label shows how many draws that pays for.
4. Click **Hunt**. The button becomes **Stop** and counts the orbs spent; click
   it again to stop at any time.

The addon stops on its own as soon as an armed Echo is dealt, when the budget is
spent, or the moment something prevents it from continuing — and chat always says
which of the three.

## 🧠 Code anatomy — how it works

Two files, loaded in that order by the `.toc`: the first defines the shared
string table, the second takes a reference to it at load. The dependency does not
run the other way — the engine reads `ns.Wishlist` at call time, never at load,
so it cannot catch the second file half-built.

| File | Exact role |
| --- | --- |
| `EbonOrbReroll.lua` | The engine. The string table, the two-step machine (take, then forget) and its guard timers, the choice of the sacrificed card, the hunt supervisor and its budget, reading the quality multiplier off your own spends, the hooks into ProjectEbonhold (`PerkUI.Show` / `Hide` / `UpdateSinglePerk` / `ResetSelection`, `OrbService.ClearOffer`, the buttons that collapse the cards), and the panel itself: two buttons and a slider. |
| `EbonOrbWishlist.lua` | The graft onto the Echo journal. The set of wanted Echoes, the Ctrl+click that feeds it on both grids, the golden ring, and the polling that only runs while the journal is on screen. No panel of our own: the journal already draws every Echo, greys the ones never discovered, and filters by name and class; rebuilding that beside it would be a second, worse copy of a list you already know how to read. |

An Echo's identity here is its `spellId` and nothing else. The journal grid
recycles its buttons: the same cell held one id before a search and another
after. A mark bound to the cell would follow the cell; bound to the id, it
follows the Echo.

## 📜 License & credits

Original author: **Sanavesa** — fork maintained by **Siphelis**.

This project is licensed under a custom license (MIT base + PolyForm
Noncommercial for modifications) — see [LICENSE](https://github.com/Siphelis/EbonOrbReroll/blob/main/LICENSE)
for details.

---
