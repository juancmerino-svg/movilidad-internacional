"""Genera la plantilla Word de referencia para la versión de envío a RESU.

Requiere python-docx. No contiene contenido científico ni datos; solo define
estilos Word reproducibles: Times New Roman 12 pt, interlineado sencillo,
márgenes de 1 pulgada y encabezados de 12 pt en negrita.
"""
from pathlib import Path

try:
    from docx import Document
    from docx.shared import Pt, Inches, RGBColor
    from docx.enum.text import WD_LINE_SPACING
    from docx.oxml.ns import qn
except ImportError as exc:
    raise SystemExit(
        "No se pudieron importar las dependencias de python-docx: "
        f"{exc!r}. Ejecute: python -m pip install python-docx lxml"
    ) from exc

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "templates" / "resu-reference.docx"
OUT.parent.mkdir(parents=True, exist_ok=True)

doc = Document()
styles = doc.styles

normal = styles["Normal"]
normal.font.name = "Times New Roman"
normal._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
normal.font.size = Pt(12)
normal.font.color.rgb = RGBColor(0, 0, 0)
normal.paragraph_format.line_spacing_rule = WD_LINE_SPACING.SINGLE
normal.paragraph_format.space_before = Pt(0)
normal.paragraph_format.space_after = Pt(0)

for name in ("Title", "Heading 1", "Heading 2", "Heading 3"):
    style = styles[name]
    style.font.name = "Times New Roman"
    style._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
    style.font.size = Pt(12)
    style.font.color.rgb = RGBColor(0, 0, 0)
    style.font.bold = True
    style.paragraph_format.line_spacing_rule = WD_LINE_SPACING.SINGLE
    style.paragraph_format.space_after = Pt(0)

if "Caption" in styles:
    style = styles["Caption"]
    style.font.name = "Times New Roman"
    style._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
    style.font.size = Pt(12)
    style.font.color.rgb = RGBColor(0, 0, 0)
    style.font.italic = False
    style.paragraph_format.line_spacing_rule = WD_LINE_SPACING.SINGLE
    style.paragraph_format.space_after = Pt(0)

for section in doc.sections:
    section.top_margin = Inches(1)
    section.bottom_margin = Inches(1)
    section.left_margin = Inches(1)
    section.right_margin = Inches(1)

# Párrafo mínimo para que Word conserve los estilos; no aparece en el manuscrito.
doc.add_paragraph("Plantilla de referencia RESU")
doc.save(OUT)
print(f"PASS: plantilla RESU generada en {OUT.relative_to(ROOT)}")
