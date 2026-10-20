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

        {NATIONAL_HOTELS_PDF && (
        <section className="hotels-card" aria-labelledby="hotels-title">
          <div className="hotels-card__icon" aria-hidden="true">
            <svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 21h18" /><path d="M5 21V7l7-4 7 4v14" /><path d="M9 21v-4h6v4" /><path d="M9 10h.01M15 10h.01M9 13.5h.01M15 13.5h.01" /></svg>
          </div>
          <div className="hotels-card__body">
            <span className="hotels-card__eyebrow">HOTELES PARTICIPANTES</span>
            <h2 id="hotels-title">¿Dónde te vas a hospedar?</h2>
            <p>Revisa la lista de hoteles por ciudad: Paracas, Cusco, Máncora, Arequipa, Ica, Tarapoto, Cajamarca, Huaraz, Puno e Iquitos.</p>
          </div>
          <a href={NATIONAL_HOTELS_PDF} target="_blank" rel="noreferrer" className="hotels-card__btn">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" aria-hidden="true"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><path d="M14 2v6h6" /><path d="M12 12v6M9 15l3 3 3-3" /></svg>
            Ver la lista de hoteles (PDF)
          </a>
        </section>
        )}

        <p className="lead-justify">Elige tu destino y vive una escapada en hoteles seleccionados, para disfrutarla o para regalarla a alguien especial.</p>

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
