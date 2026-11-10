from PIL import Image, ImageDraw, ImageFont
import os
import tool.prepare_site_screenshots as prep

get_font = prep.get_font
MOCKUPS_DIR = prep.MOCKUPS_DIR

def fix_tasks_final():
    src_path = "assets/site/photo_2026-11-09 11.36.50.png"
    im = Image.open(src_path).convert("RGBA")
    draw = ImageDraw.Draw(im)
    font_title = get_font(50, bold=True)
    font_sub = get_font(36, bold=False)
    card_bg = (230, 236, 246, 255)
    title_color = (0, 75, 135)
    sub_color = (85, 105, 130)
    
    # Card 1: 'front' is at y: 630 to 760
    draw.rectangle([80, 630, 840, 780], fill=card_bg)
    draw.text((90, 640), "Подготовить ДДУ для ЖК Mirabad", fill=title_color, font=font_title)
    draw.text((90, 710), "Квартира №104 (1к, 43 м²) · Рассрочка 24 мес", fill=sub_color, font=font_sub)
    
    # Card 2: 'Dostavka' is at y: 1120 to 1270
    draw.rectangle([130, 1120, 840, 1270], fill=card_bg)
    draw.text((140, 1130), "Показ пентхауса инвестору", fill=title_color, font=font_title)
    draw.text((90, 1205), "ЖК Sham Back Олмос · Корпус 3, 16 этаж", fill=sub_color, font=font_sub)
    
    # Card 3: 'sdefsdлл' is at y: 1640 to 1790
    draw.rectangle([80, 1640, 840, 1790], fill=card_bg)
    draw.text((90, 1650), "Согласование графика оплат", fill=title_color, font=font_title)
    draw.text((90, 1725), "Клиент: Бахтиёр Саидов · Первоначальный взнос 30%", fill=sub_color, font=font_sub)
    
    out_path = f"{MOCKUPS_DIR}/screen_tasks.png"
    im.save(out_path)
    prep.create_iphone18_mockup(out_path, "iphone_tasks.png")
    print("Tasks perfected!")

def fix_deal_final():
    src_path = "assets/site/photo_2026-11-09 11.37.17.png"
    im = Image.open(src_path).convert("RGBA")
    draw = ImageDraw.Draw(im)
    
    # Clean the ENTIRE card area between y: 180 and y: 825
    card_bg = (255, 255, 255, 255)
    draw.rectangle([40, 180, 550, 825], fill=card_bg)
    
    font_lbl = get_font(21, bold=False)
    font_val = get_font(23, bold=True)
    font_sub = get_font(18, bold=False)
    lbl_col = (20, 30, 45)
    val_col = (0, 75, 135)
    sub_col = (130, 145, 165)
    
    # Header of card
    draw.text((45, 185), "Параметры сделки", fill=(0, 75, 135), font=get_font(25, bold=True))
    draw.rounded_rectangle([420, 182, 545, 218], radius=10, fill=(235, 245, 255), outline=(180, 210, 245), width=1)
    draw.text((482, 200), "Рассрочка", fill=(0, 110, 200), font=get_font(18, bold=True), anchor="mm")
    
    rows = [
        ("Тип сделки:", "Рассрочка (ДДУ)", None),
        ("Общая стоимость:", "100 000 USD", "1 270 000 000 сум"),
        ("Первоначальный взнос:", "30 000 USD (30%)", "381 000 000 сум"),
        ("Срок рассрочки:", "10 месяцев", None),
        ("Сумма рассрочки:", "70 000 USD", "889 000 000 сум"),
        ("Ежемесячная оплата:", "7 000 USD / мес", "88 900 000 сум"),
        ("Дата первого платежа:", "30.11.2026", None)
    ]
    
    y = 235
    for lbl, val, sub in rows:
        draw.text((45, y), lbl, fill=lbl_col, font=font_lbl)
        if sub:
            draw.text((545, y - 5), val, fill=val_col, font=font_val, anchor="ra")
            draw.text((545, y + 23), sub, fill=sub_col, font=font_sub, anchor="ra")
            y += 84
        else:
            draw.text((545, y), val, fill=val_col, font=font_val, anchor="ra")
            y += 66
            
    out_path = f"{MOCKUPS_DIR}/screen_deal.png"
    im.save(out_path)
    prep.create_iphone18_mockup(out_path, "iphone_deal.png")
    print("Deal perfected!")

if __name__ == "__main__":
    fix_tasks_final()
    fix_deal_final()
