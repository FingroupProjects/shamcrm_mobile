import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

MOCKUPS_DIR = "shamcrm-website/assets/mockups"
SCREENSHOTS_DIR = "shamcrm-website/assets/screenshots"
os.makedirs(MOCKUPS_DIR, exist_ok=True)
os.makedirs(SCREENSHOTS_DIR, exist_ok=True)

# App Native Fonts
FONT_BOLD_PATH = "assets/fonts/Gilroy-Bold.ttf"
FONT_REGULAR_PATH = "assets/fonts/Gilroy-Regular.ttf"

def get_gilroy(size, bold=False):
    path = FONT_BOLD_PATH if bold else FONT_REGULAR_PATH
    if os.path.exists(path):
        return ImageFont.truetype(path, int(size))
    return ImageFont.load_default()

def make_iphone17_pro_max_mockup(screen_img, output_path):
    """
    Creates an authentic Apple iPhone 17 Pro Max mockup:
    - Screen: 1200 x 2600 (aspect ratio 19.5:9, iOS token curvature radius 162px)
    - Ultra-thin titanium bezel: 18px
    - Outer frame: 1236 x 2636, outer corner radius: 180px
    - Dynamic Island: 340 x 88px, radius 44px, centered, top=32px
    - Home Indicator: 380 x 12px, radius 6px, centered, bottom=28px
    - Soft Apple multi-layered Gaussian drop shadow
    """
    target_w, target_h = 1200, 2600
    screen_resized = screen_img.resize((target_w, target_h), Image.Resampling.LANCZOS)
    
    bezel = 18
    pad_x = 80
    pad_top = 80
    pad_bot = 110
    
    canvas_w = target_w + (pad_x + bezel) * 2
    canvas_h = target_h + pad_top + pad_bot + bezel * 2
    
    canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    
    # Coordinates of outer titanium frame
    f_left = pad_x
    f_top = pad_top
    f_right = pad_x + target_w + bezel * 2
    f_bottom = pad_top + target_h + bezel * 2
    frame_box = [f_left, f_top, f_right, f_bottom]
    frame_radius = 180
    
    # 1. Realistic Multi-layered Apple drop shadow
    shadow = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    sh_draw = ImageDraw.Draw(shadow)
    # Ambient soft contact shadow
    sh_draw.rounded_rectangle(
        [f_left + 10, f_top + 25, f_right - 10, f_bottom + 50],
        radius=frame_radius,
        fill=(15, 23, 42, 60)
    )
    # Deep elevation shadow
    sh_draw.rounded_rectangle(
        [f_left + 20, f_top + 50, f_right - 20, f_bottom + 90],
        radius=frame_radius,
        fill=(15, 23, 42, 35)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(38))
    canvas = Image.alpha_composite(canvas, shadow)
    
    draw = ImageDraw.Draw(canvas)
    
    # 2. Outer Titanium Band (Apple Natural Titanium / Space Black finish)
    # Outer bezel edge
    draw.rounded_rectangle(frame_box, radius=frame_radius, fill=(26, 29, 36), outline=(65, 70, 82), width=2)
    # Inner subtle rim highlight
    draw.rounded_rectangle(
        [f_left + 2, f_top + 2, f_right - 2, f_bottom - 2],
        radius=frame_radius - 2,
        fill=(18, 20, 26),
        outline=(35, 38, 48),
        width=1
    )
    
    # 3. Mask screen with deeply rounded Apple iPhone 17 Pro Max squircle
    screen_radius = 162
    screen_mask = Image.new("L", (target_w, target_h), 0)
    mask_draw = ImageDraw.Draw(screen_mask)
    mask_draw.rounded_rectangle([0, 0, target_w, target_h], radius=screen_radius, fill=255)
    
    # Screen placement
    s_x = f_left + bezel
    s_y = f_top + bezel
    canvas.paste(screen_resized, (s_x, s_y), screen_mask)
    
    # 4. Dynamic Island (Apple Pill Cutout)
    di_w, di_h = 340, 88
    di_radius = 44
    di_x = s_x + (target_w - di_w) // 2
    di_y = s_y + 32
    
    # Black pill body
    draw.rounded_rectangle([di_x, di_y, di_x + di_w, di_y + di_h], radius=di_radius, fill=(0, 0, 0))
    # Camera lens reflection (left-center)
    lens_x = di_x + 50
    lens_y = di_y + di_h // 2
    draw.ellipse([lens_x - 14, lens_y - 14, lens_x + 14, lens_y + 14], fill=(10, 12, 18), outline=(22, 26, 38), width=1)
    draw.ellipse([lens_x - 5, lens_y - 5, lens_x + 5, lens_y + 5], fill=(20, 35, 55)) # glass glint
    # Ambient / FaceID sensor (right-center)
    sensor_x = di_x + di_w - 60
    sensor_y = di_y + di_h // 2
    draw.ellipse([sensor_x - 12, sensor_y - 12, sensor_x + 12, sensor_y + 12], fill=(6, 8, 12))
    
    # 5. Home Indicator
    hi_w, hi_h = 380, 12
    hi_radius = 6
    hi_x = s_x + (target_w - hi_w) // 2
    hi_y = s_y + target_h - 32
    draw.rounded_rectangle([hi_x, hi_y, hi_x + hi_w, hi_y + hi_h], radius=hi_radius, fill=(160, 168, 180, 200))
    
    # 6. Subtle inner screen border for edge crispness
    inner_stroke = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    is_draw = ImageDraw.Draw(inner_stroke)
    is_draw.rounded_rectangle([0, 0, target_w - 1, target_h - 1], radius=screen_radius, outline=(0, 0, 0, 60), width=2)
    canvas.paste(inner_stroke, (s_x, s_y), inner_stroke)
    
    canvas.save(output_path, "PNG", optimize=True)
    print(f"Generated iPhone 17 Pro Max mockup: {output_path}")

