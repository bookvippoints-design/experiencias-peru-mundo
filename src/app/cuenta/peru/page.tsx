import Link from "next/link";
import { requireRole } from "@/lib/auth/identity";
import { TopBar } from "@/components/TopBar";
import { Crumbs } from "@/components/Crumbs";
import { NationalGallery } from "@/components/DestinationGallery";
import { ExtraTravelersNote } from "@/components/ExtraTravelersNote";
import { NATIONAL_HOTELS_PDF, NATIONAL_MIN_DAYS, NATIONAL_NO_CANCEL, NATIONAL_RESPONSE, NATIONAL_RULE } from "@/lib/brand";

/** Beneficios en Perú: destinos y hoteles, sin precios. */
export default async function BeneficiosPeru() {
  const profile = await requireRole("user");
  return (
    <>
      <TopBar profile={profile} eyebrow="BENEFICIOS" title="En Perú" />
      <main className="portal-content flow">
        <Crumbs trail={[{ href: "/cuenta", label: "Inicio" }, { label: "Beneficios en Perú" }]} />
        <Link href="/cuenta" className="back-link">‹ Regresar</Link>

        <section className="benefit-hero">
          <img src="/acceso/img/destino-playa.webp" alt="Pareja disfrutando de un destino de Perú" />
          <div className="benefit-hero__text">
            <span>BENEFICIOS EN PERÚ</span>
            <h2>Escapadas para disfrutar en Perú</h2>
          </div>
        </section>

        <p className="lead-justify">Elige tu destino y vive una escapada en hoteles seleccionados, para disfrutarla o para regalarla a alguien especial.</p>

        {NATIONAL_HOTELS_PDF && (
        <a href={NATIONAL_HOTELS_PDF} target="_blank" rel="noreferrer" className="big-action">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><path d="M14 2v6h6" /></svg>
          Ver los hoteles participantes (PDF)
        </a>
        )}

        <h3 className="sub-title">Destinos</h3>
        <NationalGallery />

        <ExtraTravelersNote />

        <details className="how-use">
          <summary>¿Cómo se usa?</summary>
          <ol>
            <li>En &quot;Mis beneficios activados&quot; eliges la ciudad y la fecha de tu escapada.</li>
            <li>Pídela con al menos {NATIONAL_MIN_DAYS} días de anticipación. {NATIONAL_RESPONSE}</li>
            <li>{NATIONAL_RULE}</li>
            <li>{NATIONAL_NO_CANCEL}</li>
          </ol>
        </details>

        <Link href="/cuenta" className="back-big">‹ Regresar para conocer los beneficios en el Mundo</Link>
      </main>
    </>
  );
}
