# 🔮 EbonOrbReroll

**Una tirada de Orbe de Recuerdos Perdidos ya no es un callejón sin salida.**

El servidor se niega a relanzar una tirada de Orbe. EbonOrbReroll ejecuta por ti
los dos gestos que un jugador haría a mano para sortearlo, y los repite hasta que
cae el Eco que buscas. Todo ello en un panel que se desliza bajo las cartas y
desaparece en cuanto no tiene nada que hacer allí.

[English](README.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

## Tabla de contenidos

- [Por qué este addon](#-por-qué-este-addon)
- [Funciones](#-funciones)
- [Instalación](#-instalación)
- [Inicio rápido](#️-inicio-rápido)
- [Anatomía del código](#-anatomía-del-código--cómo-funciona)
- [Licencia y créditos](#-licencia-y-créditos)

---

## 🔥 Por qué este addon

En una tirada de Orbe el servidor rechaza relanzar, desterrar y congelar — por
eso ProjectEbonhold oculta ahí su propio botón *Relanzar*. Nada en el protocolo
relanza esa tirada, y este addon no pretende lo contrario. Ejecuta dos acciones
corrientes, una detrás de otra:

1. **Coger una carta** de la mesa. La pila se concede.
2. **Gastar un orbe para olvidarla de nuevo**, que es lo que empuja una nueva
   elección de Ecos.

Resultado: tres cartas nuevas, un orbe menos, exactamente los mismos Ecos en tu
poder que antes. No se envía nada nuevo ni se decide nada en local — el servidor
valida la posesión, el bloqueo y la carga en el segundo paso, como siempre.

La única diferencia con un relanzamiento real: entre los dos pasos posees de
verdad el Eco sacrificado. Si el servidor rechaza el paso 2, se queda contigo.
Por eso la carta se elige como lo más barato con lo que quedarse atrapado, y por
eso la descripción emergente la nombra **antes** del clic.

## ✨ Funciones

- **Un botón "Reroll (Orb)"** bajo las tres cartas, con el número de orbes que
  tienes. Solo aparece en una tirada de Orbe: una tirada de subida de nivel ya
  tiene su propio botón de relanzar, que nunca se toca.
- **La carta sacrificada se elige, no se sufre.** Primero la calidad más baja.
  Nunca un Eco permanente (el servidor rechazaría el paso 2), nunca una pila ya
  llena (rechazaría el paso 1), nunca un Eco que estés cazando. La carta
  garantizada de la ranura de build, las cartas congeladas y las arrastradas solo
  entran como último recurso: se guardaron por algo.
- **La caza.** Arma Ecos desde el propio diario del juego, fija cuántos orbes
  estás dispuesto a gastar, y el addon relanza hasta que uno de ellos salga.
  **Nunca coge la carta por ti**: dos Ecos deseados pueden caer juntos, y elegir
  entre ellos es asunto tuyo. Se detiene y lo dice.
- **El coste sigue el deslizador de calidad del juego**, leído de tu último gasto
  de orbes. No un segundo control al lado del que ya existe.
- **Un deslizador de presupuesto** acotado por lo que realmente posees. Un
  presupuesto que no paga ni una tirada se rechaza de antemano, nombrando la
  cifra que debe moverse, en lugar de arrancar una caza que se detendría en el
  mismo instante.
- **Rechazos que se explican.** Botón atenuado y una descripción emergente que
  dice por qué: sin orbes, recuento aún desconocido, nada armado, autoaceptación
  activa. Y cuando ninguna carta de la mesa puede olvidarse, el botón desaparece
  en vez de quedarse atenuado — un "Reroll (0)" desactivado se leería como "te
  has quedado sin relanzamientos", que es otra afirmación, y falsa.
- **Ningún bucle.** Todo cuelga de funciones que ProjectEbonhold ya llama cuando
  cambia su estado, más temporizadores que se arman y se desarman solos. Entre
  dos tiradas el addon no ejecuta ni una línea de Lua.
- **Nada que limpiar.** La lista de Ecos cazados vive una sesión y muere con
  ella: sin SavedVariables, nada que migrar, nada caduco que explicar dentro de
  tres parches.

## 📦 Instalación

1. [**EbonOrbReroll**](https://github.com/Siphelis/EbonOrbReroll/releases/latest) — descarga la última versión.
2. Descomprime la carpeta `EbonOrbReroll` en
   `Interface/AddOns/`.
3. Comprueba en la pantalla de selección de addons que **EbonOrbReroll** está
   marcado.

## 🕹️ Inicio rápido

Sin comandos slash: todo cabe en el panel que aparece bajo las cartas.

**Para un relanzamiento suelto** no hay nada que preparar — pulsa
**Reroll (Orb)**. La descripción emergente nombra la carta que se sacrificará y
el coste.

**Para una caza:**

1. Abre el diario de Ecos y haz **Ctrl+clic** en los iconos que quieras. Un borde
   dorado marca los armados, y un segundo Ctrl+clic los retira. Ambas rejillas
   responden — el catálogo a la derecha y los Ecos de la run en curso a la
   izquierda — de modo que pedir otra pila de algo que ya posees sigue siendo
   posible.
2. Desactiva la opción de Ebonhold **"auto-accept loadout echoes"**. La caza se
   niega a empezar mientras esté activa: cogería la carta por ti.
3. En una tirada de Orbe, ajusta el deslizador al número de orbes que aceptas
   gastar. La etiqueta muestra cuántas tiradas paga eso.
4. Pulsa **Hunt**. El botón pasa a **Stop** y cuenta los orbes gastados; púlsalo
   de nuevo para detenerlo en cualquier momento.

El addon se detiene solo en cuanto se reparte un Eco armado, cuando se agota el
presupuesto, o en cuanto algo le impide continuar — y el chat siempre dice cuál
de los tres.

## 🧠 Anatomía del código — cómo funciona

Dos archivos, cargados en ese orden por el `.toc`: el primero define la tabla de
cadenas compartida, el segundo toma una referencia a ella al cargarse. La
dependencia no funciona al revés — el motor lee `ns.Wishlist` en el momento de la
llamada, nunca al cargar, así que no puede pillar el segundo archivo a medio
construir.

| Archivo | Papel exacto |
| --- | --- |
| `EbonOrbReroll.lua` | El motor. La tabla de cadenas, la máquina de dos pasos (coger y luego olvidar) y sus temporizadores de guardia, la elección de la carta sacrificada, el supervisor de la caza y su presupuesto, la lectura del multiplicador de calidad a partir de tus propios gastos, los enganches en ProjectEbonhold (`PerkUI.Show` / `Hide` / `UpdateSinglePerk` / `ResetSelection`, `OrbService.ClearOffer`, los botones que pliegan las cartas), y el propio panel: dos botones y un deslizador. |
| `EbonOrbWishlist.lua` | El injerto sobre el diario de Ecos. El conjunto de Ecos deseados, el Ctrl+clic que lo alimenta en ambas rejillas, el borde dorado, y el sondeo que solo corre mientras el diario está a la vista. Ningún panel propio: el diario ya dibuja cada Eco, atenúa los nunca descubiertos y filtra por nombre y clase; reconstruir eso al lado sería una segunda copia, peor, de una lista que ya sabes leer. |

La identidad de un Eco aquí es su `spellId` y nada más. La rejilla del diario
recicla sus botones: la misma celda llevaba un id antes de una búsqueda y otro
después. Una marca atada a la celda seguiría a la celda; atada al id, sigue al
Eco.

## 📜 Licencia y créditos

Autor original: **Sanavesa** — fork mantenido por **Siphelis**.

Este proyecto se distribuye bajo una licencia compuesta (base MIT + PolyForm
Noncommercial para las modificaciones) — consulta
[LICENSE](https://github.com/Siphelis/EbonOrbReroll/blob/main/LICENSE)
para los detalles.

---
