import re
import os

files = [
    "lib/page_2/warehouse/client_sale/create_clien_sales_document_screen.dart",
    "lib/page_2/warehouse/client_sale/edit_client_sales_document_screen.dart",
    "lib/page_2/warehouse/client_return/client_return_create.dart",
    "lib/page_2/warehouse/client_return/client_return_edit.dart",
    "lib/page_2/warehouse/incoming/incoming_document_create_screen.dart",
    "lib/page_2/warehouse/incoming/incoming_document_update_screen.dart",
    "lib/page_2/warehouse/movement/movement_create.dart",
    "lib/page_2/warehouse/movement/movement_edit.dart",
    "lib/page_2/warehouse/write_off/write_off_create.dart",
    "lib/page_2/warehouse/write_off/write_off_edit.dart",
    "lib/page_2/warehouse/supplier_return_document/supplier_return_document_create_screen.dart",
    "lib/page_2/warehouse/supplier_return_document/supplier_return_document_edit_screen.dart",
]

for file in files:
    if not os.path.exists(file):
        print(f"Skipping {file}, not found")
        continue

    with open(file, 'r') as f:
        content = f.read()

    # 4. Modify actions to remove showManualSearchDialog and use inline search
    # We use regex to match the actions block containing BarcodeAppBarButton

    actions_pattern = r"""      actions: \[\s*(//.*?\n\s*)?BarcodeAppBarButton\(\s*isLoading: _isBarcodeLoading,\s*onPressed: _handleBarcodeScanning,\s*onSearchPressed: \(\) async \{\s*final manualBarcode = await showManualSearchDialog\(context\);\s*if \(manualBarcode != null && manualBarcode\.isNotEmpty\) \{\s*await _handleBarcodeScanning\(manualBarcode: manualBarcode\);\s*\}\s*\},\s*\),\s*\],"""

    actions_new = """      actions: [
        if (!_isSearching)
          BarcodeAppBarButton(
            isLoading: _isBarcodeLoading,
            onPressed: _handleBarcodeScanning,
            onSearchPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
      ],"""

    content, count = re.subn(actions_pattern, actions_new, content)

    if count > 0:
        with open(file, 'w') as f:
            f.write(content)
        print(f"Updated actions in {file}")
    else:
        print(f"No changes for actions in {file} (pattern not found)")
