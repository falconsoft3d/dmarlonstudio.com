"use client";
// Generado por DMarlon Studio a partir de la pantalla «Lista». No lo edite.
import { useRouter } from "next/navigation";
import { app, useApp } from "../_lib/state";
import { DmsScreen, DmsMissing, DmsCanvas } from "../_lib/dms";

export default function ListaPage() {
  useApp();
  const router = useRouter();
  return (
    <DmsScreen
      title={`List`}
      back={false}
      actions={[]}
    >
      <div className="col st" style={{ gap: 10, padding: 12 }}>
        <label className="field" onClick={(e) => e.stopPropagation()}><span className="field-box"><span className="ms">search</span><input type="text" placeholder={`Search for a flight, a ship or a train`} value={app.busqueda ?? ""} onChange={(e) => { app.busqueda = e.target.value; app.notify(); }} /></span></label>
        <span className="t-labelSmall">{`${app.listaTitulo}`}</span>
        <div className="list sep">
          {(app.lista).map((item, i) => (
            <div className="item" key={i}>
              <div className="tile tap" onClick={async () => { app.elegir(item); app.home(router, 'Mapa'); }}><span className="avatar" style={{ background: item.color }}><span className="ms">{item.icon}</span></span><div className="tile-text"><div className="tile-title">{`${item.name}`}</div><div className="tile-sub">{`${item.sub}`}</div></div><span className="tile-trail">{`${item.vel}`}</span></div>
            </div>
          ))}
          {(app.lista).length === 0 && <p className="empty">{`${app.vacio}`}</p>}
        </div>
      </div>
    </DmsScreen>
  );
}
