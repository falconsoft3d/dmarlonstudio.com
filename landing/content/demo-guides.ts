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
  cpp_image_editor: {
    intro:
      "Un editor de imágenes por capas hecho en C++ con FLTK y diseñado en el estudio: la ventana, el menú y el reloj salen del Diseñador; la barra de herramientas, el lienzo con zoom, los paneles Color, Capas e Historial y los diálogos con vista previa se dibujan en el código. Abre con una imagen de ejemplo de tres capas para probarlo todo.",
    steps: [
      { title: "Pinte en capas", text: "Elija el pincel (B) y pinte con el color frontal; [ y ] cambian el tamaño. En el panel Capas cree una capa nueva, ocúltela con el ojo, cambie su opacidad o su modo de fusión (Multiplicar, Trama, Superponer…) y súbala o bájela. El bote (G), el degradado (R), las formas (U) y el texto (T) también pintan." },
      { title: "Recorte, gire y cambie el tamaño", text: "La herramienta Recortar (C) muestra un marco libre o con proporción 1:1, 4:3, 3:2 o 16:9: ajústelo y pulse Intro. En el menú Imagen: Tamaño de imagen (vecino más próximo, bilineal o bicúbica), Tamaño de lienzo con ancla, girar 90°, 180° o un ángulo cualquiera, y voltear." },
      { title: "Ajuste, filtre y guarde", text: "Niveles, Tono y saturación, Brillo y contraste… y los filtros (desenfoque gaussiano, máscara de enfoque, ruido, pixelar, bordes, relieve, viñeta) se ven en la imagen mientras mueve los controles, y solo en la selección si la hay. Cada paso queda en el Historial. Guarde como PNG, JPEG (con su calidad) o BMP para convertir, o en .dmi para conservar las capas." },
    ],
  },
  cpp_flights: {
    intro:
      "Un buscador de vuelos hecho en C++ con FLTK y diseñado en el estudio: la ventana, la barra lateral, el menú y el reloj salen del Diseñador; el análisis, las tablas y las gráficas se dibujan en el código, y las consultas a Travelpayouts (la API de Aviasales) van con curl. Abre con tres rutas de ejemplo para probarlo sin token.",
    steps: [
      { title: "Añada una ruta", text: "A la izquierda escriba el origen y el destino (ciudades o códigos IATA, como MAD o HAV), la ida (un mes, 2026-12, o un día, 2026-12-20) y, si quiere, la vuelta, la moneda y un precio en «Avisar bajo». Pulse «Añadir y analizar»: la ruta queda vigilada y se analiza al abrir la app y cada 30 minutos." },
      { title: "Vea dónde comprar", text: "Arriba, el mejor precio, el precio medio y lo que ha cambiado desde el análisis anterior. Debajo, lo más barato de cada aerolínea con la ida, la vuelta, las escalas y la duración; «Comprar» abre ese vuelo en Aviasales, que compara las agencias y la web de la aerolínea." },
      { title: "El día más barato y los avisos", text: "Las barras dan el precio de cada día del mes (en verde, el más barato; haga clic en un día para comprarlo) y la línea, cómo ha cambiado el mejor precio en cada análisis. Si baja, o pasa por debajo de su precio, la app le avisa. Para precios reales, ponga su token gratuito de Travelpayouts en Ajustes." },
    ],
  },
  cpp_hardware: {
    intro:
      "Un inspector del equipo hecho en C++ con FLTK y diseñado en el estudio: la ventana, la lista de secciones, los botones y el reloj salen del Diseñador; las tarjetas, las gráficas en directo y el informe se dibujan en el código. Lee el equipo con sysctl y system_profiler en macOS y con la API de Win32 y PowerShell en Windows; nada sale del ordenador.",
    steps: [
      { title: "Recorra cada parte del equipo", text: "El resumen da lo principal de un vistazo: el modelo, el sistema, el procesador, la memoria, los gráficos, el disco, la batería y la red, y cada tarjeta lleva a su sección. A la izquierda están el procesador (con sus cachés), el modelo y el firmware, los gráficos y las pantallas, los discos, la red, el audio y los periféricos USB y Bluetooth. Un clic en un dato lo copia." },
      { title: "Mida el uso en directo", text: "Cada segundo se mide el uso del procesador y de cada núcleo (en los chips de Apple, los de eficiencia y los de rendimiento por separado), la memoria por partes (apps, fija, comprimida y caché), el tráfico de red, el espacio de los discos y la batería, con la gráfica del último minuto. Se pausa en Ver → Lecturas en directo." },
      { title: "Guarde el informe en PDF", text: "«Guardar en PDF» crea un documento de varias páginas con todas las secciones y las lecturas del momento, listo para enviar o archivar; también se puede imprimir, guardar como texto o copiar. Los números de serie, el UUID, las direcciones MAC y el usuario van ocultos salvo que active Ver → Mostrar números de serie." },
    ],
  },
  cpp_wifi: {
    intro:
      "Un escáner de la wifi de casa hecho en C++ con FLTK y diseñado en el estudio: la ventana, la lista de secciones, los botones y el reloj salen del Diseñador; el diagnóstico, el mapa de canales y el análisis de la contraseña se dibujan en el código. Lee la wifi con system_profiler en macOS y con netsh en Windows, y prueba el router de casa con sockets.",
    steps: [
      { title: "Mire los canales", text: "Cada red que se oye es una montaña del ancho de su canal y del alto de su señal. Si la suya comparte canal con vecinas fuertes, la app marca en verde el canal más libre para ponerlo en el router (en 2,4 GHz, el 1, el 6 o el 11)." },
      { title: "Compruebe la contraseña", text: "Escriba la de su wifi: la app mira lo larga que es, si es de las más usadas, si lleva el nombre de la red, un año o una secuencia del teclado, y calcula cuánto tardarían en adivinarla con una tarjeta gráfica o con cien. Se olvida al comprobarla: no se guarda ni sale en el informe." },
      { title: "Revise el router", text: "Prueba desde dentro de casa qué deja abierto el router: Telnet y FTP (graves), la página de configuración sin HTTPS y UPnP, además de cuánto tarda en responder y si se pierden paquetes. Todo entra en la nota y en el informe, que se copia o se guarda como texto." },
    ],
  },
  cpp_console: {
    intro:
      "Una consola hecha en C++ con FLTK y diseñada en el estudio: la ventana, el panel de la cola y el menú salen del Diseñador; las pestañas, la terminal (Fl_Terminal con un pseudoterminal de verdad), la cola y las apariencias, del código. Cada pestaña abre su shell con su configuración y le añade una marca: al volver al prompt avisa del código de salida y de la carpeta.",
    steps: [
      { title: "Órdenes guardadas y atajos", text: "Pulse Ctrl+Espacio y sale una lista junto al cursor, filtrada por lo que lleve escrito: sus atajos (un nombre, como conectar-servidor, que ejecuta su orden; uno puede llamar a otro) y sus órdenes guardadas. Intro la escribe en la línea para que la revise." },
      { title: "El historial", text: "Escriba history y pulse Intro: salen las 10 últimas órdenes y elige una con las flechas. La consola las apunta según las avisa la shell, y la primera vez parte del historial de zsh o bash." },
      { title: "La ayuda y las apariencias", text: "Escriba ayuda y la consola escribe en la terminal sus órdenes, sus teclas y sus atajos. Ver cambia entre diez apariencias (de Clásica a Fósforo verde o Papel), y lo ya escrito se repinta con los colores nuevos." },
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
  pascal_docker: {
    intro:
      "Una app de la barra de menús hecha en Object Pascal con Lazarus y diseñada en el estudio: su icono le enseña los contenedores de Docker que tiene en marcha y desde ahí abre sus direcciones o los para, sin abrir Docker Desktop ni la terminal.",
    steps: [
      { title: "Sus contenedores, siempre a mano", text: "Al abrirla aparece un icono en la barra de menús (no en el Dock). Su menú dice cuántos contenedores hay en marcha y los agrupa por proyecto de Compose, con los puertos que publica cada uno; los parados van en su submenú. Se actualiza cada tres segundos." },
      { title: "Abra sus direcciones o párelos", text: "Cada contenedor tiene su submenú: «Abrir http://localhost:8080» abre la web en el navegador (https si es el 443 o el 8443), y Parar, Reiniciar o Iniciar lo hacen sin bloquear el menú. También copia su ID o la orden para entrar en él." },
      { title: "El panel", text: "«Abrir el panel…» muestra la misma lista en una ventana, con los puertos como enlaces y los botones de cada contenedor. Cerrar la ventana no cierra la app: sigue en la barra hasta que elija Salir. Si Docker no está en marcha, se lo dice y le deja abrir Docker Desktop." },
    ],
  },
  pascal_launcher: {
    intro:
      "Una app de la barra de menús hecha en Object Pascal con Lazarus y diseñada en el estudio: déjela en una carpeta con aplicaciones (por ejemplo, junto a estas demos) y su icono le enseña todas, con sus iconos, para abrirlas con un clic.",
    steps: [
      { title: "Las apps de su carpeta, en la barra", text: "Al abrirla aparece un icono en la barra de menús (no en el Dock). Su menú lista las aplicaciones de la carpeta donde está el lanzador y de sus subcarpetas, cada una con su icono y el nombre que enseña el Finder; un clic la abre." },
      { title: "Busque con el teclado", text: "«Buscar…» abre el panel: escriba parte del nombre, sin preocuparse de acentos ni mayúsculas. Primero salen las apps con una palabra que empieza así; las flechas eligen e Intro abre." },
      { title: "Favoritas y recientes", text: "La estrella de cada app en el panel la pone entre las favoritas, que van arriba del menú junto a las seis últimas que abrió. Si copia o borra una app de la carpeta, la lista se pone al día sola." },
    ],
  },
  cpp_webmon: {
    intro:
      "Un monitor de sitios web nativo en C++ con FLTK, diseñado en el estudio: comprueba cada pocos minutos si sus webs contestan y le enseña su estado, su tiempo de respuesta y su historial, desde la ventana o desde la barra de menús.",
    steps: [
      { title: "Añada sus sitios y vea sus puertos", text: "Escriba una dirección (basta con ejemplo.com) y, si quiere, un nombre, y pulse Añadir o Intro. El monitor lo comprueba en el momento y después cada 2 minutos; cambie el intervalo en «Comprobar cada» (de 1 a 30 minutos). «Puertos» prueba los 33 puertos habituales de su servidor y enseña los abiertos; en ámbar, los que no conviene abrir a internet (bases de datos, escritorio remoto…). Escanee solo servidores suyos." },
      { title: "Síganlos desde la barra de menús", text: "Cierre la ventana o pulse «Minimizar a la barra de menús»: la app sale del Dock y queda un globo con cuántos sitios están en línea (un triángulo si alguno falla). Su menú enseña cada sitio con su estado y la próxima comprobación." },
      { title: "Cada sitio, su menú", text: "Desde el submenú de cada sitio lo abre en el navegador, lo comprueba ya, lo pausa o vuelve a la ventana; también ve su disponibilidad y desde cuándo está en línea o caído. Cuando un sitio se cae o vuelve, macOS le avisa." },
    ],
  },
  cpp_clocks: {
    intro:
      "La hora de varios países siempre a la vista, en la barra de menús, hecha en C++ con FLTK y diseñada en el estudio: por defecto España, Argentina, Venezuela, República Dominicana y Cuba, y la puede cambiar.",
    steps: [
      { title: "Su hora y, al lado, la de otro país", text: "La barra de menús enseña su hora (📍) y, al lado, la del país que marque, con su bandera: «📍 17:02   🇨🇺 12:02». El menú del icono enseña todos los relojes con la hora, si es mañana o ayer allí, y la diferencia con la suya; haga clic en un país para ponerlo o quitarlo de la barra." },
      { title: "Elija los países", text: "En la ventana, cada país es una tarjeta con su esfera, que se oscurece de noche, la fecha y la diferencia horaria. Añada otros con la lista de arriba (hay 39), ordénelos con las flechas y quite los que sobren; elija el formato de 24 o de 12 horas." },
      { title: "El horario de verano, solo", text: "La app sabe cuándo cambia la hora en cada país (Europa, Estados Unidos, Cuba, Chile, Australia, Nueva Zelanda) y lo calcula sin depender del sistema. Cierre la ventana y los relojes siguen en la barra hasta que elija Salir." },
    ],
  },
  cpp_recorder: {
    intro:
      "Un grabador de pantalla para hacer vídeos de YouTube, nativo en C++ con FLTK y diseñado en el estudio: elija qué grabar, pulse Grabar y pare desde la barra de menús.",
    steps: [
      { title: "Elija qué grabar", text: "La pantalla entera, una zona de 16:9 de 1920×1080 o 1280×720 centrada en la pantalla, o una vertical de 1080×1920 para Shorts. Marque si quiere el sonido del micrófono, los clics y el cursor, y elija la cuenta atrás y el límite (1 minuto para un Short)." },
      { title: "Grabe sin salir en el vídeo", text: "Al pulsar Grabar, la ventana se esconde y la barra de menús cuenta «Grabando en 3…» y luego el tiempo, «🔴 4:12». Su menú tiene «Detener y guardar» y «Cancelar sin guardar». La primera vez, macOS pide permiso para grabar la pantalla y el micrófono." },
      { title: "Sus vídeos, listos para YouTube", text: "Cada grabación queda en Películas › DMarlon Studio con su miniatura, su duración, su tamaño y su resolución. Ábrala con un clic, muéstrela en el Finder, «Subir a YouTube» abre la página de subida para arrastrarla, y «A la Papelera» la quita." },
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
  next_world: {
    intro: "Una web de Next.js con servidor, hecha con el editor de pantallas: el código de la app termina en una línea // @server y lo que sigue se ejecuta en el servidor. Allí se descargan los aviones de OpenSky, los barcos del AIS del Báltico (Fintraffic) y los trenes de Renfe Cercanías y VR; la web solo llama a server.datos() cada 30 segundos y los dibuja en un Lienzo.",
    steps: [
      { title: "Toque un avión", text: "Toque cualquier punto y sale su ficha: indicativo, país, altitud, velocidad y rumbo. Con la diana, el mapa lo sigue; entre lectura y lectura, cada avión avanza por su rumbo y su velocidad." },
      { title: "Cambie de zona", text: "Mundo, Europa, el mar Báltico o España, y las capas de aviones, barcos y trenes. Al acercarse, el servidor manda un mapa con más detalle (Natural Earth 1:50 millones)." },
      { title: "Busque por nombre", text: "La Lista enseña lo que se ve en el mapa o busca un vuelo, un barco o un tren por su nombre, su línea o su operador. Al tocarlo, vuelve al mapa centrado en él." },
    ],
  },
  next_speed: {
    intro: "Una web de Next.js con servidor, hecha con el editor de pantallas. Después de // @server, el servidor tiene cuatro funciones: eco (para el ping), descarga (devuelve un Response con bytes al azar, que no se pueden comprimir), subida (cuenta los bytes que llegan) e info (su IP y, en Vercel, su ciudad). La app las llama con fetch y serverUrl() y mide el tiempo.",
    steps: [
      { title: "Pulse Empezar", text: "Primero el ping: doce peticiones mínimas, una tras otra; el ping es la mediana y el jitter, cuánto cambia de una a otra. Después, cuatro descargas a la vez durante 10 segundos y tres envíos durante 8." },
      { title: "Mire la aguja", text: "El indicador, dibujado en un Lienzo, marca lo que llega cada segundo: azul la bajada y morado la subida. La escala da más sitio a las velocidades bajas, de 0 a 1000 Mbps." },
      { title: "Para qué le alcanza", text: "Al acabar, la lista dice si su conexión da para videollamadas, vídeo en 4K, juegos en línea o una casa con varias personas, y la medición se guarda en el Historial de su navegador." },
    ],
  },
  next_flights: {
    intro: "El buscador de vuelos de C++ como web de Next.js con servidor, hecha con el editor de pantallas. Las rutas se guardan en el navegador; el servidor, después de // @server, consulta la Data API de Travelpayouts (la de Aviasales) con el token de TRAVELPAYOUTS_TOKEN, que nunca llega a la página, y sin token inventa precios creíbles por la distancia.",
    steps: [
      { title: "Sus rutas", text: "Al abrir, la web analiza cada ruta y vuelve a hacerlo cada 30 minutos mientras está abierta. Cada una dice su mejor precio y cuánto ha cambiado; si baja o pasa por debajo del suyo, avisa (también con una notificación del navegador)." },
      { title: "Una ruta nueva", text: "Origen y destino (una ciudad o su código IATA), la ida (un mes o un día), la vuelta si la hay, la moneda, solo directos y, si quiere, un precio para avisar." },
      { title: "El detalle", text: "El precio de cada día del mes (toque un día para comprarlo en Aviasales), lo más barato de cada aerolínea con la ida, la vuelta, las escalas y la duración, y cómo cambia el mejor precio en cada análisis." },
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
  cpp_image_editor: {
    intro:
      "A layer-based image editor made in C++ with FLTK and designed in the studio: the window, the menu and the clock come from the Designer; the toolbar, the zoomable canvas, the Color, Layers and History panels and the dialogs with live preview are drawn by the code. It opens with a three-layer sample image so you can try everything.",
    steps: [
      { title: "Paint on layers", text: "Pick the brush (B) and paint with the foreground color; [ and ] change the size. In the Layers panel create a new layer, hide it with the eye, change its opacity or its blend mode (Multiply, Screen, Overlay…) and move it up or down. The paint bucket (G), the gradient (R), the shapes (U) and the text (T) paint too." },
      { title: "Crop, rotate and resize", text: "The Crop tool (C) shows a free frame or one with a 1:1, 4:3, 3:2 or 16:9 ratio: adjust it and press Enter. In the Image menu: Image Size (nearest neighbor, bilinear or bicubic), Canvas Size with an anchor, rotate 90°, 180° or any angle, and flip." },
      { title: "Adjust, filter and save", text: "Levels, Hue and Saturation, Brightness and Contrast… and the filters (Gaussian blur, unsharp mask, noise, pixelate, edges, emboss, vignette) show on the image while you move the controls, and only inside the selection if there is one. Every step goes into the History. Save as PNG, JPEG (choosing the quality) or BMP to convert, or as .dmi to keep the layers." },
    ],
  },
  cpp_flights: {
    intro:
      "A flight finder made in C++ with FLTK and designed in the studio: the window, the sidebar, the menu and the clock come from the Designer; the analysis, the tables and the charts are drawn by the code, and the Travelpayouts queries (the Aviasales API) go through curl. It opens with three sample routes so you can try it without a token.",
    steps: [
      { title: "Add a route", text: "On the left enter the origin and the destination (cities or IATA codes, like MAD or HAV), the departure (a month, 2026-12, or a day, 2026-12-20) and, if you like, the return, the currency and a price in \"Alert below\". Press \"Add and check\": the route is watched and checked when the app opens and every 30 minutes." },
      { title: "See where to buy", text: "At the top, the best price, the average price and what has changed since the previous check. Below, the cheapest fare of each airline with the departure, the return, the stops and the duration; \"Buy\" opens that flight in Aviasales, which compares the agencies and the airline's website." },
      { title: "The cheapest day and the alerts", text: "The bars give the price of each day of the month (in green, the cheapest; click a day to buy it) and the line shows how the best price has changed at each check. If it drops, or goes below your price, the app alerts you. For real prices, enter your free Travelpayouts token in Settings." },
    ],
  },
  cpp_hardware: {
    intro:
      "A hardware inspector made in C++ with FLTK and designed in the studio: the window, the list of sections, the buttons and the clock come from the Designer; the cards, the live charts and the report are drawn by the code. It reads the computer with sysctl and system_profiler on macOS and with the Win32 API and PowerShell on Windows; nothing leaves the computer.",
    steps: [
      { title: "Go through each part of the computer", text: "The overview shows the main facts at a glance: the model, the system, the processor, the memory, the graphics, the disk, the battery and the network, and each card takes you to its section. On the left are the processor (with its caches), the model and firmware, the graphics and displays, the disks, the network, the audio and the USB and Bluetooth peripherals. Click a value to copy it." },
      { title: "Measure usage live", text: "Every second it measures the usage of the processor and of each core (on Apple chips, efficiency and performance cores separately), the memory by parts (apps, wired, compressed and cache), the network traffic, the disk space and the battery, with a chart of the last minute. Pause it in View → Live Readings." },
      { title: "Save the report as PDF", text: "\"Save as PDF\" creates a multi-page document with every section and the current readings, ready to send or keep; you can also print it, save it as text or copy it. Serial numbers, the UUID, MAC addresses and the user name stay hidden unless you turn on View → Show Serial Numbers." },
    ],
  },
  cpp_wifi: {
    intro:
      "A home Wi-Fi scanner made in C++ with FLTK and designed in the studio: the window, the section list, the buttons and the timer come from the Designer; the diagnosis, the channel map and the password analysis are drawn in code. It reads the Wi-Fi with system_profiler on macOS and netsh on Windows, and checks your home router with sockets.",
    steps: [
      { title: "Look at the channels", text: "Each network it hears is a hill as wide as its channel and as tall as its signal. If yours shares a channel with strong neighbors, the app marks in green the freest channel to set on the router (on 2.4 GHz, 1, 6 or 11)." },
      { title: "Check the password", text: "Type your Wi-Fi's: the app looks at how long it is, whether it is one of the most used, whether it contains the network's name, a year or a keyboard sequence, and works out how long it would take to guess with one graphics card or a hundred. It is forgotten once checked: it is not saved or included in the report." },
      { title: "Review the router", text: "From inside your home it tests what the router leaves open: Telnet and FTP (serious), the settings page without HTTPS and UPnP, plus how long it takes to answer and whether packets get lost. It all goes into the score and the report, which you can copy or save as text." },
    ],
  },
  cpp_console: {
    intro:
      "A console made in C++ with FLTK and designed in the studio: the window, the queue panel and the menu come from the Designer; the tabs, the terminal (Fl_Terminal with a real pseudo-terminal), the queue and the looks, from the code. Each tab opens your shell with your settings and adds a mark to it: when it returns to the prompt it reports the exit code and the folder.",
    steps: [
      { title: "Saved commands and shortcuts", text: "Press Ctrl+Space and a list appears next to the cursor, filtered by what you have typed: your shortcuts (a name, like connect-server, that runs its command; one can call another) and your saved commands. Enter types it on the line so you can check it." },
      { title: "The history", text: "Type history and press Enter: the last 10 commands appear and you pick one with the arrows. The console records them as the shell reports them, and the first time it starts from the zsh or bash history." },
      { title: "Help and looks", text: "Type help and the console writes its commands, keys and shortcuts in the terminal. View switches between ten looks (from Classic to Green Phosphor or Paper), and what is already written is repainted with the new colors." },
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
  pascal_docker: {
    intro:
      "A menu bar app made in Object Pascal with Lazarus and designed in the studio: its icon shows the Docker containers you have running, and from there it opens their addresses or stops them, without opening Docker Desktop or the terminal.",
    steps: [
      { title: "Your containers, always at hand", text: "When it opens, an icon appears in the menu bar (not in the Dock). Its menu tells you how many containers are running and groups them by Compose project, with the ports each one publishes; the stopped ones go in their own submenu. It refreshes every three seconds." },
      { title: "Open their addresses or stop them", text: "Each container has its submenu: “Open http://localhost:8080” opens the site in the browser (https for 443 or 8443), and Stop, Restart or Start do it without blocking the menu. It also copies the ID or the command to get into it." },
      { title: "The panel", text: "“Open the panel…” shows the same list in a window, with the ports as links and each container's buttons. Closing the window doesn't close the app: it stays in the bar until you choose Quit. If Docker isn't running, it tells you and lets you open Docker Desktop." },
    ],
  },
  pascal_launcher: {
    intro:
      "A menu bar app made in Object Pascal with Lazarus and designed in the studio: leave it in a folder with apps (for example, next to these demos) and its icon shows them all, with their icons, to open with one click.",
    steps: [
      { title: "The apps in its folder, in the bar", text: "When it opens, an icon appears in the menu bar (not in the Dock). Its menu lists the apps in the launcher's folder and its subfolders, each with its icon and the name the Finder shows; one click opens it." },
      { title: "Search from the keyboard", text: "“Search…” opens the panel: type part of the name, accents and case don't matter. Apps with a word starting that way come first; the arrow keys choose and Enter opens." },
      { title: "Favorites and recent", text: "The star on each app in the panel makes it a favorite; favorites go at the top of the menu with the last six you opened. If you copy or delete an app in the folder, the list updates itself." },
    ],
  },
  cpp_webmon: {
    intro:
      "A native website monitor in C++ with FLTK, designed in the studio: it checks every few minutes whether your websites answer and shows their status, response time and history, from the window or from the menu bar.",
    steps: [
      { title: "Add your sites and see their ports", text: "Type an address (example.com is enough) and, if you like, a name, and press Add or Enter. The monitor checks it right away and then every 2 minutes; change the interval in “Check every” (1 to 30 minutes). “Ports” tries the 33 usual ports of its server and shows the open ones; in amber, those that should not be open to the internet (databases, remote desktop…). Only scan your own servers." },
      { title: "Follow them from the menu bar", text: "Close the window or press “Minimize to the menu bar”: the app leaves the Dock and a globe stays with how many sites are up (a triangle if one fails). Its menu shows each site with its status and the next check." },
      { title: "Each site, its menu", text: "From each site's submenu you open it in the browser, check it now, pause it or go back to the window; you also see its uptime and how long it has been up or down. When a site goes down or comes back, macOS lets you know." },
    ],
  },
  cpp_clocks: {
    intro:
      "The time in several countries always in sight, in the menu bar, made in C++ with FLTK and designed in the studio: Spain, Argentina, Venezuela, the Dominican Republic and Cuba by default, and you can change them.",
    steps: [
      { title: "Your time and, next to it, another country's", text: "The menu bar shows your time (📍) and, next to it, the time in the country you mark, with its flag: “📍 17:02   🇨🇺 12:02”. The icon's menu shows every clock with its time, whether it is tomorrow or yesterday there, and the difference with yours; click a country to put it in the bar or take it out." },
      { title: "Choose the countries", text: "In the window, each country is a card with its dial, which goes dark at night, the date and the time difference. Add others with the list above (there are 39), order them with the arrows and remove the ones you don't need; choose 24- or 12-hour format." },
      { title: "Daylight saving, automatically", text: "The app knows when the clocks change in each country (Europe, United States, Cuba, Chile, Australia, New Zealand) and works it out without relying on the system. Close the window and the clocks stay in the bar until you choose Quit." },
    ],
  },
  cpp_recorder: {
    intro:
      "A screen recorder for making YouTube videos, native in C++ with FLTK and designed in the studio: choose what to record, press Record and stop from the menu bar.",
    steps: [
      { title: "Choose what to record", text: "The whole screen, a centered 16:9 area of 1920×1080 or 1280×720, or a vertical 1080×1920 one for Shorts. Tick whether you want microphone sound, clicks and cursor, and choose the countdown and the limit (1 minute for a Short)." },
      { title: "Record without appearing in the video", text: "When you press Record, the window hides and the menu bar counts “Recording in 3…” and then the time, “🔴 4:12”. Its menu has “Stop and save” and “Cancel without saving”. The first time, macOS asks for permission to record the screen and the microphone." },
      { title: "Your videos, ready for YouTube", text: "Each recording stays in Movies › DMarlon Studio with its thumbnail, duration, size and resolution. Open it with a click, show it in the Finder, “Upload to YouTube” opens the upload page to drag it in, and “Move to Trash” removes it." },
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
  next_world: {
    intro: "A Next.js website with a server, made with the screen editor: the app's code ends with a // @server line and what follows runs on the server. There it downloads the planes from OpenSky, the ships from the Baltic AIS (Fintraffic) and the trains from Renfe Cercanías and VR; the website just calls server.datos() every 30 seconds and draws them on a Canvas.",
    steps: [
      { title: "Tap a plane", text: "Tap any point to see its details: callsign, country, altitude, speed and heading. With the target button the map follows it; between readings, each plane moves along its heading at its speed." },
      { title: "Change the area", text: "World, Europe, the Baltic Sea or Spain, and the planes, ships and trains layers. When you zoom in, the server sends a more detailed map (Natural Earth 1:50 million)." },
      { title: "Search by name", text: "The List shows what is on the map or finds a flight, a ship or a train by its name, its line or its operator. Tap it to go back to the map centered on it." },
    ],
  },
  next_speed: {
    intro: "A Next.js website with a server, made with the screen editor. After // @server, the server has four functions: eco (for the ping), descarga (returns a Response with random bytes that can't be compressed), subida (counts the bytes that arrive) and info (your IP and, on Vercel, your city). The app calls them with fetch and serverUrl() and measures the time.",
    steps: [
      { title: "Press Start", text: "First the ping: twelve minimal requests, one after another; the ping is the median and the jitter, how much it changes from one to the next. Then four downloads at once for 10 seconds and three uploads for 8." },
      { title: "Watch the needle", text: "The gauge, drawn on a Canvas, shows what arrives each second: blue for the download and purple for the upload. The scale gives more room to low speeds, from 0 to 1000 Mbps." },
      { title: "What it is good enough for", text: "When it ends, the list tells you whether your connection is enough for video calls, 4K video, online games or a household with several people, and the measurement is saved in your browser's History." },
    ],
  },
  next_flights: {
    intro: "The C++ flight finder as a Next.js website with a server, made with the screen editor. Routes are saved in the browser; the server, after // @server, queries the Travelpayouts Data API (the Aviasales one) with the TRAVELPAYOUTS_TOKEN token, which never reaches the page, and without a token it makes up believable prices from the distance.",
    steps: [
      { title: "Your routes", text: "When it opens, the website analyzes each route and does it again every 30 minutes while it stays open. Each one shows its best price and how much it has changed; if it drops or goes below yours, it alerts you (also with a browser notification)." },
      { title: "A new route", text: "Origin and destination (a city or its IATA code), the departure (a month or a day), the return if any, the currency, direct only and, if you like, a price to be alerted at." },
      { title: "The details", text: "The price of each day of the month (tap a day to buy it on Aviasales), the cheapest from each airline with the departure, return, stops and duration, and how the best price changes with each analysis." },
    ],
  },
};

export const GUIDES: Record<Lang, Record<string, DemoGuide>> = { es, en };

/** La captura del paso n (1, 2 o 3) de una demo. */
export const stepImage = (seed: string, lang: Lang, n: number) => `/demos/${lang}/${seed}-${n}.jpg`;
