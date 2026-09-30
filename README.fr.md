# 🔮 EbonBuilds

**Planifiez vos builds d'Échos, laissez l'addon choisir vos Échos, et relancez les tirages d'Orbe jusqu'à obtenir l'Écho voulu.**

[EbonBuilds](https://github.com/Siphelis/EbonBuilds) est un addon pour Project Ebonhold. Il vous aide avec les Échos de vos runs.

[English](README.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

## Table des matières

- [Fonctionnalités](#-fonctionnalités)
- [Installation](#-installation)
- [Démarrage rapide](#-démarrage-rapide)
- [Les builds](#-les-builds)
- [Étoiles et note communautaire](#-étoiles-et-note-communautaire)
- [Automatisation](#-automatisation)
- [Relance avec les Orbes et chasse](#-relance-avec-les-orbes-et-chasse)
- [Partage](#-partage)
- [Suivre vos runs](#-suivre-vos-runs)
- [Réglages et commandes](#-réglages-et-commandes)
- [Licence et crédits](#-licence-et-crédits)

---

## ✨ Fonctionnalités

- **Builds.** Écrivez un plan pour chaque build : les Échos visés et l'envie que vous avez de chacun. Ouvrez un build depuis **Builds enregistrés** ou **Builds des joueurs** pour voir tous ses Échos, comme dans le journal des Échos du jeu.
- **Étoiles.** Chaque Écho reçoit de 1 à 3 étoiles pour votre classe. Elles apparaissent sur les cartes du tirage, dans le journal des Échos du jeu et dans la fenêtre de détail d'un build de votre classe.
- **Automatisation.** À chaque tirage, l'addon peut choisir, bannir, relancer ou geler à votre place, selon votre build actif.
- **Relance à l'Orbe et chasse.** Sur un tirage d'Orbe, l'addon peut relancer avec une Orbe. Il peut aussi recommencer jusqu'à ce qu'un Écho que vous avez marqué sorte.
- **Partage.** Les builds que le jeu mémorise dans vos emplacements de build sont partagés automatiquement. Parcourez les builds des autres joueurs et ajoutez-en un de votre classe à vos wishlists. Profitez de ce que la communauté garde et bannit.
- **Suivi des runs.** Consultez des statistiques par build, les Échos qu'il vous manque, et un journal de chaque décision.

## 📦 Installation

1. [**EbonBuilds**](https://github.com/Siphelis/EbonBuilds/releases/latest) — téléchargez la dernière version.
2. Décompressez le dossier `EbonBuilds` dans `Interface/AddOns/`.
   Installez ou mettez à jour [**EbonAPI**](https://github.com/Siphelis/EbonAPI/releases/latest) de la même façon. [EbonBuilds](https://github.com/Siphelis/EbonBuilds) nécessite [EbonAPI](https://github.com/Siphelis/EbonAPI) 2.0.0 ou une version plus récente. [EbonAPI](https://github.com/Siphelis/EbonAPI) est commun aux addons Ebonhold. [EbonBuilds](https://github.com/Siphelis/EbonBuilds) ne démarre pas sans lui.
3. Dans l'écran de sélection des addons, vérifiez que [**EbonBuilds**](https://github.com/Siphelis/EbonBuilds) et [**EbonAPI**](https://github.com/Siphelis/EbonAPI) sont cochés.

L'addon utilise la langue de votre jeu : anglais, français, allemand ou espagnol. Pour la changer, appuyez sur Échap et cliquez sur **EbonAPI**. Sur la page **Général**, choisissez-la dans la liste **Langue**.

## 🚀 Démarrage rapide

1. Tapez `/ebb`, ou cliquez sur le bouton [EbonBuilds](https://github.com/Siphelis/EbonBuilds) de la minicarte. La fenêtre s'ouvre.
2. Cliquez sur **+ Nouveau build**.
3. Choisissez **Mode assistant** pour être guidé pas à pas, ou **Mode expert** pour aller directement à l'éditeur.
4. Cliquez sur **Enregistrer**. Le build devient votre build actif. Son automatisation est activée.
5. Jouez. À chaque tirage, l'addon attend deux secondes, agit, puis affiche un bandeau qui indique ce qu'il a fait.

Vous voulez seulement les étoiles, sans automatisation ? Cliquez sur **Automatisation : OUI** sur la page du build. Le bouton passe à **Automatisation : NON**. Les étoiles restent.

**Builds enregistrés** est vide ? Ouvrez une fois la fenêtre des Échos du jeu.

## 📋 Les builds

### La fenêtre

La colonne de gauche contient :

- **Builds enregistrés** : les builds et les wishlists mémorisés par le jeu lui-même.
- **Builds des joueurs** : les builds partagés par les autres joueurs.
- **+ Nouveau build** : crée un build.
- Vos builds. Cliquez sur l'un d'eux pour l'ouvrir. Il devient votre build actif pour ce personnage. L'automatisation suit le build actif.

Dans **Builds enregistrés**, chaque build est une carte avec son numéro d'emplacement, son nom, son nombre d'Échos et ses Échos verrouillés. Un **>** vert marque le build actif du jeu.

### La fenêtre de détail

Cliquez sur une carte dans **Builds enregistrés** ou **Builds des joueurs**. Sa fenêtre de détail s'ouvre à côté de la fenêtre principale. Elle se ferme avec la fenêtre principale, ou quand vous quittez la liste.

- L'en-tête montre la classe, le nombre d'Échos et les familles du build. Chaque famille indique son nombre d'Échos, par exemple **Tank (3)**. Les Échos sans famille sont rangés sous **Sans famille**.
- Sous l'en-tête, une rangée d'emplacements montre les Échos verrouillés. Si le joueur ne les a pas transmis, une ligne le signale. La rangée a autant d'emplacements que vous en avez débloqué dans le jeu.
- Ensuite, une grille montre chaque Écho du build, comme le journal des Échos du jeu. Les plus rares passent en premier.

Dans la grille :

- Chaque Écho a une seule case, quelles que soient ses raretés. Un petit disque donne les piles de chaque rareté, pour trois raretés au plus.
- Un cadenas marque un Écho verrouillé. Son nom est doré.
- Un livre marque un Écho qui demande un tome.
- Un halo tourne derrière chaque icône, dans la couleur de sa rareté. Il est doré sur un Écho verrouillé.
- Sur un build de votre classe, l'infobulle montre les étoiles de l'Écho, comme dans le journal des Échos du jeu.

Pour filtrer la grille :

1. Cochez une famille dans l'en-tête. La grille ne montre plus que ses Échos.
2. Cochez d'autres familles pour ajouter leurs Échos. Un Écho s'affiche s'il appartient à l'une d'elles.
3. Décochez-les toutes pour revoir tous les Échos.

La rangée des Échos verrouillés n'est jamais filtrée. Les familles cochées restent quand vous ouvrez un autre build. Elles sont décochées quand la fenêtre se ferme.

Pour ajouter un build d'un joueur à vos wishlists :

1. Ouvrez un build de votre classe depuis **Builds des joueurs**.
2. Cliquez sur **Ajouter à ma wishlist** en bas.
3. Tapez un nom, ou gardez celui qui est proposé.
4. Confirmez.

Le build part au serveur comme une nouvelle wishlist, avec ses Échos et ses Échos verrouillés. Le chat confirme sa création. Vous la retrouvez ensuite parmi vos wishlists dans le journal des Échos du jeu, et dans **Builds enregistrés**. Sur un build d'une autre classe, le bouton reste grisé : une wishlist est toujours pour votre propre classe.

### Mode assistant

L'assistant demande :

1. Vos Échos verrouillés.
2. Un bonus pour les Échos nouveaux. Cette étape n'apparaît que si vous avez choisi Puissance adaptative.
3. Vos familles : aucune, secondaire (+10) ou principale (+20).
4. Un bonus pour chaque rareté.
5. Les Échos qui comptent le plus : **Je le veux**, **Bien**, **Correct** ou **Bof**.
6. Un titre et une description.

L'éditeur s'ouvre à la fin. Vérifiez-le, puis cliquez sur **Enregistrer**.

### L'éditeur

Cliquez sur **Modifier** sur la page d'un build. L'éditeur a quatre onglets.

| Onglet | Ce que vous réglez |
| --- | --- |
| **Aperçu** | Classe, spé, titre, description et Échos verrouillés. |
| **Échos** | Un poids pour chaque Écho. |
| **Bonus** | Des points en plus par rareté, par famille et pour les Échos nouveaux. |
| **Automatisation** | Bannissements, protections et seuils. Voir [Automatisation](#-automatisation). |

**Enregistrer** conserve vos changements. **Annuler** les abandonne. **Exporter** (en bas à gauche) donne le build sous forme de texte.

Les **Échos verrouillés** sont les Échos permanents que votre build vise. Il y a autant d'emplacements que vous en avez débloqué dans le jeu, 6 au plus. Cliquez sur un emplacement pour choisir un Écho. Faites un clic droit pour le vider.

La **description** peut contenir des liens d'Échos. Cliquez sur **+ Lien d'Écho**.

**Onglet Échos**

1. Un poids est un nombre entier, 0 ou plus. Plus il est haut, plus vous voulez l'Écho.
2. Un seul poids couvre toutes les raretés d'un Écho.
3. À côté du poids, vous voyez la note de chaque rareté. **Verrouillé** ou **Banni** remplace la note d'un Écho que vous avez verrouillé ou banni.
4. Utilisez la zone de recherche, la liste des raretés et la liste des familles pour filtrer.
5. Cochez **Toutes les classes** pour voir les Échos des autres classes.

**Onglet Bonus**

- **Bonus de rareté** : des points en plus pour chaque rareté.
- **Bonus de famille** : des points en plus pour chaque famille.
- **Bonus de nouveauté** : des points en plus pour un Écho que vous n'avez pas encore.
- Chaque valeur s'ajoute (**+**) ou se multiplie (**x**). Cliquez sur le petit bouton à côté du nombre pour changer. En mode **x**, une valeur inférieure à 1 baisse la note.

## ⭐ Étoiles et note communautaire

### Ce que veulent dire les étoiles

- 3 étoiles : indispensable pour votre classe.
- 2 étoiles : entre les deux.
- 1 étoile : vous pouvez vous en passer.
- 3 étoiles grises : la plupart des joueurs le bannissent.
- Aucune étoile : votre classe ne peut pas utiliser cet Écho.

### Où les voir

1. Dans le journal des Échos du jeu, survolez un Écho. La ligne **Intérêt pour** votre classe affiche les étoiles. Quand la communauté connaît l'Écho, une deuxième ligne **Va bien avec** cite jusqu'à trois Échos souvent gardés avec lui.
2. Sur un tirage, sous l'icône de chaque carte.
3. Cliquez sur une carte dans **Builds enregistrés** ou **Builds des joueurs**. Dans la fenêtre de détail qui s'ouvre, survolez un Écho. L'infobulle affiche les mêmes lignes que dans le journal. Cela ne marche que pour un build de votre classe.

### Comment la note est calculée

1. Chaque Écho part de sa rareté. Plus il est rare, plus il part haut.
2. L'addon lit ensuite les builds de votre classe : vos **Builds enregistrés** et les **Builds des joueurs**. Plus il y a de builds qui gardent un Écho, plus il monte.
3. Sur les cartes du tirage et dans l'infobulle, les builds qui ressemblent à votre run actuel pèsent plus lourd. Un Écho qui va avec ce que vous possédez déjà monte.
4. Les listes de bannissement font baisser un Écho. Dès que les listes de trois joueurs sont connues, un Écho banni par la moitié d'entre eux ou plus reçoit des étoiles grises. Un Écho banni par un cinquième d'entre eux ou plus perd une étoile.
5. Chaque joueur compte pour un, quel que soit son nombre de builds.

Plus il y a de joueurs qui utilisent l'addon, meilleure est la note.

## 🤖 Automatisation

L'automatisation joue vos tirages à votre place. Elle suit votre **build actif**. Chaque build a son propre interrupteur : **Automatisation : OUI** ou **Automatisation : NON** sur la page du build. Un nouveau build démarre avec l'automatisation activée.

L'automatisation ne dépense jamais d'Orbes. Elle utilise seulement les Bannissements, les Relances et les Gels que le jeu vous donne.

### Ce qu'elle fait à chaque tirage

Après une courte attente (2 secondes par défaut), l'addon parcourt cette liste. Il fait la première action qui s'applique.

1. **Prendre un Écho verrouillé.** Si un Écho verrouillé de votre build est proposé, l'addon le prend.
2. **Bannir.** L'addon bannit d'abord un Écho de votre liste de bannissement. Ensuite, il bannit un Écho dont la note est sous le seuil de bannissement. Il lui faut un Bannissement en réserve. Il ignore les familles protégées, les cartes gelées et les cartes reportées.
3. **Relancer.** L'addon relance quand le meilleur Écho proposé est sous le seuil de relance et qu'aucun Écho proposé n'atteint le seuil de garde. Il lui faut une Relance en réserve.
4. **Geler.** Quand deux Échos proposés dépassent le seuil de gel, l'addon gèle le moins bon et prend le meilleur. Il lui faut un Gel en réserve.
5. **Prendre le meilleur.** Sinon, l'addon prend l'Écho qui a la meilleure note.

Un bandeau en haut de l'écran montre chaque action. Il liste les Échos proposés avec leur note, marque celui qui est choisi avec **>> <<**, et indique vos Bannissements, Relances et Gels restants. Cliquez sur le bandeau pour le fermer. Gardez la souris dessus pour le garder ouvert.

### L'onglet Automatisation

- **Protection contre le bannissement.** Cochez les familles qui ne doivent jamais être bannies.
- **Échos bannis.** Les Échos à bannir en premier, quelle que soit leur note. Cliquez sur **Ajouter** pour en ajouter un. Cliquez sur une icône pour le retirer. En dessous, choisissez ce qui se passe quand tous les Échos proposés sont bannis et qu'il ne reste aucun Bannissement : **Meilleure note** ou **Au hasard**.
- **Source de la note.** Choisissez d'où viennent les notes :
  - **Matrice commune** (par défaut) : la note vient de la communauté, plus vos poids.
  - **Poids manuels** : la note vient seulement de vos poids et de vos bonus.

### Les seuils avec la Matrice commune

La note va de -5 (tout le monde refuse l'Écho) à +3 (tout le monde le garde). Un Écho ordinaire se situe près de +1.

| Seuil | Par défaut | Effet |
| --- | --- | --- |
| **Bannir sous** | -2,00 | Bannit un Écho proposé sous cette note. |
| **Relancer sous** | 0,00 | Relance quand le meilleur Écho proposé est sous cette note. |
| **Garde de relance au-dessus** | 0,00 | Bloque la relance quand un Écho proposé atteint cette note. Laissez-la au niveau du seuil de relance ou en dessous. |
| **Geler au-dessus** | +2,00 | Gèle quand deux Échos proposés dépassent cette note. |
| **Influence des poids** | 1,00 | Ce que vos poids ajoutent à la note. À 1,00, l'Écho qui a votre poids le plus haut ajoute 1 point. |

Deux autres points à connaître :

1. Chaque rareté ajoute un petit bonus à la note. Les Échos plus rares passent devant quand les notes sont proches.
2. La **Matrice commune** a besoin de trois builds de votre classe parmi vos **Builds enregistrés** et les **Builds des joueurs**, ou des listes de bannissement de trois joueurs. D'ici là, l'addon fonctionne comme avec **Poids manuels**.

Avec **Poids manuels**, les seuils sont des pourcentages du **Pic** : la meilleure note possible pour votre classe avec vos bonus. Dans ce mode, la relance compare la note totale des Échos proposés, et non la meilleure note.

Les étoiles sont une vue simple de la note communautaire. L'automatisation utilise la note plus fine, de -5 à +3.

## 🔮 Relance avec les Orbes et chasse

### Comment ça marche

Sur un tirage d'Orbe, le serveur refuse la relance, le bannissement et le gel. [EbonBuilds](https://github.com/Siphelis/EbonBuilds) ajoute un panneau sous les cartes. Le panneau enchaîne deux actions que le jeu autorise déjà :

1. Il prend l'une des cartes proposées. L'Écho est accordé.
2. Il dépense des Orbes pour oublier cet Écho. Le jeu distribue trois nouvelles cartes.

Vous obtenez trois nouvelles cartes et moins d'Orbes. Vous possédez les mêmes Échos qu'avant. Le serveur vérifie chaque étape.

Un point à connaître : entre les deux étapes, vous possédez vraiment l'Écho pris. Si le serveur refuse l'étape 2, vous le gardez. L'addon prend donc la carte la moins gênante à garder. L'infobulle la nomme avant que vous cliquiez.

### La carte prise

1. La carte de plus faible rareté passe en premier.
2. Un Écho permanent n'est jamais pris. Le serveur refuserait de l'oublier.
3. Un Écho dont la pile est pleine n'est jamais pris. Le serveur refuserait de l'accorder.
4. Un Écho que vous chassez n'est jamais pris.
5. La carte garantie d'un emplacement de build, les cartes gelées et les cartes reportées passent en dernier. Elles étaient gardées pour une raison.

### Le panneau

Le panneau apparaît sous les cartes, uniquement sur un tirage d'Orbe.

- **Relancer (Orbe : N)** : une relance. N est votre nombre d'Orbes. L'infobulle nomme la carte prise et le coût.
- **Chasser (n)** : lance une chasse. n est le nombre d'Échos que vous avez armés.
- **Carré coloré** : la rareté recherchée.
- **Curseur** : le nombre d'Orbes que la chasse peut dépenser.

Sur un tirage de montée de niveau, le bouton de relance d'origine du jeu reste tel quel. Si aucune carte du tirage ne peut être oubliée, le panneau disparaît. Un bouton grisé a une infobulle qui dit pourquoi : plus d'Orbes, nombre d'Orbes pas encore reçu, aucun Écho armé, auto-acceptation activée.

Un tirage coûte 1 Orbe par défaut. Le coût suit le curseur de qualité du jeu, tel qu'il était à votre dernière dépense d'Orbe.

### La chasse

1. Ouvrez le journal des Échos du jeu.
2. Faites **Ctrl+clic** sur les Échos que vous voulez. Un contour doré les marque. Refaites Ctrl+clic pour en retirer un. Cela marche dans les deux listes : le catalogue et les Échos de votre run. L'infobulle d'un Écho vous le rappelle : **Ctrl+clic : chasser cet Écho**, ou **Ctrl+clic : ne plus chasser** une fois qu'il est marqué.
3. Dans les options d'Ebonhold, désactivez **auto-accept loadout echoes**. La chasse ne démarre pas tant que cette option est activée.
4. Si l'automatisation est activée, allumez **Chasse** en haut à droite du journal. Tant qu'il est allumé, l'automatisation vous laisse les tirages. Il reste allumé jusqu'à ce que vous l'éteigniez.
5. Sur un tirage d'Orbe, réglez le curseur sur le nombre d'Orbes que vous acceptez de dépenser. L'étiquette indique combien de tirages cela paie.
6. Cliquez sur **Chasser (n)**. Le bouton devient **Arrêter (dépensé/budget)**. Cliquez dessus pour arrêter à tout moment.

Facultatif : cliquez sur le carré coloré pour choisir la rareté minimale de chaque Écho armé. Par défaut, un Écho armé compte dans toutes les raretés.

La chasse s'arrête quand :

- un Écho armé sort. La liste des Échos armés est alors vidée ;
- le budget est dépensé ;
- il vous reste trop peu d'Orbes ;
- vous cliquez sur **Arrêter**, ou vous prenez une carte vous-même ;
- aucune carte du tirage ne peut être oubliée, ou le serveur refuse une étape.

Le bandeau en haut de l'écran montre l'avancement : Orbes dépensées, Échos recherchés et cartes du dernier tirage. Il dit aussi pourquoi la chasse s'est arrêtée.

La chasse **ne prend jamais la carte à votre place**. Deux Échos armés peuvent sortir ensemble. C'est vous qui choisissez.

Le curseur monte jusqu'au nombre d'Orbes que vous possédez. Un budget inférieur au coût d'un tirage est refusé avec un message.

La liste des Échos armés n'est pas sauvegardée. Elle est vide après un rechargement ou une nouvelle connexion.

## 🌐 Partage

### Builds des joueurs

Les builds que le jeu mémorise dans vos emplacements de build sont partagés automatiquement avec les autres joueurs. Il n'y a rien à activer. Aucun réglage ne désactive le partage.

- De chacun de ces builds, seuls les Échos sont partagés : leur rareté, leurs piles et lesquels sont verrouillés. Le nom du build n'est pas envoyé.
- De vos builds de la colonne de gauche, seules les listes de bannissement sont partagées, et seulement pour les builds de votre classe. Elles comptent dans la note communautaire.
- Vos poids, vos bonus, vos autres réglages d'automatisation et vos descriptions ne sont pas partagés.

Pour parcourir les builds des autres :

1. Cliquez sur **Builds des joueurs**. La liste s'ouvre sur votre classe. Choisissez une autre classe, ou **Toutes les classes**.
2. Chaque carte montre la classe, le nombre d'Échos et les Échos verrouillés. Aucun nom de joueur n'est affiché. Les builds qui ont le plus d'Échos passent en premier.
3. Cliquez sur une carte pour ouvrir sa fenêtre de détail. Sur un build de votre classe, **Ajouter à ma wishlist** l'envoie au serveur comme une nouvelle wishlist.
4. **Actualiser** demande leurs builds aux autres joueurs. Il y a une attente de 30 secondes.

La liste se remplit d'elle-même à mesure que les autres joueurs partagent leurs builds. Elle les garde d'une session à l'autre.

### Import et export

- **Exporter** (en bas à gauche de l'éditeur) affiche un texte. Copiez-le et donnez-le à un ami.
- L'import revient dans une prochaine mise à jour.

Si vous modifiez un build qui vient d'un autre joueur, il devient le vôtre. L'auteur devient vous.

## 📊 Suivre vos runs

Ouvrez un build. Sa page a quatre onglets.

- **Aperçu** : titre, auteur, spé, date, Échos verrouillés et description.
- **Stats** : Échos vus, runs terminés (niveau 80 atteint), runs recommencés, choix, relances, bannissements et gels utilisés, et la part de vos choix par rareté.
- **Manquants** : les Échos de la classe du build que vous n'avez pas encore et que vous pouvez obtenir à votre niveau. Chaque ligne indique où trouver l'Écho. Les Échos verrouillés du build passent en premier.
- **Journal** : une carte par run. Cliquez sur une carte pour voir chaque décision : heure, action, Échos proposés avec leur note, et vos Bannissements, Relances et Gels restants. **Exporter** donne le run sous forme de texte. **X** supprime un run. **Tout effacer** supprime tous les runs.

Les statistiques et le journal enregistrent les actions de l'automatisation.

Un run se termine quand votre personnage repasse au niveau 1. Les 25 derniers runs gardent chaque décision. Les runs plus anciens gardent un résumé. L'addon conserve 200 runs au maximum.

## 🔧 Réglages et commandes

- `/ebb` ou `/ebonbuilds` : ouvre ou ferme la fenêtre. `/ebb help` affiche la commande.
- Bouton de la minicarte : cliquez pour ouvrir la fenêtre. Faites-le glisser pour le déplacer. Ses options sont sur la page **Addons connectés** de la fenêtre d'[EbonAPI](https://github.com/Siphelis/EbonAPI) (appuyez sur Échap et cliquez sur **EbonAPI**) :
  - **Bouton de la minimap** : **Sur la minimap**, **Dans le bouton d'EbonAPI** ou **Masqué**.
  - **Verrouiller sa position** : le bouton ne se déplace plus.
  - **Remettre à sa place** : le bouton revient à son emplacement de départ.
- Icône d'engrenage à côté du bouton de fermeture de la fenêtre : les réglages. Ils s'ouvrent sur la page [EbonBuilds](https://github.com/Siphelis/EbonBuilds) de la fenêtre d'[EbonAPI](https://github.com/Siphelis/EbonAPI).
  - **Délai d'action** (de 0,1 à 3 secondes, 2 par défaut) : l'attente avant que l'automatisation agisse. Des valeurs très basses peuvent faire dysfonctionner l'addon.
  - **Durée du bandeau** (de 0,1 à 3 secondes, 3 par défaut) : le temps pendant lequel le bandeau reste affiché.
- Les fenêtres de l'addon suivent le style choisi sur la page **Apparence** de la fenêtre d'[EbonAPI](https://github.com/Siphelis/EbonAPI).
- **Langue**, sur la page **Général** de la fenêtre d'[EbonAPI](https://github.com/Siphelis/EbonAPI) : change la langue de l'addon.

## 📜 Licence et crédits

Auteur original : **Sanavesa** — fork maintenu par **Siphelis**.

Ce projet est distribué sous une licence composite (base MIT + PolyForm
Noncommercial pour les modifications) — voir [LICENSE](https://github.com/Siphelis/EbonBuilds/blob/main/LICENSE)
pour les détails.

---
