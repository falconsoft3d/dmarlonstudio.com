import type { Lang } from "@/lib/i18n";

/**
 * La página de cada demo (/demos/<ejemplo>): qué es y cómo funciona en tres
 * pasos, cada uno con su captura (public/demos/<idioma>/<ejemplo>-<n>.jpg).
 */
export type GuideStep = { title: string; text: string };
export type DemoGuide = { intro: string; steps: [GuideStep, GuideStep, GuideStep] };

const es: Record<string, DemoGuide> = {
  calculator: {
    intro:
      "La primera aplicación que se hace con el estudio: una ventana con botones dibujada en el Diseñador y un poco de Python. Cada botón tiene su evento y el estado de la cuenta vive en la clase de la ventana.",
    steps: [
      { title: "Escriba la operación", text: "Pulse los botones o use el teclado. Cada botón llama a su evento (Btn7_click, BtnMul_click…) y la pantalla muestra lo que va escribiendo." },
      { title: "Obtenga el resultado", text: "El botón = hace la cuenta con decimales exactos (Decimal de Python), así que 0,1 + 0,2 da 0,3 y no 0,30000000000000004." },
      { title: "Los errores no cierran nada", text: "Dividir entre cero muestra «Error» en la pantalla; la siguiente tecla empieza una cuenta nueva. Así se tratan los fallos en una aplicación de verdad." },
    ],
  },
  notepad: {
    intro:
      "Un bloc de notas clásico: menú Archivo y Edición con sus atajos, los diálogos del sistema para abrir y guardar y una barra de estado que sigue al cursor.",
    steps: [
      { title: "Abra un texto", text: "Archivo → Abrir usa el diálogo de su sistema. El nombre del archivo pasa al título de la ventana y a la barra de estado." },
      { title: "Escriba con la posición a la vista", text: "La barra de estado muestra la línea, la columna y el número de caracteres, y se actualiza con cada tecla y cada clic." },
      { title: "Nada se pierde sin avisar", text: "Mientras haya cambios sin guardar, el título lleva un asterisco; al cerrar o abrir otro archivo, el programa pregunta antes de descartarlos." },
    ],
  },
  pdf_editor: {
    intro:
      "Un editor de PDF hecho con un paquete de pip (pypdf) dentro de la aplicación: ordenar, girar, unir y dividir páginas, poner un sello, editar los datos del documento y protegerlo con contraseña.",
    steps: [
      { title: "Abra un PDF", text: "La lista muestra cada página con su tamaño, giro y sus primeras palabras; a la derecha, el texto completo de la página elegida." },
      { title: "Gire, mueva o borre páginas", text: "Los botones de la barra actúan sobre las páginas elegidas. Todo queda en memoria (con Deshacer) hasta que pulsa Guardar." },
      { title: "Datos, sellos y contraseña", text: "Elija varias páginas para extraerlas a otro PDF o dividirlas, ponga un sello de texto, cambie el título y el autor, y proteja el documento con contraseña." },
    ],
  },
  disk_usage: {
    intro:
      "Un analizador de disco con un mapa al estilo de WinDirStat: cada rectángulo es un archivo, tan grande como lo que ocupa y del color de su tipo. Para encontrar en segundos qué llena el disco.",
    steps: [
      { title: "Analice una carpeta", text: "El análisis va en segundo plano (la ventana no se congela) y termina con el árbol de carpetas a la izquierda y el mapa a la derecha, con la leyenda por tipos." },
      { title: "Elija en el árbol o en el mapa", text: "Lo que elige en un lado se marca en el otro. Doble clic en una carpeta del mapa para entrar en ella; «Subir» vuelve atrás." },
      { title: "Los más grandes, a mano", text: "La pestaña «Archivos más grandes» lista los cien que más ocupan. Desde ahí se ven en el Finder o el Explorador o se mandan a la Papelera, siempre preguntando antes." },
    ],
  },
  port_scanner: {
    intro:
      "Un escáner de puertos TCP hecho solo con la biblioteca estándar de Python: muchas conexiones en paralelo, la respuesta de cada servicio y exportación a CSV. Para revisar sus propios equipos.",
    steps: [
      { title: "Lance el análisis", text: "Elija el equipo y los puertos (comunes, del 1 al 1024, todos o una lista). El progreso, los abiertos y el tiempo se ven mientras se escanea, sin bloquear la ventana." },
      { title: "Lea lo que responde cada servicio", text: "Cada puerto abierto muestra su servicio y, si contesta, su cabecera: un servidor web, de correo… Así se sabe qué hay detrás de cada puerto." },
      { title: "Vea también los cerrados", text: "Active «Mostrar también los cerrados» para ver el resultado completo y expórtelo a CSV para guardarlo o compararlo después." },
    ],
  },
  investor: {
    intro:
      "Un simulador de bolsa con empresas ficticias y precios que cambian cada segundo: compre, venda y vea su cartera ganar o perder. Datos inventados, sin riesgo.",
    steps: [
      { title: "Siga el mercado", text: "La tabla se actualiza cada segundo con el precio y la variación de cada valor; al elegir uno, el gráfico muestra sus últimos precios." },
      { title: "Compre y forme su cartera", text: "Elija el valor y la cantidad y pulse Comprar (con su comisión). Arriba, el efectivo, el valor de las acciones, el patrimonio y la ganancia o pérdida." },
      { title: "Venda y revise sus órdenes", text: "Cada venta queda en la pestaña Órdenes con su resultado. La cartera se guarda en su equipo y sigue ahí la próxima vez que abra la demo." },
    ],
  },
  pos: {
    intro:
      "Un punto de venta al estilo del de Odoo, con imágenes de los productos, que funciona solo o conectado a su Odoo: baja los productos y sus precios y envía los pedidos a Ventas.",
    steps: [
      { title: "Haga el pedido", text: "Pulse los productos para añadirlos; con el teclado cambia la cantidad, el descuento o el precio de la línea elegida, como en el TPV de Odoo." },
      { title: "Cobre", text: "Elija efectivo o tarjeta y marque lo que entrega el cliente: el programa calcula el cambio o lo que falta." },
      { title: "Entregue el ticket", text: "Al validar, la venta se guarda (en SQLite y, si está conectado, en Odoo) y sale el ticket con el IVA desglosado." },
    ],
  },
  agenda: {
    intro: "Una agenda de contactos y citas guardada en una base de datos SQLite, sin instalar nada: pestañas, tablas, búsqueda y formularios.",
    steps: [
      { title: "Sus contactos", text: "La tabla muestra nombre, teléfono y correo; al elegir uno, sus datos pasan al formulario para cambiarlos o borrarlos." },
      { title: "Sus citas", text: "En la otra pestaña, las citas con fecha, hora y contacto; la barra de estado cuenta las próximas y las de hoy." },
      { title: "Busque al vuelo", text: "Escriba en Buscar y la tabla se filtra con cada letra, por nombre, teléfono o correo." },
    ],
  },
  currency: {
    intro: "Un conversor de monedas con los tipos de cambio reales del Banco Central Europeo, descargados sin congelar la ventana y guardados para cuando no haya conexión.",
    steps: [
      { title: "Convierta al escribir", text: "Escriba el importe y el resultado aparece al momento, con el tipo de cambio debajo." },
      { title: "Cambie de monedas", text: "Elija cualquier par de monedas del BCE o pulse ⇄ para darles la vuelta." },
      { title: "Siempre sabe de cuándo son", text: "La barra de estado dice la fecha de los tipos. Sin conexión usa los últimos descargados y lo avisa." },
    ],
  },
  file_renamer: {
    intro: "Un renombrador de archivos por lotes: reglas encadenadas, vista previa en vivo, conflictos marcados antes de tocar nada y deshacer.",
    steps: [
      { title: "Elija la carpeta", text: "La lista muestra los archivos con su nombre actual; puede incluir subcarpetas y filtrar por patrones como *.jpg." },
      { title: "Escriba las reglas", text: "Buscar y reemplazar, prefijo y sufijo, numeración, mayúsculas y extensión. La columna «Nombre nuevo» cambia con cada tecla." },
      { title: "Los conflictos, antes de aplicar", text: "Si dos archivos acabarían con el mismo nombre, o el nombre no vale en Windows, se marcan en rojo y Aplicar se desactiva. Nunca se borra nada y Deshacer lo devuelve todo." },
    ],
  },
  mp3_player: {
    intro: "Un reproductor de música al estilo de los clásicos: reloj digital, analizador de espectro, título que se desplaza y lista de reproducción, todo dibujado a mano en lienzos.",
    steps: [
      { title: "Reproduzca su lista", text: "Añada archivos o una carpeta: el programa lee las etiquetas ID3 y la cabecera de cada MP3 (título, artista, duración, kbps y kHz)." },
      { title: "Aleatorio, repetir y tiempo restante", text: "Los botones con luz encienden el orden aleatorio y la repetición; un clic en el reloj cambia entre el tiempo que lleva y el que queda." },
      { title: "Ordene y guarde la lista", text: "Ordene por título, artista o archivo y guarde la lista en M3U. El programa recuerda la lista, el volumen y la pista entre sesiones." },
    ],
  },
  train_monitor: {
    intro:
      "Los trenes de Cercanías y Rodalies en directo con los datos abiertos de Renfe: dónde está cada tren, cuándo dos se acercan demasiado y la malla de circulación de la línea. Una demo educativa: no es un sistema de seguridad.",
    steps: [
      { title: "La malla de circulación", text: "Estaciones en vertical, tiempo en horizontal: cada línea es un tren. Los tramos en naranja o rojo son avisos y alertas de proximidad. Esta captura es la simulación, que funciona sin conexión." },
      { title: "Cambie de línea", text: "Elija núcleo y línea; las alertas se listan con la hora, los trenes, la distancia y el tiempo que los separa. Los umbrales se cambian arriba." },
      { title: "Siga un tren en directo", text: "Con los datos en directo de Renfe (aquí, decenas de trenes a la vez), elija un tren en la tabla o en el mapa para ver su próxima parada, su retraso real y su velocidad estimada." },
    ],
  },
  pascal_odoo: {
    intro:
      "Una aplicación nativa en Object Pascal (Lazarus) para trabajar con Odoo 8 a 20 con y sin conexión: panel de indicadores, clientes, proveedores y productos, ventas y compras de principio a fin (presupuesto, confirmación, factura y pago), un punto de venta que crea en Odoo el pedido, la entrega y la factura y, con BIM 2.0, obras y presupuestos por conceptos.",
    steps: [
      { title: "El panel de ventas", text: "Indicadores del mes, ventas por mes, pedidos por estado y mejores clientes, dibujados a partir de los datos descargados de Odoo." },
      { title: "Venda y compre sin conexión", text: "Cree productos, clientes y proveedores; haga un presupuesto o una solicitud de compra, confírmelo, factúrelo y registre el pago (banco o efectivo) aunque no haya red. Todo queda pendiente y, al volver la conexión, Odoo hace los mismos pasos con una referencia única, sin duplicados aunque se corte a medias (probado en Odoo 18, 19 y 20)." },
      { title: "Presupuestos de obra (BIM 2.0)", text: "Con el módulo BIM 2.0 en Odoo, la página Obras BIM es su árbol de conceptos: capítulos, partidas y recursos con cantidad y precio, los importes como en BIM y sus atajos (N, Mayús + N, Supr, U). Se hace sin conexión y UPD lo sube a Odoo." },
    ],
  },
  cpp_explorer: {
    intro:
      "Un explorador de archivos nativo hecho en C++ con FLTK y diseñado en el estudio, con el aspecto azulado de los exploradores de la época de Aero. Árbol de carpetas, vistas de iconos, lista y detalles, pestañas, marcadores, copiar y pegar con el Finder o el Explorador de Windows, Papelera y tema claro u oscuro. Todos sus iconos se dibujan en código.",
    steps: [
      { title: "Navegue por sus carpetas", text: "El árbol de la izquierda se carga al abrir cada rama; la barra de direcciones muestra la ruta en «migas» (la flecha de cada una abre sus subcarpetas) y se vuelve editable con un clic. Ordene la vista de detalles por cualquier columna." },
      { title: "Marcadores y pestañas", text: "Ctrl+D (⌘D en el Mac) añade la carpeta a los marcadores, con su nombre, su carpeta, una descripción y si sale en la barra. Cada pestaña recuerda su carpeta y su historial de Atrás y Adelante." },
      { title: "Copie entre ventanas, en claro u oscuro", text: "Copiar, cortar y pegar usan el portapapeles de archivos del sistema: funcionan entre dos exploradores y con el Finder o el Explorador de Windows. Las copias grandes van en segundo plano, y eliminar siempre pregunta y manda a la Papelera. Ver → Tema elige claro, oscuro o el del sistema." },
    ],
  },
  cpp_racing: {
    intro:
      "Un juego de carreras de motos hecho en C++ con FLTK y diseñado en el estudio: la ventana, el menú y el reloj del juego salen del Diseñador; la pista en pseudo-3D (como en los arcades), las motos, el paisaje y el cuadro de mandos se dibujan en el código, sin una sola imagen. Siete rivales, tres vueltas y su récord.",
    steps: [
      { title: "Salga cuando se apaguen las luces", text: "Sale sexto en la parrilla. Se encienden cinco luces rojas; cuando se apagan, ¡ya! Mantenga ↑ (o W) para acelerar y gire con ← → (o A D). La marcha, la velocidad, las revoluciones y el desgaste de los neumáticos se ven abajo a la derecha." },
      { title: "Frene antes de las curvas", text: "En las curvas cerradas la moto se abre hacia fuera: frene con ↓ antes de entrar y trace por dentro. Fuera de la pista se pierde velocidad y contra un árbol se cae. Arriba a la izquierda, su posición y la diferencia en segundos con el de delante y el de detrás; abajo, el minimapa." },
      { title: "Clasificación y récord", text: "Al cruzar la meta en la última vuelta sale la clasificación final con los tiempos y la mejor vuelta de cada uno. Su récord de vuelta se guarda. En el menú Juego elija 1, 3 o 5 vueltas y la dificultad; Intro empieza otra carrera." },
    ],
  },
  pascal_malecon: {
    intro:
      "Una aventura gráfica de investigación en La Habana de 2026, hecha en Object Pascal con Lazarus y diseñada en el estudio, con el aspecto de los juegos VGA de MS-DOS: una pantalla de 360×220 píxeles y 256 colores que se dibuja entera en código (escenas, retratos y letras). Usted es Mikel, ex-perito judicial, y busca a un mediador desaparecido.",
    steps: [
      { title: "Investigue en pleno apagón", text: "Hable con el pescador, la muchacha del móvil o el inspector Valdés, examine cada lugar y viaje por La Habana con la lista de la izquierda (o las teclas 1–6). Examinar a oscuras gasta la linterna: búsquese pilas. Para entrar al puerto, El Socio quiere dos baterías." },
      { title: "Entre al puerto sin que le vean", text: "Cada búsqueda en la zona de carga y en el contenedor hace ruido: la barra de Alerta sube y, si llega al final, los guardias le llevan a la garita. «Esperar en la sombra» la baja. Busque la memoria USB entre los sacos de café y el listado en papel térmico." },
      { title: "Descifre la clave y decida", text: "En el taller de Yari hay que adivinar el nombre en clave de quien recibe en la Habana Vieja: las coordenadas del listado y lo que le cuentan dan la respuesta. Cada fallo cuesta señal de la red. Al final, en Miramar, usted elige uno de los tres finales." },
    ],
  },
  domino: {
    intro:
      "Dominó cubano de doble 9 hecho en Python con tkinter y diseñado en el estudio: una mesa de cuatro con usted y su compañero (Yuniel, enfrente) contra Mayelín y Osmany, que juega la computadora. Las fichas, la mesa y la cadena se dibujan en un lienzo.",
    steps: [
      { title: "Su mano y la salida", text: "Cada uno tiene 10 fichas; las 15 que sobran no se juegan. La primera mano la abre quien tenga el doble más alto. Cuando le toca, las fichas que puede jugar se iluminan: haga clic en una. Si no lleva, pasa solo." },
      { title: "Elija la punta", text: "Si una ficha cabe por las dos puntas, aparecen dos flechas doradas: haga clic en la que quiera. La cadena gira como una serpiente al llegar al borde de la mesa, y los dobles van atravesados." },
      { title: "Dominó o tranque", text: "Quien se queda sin fichas gana la mano para su pareja, que se anota los tantos de todas las fichas que quedan. Si nadie puede jugar, gana quien tenga menos tantos. La partida es a 100 (o a 200, en el menú Juego); en Ver puede mirar las fichas de todos." },
    ],
  },
  flutter_store: {
    intro: "Una tienda móvil hecha con el editor de pantallas de Flutter: login, catálogo, carrito y pago, con la lógica en Dart. La misma app funciona en Android, iPhone y la web.",
    steps: [
      { title: "Entre", text: "La pantalla de login comprueba el correo y la contraseña (pruebe con demo@tienda.com y 1234)." },
      { title: "Busque en el catálogo", text: "Filtre por categoría o busque por nombre; cada producto lleva su icono, su precio y su botón para el carrito." },
      { title: "Llene el carrito y pague", text: "Cada producto tiene su botón para el carrito; el carrito suma las líneas, calcula el total y, al pagar, la app confirma el pedido." },
    ],
  },
  flutter_shipping: {
    intro: "Una app de envíos: resumen por estado, lista con insignias, detalle con su seguimiento y alta de envíos nuevos. Hecha con pantallas de Flutter.",
    steps: [
      { title: "Los envíos por estado", text: "Arriba, cuántos hay pendientes, en camino y entregados; debajo, la lista con el cliente, la dirección y el estado de cada envío." },
      { title: "El detalle de un envío", text: "Toque un envío para ver su pantalla de detalle, que recibe los datos de la lista, con su seguimiento paso a paso." },
      { title: "Un envío nuevo", text: "El botón + abre el formulario de alta, con validación de los campos antes de guardar." },
    ],
  },
  flutter_todo: {
    intro: "Una lista de tareas que se guarda en el teléfono (en la web, en el navegador) con un paquete de pub, shared_preferences.",
    steps: [
      { title: "Sus tareas", text: "La lista muestra las pendientes y las hechas, con el contador de pendientes al día." },
      { title: "Añada una tarea", text: "Escríbala y pulse Añadir: aparece al momento y se guarda en el dispositivo." },
      { title: "Filtre", text: "Todas, pendientes o hechas; «Borrar las hechas» limpia la lista de una vez." },
    ],
  },
  html_store: {
    intro: "La tienda generada en HTML, CSS y JavaScript: sin compilar ni instalar nada, se sube tal cual a cualquier hosting. Las mismas pantallas que en Flutter, React y Vue.",
    steps: [
      { title: "Entre", text: "El login con demo@tienda.com y 1234; las pantallas cambian sin recargar, con rutas tras #." },
      { title: "El catálogo", text: "Búsqueda, categorías y productos generados desde el diseño; adaptable a escritorio y móvil." },
      { title: "El carrito", text: "Las líneas, el total y el pago, con la lógica en un app.js normal y corriente." },
    ],
  },
  react_store: {
    intro: "La misma tienda generada como web de React con Vite: componentes de React a partir del diseño y archivos estáticos listos para publicar.",
    steps: [
      { title: "Entre", text: "El login con demo@tienda.com y 1234, como componente de React." },
      { title: "El catálogo", text: "Cada pantalla del diseño es un componente; los datos y la lógica, en JavaScript." },
      { title: "El carrito", text: "El estado de la app vuelve a pintar el carrito y el total en cuanto cambia." },
    ],
  },
  vue_store: {
    intro: "La misma tienda con Vue: cada pantalla del diseño se convierte en un componente .vue con su plantilla, compilado con Vite.",
    steps: [
      { title: "Entre", text: "El login con demo@tienda.com y 1234, con v-model en los campos." },
      { title: "El catálogo", text: "v-for para los productos y v-if para lo que solo se ve a veces, generados desde el diseño." },
      { title: "El carrito", text: "Un diseño, tres tecnologías: compare esta web con la de HTML y la de React." },
    ],
  },
  html_domino: {
    intro: "El dominó doble 9 como web en HTML y JavaScript, hecho con el editor de pantallas: una sola pantalla con un Lienzo. El Lienzo llama a app.dibujar(ctx, w, h) cada vez que la app avisa y pasa los toques a app.tocar(x, y); la partida entera vive en app.js.",
    steps: [
      { title: "Toque una ficha", text: "Usted juega con Yuniel (enfrente) contra Mayelín y Osmany. Cuando le toca, sus fichas que se pueden jugar se iluminan: tóquela. Los rivales juegan solos y quien no lleva, pasa." },
      { title: "Elija la punta", text: "Si una ficha cabe por las dos puntas, aparecen dos flechas doradas: toque la que quiera. La cadena gira al llegar al borde y la mesa se ajusta al tamaño de la ventana." },
      { title: "Dominó o tranque", text: "Al acabar la mano salen las fichas que quedaban y los tantos de cada pareja; la partida es a 100. Arriba, el botón de recargar empieza otra y el del ojo enseña las fichas de todos." },
    ],
  },
};

