import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/page_2/good_variants_model.dart';

@immutable
sealed class GetAllGoodsListEvent {}

class GetAllGoodsListEv extends GetAllGoodsListEvent {}

class RefreshAllGoodsListEv extends GetAllGoodsListEvent {}

// Внутреннее событие для обновления данных в фоне
class UpdateGoodsListInBackground extends GetAllGoodsListEvent {
  final List<GoodVariantItem> data;
  final int totalPages;
  
  UpdateGoodsListInBackground(this.data, this.totalPages);
}

