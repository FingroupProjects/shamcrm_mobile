import os
import math
from PIL import Image, ImageDraw, ImageFont

OUT_DIR = "shamcrm-website/assets/screenshots"
os.makedirs(OUT_DIR, exist_ok=True)

W, H = 1284, 2778
SCALE = 1.0

# Fonts
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
    draw.text((105, 50), "14:15", fill=fg, font=font)
    
    # Battery icon
    bx, by = 1120, 58
    draw.rounded_rectangle([bx, by, bx + 65, by + 32], radius=8, outline=fg, width=4)
    draw.rectangle([bx + 4, by + 4, bx + 50, by + 28], fill=fg)
    draw.rectangle([bx + 67, by + 10, bx + 70, by + 22], fill=fg)
    
    # Wifi icon
    wx, wy = 1050, 72
    draw.arc([wx - 25, wy - 25, wx + 25, wy + 25], start=210, end=330, fill=fg, width=4)
    draw.arc([wx - 16, wy - 16, wx + 16, wy + 16], start=210, end=330, fill=fg, width=4)
    draw.ellipse([wx - 4, wy + 4, wx + 4, wy + 12], fill=fg)

def draw_bottom_nav(draw, active_idx=0):
    nav_y = H - 240
    # blurred background bar
    draw.rounded_rectangle([40, nav_y, W - 40, nav_y + 160], radius=50, fill=(16, 24, 45, 240), outline=(40, 56, 95), width=2)
    
    tabs = [
        ("Дашборд", "assets/icons/MyNavBar/dashboard_ON.png"),
        ("Шахматка", "assets/icons/MyNavBar/google-docs (5).png"),
        ("Задачи", "assets/icons/MyNavBar/tasks_ON.png"),
        ("Лиды", "assets/icons/MyNavBar/clients_ON.png"),
        ("Сделки", "assets/icons/MyNavBar/deal_ON.png"),
    ]
    
    font_active = get_font(28, bold=True)
    font_inactive = get_font(26, bold=False)
    
    item_w = (W - 80) // len(tabs)
    for i, (name, icon_path) in enumerate(tabs):
        cx = 40 + i * item_w + item_w // 2
        is_active = (i == active_idx)
        
        if is_active:
            draw.rounded_rectangle([cx - 95, nav_y + 20, cx + 95, nav_y + 140], radius=35, fill=(0, 163, 255, 230))
            text_color = (255, 255, 255)
            # icon placeholder or circle
            draw.ellipse([cx - 24, nav_y + 36, cx + 24, nav_y + 84], fill=(255, 255, 255, 200))
            draw.text((cx, nav_y + 115), name, fill=text_color, font=font_active, anchor="ms")
        else:
            text_color = (130, 145, 175)
            draw.ellipse([cx - 20, nav_y + 42, cx + 20, nav_y + 82], outline=text_color, width=3)
            draw.text((cx, nav_y + 115), name, fill=text_color, font=font_inactive, anchor="ms")

print("Generator helper defined successfully")
