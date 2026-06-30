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

    # 1. Update _handleBarcodeScanning signature
    old_sig = "Future<void> _handleBarcodeScanning() async {"
    new_sig = "Future<void> _handleBarcodeScanning({String? manualBarcode}) async {"
    content = content.replace(old_sig, new_sig)

    # 2. Update openBarcodeScanner call
    old_scan = "final barcode = await openBarcodeScanner(context);"
    new_scan = "final barcode = manualBarcode ?? await openBarcodeScanner(context);"
    content = content.replace(old_scan, new_scan)

    # 3. Update BarcodeAppBarButton
    old_btn = """        BarcodeAppBarButton(
          isLoading: _isBarcodeLoading,
          onPressed: _handleBarcodeScanning,
        ),"""
    new_btn = """        BarcodeAppBarButton(
          isLoading: _isBarcodeLoading,
          onPressed: _handleBarcodeScanning,
          onSearchPressed: () async {
            final manualBarcode = await showManualSearchDialog(context);
            if (manualBarcode != null && manualBarcode.isNotEmpty) {
              await _handleBarcodeScanning(manualBarcode: manualBarcode);
            }
          },
        ),"""
    content = content.replace(old_btn, new_btn)

    with open(file, 'w') as f:
        f.write(content)
    print(f"Updated {file}")
