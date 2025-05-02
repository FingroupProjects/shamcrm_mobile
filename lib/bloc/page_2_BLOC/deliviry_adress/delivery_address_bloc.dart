// import 'dart:io';
// import 'package:bloc/bloc.dart';
// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'delivery_address_event.dart';
// import 'delivery_address_state.dart';

// class DeliveryAddressBloc extends Bloc<DeliveryAddressEvent, DeliveryAddressState> {
//   final ApiService apiService;

//   DeliveryAddressBloc(this.apiService) : super(DeliveryAddressInitial()) {
//     print('DeliveryAddressBloc: Initialized');
//     on<FetchDeliveryAddresses>(_onFetchDeliveryAddresses);
//   }

//   Future<void> _onFetchDeliveryAddresses(
//       FetchDeliveryAddresses event, Emitter<DeliveryAddressState> emit) async {
//     print('DeliveryAddressBloc: Handling FetchDeliveryAddresses, leadId=${event.leadId}');
//     if (await _checkInternetConnection()) {
//       try {
//         emit(DeliveryAddressLoading());
//         print('DeliveryAddressBloc: Emitted DeliveryAddressLoading');
//         final addresses = await apiService.getDeliveryAddresses(
//           leadId: event.leadId,
//         );
//         print('DeliveryAddressBloc: Addresses fetched: ${addresses.result.map((a) => a.toJson()).toList()}');
//         emit(DeliveryAddressSuccess(addresses: addresses.result));
//         print('DeliveryAddressBloc: Emitted DeliveryAddressSuccess');
//       } catch (e) {
//         print('DeliveryAddressBloc: Error fetching addresses: $e');
//         emit(DeliveryAddressError(message: e.toString()));
//       }
//     } else {
//       print('DeliveryAddressBloc: No internet connection');
//       emit(DeliveryAddressError(
//           message:
//               'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
//     }
//   }

//   Future<bool> _checkInternetConnection() async {
//     try {
//       final result = await InternetAddress.lookup('example.com');
//       final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
//       print('DeliveryAddressBloc: Internet connection check: $isConnected');
//       return isConnected;
//     } on SocketException catch (e) {
//       print('DeliveryAddressBloc: Internet connection error: $e');
//       return false;
//     }
//   }
// }