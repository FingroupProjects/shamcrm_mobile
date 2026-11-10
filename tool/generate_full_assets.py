import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT_DIR = "shamcrm-website/assets/screenshots"
os.makedirs(OUT_DIR, exist_ok=True)
W, H = 1284, 2778

def get_font(size, bold=False):
    style = "Bold" if bold else "Regular"
    paths = [
        f"assets/fonts/San Francisco Pro Display/SF-Pro-Display-{style}.otf",
        f"assets/fonts/Gilroy-{style}.ttf",
        "/System/Library/Fonts/SFProDisplay-" + ("Bold" if bold else "Regular") + ".otf",
        "/System/Library/Fonts/HelveticaNeue.ttc"
    ]
    for p in paths:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, int(size))
            except:
                pass
    return ImageFont.load_default()

def draw_status_bar(draw, dark=True):
    fg = (255, 255, 255) if dark else (20, 20, 20)
    font = get_font(44, bold=True)
    draw.text((105, 52), "14:15", fill=fg, font=font)
    bx, by = 1120, 58
    draw.rounded_rectangle([bx, by, bx + 65, by + 32], radius=8, outline=fg, width=4)
    draw.rectangle([bx + 4, by + 4, bx + 50, by + 28], fill=fg)
    draw.rectangle([bx + 67, by + 10, bx + 70, by + 22], fill=fg)
    wx, wy = 1050, 72
    draw.arc([wx - 25, wy - 25, wx + 25, wy + 25], start=210, end=330, fill=fg, width=4)
    draw.arc([wx - 16, wy - 16, wx + 16, wy + 16], start=210, end=330, fill=fg, width=4)
    draw.ellipse([wx - 4, wy + 4, wx + 4, wy + 12], fill=fg)

def draw_bottom_nav(draw, active_idx=1):
    nav_y = H - 250
    draw.rounded_rectangle([45, nav_y, W - 45, nav_y + 160], radius=48, fill=(16, 24, 45, 245), outline=(42, 60, 102), width=2)
    tabs = ["Дашборд", "Шахматка", "Задачи", "Лиды", "Сделки"]
    font_active = get_font(28, bold=True)
    font_inactive = get_font(26, bold=False)
    item_w = (W - 90) // len(tabs)
    for i, name in enumerate(tabs):
        cx = 45 + i * item_w + item_w // 2
        is_active = (i == active_idx)
        if is_active:
            draw.rounded_rectangle([cx - 95, nav_y + 18, cx + 95, nav_y + 142], radius=36, fill=(0, 163, 255, 240))
            draw.ellipse([cx - 24, nav_y + 34, cx + 24, nav_y + 82], fill=(255, 255, 255, 210))
            draw.text((cx, nav_y + 115), name, fill=(255, 255, 255), font=font_active, anchor="ms")
        else:
            text_color = (130, 145, 175)
            draw.ellipse([cx - 20, nav_y + 40, cx + 20, nav_y + 80], outline=text_color, width=3)
            draw.text((cx, nav_y + 115), name, fill=text_color, font=font_inactive, anchor="ms")

def create_base_canvas():
    im = Image.new("RGBA", (W, H), (10, 15, 28, 255))
    draw = ImageDraw.Draw(im)
    # Background subtle nebula gradients
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ov_draw = ImageDraw.Draw(overlay)
    ov_draw.ellipse([-200, -200, 700, 700], fill=(24, 60, 150, 40))
    ov_draw.ellipse([W - 600, 400, W + 400, 1400], fill=(80, 20, 140, 30))
    ov_draw.ellipse([100, 1200, 900, 2000], fill=(0, 120, 180, 25))
    overlay = overlay.filter(ImageFilter.GaussianBlur(100))
    im = Image.alpha_composite(im, overlay)
    return im

