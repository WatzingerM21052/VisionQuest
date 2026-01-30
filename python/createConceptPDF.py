import matplotlib.pyplot as plt
import matplotlib.patches as patches
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

# --- 1. MOCKUP GENERATOR ---
def create_mockup_buffer(title, elements):
    fig, ax = plt.subplots(figsize=(4, 7.5)) 
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 180)
    ax.set_facecolor('white')
    
    rect = patches.Rectangle((2, 2), 96, 176, linewidth=1.5, edgecolor='#2c3e50', facecolor='#f8f9fa')
    ax.add_patch(rect)
    ax.add_patch(patches.Rectangle((35, 172), 30, 4, color='black', alpha=0.9))

    ax.text(50, 160, title, fontsize=10, ha='center', weight='bold', color='#34495e')
    
    for el in elements:
        etype = el.get('type')
        x, y, w, h = el.get('pos', (0,0,0,0))
        label = el.get('text', '')
        bg_col = el.get('color', '#e9ecef')
        
        if etype == 'rect':
            r = patches.Rectangle((x, y), w, h, linewidth=0.5, edgecolor='#ced4da', facecolor=bg_col)
            ax.add_patch(r)
            if label:
                ax.text(x + w/2, y + h/2, label, ha='center', va='center', fontsize=7, wrap=True, color='#212529')
        elif etype == 'circle':
            c = patches.Circle((x, y), w, linewidth=0.5, edgecolor='#ced4da', facecolor=bg_col)
            ax.add_patch(c)
            if label:
                ax.text(x, y, label, ha='center', va='center', fontsize=7, color='#212529')
        elif etype == 'text':
            ax.text(x, y, label, ha='center', va='center', fontsize=el.get('fontsize', 8), color='#495057')
            
    ax.plot([10, 90], [15, 15], color='#dee2e6', lw=1)
    ax.text(50, 8, "●", ha='center', fontsize=6, color='#adb5bd')

    plt.axis('off')
    buf = BytesIO()
    plt.savefig(buf, format='png', bbox_inches='tight', dpi=150)
    plt.close()
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
        "Implementierung von 5 Screens (Home, Scanner, Reward, History, Settings)",
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
        
        [Paragraph("bis 07.02.2026", style_td), 
         Paragraph("<b>Projekt-Init:</b><br/>• Git-Repo erstellt<br/>• Flutter Projekt 'skeleton' angelegt<br/>• Express Server läuft (Hello World)", style_td),
         Paragraph("Offen", style_td)],

        [Paragraph("bis 13.02.2026", style_td), 
         Paragraph("<b>Datenbank & API Basis:</b><br/>• DB Schema (Users, Quests) finalisiert<br/>• REST-Endpunkte definiert", style_td),
         Paragraph("Offen", style_td)],
         
        [Paragraph("bis 27.02.2026", style_td), 
         Paragraph("<b>Core Feature (Scanner):</b><br/>• Screen 'Scanner' mit Kamera-Stream läuft<br/>• Bildaufnahme und Upload an Backend funktioniert", style_td),
         Paragraph("Offen", style_td)],
         
        [Paragraph("bis 05.03.2026", style_td), 
         Paragraph("<b>UI & Navigation:</b><br/>• Alle 5 Screens als Layout implementiert<br/>• Navigation (Routing) funktioniert", style_td),
         Paragraph("Offen", style_td)],

        [Paragraph("bis 09.03.2026", style_td), 
         Paragraph("<b>Design & Logic:</b><br/>• Alle 5 Themes implementiert (Riverpod)<br/>• State Management Logik verknüpft", style_td),
         Paragraph("Offen", style_td)],
         
        [Paragraph("bis 13.03.2026", style_td), 
         Paragraph("<b>Finalisierung & Abgabe:</b><br/>• Animationen (Reward) eingebaut<br/>• Code Cleanup & Dokumentation<br/>• <b>Projekt-Abgabe</b>", style_td),
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
    story.append(Paragraph("Visualisierung der 5 Screens:", style_normal))
    story.append(Spacer(1, 4))

    # Mockups Images
    m1 = create_mockup_buffer("HOME", [
        {'type': 'rect', 'pos': (10, 100, 80, 40), 'text': 'Daily Quest:\nFinde Tasse', 'color': '#d1ecf1'},
        {'type': 'rect', 'pos': (10, 70, 80, 5), 'color': '#2ecc71'}, 
        {'type': 'text', 'pos': (50, 80, 0, 0), 'text': 'Level 5', 'fontsize': 8},
        {'type': 'rect', 'pos': (25, 30, 50, 15), 'text': 'START', 'color': '#3498db'}
    ])
    m2 = create_mockup_buffer("SCANNER", [
        {'type': 'rect', 'pos': (0, 30, 100, 120), 'text': '', 'color': '#343a40'},
        {'type': 'text', 'pos': (50, 120, 0, 0), 'text': '[ SUCHER ]', 'color': 'white'},
        {'type': 'circle', 'pos': (50, 40, 10, 0), 'text': '', 'color': 'white'}
    ])
    m3 = create_mockup_buffer("REWARD", [
        {'type': 'text', 'pos': (50, 130, 0, 0), 'text': 'SUCCESS!', 'fontsize': 12},
        {'type': 'circle', 'pos': (50, 95, 25, 0), 'text': '★', 'color': '#f1c40f'},
        {'type': 'text', 'pos': (50, 60, 0, 0), 'text': '+100 XP', 'fontsize': 12},
    ])
    m4 = create_mockup_buffer("HISTORY", [
        {'type': 'text', 'pos': (50, 140, 0, 0), 'text': 'Gallery', 'fontsize': 10},
        {'type': 'rect', 'pos': (10, 105, 35, 35), 'text': 'IMG', 'color': '#ced4da'},
        {'type': 'rect', 'pos': (55, 105, 35, 35), 'text': 'IMG', 'color': '#ced4da'},
        {'type': 'rect', 'pos': (10, 65, 35, 35), 'text': 'IMG', 'color': '#ced4da'},
    ])
    m5 = create_mockup_buffer("SETTINGS", [
        {'type': 'rect', 'pos': (10, 120, 80, 12), 'text': 'User Profile', 'color': 'white'},
        {'type': 'text', 'pos': (20, 105, 0, 0), 'text': 'Themes (5)', 'fontsize': 9},
        {'type': 'rect', 'pos': (10, 85, 22, 12), 'text': 'Light', 'color': '#fff'},
        {'type': 'rect', 'pos': (38, 85, 22, 12), 'text': 'Dark', 'color': '#333'},
        {'type': 'rect', 'pos': (66, 85, 22, 12), 'text': 'Retro', 'color': '#2ecc71'},
        {'type': 'rect', 'pos': (10, 68, 22, 12), 'text': 'Adv.', 'color': '#f39c12'},
    ])

    iw, ih = 85, 153
    i1, i2, i3, i4, i5 = [Image(m, width=iw, height=ih) for m in [m1, m2, m3, m4, m5]]

    t_imgs = Table([
        [i1, i2, i3],
        [Paragraph("Fig 1: Home", style_normal), Paragraph("Fig 2: Scanner", style_normal), Paragraph("Fig 3: Reward", style_normal)],
        [i4, i5, ""],
        [Paragraph("Fig 4: History", style_normal), Paragraph("Fig 5: Settings", style_normal), ""]
    ], colWidths=[120, 120, 120])
    
    t_imgs.setStyle(TableStyle([
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('TOPPADDING', (0,1), (-1,1), 1),
        ('BOTTOMPADDING', (0,1), (-1,1), 8),
    ]))
    story.append(t_imgs)
    doc.build(story)
    print(f"PDF '{filename}' erfolgreich erstellt!")

if __name__ == "__main__":
    create_pdf(f"Projektkonzept_{PROJECT_NAME}_{STUDENT_NAME}.pdf")