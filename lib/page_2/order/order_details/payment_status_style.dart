import 'package:flutter/material.dart';

class PaymentStatusStyle {
 final Widget content;
 final Color backgroundColor;

 PaymentStatusStyle({
   required this.content,
   required this.backgroundColor,
 });
}

PaymentStatusStyle getPaymentStatusStyle(String? paymentStatus, BuildContext context) {
 switch (paymentStatus?.toLowerCase()) {
   case 'pending':
     return PaymentStatusStyle(
       content: Text(
         'Ожидает',
         style: const TextStyle(
           fontSize: 12,
           fontFamily: 'Gilroy',
           fontWeight: FontWeight.w500,
           color: Color.fromARGB(255, 242, 242, 242),
         ),
         maxLines: 1,
         overflow: TextOverflow.ellipsis,
       ),
       backgroundColor: Colors.amber[700]!,
     );
   case 'paid':
     return PaymentStatusStyle(
       content: Text(
         'Оплачено',
         style: const TextStyle(
           fontSize: 12,
           fontFamily: 'Gilroy',
           fontWeight: FontWeight.w500,
           color: Color.fromARGB(255, 242, 242, 242),
         ),
         maxLines: 1,
         overflow: TextOverflow.ellipsis,
       ),
       backgroundColor: const Color.fromARGB(255, 23, 178, 36),
     );
   case 'failed':
     return PaymentStatusStyle(
       content: Text(
         'Ошибка',
         style: const TextStyle(
           fontSize: 12,
           fontFamily: 'Gilroy',
           fontWeight: FontWeight.w500,
           color: Color.fromARGB(255, 242, 242, 242),
         ),
         maxLines: 1,
         overflow: TextOverflow.ellipsis,
       ),
       backgroundColor: Colors.red[700]!,
     );
   default:
     return PaymentStatusStyle(
       content: const SizedBox.shrink(),
       backgroundColor: Colors.transparent,
     );
 }
}