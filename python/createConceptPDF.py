from PIL import Image as PILImage, ImageDraw, ImageFont
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, PageBreak
from io import BytesIO

# --- KONFIGURATION ---
STUDENT_NAME = "Matthias"
SUBJECT = "WMC" 
PROJECT_NAME = "VisionQuest"
DEADLINE_FINAL = "13.03.2026"

# --- 1. MOCKUP GENERATOR (PIL-basiert für besseres Design) ---
def create_mockup_buffer(title, elements):
    """Erstellt mobile App-Mockups mit Pillow mit verbessertem Layout"""
    WIDTH, HEIGHT = 300, 560
    bg_color = (248, 249, 250)
    img = PILImage.new('RGB', (WIDTH, HEIGHT), bg_color)
    draw = ImageDraw.Draw(img)
    
    # Fonts laden (fallback auf default)
    try:
        font_header = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 15)
        font_normal = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 11)
        font_small = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 9)
        font_tiny = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 7)
    except:
        font_header = font_normal = font_small = font_tiny = ImageFont.load_default()

    # Rahmenborder mit Schatten-Effekt
    draw.rectangle([2, 2, WIDTH-2, HEIGHT-2], outline=(100, 100, 100), width=1)
    draw.rectangle([4, 4, WIDTH-4, HEIGHT-4], outline=(200, 200, 200), width=1)
    
    # Status bar mit Größe
    draw.rectangle([0, 545, WIDTH, 560], fill=(51, 51, 51))

    # Header bar mit Titel - Gradient-Effekt durch dunkleres Blau
    hex_to_rgb = lambda h: tuple(int(h.lstrip('#')[i:i+2], 16) for i in (0, 2, 4))
    draw.rectangle([0, 0, WIDTH, 50], fill=hex_to_rgb('#2980b9'))
    # Unterline für Header
    draw.rectangle([0, 47, WIDTH, 50], fill=hex_to_rgb('#1f618d'))
    draw.text((WIDTH//2, 25), title, font=font_header, fill=(255, 255, 255), anchor='mm')

    # Elemente zeichnen - mit Boundary-Checking
    for el in elements:
        etype = el.get('type')
        x, y, w, h = el.get('pos', (0, 0, 0, 0))
        text = el.get('text', '')
        color = el.get('color', '#e9ecef')
        text_color = el.get('text_color', '#212529')
        fontsize_name = el.get('fontsize', 'normal')
        align = el.get('align', 'center')
        
        if fontsize_name == 'small': 
            font_use = font_small
        elif fontsize_name == 'tiny': 
            font_use = font_tiny
        else: 
            font_use = font_normal

        if etype == 'rect':
            # Boundary check - bleibe im Fenster
            x_end = min(x + w, WIDTH - 2)
            y_end = min(y + h, 540)
            x = max(x, 2)
            y = max(y, 50)
            
            if x_end > x and y_end > y:
                draw.rectangle([x, y, x_end, y_end], fill=hex_to_rgb(color), outline=hex_to_rgb('#d0d0d0'), width=1)
                
                # Text im Rechteck
                if text:
                    text_color_rgb = hex_to_rgb(text_color)
                    if align == 'left':
                        text_x = x + 10
                        anchor = 'lm'
                    else:  # center
                        text_x = x + (x_end - x) // 2
                        anchor = 'mm'
                    text_y = y + (y_end - y) // 2
                    draw.text((text_x, text_y), text, font=font_use, fill=text_color_rgb, anchor=anchor)

        elif etype == 'text':
            # Text - mit Boundary check
            y = max(y, 50)
            y = min(y, 540)
            text_color_rgb = hex_to_rgb(text_color)
            if align == 'left':
                x = max(x, 5)
                draw.text((x, y), text, font=font_use, fill=text_color_rgb, anchor='lm')
            elif align == 'right':
                x = min(x, WIDTH - 5)
                draw.text((x, y), text, font=font_use, fill=text_color_rgb, anchor='rm')
            else:  # center
                draw.text((x, y), text, font=font_use, fill=text_color_rgb, anchor='mm')

        elif etype == 'bar':
            # Progress-Bar Hintergrund - mit Boundary check
            x_end = min(x + w, WIDTH - 2)
            y_end = min(y + h, 540)
            x = max(x, 2)
            y = max(y, 50)
            
            if x_end > x and y_end > y:
                draw.rectangle([x, y, x_end, y_end], fill=hex_to_rgb('#ecf0f1'), outline=hex_to_rgb('#bdc3c7'), width=1)
                # Gefüllter Teil
                filled_w = int((x_end - x) * el.get('percentage', 0.6))
                if filled_w > 0:
                    draw.rectangle([x, y, x + filled_w, y_end], fill=hex_to_rgb(color))

    buf = BytesIO()
    img.save(buf, format='PNG', quality=95)
    buf.seek(0)
    return buf

# --- 2. PDF ERSTELLUNG ---
def create_pdf(filename):
    doc = SimpleDocTemplate(filename, pagesize=A4, rightMargin=40, leftMargin=40, topMargin=40, bottomMargin=40)
    styles = getSampleStyleSheet()
    story = []

    # Styles
    style_title = ParagraphStyle('MainTitle', parent=styles['Title'], fontSize=20, spaceAfter=6, textColor=colors.HexColor("#2c3e50"), alignment=0)
    style_h1 = ParagraphStyle('MyH1', parent=styles['Heading1'], fontSize=13, spaceBefore=10, spaceAfter=4, textColor=colors.HexColor("#2980b9"), borderPadding=0)
    style_sub_h = ParagraphStyle('SubHeader', parent=styles['Heading2'], fontSize=10, spaceBefore=6, spaceAfter=2, textColor=colors.HexColor("#34495e"))
    style_normal = ParagraphStyle('MyNormal', parent=styles['BodyText'], fontSize=9, leading=12, spaceAfter=4, alignment=4) 
    style_bullet = ParagraphStyle('MyBullet', parent=styles['BodyText'], fontSize=9, leading=12, leftIndent=15, spaceAfter=1)
    style_th = ParagraphStyle('TableHeader', parent=styles['BodyText'], fontSize=9, textColor=colors.white, alignment=1, fontName='Helvetica-Bold')
    style_td = ParagraphStyle('TableData', parent=styles['BodyText'], fontSize=9, leading=11, alignment=0)
    
    # --- HEADER ---
    header_data = [
        [Paragraph(f"PROJEKTKONZEPT:<br/>{PROJECT_NAME}", style_title), 
         Paragraph(f"<b>Entwickler:</b> {STUDENT_NAME}<br/><b>Fach:</b> {SUBJECT}<br/><b>Abgabe:</b> {DEADLINE_FINAL}", style_td)]
    ]
    t_header = Table(header_data, colWidths=[350, 160])
    t_header.setStyle(TableStyle([('VALIGN', (0,0), (-1,-1), 'TOP')]))
    story.append(t_header)
    story.append(Spacer(1, 6))
    story.append(Paragraph("_" * 85, style_normal)) 

    # --- 1. BESCHREIBUNG ---
    story.append(Paragraph("1. Projektbeschreibung", style_h1))
    text_desc = """
    <b>VisionQuest</b> ist eine gamifizierte Mobile-App, die Computer Vision nutzt, um die Interaktion mit der realen Welt spielerisch zu gestalten. 
    Der Nutzer erhält "Quests", bestimmte Objekte in seiner Umgebung zu finden. Die Kamera analysiert das Bild, validiert den Fund und 
    belohnt den Nutzer mit Erfahrungspunkten und Level-Aufstiegen.
    """
    story.append(Paragraph(text_desc, style_normal))

    # --- 2. TECHNISCHER UMFANG (Neue Struktur) ---
    story.append(Paragraph("2. Technischer Umfang & KI-Einsatz", style_h1))
    story.append(Paragraph("Das Projekt wird mit KI-Unterstützung (LLMs) entwickelt. Daraus ergeben sich folgende erweiterte Anforderungen:", style_normal))
    
    # Frontend Section
    story.append(Paragraph("Frontend (Flutter App)", style_sub_h))
    frontend_pts = [
        "Implementierung von 6 Screens (Login, Home, Scanner, Reward, History, Settings)",
        "Login/Registrierung mit validierten Formularen",
        "5 Themes inklusive Light, Dark, System, Retro (Pixel-Art) und Adventure",
        "Einsatz von Riverpod für globales State Management",
        "Animationen (Rive/Lottie) für Belohnungseffekte"
    ]
    for p in frontend_pts: story.append(Paragraph(f"• {p}", style_bullet))

    # Backend Section
    story.append(Paragraph("Backend (Server & API)", style_sub_h))
    backend_pts = [
        "Node.js Express REST-API zur Verarbeitung der Client-Anfragen",
        "Integration von Bildverarbeitungs-Logik"
    ]
    for p in backend_pts: story.append(Paragraph(f"• {p}", style_bullet))

    # Data Section
    story.append(Paragraph("Datenhaltung & Persistenz", style_sub_h))
    data_pts = [
        "Relationale Datenbank (SQLite) mit mind. 2 Tabellen (Users, Quests)",
        "Persistente Speicherung von User-Settings mittels Shared Preferences",
        "Verwendung des Camera-Packages für direkten Stream-Zugriff"
    ]
    for p in data_pts: story.append(Paragraph(f"• {p}", style_bullet))

    # --- 3. MEILENSTEINE (Granular & "bis") ---
    story.append(Paragraph("3. Meilenstein-Plan", style_h1))
    
    h_date = Paragraph("Deadline (Bis)", style_th)
    h_todo = Paragraph("Geplante Arbeitspakete / Funktionalität", style_th)
    h_stat = Paragraph("Status", style_th)

    ms_data = [
        [h_date, h_todo, h_stat],
        
        [Paragraph("bis 10.02.2026", style_td), 
         Paragraph("<b>Projektplanung:</b><br/>• Git-Repository erstellen<br/>• Projektkonzept & Mockups finalisieren<br/>• Dev-Umgebung konfigurieren", style_td),
         Paragraph("Offen", style_td)],

        [Paragraph("bis 27.02.2026", style_td), 
         Paragraph("<b>Projekt-Init:</b><br/>• Flutter Projekt-Struktur aufbauen<br/>• Express-Server Boilerplate<br/>• Frontend-Backend Verbindung funktioniert", style_td),
         Paragraph("Offen", style_td)],

        [Paragraph("bis 02.03.2026", style_td), 
         Paragraph("<b>Datenbank & API:</b><br/>• SQLite Schema (Users, Quests)<br/>• CRUD-Operationen implementieren<br/>• REST-Endpunkte definieren", style_td),
         Paragraph("Offen", style_td)],

        [Paragraph("bis 04.03.2026", style_td), 
         Paragraph("<b>Authentication:</b><br/>• Login & Registrierung UI<br/>• JWT-basierte Auth implementieren<br/>• Session-Verwaltung & Error-Handling", style_td),
         Paragraph("Offen", style_td)],
         
        [Paragraph("bis 06.03.2026", style_td), 
         Paragraph("<b>Scanner & Computer Vision:</b><br/>• Camera-Integration & Live-Preview<br/>• Bildaufnahme & Upload an Backend<br/>• Objekt-Erkennung starten", style_td),
         Paragraph("Offen", style_td)],
         
        [Paragraph("bis 09.03.2026", style_td), 
         Paragraph("<b>UI & Navigation:</b><br/>• Alle 6 Screens implementieren<br/>• Routing & Navigation verbinden<br/>• Responsive Layouts", style_td),
         Paragraph("Offen", style_td)],

        [Paragraph("bis 11.03.2026", style_td), 
         Paragraph("<b>State & Theme:</b><br/>• Riverpod State Management<br/>• 5 Themes implementieren<br/>• Quest-Logik (XP, Level, Streak)", style_td),
         Paragraph("Offen", style_td)],
         
        [Paragraph("bis 13.03.2026", style_td), 
         Paragraph("<b>Finalisierung & Abgabe:</b><br/>• Animationen (Rive/Lottie) einbauen<br/>• Code Cleanup & Dokumentation<br/>• <b>Projekt-Abgabe</b>", style_td),
         Paragraph("Offen", style_td)],
    ]
    
    t_ms = Table(ms_data, colWidths=[90, 370, 50])
    t_ms.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#2c3e50")), 
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#bdc3c7")),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#f1f3f5")]),
        ('LEFTPADDING', (0,0), (-1,-1), 4),
        ('RIGHTPADDING', (0,0), (-1,-1), 4),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
    ]))
    story.append(t_ms)

    # --- 4. MOCKUPS ---
    story.append(Paragraph("4. Mockups (UI Skizzen)", style_h1))
    story.append(Paragraph("Visualisierung der 6 Screens:", style_normal))
    story.append(Spacer(1, 4))

    # Mockups Images mit verbessertem PIL-Design
    m0 = create_mockup_buffer("LOGIN", [
        {'type': 'rect', 'pos': (90, 80, 120, 120), 'color': '#ecf0f1'},
        {'type': 'text', 'pos': (150, 140, 0, 0), 'text': 'VQ', 'fontsize': 'normal', 'text_color': '#2980b9'},
        {'type': 'text', 'pos': (150, 220, 0, 0), 'text': 'Willkommen bei VisionQuest', 'fontsize': 'small', 'text_color': '#2c3e50'},
        {'type': 'text', 'pos': (40, 260, 0, 0), 'text': 'E-Mail', 'fontsize': 'tiny', 'text_color': '#7f8c8d', 'align': 'left'},
        {'type': 'rect', 'pos': (30, 275, 240, 40), 'color': '#ffffff'},
        {'type': 'text', 'pos': (45, 295, 0, 0), 'text': 'matthias@visionquest.app', 'fontsize': 'tiny', 'text_color': '#34495e', 'align': 'left'},
        {'type': 'text', 'pos': (40, 330, 0, 0), 'text': 'Passwort', 'fontsize': 'tiny', 'text_color': '#7f8c8d', 'align': 'left'},
        {'type': 'rect', 'pos': (30, 345, 240, 40), 'color': '#ffffff'},
        {'type': 'text', 'pos': (45, 365, 0, 0), 'text': '* * * * * * * *', 'fontsize': 'tiny', 'text_color': '#34495e', 'align': 'left'},
        {'type': 'rect', 'pos': (60, 410, 180, 45), 'color': '#27ae60', 'text': 'ANMELDEN', 'text_color': '#ffffff'},
        {'type': 'text', 'pos': (150, 480, 0, 0), 'text': 'Noch kein Konto?', 'fontsize': 'tiny', 'text_color': '#7f8c8d'},
        {'type': 'text', 'pos': (150, 500, 0, 0), 'text': 'Jetzt registrieren', 'fontsize': 'tiny', 'text_color': '#2980b9'},
    ])
    m1 = create_mockup_buffer("HOME", [
        {'type': 'text', 'pos': (40, 65, 0, 0), 'text': 'Hallo, Matthias!', 'fontsize': 'normal', 'text_color': '#ffffff', 'align': 'left'},
        {'type': 'rect', 'pos': (235, 58, 50, 22), 'color': '#f39c12'},
        {'type': 'text', 'pos': (260, 69, 0, 0), 'text': 'Lvl 5', 'fontsize': 'tiny', 'text_color': '#ffffff'},
        {'type': 'text', 'pos': (40, 95, 0, 0), 'text': '1200 / 2000 XP', 'fontsize': 'tiny', 'text_color': '#ecf0f1', 'align': 'left'},
        {'type': 'bar', 'pos': (30, 108, 240, 12), 'color': '#f39c12', 'percentage': 0.6},
        {'type': 'text', 'pos': (30, 145, 0, 0), 'text': 'Taegliche Quest', 'fontsize': 'small', 'text_color': '#2c3e50', 'align': 'left'},
        {'type': 'rect', 'pos': (25, 165, 250, 100), 'color': '#ffffff'},
        {'type': 'rect', 'pos': (35, 175, 60, 60), 'color': '#d1ecf1'},
        {'type': 'text', 'pos': (65, 205, 0, 0), 'text': '[CUP]', 'fontsize': 'tiny', 'text_color': '#7f8c8d'},
        {'type': 'text', 'pos': (110, 185, 0, 0), 'text': 'Finde eine Tasse', 'fontsize': 'small', 'text_color': '#2c3e50', 'align': 'left'},
        {'type': 'text', 'pos': (110, 210, 0, 0), 'text': '+50 XP  |  Schwierigkeit: *', 'fontsize': 'tiny', 'text_color': '#7f8c8d', 'align': 'left'},
        {'type': 'rect', 'pos': (220, 172, 40, 18), 'color': '#27ae60'},
        {'type': 'text', 'pos': (240, 181, 0, 0), 'text': 'NEU', 'fontsize': 'tiny', 'text_color': '#ffffff'},
        {'type': 'rect', 'pos': (60, 295, 180, 48), 'color': '#27ae60', 'text': 'QUEST STARTEN', 'text_color': '#ffffff'},
        {'type': 'text', 'pos': (30, 370, 0, 0), 'text': 'Wochenfortschritt', 'fontsize': 'small', 'text_color': '#2c3e50', 'align': 'left'},
        {'type': 'rect', 'pos': (25, 390, 250, 65), 'color': '#ffffff'},
        {'type': 'text', 'pos': (40, 410, 0, 0), 'text': '3 / 7 Quests abgeschlossen', 'fontsize': 'tiny', 'text_color': '#7f8c8d', 'align': 'left'},
        {'type': 'bar', 'pos': (35, 425, 230, 8), 'color': '#3498db', 'percentage': 0.43},
    ])
    m2 = create_mockup_buffer("SCANNER", [
        {'type': 'text', 'pos': (150, 65, 0, 0), 'text': 'Suche: Tasse', 'fontsize': 'normal', 'text_color': '#ffffff'},
        {'type': 'rect', 'pos': (20, 95, 260, 310), 'color': '#1a1a1a'},
        {'type': 'rect', 'pos': (80, 180, 140, 140), 'color': '#2c3e50'},
        {'type': 'text', 'pos': (150, 200, 0, 0), 'text': '+', 'fontsize': 'normal', 'text_color': '#27ae60'},
        {'type': 'text', 'pos': (90, 250, 0, 0), 'text': '-', 'fontsize': 'small', 'text_color': '#27ae60', 'align': 'left'},
        {'type': 'text', 'pos': (210, 250, 0, 0), 'text': '-', 'fontsize': 'small', 'text_color': '#27ae60', 'align': 'right'},
        {'type': 'text', 'pos': (150, 210, 0, 0), 'text': '|', 'fontsize': 'normal', 'text_color': '#27ae60'},
        {'type': 'text', 'pos': (150, 290, 0, 0), 'text': '|', 'fontsize': 'normal', 'text_color': '#27ae60'},
        {'type': 'rect', 'pos': (40, 420, 220, 40), 'color': '#ffffff'},
        {'type': 'text', 'pos': (150, 430, 0, 0), 'text': 'Erkennung...', 'fontsize': 'tiny', 'text_color': '#7f8c8d'},
        {'type': 'bar', 'pos': (50, 445, 200, 8), 'color': '#27ae60', 'percentage': 0.75},
        {'type': 'text', 'pos': (150, 468, 0, 0), 'text': 'Konfidenz: 75%', 'fontsize': 'tiny', 'text_color': '#27ae60'},
        {'type': 'rect', 'pos': (115, 485, 70, 35), 'color': '#3498db', 'text': 'SCAN', 'text_color': '#ffffff'},
    ])
    m3 = create_mockup_buffer("REWARD", [
        {'type': 'text', 'pos': (100, 75, 0, 0), 'text': '*', 'fontsize': 'normal', 'text_color': '#f39c12'},
        {'type': 'text', 'pos': (200, 90, 0, 0), 'text': '*', 'fontsize': 'small', 'text_color': '#f39c12'},
        {'type': 'text', 'pos': (80, 110, 0, 0), 'text': '*', 'fontsize': 'tiny', 'text_color': '#f39c12'},
        {'type': 'rect', 'pos': (100, 140, 100, 100), 'color': '#fff3cd'},
        {'type': 'text', 'pos': (150, 190, 0, 0), 'text': '[TROPHY]', 'fontsize': 'small', 'text_color': '#f39c12'},
        {'type': 'text', 'pos': (150, 260, 0, 0), 'text': 'Quest abgeschlossen!', 'fontsize': 'small', 'text_color': '#27ae60'},
        {'type': 'text', 'pos': (150, 290, 0, 0), 'text': '+100 XP', 'fontsize': 'normal', 'text_color': '#27ae60'},
        {'type': 'rect', 'pos': (230, 280, 50, 22), 'color': '#e74c3c'},
        {'type': 'text', 'pos': (255, 291, 0, 0), 'text': 'x2', 'fontsize': 'tiny', 'text_color': '#ffffff'},
        {'type': 'rect', 'pos': (75, 330, 150, 50), 'color': '#f39c12'},
        {'type': 'text', 'pos': (150, 345, 0, 0), 'text': 'LEVEL UP!', 'fontsize': 'small', 'text_color': '#ffffff'},
        {'type': 'text', 'pos': (150, 365, 0, 0), 'text': 'Du bist jetzt Level 6', 'fontsize': 'tiny', 'text_color': '#ffffff'},
        {'type': 'text', 'pos': (150, 410, 0, 0), 'text': 'Neue Quests freigeschaltet!', 'fontsize': 'tiny', 'text_color': '#7f8c8d'},
        {'type': 'rect', 'pos': (65, 450, 170, 45), 'color': '#3498db', 'text': 'WEITER', 'text_color': '#ffffff'},
    ])
    m4 = create_mockup_buffer("HISTORY", [
        {'type': 'text', 'pos': (40, 65, 0, 0), 'text': 'Erfolge', 'fontsize': 'normal', 'text_color': '#ffffff', 'align': 'left'},
        {'type': 'text', 'pos': (260, 65, 0, 0), 'text': '12', 'fontsize': 'normal', 'text_color': '#f39c12', 'align': 'right'},
        {'type': 'rect', 'pos': (20, 100, 80, 90), 'color': '#ffffff'},
        {'type': 'rect', 'pos': (25, 105, 70, 70), 'color': '#d1ecf1'},
        {'type': 'text', 'pos': (60, 140, 0, 0), 'text': '[CUP]', 'fontsize': 'tiny', 'text_color': '#7f8c8d'},
        {'type': 'text', 'pos': (60, 180, 0, 0), 'text': 'Tasse', 'fontsize': 'tiny', 'text_color': '#2c3e50'},
        {'type': 'text', 'pos': (60, 193, 0, 0), 'text': '08.02', 'fontsize': 'tiny', 'text_color': '#95a5a6'},
        {'type': 'rect', 'pos': (110, 100, 80, 90), 'color': '#ffffff'},
        {'type': 'rect', 'pos': (115, 105, 70, 70), 'color': '#d1ecf1'},
        {'type': 'text', 'pos': (150, 140, 0, 0), 'text': '[CHAIR]', 'fontsize': 'tiny', 'text_color': '#7f8c8d'},
        {'type': 'text', 'pos': (150, 180, 0, 0), 'text': 'Stuhl', 'fontsize': 'tiny', 'text_color': '#2c3e50'},
        {'type': 'text', 'pos': (150, 193, 0, 0), 'text': '07.02', 'fontsize': 'tiny', 'text_color': '#95a5a6'},
        {'type': 'rect', 'pos': (200, 100, 80, 90), 'color': '#ffffff'},
        {'type': 'rect', 'pos': (205, 105, 70, 70), 'color': '#d1ecf1'},
        {'type': 'text', 'pos': (240, 140, 0, 0), 'text': '[BOOK]', 'fontsize': 'tiny', 'text_color': '#7f8c8d'},
        {'type': 'text', 'pos': (240, 180, 0, 0), 'text': 'Buch', 'fontsize': 'tiny', 'text_color': '#2c3e50'},
        {'type': 'text', 'pos': (240, 193, 0, 0), 'text': '06.02', 'fontsize': 'tiny', 'text_color': '#95a5a6'},
        {'type': 'rect', 'pos': (25, 220, 250, 70), 'color': '#ffffff'},
        {'type': 'text', 'pos': (40, 238, 0, 0), 'text': 'Statistik', 'fontsize': 'small', 'text_color': '#2c3e50', 'align': 'left'},
        {'type': 'text', 'pos': (40, 258, 0, 0), 'text': 'Gesamt XP:', 'fontsize': 'tiny', 'text_color': '#7f8c8d', 'align': 'left'},
        {'type': 'text', 'pos': (260, 258, 0, 0), 'text': '1650', 'fontsize': 'tiny', 'text_color': '#f39c12', 'align': 'right'},
        {'type': 'text', 'pos': (40, 275, 0, 0), 'text': 'Streak:', 'fontsize': 'tiny', 'text_color': '#7f8c8d', 'align': 'left'},
        {'type': 'text', 'pos': (260, 275, 0, 0), 'text': '5 Tage', 'fontsize': 'tiny', 'text_color': '#e74c3c', 'align': 'right'},
    ])
    m5 = create_mockup_buffer("SETTINGS", [
        {'type': 'text', 'pos': (150, 65, 0, 0), 'text': 'Einstellungen', 'fontsize': 'normal', 'text_color': '#ffffff'},
        {'type': 'text', 'pos': (30, 95, 0, 0), 'text': 'Konto', 'fontsize': 'tiny', 'text_color': '#7f8c8d', 'align': 'left'},
        {'type': 'rect', 'pos': (25, 110, 250, 45), 'color': '#ffffff'},
        {'type': 'text', 'pos': (40, 132, 0, 0), 'text': 'Profil bearbeiten', 'fontsize': 'small', 'text_color': '#2c3e50', 'align': 'left'},
        {'type': 'text', 'pos': (265, 132, 0, 0), 'text': '>', 'fontsize': 'normal', 'text_color': '#bdc3c7', 'align': 'right'},
        {'type': 'text', 'pos': (30, 170, 0, 0), 'text': 'App-Einstellungen', 'fontsize': 'tiny', 'text_color': '#7f8c8d', 'align': 'left'},
        {'type': 'rect', 'pos': (25, 185, 250, 45), 'color': '#ffffff'},
        {'type': 'text', 'pos': (40, 207, 0, 0), 'text': 'Theme', 'fontsize': 'small', 'text_color': '#2c3e50', 'align': 'left'},
        {'type': 'text', 'pos': (235, 207, 0, 0), 'text': 'Dark', 'fontsize': 'tiny', 'text_color': '#7f8c8d', 'align': 'right'},
        {'type': 'text', 'pos': (265, 207, 0, 0), 'text': '>', 'fontsize': 'normal', 'text_color': '#bdc3c7', 'align': 'right'},
        {'type': 'rect', 'pos': (25, 238, 250, 45), 'color': '#ffffff'},
        {'type': 'text', 'pos': (40, 260, 0, 0), 'text': 'Sprache', 'fontsize': 'small', 'text_color': '#2c3e50', 'align': 'left'},
        {'type': 'text', 'pos': (225, 260, 0, 0), 'text': 'Deutsch', 'fontsize': 'tiny', 'text_color': '#7f8c8d', 'align': 'right'},
        {'type': 'text', 'pos': (265, 260, 0, 0), 'text': '>', 'fontsize': 'normal', 'text_color': '#bdc3c7', 'align': 'right'},
        {'type': 'rect', 'pos': (25, 291, 250, 45), 'color': '#ffffff'},
        {'type': 'text', 'pos': (40, 313, 0, 0), 'text': 'Benachrichtigungen', 'fontsize': 'small', 'text_color': '#2c3e50', 'align': 'left'},
        {'type': 'rect', 'pos': (248, 303, 30, 20), 'color': '#27ae60'},
        {'type': 'rect', 'pos': (260, 306, 14, 14), 'color': '#ffffff'},
        {'type': 'text', 'pos': (30, 355, 0, 0), 'text': 'Datenschutz', 'fontsize': 'tiny', 'text_color': '#7f8c8d', 'align': 'left'},
        {'type': 'rect', 'pos': (25, 370, 250, 45), 'color': '#ffffff'},
        {'type': 'text', 'pos': (40, 392, 0, 0), 'text': 'Daten loeschen', 'fontsize': 'small', 'text_color': '#e74c3c', 'align': 'left'},
        {'type': 'text', 'pos': (265, 392, 0, 0), 'text': '>', 'fontsize': 'normal', 'text_color': '#bdc3c7', 'align': 'right'},
        {'type': 'rect', 'pos': (60, 450, 180, 45), 'color': '#e74c3c', 'text': 'ABMELDEN', 'text_color': '#ffffff'},
    ])

    iw, ih = 105, 197
    i0, i1, i2, i3, i4, i5 = [Image(m, width=iw, height=ih) for m in [m0, m1, m2, m3, m4, m5]]

    t_imgs = Table([
        [i0, i1, i2],
        [Paragraph("Fig 1: Login", style_normal), Paragraph("Fig 2: Home", style_normal), Paragraph("Fig 3: Scanner", style_normal)],
        [i3, i4, i5],
        [Paragraph("Fig 4: Reward", style_normal), Paragraph("Fig 5: History", style_normal), Paragraph("Fig 6: Settings", style_normal)]
    ], colWidths=[140, 140, 140])
    
    t_imgs.setStyle(TableStyle([
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('TOPPADDING', (0,1), (-1,1), 2),
        ('BOTTOMPADDING', (0,1), (-1,1), 10),
    ]))
    story.append(t_imgs)
    doc.build(story)
    print(f"PDF '{filename}' erfolgreich erstellt!")

if __name__ == "__main__":
    create_pdf(f"Projektkonzept_{PROJECT_NAME}_{STUDENT_NAME}.pdf")
