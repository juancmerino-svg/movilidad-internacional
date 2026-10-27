"""Postprocesa y audita los DOCX de envío a RESU.

Objetivos:
- eliminar el sufijo espurio `.X` de DOI;
- convertir las cuatro tablas científicas anidadas generadas por Pandoc en
  tablas Word normales de primer nivel para mejorar compatibilidad entre Word
  y LibreOffice;
- conservar caption, contenido y formato de las tablas;
- verificar cuatro tablas, al menos una figura y ausencia de DOI `.X`;
- auditar metadatos básicos, comentarios y control de cambios para doble ciego;
- no modificar contenido científico.
"""
from pathlib import Path
import re
import shutil
import tempfile
import zipfile

from lxml import etree
from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt

ROOT = Path(__file__).resolve().parents[1]
FILES = [
    ROOT / "manuscript" / "article-resu-submit.docx",
    ROOT / "manuscript" / "article-resu-elements.docx",
]

NS = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
CP_NS = {
    "cp": "http://schemas.openxmlformats.org/package/2006/metadata/core-properties",
    "dc": "http://purl.org/dc/elements/1.1/",
}
DOI_BAD = re.compile(r"https://doi\.org/\S+?\.X(?=\s|$)", re.IGNORECASE)
PROHIBITED_IDENTITY = (
    "Universidad Nacional de Loja",
    "josevicente1980",
    "José Vicente",
    "Jose Vicente",
    "Ordóñez",
    "Ordonez",
)

TABLE_SPECS = {
    "Tabla 1:": {
        "header": ("Etapa", "n"),
        "widths": [5.45, 0.70],
        "align": ("left", "center"),
    },
    "Tabla 2:": {
        "header": ("Muestra", "Agrupación", "Media"),
        "widths": [0.80, 4.60, 0.75],
        "align": ("left", "left", "center"),
    },
    "Tabla 3:": {
        "header": ("Pos.", "Agrupación", "Indicador", "n", "Media"),
        "widths": [0.45, 1.00, 3.65, 0.40, 0.65],
        "align": ("center", "left", "left", "center", "center"),
    },
    "Tabla 4:": {
        "header": ("Muestra", "n", "Global", "Personal", "Institucional", "Contraste P–I"),
        "widths": [1.40, 0.35, 0.65, 0.85, 1.00, 1.30],
        "align": ("left", "center", "center", "center", "center", "center"),
    },
}


def _norm(text: str) -> str:
    return " ".join((text or "").replace("\u00a0", " ").split())


def _remove_global_chars(nodes, start: int, end: int) -> None:
    pos = 0
    for node in nodes:
        s = node.text or ""
        node_start, node_end = pos, pos + len(s)
        overlap_start = max(start, node_start)
        overlap_end = min(end, node_end)
        if overlap_start < overlap_end:
            a = overlap_start - node_start
            b = overlap_end - node_start
            node.text = s[:a] + s[b:]
        pos = node_end


def clean_doi_xml(path: Path) -> int:
    """Quita `.X` visible de DOI aunque esté dividido entre runs."""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        with zipfile.ZipFile(path, "r") as zin:
            zin.extractall(tmp)

        xml_path = tmp / "word" / "document.xml"
        tree = etree.parse(str(xml_path))
        root = tree.getroot()
        changed = 0

        for paragraph in root.xpath(".//w:p", namespaces=NS):
            nodes = paragraph.xpath(".//w:t", namespaces=NS)
            if not nodes:
                continue
            text = "".join((n.text or "") for n in nodes)
            matches = list(DOI_BAD.finditer(text))
            for match in reversed(matches):
                _remove_global_chars(nodes, match.end() - 2, match.end())
                changed += 1

        tree.write(str(xml_path), encoding="UTF-8", xml_declaration=True, standalone="yes")
        rebuilt = path.with_suffix(".tmp.docx")
        with zipfile.ZipFile(rebuilt, "w", zipfile.ZIP_DEFLATED) as zout:
            for f in tmp.rglob("*"):
                if f.is_file():
                    zout.write(f, f.relative_to(tmp))
        shutil.move(rebuilt, path)
    return changed


