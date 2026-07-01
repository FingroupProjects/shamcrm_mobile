import json
import os

langs = {
    'ru': 'Скопировано',
    'en': 'Copied',
    'uz': 'Nusxalandi'
}

for lang, translation in langs.items():
    file_path = f"assets/langs/{lang}.json"
    if os.path.exists(file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        data['copied_to_clipboard'] = translation
        
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            # Flutter expects typical json, adding a newline at end is good practice
            f.write('\n')
        print(f"Updated {file_path}")

