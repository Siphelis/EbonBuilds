# 🔮 EbonOrbReroll

**Eine Ziehung aus einem Orb der verlorenen Erinnerungen ist keine Sackgasse mehr.**

Der Server verweigert das Neuziehen bei einer Orb-Ziehung. EbonOrbReroll führt an
deiner Stelle die beiden Handgriffe aus, mit denen ein Spieler das von Hand
umgeht, und wiederholt sie, bis das gesuchte Echo fällt. Alles in einem Panel,
das sich unter die Karten schiebt und verschwindet, sobald es dort nichts mehr zu
tun hat.

[English](README.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

## Inhaltsverzeichnis

- [Warum dieses Addon](#-warum-dieses-addon)
- [Funktionen](#-funktionen)
- [Installation](#-installation)
- [Schnellstart](#️-schnellstart)
- [Anatomie des Codes](#-anatomie-des-codes--wie-es-funktioniert)
- [Lizenz & Credits](#-lizenz--credits)

---

## 🔥 Warum dieses Addon

Bei einer Orb-Ziehung verweigert der Server Neuziehen, Verbannen und Einfrieren —
deshalb blendet ProjectEbonhold dort auch seinen eigenen *Reroll*-Button aus. Im
Protokoll gibt es nichts, was diese Ziehung neu zieht, und dieses Addon behauptet
nichts anderes. Es führt zwei ganz gewöhnliche Aktionen aus, direkt hintereinander:

1. **Eine Karte nehmen.** Der Stapel wird gewährt.
2. **Einen Orb ausgeben, um sie wieder zu vergessen** — und genau das stößt eine
   frische Echo-Auswahl an.

Unterm Strich: drei neue Karten, ein Orb weniger, exakt dieselben Echos im Besitz
wie zuvor. Es wird nichts Neues gesendet und nichts lokal entschieden — der
Server prüft Besitz, Sperrstatus und Ladung im zweiten Schritt, wie immer.

Der einzige Unterschied zu einem echten Reroll: zwischen den beiden Schritten
besitzt du das geopferte Echo tatsächlich. Verweigert der Server Schritt 2,
bleibt es bei dir. Deshalb wird die Karte so gewählt, dass sie das Billigste ist,
mit dem man hängenbleiben kann — und deshalb nennt der Tooltip sie **vor** dem
Klick.

## ✨ Funktionen

- **Ein "Reroll (Orb)"-Button** unter den drei Karten, mit der Anzahl deiner
  Orbs. Er erscheint nur bei einer Orb-Ziehung: eine Stufenaufstiegs-Ziehung hat
  bereits ihren eigenen Reroll-Button, der unangetastet bleibt.
- **Die geopferte Karte wird gewählt, nicht erlitten.** Niedrigste Qualität
  zuerst. Nie ein permanentes Echo (der Server würde Schritt 2 verweigern), nie
  ein voller Stapel (er würde Schritt 1 verweigern), nie ein Echo, auf das du
  Jagd machst. Die garantierte Karte des Build-Slots, eingefrorene und
  übernommene Karten kommen nur als letzter Ausweg in Frage: sie wurden aus einem
  Grund behalten.
- **Die Jagd.** Rüste Echos im Journal des Spiels scharf, lege fest, wie viele
  Orbs du dafür ausgeben willst, und das Addon zieht neu, bis eines davon
  ausgeteilt wird. Es **nimmt die Karte nie für dich**: zwei gewünschte Echos
  können gemeinsam fallen, und die Wahl dazwischen ist deine Sache. Es hält an
  und sagt es.
- **Die Kosten folgen dem Qualitätsregler des Spiels**, ausgelesen aus deiner
  letzten Orb-Ausgabe. Kein zweites Bedienelement neben dem, das es schon gibt.
- **Ein Budget-Regler**, begrenzt durch das, was du wirklich besitzt. Ein Budget,
  das nicht einmal eine Ziehung bezahlt, wird vorab abgelehnt — mit der Zahl, die
  sich bewegen muss, statt eine Jagd zu starten, die im selben Moment endet.
- **Ablehnungen, die sich erklären.** Ausgegrauter Button und ein Tooltip, der
  sagt warum: keine Orbs mehr, Anzahl noch unbekannt, nichts scharfgestellt,
  Auto-Annahme aktiv. Und wenn keine Karte auf dem Tisch vergessen werden kann,
  verschwindet der Button, statt ausgegraut zu bleiben — ein deaktiviertes
  "Reroll (0)" würde "du hast keine Rerolls mehr" bedeuten, eine andere Aussage,
  und eine falsche.
- **Keine Schleife.** Alles hängt an Funktionen, die ProjectEbonhold bei
  Zustandswechseln ohnehin aufruft, plus Timer, die sich selbst scharf schalten
  und selbst abschalten. Zwischen zwei Ziehungen führt das Addon keine einzige
  Zeile Lua aus.
- **Nichts aufzuräumen.** Die Liste der gejagten Echos lebt eine Sitzung lang und
  stirbt mit ihr: keine SavedVariables, nichts zu migrieren, nichts Veraltetes,
  das in drei Patches erklärt werden müsste.

## 📦 Installation

1. [**EbonOrbReroll**](https://github.com/Siphelis/EbonOrbReroll/releases/latest) — lade die neueste Version herunter.
2. Entpacke den Ordner `EbonOrbReroll` nach
   `Interface/AddOns/`.
3. Prüfe im Addon-Auswahlbildschirm, dass **EbonOrbReroll** angehakt ist.

## 🕹️ Schnellstart

Keine Slash-Befehle: alles steckt in dem Panel, das unter den Karten erscheint.

**Für einen einzelnen Reroll** ist nichts vorzubereiten — klicke auf
**Reroll (Orb)**. Der Tooltip nennt die Karte, die geopfert wird, und die Kosten.

**Für eine Jagd:**

1. Öffne das Echo-Journal und **Strg+Klick** auf die gewünschten Symbole. Ein
   goldener Rahmen markiert die scharfgestellten, ein zweiter Strg+Klick nimmt
   sie wieder heraus. Beide Raster reagieren — der Katalog rechts und die Echos
   des laufenden Runs links — damit ein weiterer Stapel von etwas, das du schon
   besitzt, überhaupt anforderbar bleibt.
2. Schalte Ebonholds Option **"auto-accept loadout echoes"** aus. Die Jagd
   verweigert den Start, solange sie aktiv ist: sie würde die Karte für dich
   nehmen.
3. Stelle bei einer Orb-Ziehung den Regler auf die Anzahl Orbs, die du ausgeben
   willst. Die Beschriftung zeigt, wie viele Ziehungen das bezahlt.
4. Klicke auf **Hunt**. Der Button wird zu **Stop** und zählt die ausgegebenen
   Orbs; ein weiterer Klick hält jederzeit an.

Das Addon hält von selbst an, sobald ein scharfgestelltes Echo ausgeteilt wird,
wenn das Budget aufgebraucht ist, oder sobald etwas es am Weitermachen hindert —
und der Chat sagt immer, welcher der drei Fälle es war.

## 🧠 Anatomie des Codes — wie es funktioniert

Zwei Dateien, in dieser Reihenfolge von der `.toc` geladen: die erste definiert
die gemeinsame String-Tabelle, die zweite nimmt sich beim Laden eine Referenz
darauf. Umgekehrt gilt die Abhängigkeit nicht — die Engine liest `ns.Wishlist`
zum Aufrufzeitpunkt, nie beim Laden, und kann die zweite Datei daher nicht
halbfertig erwischen.

| Datei | Genaue Rolle |
| --- | --- |
| `EbonOrbReroll.lua` | Die Engine. Die String-Tabelle, die Zwei-Schritt-Maschine (nehmen, dann vergessen) und ihre Wach-Timer, die Wahl der geopferten Karte, der Jagd-Supervisor und sein Budget, das Auslesen des Qualitätsmultiplikators aus deinen eigenen Ausgaben, die Hooks in ProjectEbonhold (`PerkUI.Show` / `Hide` / `UpdateSinglePerk` / `ResetSelection`, `OrbService.ClearOffer`, die Buttons, die die Karten einklappen) und das Panel selbst: zwei Buttons und ein Regler. |
| `EbonOrbWishlist.lua` | Die Pfropfung auf das Echo-Journal. Die Menge der gewünschten Echos, der Strg+Klick, der sie auf beiden Rastern füttert, der goldene Rahmen, und das Polling, das nur läuft, solange das Journal sichtbar ist. Kein eigenes Panel: das Journal zeichnet bereits jedes Echo, graut nie entdeckte aus und filtert nach Name und Klasse; das daneben nachzubauen wäre eine zweite, schlechtere Kopie einer Liste, die man schon zu lesen weiß. |

Die Identität eines Echos ist hier seine `spellId` und sonst nichts. Das Raster
des Journals recycelt seine Buttons: dieselbe Zelle trug vor einer Suche die eine
ID und danach eine andere. Eine an die Zelle gebundene Markierung würde der Zelle
folgen; an die ID gebunden, folgt sie dem Echo.

## 📜 Lizenz & Credits

Ursprünglicher Autor: **Sanavesa** — Fork gepflegt von **Siphelis**.

Dieses Projekt steht unter einer zusammengesetzten Lizenz (MIT-Basis + PolyForm
Noncommercial für die Änderungen) — siehe [LICENSE](https://github.com/Siphelis/EbonOrbReroll/blob/main/LICENSE)
für die Einzelheiten.

---
