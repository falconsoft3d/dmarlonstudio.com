part of 'tk_examples.dart';

/// Gestión de animales: altas, bajas y vacunas en una aplicación de consola
/// de Python; los datos se guardan en animales.json.
TkExample _consoleAnimals(String Function(String) t) {
  String m(String s) => t(s).replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  final code =
      '''# ${t(markTr('Gestión de animales: altas, bajas y vacunas. Los datos se guardan en animales.json, en la carpeta del proyecto.'))}
import json
import os
from datetime import date, datetime, timedelta

ARCHIVO = "animales.json"


def cargar():
    if not os.path.exists(ARCHIVO):
        return {"siguiente": 1, "animales": []}
    with open(ARCHIVO, encoding="utf-8") as f:
        return json.load(f)


def guardar(datos):
    with open(ARCHIVO, "w", encoding="utf-8") as f:
        json.dump(datos, f, ensure_ascii=False, indent=2)


def pedir(texto, obligatorio=True):
    while True:
        valor = input(texto).strip()
        if valor or not obligatorio:
            return valor
        print("${m(markTr('Este dato es obligatorio.'))}")


def pedir_fecha(texto, obligatorio=True):
    while True:
        valor = pedir(texto + " (AAAA-MM-DD): ", obligatorio)
        if not valor:
            return ""
        try:
            return datetime.strptime(valor, "%Y-%m-%d").date().isoformat()
        except ValueError:
            print("${m(markTr('Fecha no válida. Ejemplo: 2026-03-15'))}")


def buscar(datos, mostrar_bajas=False):
    texto = pedir("${m(markTr('Número del animal: '))}")
    if not texto.isdigit():
        print("${m(markTr('Escriba un número.'))}")
        return None
    for a in datos["animales"]:
        if a["id"] == int(texto) and (mostrar_bajas or a["activo"]):
            return a
    print("${m(markTr('No hay ningún animal activo con ese número.'))}")
    return None


def listar(datos):
    activos = [a for a in datos["animales"] if a["activo"]]
    if not activos:
        print("${m(markTr('No hay animales dados de alta.'))}")
        return
    print("${m(markTr('Nº   Nombre          Especie      Nacimiento   Vacunas'))}")
    for a in activos:
        print(f"{a['id']:<4} {a['nombre']:<15} {a['especie']:<12} "
              f"{a['nacimiento'] or '-':<12} {len(a['vacunas'])}")


def alta(datos):
    animal = {
        "id": datos["siguiente"],
        "nombre": pedir("${m(markTr('Nombre: '))}"),
        "especie": pedir("${m(markTr('Especie (perro, gato, vaca…): '))}"),
        "nacimiento": pedir_fecha("${m(markTr('Fecha de nacimiento'))}", obligatorio=False),
        "alta": date.today().isoformat(),
        "activo": True,
        "baja": None,
        "vacunas": [],
    }
    datos["siguiente"] += 1
    datos["animales"].append(animal)
    guardar(datos)
    print("${m(markTr('Dado de alta con el número'))}", animal["id"])


def baja(datos):
    animal = buscar(datos)
    if animal is None:
        return
    motivo = pedir("${m(markTr('Motivo de la baja: '))}")
    pregunta = "${m(markTr('¿Dar de baja a {0}? (s/n): '))}".replace("{0}", animal["nombre"])
    if pedir(pregunta).lower()[:1] not in ("s", "y"):
        print("${m(markTr('Cancelado.'))}")
        return
    animal["activo"] = False
    animal["baja"] = {"fecha": date.today().isoformat(), "motivo": motivo}
    guardar(datos)
    print("${m(markTr('{0} queda dado de baja.'))}".replace("{0}", animal["nombre"]))


def vacunar(datos):
    animal = buscar(datos)
    if animal is None:
        return
    vacuna = {
        "nombre": pedir("${m(markTr('Vacuna: '))}"),
        "fecha": pedir_fecha("${m(markTr('Fecha de aplicación'))}", obligatorio=False)
        or date.today().isoformat(),
        "proxima": pedir_fecha("${m(markTr('Próxima dosis (vacío si no hay)'))}", obligatorio=False),
    }
    animal["vacunas"].append(vacuna)
    guardar(datos)
    print("${m(markTr('Vacuna registrada para {0}.'))}".replace("{0}", animal["nombre"]))


def ver_vacunas(datos):
    animal = buscar(datos, mostrar_bajas=True)
    if animal is None:
        return
    print(animal["nombre"], "-", animal["especie"])
    if not animal["vacunas"]:
        print("${m(markTr('Sin vacunas registradas.'))}")
    for v in animal["vacunas"]:
        proxima = v["proxima"] or "-"
        print(f"  {v['fecha']}  {v['nombre']:<20} ${m(markTr('próxima:'))} {proxima}")


def pendientes(datos):
    limite = (date.today() + timedelta(days=30)).isoformat()
    hoy = date.today().isoformat()
    hay = False
    for a in datos["animales"]:
        if not a["activo"]:
            continue
        for v in a["vacunas"]:
            if v["proxima"] and v["proxima"] <= limite:
                estado = "${m(markTr('VENCIDA'))}" if v["proxima"] < hoy else "${m(markTr('pronto'))}"
                print(f"  {v['proxima']}  {a['nombre']:<15} {v['nombre']:<20} {estado}")
                hay = True
    if not hay:
        print("${m(markTr('No hay vacunas pendientes en los próximos 30 días.'))}")


MENU = """
${m(markTr('=== Gestión de animales ==='))}
1. ${m(markTr('Listar los animales'))}
2. ${m(markTr('Dar de alta un animal'))}
3. ${m(markTr('Dar de baja un animal'))}
4. ${m(markTr('Registrar una vacuna'))}
5. ${m(markTr('Ver las vacunas de un animal'))}
6. ${m(markTr('Vacunas pendientes (30 días)'))}
0. ${m(markTr('Salir'))}"""

ACCIONES = {"1": listar, "2": alta, "3": baja, "4": vacunar, "5": ver_vacunas, "6": pendientes}

datos = cargar()
while True:
    print(MENU)
    opcion = input("${m(markTr('Opción: '))}").strip()
    if opcion == "0":
        print("${m(markTr('Hasta luego.'))}")
        break
    accion = ACCIONES.get(opcion)
    if accion:
        accion(datos)
    else:
        print("${m(markTr('Opción no válida.'))}")
''';
  return TkExample(
    'console_animals',
    t(markTr('Gestión de animales (consola)')),
    t(
      markTr(
        'Una aplicación de consola en Python con menú: dar de alta y de baja animales y llevar sus vacunas, con las próximas dosis y las pendientes. Guarda los datos en animales.json.',
      ),
    ),
    TkDesign(target: tkTargetConsolePy, props: {'title': 'Animales'}),
    code,
  );
}
