"use client";
// Generado por DMarlon Studio a partir de la pantalla «Fuentes». No lo edite.
import { useRouter } from "next/navigation";
import { app, useApp } from "../_lib/state";
import { DmsScreen, DmsMissing, DmsCanvas } from "../_lib/dms";

export default function FuentesPage() {
  useApp();
  const router = useRouter();
  return (
    <DmsScreen
      title={`Fuentes`}
      back={false}
      actions={[]}
    >
      <div className="col st" style={{ gap: 12, padding: 12 }}>
        <div className="list sep">
          {(app.fuentes).map((f, i) => (
            <div className="item" key={i}>
              <div className="tile"><span className="avatar" style={{ background: f.color }}><span className="ms">{f.icon}</span></span><div className="tile-text"><div className="tile-title">{`${f.name}`}</div><div className="tile-sub">{`${f.detail}`}</div></div><span className="tile-trail">{`${f.n}`}</span></div>
            </div>
          ))}
        </div>
        <div className="card" style={{ padding: 16 }}>
          <div className="col st" style={{ gap: 8 }}>
            <h4 className="t-titleMedium">{`Cómo funciona`}</h4>
            <p className="t-bodyMedium">{`La web pide los datos a su propio servidor de Next.js cada 30 segundos. El servidor los descarga de las APIs públicas, los junta y los guarda un rato en memoria: el navegador no habla con ellas y no hacen falta claves.`}</p>
            <p className="t-bodySmall">{`Aviones: OpenSky Network, el mundo entero (sin cuenta, cada 15 minutos; con OPENSKY_CLIENT_ID y OPENSKY_CLIENT_SECRET, cada 90 segundos) o adsb.lol. Entre una lectura y otra, cada avión avanza por su rumbo y su velocidad.`}</p>
            <p className="t-bodySmall">{`Barcos: el AIS del mar Báltico de Fintraffic (Digitraffic). Trenes: Renfe Cercanías (España) y VR (Finlandia). El mapa: Natural Earth.`}</p>
          </div>
        </div>
      </div>
    </DmsScreen>
  );
}
