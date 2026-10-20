export interface DestinationInfo {
  name: string;
  imageId: string;
  caption?: string;
}

export const NATIONAL_DESTINATIONS: DestinationInfo[] = [
  { name: "Paracas", imageId: "photo-1547818818-36fbc87a3913", caption: "Reserva natural y mar" },
  { name: "Cusco", imageId: "photo-1587595431973-160d0d94add1", caption: "Puerta a Machu Picchu" },
  { name: "Máncora", imageId: "photo-1603854690030-13b18ce2a495", caption: "Playa y sol todo el año" },
  { name: "Arequipa", imageId: "photo-1590545651636-f0e7f151239f", caption: "La ciudad blanca y sus volcanes" },
  { name: "Ica", imageId: "photo-1527736848781-72dc3b2ee00f", caption: "Oasis de Huacachina y viñedos" },
  { name: "Tarapoto", imageId: "photo-1610020909888-64e731d9e9f7", caption: "Selva alta y cascadas" },
  { name: "Cajamarca", imageId: "photo-1650237898652-dbfcc5851fda", caption: "Historia, baños termales y campiña" },
  { name: "Huaraz", imageId: "photo-1518081125676-71b905e428b5", caption: "Cordillera Blanca y lagunas" },
  { name: "Puno", imageId: "photo-1544144554-41d909fadcf3", caption: "Lago Titicaca" },
  { name: "Iquitos", imageId: "photo-1588837276720-2d2c1de8d05f", caption: "Amazonía peruana" },
];

/**
 * Imágenes de inspiración para la invitación internacional. Son solo ejemplos
 * referenciales: la invitación da acceso a más de 130 destinos en el mundo.
 */
export const INTERNATIONAL_INSPIRATION: DestinationInfo[] = [
  { name: "Punta Cana", imageId: "photo-1692017827893-f97d95397b49" },
  { name: "Cancún", imageId: "photo-1679599767221-4e1128c941ee" },
  { name: "Orlando", imageId: "photo-1609184889233-eff6dd93def4" },
  { name: "París", imageId: "photo-1632168594270-831d770aa8c3" },
  { name: "Roma", imageId: "photo-1514896856000-91cb6de818e0" },
  { name: "Cartagena", imageId: "photo-1672984181706-68495d988419" },
];

/** Fotos genéricas de hotel, siempre con la etiqueta "Imagen referencial". */
export const HOTEL_PHOTOS = [
  "photo-1520250497591-112f2f40a3f4",
  "photo-1566073771259-6a8506099945",
  "photo-1551882547-ff40c63fe5fa",
  "photo-1611892440504-42a792e24d32",
];

export function unsplashUrl(imageId: string, width = 400, height = 300): string {
  return `https://images.unsplash.com/${imageId}?w=${width}&h=${height}&fit=crop&auto=format&q=70`;
}
