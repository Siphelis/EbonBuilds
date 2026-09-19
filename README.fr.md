# 🔮 EbonOrbReroll

**Le tirage d'un Orbe des Souvenirs Perdus n'est plus une impasse.**

Le serveur refuse la relance sur un tirage d'Orbe. EbonOrbReroll fait à votre
place les deux gestes qu'un joueur exécuterait à la main pour la contourner, puis
les répète jusqu'à ce que l'Écho que vous cherchez tombe. Le tout dans un panneau
qui se glisse sous les cartes et disparaît dès qu'il n'a plus rien à y faire.

[English](README.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

## Table des matières

- [Pourquoi cette extension](#-pourquoi-cette-extension)
- [Fonctionnalités](#-fonctionnalités)
- [Installation](#-installation)
- [Démarrage rapide](#️-démarrage-rapide)
- [Anatomie du code](#-anatomie-du-code--comment-ça-fonctionne)
- [Licence et crédits](#-licence-et-crédits)

---

## 🔥 Pourquoi cette extension

Sur un tirage d'Orbe, le serveur refuse la relance, le bannissement et le gel —
ProjectEbonhold masque d'ailleurs son propre bouton *Relancer* à ce moment-là.
Rien dans le protocole ne relance ce tirage, et cette extension ne prétend pas le
contraire. Elle exécute deux actions ordinaires, coup sur coup :

1. **Prendre une carte** sur la table. La pile est accordée.
2. **Dépenser un orbe pour l'oublier à nouveau**, ce qui pousse un nouveau
   tirage d'Échos.

Bilan : trois nouvelles cartes, un orbe en moins, exactement les mêmes Échos
possédés qu'avant. Rien de nouveau n'est envoyé, rien n'est décidé en local — le
serveur valide la possession, le verrou et la charge à la seconde étape, comme il
l'a toujours fait.

La seule différence avec une vraie relance : entre les deux gestes, vous possédez
réellement l'Écho sacrifié. Si le serveur refuse la seconde étape, il vous reste.
C'est pourquoi la carte est choisie comme la chose la moins chère à se retrouver
sur les bras, et pourquoi l'infobulle la nomme **avant** le clic.

## ✨ Fonctionnalités

- **Bouton « Reroll (Orb) »** sous les trois cartes, avec le nombre d'orbes
  possédés. Il n'apparaît que sur un tirage d'Orbe : un tirage de montée de
  niveau a déjà son propre bouton de relance, auquel rien n'est touché.
- **La carte sacrifiée est choisie, pas subie.** Qualité la plus basse d'abord.
  Jamais un Écho permanent (le serveur refuserait la seconde étape), jamais une
  pile déjà pleine (il refuserait la première), jamais un Écho que vous chassez.
  La carte garantie du slot de build, les cartes gelées et les cartes reportées
  ne passent qu'en dernier recours : elles ont été gardées pour une raison.
- **La chasse.** Armez des Échos dans le journal du jeu, fixez le nombre d'orbes
  que vous acceptez d'y laisser, et l'extension relance jusqu'à ce que l'un
  d'eux soit distribué. Elle **ne le prend jamais pour vous** : deux Échos voulus
  peuvent tomber ensemble, et arbitrer entre eux vous regarde. Elle s'arrête et
  le dit.
- **Le coût suit le curseur de qualité du jeu**, lu sur votre dernière dépense
  d'orbe. Pas un second réglage à côté de celui qui existe déjà.
- **Curseur de budget** borné par ce que vous possédez réellement. Un budget qui
  ne paie même pas un tirage est refusé d'avance, en nommant le chiffre à bouger,
  plutôt que de lancer une chasse qui s'arrêterait dans la seconde.
- **Des refus qui expliquent.** Bouton grisé et infobulle qui dit pourquoi : plus
  d'orbes, compte pas encore connu, rien d'armé, auto-acceptation active. Et
  quand aucune carte de la table ne peut être oubliée, le bouton disparaît au
  lieu de rester grisé — un « Relancer (0) » éteint dirait « vous n'avez plus de
  relances », ce qui serait une autre affirmation, et une fausse.
- **Aucune boucle.** Tout est accroché à des fonctions que ProjectEbonhold appelle
  déjà quand son état change, plus des minuteurs qui s'arment et se désarment
  seuls. Entre deux tirages, l'extension n'exécute pas une ligne de Lua.
- **Rien à nettoyer.** La liste d'Échos chassés vit le temps d'une session et
  meurt avec elle : aucune SavedVariables, rien à migrer, rien de périmé à
  expliquer dans trois patchs.

## 📦 Installation

1. [**EbonOrbReroll**](https://github.com/Siphelis/EbonOrbReroll/releases/latest) — téléchargez la dernière version.
2. Décompressez le dossier `EbonOrbReroll` dans
   `Interface/AddOns/`.
3. Vérifiez dans l'écran de sélection des extensions que
   **EbonOrbReroll** est bien coché.

## 🕹️ Démarrage rapide

Aucune commande slash : tout tient dans le panneau qui apparaît sous les cartes.

**Pour une relance unique**, il n'y a rien à préparer — cliquez sur
**Reroll (Orb)**. L'infobulle nomme la carte qui sera sacrifiée et le coût.

**Pour une chasse :**

1. Ouvrez le journal des Échos et **Ctrl+clic** sur les icônes que vous voulez.
   Un liseré doré marque celles qui sont armées, un second Ctrl+clic les retire.
   Les deux grilles répondent — le catalogue à droite et les Échos de la run en
   cours à gauche — de sorte que viser une pile supplémentaire de quelque chose
   que vous possédez déjà reste possible.
2. Coupez l'option d'Ebonhold **« auto-accept loadout echoes »**. La chasse la
   refuse tant qu'elle est active : elle prendrait la carte à votre place.
3. Sur un tirage d'Orbe, réglez le curseur sur le nombre d'orbes que vous
   acceptez de dépenser. L'étiquette affiche combien de tirages cela paie.
4. Cliquez sur **Hunt**. Le bouton devient **Stop** et compte les orbes dépensés ;
   re-cliquez pour arrêter à tout moment.

L'extension s'arrête d'elle-même dès qu'un Écho armé est distribué, quand le
budget est épuisé, ou dès que quelque chose l'empêche de continuer — et le chat
dit toujours lequel des trois.

## 🧠 Anatomie du code — comment ça fonctionne

Deux fichiers, chargés dans cet ordre par le `.toc` : le premier définit la table
de chaînes partagée, le second en prend une référence au chargement. La
dépendance ne joue pas dans l'autre sens — le moteur lit `ns.Wishlist` au moment
de l'appel, jamais au chargement, donc il ne peut pas attraper le second fichier
à moitié construit.

| Fichier | Rôle exact |
| --- | --- |
| `EbonOrbReroll.lua` | Le moteur. La table de chaînes, la machine à deux temps (prendre, puis oublier) et ses minuteurs de garde, le choix de la carte sacrifiée, le superviseur de chasse et son budget, la lecture du multiplicateur de qualité sur vos propres dépenses, les accroches sur ProjectEbonhold (`PerkUI.Show` / `Hide` / `UpdateSinglePerk` / `ResetSelection`, `OrbService.ClearOffer`, les boutons qui replient les cartes), et le panneau lui-même : deux boutons et un curseur. |
| `EbonOrbWishlist.lua` | La greffe sur le journal des Échos. L'ensemble des Échos voulus, le Ctrl+clic qui l'alimente sur les deux grilles, le liseré doré, et le sondage qui ne tourne que pendant que le journal est affiché. Aucun panneau de notre côté : le journal dessine déjà chaque Écho, grise ceux jamais découverts et filtre par nom et par classe ; en rebâtir une copie à côté serait une seconde liste, moins bonne. |

L'identité d'un Écho, ici, c'est son `spellId` et rien d'autre. La grille du
journal recycle ses boutons : la même cellule portait un identifiant avant une
recherche et un autre après. Une marque attachée à la cellule suivrait la
cellule ; attachée à l'identifiant, elle suit l'Écho.

## 📜 Licence et crédits

Auteur original : **Sanavesa** — fork maintenu par **Siphelis**.

Ce projet est distribué sous une licence composite (base MIT + PolyForm
Noncommercial pour les modifications) — voir [LICENSE](https://github.com/Siphelis/EbonOrbReroll/blob/main/LICENSE)
pour les détails.

---
