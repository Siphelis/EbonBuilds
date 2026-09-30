# 🔮 EbonBuilds

**Plan your Echo builds, let the addon choose your Echoes, and reroll Orb draws until the Echo you want is dealt.**

[EbonBuilds](https://github.com/Siphelis/EbonBuilds) is an addon for Project Ebonhold. It helps you with the Echoes of your runs.

[English](README.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

## Table of Contents

- [What it does](#-what-it-does)
- [Installation](#-installation)
- [Getting started](#-getting-started)
- [Builds](#-builds)
- [Stars and community rating](#-stars-and-community-rating)
- [Automation](#-automation)
- [Orb reroll and hunt](#-orb-reroll-and-hunt)
- [Sharing](#-sharing)
- [Follow your runs](#-follow-your-runs)
- [Settings and commands](#-settings-and-commands)
- [License & credits](#-license--credits)

---

## ✨ What it does

- **Builds.** Write a plan for each build: the Echoes you aim for and how much you want each one. Open a build from **Saved Builds** or **Player Builds** to see all its Echoes, like in the game's Echo journal.
- **Stars.** Every Echo gets 1 to 3 stars for your class. They appear on the draw cards, in the game's Echo journal and in the detail window of a build of your class.
- **Automation.** At each draw, the addon can pick, banish, reroll or freeze for you, following your active build.
- **Orb reroll and hunt.** On an Orb draw, the addon can reroll with an Orb. It can also repeat until an Echo you marked is dealt.
- **Sharing.** The builds in your game's build slots are shared automatically. Browse the builds of other players and add one of your class to your wishlists. Benefit from what the community keeps and bans.
- **Run follow-up.** See statistics per build, the Echoes you still miss, and a logbook of every decision.

## 📦 Installation

1. [**EbonBuilds**](https://github.com/Siphelis/EbonBuilds/releases/latest) — download the latest version.
2. Unzip the `EbonBuilds` folder into `Interface/AddOns/`.
   Install or update [**EbonAPI**](https://github.com/Siphelis/EbonAPI/releases/latest) the same way. [EbonBuilds](https://github.com/Siphelis/EbonBuilds) needs [EbonAPI](https://github.com/Siphelis/EbonAPI) 2.0.0 or newer. [EbonAPI](https://github.com/Siphelis/EbonAPI) is shared by the Ebonhold addons. [EbonBuilds](https://github.com/Siphelis/EbonBuilds) does not start without it.
3. On the AddOns selection screen, check that [**EbonBuilds**](https://github.com/Siphelis/EbonBuilds) and [**EbonAPI**](https://github.com/Siphelis/EbonAPI) are ticked.

The addon uses the language of your game: English, French, German or Spanish. To change it, press Esc and click **EbonAPI**. On the **General** page, choose it in the **Language** list.

## 🚀 Getting started

1. Type `/ebb`, or click the [EbonBuilds](https://github.com/Siphelis/EbonBuilds) button on the minimap. The window opens.
2. Click **+ New Build**.
3. Choose **Wizard Mode** to be guided step by step, or **Pro Mode** to go straight to the editor.
4. Click **Save**. The build becomes your active build. Its automation is on.
5. Play. At each draw the addon waits two seconds, acts, and shows a banner with what it did.

You only want the stars and no automation? Click **Automation: ON** on the build page. It switches to **Automation: OFF**. The stars stay.

**Saved Builds** shows nothing? Open the game's Echoes window once.

## 📋 Builds

### The window

The left column holds:

- **Saved Builds**: the builds and wishlists stored by the game itself.
- **Player Builds**: the builds shared by other players.
- **+ New Build**: creates a build.
- Your builds. Click one to open it. It becomes your active build for this character. The automation follows the active build.

In **Saved Builds**, each build is a card with its slot number, its name, its number of Echoes and its locked Echoes. A green **>** marks the game's active build.

### The detail window

Click a card in **Saved Builds** or **Player Builds**. Its detail window opens beside the main window. It closes with the main window, or when you leave the list.

- The header shows the class, the number of Echoes and the families of the build. Each family gives its number of Echoes, for example **Tank (3)**. Echoes without a family are under **No family**.
- Below the header, a row of slots shows the locked Echoes. If the player did not send them, a line says so. The row has as many slots as you have unlocked in the game.
- Then a grid shows every Echo of the build, like the game's Echo journal. The rarest come first.

In the grid:

- Each Echo has one cell, whatever its rarities. A small disc gives the stacks of each rarity, for up to three rarities.
- A lock marks a locked Echo. Its name is in gold.
- A book marks an Echo that needs a tome.
- A halo turns behind each icon, in the colour of its rarity. It is gold on a locked Echo.
- On a build of your class, the tooltip shows the stars of the Echo, as in the game's Echo journal.

To filter the grid:

1. Tick a family in the header. The grid shows only its Echoes.
2. Tick more families to add their Echoes. An Echo shows if it belongs to one of them.
3. Untick them all to see every Echo again.

The row of locked Echoes is never filtered. The families you ticked stay when you open another build. They are cleared when the window closes.

To add a player build to your wishlists:

1. Open a build of your class from **Player Builds**.
2. Click **Add to my wishlist** at the bottom.
3. Type a name, or keep the one offered.
4. Confirm.

The build goes to the server as a new wishlist, with its Echoes and its locked Echoes. The chat confirms when it is created. You then find it among your wishlists in the game's Echo journal, and in **Saved Builds**. On a build of another class, the button stays grey: a wishlist is always for your own class.

### Wizard Mode

The wizard asks for:

1. Your locked Echoes.
2. A bonus for new Echoes. This step only appears if you chose Adaptive Power.
3. Your families: none, secondary (+10) or primary (+20).
4. A bonus for each rarity.
5. The Echoes that matter most: **Want it**, **Good**, **OK** or **Mehh**.
6. A title and a description.

The editor opens at the end. Check it, then click **Save**.

### The editor

Click **Edit Build** on a build page. The editor has four tabs.

| Tab | What you set |
| --- | --- |
| **Overview** | Class, spec, title, description and locked Echoes. |
| **Echoes** | A weight for each Echo. |
| **Bonus** | Extra points by rarity, by family and for new Echoes. |
| **Automation** | Bans, protections and thresholds. See [Automation](#-automation). |

**Save** keeps your changes. **Cancel** drops them. **Export** (bottom left) gives the build as a text.

**Locked Echoes** are the permanent Echoes your build aims for. There are as many slots as you have unlocked in the game, up to 6. Click a slot to choose an Echo. Right-click to empty it.

The **description** can hold Echo links. Click **+ Insert Echo Link**.

**Echoes tab**

1. A weight is a whole number, 0 or more. The higher it is, the more you want the Echo.
2. One weight covers every rarity of an Echo.
3. Next to the weight, you see the score of each rarity. **Locked** or **Banned** replaces the score of an Echo you locked or banned.
4. Use the search box, the rarity list and the family list to filter.
5. Tick **Show all classes** to see the Echoes of other classes.

**Bonus tab**

- **Quality Bonus**: extra points for each rarity.
- **Family Bonus**: extra points for each family.
- **Novelty Bonus**: extra points for an Echo you do not own yet.
- Each value is added (**+**) or multiplied (**x**). Click the small button next to the number to switch. In **x** mode, a value under 1 lowers the score.

## ⭐ Stars and community rating

### What the stars mean

- 3 stars: essential for your class.
- 2 stars: in between.
- 1 star: you can do without it.
- 3 grey stars: most players ban it.
- No star: your class cannot use this Echo.

### Where to see them

1. In the game's Echo journal, hover an Echo. The line **Interest for** your class shows the stars. When the community knows the Echo, a second line **Goes well with** lists up to three Echoes often kept with it.
2. On a draw, under the icon of each card.
3. Click a card in **Saved Builds** or **Player Builds**. In the detail window that opens, hover an Echo. The tooltip shows the same lines as in the journal. This works only for a build of your class.

### How the rating is made

1. Each Echo starts from its rarity. The rarer it is, the higher it starts.
2. The addon then reads the builds of your class: your **Saved Builds** and the **Player Builds**. The more builds keep an Echo, the higher it goes.
3. On draw cards and in the tooltip, builds that look like your current run weigh more. An Echo that fits what you already own goes up.
4. Ban lists pull an Echo down. Once three players' ban lists are known, an Echo banned by half of them or more gets grey stars. An Echo banned by a fifth of them or more loses one star.
5. Each player counts once, whatever their number of builds.

The more players use the addon, the better the rating gets.

## 🤖 Automation

The automation plays your draws for you. It follows your **active build**. Each build has its own switch: **Automation: ON** or **Automation: OFF** on the build page. A new build starts with automation on.

The automation never spends Orbs. It only uses the Banishes, Rerolls and Freezes the game gives you.

### What it does at each draw

After a short wait (2 seconds by default), the addon goes through this list. It does the first action that applies.

1. **Take a locked Echo.** If a locked Echo of your build is offered, the addon takes it.
2. **Banish.** The addon banishes an Echo of your ban list first. Then it banishes an Echo whose note is under the banish threshold. It needs a Banish left. It skips protected families, frozen cards and carried cards.
3. **Reroll.** The addon rerolls when the best offered Echo is under the reroll threshold and no offered Echo reaches the guard threshold. It needs a Reroll left.
4. **Freeze.** When two offered Echoes are above the freeze threshold, the addon freezes the lesser one and takes the better one. It needs a Freeze left.
5. **Take the best.** Otherwise the addon takes the Echo with the best note.

A banner at the top of the screen shows each action. It lists the offered Echoes with their notes, marks the chosen one with **>> <<**, and shows your remaining Banishes, Rerolls and Freezes. Click the banner to close it. Keep the mouse over it to keep it open.

### The Automation tab

- **Banish Protection.** Tick the families that must never be banished.
- **Echo Ban.** The Echoes to banish first, whatever their note. Click **Add Echo** to add one. Click an icon to remove it. Below, choose what happens when every offered Echo is banned and no Banish is left: **Highest Score** or **Random**.
- **Score Source.** Choose where the notes come from:
  - **Community matrix** (default): the note comes from the community, plus your weights.
  - **Manual weights**: the note comes only from your weights and bonuses.

### Thresholds with Community matrix

The note goes from -5 (everyone refuses the Echo) to +3 (everyone keeps it). An ordinary Echo sits near +1.

| Threshold | Default | Effect |
| --- | --- | --- |
| **Auto-banish below** | -2.00 | Banishes an offered Echo under this note. |
| **Auto-reroll below** | 0.00 | Rerolls when the best offered Echo is under this note. |
| **Reroll guard above** | 0.00 | Blocks a reroll when an offered Echo reaches this note. Keep it at or under the reroll threshold. |
| **Auto-freeze above** | +2.00 | Freezes when two offered Echoes are above this note. |
| **Weight influence** | 1.00 | How much your weights add to the note. At 1.00, the Echo with your highest weight adds 1 point. |

Two more things to know:

1. Each rarity adds a small bonus to the note. Rarer Echoes come first when notes are close.
2. **Community matrix** needs three builds of your class among your **Saved Builds** and the **Player Builds**, or three players' ban lists. Until then, the addon works as with **Manual weights**.

With **Manual weights**, the thresholds are percentages of the **Peak**: the best score possible for your class with your bonuses. In this mode, the reroll compares the total score of the offered Echoes, not the best one.

The stars are a simple view of the community rating. The automation uses the finer note, from -5 to +3.

## 🔮 Orb reroll and hunt

### How it works

On an Orb draw, the server refuses to reroll, banish and freeze. [EbonBuilds](https://github.com/Siphelis/EbonBuilds) adds a panel under the cards. The panel chains two actions the game already allows:

1. It takes one of the offered cards. The Echo is granted.
2. It spends Orbs to forget that Echo. The game deals three new cards.

You end with three new cards and fewer Orbs. You own the same Echoes as before. The server still checks every step.

One point to know: between the two steps, you really own the Echo taken. If the server refuses step 2, you keep it. So the addon takes the card that is the least harmful to keep. The tooltip names it before you click.

### The card taken

1. The card with the lowest rarity comes first.
2. A permanent Echo is never taken. The server would refuse to forget it.
3. An Echo at full stacks is never taken. The server would refuse to grant it.
4. An Echo you are hunting is never taken.
5. The guaranteed card of a build slot, frozen cards and carried cards come last. They were kept for a reason.

### The panel

The panel appears under the cards on an Orb draw only.

- **Reroll (Orb: N)**: one reroll. N is your number of Orbs. The tooltip names the card taken and the cost.
- **Hunt (n)**: starts a hunt. n is the number of Echoes you armed.
- **Coloured square**: the rarity you look for.
- **Slider**: how many Orbs the hunt may spend.

On a level-up draw, the game's own Reroll button stays as it is. If no card of the draw can be forgotten, the panel disappears. A grey button has a tooltip that tells why: no Orbs left, Orb count not received yet, no Echo armed, auto-accept on.

A draw costs 1 Orb by default. The cost follows the game's own quality slider, as set at your last Orb spend.

### Hunt

1. Open the game's Echo journal.
2. **Ctrl+click** the Echoes you want. A golden frame marks them. Ctrl+click again to remove one. It works in both lists: the catalog and the Echoes of your run. The tooltip of an Echo reminds you: **Ctrl+click: hunt this Echo**, or **Ctrl+click: stop hunting** once it is marked.
3. In Ebonhold's options, turn **auto-accept loadout echoes** off. The hunt does not start while it is on.
4. If the automation is on, switch on **Hunt** at the top right of the journal. While it is on, the automation leaves the draws to you. It stays on until you switch it off.
5. On an Orb draw, set the slider to the number of Orbs you accept to spend. The label tells how many draws it pays.
6. Click **Hunt (n)**. It becomes **Stop (spent/budget)**. Click it to stop at any time.

Optional: click the coloured square to choose the lowest rarity for each armed Echo. By default, an armed Echo counts in every rarity.

The hunt stops when:

- an armed Echo is dealt. The list of armed Echoes is then emptied;
- the budget is spent;
- you have too few Orbs left;
- you click **Stop**, or you take a card yourself;
- no card of the draw can be forgotten, or the server refuses a step.

The banner at the top of the screen shows the progress: Orbs spent, the Echoes you look for and the cards of the last draw. It also says why the hunt stopped.

The hunt **never takes the card for you**. Two armed Echoes can come together. You choose.

The slider goes up to the number of Orbs you hold. A budget under the cost of one draw is refused with a message.

The list of armed Echoes is not saved. It is empty after a reload or a new login.

## 🌐 Sharing

### Player builds

The builds in your game's build slots are shared with other players automatically. There is nothing to switch on. No setting turns sharing off.

- From each of these builds, only the Echoes are shared: their rarity, their stacks and which ones are locked. The build name is not sent.
- From your builds in the left column, only the ban lists of your class are shared. They count in the community rating.
- Your weights, bonuses, other automation settings and descriptions are not shared.

To browse the builds of others:

1. Click **Player Builds**. The list opens on your class. Choose another class, or **All Classes**.
2. Each card shows the class, the number of Echoes and the locked Echoes. No player name is shown. The builds with the most Echoes come first.
3. Click a card to open its detail window. On a build of your class, **Add to my wishlist** sends it to the server as a new wishlist.
4. **Reload** asks other players for their builds. It has a 30 second wait.

The list fills by itself as other players share their builds. It keeps them from one session to the next.

### Import and export

- **Export** (bottom left of the editor) shows a text. Copy it and give it to a friend.
- Import comes back in a future update.

If you edit a build that comes from another player, it becomes yours. The author changes to you.

## 📊 Follow your runs

Open a build. Its page has four tabs.

- **Overview**: title, author, spec, date, locked Echoes and description.
- **Stats**: Echoes seen, runs completed (level 80 reached), runs reset, picks, rerolls, banishes and freezes used, and the share of your picks by rarity.
- **Missing**: the Echoes of the build's class that you do not own yet and can get at your level. Each line shows where to find the Echo. The locked Echoes of the build come first.
- **Logbook**: one card per run. Click a card to see each decision: time, action, offered Echoes with their notes, and your remaining Banishes, Rerolls and Freezes. **Export** gives the run as a text. **X** deletes a run. **Clear All** deletes every run.

Statistics and the logbook record the actions of the automation.

A run ends when your character is back at level 1. The 25 latest runs keep every decision. Older runs keep a summary. The addon keeps 200 runs at most.

## 🔧 Settings and commands

- `/ebb` or `/ebonbuilds`: opens or closes the window. `/ebb help` prints the command.
- Minimap button: click to open the window. Drag to move it. Its options are on the **Connected addons** page of the [EbonAPI](https://github.com/Siphelis/EbonAPI) window (press Esc and click **EbonAPI**):
  - **Minimap button**: **On the minimap**, **In the EbonAPI button** or **Hidden**.
  - **Lock its position**: the button no longer moves.
  - **Reset its position**: the button goes back to its starting place.
- Gear icon next to the close button of the window: the settings. They open on the [EbonBuilds](https://github.com/Siphelis/EbonBuilds) page of the [EbonAPI](https://github.com/Siphelis/EbonAPI) window.
  - **Action delay** (0.1 to 3 seconds, 2 by default): the wait before the automation acts. Very low values can make the addon fail.
  - **Toast duration** (0.1 to 3 seconds, 3 by default): how long the banner stays.
- The addon's windows follow the look chosen on the **Appearance** page of the [EbonAPI](https://github.com/Siphelis/EbonAPI) window.
- **Language**, on the **General** page of the [EbonAPI](https://github.com/Siphelis/EbonAPI) window: changes the language of the addon.

## 📜 License & credits

Original author: **Sanavesa** — fork maintained by **Siphelis**.

This project is licensed under a custom license (MIT base + PolyForm
Noncommercial for modifications) — see [LICENSE](https://github.com/Siphelis/EbonBuilds/blob/main/LICENSE)
for details.

---
