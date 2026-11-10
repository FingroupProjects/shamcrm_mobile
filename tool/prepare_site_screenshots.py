import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

MOCKUPS_DIR = "shamcrm-website/assets/mockups"
os.makedirs(MOCKUPS_DIR, exist_ok=True)

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

# 1. Clean Tasks Screenshot (1183 x 2560)
def clean_tasks_screenshot():
    src_path = "assets/site/photo_2026-11-09 11.36.50.png"
    im = Image.open(src_path).convert("RGBA")
    draw = ImageDraw.Draw(im)
    
    font_title = get_font(52, bold=True)
    font_sub = get_font(38, bold=False)
    
    # Card background in 11.36.50.png is light frosty grey-white: (230, 235, 245)
    card_bg = (230, 236, 246, 255)
    title_color = (0, 75, 135)
    sub_color = (85, 105, 130)
    
    # Card 1 (Y: 460 to 620)
    # Replace "front" and "Internet magazin"
    draw.rectangle([80, 465, 840, 540], fill=card_bg)
    draw.text((90, 470), "Подготовить ДДУ для ЖК Mirabad", fill=title_color, font=font_title)
    
    draw.rectangle([80, 555, 840, 625], fill=card_bg)
    draw.text((90, 560), "Квартира №104 (1к, 43 м²) · Договор рассрочки", fill=sub_color, font=font_sub)
    
    # Card 2 (Y: 1160 to 1320)
    # Replace "Dostavka" and "Samarqand"
    draw.rectangle([140, 1165, 840, 1240], fill=card_bg)
    draw.text((140, 1170), "Показ пентхауса инвестору", fill=title_color, font=font_title)
    
    draw.rectangle([80, 1255, 840, 1325], fill=card_bg)
    draw.text((90, 1260), "ЖК Sham Back Олмос · Корпус 3, 16 этаж", fill=sub_color, font=font_sub)
    
    # Card 3 (Y: 1720 to 1880)
    # Replace "sdefsdлл" and "Toshkent"
    draw.rectangle([80, 1725, 840, 1800], fill=card_bg)
    draw.text((90, 1730), "Согласование графика оплат", fill=title_color, font=font_title)
    
    draw.rectangle([80, 1815, 840, 1885], fill=card_bg)
    draw.text((90, 1820), "Клиент: Бахтиёр Саидов · Первоначальный взнос 30%", fill=sub_color, font=font_sub)
    
    out_path = f"{MOCKUPS_DIR}/screen_tasks.png"
    im.save(out_path)
    print("Cleaned screen_tasks.png successfully")
    return out_path

# 2. Clean Leads Screenshot (1183 x 2560)
def clean_leads_screenshot():
    src_path = "assets/site/photo_2026-11-09 11.36.52.png"
    im = Image.open(src_path).convert("RGBA")
    draw = ImageDraw.Draw(im)
    
    font_title = get_font(52, bold=True)
    card_bg = (230, 236, 246, 255)
    title_color = (0, 75, 135)
    
    # Card 1 (Y: 460 - 540)
    draw.rectangle([80, 465, 850, 545], fill=card_bg)
    draw.text((90, 470), "Алишер Умаров (Инвестор)", fill=title_color, font=font_title)
    
    # Card 2 (Y: 1060 - 1140)
    # Replace "<test lead: dummy data for full name>"
    draw.rectangle([80, 1065, 1050, 1145], fill=card_bg)
    draw.text((90, 1070), "Улугбек Рахимов (3к, 89 м²)", fill=title_color, font=font_title)
    
    # Card 3 (Y: 1670 - 1750)
    # Replace "Тест(Admin)"
    draw.rectangle([80, 1675, 850, 1755], fill=card_bg)
    draw.text((90, 1680), "Бахтиёр Саидов (ЖК Mirabad)", fill=title_color, font=font_title)
    
    out_path = f"{MOCKUPS_DIR}/screen_leads.png"
    im.save(out_path)
    print("Cleaned screen_leads.png successfully")
    return out_path

