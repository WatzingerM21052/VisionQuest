#!/usr/bin/env python3
"""
Premium Wochenprotokoll-Generator für VisionQuest
Material Design + moderne Typografie
"""

from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, PageTemplate, Frame
from reportlab.lib import colors
from reportlab.pdfgen import canvas as pdfcanvas
import os

# Material Design Color System
PRIMARY = colors.HexColor('#1976D2')      # Material Blue
PRIMARY_DARK = colors.HexColor('#1565C0')
PRIMARY_LIGHT = colors.HexColor('#BBDEFB')
ACCENT = colors.HexColor('#FF6F00')       # Material Orange
SECONDARY = colors.HexColor('#00838F')    # Material Teal

SURFACE = colors.HexColor('#FFFFFF')
BACKGROUND = colors.HexColor('#FAFAFA')
TEXT_PRIMARY = colors.HexColor('#212121')
TEXT_SECONDARY = colors.HexColor('#757575')
DIVIDER = colors.HexColor('#BDBDBD')

PROTOKOLL_DATA = {
    "titel": "VisionQuest",
    "subtitle": "Wochenprotokoll",
    "name": "Matthias",
    "datum": "26.02.2026",
    "meilenstein": "M2",
    "items": [
        {
            "titel": "Abgeschlossene Arbeiten",
            "punkte": [
                "SQLite Datenbank mit 4 Tabellen (users, quests, user_stats, achievements) erstellt",
                "CRUD-Operationen für User und Quests implementiert",
                "13 REST-API Endpoints definiert und getestet",
                "JWT-Authentication und Passwort-Hashing mit bcryptjs integriert",
                "Error-Handling für alle API-Endpoints implementiert",
                "Code-Struktur mit Service-Layer organisiert",
                "API-Dokumentation geschrieben"
            ]
        },
        {
            "titel": "Projektstatus",
            "punkte": [
                "Gut im Zeitplan - alle für 02.03.2026 geplanten Tasks abgeschlossen",
                "Backend läuft stabil mit SQLite und vollständiger Authentication"
            ]
        },
        {
            "titel": "Nächste Schritte",
            "punkte": [
                "Flutter Frontend mit Login/Register Screens erweitern",
                "Alle API-Endpoints mit curl/Postman testen",
                "Token-Storage in Flutter implementieren",
                "Gamification-Features (XP, Levels, Streaks) testen",
                "npm Security Vulnerabilities beheben"
            ]
        }
    ],
    "ki_section": [
        {
            "titel": "Fehlermeldungen & Error-Handling",
            "items": [
                "Try-Catch Blöcke um alle SQL-Queries",
                "Standardisiertes Error-Response Format",
                "Aussagekräftige Error-Messages für Client",
                "Input-Validierung bei allen POST/PUT Endpoints"
            ]
        },
        {
            "titel": "Code-Struktur & Übersichtlichkeit",
            "items": [
                "CRUD-Funktionen in separate dbService.js ausgelagert",
                "Funktionen nach Logik gruppiert (Users, Quests, Stats)",
                "Konsistente Namenkonventionen implementiert",
                "JSDoc-Kommentare für alle öffentlichen Funktionen"
            ]
        }
    ]
}


