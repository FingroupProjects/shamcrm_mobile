from PIL import Image, ImageDraw, ImageFont
import os
import tool.prepare_site_screenshots as prep

get_font = prep.get_font
MOCKUPS_DIR = prep.MOCKUPS_DIR

# Fix Tasks:
def fix_tasks():
    src_path = "assets/site/photo_2026-11-09 11.36.50.png"
    im = Image.open(src_path).convert("RGBA")
    draw = ImageDraw.Draw(im)
    font_title = get_font(50, bold=True)
    font_sub = get_font(36, bold=False)
    card_bg = (230, 236, 246, 255)
    title_color = (0, 75, 135)
    sub_color = (85, 105, 130)
    
    # Card 1: 'front' is at y: 640 to 760
    draw.rectangle([80, 640, 840, 780], fill=card_bg)
    draw.text((90, 645), "Подготовить ДДУ для ЖК Mirabad", fill=title_color, font=font_title)
    draw.text((90, 715), "Квартира №104 (1к, 43 м²) · Рассрочка 24 мес", fill=sub_color, font=font_sub)
    
    # Card 2: 'Dostavka' at y: 1200 to 1340
    draw.rectangle([140, 1200, 840, 1340], fill=card_bg)
    draw.text((140, 1205), "Показ пентхауса инвестору", fill=title_color, font=font_title)
    draw.text((90, 1275), "ЖК Sham Back Олмос · Корпус 3, 16 этаж", fill=sub_color, font=font_sub)
    
    # Card 3: 'sdefsdлл' at y: 1760 to 1900
    draw.rectangle([80, 1760, 840, 1900], fill=card_bg)
    draw.text((90, 1765), "Согласование графика оплат", fill=title_color, font=font_title)
    draw.text((90, 1835), "Клиент: Бахтиёр Саидов · Первоначальный взнос 30%", fill=sub_color, font=font_sub)
    
    out_path = f"{MOCKUPS_DIR}/screen_tasks.png"
    im.save(out_path)
    prep.create_iphone18_mockup(out_path, "iphone_tasks.png")
    print("Tasks fixed and regenerated")

# Fix Deal:
def fix_deal():
    src_path = "assets/site/photo_2026-11-09 11.37.17.png"
    im = Image.open(src_path).convert("RGBA")
    draw = ImageDraw.Draw(im)
    
    # Re-draw the clean parameters table
    # Area of table: x: 42 to 550, y: 200 to 860
    card_bg = (255, 255, 255, 255)
    draw.rectangle([42, 205, 550, 850], fill=card_bg)
    
    font_lbl = get_font(21, bold=False)
    font_val = get_font(23, bold=True)
    font_sub = get_font(18, bold=False)
    lbl_col = (20, 30, 45)
    val_col = (0, 75, 135)
    sub_col = (130, 145, 165)
    
    rows = [
        ("Тип сделки:", "Рассрочка (ДДУ)", None),
        ("Общая стоимость:", "100 000 USD", "1 270 000 000 сум"),
        ("Первоначальный взнос:", "30 000 USD (30%)", "381 000 000 сум"),
        ("Срок рассрочки:", "10 месяцев", None),
        ("Сумма рассрочки:", "70 000 USD", "889 000 000 сум"),
        ("Ежемесячная оплата:", "7 000 USD / мес", "88 900 000 сум"),
        ("Дата первого платежа:", "30.11.2026", None)
    ]
    
    y = 230
    for lbl, val, sub in rows:
        draw.text((45, y), lbl, fill=lbl_col, font=font_lbl)
        if sub:
            draw.text((545, y - 6), val, fill=val_col, font=font_val, anchor="ra")
            draw.text((545, y + 22), sub, fill=sub_col, font=font_sub, anchor="ra")
            y += 82
        else:
            draw.text((545, y), val, fill=val_col, font=font_val, anchor="ra")
            y += 65
            
    out_path = f"{MOCKUPS_DIR}/screen_deal.png"
    im.save(out_path)
    prep.create_iphone18_mockup(out_path, "iphone_deal.png")
    print("Deal fixed and regenerated")

if __name__ == "__main__":
    fix_tasks()
    fix_deal()