# 3. Clean Deal Details Screenshot (591 x 1280)
def clean_deal_screenshot():
    src_path = "assets/site/photo_2026-11-09 11.37.17.png"
    im = Image.open(src_path).convert("RGBA")
    draw = ImageDraw.Draw(im)
    
    font_val = get_font(27, bold=True)
    font_sub = get_font(21, bold=False)
    card_bg = (255, 255, 255, 255)
    text_color = (0, 75, 135)
    sub_color = (120, 140, 160)
    
    # 1. Total price (Y: 235 to 380, X: 260 to 560)
    draw.rectangle([250, 235, 560, 380], fill=card_bg)
    draw.text((545, 245), "100 000 USD", fill=text_color, font=font_val, anchor="ra")
    draw.text((545, 280), "1 270 000 000 сум", fill=sub_color, font=font_sub, anchor="ra")
    
    # 2. Downpayment (Y: 405 to 550)
    draw.rectangle([250, 405, 560, 550], fill=card_bg)
    draw.text((545, 415), "30 000 USD (30%)", fill=text_color, font=font_val, anchor="ra")
    draw.text((545, 450), "381 000 000 сум", fill=sub_color, font=font_sub, anchor="ra")
    
    # 3. Installment sum (Y: 580 to 695)
    draw.rectangle([250, 580, 560, 695], fill=card_bg)
    draw.text((545, 585), "70 000 USD", fill=text_color, font=font_val, anchor="ra")
    draw.text((545, 620), "889 000 000 сум", fill=sub_color, font=font_sub, anchor="ra")
    
    # 4. Monthly payment (Y: 705 to 825)
    draw.rectangle([250, 705, 560, 825], fill=card_bg)
    draw.text((545, 715), "7 000 USD / мес", fill=(16, 150, 80), font=font_val, anchor="ra")
    draw.text((545, 750), "88 900 000 сум", fill=sub_color, font=font_sub, anchor="ra")
    
    out_path = f"{MOCKUPS_DIR}/screen_deal.png"
    im.save(out_path)
    print("Cleaned screen_deal.png successfully")
    return out_path

# 4. Clean Dashboard KPI Screenshot (591 x 1280)
def clean_dashboard_screenshot():
    src_path = "assets/site/photo_2026-11-09 11.37.05.png"
    im = Image.open(src_path).convert("RGBA")
    draw = ImageDraw.Draw(im)
    
    card_bg = (235, 243, 253, 255)
    font_bold = get_font(34, bold=True)
    
    # 50% -> 94%
    draw.rectangle([35, 545, 140, 585], fill=card_bg)
    draw.text((40, 548), "94%", fill=(16, 175, 90), font=font_bold)
    
    # 17/34 -> 32/34
    draw.rectangle([440, 545, 555, 585], fill=card_bg)
    draw.text((545, 548), "32/34", fill=(0, 75, 135), font=font_bold, anchor="ra")
    
    out_path = f"{MOCKUPS_DIR}/screen_dashboard.png"
    im.save(out_path)
    print("Cleaned screen_dashboard.png successfully")
    return out_path