const en: Record<string, DemoGuide> = {
  calculator: {
    intro:
      "The first app you make with the studio: a window with buttons drawn in the Designer and a little Python. Each button has its event and the calculation state lives in the window's class.",
    steps: [
      { title: "Type the operation", text: "Press the buttons or use the keyboard. Each button calls its event (Btn7_click, BtnMul_click…) and the display shows what you type." },
      { title: "Get the result", text: "The = button calculates with exact decimals (Python's Decimal), so 0.1 + 0.2 gives 0.3, not 0.30000000000000004." },
      { title: "Errors close nothing", text: "Dividing by zero shows “Error” on the display; the next key starts a new calculation. That is how a real app handles failures." },
    ],
  },
  notepad: {
    intro: "A classic notepad: File and Edit menus with shortcuts, the system's open and save dialogs and a status bar that follows the cursor.",
    steps: [
      { title: "Open a text", text: "File → Open uses your system's dialog. The file name goes to the window title and the status bar." },
      { title: "Write with the position in view", text: "The status bar shows the line, column and character count, updated with every key and click." },
      { title: "Nothing is lost without warning", text: "While there are unsaved changes the title has an asterisk; when closing or opening another file the program asks before discarding them." },
    ],
  },
  pdf_editor: {
    intro: "A PDF editor made with a pip package (pypdf) inside the app: reorder, rotate, merge and split pages, add a stamp, edit the document details and protect it with a password.",
    steps: [
      { title: "Open a PDF", text: "The list shows each page with its size, rotation and first words; on the right, the full text of the selected page." },
      { title: "Rotate, move or delete pages", text: "The toolbar acts on the selected pages. Everything stays in memory (with Undo) until you press Save." },
      { title: "Details, stamps and password", text: "Select several pages to extract them to another PDF or split them, add a text stamp, change the title and author, and protect the document with a password." },
    ],
  },
  disk_usage: {
    intro: "A disk analyzer with a WinDirStat-style map: each rectangle is a file, as big as the space it takes and coloured by type. To find in seconds what fills your disk.",
    steps: [
      { title: "Scan a folder", text: "The scan runs in the background (the window never freezes) and ends with the folder tree on the left and the map on the right, with a legend by type." },
      { title: "Pick in the tree or the map", text: "What you select on one side is highlighted on the other. Double-click a folder on the map to zoom in; “Move up” goes back." },
      { title: "The largest, at hand", text: "The “Largest files” tab lists the hundred biggest. From there you can show them in Finder or Explorer or move them to the Trash, always asking first." },
    ],
  },
  port_scanner: {
    intro: "A TCP port scanner made only with Python's standard library: many parallel connections, each service's answer and CSV export. To check your own machines.",
    steps: [
      { title: "Start the scan", text: "Choose the host and the ports (common, 1 to 1024, all or a list). Progress, open ports and time show while it scans, without blocking the window." },
      { title: "Read each service's answer", text: "Each open port shows its service and, if it answers, its banner: a web server, a mail server… so you know what is behind each port." },
      { title: "See the closed ones too", text: "Turn on “Also show closed ports” for the full result and export it to CSV to keep or compare later." },
    ],
  },
  investor: {
    intro: "A stock market simulator with fictional companies and prices changing every second: buy, sell and watch your portfolio win or lose. Made-up data, no risk.",
    steps: [
      { title: "Follow the market", text: "The table updates every second with each stock's price and change; pick one and the chart shows its latest prices." },
      { title: "Buy and build your portfolio", text: "Choose the stock and quantity and press Buy (with its commission). At the top: cash, shares value, net worth and gain or loss." },
      { title: "Sell and review your orders", text: "Each sale goes to the Orders tab with its result. The portfolio is saved on your computer and is still there next time." },
    ],
  },
  pos: {
    intro: "A point of sale in the style of Odoo's, with product pictures, that works on its own or connected to your Odoo: it downloads products and prices and sends the orders to Sales.",
    steps: [
      { title: "Build the order", text: "Tap products to add them; the keypad changes the quantity, discount or price of the selected line, as in Odoo's POS." },
      { title: "Take payment", text: "Choose cash or card and enter what the customer hands over: the program works out the change or what is still due." },
      { title: "Hand over the receipt", text: "On validation the sale is saved (in SQLite and, when connected, in Odoo) and the receipt shows the VAT breakdown." },
    ],
  },
  agenda: {
    intro: "A contacts and appointments book saved in an SQLite database, with nothing to install: tabs, tables, search and forms.",
    steps: [
      { title: "Your contacts", text: "The table shows name, phone and email; pick one and its details fill the form to change or delete them." },
      { title: "Your appointments", text: "On the other tab, appointments with date, time and contact; the status bar counts upcoming ones and today's." },
      { title: "Search as you type", text: "Type in Search and the table filters with every letter, by name, phone or email." },
    ],
  },
  currency: {
    intro: "A currency converter with the European Central Bank's real exchange rates, downloaded without freezing the window and kept for when there is no connection.",
    steps: [
      { title: "Convert as you type", text: "Type the amount and the result appears at once, with the rate underneath." },
      { title: "Change currencies", text: "Pick any pair of ECB currencies or press ⇄ to swap them." },
      { title: "Always know how recent", text: "The status bar shows the date of the rates. Offline it uses the last ones downloaded and says so." },
    ],
  },
  file_renamer: {
    intro: "A batch file renamer: chained rules, live preview, conflicts marked before touching anything, and undo.",
    steps: [
      { title: "Pick the folder", text: "The list shows the files with their current name; include subfolders and filter with patterns like *.jpg." },
      { title: "Write the rules", text: "Find and replace, prefix and suffix, numbering, case and extension. The “New name” column changes with every key." },
      { title: "Conflicts before applying", text: "If two files would end up with the same name, or a name is invalid on Windows, they are marked in red and Apply is disabled. Nothing is ever deleted and Undo restores everything." },
    ],
  },
  mp3_player: {
    intro: "A music player in the style of the classics: digital clock, spectrum analyzer, scrolling title and playlist, all drawn by hand on canvases.",
    steps: [
      { title: "Play your list", text: "Add files or a folder: the program reads the ID3 tags and each MP3's header (title, artist, duration, kbps and kHz)." },
      { title: "Shuffle, repeat and time left", text: "The lit buttons turn shuffle and repeat on; a click on the clock switches between elapsed and remaining time." },
      { title: "Sort and save the list", text: "Sort by title, artist or file and save the list as M3U. The program remembers the list, volume and track between sessions." },
    ],
  },
  train_monitor: {
    intro: "Spain's commuter trains live with Renfe's open data: where each train is, when two get too close, and the line's train graph. An educational demo: not a safety system.",
    steps: [
      { title: "The train graph", text: "Stations vertically, time horizontally: each line is a train. Orange or red stretches are proximity warnings and alerts. This capture is the simulation, which works offline." },
      { title: "Change line", text: "Pick the area and line; alerts are listed with time, trains, distance and the time between them. Thresholds are set at the top." },
      { title: "Follow a train live", text: "With Renfe's live data (here, dozens of trains at once), pick a train in the table or on the map to see its next stop, its real delay and its estimated speed." },
    ],
  },
  pascal_odoo: {
    intro: "A native Object Pascal (Lazarus) app to work with Odoo 8 to 20 online and offline: KPI dashboard, customers, vendors and products, sales and purchases end to end (quotation, confirmation, invoice and payment), a point of sale that creates the order, delivery and invoice in Odoo and, with BIM 2.0, projects and budgets by concepts.",
    steps: [
      { title: "The sales dashboard", text: "Month KPIs, sales by month, orders by status and top customers, drawn from the data downloaded from Odoo." },
      { title: "Sell and buy offline", text: "Create products, customers and vendors; make a quotation or a purchase request, confirm it, invoice it and register the payment (bank or cash) with no network. Everything stays pending and, when the connection is back, Odoo does the same steps with a unique reference, without duplicates even if it stops halfway (tested on Odoo 18, 19 and 20)." },
      { title: "Construction budgets (BIM 2.0)", text: "With the BIM 2.0 module in Odoo, the BIM projects page is its concept tree: chapters, items and resources with quantity and price, amounts worked out as in BIM and its shortcuts (N, Shift + N, Del, U). It works offline and UPD uploads it to Odoo." },
    ],
  },
  cpp_explorer: {
    intro:
      "A native file explorer made in C++ with FLTK and designed in the studio, with the bluish look of the Aero-era explorers. Folder tree, icon, list and details views, tabs, bookmarks, copy and paste with Finder or Windows Explorer, Trash and a light or dark theme. Every icon is drawn in code.",
    steps: [
      { title: "Browse your folders", text: "The tree on the left loads each branch when you open it; the address bar shows the path as breadcrumbs (each arrow opens its subfolders) and becomes editable with a click. Sort the details view by any column." },
      { title: "Bookmarks and tabs", text: "Ctrl+D (⌘D on a Mac) adds the folder to the bookmarks, with its name, folder, a description and whether it shows on the bar. Each tab remembers its folder and its Back and Forward history." },
      { title: "Copy between windows, light or dark", text: "Copy, cut and paste use the system file clipboard: they work between two explorers and with Finder or Windows Explorer. Big copies run in the background, and deleting always asks first and uses the Trash. View → Theme picks light, dark or the system one." },
    ],
  },
  cpp_racing: {
    intro:
      "A motorbike racing game made in C++ with FLTK and designed in the studio: the window, the menu and the game clock come from the Designer; the pseudo-3D track (as in the arcades), the bikes, the scenery and the dashboard are drawn by the code, without a single image. Seven rivals, three laps and your lap record.",
    steps: [
      { title: "Go when the lights go out", text: "You start sixth on the grid. Five red lights come on; when they go out, go! Hold ↑ (or W) to accelerate and steer with ← → (or A D). The gear, the speed, the revs and the tyre wear are shown at the bottom right." },
      { title: "Brake before the bends", text: "In tight bends the bike runs wide: brake with ↓ before turning in and take the inside line. Off the track you lose speed, and hitting a tree means a crash. At the top left, your position and the gap in seconds to the rider ahead and behind; at the bottom, the minimap." },
      { title: "Standings and lap record", text: "When you cross the line on the last lap, the final classification shows everyone's time and best lap. Your lap record is saved. In the Game menu choose 1, 3 or 5 laps and the difficulty; Enter starts another race." },
    ],
  },
  pascal_malecon: {
    intro:
      "A graphic investigation adventure in Havana in 2026, made in Object Pascal with Lazarus and designed in the studio, with the look of the MS-DOS VGA games: a 360×220, 256-colour screen drawn entirely in code (scenes, portraits and letters). You are Mikel, a former court expert, looking for a missing fixer.",
    steps: [
      { title: "Investigate in the blackout", text: "Talk to the fisherman, the girl with the phone or Inspector Valdés, examine every place and travel around Havana with the list on the left (or keys 1–6). Examining in the dark uses up your torch: find batteries. To get into the port, El Socio wants two batteries." },
      { title: "Get into the port unseen", text: "Every search in the cargo yard and the container makes noise: the Alert bar goes up and, if it fills, the guards take you to their hut. «Wait in the shadows» brings it down. Find the USB stick among the coffee sacks and the list on thermal paper." },
      { title: "Crack the key and decide", text: "In Yari's workshop you must guess the code name of whoever receives in Old Havana: the coordinates on the list and what people tell you give the answer. Every miss costs network signal. In the end, in Miramar, you choose one of three endings." },
    ],
  },
  domino: {
    intro:
      "Cuban double-nine dominoes made in Python with tkinter and designed in the studio: a table of four with you and your partner (Yuniel, opposite) against Mayelín and Osmany, played by the computer. The tiles, the table and the line of play are drawn on a canvas.",
    steps: [
      { title: "Your hand and the lead", text: "Everyone has 10 tiles; the 15 left over are not used. The first hand is opened by whoever has the highest double. On your turn, the tiles you can play light up: click one. If you can't play, you pass automatically." },
      { title: "Pick the end", text: "If a tile fits both ends, two golden arrows appear: click the one you want. The line snakes round when it reaches the edge of the table, and doubles are placed crosswise." },
      { title: "Domino or blocked game", text: "Whoever plays all their tiles wins the hand for their partnership, which scores the points of every tile left. If nobody can play, whoever has the fewest points wins. The game is to 100 (or 200, in the Game menu); in View you can see everyone's tiles." },
    ],
  },
  flutter_store: {
    intro: "A mobile shop made with the Flutter screen editor: login, catalog, cart and payment, with the logic in Dart. The same app runs on Android, iPhone and the web.",
    steps: [
      { title: "Sign in", text: "The login screen checks the email and password (try demo@tienda.com and 1234)." },
      { title: "Search the catalog", text: "Filter by category or search by name; each product has its icon, price and cart button." },
      { title: "Fill the cart and pay", text: "Each product has its cart button; the cart adds up the lines, works out the total and, on payment, the app confirms the order." },
    ],
  },
  flutter_shipping: {
    intro: "A shipments app: summary by status, list with badges, detail with tracking and adding new shipments. Made with Flutter screens.",
    steps: [
      { title: "Shipments by status", text: "At the top, how many are pending, on the way and delivered; below, the list with each shipment's customer, address and status." },
      { title: "A shipment's detail", text: "Tap a shipment to open its detail screen, which receives the data from the list, with its step-by-step tracking." },
      { title: "A new shipment", text: "The + button opens the form, which validates the fields before saving." },
    ],
  },
  flutter_todo: {
    intro: "A to-do list saved on the phone (on the web, in the browser) with a pub package, shared_preferences.",
    steps: [
      { title: "Your tasks", text: "The list shows pending and done tasks, with the pending count always up to date." },
      { title: "Add a task", text: "Type it and press Add: it appears at once and is saved on the device." },
      { title: "Filter", text: "All, pending or done; “Clear completed” cleans the list in one go." },
    ],
  },
  html_store: {
    intro: "The shop generated in HTML, CSS and JavaScript: nothing to build or install, upload it as is to any hosting. The same screens as in Flutter, React and Vue.",
    steps: [
      { title: "Sign in", text: "Log in with demo@tienda.com and 1234; screens change without reloading, with routes after #." },
      { title: "The catalog", text: "Search, categories and products generated from the design; responsive on desktop and mobile." },
      { title: "The cart", text: "Lines, total and payment, with the logic in a plain app.js." },
    ],
  },
  react_store: {
    intro: "The same shop generated as a React website with Vite: React components from the design and static files ready to publish.",
    steps: [
      { title: "Sign in", text: "Log in with demo@tienda.com and 1234, as a React component." },
      { title: "The catalog", text: "Each screen of the design is a component; data and logic in JavaScript." },
      { title: "The cart", text: "The app state repaints the cart and total as soon as it changes." },
    ],
  },
  vue_store: {
    intro: "The same shop with Vue: each screen of the design becomes a .vue component with its template, built with Vite.",
    steps: [
      { title: "Sign in", text: "Log in with demo@tienda.com and 1234, with v-model on the fields." },
      { title: "The catalog", text: "v-for for the products and v-if for what shows only sometimes, generated from the design." },
      { title: "The cart", text: "One design, three technologies: compare this site with the HTML and React ones." },
    ],
  },
  html_domino: {
    intro: "Double-nine dominoes as a website in HTML and JavaScript, made with the screen editor: a single screen with a Canvas. The Canvas calls app.dibujar(ctx, w, h) whenever the app notifies and passes the taps to app.tocar(x, y); the whole game lives in app.js.",
    steps: [
      { title: "Tap a tile", text: "You play with Yuniel (opposite) against Mayelín and Osmany. On your turn, the tiles you can play light up: tap one. The rivals play by themselves and whoever can't play passes." },
      { title: "Pick the end", text: "If a tile fits both ends, two golden arrows appear: tap the one you want. The line turns at the edge and the table fits the size of the window." },
      { title: "Domino or blocked game", text: "When the hand ends you see the tiles that were left and each partnership's points; the game is to 100. At the top, the reload button starts another one and the eye shows everyone's tiles." },
    ],
  },
};

export const GUIDES: Record<Lang, Record<string, DemoGuide>> = { es, en };

/** La captura del paso n (1, 2 o 3) de una demo. */
export const stepImage = (seed: string, lang: Lang, n: number) => `/demos/${lang}/${seed}-${n}.jpg`;