# 1. CHESS GRID SCREEN
def generate_chess_grid():
    im = create_base_canvas()
    draw = ImageDraw.Draw(im)
    draw_status_bar(draw)

    # Header
    font_h1 = get_font(46, bold=True)
    font_sub = get_font(30, bold=False)
    draw.rounded_rectangle([50, 140, 170, 260], radius=32, fill=(24, 34, 62), outline=(45, 62, 105), width=2)
    # Back chevron
    draw.line([120, 185, 100, 200], fill=(255, 255, 255), width=4)
    draw.line([100, 200, 120, 215], fill=(255, 255, 255), width=4)

    # Title & Complex name
    draw.text((195, 152), "ЖК Mirabad Avenue", fill=(255, 255, 255), font=font_h1)
    draw.text((195, 212), "Блок А · 16 этажей · 128 квартир", fill=(140, 158, 195), font=font_sub)

    # 3D Button & Filter
    draw.rounded_rectangle([W - 270, 150, W - 150, 250], radius=28, fill=(0, 163, 255, 30), outline=(0, 163, 255), width=2)
    draw.text((W - 210, 200), "3D", fill=(0, 180, 255), font=get_font(36, bold=True), anchor="mm")
    
    draw.rounded_rectangle([W - 130, 150, W - 50, 250], radius=28, fill=(24, 34, 62), outline=(45, 62, 105), width=2)
    draw.ellipse([W - 95, 185, W - 85, 195], fill=(255, 255, 255))
    draw.ellipse([W - 95, 205, W - 85, 215], fill=(255, 255, 255))

    # Status KPI Pills
    pills_y = 285
    pills = [
        ("Свободно", "48", (46, 158, 99)),
        ("Бронь", "18", (226, 168, 28)),
        ("Резерв", "8", (37, 99, 235)),
        ("Продано", "54", (208, 70, 60)),
    ]
    pill_w = (W - 100 - 45) // 4
    for i, (label, count, color) in enumerate(pills):
        px = 50 + i * (pill_w + 15)
        draw.rounded_rectangle([px, pills_y, px + pill_w, pills_y + 110], radius=24, fill=(18, 27, 49), outline=color, width=2)
        draw.ellipse([px + 20, pills_y + 25, px + 36, pills_y + 41], fill=color)
        draw.text((px + 45, pills_y + 22), label, fill=(160, 175, 205), font=get_font(24, bold=False))
        draw.text((px + 20, pills_y + 55), count, fill=(255, 255, 255), font=get_font(38, bold=True))

    # Section Selector
    sec_y = 425
    draw.rounded_rectangle([50, sec_y, 400, sec_y + 75], radius=22, fill=(0, 163, 255), outline=None)
    draw.text((225, sec_y + 38), "Секция 1 (Блок А)", fill=(255, 255, 255), font=get_font(28, bold=True), anchor="mm")
    draw.rounded_rectangle([420, sec_y, 770, sec_y + 75], radius=22, fill=(20, 29, 52), outline=(38, 52, 88), width=2)
    draw.text((595, sec_y + 38), "Секция 2 (Блок Б)", fill=(140, 155, 185), font=get_font(28, bold=False), anchor="mm")

    # Grid Matrix (Floors & Apartments)
    grid_y = 530
    cols = 4
    col_w = (W - 100 - 130 - 45) // cols
    cell_h = 175

    # Sample floor data
    # (apt_num, rooms, area, price, status)
    # status: 0=free, 1=booked, 2=reserved, 3=sold
    status_colors = {
        0: ((46, 158, 99), (20, 48, 36), "Свободно"),
        1: ((226, 168, 28), (52, 42, 20), "Бронь"),
        2: ((37, 99, 235), (20, 36, 68), "Резерв"),
        3: ((208, 70, 60), (50, 24, 26), "Продано"),
    }

    floors = [
        (12, [("121", "2к", "68.4м²", "920 млн", 0), ("122", "3к", "94.2м²", "1.25 млрд", 3), ("123", "1к", "42.1м²", "580 млн", 1), ("124", "2к", "64.0м²", "880 млн", 0)]),
        (11, [("111", "2к", "68.4м²", "915 млн", 3), ("112", "3к", "94.2м²", "1.24 млрд", 0), ("113", "1к", "42.1м²", "575 млн", 2), ("114", "2к", "64.0м²", "875 млн", 3)]),
        (10, [("101", "2к", "68.4м²", "910 млн", 0), ("102", "3к", "94.2м²", "1.24 млрд", 1), ("103", "1к", "42.1м²", "570 млн", 0), ("104", "2к", "64.0м²", "870 млн", 3)]),
        (9,  [("91",  "2к", "68.4м²", "900 млн", 3), ("92",  "3к", "94.2м²", "1.22 млрд", 3), ("93",  "1к", "42.1м²", "565 млн", 0), ("94",  "2к", "64.0м²", "860 млн", 0)]),
        (8,  [("81",  "2к", "68.4м²", "895 млн", 0), ("82",  "3к", "94.2м²", "1.21 млрд", 2), ("83",  "1к", "42.1м²", "560 млн", 0), ("84",  "2к", "64.0м²", "855 млн", 3)]),
        (7,  [("71",  "2к", "68.4м²", "890 млн", 3), ("72",  "3к", "94.2м²", "1.20 млрд", 0), ("73",  "1к", "42.1м²", "555 млн", 1), ("74",  "2к", "64.0м²", "850 млн", 0)]),
    ]

    for r, (floor_num, apts) in enumerate(floors):
        fy = grid_y + r * (cell_h + 15)
        # Floor label
        draw.rounded_rectangle([50, fy, 150, fy + cell_h], radius=22, fill=(22, 32, 58), outline=(38, 54, 94), width=2)
        draw.text((100, fy + cell_h // 2 - 18), f"{floor_num}", fill=(255, 255, 255), font=get_font(42, bold=True), anchor="mm")
        draw.text((100, fy + cell_h // 2 + 25), "этаж", fill=(130, 150, 185), font=get_font(22, bold=False), anchor="mm")

        for c, (num, rooms, area, price, st) in enumerate(apts):
            cx = 175 + c * (col_w + 15)
            b_col, bg_col, st_label = status_colors[st]
            # Active selection highlight for 102
            is_selected = (floor_num == 10 and num == "102")
            border_w = 4 if is_selected else 2
            border_c = (255, 255, 255) if is_selected else b_col

            draw.rounded_rectangle([cx, fy, cx + col_w, fy + cell_h], radius=22, fill=bg_col, outline=border_c, width=border_w)
            
            # Number & Rooms
            draw.text((cx + 18, fy + 16), f"№{num}", fill=(255, 255, 255), font=get_font(32, bold=True))
            draw.text((cx + col_w - 18, fy + 18), rooms, fill=b_col, font=get_font(26, bold=True), anchor="ra")
            
            # Area & Price
            draw.text((cx + 18, fy + 72), area, fill=(200, 215, 240), font=get_font(28, bold=False))
            draw.text((cx + 18, fy + 115), price, fill=(255, 255, 255), font=get_font(28, bold=True))

    # Selected Apartment Floating Action Card (Bottom Sheet Preview)
    sheet_y = H - 850
    draw.rounded_rectangle([45, sheet_y, W - 45, H - 280], radius=38, fill=(18, 27, 52, 252), outline=(0, 163, 255), width=3)
    
    # Handle bar
    draw.rounded_rectangle([W // 2 - 50, sheet_y + 16, W // 2 + 50, sheet_y + 24], radius=4, fill=(80, 100, 140))
    
    # Selected info
    draw.text((80, sheet_y + 55), "Квартира №102 · Блок А", fill=(255, 255, 255), font=get_font(42, bold=True))
    draw.rounded_rectangle([W - 240, sheet_y + 50, W - 80, sheet_y + 105], radius=18, fill=(226, 168, 28, 40), outline=(226, 168, 28), width=2)
    draw.text((W - 160, sheet_y + 78), "БРОНЬ", fill=(235, 180, 45), font=get_font(26, bold=True), anchor="mm")

    draw.text((80, sheet_y + 125), "3 комнаты · 94.2 м² · 10 этаж · Окна во двор и бульвар", fill=(160, 180, 215), font=get_font(30, bold=False))
    draw.text((80, sheet_y + 185), "1 245 000 000 сум", fill=(255, 255, 255), font=get_font(48, bold=True))
    draw.text((540, sheet_y + 200), "($98 000) · 13.2 млн/м²", fill=(140, 160, 195), font=get_font(30, bold=False))

    # CTA Buttons
    draw.rounded_rectangle([80, sheet_y + 270, W // 2 - 15, sheet_y + 375], radius=28, fill=(0, 163, 255), outline=None)
    draw.text(((80 + W // 2 - 15) // 2, sheet_y + 322), "⚡ Сделка / Договор", fill=(255, 255, 255), font=get_font(32, bold=True), anchor="mm")

    draw.rounded_rectangle([W // 2 + 15, sheet_y + 270, W - 80, sheet_y + 375], radius=28, fill=(30, 44, 78), outline=(50, 72, 122), width=2)
    draw.text(((W // 2 + 15 + W - 80) // 2, sheet_y + 322), "📄 Презентация PDF", fill=(255, 255, 255), font=get_font(32, bold=False), anchor="mm")

    draw_bottom_nav(draw, active_idx=1)
    im.save(f"{OUT_DIR}/chess_grid.png")
    print("Generated chess_grid.png")

# 2. TASKS KANBAN SCREEN
def generate_tasks_kanban():
    im = create_base_canvas()
    draw = ImageDraw.Draw(im)
    draw_status_bar(draw)

    # Header
    draw.text((70, 150), "Задачи и проекты", fill=(255, 255, 255), font=get_font(52, bold=True))
    # Add task button (+)
    draw.rounded_rectangle([W - 170, 140, W - 70, 240], radius=30, fill=(0, 163, 255), outline=None)
    draw.text((W - 120, 185), "+", fill=(255, 255, 255), font=get_font(56, bold=True), anchor="mm")

    # Tabs: Канбан, Список, Дедлайны
    tab_y = 265
    tabs = ["Канбан", "По срокам", "Мой план", "Делегированные"]
    tx = 70
    for i, t in enumerate(tabs):
        is_sel = (i == 0)
        t_w = len(t) * 22 + 45
        if is_sel:
            draw.rounded_rectangle([tx, tab_y, tx + t_w, tab_y + 70], radius=22, fill=(0, 163, 255))
            draw.text((tx + t_w // 2, tab_y + 35), t, fill=(255, 255, 255), font=get_font(28, bold=True), anchor="mm")
        else:
            draw.rounded_rectangle([tx, tab_y, tx + t_w, tab_y + 70], radius=22, fill=(22, 32, 58), outline=(40, 56, 96), width=2)
            draw.text((tx + t_w // 2, tab_y + 35), t, fill=(150, 170, 205), font=get_font(28, bold=False), anchor="mm")
        tx += t_w + 16

    # Kanban Columns Preview
    col_y = 370
    draw.rounded_rectangle([60, col_y, W - 60, col_y + 70], radius=20, fill=(26, 38, 70))
    draw.text((90, col_y + 35), "🔥 В РАБОТЕ (3)", fill=(255, 255, 255), font=get_font(30, bold=True), anchor="lm")
    draw.text((W - 90, col_y + 35), "Фокус дня", fill=(0, 180, 255), font=get_font(26, bold=True), anchor="rm")

    cards = [
        {
            "title": "Оформить ДДУ для кв. 102 (ЖК Mirabad)",
            "desc": "Клиент Бахтиёр Саидов ждет финальный вариант с графиком рассрочки на 24 мес.",
            "tag": "Сделка #412",
            "tag_c": (0, 163, 255),
            "deadline": "Сегодня, 17:00",
            "dead_c": (226, 168, 28),
            "subtasks": "3 из 4 подзадач",
            "author": "Дилшоджон"
        },
        {
            "title": "Провести презентацию пентхауса на 16 этаже",
            "desc": "Встреча с инвестором в офисе продаж, подготовить 3D модель и план террасы.",
            "tag": "Показ ЖК",
            "tag_c": (46, 158, 99),
            "deadline": "Завтра, 11:30",
            "dead_c": (140, 160, 200),
            "subtasks": "Чек-лист готов",
            "author": "Алишер У."
        },
        {
            "title": "Согласовать скидку 3% с гендиректором",
            "desc": "Повторный клиент, оплата 100% собственными средствами за 3 дня.",
            "tag": "Согласование",
            "tag_c": (208, 70, 60),
            "deadline": "Срочно",
            "dead_c": (208, 70, 60),
            "subtasks": "Документы в 1С",
            "author": "Камилла"
        },
        {
            "title": "Сверить выписку из банка по счетам эскроу",
            "desc": "Реестр платежей за ноябрь, внесение данных в финучет shamCRM.",
            "tag": "Финансы",
            "tag_c": (147, 51, 234),
            "deadline": "12 ноября",
            "dead_c": (140, 160, 200),
            "subtasks": "Сверка 1С",
            "author": "Бухгалтерия"
        }
    ]

    card_y = col_y + 95
    for c in cards:
        draw.rounded_rectangle([60, card_y, W - 60, card_y + 440], radius=32, fill=(18, 27, 50), outline=(36, 52, 92), width=2)
        
        # Tag & Deadline pills
        draw.rounded_rectangle([95, card_y + 35, 95 + len(c["tag"]) * 18 + 35, card_y + 90], radius=16, fill=(*c["tag_c"], 35), outline=c["tag_c"], width=2)
        draw.text((95 + (len(c["tag"]) * 18 + 35) // 2, card_y + 62), c["tag"], fill=c["tag_c"], font=get_font(24, bold=True), anchor="mm")

        draw.rounded_rectangle([W - 380, card_y + 35, W - 95, card_y + 90], radius=16, fill=(30, 42, 70), outline=c["dead_c"], width=2)
        draw.text((W - 238, card_y + 62), f"⏱ {c['deadline']}", fill=c["dead_c"], font=get_font(24, bold=True), anchor="mm")

        # Title
        draw.text((95, card_y + 115), c["title"], fill=(255, 255, 255), font=get_font(36, bold=True))
        
        # Description
        draw.text((95, card_y + 180), c["desc"], fill=(150, 170, 205), font=get_font(26, bold=False))

        # Bottom info: Subtasks & Assignee
        draw.line([95, card_y + 335, W - 95, card_y + 335], fill=(30, 44, 76), width=2)
        draw.text((95, card_y + 380), f"✓ {c['subtasks']}", fill=(0, 180, 255), font=get_font(26, bold=True), anchor="lm")
        
        # Avatar circle
        draw.ellipse([W - 290, card_y + 355, W - 235, card_y + 410], fill=(0, 163, 255))
        draw.text((W - 262, card_y + 382), c["author"][0], fill=(255, 255, 255), font=get_font(26, bold=True), anchor="mm")
        draw.text((W - 220, card_y + 380), c["author"], fill=(200, 215, 245), font=get_font(26, bold=False), anchor="lm")

        card_y += 465

    draw_bottom_nav(draw, active_idx=2)
    im.save(f"{OUT_DIR}/tasks_kanban.png")
    print("Generated tasks_kanban.png")

# 3. DEALS PIPELINE SCREEN
def generate_deals_pipeline():
    im = create_base_canvas()
    draw = ImageDraw.Draw(im)
    draw_status_bar(draw)

    # Header
    draw.text((70, 150), "Сделки и воронка", fill=(255, 255, 255), font=get_font(52, bold=True))
    draw.text((70, 225), "Общий оборот воронки: 18.4 млрд сум ($1.45M)", fill=(0, 180, 255), font=get_font(30, bold=True))

    # Stage tabs with count and sum
    stages = [
        ("Новые лиды", "14 сделок · 4.2 млрд", (0, 163, 255)),
        ("Встреча / Показ", "8 сделок · 3.1 млрд", (147, 51, 234)),
        ("Бронь (10%)", "5 сделок · 2.6 млрд", (226, 168, 28)),
        ("Договор ДДУ", "6 сделок · 5.8 млрд", (46, 158, 99)),
    ]

    sy = 295
    for i, (title, sub, col) in enumerate(stages):
        is_active = (i == 2) # Бронь active
        draw.rounded_rectangle([70, sy, W - 70, sy + 110], radius=24, fill=(22, 32, 58) if not is_active else (26, 42, 80), outline=col if is_active else (36, 52, 92), width=3 if is_active else 2)
        draw.ellipse([105, sy + 38, 135, sy + 68], fill=col)
        draw.text((160, sy + 35), title, fill=(255, 255, 255), font=get_font(32, bold=True))
        draw.text((160, sy + 75), sub, fill=(150, 175, 210), font=get_font(24, bold=False))
        # Arrow
        draw.text((W - 120, sy + 55), "›", fill=col, font=get_font(46, bold=True), anchor="mm")
        sy += 128

    # Deals in active stage
    draw.text((70, sy + 25), "Сделки на этапе «БРОНЬ» (5)", fill=(255, 255, 255), font=get_font(36, bold=True))
    
    deals = [
        {
            "client": "Бахтиёр Саидов",
            "phone": "+998 90 123-45-67",
            "obj": "ЖК Mirabad Avenue · Кв. 102 (3к, 94.2 м²)",
            "sum": "1 245 000 000 сум",
            "paid": "Внесено 10% (124.5 млн)",
            "mgr": "Дилшоджон"
        },
        {
            "client": "Нодира Каримова",
            "phone": "+998 97 888-99-00",
            "obj": "ЖК Boulevard · Кв. 48 (2к, 68.0 м²)",
            "sum": "890 000 000 сум",
            "paid": "Внесено 5% (44.5 млн)",
            "mgr": "Алишер У."
        },
        {
            "client": "Фарход Юсупов",
            "phone": "+998 99 777-11-22",
            "obj": "ЖК Panorama · Кв. 15 (1к, 44.5 м²)",
            "sum": "560 000 000 сум",
            "paid": "Ожидает оплату брони",
            "mgr": "Камилла"
        }
    ]

    dy = sy + 85
    for d in deals:
        draw.rounded_rectangle([70, dy, W - 70, dy + 320], radius=32, fill=(18, 27, 50), outline=(36, 52, 92), width=2)
        
        # Client name & Phone
        draw.text((105, dy + 35), d["client"], fill=(255, 255, 255), font=get_font(36, bold=True))
        draw.text((W - 105, dy + 38), d["phone"], fill=(0, 180, 255), font=get_font(26, bold=True), anchor="ra")

        # Object
        draw.text((105, dy + 95), f"🏢 {d['obj']}", fill=(180, 200, 235), font=get_font(28, bold=False))

        # Price & Paid status
        draw.text((105, dy + 160), d["sum"], fill=(255, 255, 255), font=get_font(42, bold=True))
        draw.rounded_rectangle([105, dy + 230, 105 + len(d["paid"]) * 16 + 40, dy + 285], radius=16, fill=(46, 158, 99, 35), outline=(46, 158, 99), width=2)
        draw.text((105 + (len(d["paid"]) * 16 + 40) // 2, dy + 257), f"✓ {d['paid']}", fill=(56, 185, 115), font=get_font(24, bold=True), anchor="mm")

        # Manager
        draw.text((W - 105, dy + 257), f"Ответственный: {d['mgr']}", fill=(140, 160, 195), font=get_font(26, bold=False), anchor="ra")

        dy += 345

    draw_bottom_nav(draw, active_idx=4)
    im.save(f"{OUT_DIR}/deals_pipeline.png")
    print("Generated deals_pipeline.png")

# 4. CHATS SCREEN
def generate_chats_team():
    im = create_base_canvas()
    draw = ImageDraw.Draw(im)
    draw_status_bar(draw)

    # Header
    draw.text((70, 150), "Корпоративные чаты", fill=(255, 255, 255), font=get_font(52, bold=True))
    
    # Search bar
    draw.rounded_rectangle([70, 240, W - 70, 330], radius=24, fill=(20, 29, 54), outline=(36, 52, 92), width=2)
    draw.text((115, 285), "🔍 Поиск по коллегам, объектам и клиентам...", fill=(130, 150, 185), font=get_font(28, bold=False), anchor="lm")

    # Category filters
    tabs = ["Все чаты (18)", "Отделы", "ЖК Объекты", "Клиенты"]
    tx = 70
    cy = 360
    for i, t in enumerate(tabs):
        is_sel = (i == 0)
        t_w = len(t) * 20 + 40
        draw.rounded_rectangle([tx, cy, tx + t_w, cy + 65], radius=20, fill=(0, 163, 255) if is_sel else (22, 32, 58), outline=None if is_sel else (38, 54, 94), width=2)
        draw.text((tx + t_w // 2, cy + 32), t, fill=(255, 255, 255) if is_sel else (140, 160, 195), font=get_font(26, bold=is_sel), anchor="mm")
        tx += t_w + 15

    # Chat rows
    chats = [
        {
            "title": "Отдел продаж Ташкент",
            "last": "Дилшоджон: Бронь на 102 квартиру зафиксирована в шахматке! 🔒",
            "time": "14:12",
            "unread": 3,
            "badge_col": (0, 163, 255),
            "avatar_text": "ОП"
        },
        {
            "title": "ЖК Mirabad Avenue · Проект",
            "last": "Камилла: Прикрепила свежий буклет и планировки блока Б 📎",
            "time": "13:45",
            "unread": 1,
            "badge_col": (0, 163, 255),
            "avatar_text": "МА"
        },
        {
            "title": "Бахтиёр Саидов (Лид #412)",
            "last": "Клиент: Спасибо за быстрый расчет рассрочки, завтра подъеду в офис.",
            "time": "12:30",
            "unread": 0,
            "badge_col": None,
            "avatar_text": "БС"
        },
        {
            "title": "Юридический отдел shamCRM",
            "last": "Азиз Юрист: Типовой договор ДДУ согласован с изменениями банка.",
            "time": "11:15",
            "unread": 0,
            "badge_col": None,
            "avatar_text": "ЮО"
        },
        {
            "title": "Алишер Умаров (Старший менеджер)",
            "last": "▶ Голосовое сообщение (0:38)",
            "time": "Вчера",
            "unread": 0,
            "badge_col": None,
            "avatar_text": "АУ"
        },
        {
            "title": "Строительный контроль · ЖК Panorama",
            "last": "Заливка монолита 14 этажа завершена в срок.",
            "time": "Вчера",
            "unread": 0,
            "badge_col": None,
            "avatar_text": "СК"
        }
    ]

    list_y = 460
    for chat in chats:
        draw.rounded_rectangle([70, list_y, W - 70, list_y + 200], radius=28, fill=(18, 27, 50), outline=(34, 48, 86), width=2)
        
        # Avatar
        draw.ellipse([100, list_y + 40, 220, list_y + 160], fill=(28, 48, 92))
        draw.text((160, list_y + 100), chat["avatar_text"], fill=(0, 180, 255), font=get_font(40, bold=True), anchor="mm")

        # Title & Time
        draw.text((250, list_y + 55), chat["title"], fill=(255, 255, 255), font=get_font(34, bold=True))
        draw.text((W - 110, list_y + 55), chat["time"], fill=(130, 150, 185), font=get_font(26, bold=False), anchor="ra")

        # Last message
        msg_cut = chat["last"] if len(chat["last"]) < 48 else chat["last"][:46] + "..."
        draw.text((250, list_y + 115), msg_cut, fill=(160, 180, 215), font=get_font(28, bold=False))

        # Unread badge
        if chat["unread"] > 0:
            draw.rounded_rectangle([W - 170, list_y + 105, W - 110, list_y + 155], radius=18, fill=(0, 163, 255))
            draw.text((W - 140, list_y + 130), str(chat["unread"]), fill=(255, 255, 255), font=get_font(26, bold=True), anchor="mm")

        list_y += 225

    draw_bottom_nav(draw, active_idx=3)
    im.save(f"{OUT_DIR}/chats_team.png")
    print("Generated chats_team.png")

# 5. DESKTOP SHAMCRM MOCKUP
def generate_desktop_mockup():
    DW, DH = 2400, 1500
    im = Image.new("RGBA", (DW, DH), (10, 15, 28, 255))
    draw = ImageDraw.Draw(im)

    # Window bar
    draw.rounded_rectangle([0, 0, DW, DH], radius=24, fill=(12, 18, 34))
    draw.rectangle([0, 0, DW, 70], fill=(16, 24, 45))
    # Traffic lights
    draw.ellipse([30, 25, 50, 45], fill=(237, 106, 94))
    draw.ellipse([65, 25, 85, 45], fill=(245, 191, 79))
    draw.ellipse([100, 25, 120, 45], fill=(98, 197, 84))
    draw.text((DW // 2, 35), "shamCRM Desktop · Система управления продажами девелопера", fill=(140, 160, 200), font=get_font(26, bold=True), anchor="mm")

    # Left Sidebar
    sb_w = 340
    draw.rectangle([0, 70, sb_w, DH], fill=(15, 22, 42), outline=(32, 46, 82), width=2)
    # Brand
    draw.text((45, 120), "shamCRM", fill=(255, 255, 255), font=get_font(42, bold=True))
    draw.text((230, 125), "PRO", fill=(0, 180, 255), font=get_font(22, bold=True))

    menu_items = [
        ("📊 Дашборд KPI", False),
        ("🏢 Шахматка 3D", True),
        ("⚡ Воронка сделок", False),
        ("✓ Задачи и проекты", False),
        ("💬 Корпоративный чат", False),
        ("📞 Телефония & SIP", False),
        ("📦 Склад и товары", False),
        ("💼 1С Синхронизация", False),
        ("📈 Аналитика продаж", False),
        ("⚙ Настройки CRM", False),
    ]

    my = 210
    for title, is_act in menu_items:
        if is_act:
            draw.rounded_rectangle([25, my, sb_w - 25, my + 64], radius=16, fill=(0, 163, 255))
            draw.text((45, my + 32), title, fill=(255, 255, 255), font=get_font(26, bold=True), anchor="lm")
        else:
            draw.text((45, my + 32), title, fill=(140, 160, 195), font=get_font(26, bold=False), anchor="lm")
        my += 80

    # User profile at bottom of sidebar
    draw.rounded_rectangle([25, DH - 110, sb_w - 25, DH - 25], radius=18, fill=(22, 32, 58))
    draw.ellipse([45, DH - 95, 95, DH - 45], fill=(0, 163, 255))
    draw.text((70, DH - 70), "ДУ", fill=(255, 255, 255), font=get_font(22, bold=True), anchor="mm")
    draw.text((115, DH - 82), "Дилшоджон А.", fill=(255, 255, 255), font=get_font(24, bold=True), anchor="lm")
    draw.text((115, DH - 58), "Руководитель ОП", fill=(0, 180, 255), font=get_font(20, bold=False), anchor="lm")

    # Main Top Bar
    draw.rectangle([sb_w, 70, DW, 160], fill=(16, 25, 48), outline=(32, 46, 82), width=1)
    draw.text((sb_w + 50, 115), "Интерактивная шахматка объектов · ЖК Mirabad Avenue", fill=(255, 255, 255), font=get_font(34, bold=True), anchor="lm")
    draw.rounded_rectangle([DW - 420, 95, DW - 50, 145], radius=16, fill=(24, 36, 68), outline=(42, 60, 105), width=2)
    draw.text((DW - 400, 120), "🔍 Быстрый поиск кв., клиента...", fill=(130, 150, 185), font=get_font(22, bold=False), anchor="lm")

    # Main content: High-res interactive matrix + Right inspector panel
    # Right Inspector Panel (Apartment details)
    insp_w = 560
    insp_x = DW - insp_w
    draw.rectangle([insp_x, 160, DW, DH], fill=(16, 24, 46), outline=(32, 46, 82), width=2)
    
    draw.text((insp_x + 40, 210), "Квартира №102", fill=(255, 255, 255), font=get_font(38, bold=True))
    draw.rounded_rectangle([insp_x + 360, 195, DW - 40, 245], radius=14, fill=(226, 168, 28, 40), outline=(226, 168, 28), width=2)
    draw.text((insp_x + 460, 220), "БРОНЬ", fill=(235, 180, 45), font=get_font(22, bold=True), anchor="mm")

    props = [
        ("Жилой комплекс:", "ЖК Mirabad Avenue"),
        ("Блок / Секция:", "Блок А · Подъезд 2"),
        ("Этаж:", "10 из 16 этажей"),
        ("Комнатность:", "3-комнатная квартира"),
        ("Общая площадь:", "94.20 м²"),
        ("Жилая площадь:", "62.40 м²"),
        ("Высота потолков:", "3.30 м"),
        ("Вид из окон:", "Панорама на бульвар"),
        ("Стоимость за м²:", "13 216 000 сум/м²"),
        ("Итоговая цена:", "1 245 000 000 сум"),
        ("Клиент брони:", "Бахтиёр Саидов"),
        ("Номер телефона:", "+998 90 123-45-67"),
    ]

    py = 280
    for label, val in props:
        draw.text((insp_x + 40, py), label, fill=(140, 160, 195), font=get_font(22, bold=False))
        draw.text((DW - 40, py), val, fill=(255, 255, 255), font=get_font(22, bold=True), anchor="ra")
        py += 44

    # Actions in inspector
    draw.rounded_rectangle([insp_x + 40, DH - 200, DW - 40, DH - 125], radius=18, fill=(0, 163, 255))
    draw.text((insp_x + insp_w // 2, DH - 162), "⚡ Оформить сделку и ДДУ", fill=(255, 255, 255), font=get_font(26, bold=True), anchor="mm")

    draw.rounded_rectangle([insp_x + 40, DH - 110, DW - 40, DH - 40], radius=18, fill=(24, 36, 68), outline=(42, 62, 108), width=2)
    draw.text((insp_x + insp_w // 2, DH - 75), "📄 Экспорт КП и графика платежей PDF", fill=(255, 255, 255), font=get_font(24, bold=False), anchor="mm")

    # Center Matrix Grid
    center_w = insp_x - sb_w
    # Quick filter row
    draw.rounded_rectangle([sb_w + 40, 190, sb_w + 220, 240], radius=14, fill=(46, 158, 99, 40), outline=(46, 158, 99), width=2)
    draw.text((sb_w + 130, 215), "● 48 Свободно", fill=(56, 195, 120), font=get_font(22, bold=True), anchor="mm")

    draw.rounded_rectangle([sb_w + 240, 190, sb_w + 400, 240], radius=14, fill=(226, 168, 28, 40), outline=(226, 168, 28), width=2)
    draw.text((sb_w + 320, 215), "● 18 Бронь", fill=(235, 185, 45), font=get_font(22, bold=True), anchor="mm")

    draw.rounded_rectangle([sb_w + 420, 190, sb_w + 580, 240], radius=14, fill=(37, 99, 235, 40), outline=(37, 99, 235), width=2)
    draw.text((sb_w + 500, 215), "● 8 Резерв", fill=(80, 140, 255), font=get_font(22, bold=True), anchor="mm")

    draw.rounded_rectangle([sb_w + 600, 190, sb_w + 770, 240], radius=14, fill=(208, 70, 60, 40), outline=(208, 70, 60), width=2)
    draw.text((sb_w + 685, 215), "● 54 Продано", fill=(225, 85, 75), font=get_font(22, bold=True), anchor="mm")

    # Large matrix rows
    m_y = 270
    desk_floors = 9
    desk_cols = 8
    d_cell_w = (center_w - 180) // desk_cols
    d_cell_h = (DH - m_y - 60) // desk_floors

    st_colors = [
        ((46, 158, 99), (18, 45, 34)),
        ((226, 168, 28), (48, 38, 20)),
        ((37, 99, 235), (20, 36, 68)),
        ((208, 70, 60), (48, 24, 26)),
    ]

    for fl in range(16, 16 - desk_floors, -1):
        fy = m_y + (16 - fl) * d_cell_h
        # Floor label
        draw.rounded_rectangle([sb_w + 40, fy + 4, sb_w + 110, fy + d_cell_h - 4], radius=10, fill=(24, 34, 62))
        draw.text((sb_w + 75, fy + d_cell_h // 2), f"{fl} эт", fill=(255, 255, 255), font=get_font(20, bold=True), anchor="mm")

        for ap in range(1, desk_cols + 1):
            ax = sb_w + 125 + (ap - 1) * d_cell_w
            # Deterministic color pattern
            st_idx = (fl * 3 + ap * 7) % 4
            if fl == 10 and ap == 2:
                st_idx = 1 # 102 Booked!
            b_col, bg_col = st_colors[st_idx]
            
            is_active_cell = (fl == 10 and ap == 2)
            c_fill = (45, 65, 110) if is_active_cell else bg_col
            c_out = (255, 255, 255) if is_active_cell else b_col

            draw.rounded_rectangle([ax + 3, fy + 4, ax + d_cell_w - 3, fy + d_cell_h - 4], radius=10, fill=c_fill, outline=c_out, width=3 if is_active_cell else 1)
            
            apt_num = fl * 10 + ap
            draw.text((ax + 12, fy + 14), f"{apt_num}", fill=(255, 255, 255), font=get_font(20, bold=True))
            draw.text((ax + d_cell_w - 12, fy + 14), f"{1 + (ap % 3)}к", fill=b_col, font=get_font(18, bold=True), anchor="ra")
            draw.text((ax + 12, fy + d_cell_h - 22), f"{42 + ap * 8}м²", fill=(180, 200, 230), font=get_font(16, bold=False))

    im.save(f"{OUT_DIR}/desktop_mockup.png")
    print("Generated desktop_mockup.png")

if __name__ == "__main__":
    generate_chess_grid()
    generate_tasks_kanban()
    generate_deals_pipeline()
    generate_chats_team()
    generate_desktop_mockup()