def clean_and_build_tasks():
    src = "assets/site/photo_2026-11-09 11.36.50.png"
    im = Image.open(src).convert("RGBA")
    draw = ImageDraw.Draw(im)
    
    font_title = get_gilroy(50, bold=True)
    font_sub = get_gilroy(38, bold=False)
    title_color = (0, 65, 110)
    sub_color = (60, 75, 95)
    
    # Card 1:
    draw.rectangle([75, 625, 820, 685], fill=(210, 215, 230))
    draw.text((80, 626), "Подготовить ДДУ для ЖК Mirabad", fill=title_color, font=font_title)
    draw.rectangle([75, 735, 820, 785], fill=(213, 221, 234))
    draw.text((80, 738), "Квартира №104 (1к, 43 м²) · Рассрочка 24 мес", fill=sub_color, font=font_sub)
    
    # Card 2 (preserve left avatar icon up to x=150):
    draw.rectangle([150, 1180, 820, 1240], fill=(212, 212, 222))
    draw.text((155, 1182), "Показ пентхауса инвестору", fill=title_color, font=font_title)
    draw.rectangle([75, 1285, 820, 1340], fill=(209, 210, 220))
    draw.text((80, 1288), "ЖК Sham Back Олмос · Корпус 3, 16 этаж", fill=sub_color, font=font_sub)
    
    # Card 3:
    draw.rectangle([75, 1735, 820, 1795], fill=(224, 223, 229))
    draw.text((80, 1736), "Согласование графика оплат", fill=title_color, font=font_title)
    draw.rectangle([75, 1840, 820, 1895], fill=(221, 220, 226))
    draw.text((80, 1843), "Клиент: Бахтиёр Саидов · Взнос 30%", fill=sub_color, font=font_sub)
    
    raw_path = f"{MOCKUPS_DIR}/screen_tasks.png"
    im.save(raw_path)
    make_iphone17_pro_max_mockup(im, f"{MOCKUPS_DIR}/iphone_tasks.png")

def clean_and_build_deal():
    src = "assets/site/photo_2026-11-09 11.37.17.png"
    im = Image.open(src).convert("RGBA")
    draw = ImageDraw.Draw(im)
    
    font_bold = get_gilroy(20, bold=True)
    font_sub = get_gilroy(16, bold=False)
    
    # Clean only the right column text dumps inside the native white card
    # Row 1: Общая стоимость
    draw.rectangle([240, 290, 550, 510], fill=(255, 255, 255))
    draw.text((545, 298), "100 000 USD", fill=(0, 75, 135), font=font_bold, anchor="ra")
    draw.text((545, 324), "1 270 000 000 сум", fill=(120, 135, 155), font=font_sub, anchor="ra")
    
    # Row 2: Первоначальный взнос
    draw.rectangle([240, 515, 550, 705], fill=(255, 255, 255))
    draw.text((545, 520), "30 000 USD (30%)", fill=(0, 75, 135), font=font_bold, anchor="ra")
    draw.text((545, 546), "381 000 000 сум", fill=(120, 135, 155), font=font_sub, anchor="ra")
    
    # Row 3: Сумма рассрочки
    draw.rectangle([240, 740, 550, 930], fill=(255, 255, 255))
    draw.text((545, 745), "70 000 USD", fill=(0, 75, 135), font=font_bold, anchor="ra")
    draw.text((545, 771), "889 000 000 сум", fill=(120, 135, 155), font=font_sub, anchor="ra")
    
    # Row 4: Ежемесячная оплата
    draw.rectangle([240, 940, 550, 1070], fill=(255, 255, 255))
    draw.text((545, 965), "7 000 USD / мес", fill=(16, 150, 80), font=font_bold, anchor="ra")
    draw.text((545, 991), "88 900 000 сум", fill=(120, 135, 155), font=font_sub, anchor="ra")
    
    raw_path = f"{MOCKUPS_DIR}/screen_deal.png"
    im.save(raw_path)
    make_iphone17_pro_max_mockup(im, f"{MOCKUPS_DIR}/iphone_deal.png")