def _row_values(row) -> tuple[str, ...]:
    return tuple(_norm(cell.text) for cell in row.cells)


def _caption_text(table) -> str:
    if not table.rows:
        return ""
    for value in _row_values(table.rows[0]):
        if value:
            return value.split("\n", 1)[0].strip()
    return ""


def _nested_tables(table):
    nested = []
    for row in table.rows:
        for cell in row.cells:
            nested.extend(cell.tables)
    return nested


def flatten_scientific_tables(doc) -> int:
    """Saca las tablas científicas de contenedores Pandoc 1x1.

    Resultado: caption como párrafo + tabla científica de primer nivel.
    """
    flattened = 0
    for outer in list(doc.tables):
        caption = _caption_text(outer)
        label = next((x for x in TABLE_SPECS if caption.startswith(x)), None)
        if label is None:
            continue

        spec = TABLE_SPECS[label]
        candidates = [
            t for t in _nested_tables(outer)
            if t.rows and _row_values(t.rows[0]) == spec["header"]
        ]
        if len(candidates) != 1:
            raise SystemExit(
                f"BLOCK: {label} contiene {len(candidates)} tablas internas compatibles; se esperaba 1."
            )

        inner = candidates[0]
        matrix = [[cell.text for cell in row.cells] for row in inner.rows]

        parent = outer._tbl.getparent()
        idx = parent.index(outer._tbl)

        p = doc.add_paragraph(caption)
        try:
            p.style = doc.styles["Caption"]
        except KeyError:
            pass
        for run in p.runs:
            run.font.name = "Times New Roman"
            run.font.size = Pt(12)
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        p.paragraph_format.line_spacing = 1

        # Crear una tabla Word nueva de primer nivel. No se reutiliza el XML
        # de la tabla anidada de Pandoc, porque algunos renderizadores conservan
        # artefactos de su contexto original aun después de mover el nodo.
        fresh = doc.add_table(rows=len(matrix), cols=len(matrix[0]))
        for r_idx, values in enumerate(matrix):
            for c_idx, value in enumerate(values):
                fresh.cell(r_idx, c_idx).text = value

        parent.insert(idx, p._p)
        parent.insert(idx + 1, fresh._tbl)
        parent.remove(outer._tbl)
        flattened += 1

    if flattened != 4:
        raise SystemExit(f"BLOCK: se aplanaron {flattened} tablas científicas; se esperaban 4.")
    return flattened


def _set_repeat_table_header(row) -> None:
    tr_pr = row._tr.get_or_add_trPr()
    tbl_header = tr_pr.find(qn("w:tblHeader"))
    if tbl_header is None:
        tbl_header = OxmlElement("w:tblHeader")
        tr_pr.append(tbl_header)
    tbl_header.set(qn("w:val"), "true")


def _prevent_row_split(row) -> None:
    tr_pr = row._tr.get_or_add_trPr()
    cant_split = tr_pr.find(qn("w:cantSplit"))
    if cant_split is None:
        cant_split = OxmlElement("w:cantSplit")
        tr_pr.append(cant_split)


def _set_cell_width(cell, inches: float) -> None:
    cell.width = Inches(inches)
    tc_pr = cell._tc.get_or_add_tcPr()
    tc_w = tc_pr.first_child_found_in("w:tcW")
    if tc_w is None:
        tc_w = OxmlElement("w:tcW")
        tc_pr.append(tc_w)
    tc_w.set(qn("w:type"), "dxa")
    tc_w.set(qn("w:w"), str(int(inches * 1440)))


def _identify_top_level_scientific_tables(doc):
    found = {}
    for table in doc.tables:
        if not table.rows:
            continue
        header = _row_values(table.rows[0])
        for label, spec in TABLE_SPECS.items():
            if header == spec["header"]:
                if label in found:
                    raise SystemExit(f"BLOCK: tabla científica duplicada: {label}")
                found[label] = table
    return found