# 5. Build Apple iPhone 18 Pro Max Frame (Silver Titanium + Smooth Apple Shadow)
def create_iphone18_mockup(screen_path, output_filename):
    screen = Image.open(screen_path).convert("RGBA")
    
    target_screen_w = 1179
    target_screen_h = 2556
    screen_resized = screen.resize((target_screen_w, target_screen_h), Image.Resampling.LANCZOS)
    
    pad_x = 70
    pad_top = 70
    pad_bot = 110
    bezel = 22
    
    canvas_w = target_screen_w + (pad_x + bezel) * 2
    canvas_h = target_screen_h + pad_top + pad_bot + bezel * 2
    
    canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    
    # Smooth, natural Apple drop-shadow (Subtle, soft, realistic grey shadow)
    shadow = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    sh_draw = ImageDraw.Draw(shadow)
    
    phone_box = [
        pad_x, 
        pad_top, 
        pad_x + target_screen_w + bezel * 2, 
        pad_top + target_screen_h + bezel * 2
    ]
    
    # Multi-layered shadow for hyper-realism
    sh_draw.rounded_rectangle(
        [phone_box[0] + 12, phone_box[1] + 28, phone_box[2] - 12, phone_box[3] + 48], 
        radius=115, 
        fill=(15, 23, 42, 50)
    )
    sh_draw.rounded_rectangle(
        [phone_box[0] + 6, phone_box[1] + 14, phone_box[2] - 6, phone_box[3] + 24], 
        radius=112, 
        fill=(15, 23, 42, 35)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(32))
    canvas = Image.alpha_composite(canvas, shadow)
    
    draw = ImageDraw.Draw(canvas)
    
    # Titanium Rim (Apple Natural Titanium / Space Silver)
    draw.rounded_rectangle(phone_box, radius=108, fill=(228, 232, 238), outline=(200, 205, 215), width=3)
    
    # Inner display gasket
    gasket_box = [
        phone_box[0] + 5,
        phone_box[1] + 5,
        phone_box[2] - 5,
        phone_box[3] - 5
    ]
    draw.rounded_rectangle(gasket_box, radius=102, fill=(18, 22, 30), outline=(145, 150, 160), width=2)
    
    # Screen display placement
    screen_box = [
        phone_box[0] + bezel,
        phone_box[1] + bezel,
        phone_box[0] + bezel + target_screen_w,
        phone_box[1] + bezel + target_screen_h
    ]
    
    mask = Image.new("L", (target_screen_w, target_screen_h), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, target_screen_w, target_screen_h], radius=82, fill=255)
    
    canvas.paste(screen_resized, (screen_box[0], screen_box[1]), mask)
    
    # Dynamic Island
    di_w = 260
    di_h = 68
    di_x = screen_box[0] + (target_screen_w - di_w) // 2
    di_y = screen_box[1] + 20
    draw.rounded_rectangle([di_x, di_y, di_x + di_w, di_y + di_h], radius=34, fill=(0, 0, 0))
    # Camera aperture
    draw.ellipse([di_x + 36, di_y + 22, di_x + 58, di_y + 44], fill=(12, 12, 18), outline=(25, 25, 35), width=1)
    draw.ellipse([di_x + di_w - 60, di_y + 25, di_x + di_w - 42, di_y + 43], fill=(8, 8, 12))
    
    # Home Indicator
    hb_w = 340
    hb_h = 10
    hb_x = screen_box[0] + (target_screen_w - hb_w) // 2
    hb_y = screen_box[3] - 22
    draw.rounded_rectangle([hb_x, hb_y, hb_x + hb_w, hb_y + hb_h], radius=5, fill=(180, 185, 195, 220))

    out_file = f"{MOCKUPS_DIR}/{output_filename}"
    canvas.save(out_file)
    print(f"Generated: {out_file}")

if __name__ == "__main__":
    t_path = clean_tasks_screenshot()
    l_path = clean_leads_screenshot()
    d_path = clean_deal_screenshot()
    k_path = clean_dashboard_screenshot()
    
    # Core iPhone 18 Pro Max mockups
    create_iphone18_mockup("assets/site/photo_2026-11-09 11.36.39.png", "iphone_chess_matrix.png")
    create_iphone18_mockup("assets/site/photo_2026-11-09 11.36.37.png", "iphone_chess_3d.png")
    create_iphone18_mockup(t_path, "iphone_tasks.png")
    create_iphone18_mockup(l_path, "iphone_leads.png")
    create_iphone18_mockup(d_path, "iphone_deal.png")
    create_iphone18_mockup(k_path, "iphone_dashboard.png")
    create_iphone18_mockup("assets/site/photo_2026-11-09 11.36.18.png", "iphone_telephony.png")
    create_iphone18_mockup("assets/site/photo_2026-11-09 11.36.42.png", "iphone_warehouse.png")
