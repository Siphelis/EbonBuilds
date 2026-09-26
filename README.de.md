# 🔮 EbonBuilds

**Plane deine Echo-Builds, lass das Addon deine Echos wählen und zieh Züge mit Kugeln neu, bis das gewünschte Echo fällt.**

EbonBuilds ist ein Addon für Project Ebonhold. Es hilft dir bei den Echos deiner Runs.

[English](README.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

## Inhaltsverzeichnis

- [Funktionen](#-funktionen)
- [Installation](#-installation)
- [Schnellstart](#-schnellstart)
- [Builds](#-builds)
- [Sterne und Gemeinschaftsnote](#-sterne-und-gemeinschaftsnote)
- [Automatik](#-automatik)
- [Neu ziehen mit Kugeln und Jagd](#-neu-ziehen-mit-kugeln-und-jagd)
- [Teilen](#-teilen)
- [Deine Runs verfolgen](#-deine-runs-verfolgen)
- [Einstellungen und Befehle](#-einstellungen-und-befehle)
- [Lizenz & Credits](#-lizenz--credits)

---

## ✨ Funktionen

- **Builds.** Schreibe für jeden Build einen Plan: die Echos, die du anstrebst, und wie sehr du jedes einzelne willst.
- **Sterne.** Jedes Echo bekommt für deine Klasse 1 bis 3 Sterne. Sie erscheinen auf den Karten eines Zugs, im Echo-Journal des Spiels und in deinen gespeicherten Builds.
- **Automatik.** Bei jedem Zug kann das Addon für dich wählen, verbannen, neu ziehen oder einfrieren, nach deinem aktiven Build.
- **Neu ziehen mit Kugeln und Jagd.** Bei einem Kugel-Zug kann das Addon mit einer Kugel neu ziehen. Es kann das auch wiederholen, bis ein Echo fällt, das du vorgemerkt hast.
- **Teilen.** Teile deine Builds mit anderen Spielern, importiere ihre und profitiere davon, was die Gemeinschaft behält und verbannt.
- **Run-Verfolgung.** Sieh Statistiken pro Build, die Echos, die dir noch fehlen, und ein Logbuch jeder Entscheidung.

## 📦 Installation

1. [**EbonBuilds**](https://github.com/Siphelis/EbonBuilds/releases/latest) — lade die neueste Version herunter.
2. Entpacke den Ordner `EbonBuilds` nach `Interface/AddOns/`.
   Installiere **EbonAPI** auf dieselbe Weise, falls es noch fehlt. EbonAPI wird von den Ebonhold-Addons gemeinsam genutzt. Ohne EbonAPI startet EbonBuilds nicht.
3. Prüfe im Addon-Auswahlbildschirm, dass **EbonBuilds** und **EbonAPI** angehakt sind.

Das Addon nutzt die Sprache deines Spiels: Englisch, Französisch, Deutsch oder Spanisch. Zum Ändern tippe `/eapi lang` gefolgt von `enUS`, `frFR`, `deDE` oder `esES`.

## 🚀 Schnellstart

1. Tippe `/ebb` oder klicke auf den EbonBuilds-Knopf an der Minikarte. Das Fenster öffnet sich.
2. Klicke auf **+ Neuer Build**.
3. Wähle **Assistent**, um Schritt für Schritt geführt zu werden, oder **Profi-Modus**, um direkt zum Editor zu gehen.
4. Klicke auf **Speichern**. Der Build wird dein aktiver Build. Seine Automatik ist an.
5. Spiele. Bei jedem Zug wartet das Addon zwei Sekunden, handelt und zeigt ein Banner mit dem, was es getan hat.

Du willst nur die Sterne und keine Automatik? Klicke auf der Build-Seite auf **Automatik: AN**. Der Knopf wechselt zu **Automatik: AUS**. Die Sterne bleiben.

**Gespeicherte Builds** zeigt nichts? Öffne einmal das Echo-Fenster des Spiels.

## 📋 Builds

### Das Fenster

Die linke Spalte enthält:

- **Gespeicherte Builds**: die Builds, die das Spiel selbst speichert, mit ihren Echos und Sternen.
- **Öffentliche Builds**: die Builds, die andere Spieler teilen.
- **Build importieren**: fügt einen Build aus einem Text hinzu.
- **+ Neuer Build**: erstellt einen Build.
- Deine Builds. Klicke auf einen, um ihn zu öffnen. Er wird dein aktiver Build für diesen Charakter. Die Automatik folgt dem aktiven Build.

### Assistent

Der Assistent fragt nach:

1. Deinen gesperrten Echos.
2. Einem Bonus für neue Echos. Dieser Schritt erscheint nur, wenn du Adaptive Macht gewählt hast.
3. Deinen Familien: keine, Neben (+10) oder Haupt (+20).
4. Einem Bonus für jede Seltenheit.
5. Den Echos, die am meisten zählen: **Will ich**, **Gut**, **Okay** oder **Naja**.
6. Einem Titel und einer Beschreibung.

Am Ende öffnet sich der Editor. Prüfe ihn und klicke dann auf **Speichern**.

### Der Editor

Klicke auf der Build-Seite auf **Bearbeiten**. Der Editor hat vier Reiter.

| Reiter | Was du einstellst |
| --- | --- |
| **Übersicht** | Klasse, Spez., Titel, Beschreibung, gesperrte Echos und den Schalter **Veröffentlichen**. |
| **Echos** | Ein Gewicht für jedes Echo. |
| **Bonus** | Zusatzpunkte nach Seltenheit, nach Familie und für neue Echos. |
| **Automatik** | Verbannungen, Schutz und Schwellen. Siehe [Automatik](#-automatik). |

**Speichern** behält deine Änderungen. **Abbrechen** verwirft sie. **Exportieren** (unten links) gibt den Build als Text aus.

**Gesperrte Echos** sind die permanenten Echos, die dein Build anstrebt. Es gibt 6 Plätze. Klicke auf einen Platz, um ein Echo zu wählen. Rechtsklick leert ihn.

Die **Beschreibung** kann Echo-Links enthalten. Klicke auf **+ Echo-Link**.

**Reiter Echos**

1. Ein Gewicht ist eine ganze Zahl, 0 oder mehr. Je höher es ist, desto mehr willst du das Echo.
2. Ein Gewicht gilt für alle Seltenheiten eines Echos.
3. Neben dem Gewicht siehst du die Note jeder Seltenheit. **Gesperrt** oder **Verbannt** ersetzt die Note eines Echos, das du gesperrt oder verbannt hast.
4. Nutze das Suchfeld, die Seltenheitsliste und die Familienliste zum Filtern.
5. Hake **Alle Klassen zeigen** an, um die Echos anderer Klassen zu sehen.

**Reiter Bonus**

- **Seltenheitsbonus**: Zusatzpunkte für jede Seltenheit.
- **Familienbonus**: Zusatzpunkte für jede Familie.
- **Neuheitsbonus**: Zusatzpunkte für ein Echo, das du noch nicht besitzt.
- Jeder Wert wird addiert (**+**) oder multipliziert (**x**). Klicke auf den kleinen Knopf neben der Zahl, um zu wechseln. Im **x**-Modus senkt ein Wert unter 1 die Note.

## ⭐ Sterne und Gemeinschaftsnote

### Was die Sterne bedeuten

- 3 Sterne: unverzichtbar für deine Klasse.
- 2 Sterne: dazwischen.
- 1 Stern: du kannst darauf verzichten.
- 3 graue Sterne: die meisten Spieler verbannen es.
- Kein Stern: deine Klasse kann dieses Echo nicht nutzen.

### Wo du sie siehst

1. Fahre im Echo-Journal des Spiels über ein Echo. Die Zeile **Nutzen für** deine Klasse zeigt die Sterne. Kennt die Gemeinschaft das Echo, nennt eine zweite Zeile **Passt gut zu** bis zu drei Echos, die oft zusammen behalten werden.
2. Bei einem Zug unter dem Symbol jeder Karte.
3. In **Gespeicherte Builds** unter jedem Echo.

### Wie die Note entsteht

1. Jedes Echo startet bei seiner Seltenheit. Je seltener, desto höher der Start.
2. Danach liest das Addon die Builds deiner Klasse: deine eigenen, die importierten und die von anderen Spielern erhaltenen. Je mehr Builds ein Echo behalten, desto höher steigt es.
3. Auf den Karten eines Zugs und im Tooltip zählen Builds stärker, die deinem aktuellen Run ähneln. Ein Echo, das zu dem passt, was du schon besitzt, steigt.
4. Verbannungslisten ziehen ein Echo nach unten. Sobald die Listen von drei Spielern bekannt sind, bekommt ein Echo graue Sterne, wenn die Hälfte von ihnen oder mehr es verbannt. Verbannt es ein Fünftel von ihnen oder mehr, verliert es einen Stern.
5. Jeder Spieler zählt einmal, egal wie viele Builds er hat.

Je mehr Spieler das Addon nutzen, desto besser wird die Note.

## 🤖 Automatik

Die Automatik spielt deine Züge für dich. Sie folgt deinem **aktiven Build**. Jeder Build hat seinen eigenen Schalter: **Automatik: AN** oder **Automatik: AUS** auf der Build-Seite. Ein neuer Build startet mit eingeschalteter Automatik.

Die Automatik gibt nie Kugeln aus. Sie nutzt nur die Verbannungen, das Neuziehen und das Einfrieren, die das Spiel dir gibt.

### Was sie bei jedem Zug tut

Nach einer kurzen Wartezeit (standardmäßig 2 Sekunden) geht das Addon diese Liste durch. Es führt die erste passende Aktion aus.

1. **Ein gesperrtes Echo nehmen.** Wird ein gesperrtes Echo deines Builds angeboten, nimmt das Addon es.
2. **Verbannen.** Das Addon verbannt zuerst ein Echo deiner Verbannungsliste. Danach verbannt es ein Echo, dessen Note unter der Verbannungsschwelle liegt. Dafür braucht es eine übrige Verbannung. Geschützte Familien, eingefrorene Karten und übernommene Karten lässt es aus.
3. **Neu ziehen.** Das Addon zieht neu, wenn das beste angebotene Echo unter der Neuzieh-Schwelle liegt und kein angebotenes Echo die Sperrschwelle erreicht. Dafür braucht es ein übriges Neuziehen.
4. **Einfrieren.** Liegen zwei angebotene Echos über der Einfrier-Schwelle, friert das Addon das schwächere ein und nimmt das bessere. Dafür braucht es ein übriges Einfrieren.
5. **Das Beste nehmen.** Sonst nimmt das Addon das Echo mit der besten Note.

Ein Banner am oberen Bildschirmrand zeigt jede Aktion. Es listet die angebotenen Echos mit ihren Noten auf, markiert das gewählte mit **>> <<** und zeigt deine übrigen Verbannungen, Neuziehen und Einfrieren. Klicke auf das Banner, um es zu schließen. Halte die Maus darüber, damit es offen bleibt.

### Der Reiter Automatik

- **Schutz vor Verbannung.** Hake die Familien an, die nie verbannt werden dürfen.
- **Verbannte Echos.** Die Echos, die zuerst verbannt werden, egal welche Note sie haben. Klicke auf **Hinzufügen**, um eines hinzuzufügen. Klicke auf ein Symbol, um es zu entfernen. Darunter wählst du, was passiert, wenn alle angebotenen Echos verbannt sind und keine Verbannung übrig ist: **Beste Note** oder **Zufällig**.
- **Quelle der Note.** Wähle, woher die Noten kommen:
  - **Gemeinschaftsmatrix** (Standard): Die Note kommt von der Gemeinschaft, plus deine Gewichte.
  - **Eigene Gewichte**: Die Note kommt nur aus deinen Gewichten und Boni.

### Die Schwellen mit der Gemeinschaftsmatrix

Die Note reicht von -5 (alle lehnen das Echo ab) bis +3 (alle behalten es). Ein gewöhnliches Echo liegt nahe +1.

| Schwelle | Standard | Wirkung |
| --- | --- | --- |
| **Verbannen unter** | -2,00 | Verbannt ein angebotenes Echo unter dieser Note. |
| **Neu ziehen unter** | 0,00 | Zieht neu, wenn das beste angebotene Echo unter dieser Note liegt. |
| **Neuzieh-Sperre über** | 0,00 | Blockiert das Neuziehen, wenn ein angebotenes Echo diese Note erreicht. Lass sie auf der Neuzieh-Schwelle oder darunter. |
| **Einfrieren über** | +2,00 | Friert ein, wenn zwei angebotene Echos über dieser Note liegen. |
| **Einfluss der Gewichte** | 1,00 | Wie viel deine Gewichte zur Note addieren. Bei 1,00 addiert das Echo mit deinem höchsten Gewicht 1 Punkt. |

Zwei weitere Dinge, die du wissen solltest:

1. Jede Seltenheit addiert einen kleinen Bonus zur Note. Seltenere Echos liegen vorn, wenn die Noten nah beieinander liegen.
2. Kennt die Gemeinschaft keines der angebotenen Echos, nutzt das Addon für diesen Zug deine Gewichte.

Mit **Eigene Gewichte** sind die Schwellen Prozentwerte der **Spitze**: der bestmöglichen Note für deine Klasse mit deinen Boni.

Die Sterne sind eine einfache Ansicht der Gemeinschaftsnote. Die Automatik nutzt die feinere Note von -5 bis +3.

## 🔮 Neu ziehen mit Kugeln und Jagd

### So funktioniert es

Bei einem Kugel-Zug verweigert der Server Neuziehen, Verbannen und Einfrieren. EbonBuilds fügt unter den Karten ein Panel hinzu. Das Panel verkettet zwei Aktionen, die das Spiel schon erlaubt:

1. Es nimmt eine der angebotenen Karten. Das Echo wird gewährt.
2. Es gibt Kugeln aus, um dieses Echo zu vergessen. Das Spiel teilt drei neue Karten aus.

Am Ende hast du drei neue Karten und weniger Kugeln. Du besitzt dieselben Echos wie vorher. Der Server prüft jeden Schritt.

Ein Punkt, den du wissen solltest: Zwischen den beiden Schritten besitzt du das genommene Echo wirklich. Verweigert der Server Schritt 2, behältst du es. Deshalb nimmt das Addon die Karte, die am wenigsten stört, wenn man sie behält. Der Tooltip nennt sie vor deinem Klick.

### Die genommene Karte

1. Die Karte mit der niedrigsten Seltenheit kommt zuerst.
2. Ein permanentes Echo wird nie genommen. Der Server würde sich weigern, es zu vergessen.
3. Ein Echo mit vollem Stapel wird nie genommen. Der Server würde sich weigern, es zu gewähren.
4. Ein Echo, auf das du Jagd machst, wird nie genommen.
5. Die garantierte Karte eines Build-Platzes, eingefrorene Karten und übernommene Karten kommen zuletzt. Sie wurden aus einem Grund behalten.

### Das Panel

Das Panel erscheint nur bei einem Kugel-Zug unter den Karten.

- **Neu ziehen (Kugel: N)**: ein Neuziehen. N ist deine Anzahl Kugeln. Der Tooltip nennt die genommene Karte und die Kosten.
- **Jagen (n)**: startet eine Jagd. n ist die Anzahl der Echos, die du vorgemerkt hast.
- **Farbiges Quadrat**: die gesuchte Seltenheit.
- **Regler**: wie viele Kugeln die Jagd ausgeben darf.

Bei einem Stufenaufstiegs-Zug bleibt der eigene Neuzieh-Knopf des Spiels unverändert. Kann keine Karte des Zugs vergessen werden, verschwindet das Panel. Ein ausgegrauter Knopf hat einen Tooltip, der sagt warum: keine Kugeln mehr, Kugelanzahl noch nicht empfangen, kein Echo vorgemerkt, Auto-Annahme aktiv.

Ein Zug kostet standardmäßig 1 Kugel. Die Kosten folgen dem Qualitätsregler des Spiels, so wie er bei deiner letzten Kugelausgabe stand.

### Die Jagd

1. Öffne das Echo-Journal des Spiels.
2. **Strg+Klick** auf die Echos, die du willst. Ein goldener Rahmen markiert sie. Strg+Klick erneut entfernt eines. Es funktioniert in beiden Listen: dem Katalog und den Echos deines Runs.
3. Schalte in den Optionen von Ebonhold **auto-accept loadout echoes** aus. Die Jagd startet nicht, solange diese Option an ist.
4. Ist die Automatik an, schalte oben rechts im Journal **Jagd** ein. Solange er an ist, überlässt dir die Automatik die Züge. Er bleibt an, bis du ihn ausschaltest.
5. Stelle bei einem Kugel-Zug den Regler auf die Anzahl Kugeln, die du auszugeben bereit bist. Die Beschriftung zeigt, wie viele Züge das bezahlt.
6. Klicke auf **Jagen (n)**. Der Knopf wird zu **Stopp (ausgegeben/Budget)**. Klicke darauf, um jederzeit anzuhalten.

Optional: Klicke auf das farbige Quadrat, um die niedrigste Seltenheit für jedes vorgemerkte Echo zu wählen. Standardmäßig zählt ein vorgemerktes Echo in jeder Seltenheit.

Die Jagd hält an, wenn:

- ein vorgemerktes Echo fällt. Die Liste der vorgemerkten Echos wird dann geleert;
- das Budget ausgegeben ist;
- dir zu wenige Kugeln bleiben;
- du auf **Stopp** klickst oder selbst eine Karte nimmst;
- keine Karte des Zugs vergessen werden kann oder der Server einen Schritt verweigert.

Das Banner am oberen Bildschirmrand zeigt den Fortschritt: ausgegebene Kugeln, die gesuchten Echos und die Karten des letzten Zugs. Es sagt auch, warum die Jagd angehalten hat.

Die Jagd **nimmt die Karte nie für dich**. Zwei vorgemerkte Echos können zusammen fallen. Du wählst.

Der Regler reicht bis zur Anzahl Kugeln, die du besitzt. Ein Budget unter den Kosten eines Zugs wird mit einer Meldung abgelehnt.

Die Liste der vorgemerkten Echos wird nicht gespeichert. Nach einem Neuladen oder einer neuen Anmeldung ist sie leer.

## 🌐 Teilen

### Öffentliche Builds

1. Öffne den Build im Editor. Klicke im Reiter **Übersicht** auf **Veröffentlichen** und dann auf **Speichern**.
2. Spiele einen Charakter mit diesem aktiven Build von Stufe 1 auf 80. Der Build wird **Bestätigt**.
3. Ein öffentlicher und bestätigter Build wird automatisch an andere Spieler gesendet.

Eine Änderung am Build entfernt die Bestätigung. Spiele erneut, um ihn zu bestätigen.

Alles in einem öffentlichen Build wird geteilt: Gewichte, Boni, Automatik-Einstellungen, Verbannungsliste und Beschreibung.

So durchsuchst du die Builds anderer:

1. Klicke auf **Öffentliche Builds**. Die Liste öffnet sich für deine Klasse. Filtere nach Klasse und Spez.
2. Klicke auf **Importieren**, um einen Build in deine Liste zu kopieren. Die Kopie ist privat und öffnet sich sofort.
3. **Aktualisieren** erscheint, wenn der Autor eine neuere Version eines von dir importierten Builds veröffentlicht hat.
4. **Neu laden** fragt andere Spieler nach ihren Builds. Es gibt 30 Sekunden Wartezeit.

Änderst du einen Build, der von einem anderen Spieler stammt, wird er zu deinem. Der Autor wechselt zu dir und die Bestätigung wird entfernt.

### Import und Export

- **Exportieren** (unten links im Editor) zeigt einen Text. Kopiere ihn und gib ihn einem Freund.
- **Build importieren** (linke Spalte) nimmt so einen Text an. Es nimmt auch eine **EBH1**-Zusammenstellung an, die aus dem Echo-Fenster des Spiels kopiert wurde. Eine EBH1-Zusammenstellung erstellt keinen Build. Sie fließt nur in die Gemeinschaftsnote ein.

## 📊 Deine Runs verfolgen

Öffne einen Build. Seine Seite hat vier Reiter.

- **Übersicht**: Titel, Autor, Spez., Datum, Status (öffentlich oder privat, bestätigt oder nicht), gesperrte Echos und Beschreibung.
- **Statistik**: gesehene Echos, abgeschlossene Läufe (Stufe 80 erreicht), neu begonnene Läufe, Wahlen, Neuziehungen, Verbannungen und Einfrierungen sowie der Anteil deiner Wahlen nach Seltenheit.
- **Fehlend**: die Echos der Build-Klasse, die du noch nicht besitzt und auf deiner Stufe bekommen kannst. Jede Zeile zeigt, wo man das Echo findet. Die gesperrten Echos des Builds stehen vorn.
- **Logbuch**: eine Karte pro Run. Klicke auf eine Karte, um jede Entscheidung zu sehen: Uhrzeit, Aktion, angebotene Echos mit ihren Noten und deine übrigen Verbannungen, Neuziehen und Einfrieren. **Exportieren** gibt den Run als Text aus. **X** löscht einen Run. **Alles löschen** löscht alle Runs.

Statistik und Logbuch zeichnen die Aktionen der Automatik auf.

Ein Run endet, wenn dein Charakter wieder auf Stufe 1 ist. Die 25 letzten Runs behalten jede Entscheidung. Ältere Runs behalten eine Zusammenfassung. Das Addon behält höchstens 200 Runs.

## 🔧 Einstellungen und Befehle

- `/ebb` oder `/ebonbuilds`: öffnet oder schließt das Fenster. `/ebb help` gibt den Befehl aus.
- Minikarten-Knopf: Klicke, um das Fenster zu öffnen. Ziehe ihn, um ihn zu verschieben.
- Zahnrad-Symbol oben rechts im Fenster: die Einstellungen.
  - **Aktionsverzögerung** (0,1 bis 3 Sekunden, standardmäßig 2): die Wartezeit, bevor die Automatik handelt. Sehr niedrige Werte können das Addon stören.
  - **Anzeigedauer des Banners** (0,1 bis 3 Sekunden, standardmäßig 3): wie lange das Banner sichtbar bleibt.
- `/eapi lang`: ändert die Sprache des Addons.

## 📜 Lizenz & Credits

Ursprünglicher Autor: **Sanavesa** — Fork gepflegt von **Siphelis**.

Dieses Projekt steht unter einer zusammengesetzten Lizenz (MIT-Basis + PolyForm
Noncommercial für die Änderungen) — siehe [LICENSE](https://github.com/Siphelis/EbonBuilds/blob/main/LICENSE)
für die Einzelheiten.

---