def format_reference_paragraphs(doc) -> int:
    """Aplica sangría francesa y formato RESU a la bibliografía, si existe."""
    inside = False
    found_section = False
    count = 0
    for paragraph in doc.paragraphs:
        text = _norm(paragraph.text)
        if text == "Referencias":
            inside = True
            found_section = True
            continue
        if inside and text == "Cuadros y figura":
            break
        if not inside or not text:
            continue
        paragraph.paragraph_format.left_indent = Inches(0.5)
        paragraph.paragraph_format.first_line_indent = Inches(-0.5)
        paragraph.paragraph_format.right_indent = Inches(0)
        paragraph.paragraph_format.space_before = Pt(0)
        paragraph.paragraph_format.space_after = Pt(0)
        paragraph.paragraph_format.line_spacing = 1
        for run in paragraph.runs:
            run.font.name = "Times New Roman"
            run.font.size = Pt(12)
        count += 1
    if found_section and count < 50:
        raise SystemExit(f"BLOCK: solo se formatearon {count} referencias; se esperaban al menos 50.")
    return count


def format_tables(path: Path) -> tuple[int, int]:
    doc = Document(path)
    flattened = flatten_scientific_tables(doc)
    n_references = format_reference_paragraphs(doc)
    scientific = _identify_top_level_scientific_tables(doc)
    missing = [label for label in TABLE_SPECS if label not in scientific]
    if missing:
        raise SystemExit("BLOCK: faltan tablas científicas: " + ", ".join(missing))

    for label, table in scientific.items():
        spec = TABLE_SPECS[label]
        widths = spec["widths"]
        alignments = spec["align"]
        table.style = "Table Grid"
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        table.autofit = False

        tbl_pr = table._tbl.tblPr
        tbl_layout = tbl_pr.first_child_found_in("w:tblLayout")
        if tbl_layout is None:
            tbl_layout = OxmlElement("w:tblLayout")
            tbl_pr.append(tbl_layout)
        tbl_layout.set(qn("w:type"), "fixed")

        total_twips = int(round(sum(widths) * 1440))
        tbl_w = tbl_pr.first_child_found_in("w:tblW")
        if tbl_w is None:
            tbl_w = OxmlElement("w:tblW")
            tbl_pr.append(tbl_w)
        tbl_w.set(qn("w:type"), "dxa")
        tbl_w.set(qn("w:w"), str(total_twips))

        grid = table._tbl.tblGrid
        grid_cols = list(grid)
        if len(grid_cols) != len(widths):
            raise SystemExit(
                f"BLOCK: {label} tiene {len(grid_cols)} columnas en tblGrid; se esperaban {len(widths)}."
            )
        for grid_col, width in zip(grid_cols, widths):
            grid_col.set(qn("w:w"), str(int(round(width * 1440))))

        _set_repeat_table_header(table.rows[0])
        for r_idx, row in enumerate(table.rows):
            _prevent_row_split(row)
            if len(row.cells) != len(widths):
                raise SystemExit(
                    f"BLOCK: {label} tiene {len(row.cells)} columnas; se esperaban {len(widths)}."
                )
            for c_idx, cell in enumerate(row.cells):
                _set_cell_width(cell, widths[c_idx])
                cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
                for paragraph in cell.paragraphs:
                    paragraph.paragraph_format.space_before = Pt(0)
                    paragraph.paragraph_format.space_after = Pt(0)
                    paragraph.paragraph_format.line_spacing = 1
                    paragraph.alignment = (
                        WD_ALIGN_PARAGRAPH.CENTER
                        if alignments[c_idx] == "center"
                        else WD_ALIGN_PARAGRAPH.LEFT
                    )
                    for run in paragraph.runs:
                        run.font.name = "Times New Roman"
                        run.font.size = Pt(12)
                        if r_idx == 0:
                            run.bold = True

    # Metadatos core sin identidad.
    doc.core_properties.author = ""
    doc.core_properties.last_modified_by = ""
    doc.save(path)
    return flattened, len(scientific), n_references


