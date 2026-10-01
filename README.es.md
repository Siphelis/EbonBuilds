# 🔮 EbonBuilds

**Planifica tus builds de Ecos, deja que el addon elija tus Ecos y vuelve a tirar las tiradas de Orbe hasta que salga el Eco que quieres.**

[EbonBuilds](https://github.com/Siphelis/EbonBuilds) es un addon para Project Ebonhold. Te ayuda con los Ecos de tus partidas.

[English](README.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Español](README.es.md)

---

## Tabla de contenidos

- [Funciones](#-funciones)
- [Instalación](#-instalación)
- [Inicio rápido](#-inicio-rápido)
- [Builds](#-builds)
- [Estrellas y nota de la comunidad](#-estrellas-y-nota-de-la-comunidad)
- [Automatización](#-automatización)
- [Tirada con Orbes y caza](#-tirada-con-orbes-y-caza)
- [Compartir](#-compartir)
- [Sigue tus partidas](#-sigue-tus-partidas)
- [Ajustes y comandos](#-ajustes-y-comandos)
- [Licencia y créditos](#-licencia-y-créditos)

---

## ✨ Funciones

- **Builds.** Escribe un plan para cada build: los Ecos que buscas y cuánto quieres cada uno. Abre un build desde **Builds guardados** o **Builds de jugadores** para ver todos sus Ecos, como en el diario de Ecos del juego.
- **Estrellas.** Cada Eco recibe de 1 a 3 estrellas para tu clase. Aparecen en las cartas de la tirada, en el diario de Ecos del juego y en la ventana de detalle de un build de tu clase.
- **Automatización.** En cada tirada, el addon puede elegir, desterrar, relanzar o congelar por ti, según tu build activo.
- **Relanzamiento con Orbe y caza.** En una tirada de Orbe, el addon puede relanzar con un Orbe. También puede repetirlo hasta que salga un Eco que hayas marcado.
- **Compartir.** Los builds de tus ranuras de build del juego se comparten automáticamente. Explora los builds de otros jugadores y añade uno de tu clase a tus wishlists. Aprovecha lo que la comunidad conserva y destierra.
- **Seguimiento de partidas.** Consulta estadísticas por build, los Ecos que aún te faltan y un diario de cada decisión.

## 📦 Instalación

1. [**EbonBuilds**](https://github.com/Siphelis/EbonBuilds/releases/latest) — descarga la última versión.
2. Descomprime la carpeta `EbonBuilds` en `Interface/AddOns/`.
   Instala o actualiza [**EbonAPI**](https://github.com/Siphelis/EbonAPI/releases/latest) de la misma forma. [EbonBuilds](https://github.com/Siphelis/EbonBuilds) necesita [EbonAPI](https://github.com/Siphelis/EbonAPI) 2.1.0 o posterior. [EbonAPI](https://github.com/Siphelis/EbonAPI) es común a los addons de Ebonhold. [EbonBuilds](https://github.com/Siphelis/EbonBuilds) no arranca sin él.
3. En la pantalla de selección de addons, comprueba que [**EbonBuilds**](https://github.com/Siphelis/EbonBuilds) y [**EbonAPI**](https://github.com/Siphelis/EbonAPI) están marcados.

El addon usa el idioma de tu juego: inglés, francés, alemán o español. Para cambiarlo, pulsa Esc y haz clic en **EbonAPI**. En la página **General**, elígelo en la lista **Idioma**.

## 🚀 Inicio rápido

1. Escribe `/ebb`, o haz clic en el botón de [EbonBuilds](https://github.com/Siphelis/EbonBuilds) del minimapa. La ventana se abre.
2. Haz clic en **+ Nuevo build**.
3. Elige **Modo asistente** para que te guíen paso a paso, o **Modo experto** para ir directo al editor.
4. Haz clic en **Guardar**. El build pasa a ser tu build activo. Su automatización está activada.
5. Juega. En cada tirada, el addon espera dos segundos, actúa y muestra un aviso con lo que ha hecho.

¿Solo quieres las estrellas, sin automatización? Haz clic en **Automatización: SÍ** en la página del build. El botón pasa a **Automatización: NO**. Las estrellas se quedan.

¿**Builds guardados** está vacío? Abre una vez la ventana de Ecos del juego.

## 📋 Builds

### La ventana

La columna de la izquierda contiene:

- **Builds guardados**: los builds y las wishlists que guarda el propio juego.
- **Builds de jugadores**: los builds que comparten otros jugadores.
- **+ Nuevo build**: crea un build.
- Tus builds. Haz clic en uno para abrirlo. Pasa a ser tu build activo para este personaje. La automatización sigue al build activo.

En **Builds guardados**, cada build es una tarjeta con su número de ranura, su nombre, su número de Ecos y sus Ecos bloqueados. Un **>** verde marca el build activo del juego.

### La ventana de detalle

Haz clic en una tarjeta de **Builds guardados** o de **Builds de jugadores**. Su ventana de detalle se abre junto a la ventana principal. Se cierra con la ventana principal, o cuando sales de la lista.

- El encabezado muestra la clase, el número de Ecos y las familias del build. Cada familia indica su número de Ecos, por ejemplo **Tanque (3)**. Los Ecos sin familia están en **Sin familia**.
- Bajo el encabezado, una fila de ranuras muestra los Ecos bloqueados. Si el jugador no los ha enviado, una línea lo indica. La fila tiene tantas ranuras como has desbloqueado en el juego.
- Después, una cuadrícula muestra todos los Ecos del build, como en el diario de Ecos del juego. Los más raros van primero.

En la cuadrícula:

- Cada Eco tiene una sola casilla, sean cuales sean sus rarezas. Un pequeño disco indica las pilas de cada rareza, hasta tres rarezas.
- Un candado marca un Eco bloqueado. Su nombre aparece en dorado.
- Un libro marca un Eco que necesita un tomo.
- Un halo gira detrás de cada icono, del color de su rareza. Es dorado en un Eco bloqueado.
- En un build de tu clase, la descripción emergente muestra las estrellas del Eco, como en el diario de Ecos del juego.

Para filtrar la cuadrícula:

1. Marca una familia en el encabezado. La cuadrícula solo muestra sus Ecos.
2. Marca más familias para añadir sus Ecos. Un Eco aparece si pertenece a una de ellas.
3. Desmárcalas todas para volver a ver todos los Ecos.

La fila de Ecos bloqueados nunca se filtra. Las familias que has marcado se mantienen cuando abres otro build. Se desmarcan cuando se cierra la ventana.

Para añadir un build de jugador a tus wishlists:

1. Abre un build de tu clase desde **Builds de jugadores**.
2. Haz clic en **Añadir a mi wishlist**, en la parte inferior.
3. Escribe un nombre, o conserva el que se propone.
4. Confirma.

El build se envía al servidor como una wishlist nueva, con sus Ecos y sus Ecos bloqueados. El chat confirma su creación. Después la encuentras entre tus wishlists en el diario de Ecos del juego, y en **Builds guardados**. En un build de otra clase, el botón queda gris: una wishlist es siempre para tu propia clase.

### Modo asistente

El asistente pide:

1. Tus Ecos bloqueados.
2. Un bonus para los Ecos nuevos. Este paso solo aparece si has elegido Poder adaptativo.
3. Tus familias: ninguna, secundaria (+10) o principal (+20).
4. Un bonus para cada rareza.
5. Los Ecos que más importan: **Lo quiero**, **Bueno**, **Aceptable** o **Regular**.
6. Un título y una descripción.

Al final se abre el editor. Revísalo y haz clic en **Guardar**.

### El editor

Haz clic en **Editar** en la página de un build. El editor tiene cuatro pestañas.

| Pestaña | Qué ajustas |
| --- | --- |
| **Resumen** | Clase, espec., título, descripción y Ecos bloqueados. |
| **Ecos** | Un peso para cada Eco. |
| **Bonus** | Puntos extra por rareza, por familia y para los Ecos nuevos. |
| **Automatización** | Destierros, protecciones y umbrales. Consulta [Automatización](#-automatización). |

**Guardar** conserva tus cambios. **Cancelar** los descarta. **Exportar** (abajo a la izquierda) da el build en forma de texto.

Los **Ecos bloqueados** son los Ecos permanentes que busca tu build. Hay tantas ranuras como has desbloqueado en el juego, 6 como máximo. Haz clic en una ranura para elegir un Eco. Haz clic derecho para vaciarla.

La **descripción** puede contener enlaces de Ecos. Haz clic en **+ Enlace de Eco**.

**Pestaña Ecos**

1. Un peso es un número entero, 0 o más. Cuanto más alto, más quieres el Eco.
2. Un solo peso cubre todas las rarezas de un Eco.
3. Junto al peso ves la nota de cada rareza. **Bloqueado** o **Desterrado** sustituye la nota de un Eco que has bloqueado o desterrado.
4. Usa el cuadro de búsqueda, la lista de rarezas y la lista de familias para filtrar.
5. Marca **Todas las clases** para ver los Ecos de otras clases.

**Pestaña Bonus**

- **Bonus de rareza**: puntos extra para cada rareza.
- **Bonus de familia**: puntos extra para cada familia.
- **Bonus de novedad**: puntos extra para un Eco que aún no tienes.
- Cada valor se suma (**+**) o se multiplica (**x**). Haz clic en el botón pequeño junto al número para cambiar. En modo **x**, un valor menor que 1 baja la nota.

## ⭐ Estrellas y nota de la comunidad

### Qué significan las estrellas

- 3 estrellas: imprescindible para tu clase.
- 2 estrellas: punto intermedio.
- 1 estrella: puedes prescindir de él.
- 3 estrellas grises: la mayoría de los jugadores lo destierran.
- Ninguna estrella: tu clase no puede usar este Eco.

### Dónde verlas

1. En el diario de Ecos del juego, pasa el cursor sobre un Eco. La línea **Interés para** tu clase muestra las estrellas. Cuando la comunidad conoce el Eco, una segunda línea **Combina bien con** cita hasta tres Ecos que suelen conservarse con él.
2. En una tirada, bajo el icono de cada carta.
3. Haz clic en una tarjeta de **Builds guardados** o de **Builds de jugadores**. En la ventana de detalle que se abre, pasa el cursor sobre un Eco. La descripción emergente muestra las mismas líneas que en el diario. Solo funciona con un build de tu clase.

### Cómo se calcula la nota

1. Cada Eco parte de su rareza. Cuanto más raro, más alto parte.
2. Después, el addon lee los builds de tu clase: tus **Builds guardados** y los **Builds de jugadores**. Cuantos más builds conservan un Eco, más sube.
3. En las cartas de la tirada y en la descripción emergente, pesan más los builds que se parecen a tu partida actual. Un Eco que encaja con lo que ya tienes sube.
4. Las listas de destierro bajan un Eco. Cuando se conocen las listas de tres jugadores, un Eco desterrado por la mitad de ellos o más recibe estrellas grises. Un Eco desterrado por una quinta parte de ellos o más pierde una estrella.
5. Cada jugador cuenta una vez, tenga los builds que tenga.

Cuantos más jugadores usan el addon, mejor es la nota.

## 🤖 Automatización

La automatización juega tus tiradas por ti. Sigue a tu **build activo**. Cada build tiene su propio interruptor: **Automatización: SÍ** o **Automatización: NO** en la página del build. Un build nuevo empieza con la automatización activada.

La automatización nunca gasta Orbes. Solo usa los destierros, los relanzamientos y las congelaciones que te da el juego.

### Qué hace en cada tirada

Tras una breve espera (2 segundos por defecto), el addon recorre esta lista. Hace la primera acción que se aplique.

1. **Tomar un Eco bloqueado.** Si se ofrece un Eco bloqueado de tu build, el addon lo toma.
2. **Desterrar.** El addon destierra primero un Eco de tu lista de destierro. Después destierra un Eco cuya nota está bajo el umbral de destierro. Necesita un destierro disponible. Omite las familias protegidas, las cartas congeladas y las cartas arrastradas.
3. **Relanzar.** El addon relanza cuando el mejor Eco ofrecido está bajo el umbral de relanzamiento y ningún Eco ofrecido alcanza el umbral de bloqueo. Necesita un relanzamiento disponible.
4. **Congelar.** Cuando dos Ecos ofrecidos superan el umbral de congelación, el addon congela el peor y toma el mejor. Necesita una congelación disponible.
5. **Tomar el mejor.** Si no, el addon toma el Eco con la mejor nota.

Un aviso en la parte superior de la pantalla muestra cada acción. Lista los Ecos ofrecidos con su nota, marca el elegido con **>> <<** y muestra tus destierros, relanzamientos y congelaciones restantes. Haz clic en el aviso para cerrarlo. Deja el ratón encima para mantenerlo abierto.

### La pestaña Automatización

- **Protección contra destierro.** Marca las familias que nunca deben desterrarse.
- **Ecos desterrados.** Los Ecos que se destierran primero, sea cual sea su nota. Haz clic en **Añadir** para añadir uno. Haz clic en un icono para quitarlo. Debajo, elige qué ocurre cuando todos los Ecos ofrecidos están desterrados y no queda ningún destierro: **Mejor nota** o **Al azar**.
- **Origen de la nota.** Elige de dónde vienen las notas:
  - **Matriz común** (por defecto): la nota viene de la comunidad, más tus pesos.
  - **Pesos manuales**: la nota viene solo de tus pesos y tus bonus.

### Los umbrales con la Matriz común

La nota va de -5 (todos rechazan el Eco) a +3 (todos lo conservan). Un Eco ordinario está cerca de +1.

| Umbral | Por defecto | Efecto |
| --- | --- | --- |
| **Desterrar bajo** | -2,00 | Destierra un Eco ofrecido bajo esta nota. |
| **Volver a tirar bajo** | 0,00 | Relanza cuando el mejor Eco ofrecido está bajo esta nota. |
| **Bloqueo de tirada sobre** | 0,00 | Impide relanzar cuando un Eco ofrecido alcanza esta nota. Déjalo en el umbral de relanzamiento o por debajo. |
| **Congelar sobre** | +2,00 | Congela cuando dos Ecos ofrecidos superan esta nota. |
| **Influencia de los pesos** | 1,00 | Lo que tus pesos suman a la nota. Con 1,00, el Eco con tu peso más alto suma 1 punto. |

Dos cosas más que conviene saber:

1. Cada rareza suma un pequeño bonus a la nota. Los Ecos más raros pasan delante cuando las notas están cerca.
2. La **Matriz común** necesita tres builds de tu clase entre tus **Builds guardados** y los **Builds de jugadores**, o las listas de destierro de tres jugadores. Hasta entonces, el addon funciona como con **Pesos manuales**.

Con **Pesos manuales**, los umbrales son porcentajes del **Pico**: la mejor nota posible para tu clase con tus bonus. En este modo, el relanzamiento compara la nota total de los Ecos ofrecidos, no la mejor.

Las estrellas son una vista sencilla de la nota de la comunidad. La automatización usa la nota más fina, de -5 a +3.

## 🔮 Tirada con Orbes y caza

### Cómo funciona

En una tirada de Orbe, el servidor rechaza relanzar, desterrar y congelar. [EbonBuilds](https://github.com/Siphelis/EbonBuilds) añade un panel bajo las cartas. El panel encadena dos acciones que el juego ya permite:

1. Toma una de las cartas ofrecidas. El Eco se concede.
2. Gasta Orbes para olvidar ese Eco. El juego reparte tres cartas nuevas.

Acabas con tres cartas nuevas y menos Orbes. Tienes los mismos Ecos que antes. El servidor comprueba cada paso.

Un punto que conviene saber: entre los dos pasos, posees de verdad el Eco tomado. Si el servidor rechaza el paso 2, te lo quedas. Por eso el addon toma la carta que menos molesta conservar. La descripción emergente la nombra antes de que hagas clic.

### La carta que se toma

1. La carta de menor rareza va primero.
2. Un Eco permanente nunca se toma. El servidor se negaría a olvidarlo.
3. Un Eco con la pila llena nunca se toma. El servidor se negaría a concederlo.
4. Un Eco que estás cazando nunca se toma.
5. La carta garantizada de una ranura de build, las cartas congeladas y las cartas arrastradas van al final. Se guardaron por algo.

### El panel

El panel aparece bajo las cartas solo en una tirada de Orbe.

- **Tirar (Orbe: N)**: un relanzamiento. N es tu número de Orbes. La descripción emergente nombra la carta que se toma y el coste.
- **Cazar (n)**: inicia una caza. n es el número de Ecos que has marcado.
- **Cuadrado de color**: la rareza buscada.
- **Deslizador**: cuántos Orbes puede gastar la caza.

En una tirada de subida de nivel, el botón de relanzar propio del juego se queda como está. Si ninguna carta de la tirada puede olvidarse, el panel desaparece. Un botón atenuado tiene una descripción emergente que dice por qué: sin Orbes, número de Orbes aún no recibido, ningún Eco marcado, autoaceptación activada.

Una tirada cuesta 1 Orbe por defecto. El coste sigue el deslizador de calidad del juego, tal como estaba en tu último gasto de Orbes.

### La caza

1. Abre el diario de Ecos del juego.
2. Haz **Ctrl+clic** en los Ecos que quieres. Un borde dorado los marca. Otro Ctrl+clic quita uno. Funciona en las dos listas: el catálogo y los Ecos de tu partida. La descripción emergente de un Eco te lo recuerda: **Ctrl+clic: cazar este Eco**, o **Ctrl+clic: dejar de cazar** cuando ya está marcado.
3. En las opciones de Ebonhold, desactiva **auto-accept loadout echoes**. La caza no empieza mientras esa opción esté activada.
4. Si la automatización está activada, enciende **Caza** arriba a la derecha del diario. Mientras esté encendido, la automatización te deja las tiradas. Se queda encendido hasta que lo apagues.
5. En una tirada de Orbe, ajusta el deslizador al número de Orbes que aceptas gastar. La etiqueta indica cuántas tiradas paga.
6. Haz clic en **Cazar (n)**. El botón pasa a **Parar (gastado/presupuesto)**. Haz clic para parar en cualquier momento.

Opcional: haz clic en el cuadrado de color para elegir la rareza mínima de cada Eco marcado. Por defecto, un Eco marcado cuenta en todas las rarezas.

La caza se detiene cuando:

- sale un Eco marcado. La lista de Ecos marcados se vacía entonces;
- se agota el presupuesto;
- te quedan pocos Orbes;
- haces clic en **Parar**, o tomas una carta tú mismo;
- ninguna carta de la tirada puede olvidarse, o el servidor rechaza un paso.

El aviso en la parte superior de la pantalla muestra el avance: Orbes gastados, Ecos buscados y cartas de la última tirada. También dice por qué se detuvo la caza.

La caza **nunca toma la carta por ti**. Dos Ecos marcados pueden salir juntos. Tú eliges.

El deslizador llega hasta el número de Orbes que tienes. Un presupuesto inferior al coste de una tirada se rechaza con un mensaje.

La lista de Ecos marcados no se guarda. Está vacía tras una recarga o una nueva conexión.

## 🌐 Compartir

### Builds de jugadores

Los builds de tus ranuras de build del juego se comparten automáticamente con otros jugadores. No hay nada que activar. Ningún ajuste desactiva el uso compartido.

- De cada uno de estos builds, solo se comparten los Ecos: su rareza, sus pilas y cuáles están bloqueados. El nombre del build no se envía.
- De tus builds de la columna de la izquierda, solo se comparten las listas de destierro de tu clase. Cuentan en la nota de la comunidad.
- Tus pesos, bonus, otros ajustes de automatización y descripciones no se comparten.

Para explorar los builds de otros:

1. Haz clic en **Builds de jugadores**. La lista se abre con tu clase. Elige otra clase, o **Todas las clases**.
2. Cada tarjeta muestra la clase, el número de Ecos y los Ecos bloqueados. No se muestra ningún nombre de jugador. Los builds con más Ecos van primero.
3. Haz clic en una tarjeta para abrir su ventana de detalle. En un build de tu clase, **Añadir a mi wishlist** lo envía al servidor como una wishlist nueva.
4. **Recargar** pide sus builds a otros jugadores. Hay una espera de 30 segundos.

La lista se llena sola a medida que otros jugadores comparten sus builds. Los conserva de una sesión a otra.

### Importar y exportar

- **Exportar** (abajo a la izquierda del editor) muestra un texto. Cópialo y dáselo a un amigo.
- La importación vuelve en una próxima actualización.

Si modificas un build que viene de otro jugador, pasa a ser tuyo. El autor pasa a ser tú.

## 📊 Sigue tus partidas

Abre un build. Su página tiene cuatro pestañas.

- **Resumen**: título, autor, espec., fecha, Ecos bloqueados y descripción.
- **Estadísticas**: Ecos vistos, partidas terminadas (nivel 80 alcanzado), partidas reiniciadas, elecciones, relanzamientos, destierros y congelaciones usados, y el reparto de tus elecciones por rareza.
- **Faltan**: los Ecos de la clase del build que aún no tienes y que puedes conseguir a tu nivel. Cada línea indica dónde encontrar el Eco. Los Ecos bloqueados del build van primero.
- **Diario**: una tarjeta por partida. Haz clic en una tarjeta para ver cada decisión: hora, acción, Ecos ofrecidos con su nota, y tus destierros, relanzamientos y congelaciones restantes. **Exportar** da la partida en forma de texto. **X** borra una partida. **Borrar todo** borra todas las partidas.

Las estadísticas y el diario registran las acciones de la automatización.

Una partida termina cuando tu personaje vuelve al nivel 1. Las 25 últimas partidas conservan cada decisión. Las más antiguas conservan un resumen. El addon guarda 200 partidas como máximo.

## 🔧 Ajustes y comandos

- `/ebb` o `/ebonbuilds`: abre o cierra la ventana. `/ebb help` muestra el comando.
- Botón del minimapa: haz clic para abrir la ventana. Arrástralo para moverlo. Sus opciones están en la página **Addons conectados** de la ventana de [EbonAPI](https://github.com/Siphelis/EbonAPI) (pulsa Esc y haz clic en **EbonAPI**):
  - **Botón del minimapa**: **En el minimapa**, **En el botón de EbonAPI** u **Oculto**.
  - **Bloquear su posición**: el botón ya no se mueve.
  - **Restablecer su posición**: el botón vuelve a su lugar inicial.
- Icono de engranaje junto al botón de cerrar de la ventana: los ajustes. Se abren en la página de [EbonBuilds](https://github.com/Siphelis/EbonBuilds) de la ventana de [EbonAPI](https://github.com/Siphelis/EbonAPI).
  - **Retraso de acción** (de 0,1 a 3 segundos, 2 por defecto): la espera antes de que la automatización actúe. Valores muy bajos pueden causar problemas al addon.
  - **Duración del aviso** (de 0,1 a 3 segundos, 3 por defecto): cuánto tiempo se queda visible el aviso.
- Las ventanas del addon siguen el aspecto elegido en la página **Apariencia** de la ventana de [EbonAPI](https://github.com/Siphelis/EbonAPI).
- **Idioma**, en la página **General** de la ventana de [EbonAPI](https://github.com/Siphelis/EbonAPI): cambia el idioma del addon.

## 📜 Licencia y créditos

Autor original: **Sanavesa** — fork mantenido por **Siphelis**.

Este proyecto se distribuye bajo una licencia compuesta (base MIT + PolyForm
Noncommercial para las modificaciones) — consulta
[LICENSE](https://github.com/Siphelis/EbonBuilds/blob/main/LICENSE)
para los detalles.

---
