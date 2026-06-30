import json

langs = {
    'ru': 'assets/langs/ru.json',
    'en': 'assets/langs/en.json',
    'uz': 'assets/langs/uz.json',
}

new_keys = {
    'ru': {
        "barcode_not_found": "Товар не найден",
        "barcode_scan_error": "Ошибка поиска товара",
        "barcode_item_added": "Товар добавлен",
        "barcode_quantity_increased": "Количество увеличено",
        "search_item": "Поиск товара",
        "search_barcode_or_name": "Поиск..."
    },
    'en': {
        "barcode_not_found": "Item not found",
        "barcode_scan_error": "Error searching item",
        "barcode_item_added": "Item added",
        "barcode_quantity_increased": "Quantity increased",
        "search_item": "Search item",
        "search_barcode_or_name": "Search..."
    },
    'uz': {
        "barcode_not_found": "Mahsulot topilmadi",
        "barcode_scan_error": "Qidiruv xatosi",
        "barcode_item_added": "Mahsulot qo'shildi",
        "barcode_quantity_increased": "Miqdori oshirildi",
        "search_item": "Mahsulotni qidirish",
        "search_barcode_or_name": "Qidiruv..."
    }
}

for lang, path in langs.items():
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    for k, v in new_keys[lang].items():
        data[k] = v
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"Updated {path}")
