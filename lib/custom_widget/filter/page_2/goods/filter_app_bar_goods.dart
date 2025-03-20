import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/goods/category_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';


class GoodsFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;

  GoodsFilterScreen({
    Key? key,
    this.onSelectedDataFilter,
    this.onResetFilters, 
  }) : super(key: key);

  @override
  _GoodsFilterScreenState createState() => _GoodsFilterScreenState();
}

class _GoodsFilterScreenState extends State<GoodsFilterScreen> {

  final TextEditingController priceController = TextEditingController();
  final TextEditingController discountPriceController = TextEditingController();
  final TextEditingController stockQuantityController = TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;
  String? selectedCategory;
  bool isActive = false;



  @override
  void initState() {
    super.initState();
   
    // _fromDate = widget.initialFromDate;
    // _toDate = widget.initialToDate;

  }

  void _selectDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );
    if (pickedRange != null) {
      setState(() {
        _fromDate = pickedRange.start;
        _toDate = pickedRange.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF4F7FD),
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
         AppLocalizations.of(context)!.translate('filter'),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xfff1E2E52), fontFamily: 'Gilroy'),
        ),
        backgroundColor: Colors.white,
        forceMaterialTransparency: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                widget.onResetFilters?.call(); 
                _fromDate = null;
                _toDate = null;
              });
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: Colors.blueAccent, width: 0.5),
            ),
            child: Text(
             AppLocalizations.of(context)!.translate('reset'),
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w600, 
                color: Colors.blueAccent,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          SizedBox(width: 10),
          TextButton(
            onPressed: () async {
              bool isAnyFilterSelected =  _fromDate != null || _toDate != null;
              if (isAnyFilterSelected) {
                print('Start Filter');
                widget.onSelectedDataFilter?.call({
                  'fromDate': _fromDate,
                  'toDate': _toDate,
                });
              } else {
                print('NOTHING!!!!!!');
              }
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: Colors.blueAccent, width: 0.5),
            ),
            child: Text(
             AppLocalizations.of(context)!.translate('apply'),
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w600, 
                color: Colors.blueAccent,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
       body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: GestureDetector(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fromDate != null && _toDate != null
                                    ? "${_fromDate!.day.toString().padLeft(2, '0')}.${_fromDate!.month.toString().padLeft(2, '0')}.${_fromDate!.year} - ${_toDate!.day.toString().padLeft(2, '0')}.${_toDate!.month.toString().padLeft(2, '0')}.${_toDate!.year}"
                                    : AppLocalizations.of(context)!.translate('select_date_range'),
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  color: _fromDate != null && _toDate != null ? Colors.black : Color(0xff99A4BA), 
                                  fontSize: 14,
                                ),
                              ),
                              Icon(Icons.calendar_today, color: Color(0xff99A4BA)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  CategoryDropdownWidget(
                    selectedCategory: selectedCategory,
                    onSelectCategory: (category) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: priceController,
                  hintText: AppLocalizations.of(context)!.translate('enter_goods_price'),
                  label: AppLocalizations.of(context)!.translate('goods_price'),
                    keyboardType: TextInputType.number,
                    backgroundColor: Colors.white, 
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: discountPriceController,
                  hintText: AppLocalizations.of(context)!.translate('enter_discount_price'),
                  label: AppLocalizations.of(context)!.translate('discount_price'),
                    keyboardType: TextInputType.number,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: stockQuantityController,
                  hintText: AppLocalizations.of(context)!.translate('enter_stock_quantity'),
                  label: AppLocalizations.of(context)!.translate('stock_quantity'),
                    keyboardType: TextInputType.number,
                    backgroundColor: Colors.white, 
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.translate('status_goods'), 
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                                color: Color(0xff1E2E52),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isActive = !isActive;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Switch(
                                      value: isActive,
                                      onChanged: (value) {
                                        setState(() {
                                          isActive = value;
                                        });
                                      },
                                      activeColor: const Color.fromARGB(255, 255, 255, 255),
                                      inactiveTrackColor: const Color.fromARGB(255, 179, 179, 179).withOpacity(0.5),
                                      activeTrackColor: ChatSmsStyles.messageBubbleSenderColor,
                                      inactiveThumbColor: const Color.fromARGB(255, 255, 255, 255),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      isActive ? AppLocalizations.of(context)!.translate('active') : AppLocalizations.of(context)!.translate('inactive'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Gilroy',
                                        color: Color(0xFF1E1E1E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}