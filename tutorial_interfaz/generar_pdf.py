"""Genera el PDF de TUTORIAL.md sin requerir Word ni LibreOffice.

Dependencias de edición del manual: reportlab. No son dependencias de la app.
Después de generar, renderizar el PDF y revisar todas sus páginas.
"""

from html import escape
from pathlib import Path
import re

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    Image, KeepTogether, LongTable, PageBreak, Paragraph, SimpleDocTemplate,
    Spacer, TableStyle,
)


ROOT = Path(__file__).resolve().parent
OUTPUT = ROOT / "tutorial_interfaz_hospital.pdf"
TOKEN = re.compile(r"(\*\*[^*]+\*\*|`[^`]+`|\[[^\]]+\]\([^)]+\))")
WIDTH = 6.8 * inch


def inline(text):
    output = []
    for part in TOKEN.split(text):
        if part.startswith("**"):
            output.append("<b>" + escape(part[2:-2]) + "</b>")
        elif part.startswith("`"):
            # Insert wrapping opportunities in long file names and paths.
            code = escape(part[1:-1]).replace("\\", "\\<wbr/>").replace("_", "_<wbr/>")
            output.append('<font face="Helvetica" size="10">' + code + "</font>")
        elif part.startswith("["):
            match = re.fullmatch(r"\[([^\]]+)\]\(([^)]+)\)", part)
            output.append('<link href="' + escape(match[2], quote=True) + '" color="#174A70">' + escape(match[1]) + "</link>")
        else:
            output.append(escape(part))
    return "".join(output)


def build():
    styles = getSampleStyleSheet()
    styles.add(ParagraphStyle("BodyHospital", fontName="Helvetica", fontSize=10.5,
                              leading=14.0, spaceAfter=7, textColor=colors.black))
    styles.add(ParagraphStyle("TitleHospital", parent=styles["BodyHospital"],
                              fontName="Helvetica-Bold", fontSize=22, leading=27,
                              spaceAfter=12, keepWithNext=True))
    styles.add(ParagraphStyle("HeadingHospital", parent=styles["BodyHospital"],
                              fontName="Helvetica-Bold", fontSize=15, leading=19,
                              spaceBefore=12, spaceAfter=7, keepWithNext=True))
    styles.add(ParagraphStyle("SubheadingHospital", parent=styles["HeadingHospital"],
                              fontSize=12, leading=16, spaceBefore=9))
    styles.add(ParagraphStyle("StepHospital", parent=styles["BodyHospital"],
                              leftIndent=14, firstLineIndent=-14))
    styles.add(ParagraphStyle("TableHospital", parent=styles["BodyHospital"],
                              fontSize=10, leading=12.7, spaceAfter=0))
    styles.add(ParagraphStyle("CaptionHospital", parent=styles["BodyHospital"],
                              fontSize=9, leading=12, spaceAfter=9))
    story = []
    lines = (ROOT / "TUTORIAL.md").read_text(encoding="utf-8").splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        i += 1
        if not line:
            continue
        if line == "<!-- pagebreak -->":
            story.append(PageBreak())
        elif line.startswith("!["):
            match = re.fullmatch(r"!\[([^\]]*)\]\(([^)]+)\)", line)
            image = Image(str(ROOT / match[2]))
            scale = min(WIDTH / image.imageWidth, 5.5 * inch / image.imageHeight)
            image.drawWidth, image.drawHeight = image.imageWidth * scale, image.imageHeight * scale
            image.hAlign = "CENTER"
            caption = Paragraph(escape(match[1]), styles["CaptionHospital"])
            story.append(KeepTogether([Spacer(1, 4), image, Spacer(1, 4), caption]))
        elif line.startswith("# "):
            story.append(Paragraph(inline(line[2:]), styles["TitleHospital"]))
        elif line.startswith("## "):
            story.append(Paragraph(inline(line[3:]), styles["HeadingHospital"]))
        elif line.startswith("### "):
            story.append(Paragraph(inline(line[4:]), styles["SubheadingHospital"]))
        elif line.startswith("|"):
            rows = [[cell.strip() for cell in line.strip("|").split("|")]]
            while i < len(lines) and lines[i].strip().startswith("|"):
                rows.append([cell.strip() for cell in lines[i].strip().strip("|").split("|")])
                i += 1
            rows.pop(1)  # Markdown alignment row.
            formatted = [[Paragraph(("<b>" + inline(cell) + "</b>") if index == 0 else inline(cell), styles["TableHospital"])
                          for cell in row] for index, row in enumerate(rows)]
            col_widths = [2.05 * inch, 4.75 * inch] if len(rows[0]) == 2 else [WIDTH / len(rows[0])] * len(rows[0])
            table = LongTable(formatted, colWidths=col_widths, repeatRows=1, hAlign="LEFT")
            commands = [
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#D9D9D9")),
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#E7EBEF")),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("LEFTPADDING", (0, 0), (-1, -1), 7),
                ("RIGHTPADDING", (0, 0), (-1, -1), 7),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ]
            for row in range(2, len(rows), 2):
                commands.append(("BACKGROUND", (0, row), (-1, row), colors.HexColor("#F7F8FA")))
            table.setStyle(TableStyle(commands))
            story.extend([table, Spacer(1, 9)])
        else:
            style = styles["StepHospital"] if re.match(r"^(?:\d+\. |- )", line) else styles["BodyHospital"]
            if line.startswith("- "):
                line = "• " + line[2:]
            story.append(Paragraph(inline(line), style))

    def footer(canvas, document):
        canvas.saveState()
        canvas.setFont("Helvetica", 8.5)
        canvas.drawRightString(7.65 * inch, 0.36 * inch, "Hospital universitario  |  " + str(document.page))
        canvas.restoreState()

    document = SimpleDocTemplate(str(OUTPUT), pagesize=letter,
                                 rightMargin=0.85 * inch, leftMargin=0.85 * inch,
                                 topMargin=0.72 * inch, bottomMargin=0.65 * inch,
                                 title="Cómo usar la aplicación del hospital desde cero",
                                 author="Equipo del proyecto")
    document.build(story, onFirstPage=footer, onLaterPages=footer)
    print(OUTPUT)


if __name__ == "__main__":
    build()
