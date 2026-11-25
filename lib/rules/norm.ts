/** Normaliza texto para buscar y comparar: minúsculas, sin tildes ni espacios sobrantes. */
export function norm(text: string | null | undefined): string {
  return (text ?? "")
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/\s+/g, " ")
    .trim();
}