def audit_blind_metadata(path: Path) -> None:
    with zipfile.ZipFile(path, "r") as zf:
        names = set(zf.namelist())

        # Core properties.
        if "docProps/core.xml" in names:
            root = etree.fromstring(zf.read("docProps/core.xml"))
            creator = root.find("dc:creator", namespaces=CP_NS)
            modified = root.find("cp:lastModifiedBy", namespaces=CP_NS)
            for label, node in (("creator", creator), ("lastModifiedBy", modified)):
                value = (node.text or "").strip() if node is not None else ""
                if value:
                    raise SystemExit(f"BLOCK doble ciego: {label} contiene '{value}'.")

        # Control de cambios y comentarios reales.
        n_ins = n_del = n_comments = 0
        identity_hits = []
        for name in names:
            if not (name.endswith(".xml") or name.endswith(".rels")):
                continue
            data = zf.read(name)
            text = data.decode("utf-8", "ignore")
            for token in PROHIBITED_IDENTITY:
                if token.lower() in text.lower():
                    identity_hits.append((name, token))
            if name.startswith("word/") and name.endswith(".xml"):
                try:
                    root = etree.fromstring(data)
                except Exception:
                    continue
                n_ins += len(root.xpath(".//w:ins", namespaces=NS))
                n_del += len(root.xpath(".//w:del", namespaces=NS))
                n_comments += len(root.xpath(
                    ".//w:commentRangeStart | .//w:commentRangeEnd | .//w:commentReference",
                    namespaces=NS,
                ))

        if n_ins or n_del:
            raise SystemExit(
                f"BLOCK doble ciego/revisión: cambios controlados presentes (ins={n_ins}, del={n_del})."
            )
        if n_comments:
            raise SystemExit(f"BLOCK doble ciego/revisión: {n_comments} anclajes de comentarios presentes.")
        if identity_hits:
            sample = "; ".join(f"{n}: {t}" for n, t in identity_hits[:5])
            raise SystemExit("BLOCK doble ciego: identificadores en paquete DOCX: " + sample)


def audit(path: Path) -> tuple[int, int, int]:
    doc = Document(path)
    scientific = _identify_top_level_scientific_tables(doc)
    n_scientific = len(scientific)
    n_figures = len(doc.inline_shapes)

    if n_scientific != 4:
        raise SystemExit(
            f"BLOCK: {path.name} contiene {n_scientific} tablas científicas; se esperaban 4."
        )
    if n_figures < 1:
        raise SystemExit(f"BLOCK: {path.name} no contiene la figura esperada.")

    with zipfile.ZipFile(path, "r") as zf:
        root = etree.fromstring(zf.read("word/document.xml"))
    bad = []
    for paragraph in root.xpath(".//w:p", namespaces=NS):
        text = "".join(paragraph.xpath(".//w:t/text()", namespaces=NS))
        bad.extend(DOI_BAD.findall(text))
    if bad:
        raise SystemExit(
            f"BLOCK: persisten {len(bad)} DOI con sufijo .X en {path.name}; ejemplo: {bad[0]}"
        )

    audit_blind_metadata(path)
    return n_scientific, n_figures, len(doc.tables)


for path in FILES:
    if not path.exists():
        raise SystemExit(f"No existe el DOCX para postprocesar: {path}")
    n_clean = clean_doi_xml(path)
    n_flattened, _, n_references = format_tables(path)
    n_scientific, n_figures, n_top_tables = audit(path)
    print(
        f"PASS postproceso RESU: {path.relative_to(ROOT)} | "
        f"DOI corregidos: {n_clean} | referencias con sangría francesa: {n_references} | "
        f"tablas aplanadas: {n_flattened} | tablas científicas: {n_scientific} | "
        f"tablas top-level: {n_top_tables} | figuras: {n_figures} | "
        f"doble ciego DOCX: PASS"
    )