class PremiumWochenprotokollPDF:
    def __init__(self, filename):
        self.filename = filename
        self.styles = getSampleStyleSheet()
        self._define_styles()
        self.story = []

    def _define_styles(self):
        """Material Design Styles"""
        # Display 1 - Großer Titel
        self.styles.add(ParagraphStyle(
            name='MD_Display1',
            fontSize=40,
            textColor=PRIMARY_DARK,
            fontName='Helvetica-Bold',
            spaceAfter=0,
            leading=44,
            leftIndent=0
        ))

        # Display 2 - Untertitel
        self.styles.add(ParagraphStyle(
            name='MD_Display2',
            fontSize=16,
            textColor=ACCENT,
            fontName='Helvetica',
            spaceAfter=3,
            leading=16
        ))

        # Headline - Große Überschriften
        self.styles.add(ParagraphStyle(
            name='MD_Headline',
            fontSize=18,
            textColor=PRIMARY,
            fontName='Helvetica-Bold',
            spaceAfter=8,
            spaceBefore=12,
            leading=20
        ))

        # Title - Medium Überschriften
        self.styles.add(ParagraphStyle(
            name='MD_Title',
            fontSize=14,
            textColor=TEXT_PRIMARY,
            fontName='Helvetica-Bold',
            spaceAfter=6,
            spaceBefore=8,
            leading=16
        ))

        # Subtitle - Kleine Überschriften
        self.styles.add(ParagraphStyle(
            name='MD_Subtitle',
            fontSize=14,
            textColor=TEXT_SECONDARY,
            fontName='Helvetica',
            spaceAfter=8,
            leading=16
        ))

        # Body 1 - Haupttext
        self.styles.add(ParagraphStyle(
            name='MD_Body1',
            fontSize=11,
            textColor=TEXT_PRIMARY,
            fontName='Helvetica',
            spaceAfter=6,
            leftIndent=0,
            leading=15
        ))

        # Body 2 - Sekundärtext
        self.styles.add(ParagraphStyle(
            name='MD_Body2',
            fontSize=10,
            textColor=TEXT_SECONDARY,
            fontName='Helvetica',
            spaceAfter=4,
            leftIndent=0,
            leading=13
        ))

        # Button - Hervorgehobener Text
        self.styles.add(ParagraphStyle(
            name='MD_Button',
            fontSize=12,
            textColor=PRIMARY,
            fontName='Helvetica-Bold',
            spaceAfter=0,
            leading=14
        ))

        # Caption - Kleine Labels
        self.styles.add(ParagraphStyle(
            name='MD_Caption',
            fontSize=8,
            textColor=TEXT_SECONDARY,
            fontName='Helvetica',
            spaceAfter=4,
            leading=9
        ))

        # Bullet Text
        self.styles.add(ParagraphStyle(
            name='MD_Bullet',
            fontSize=10,
            leftIndent=20,
            spaceAfter=2,
            fontName='Helvetica',
            textColor=TEXT_PRIMARY,
            leading=12
        ))

    def _draw_card_header(self, title):
        """Card-Header simpel"""
        data = [[
            Paragraph(title, self.styles['MD_Title'])
        ]]
        
        table = Table(data, colWidths=[19*cm])
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), SURFACE),
            ('TOPPADDING', (0, 0), (-1, -1), 0),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
            ('LEFTPADDING', (0, 0), (-1, -1), 0),
            ('RIGHTPADDING', (0, 0), (-1, -1), 0),
            ('BORDER', (0, 0), (-1, -1), 0),
        ]))
        return table

    def _create_card(self, content, color=PRIMARY_LIGHT):
        """Card-ähnliches Design mit Rahmen"""
        card = Table(content, colWidths=[19*cm])
        card.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), SURFACE),
            ('BORDER', (0, 0), (-1, -1), 1.5),
            ('BORDERCOLOR', (0, 0), (-1, -1), color),
            ('TOPPADDING', (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
            ('LEFTPADDING', (0, 0), (-1, -1), 12),
            ('RIGHTPADDING', (0, 0), (-1, -1), 12),
        ]))
        return card

    def _add_premium_header(self):
        """Premium Header mit Material Design"""
        # Blauer Hintergrund-Balken
        header_bg = Table([['']],colWidths=[19*cm], rowHeights=[0.08*cm])
        header_bg.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (0, 0), PRIMARY_DARK),
            ('BORDER', (0, 0), (0, 0), 0),
        ]))
        self.story.append(header_bg)
        self.story.append(Spacer(1, 0.3*cm))

        # Titel
        self.story.append(Paragraph(PROTOKOLL_DATA["titel"], self.styles['MD_Display1']))
        self.story.append(Paragraph(PROTOKOLL_DATA["subtitle"], self.styles['MD_Display2']))
        
        self.story.append(Spacer(1, 0.15*cm))

        # Zeitraum
        self.story.append(Paragraph(
            "19. - 26. Februar 2026",
            self.styles['MD_Body2']
        ))
        self.story.append(Spacer(1, 0.25*cm))

        # Metadaten Cards
        meta_content = [
            [
                Paragraph(f"<b>{PROTOKOLL_DATA['name']}</b><br/><font size=8 color='#757575'>Bearbeiter</font>", self.styles['MD_Body1']),
                Paragraph(f"<b>{PROTOKOLL_DATA['meilenstein']}</b><br/><font size=8 color='#757575'>Meilenstein</font>", self.styles['MD_Body1']),
                Paragraph(f"<b>Im Plan ✓</b><br/><font size=8 color='#757575'>Status</font>", self.styles['MD_Body1'])
            ]
        ]
        
        meta_table = Table(meta_content, colWidths=[6*cm, 6*cm, 6*cm])
        meta_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), PRIMARY_LIGHT),
            ('BORDER', (0, 0), (-1, -1), 1),
            ('BORDERCOLOR', (0, 0), (-1, -1), PRIMARY),
            ('TOPPADDING', (0, 0), (-1, -1), 12),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
            ('LEFTPADDING', (0, 0), (-1, -1), 12),
            ('RIGHTPADDING', (0, 0), (-1, -1), 12),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ]))
        
        self.story.append(meta_table)
        self.story.append(Spacer(1, 0.35*cm))

    def _add_section_card(self, section):
        """Abschnitt als Card"""
        # Card Header
        self.story.append(self._draw_card_header(section["titel"]))
        self.story.append(Spacer(1, 0.08*cm))

        # Bullet Points
        card_content = []
        for punkt in section["punkte"]:
            card_content.append([Paragraph(f"• {punkt}", self.styles['MD_Bullet'])])

        card = self._create_card(card_content)
        self.story.append(card)
        self.story.append(Spacer(1, 0.35*cm))

    def _add_ki_section(self):
        """KI Sektion mit modernem Design"""
        self.story.append(Spacer(1, 0.1*cm))
        self.story.append(Paragraph("🌟 KI-gestützte Lösungen", self.styles['MD_Headline']))
        self.story.append(Spacer(1, 0.15*cm))

        for i, ki_item in enumerate(PROTOKOLL_DATA["ki_section"]):
            if i > 0:
                self.story.append(Spacer(1, 0.2*cm))
            # Header
            self.story.append(self._draw_card_header(ki_item["titel"]))
            self.story.append(Spacer(1, 0.06*cm))

            # Items in Card
            card_content = []
            for item in ki_item['items']:
                card_content.append([Paragraph(f"• {item}", self.styles['MD_Bullet'])])

            card = self._create_card(card_content, PRIMARY_LIGHT)
            self.story.append(card)
            self.story.append(Spacer(1, 0.2*cm))

    def _add_footer(self):
        """Premium Footer"""
        self.story.append(Spacer(1, 0.2*cm))
        
        divider = Table([['']],colWidths=[19*cm], rowHeights=[0.03*cm])
        divider.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (0, 0), DIVIDER),
            ('BORDER', (0, 0), (0, 0), 0),
        ]))
        self.story.append(divider)
        self.story.append(Spacer(1, 0.12*cm))

        footer_text = f"VisionQuest Project · Wochenprotokoll · {PROTOKOLL_DATA['datum']}"
        self.story.append(Paragraph(footer_text, self.styles['MD_Caption']))

    def generate(self):
        """PDF mit Premium Design erstellen"""
        doc = SimpleDocTemplate(
            self.filename,
            pagesize=A4,
            rightMargin=1.5*cm,
            leftMargin=1.5*cm,
            topMargin=1.2*cm,
            bottomMargin=1.5*cm,
            title="Wochenprotokoll VisionQuest"
        )

        self._add_premium_header()
        for section in PROTOKOLL_DATA["items"]:
            self._add_section_card(section)
        self._add_ki_section()
        self._add_footer()

        doc.build(self.story)
        print(f"✅ Premium PDF erstellt: {self.filename}")


def main():
    python_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(python_dir)
    output_file = os.path.join(project_root, "Wochenprotokoll_26.02.2026.pdf")

    print("📄 Generiere Premium Wochenprotokoll...")
    pdf = PremiumWochenprotokollPDF(output_file)
    pdf.generate()
    print(f"📍 Datei: {output_file}")


if __name__ == "__main__":
    main()
