import {
  AppWindow,
  CheckSquare,
  ChevronDown,
  Circle,
  Grid3x3,
  List,
  Play,
  Save,
  Square,
  Table2,
  TextCursorInput,
  Type,
  Undo2,
} from "lucide-react";

const PALETTE = [
  { icon: Type, label: "Label" },
  { icon: Square, label: "Button" },
  { icon: TextCursorInput, label: "Entry" },
  { icon: CheckSquare, label: "Checkbutton" },
  { icon: Circle, label: "Radiobutton" },
  { icon: ChevronDown, label: "Combobox" },
  { icon: List, label: "Listbox" },
  { icon: Table2, label: "Treeview" },
];

const TREE = ["Form1", "Label1", "NameEntry", "Button1", "Grid1"];

const PROPS: [string, string][] = [
  ["name", "Button1"],
  ["text", "Guardar"],
  ["x", "216"],
  ["y", "120"],
  ["width", "96"],
  ["height", "30"],
];

/**
 * Maqueta del diseñador hecha con HTML y CSS: barra de herramientas,
 * paleta, árbol e inspector a la izquierda y el formulario en el lienzo.
 * Es decorativa: se oculta a los lectores de pantalla.
 */
export function IdeMock() {
  return (
    <div
      aria-hidden
      className="overflow-hidden rounded-xl border border-line bg-ide-panel text-[11px] shadow-2xl shadow-black/10 select-none dark:shadow-black/40"
    >
      {/* Barra de título */}
      <div className="flex items-center gap-1.5 border-b border-line bg-ide-bar px-3 py-2">
        <span className="size-2.5 rounded-full bg-[#ff5f57]" />
        <span className="size-2.5 rounded-full bg-[#febc2e]" />
        <span className="size-2.5 rounded-full bg-[#28c840]" />
        <span className="ml-3 truncate text-muted">DMarlon Studio — Agenda</span>
      </div>
      {/* Herramientas */}
      <div className="flex items-center gap-3 border-b border-line bg-ide-bar px-3 py-1.5 text-muted">
        <Save className="size-3.5" />
        <Undo2 className="size-3.5" />
        <span className="h-3.5 w-px bg-line" />
        <span className="flex items-center gap-1 text-success">
          <Play className="size-3.5 fill-current" /> F9
        </span>
        <Square className="size-3.5" />
        <span className="h-3.5 w-px bg-line" />
        <Grid3x3 className="size-3.5 text-accent" />
      </div>
      {/* Paleta */}
      <div className="flex gap-1 overflow-hidden border-b border-line px-2 py-1.5">
        {PALETTE.map(({ icon: Icon, label }) => (
          <span key={label} className="flex shrink-0 items-center gap-1 rounded bg-soft px-2 py-1">
            <Icon className="size-3" />
            {label}
          </span>
        ))}
      </div>
      <div className="flex h-[300px] sm:h-[340px]">
        {/* Árbol e inspector */}
        <div className="hidden w-44 shrink-0 flex-col border-r border-line sm:flex">
          <div className="border-b border-line py-1">
            {TREE.map((n, i) => (
              <div
                key={n}
                className={`flex items-center gap-1.5 py-0.5 ${i === 3 ? "bg-ide-select" : ""}`}
                style={{ paddingLeft: i === 0 ? 8 : 22 }}
              >
                <AppWindow className="size-3 text-muted" />
                {n}
              </div>
            ))}
          </div>
          <div className="flex gap-3 border-b border-line px-2 py-1 font-medium">
            <span className="border-b-2 border-accent">Propiedades</span>
            <span className="text-muted">Eventos</span>
          </div>
          <div className="flex-1">
            {PROPS.map(([k, v]) => (
              <div key={k} className="grid grid-cols-2 border-b border-line/70">
                <span className="truncate px-2 py-1 text-muted">{k}</span>
                <span className="truncate border-l border-line/70 px-2 py-1 font-mono">{v}</span>
              </div>
            ))}
          </div>
        </div>
        {/* Lienzo */}
        <div className="flex min-w-0 flex-1 flex-col">
          <div className="flex gap-4 border-b border-line px-3 py-1">
            <span className="border-b-2 border-accent pb-0.5 font-medium">Diseño</span>
            <span className="text-muted">Código</span>
            <span className="text-muted">Python generado</span>
          </div>
          <div className="relative flex-1 bg-ide-canvas p-4 sm:p-6">
            <div className="ide-grid relative h-full max-w-[340px] overflow-hidden rounded border border-line bg-ide-form">
              <div className="flex items-center justify-between bg-accent/90 px-2 py-1 text-on-accent">
                <span>Agenda</span>
                <span className="opacity-80">✕</span>
              </div>
              <div className="absolute left-4 top-11 text-ink">Nombre</div>
              <div className="absolute left-20 right-4 top-10 h-6 rounded-sm border border-line bg-surface" />
              <div className="absolute left-4 top-[4.6rem] text-ink">Correo</div>
              <div className="absolute left-20 right-4 top-[4.4rem] h-6 rounded-sm border border-line bg-surface" />
              {/* Botón seleccionado con sus tiradores */}
              <div className="absolute right-4 top-[6.9rem] flex h-7 w-24 items-center justify-center rounded-sm border border-line bg-soft text-ink outline-1 outline-dashed outline-offset-2 outline-accent">
                Guardar
                {["-left-1.5 -top-1.5", "-right-1.5 -top-1.5", "-left-1.5 -bottom-1.5", "-right-1.5 -bottom-1.5"].map(
                  (p) => (
                    <span key={p} className={`absolute size-1.5 bg-accent ${p}`} />
                  ),
                )}
              </div>
              <div className="absolute inset-x-4 bottom-4 top-[9.6rem] rounded-sm border border-line bg-surface">
                <div className="grid grid-cols-3 border-b border-line bg-soft px-2 py-1 text-muted">
                  <span>Nombre</span>
                  <span>Correo</span>
                  <span>Teléfono</span>
                </div>
                {[0, 1, 2].map((r) => (
                  <div key={r} className="grid grid-cols-3 gap-2 px-2 py-1.5">
                    <span className="h-1.5 rounded bg-line" />
                    <span className="h-1.5 rounded bg-line" />
                    <span className="h-1.5 w-2/3 rounded bg-line" />
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
