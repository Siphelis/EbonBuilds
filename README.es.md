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

- **Builds.** Escribe un plan para cada build: los Ecos que buscas y cuánto quieres cada uno.
- **Estrellas.** Cada Eco recibe de 1 a 3 estrellas para tu clase. Aparecen en las cartas de la tirada, en el diario de Ecos del juego y en tus builds guardados.
- **Automatización.** En cada tirada, el addon puede elegir, desterrar, relanzar o congelar por ti, según tu build activo.
- **Relanzamiento con Orbe y caza.** En una tirada de Orbe, el addon puede relanzar con un Orbe. También puede repetirlo hasta que salga un Eco que hayas marcado.
- **Compartir.** Comparte tus builds con otros jugadores, importa los suyos y aprovecha lo que la comunidad conserva y destierra.
- **Seguimiento de partidas.** Consulta estadísticas por build, los Ecos que aún te faltan y un diario de cada decisión.

## 📦 Instalación

1. [**EbonBuilds**](https://github.com/Siphelis/EbonBuilds/releases/latest) — descarga la última versión.
2. Descomprime la carpeta `EbonBuilds` en `Interface/AddOns/`.
   Instala [**EbonAPI**](https://github.com/Siphelis/EbonAPI/releases/latest) de la misma forma si aún no está. [EbonAPI](https://github.com/Siphelis/EbonAPI) es común a los addons de Ebonhold. [EbonBuilds](https://github.com/Siphelis/EbonBuilds) no arranca sin él.
3. En la pantalla de selección de addons, comprueba que [**EbonBuilds**](https://github.com/Siphelis/EbonBuilds) y [**EbonAPI**](https://github.com/Siphelis/EbonAPI) están marcados.

El addon usa el idioma de tu juego: inglés, francés, alemán o español. Para cambiarlo, escribe `/eapi lang` seguido de `enUS`, `frFR`, `deDE` o `esES`.

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

- **Builds guardados**: los builds que guarda el propio juego, con sus Ecos y sus estrellas.
- **Builds públicos**: los builds que comparten otros jugadores.
- **Importar build**: añade un build a partir de un texto.
- **+ Nuevo build**: crea un build.
- Tus builds. Haz clic en uno para abrirlo. Pasa a ser tu build activo para este personaje. La automatización sigue al build activo.

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
| **Resumen** | Clase, espec., título, descripción, Ecos bloqueados y el interruptor **Hacer público**. |
| **Ecos** | Un peso para cada Eco. |
| **Bonus** | Puntos extra por rareza, por familia y para los Ecos nuevos. |
| **Automatización** | Destierros, protecciones y umbrales. Consulta [Automatización](#-automatización). |

**Guardar** conserva tus cambios. **Cancelar** los descarta. **Exportar** (abajo a la izquierda) da el build en forma de texto.

Los **Ecos bloqueados** son los Ecos permanentes que busca tu build. Hay 6 ranuras. Haz clic en una ranura para elegir un Eco. Haz clic derecho para vaciarla.

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
3. En **Builds guardados**, bajo cada Eco.

### Cómo se calcula la nota

1. Cada Eco parte de su rareza. Cuanto más raro, más alto parte.
2. Después, el addon lee los builds de tu clase: los tuyos, los que has importado y los recibidos de otros jugadores. Cuantos más builds conservan un Eco, más sube.
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
2. Si la comunidad no conoce ninguno de los Ecos ofrecidos, el addon usa tus pesos en esa tirada.

Con **Pesos manuales**, los umbrales son porcentajes del **Pico**: la mejor nota posible para tu clase con tus bonus.

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
2. Haz **Ctrl+clic** en los Ecos que quieres. Un borde dorado los marca. Otro Ctrl+clic quita uno. Funciona en las dos listas: el catálogo y los Ecos de tu partida.
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

### Builds públicos

1. Abre el build en el editor. En la pestaña **Resumen**, haz clic en **Hacer público** y luego en **Guardar**.
2. Juega un personaje del nivel 1 al 80 con este build activo. El build queda **Validado**.
3. Un build público y validado se envía a otros jugadores automáticamente.

Modificar un build le quita la validación. Vuelve a jugar para validarlo.

Todo lo que contiene un build público se comparte: pesos, bonus, ajustes de automatización, lista de destierro y descripción.

Para explorar los builds de otros:

1. Haz clic en **Builds públicos**. La lista se abre con tu clase. Filtra por clase y espec.
2. Haz clic en **Importar** para copiar un build a tu lista. La copia es privada y se abre enseguida.
3. **Actualizar** aparece cuando el autor ha publicado una versión más reciente de un build que importaste.
4. **Recargar** pide sus builds a otros jugadores. Hay una espera de 30 segundos.

Si modificas un build que viene de otro jugador, pasa a ser tuyo. El autor pasa a ser tú y se quita la validación.

### Importar y exportar

- **Exportar** (abajo a la izquierda del editor) muestra un texto. Cópialo y dáselo a un amigo.
- **Importar build** (columna de la izquierda) acepta ese texto. También acepta una composición **EBH1** copiada de la ventana de Ecos del juego. Una composición EBH1 no crea un build. Solo se suma a la nota de la comunidad.

## 📊 Sigue tus partidas

Abre un build. Su página tiene cuatro pestañas.

- **Resumen**: título, autor, espec., fecha, estado (público o privado, validado o no), Ecos bloqueados y descripción.
- **Estadísticas**: Ecos vistos, partidas terminadas (nivel 80 alcanzado), partidas reiniciadas, elecciones, relanzamientos, destierros y congelaciones usados, y el reparto de tus elecciones por rareza.
- **Faltan**: los Ecos de la clase del build que aún no tienes y que puedes conseguir a tu nivel. Cada línea indica dónde encontrar el Eco. Los Ecos bloqueados del build van primero.
- **Diario**: una tarjeta por partida. Haz clic en una tarjeta para ver cada decisión: hora, acción, Ecos ofrecidos con su nota, y tus destierros, relanzamientos y congelaciones restantes. **Exportar** da la partida en forma de texto. **X** borra una partida. **Borrar todo** borra todas las partidas.

Las estadísticas y el diario registran las acciones de la automatización.

Una partida termina cuando tu personaje vuelve al nivel 1. Las 25 últimas partidas conservan cada decisión. Las más antiguas conservan un resumen. El addon guarda 200 partidas como máximo.

## 🔧 Ajustes y comandos

- `/ebb` o `/ebonbuilds`: abre o cierra la ventana. `/ebb help` muestra el comando.
- Botón del minimapa: haz clic para abrir la ventana. Arrástralo para moverlo.
- Icono de engranaje arriba a la derecha de la ventana: los ajustes.
  - **Retraso de acción** (de 0,1 a 3 segundos, 2 por defecto): la espera antes de que la automatización actúe. Valores muy bajos pueden causar problemas al addon.
  - **Duración del aviso** (de 0,1 a 3 segundos, 3 por defecto): cuánto tiempo se queda visible el aviso.
- `/eapi lang`: cambia el idioma del addon.

## 📜 Licencia y créditos

Autor original: **Sanavesa** — fork mantenido por **Siphelis**.

Este proyecto se distribuye bajo una licencia compuesta (base MIT + PolyForm
Noncommercial para las modificaciones) — consulta
[LICENSE](https://github.com/Siphelis/EbonBuilds/blob/main/LICENSE)
para los detalles.

---
