// Descarga, durante el build, las fotos de destinos de la invitación impresa
// para que el PDF no dependa de internet al generarse. Si alguna falla, el
// build sigue y el PDF intenta descargarla al momento.
import { mkdir, writeFile, stat } from "node:fs/promises";
import path from "node:path";

const IMAGES = {
  paracas: "photo-1547818818-36fbc87a3913",
  cusco: "photo-1587595431973-160d0d94add1",
  mancora: "photo-1603854690030-13b18ce2a495",
  arequipa: "photo-1590545651636-f0e7f151239f",
  ica: "photo-1527736848781-72dc3b2ee00f",
  tarapoto: "photo-1610020909888-64e731d9e9f7",
  cajamarca: "photo-1650237898652-dbfcc5851fda",
  huaraz: "photo-1518081125676-71b905e428b5",
  puno: "photo-1544144554-41d909fadcf3",
  iquitos: "photo-1588837276720-2d2c1de8d05f",
  "punta-cana": "photo-1692017827893-f97d95397b49",
  cancun: "photo-1679599767221-4e1128c941ee",
  orlando: "photo-1609184889233-eff6dd93def4",
  paris: "photo-1632168594270-831d770aa8c3",
  roma: "photo-1514896856000-91cb6de818e0",
};

const dir = path.join(process.cwd(), "public", "invitacion", "dest");
await mkdir(dir, { recursive: true });
let ok = 0;
await Promise.all(
  Object.entries(IMAGES).map(async ([slug, id]) => {
    const file = path.join(dir, `${slug}.jpg`);
    try {
      const existing = await stat(file).catch(() => null);
      if (existing && existing.size > 5000) { ok++; return; }
      const res = await fetch(`https://images.unsplash.com/${id}?w=480&h=320&fit=crop&fm=jpg&q=75`, { signal: AbortSignal.timeout(15000) });
      const type = res.headers.get("content-type") ?? "";
      const buf = Buffer.from(await res.arrayBuffer());
      if (!res.ok || !type.startsWith("image/") || buf.length < 5000) throw new Error(`${res.status} ${type}`);
      await writeFile(file, buf);
      ok++;
    } catch (e) {
      console.warn(`[invitacion] no se pudo descargar ${slug}: ${e instanceof Error ? e.message : e}`);
    }
  })
);
console.log(`[invitacion] fotos de destinos listas: ${ok}/${Object.keys(IMAGES).length}`);