def clean_and_build_leads():
    src = "assets/site/photo_2026-11-09 11.36.52.png"
    im = Image.open(src).convert("RGBA")
    draw = ImageDraw.Draw(im)
    
    font_title = get_gilroy(50, bold=True)
    title_color = (0, 65, 110)
    
    # Card 3: replace dummy full name string only
    draw.rectangle([75, 1600, 1000, 1660], fill=(236, 237, 242))
    draw.text((80, 1605), "Бахтиёр Саидов (Покупка)", fill=title_color, font=font_title)
    
    # Card 4: replace Тест(Admin) only
    draw.rectangle([75, 2150, 800, 2210], fill=(236, 237, 242))
    draw.text((80, 2155), "Улугбек Рахимов", fill=title_color, font=font_title)
    
    raw_path = f"{MOCKUPS_DIR}/screen_leads.png"
    im.save(raw_path)
    make_iphone17_pro_max_mockup(im, f"{MOCKUPS_DIR}/iphone_leads.png")

def build_direct_mockups():
    items = [
        # (src, out_filename)
        ("assets/site/photo_2026-11-09 11.37.05.png", "iphone_dashboard.png"),
        ("assets/site/photo_2026-11-09 11.36.42.png", "iphone_chess_3d.png"),
        ("assets/site/photo_2026-11-09 11.36.30.png", "iphone_chess_matrix.png"),
        ("assets/site/photo_2026-11-09 11.36.21.png", "iphone_telephony.png"),
        ("assets/site/photo_2026-11-09 11.36.55.png", "iphone_warehouse.png"),
    ]
    for src, out_name in items:
        im = Image.open(src).convert("RGBA")
        out_path = f"{MOCKUPS_DIR}/{out_name}"
        make_iphone17_pro_max_mockup(im, out_path)

def build_macos_desktop_mockup():
    """
    Renders authentic desktop screenshot from assets/site/new into a macOS window frame
    """
    src = "assets/site/new/Снимок экрана — 2026-11-09 в 13.06.01.png"
    if not os.path.exists(src):
        src = "assets/site/new/Снимок экрана — 2026-11-09 в 13.06.01.png"
    
    im = Image.open(src).convert("RGBA")
    w, h = im.size
    
    # Add subtle macOS shadow and window border
    pad = 50
    cw, ch = w + pad * 2, h + pad * 2
    canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    
    shadow = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    sh_draw = ImageDraw.Draw(shadow)
    sh_draw.rounded_rectangle([pad + 5, pad + 15, pad + w - 5, pad + h + 30], radius=16, fill=(15, 23, 42, 60))
    sh_draw.rounded_rectangle([pad + 15, pad + 30, pad + w - 15, pad + h + 50], radius=16, fill=(15, 23, 42, 35))
    shadow = shadow.filter(ImageFilter.GaussianBlur(30))
    canvas = Image.alpha_composite(canvas, shadow)
    
    # Mask window with 14px macOS corner radius
    mask = Image.new("L", (w, h), 0)
    m_draw = ImageDraw.Draw(mask)
    m_draw.rounded_rectangle([0, 0, w, h], radius=14, fill=255)
    
    canvas.paste(im, (pad, pad), mask)
    
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle([pad, pad, pad + w, pad + h], radius=14, outline=(220, 226, 235), width=1)
    
    out_desktop = f"{SCREENSHOTS_DIR}/desktop_mockup.png"
    canvas.save(out_desktop, "PNG", optimize=True)
    print(f"Generated Desktop Mockup: {out_desktop}")

if __name__ == "__main__":
    print("Building Tasks...")
    clean_and_build_tasks()
    print("Building Deal...")
    clean_and_build_deal()
    print("Building Leads...")
    clean_and_build_leads()
    print("Building Direct Mobile Mockups...")
    build_direct_mockups()
    print("Building macOS Desktop Mockup...")
    build_macos_desktop_mockup()
    print("ALL MOCKUPS SUCCESSFULLY BUILT!")

