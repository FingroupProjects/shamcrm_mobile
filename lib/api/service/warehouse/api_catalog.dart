part of '../api_service.dart';

extension ApiWarehouseCatalogX on ApiService {
  Future<void> markPageCompleted(String section, String pageType) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/tutorials/markPageCompleted');
    if (kDebugMode) {
      //debugPrint('ApiService: markPageCompleted - Generated path: $path');
    }

    final response = await _postRequest(
      path,
      {
        "section": section,
        "page_type": pageType,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark page completed: ${response.statusCode}');
    }
  }

  Future<CharacteristicListDataResponse> getAllCharacteristics() async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/attribute');
    if (kDebugMode) {
      //debugPrint('ApiService: getAllCharacteristics - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return CharacteristicListDataResponse.fromJson(data);
    } else {
      throw ('Ошибка загрузки списка характеритсикии');
    }
  }

  Future<List<CategoryData>> getCategory({String? search}) async {
    String path = '/category';
    if (search != null && search.isNotEmpty) {
      path += '?search=$search';
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //debugPrint('ApiService: getCategory - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.containsKey('result') && data['result'] is List) {
        return (data['result'] as List)
            .map((category) =>
                CategoryData.fromJson(category as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      throw Exception('Ошибка загрузки категории: ${response.statusCode}');
    }
  }

  Future<SubCategoryResponseASD> getSubCategoryById(int categoryId) async {
    try {
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path =
          await _appendQueryParams('/category/get-by-parent-id/$categoryId');
      if (kDebugMode) {
        //debugPrint('ApiService: getSubCategoryById - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedJson = json.decode(response.body);
        ////debugPrint(decodedJson);
        return SubCategoryResponseASD.fromJson(decodedJson);
      } else {
        throw Exception(
            'Failed to load subcategories. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load subcategories: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createCategory({
    required String name,
    required int parentId,
    required List<Map<String, dynamic>> attributes,
    File? image,
    required String displayType,
    required bool hasPriceCharacteristics,
    required bool isParent, // Добавляем новый параметр
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/category');
      if (kDebugMode) {
        //debugPrint('ApiService: createCategory - Generated path: $path');
      }

      var uri = Uri.parse('$baseUrl$path');
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      request.fields['name'] = name;
      if (parentId != 0) {
        request.fields['parent_id'] = parentId.toString();
      }
      request.fields['display_type'] = displayType;
      request.fields['has_price_characteristics'] =
          hasPriceCharacteristics ? '1' : '0';
      request.fields['is_parent'] =
          isParent ? '1' : '0'; // Добавляем поле is_parent

      for (int i = 0; i < attributes.length; i++) {
        request.fields['attributes[$i][attribute]'] = attributes[i]['name'];
        request.fields['attributes[$i][is_individual]'] =
            attributes[i]['is_individual'] ? '1' : '0';
      }

      if (image != null) {
        final imageFile =
            await http.MultipartFile.fromPath('image', image.path);
        request.files.add(imageFile);
      }

      final response = await _multipartPostRequest('', request);

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'category_created_successfully',
          'data': CategoryData.fromJson(responseBody),
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to create category',
          'error': responseBody,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ',
      };
    }
  }

  Future<Map<String, dynamic>> updateCategory({
    required int categoryId,
    required String name,
    File? image,
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/category/update/$categoryId');
      if (kDebugMode) {
        //debugPrint('ApiService: updateCategory - Generated path: $path');
      }

      var uri = Uri.parse('$baseUrl$path');
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      request.fields['name'] = name;

      if (image != null) {
        final imageFile =
            await http.MultipartFile.fromPath('image', image.path);
        request.files.add(imageFile);
      }

      final response = await _multipartPostRequest('', request);
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Категория успешно обновлена',
          'data': responseBody,
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to update category',
          'error': responseBody,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ',
      };
    }
  }

  Future<Map<String, dynamic>> deleteCategory(int categoryId) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final path = await _appendQueryParams('/category/$categoryId');
    if (kDebugMode) {
      //debugPrint('ApiService: deleteCategory - Generated path: $path');
    }

    final response = await _deleteRequest(path);

    if (response.statusCode == 200) {
      return {'result': 'Success'};
    } else {
      throw Exception('Failed to delete category!');
    }
  }

  Future<Map<String, dynamic>> updateSubCategory({
    required int subCategoryId,
    required String name,
    File? image,
    required List<Map<String, dynamic>> attributes,
    required String displayType,
    required bool hasPriceCharacteristics,
  }) async {
    try {
      final token = await getToken();
      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/category/update/$subCategoryId');
      if (kDebugMode) {
        //debugPrint('ApiService: updateSubCategory - Generated path: $path');
      }

      var uri = Uri.parse('$baseUrl$path');
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Device': 'mobile'
      });

      request.fields['name'] = name;
      request.fields['display_type'] = displayType;
      request.fields['has_price_characteristics'] =
          hasPriceCharacteristics ? '1' : '0';

      for (int i = 0; i < attributes.length; i++) {
        request.fields['attributes[$i][attribute]'] = attributes[i]['name'];
        request.fields['attributes[$i][is_individual]'] =
            attributes[i]['is_individual'] ? '1' : '0';
      }

      if (image != null) {
        final imageFile =
            await http.MultipartFile.fromPath('image', image.path);
        request.files.add(imageFile);
      }

      final response = await _multipartPostRequest('', request);
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'subcategory_updated_successfully',
          'data': responseBody,
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'failed_to_update_subcategory',
          'error': responseBody,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'error_occurred: ',
      };
    }
  }

  Future<List<Goods>> getGoods({
    int page = 1,
    int perPage = 20,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    String path = '/good?page=$page&per_page=$perPage';
    if (search != null && search.isNotEmpty) {
      path += '&search=$search&barCode=$search';
    }

    if (filters != null) {
      if (filters.containsKey('category_id') &&
          filters['category_id'] is List &&
          (filters['category_id'] as List).isNotEmpty) {
        final categoryIds = filters['category_id'] as List;
        for (int i = 0; i < categoryIds.length; i++) {
          path += '&category_id[]=${categoryIds[i]}';
        }
      }

      if (filters.containsKey('discount_percent')) {
        path += '&discount=${filters['discount_percent']}';
      }

      if (filters.containsKey('label_id') &&
          filters['label_id'] is List &&
          (filters['label_id'] as List).isNotEmpty) {
        final labelIds = filters['label_id'] as List<String>;
        for (var labelId in labelIds) {
          path += '&label_id[]=$labelId';
        }
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлены label_id: $labelIds');
        }
      }

      if (filters.containsKey('is_active')) {
        path += '&is_active=${filters['is_active'] ? 1 : 0}';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр is_active: ${filters['is_active']}');
        }
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //debugPrint('ApiService: getGoods - Generated path: $path');
    }

    final response = await _getRequest(
      path,
      timeout: ApiService._slowListRequestTimeout,
    );
    if (kDebugMode) {
      //debugPrint(
      // 'ApiService: Ответ сервера: statusCode=${response.statusCode}, body=${response.body}');
    }
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result') && data['result']['data'] is List) {
        final goods = (data['result']['data'] as List)
            .map((item) => Goods.fromJson(item as Map<String, dynamic>))
            .toList();
        final total = data['result']['total'] ?? goods.length;
        final totalPages = data['result']['total_pages'] ??
            (goods.length < perPage ? page : page + 1);
        if (kDebugMode) {
          //debugPrint(
          // 'ApiService: Успешно получено ${goods.length} товаров, всего: $total, страниц: $totalPages');
        }
        return goods;
      } else {
        if (kDebugMode) {
          //debugPrint('ApiService: Ошибка формата данных: $data');
        }
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      if (kDebugMode) {
        //debugPrint('ApiService: Ошибка загрузки товаров: ${response.statusCode}');
      }
      throw Exception('Ошибка загрузки товаров: ${response.statusCode}');
    }
  }

  Future<List<Goods>> getGoodsById(int goodsId,
      {bool isFromOrder = false}) async {
    // Выбираем эндпоинт в зависимости от контекста
    final String path =
        isFromOrder ? '/good/variant-by-id/$goodsId' : '/good/$goodsId';

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final updatedPath = await _appendQueryParams(path);
    if (kDebugMode) {
      //debugPrint('ApiService: getGoodsById - Generated path: $updatedPath');
    }

    final response = await _getRequest(updatedPath);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('result')) {
        return [Goods.fromJson(data['result'] as Map<String, dynamic>)];
      } else {
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      throw Exception(
          'Ошибка загрузки просмотра товаров: ${response.statusCode}');
    }
  }

  Future<List<SubCategoryAttributesData>> getSubCategoryAttributes({
    String? search,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    final encodedSearch = search?.trim();
    final basePath = encodedSearch != null && encodedSearch.isNotEmpty
        ? '/category/get/subcategories?search=${Uri.encodeQueryComponent(encodedSearch)}'
        : '/category/get/subcategories';
    final path = await _appendQueryParams(basePath);
    if (kDebugMode) {
      //debugPrint('ApiService: getSubCategoryAttributes - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      ////debugPrint('Response data: $data'); // Debug: //print the response
      if (data.containsKey('data')) {
        return (data['data'] as List).map((item) {
          ////debugPrint('Item: $item'); // Debug: //print each item
          return SubCategoryAttributesData.fromJson(
              item as Map<String, dynamic>);
        }).toList();
      } else {
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      throw Exception(
          'Ошибка загрузки просмотра товаров: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createGoods({
    required bool isService,
    required String name,
    String? barcode,
    required int parentId,
    required String description,
    required int? quantity,
    required int? unitId,
    required List<Map<String, dynamic>> attributes,
    required List<Map<String, dynamic>> variants,
    required List<File> images,
    required bool isActive,
    // double? discountPrice,
    double? price,
    int? storageId,
    int? mainImageIndex,
    int? labelId, // Parameter for label ID
    String? productionType,
    List<Map<String, dynamic>> materialGoods = const [],
    List<Map<String, dynamic>> relatedGoods = const [],
  }) async {
    try {
      final requestBody = await _buildGoodsRequestBody(
        isService: isService,
        name: name,
        barcode: barcode,
        parentId: parentId,
        description: description,
        quantity: quantity,
        unitId: unitId,
        attributes: attributes,
        variants: variants,
        isActive: isActive,
        price: price,
        storageId: storageId,
        labelId: labelId,
        productionType: productionType,
        materialGoods: materialGoods,
        relatedGoods: relatedGoods,
      );

      final hasFiles = await _goodsRequestHasFiles(images, variants);

      late final http.Response response;

      if (!hasFiles) {
        response = await _postRequest('/good', requestBody);
      } else {
        final token = await getToken();
        final path = await _appendQueryParams('/good');
        var uri = Uri.parse('$baseUrl$path');
        var request = http.MultipartRequest('POST', uri);
        request.headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Device': 'mobile',
          'Content-Type': 'multipart/form-data; charset=utf-8',
        });

        request.fields['name'] = name;
        request.fields['barcode'] = barcode ?? '';
        request.fields['category_id'] = parentId.toString();
        request.fields['description'] = description;
        request.fields['quantity'] = quantity?.toString() ?? 'null';
        request.fields['unit_id'] = unitId?.toString() ?? 'null';
        request.fields['label_id'] = labelId?.toString() ?? '';
        request.fields['is_active'] = isActive ? '1' : '0';
        request.fields['is_popular'] = '0';
        request.fields['is_new'] = '0';
        request.fields['is_sale'] = '0';
        request.fields['is_service'] = isService ? '1' : '0';
        request.fields['is_subscription'] = '0';
        request.fields['price'] = (price ?? 0).toString();

        final organizationId = await getSelectedOrganization();
        final salesFunnelId = await getSelectedSalesFunnel();
        request.fields['organization_id'] = organizationId ?? '1';
        request.fields['sales_funnel_id'] = salesFunnelId ?? '1';

        if (productionType != null && productionType.isNotEmpty) {
          request.fields['production_type'] = productionType;
        }

        if (storageId != null) {
          request.fields['storage_id'] = storageId.toString();
          request.fields['branch_id'] = storageId.toString();
        }

        for (int i = 0; i < materialGoods.length; i++) {
          final material = materialGoods[i];
          request.fields['good_ids[$i][good_id]'] =
              material['good_id'].toString();
          request.fields['good_ids[$i][norm]'] = material['norm'].toString();
        }

        for (int i = 0; i < relatedGoods.length; i++) {
          final related = relatedGoods[i];
          request.fields['related_goods[$i][variant_id]'] =
              related['variant_id'].toString();
          request.fields['related_goods[$i][is_required]'] =
              _boolToMultipartFlag(related['is_required']);
        }

        for (int i = 0; i < attributes.length; i++) {
          request.fields['attributes[$i][category_attribute_id]'] =
              attributes[i]['category_attribute_id'].toString();
          request.fields['attributes[$i][value]'] =
              attributes[i]['value'].toString();
        }

        for (int i = 0; i < variants.length; i++) {
          request.fields['variants[$i][is_active]'] =
              variants[i]['is_active'] ? '1' : '0';
          final variantPrice = variants[i]['price'] ?? 0.0;
          request.fields['variants[$i][price]'] = variantPrice.toString();
          if (variants[i]['barcode'] != null &&
              variants[i]['barcode'].toString().isNotEmpty) {
            request.fields['variants[$i][barcode]'] =
                variants[i]['barcode'].toString();
          }

          List<dynamic> variantAttributes =
              variants[i]['variant_attributes'] ?? [];
          for (int j = 0; j < variantAttributes.length; j++) {
            request.fields[
                    'variants[$i][variant_attributes][$j][category_attribute_id]'] =
                variantAttributes[j]['category_attribute_id'].toString();
            request.fields['variants[$i][variant_attributes][$j][value]'] =
                variantAttributes[j]['value'].toString();
          }

          List<File> variantFiles = variants[i]['files'] ?? [];
          for (int j = 0; j < variantFiles.length; j++) {
            File file = variantFiles[j];
            if (await file.exists()) {
              final imageFile = await http.MultipartFile.fromPath(
                  'variants[$i][files][$j]', file.path);
              request.files.add(imageFile);
            }
          }
        }

        for (int i = 0; i < images.length; i++) {
          File file = images[i];
          if (await file.exists()) {
            final imageFile =
                await http.MultipartFile.fromPath('files[$i][file]', file.path);
            request.files.add(imageFile);
            request.fields['files[$i][is_main]'] =
                (i == (mainImageIndex ?? 0)) ? '1' : '0';
          }
        }

        response = await _multipartPostRequest('', request);
      }

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Товар успешно создан',
          'data': responseBody,
        };
      } else {
        String errorMessage =
            responseBody['message'] ?? 'Не удалось создать товар';
        // Локализуем ошибку штрих-кода
        final errors = responseBody['errors'] as Map<String, dynamic>?;
        final bool hasBarcodeError = errors != null &&
            errors.keys.any((k) =>
                k == 'barcode' ||
                k.startsWith('variants.') && k.endsWith('.barcode'));
        if (hasBarcodeError || errorMessage.contains('barcode')) {
          errorMessage = 'Такое значение штрих кода уже существует';
        }
        return {
          'success': false,
          'message': errorMessage,
          'error': responseBody,
        };
      }
    } catch (e, stackTrace) {
      // //debugPrint('ApiService: Error in createGoods: $e');
      // //debugPrint('ApiService: Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Произошла ошибка',
      };
    }
  }

  Future<Map<String, dynamic>> updateGoods({
    required bool isService,
    required int goodId,
    required String name,
    String? barcode,
    required int parentId,
    required String description,
    required int? quantity,
    int? unitId,
    required List<Map<String, dynamic>> attributes,
    required List<Map<String, dynamic>> variants,
    required List<File> images,
    required bool isActive,
    double? discountPrice,
    required int? storageId,
    String? comments,
    int? mainImageIndex,
    int? labelId, // Добавляем параметр для ID метки
    String? productionType,
    List<Map<String, dynamic>> materialGoods = const [],
    List<Map<String, dynamic>> relatedGoods = const [],
  }) async {
    try {
      final requestBody = await _buildGoodsRequestBody(
        isService: isService,
        name: name,
        barcode: barcode,
        parentId: parentId,
        description: description,
        quantity: quantity,
        unitId: unitId,
        attributes: attributes,
        variants: variants,
        isActive: isActive,
        price: discountPrice,
        storageId: storageId,
        labelId: labelId,
        productionType: productionType,
        materialGoods: materialGoods,
        relatedGoods: relatedGoods,
        comments: comments,
      );

      final hasFiles = await _goodsRequestHasFiles(images, variants);

      late final http.Response response;

      if (!hasFiles) {
        response = await _postRequest('/good/$goodId', requestBody);
      } else {
        final token = await getToken();
        final path = await _appendQueryParams('/good/$goodId');
        var uri = Uri.parse('$baseUrl$path');
        var request = http.MultipartRequest('POST', uri);
        request.headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Device': 'mobile',
          'Content-Type': 'multipart/form-data; charset=utf-8',
        });

        request.fields['name'] = name;
        request.fields['barcode'] = barcode ?? '';
        request.fields['category_id'] = parentId.toString();
        request.fields['description'] = description;
        request.fields['quantity'] = quantity?.toString() ?? 'null';
        request.fields['label_id'] = labelId?.toString() ?? '';
        request.fields['is_active'] = isActive ? '1' : '0';
        request.fields['is_popular'] = '0';
        request.fields['is_new'] = '0';
        request.fields['is_sale'] = '0';
        request.fields['is_service'] = isService ? '1' : '0';
        request.fields['is_subscription'] = '0';
        request.fields['price'] = (discountPrice ?? 0).toString();

        final organizationId = await getSelectedOrganization();
        final salesFunnelId = await getSelectedSalesFunnel();
        request.fields['organization_id'] = organizationId ?? '1';
        request.fields['sales_funnel_id'] = salesFunnelId ?? '1';

        if (productionType != null && productionType.isNotEmpty) {
          request.fields['production_type'] = productionType;
        }

        if (unitId != null) {
          request.fields['unit_id'] = unitId.toString();
        } else {
          request.fields['unit_id'] = 'null';
        }

        if (storageId != null) {
          request.fields['branch_id'] = storageId.toString();
          request.fields['storage_id'] = storageId.toString();
        }
        if (comments != null && comments.isNotEmpty) {
          request.fields['comments'] = comments;
        }

        for (int i = 0; i < materialGoods.length; i++) {
          final material = materialGoods[i];
          request.fields['good_ids[$i][good_id]'] =
              material['good_id'].toString();
          request.fields['good_ids[$i][norm]'] = material['norm'].toString();
        }

        for (int i = 0; i < relatedGoods.length; i++) {
          final related = relatedGoods[i];
          request.fields['related_goods[$i][variant_id]'] =
              related['variant_id'].toString();
          request.fields['related_goods[$i][is_required]'] =
              _boolToMultipartFlag(related['is_required']);
        }

        for (int i = 0; i < attributes.length; i++) {
          request.fields['attributes[$i][category_attribute_id]'] =
              attributes[i]['category_attribute_id'].toString();
          request.fields['attributes[$i][value]'] =
              attributes[i]['value'].toString();
        }

        for (int i = 0; i < variants.length; i++) {
          if (variants[i].containsKey('id')) {
            request.fields['variants[$i][id]'] = variants[i]['id'].toString();
          }
          request.fields['variants[$i][is_active]'] =
              variants[i]['is_active'] ? '1' : '0';
          request.fields['variants[$i][price]'] =
              (variants[i]['price'] ?? 0.0).toString();
          if (variants[i]['barcode'] != null &&
              variants[i]['barcode'].toString().isNotEmpty) {
            request.fields['variants[$i][barcode]'] =
                variants[i]['barcode'].toString();
          }

          List<dynamic> variantAttributes =
              variants[i]['variant_attributes'] ?? [];
          for (int j = 0; j < variantAttributes.length; j++) {
            if (variantAttributes[j].containsKey('id')) {
              request.fields['variants[$i][variant_attributes][$j][id]'] =
                  variantAttributes[j]['id'].toString();
            }
            request.fields[
                    'variants[$i][variant_attributes][$j][category_attribute_id]'] =
                variantAttributes[j]['category_attribute_id'].toString();
            request.fields['variants[$i][variant_attributes][$j][value]'] =
                variantAttributes[j]['value'].toString();
          }

          List<File> variantFiles = variants[i]['files'] ?? [];
          for (int j = 0; j < variantFiles.length; j++) {
            File file = variantFiles[j];
            if (await file.exists()) {
              final imageFile = await http.MultipartFile.fromPath(
                  'variants[$i][files][$j]', file.path);
              request.files.add(imageFile);
            }
          }
        }

        for (int i = 0; i < images.length; i++) {
          File file = images[i];
          if (await file.exists()) {
            final imageFile =
                await http.MultipartFile.fromPath('files[$i][file]', file.path);
            request.files.add(imageFile);
            request.fields['files[$i][is_main]'] =
                i == (mainImageIndex ?? 0) ? '1' : '0';
          }
        }

        response = await _multipartPostRequest('', request);
      }

      final responseBody = json.decode(response.body);

      ////debugPrint('ApiService: Response status: ${response.statusCode}');
      ////debugPrint('ApiService: Response body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'goods_updated_successfully',
          'data': responseBody,
        };
      } else {
        String errorMessage =
            responseBody['message'] ?? 'Failed to update goods';
        final errors = responseBody['errors'] as Map<String, dynamic>?;
        final bool hasBarcodeError = errors != null &&
            errors.keys.any((k) =>
                k == 'barcode' ||
                k.startsWith('variants.') && k.endsWith('.barcode'));
        if (hasBarcodeError || errorMessage.contains('barcode')) {
          errorMessage = 'Такое значение штрих кода уже существует';
        }
        return {
          'success': false,
          'message': errorMessage,
          'error': responseBody,
        };
      }
    } catch (e, stackTrace) {
      ////debugPrint('ApiService: Error in updateGoods: ');
      ////debugPrint('ApiService: Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'An error occurred: ',
      };
    }
  }

  Future<bool> deleteGoods(int goodId, {int? organizationId}) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Токен не найден');

      // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
      final path = await _appendQueryParams('/good/$goodId');
      if (kDebugMode) {
        //debugPrint('ApiService: deleteGoods - Generated path: $path');
      }

      var uri = Uri.parse('$baseUrl$path');

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Device': 'mobile',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(
            jsonResponse['message'] ?? 'Ошибка при удалении товара');
      }
    } catch (e) {
      ////debugPrint('Ошибка удаления товара: ');
      return false;
    }
  }

  Future<List<Goods>> getGoodsByBarcode(String barcode) async {
    String path = '/good?search=$barcode';
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      debugPrint('ApiService: Запрос товаров по штрихкоду: $path');
    }

    final response = await _getRequest(path);
    if (kDebugMode) {
      debugPrint(
          'ApiService: Ответ сервера: statusCode=${response.statusCode}, body=${response.body}');
    }

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('errors') && data['errors'] != null) {
        if (kDebugMode) {
          debugPrint('ApiService: Ошибка сервера: ${data['errors']}');
        }
        throw Exception('Ошибка сервера: ${data['errors']}');
      }
      if (data.containsKey('result')) {
        final result = data['result'];
        if (result == null || result == 'Товар не найден') {
          if (kDebugMode) {
            debugPrint('ApiService: Товары по штрихкоду не найдены');
          }
          return [];
        }
        List<dynamic> goodsData;

        if (result is List) {
          goodsData = result;
        } else if (result is Map<String, dynamic>) {
          if (result.containsKey('data') && result['data'] is List) {
            goodsData = result['data'];
          } else {
            goodsData = [result];
          }
        } else {
          if (kDebugMode) {
            debugPrint(
                'ApiService: Ошибка формата данных: result не является списком или объектом: $data');
          }
          throw Exception('Ошибка: Неверный формат данных');
        }

        final goods = goodsData
            .map((item) => Goods.fromJson(item as Map<String, dynamic>))
            .toList();
        if (kDebugMode) {
          debugPrint(
              'ApiService: Успешно получено ${goods.length} товаров по штрихкоду');
        }
        return goods;
      } else {
        if (kDebugMode) {
          debugPrint(
              'ApiService: Ошибка формата данных: отсутствует поле result в $data');
        }
        throw Exception('Ошибка: Неверный формат данных');
      }
    } else {
      if (kDebugMode) {
        debugPrint(
            'ApiService: Ошибка загрузки товаров по штрихкоду: ${response.statusCode}');
      }
      throw Exception('Ошибка загрузки товаров: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getAllCalls({
    required int page,
    required int perPage,
    String? searchQuery,
    int? salesFunnelId, // ИЗМЕНЕНО: Добавили параметр для воронки
    Map<String, dynamic>? filters,
  }) async {
    // Формируем базовый путь
    String path = '/calls?page=$page&per_page=$perPage';

    // ИЗМЕНЕНО: Если пользователь выбрал воронку, добавляем sales_funnel_id сразу,
    // чтобы _appendQueryParams не добавил текущую (из-за containsKey).
    if (salesFunnelId != null) {
      path += '&sales_funnel_id=$salesFunnelId';
    }

    // Добавляем search параметр
    if (searchQuery != null && searchQuery.isNotEmpty) {
      path += '&search=${Uri.encodeQueryComponent(searchQuery)}';
    }

    // Обрабатываем фильтры
    if (filters != null) {
      if (filters.containsKey('startDate') && filters['startDate'] != null) {
        path += '&from=${Uri.encodeQueryComponent(filters['startDate'])}';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр from: ${filters['startDate']}');
        }
      }
      if (filters.containsKey('endDate') && filters['endDate'] != null) {
        path += '&to=${Uri.encodeQueryComponent(filters['endDate'])}';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр to: ${filters['endDate']}');
        }
      }
      if (filters.containsKey('leads') &&
          filters['leads'] is List &&
          (filters['leads'] as List).isNotEmpty) {
        final leadIds = filters['leads'] as List<int>;
        for (var leadId in leadIds) {
          path += '&leads[]=$leadId';
        }
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлены lead_id: $leadIds');
        }
      }
      if (filters.containsKey('operators') &&
          filters['operators'] is List &&
          (filters['operators'] as List).isNotEmpty) {
        final operatorIds = filters['operators'] as List<int>;
        for (var operatorId in operatorIds) {
          path += '&operator_id[]=$operatorId';
        }
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлены operator_id: $operatorIds');
        }
      }
      if (filters.containsKey('ratings') &&
          filters['ratings'] is List &&
          (filters['ratings'] as List).isNotEmpty) {
        final ratingIds = filters['ratings'] as List<int>;
        for (var ratingId in ratingIds) {
          path += '&rating[]=$ratingId';
        }
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлены rating: $ratingIds');
        }
      }
      if (filters.containsKey('remarks') &&
          filters['remarks'] is List &&
          (filters['remarks'] as List).isNotEmpty) {
        final remarks = (filters['remarks'] as List)[0] as int;
        path += '&remarks=$remarks';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр remarks: $remarks');
        }
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id (только если не добавлена выше)
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //debugPrint('ApiService: getAllCalls - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (kDebugMode) {
        //debugPrint('ApiService: Response for getAllCalls: $data');
      }
      if (data['result']['data'] != null) {
        final calls = (data['result']['data'] as List)
            .map((json) => CallLogEntry.fromJson(json))
            .toList();
        final pagination = data['result']['pagination'] as Map<String, dynamic>;
        return {
          'calls': calls,
          'pagination': pagination,
        };
      } else {
        throw ('Нет данных о звонках в ответе');
      }
    } else {
      if (kDebugMode) {
        //debugPrint('ApiService: Error response body: ${response.body}');
      }
      throw ('Ошибка загрузки звонков');
    }
  }

  Future<Map<String, dynamic>> getOutgoingCalls({
    required int page,
    required int perPage,
    String? searchQuery,
    Map<String, dynamic>? filters,
  }) async {
    String path = '/calls?incoming=0&page=$page&per_page=$perPage';

    if (searchQuery != null && searchQuery.isNotEmpty) {
      path += '&search=${Uri.encodeQueryComponent(searchQuery)}';
    }

    if (filters != null) {
      if (filters.containsKey('startDate') && filters['startDate'] != null) {
        path += '&from=${Uri.encodeQueryComponent(filters['startDate'])}';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр from: ${filters['startDate']}');
        }
      }
      if (filters.containsKey('endDate') && filters['endDate'] != null) {
        path += '&to=${Uri.encodeQueryComponent(filters['endDate'])}';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр to: ${filters['endDate']}');
        }
      }
      if (filters.containsKey('leads') &&
          filters['leads'] is List &&
          (filters['leads'] as List).isNotEmpty) {
        final leadIds = filters['leads'] as List<int>;
        for (var leadId in leadIds) {
          path += '&leads[]=$leadId';
        }
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлены lead_id: $leadIds');
        }
      }
      if (filters.containsKey('operators') &&
          filters['operators'] is List &&
          (filters['operators'] as List).isNotEmpty) {
        final operatorIds = filters['operators'] as List<int>;
        for (var operatorId in operatorIds) {
          path += '&operator_id[]=$operatorId';
        }
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлены operator_id: $operatorIds');
        }
      }
      if (filters.containsKey('ratings') &&
          filters['ratings'] is List &&
          (filters['ratings'] as List).isNotEmpty) {
        final ratingIds = filters['ratings'] as List<int>;
        for (var ratingId in ratingIds) {
          path += '&rating[]=$ratingId';
        }
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлены rating: $ratingIds');
        }
      }
      if (filters.containsKey('remarks') &&
          filters['remarks'] is List &&
          (filters['remarks'] as List).isNotEmpty) {
        final remarks = (filters['remarks'] as List)[0] as int;
        path += '&remarks=$remarks';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр remarks: $remarks');
        }
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //debugPrint('ApiService: getOutgoingCalls - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (kDebugMode) {
        //debugPrint('ApiService: Response for getOutgoingCalls: $data');
      }
      if (data['result']['data'] != null) {
        final calls = (data['result']['data'] as List)
            .map((json) => CallLogEntry.fromJson(json))
            .toList();
        final pagination = data['result']['pagination'] as Map<String, dynamic>;
        return {
          'calls': calls,
          'pagination': pagination,
        };
      } else {
        throw ('Нет данных об исходящих звонках в ответе');
      }
    } else {
      if (kDebugMode) {
        //debugPrint('ApiService: Error response body: ${response.body}');
      }
      throw ('Ошибка загрузки исходящих звонков');
    }
  }

  Future<Map<String, dynamic>> getMissedCalls({
    required int page,
    required int perPage,
    String? searchQuery,
    Map<String, dynamic>? filters,
  }) async {
    String path = '/calls?missed=1&page=$page&per_page=$perPage';

    if (searchQuery != null && searchQuery.isNotEmpty) {
      path += '&search=${Uri.encodeQueryComponent(searchQuery)}';
    }

    if (filters != null) {
      if (filters.containsKey('startDate') && filters['startDate'] != null) {
        path += '&from=${Uri.encodeQueryComponent(filters['startDate'])}';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр from: ${filters['startDate']}');
        }
      }
      if (filters.containsKey('endDate') && filters['endDate'] != null) {
        path += '&to=${Uri.encodeQueryComponent(filters['endDate'])}';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр to: ${filters['endDate']}');
        }
      }
      if (filters.containsKey('leads') &&
          filters['leads'] is List &&
          (filters['leads'] as List).isNotEmpty) {
        final leadIds = filters['leads'] as List<int>;
        for (var leadId in leadIds) {
          path += '&leads[]=$leadId';
        }
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлены lead_id: $leadIds');
        }
      }
      if (filters.containsKey('operators') &&
          filters['operators'] is List &&
          (filters['operators'] as List).isNotEmpty) {
        final operatorIds = filters['operators'] as List<int>;
        for (var operatorId in operatorIds) {
          path += '&operator_id[]=$operatorId';
        }
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлены operator_id: $operatorIds');
        }
      }
      if (filters.containsKey('ratings') &&
          filters['ratings'] is List &&
          (filters['ratings'] as List).isNotEmpty) {
        final ratingIds = filters['ratings'] as List<int>;
        for (var ratingId in ratingIds) {
          path += '&rating[]=$ratingId';
        }
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлены rating: $ratingIds');
        }
      }
      if (filters.containsKey('remarks') &&
          filters['remarks'] is List &&
          (filters['remarks'] as List).isNotEmpty) {
        final remarks = (filters['remarks'] as List)[0] as int;
        path += '&remarks=$remarks';
        if (kDebugMode) {
          //debugPrint('ApiService: Добавлен параметр remarks: $remarks');
        }
      }
    }

    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    path = await _appendQueryParams(path);
    if (kDebugMode) {
      //debugPrint('ApiService: getMissedCalls - Generated path: $path');
    }

    final response = await _getRequest(path);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (kDebugMode) {
        //debugPrint('ApiService: Response for getMissedCalls: $data');
      }
      if (data['result']['data'] != null) {
        final calls = (data['result']['data'] as List)
            .map((json) => CallLogEntry.fromJson(json))
            .toList();
        final pagination = data['result']['pagination'] as Map<String, dynamic>;
        return {
          'calls': calls,
          'pagination': pagination,
        };
      } else {
        throw ('Нет данных о пропущенных звонках в ответе');
      }
    } else {
      if (kDebugMode) {
        //debugPrint('ApiService: Error response body: ${response.body}');
      }
      throw ('Ошибка загрузки пропущенных звонков');
    }
  }

  Future<void> setCallRating({
    required int callId,
    required int rating,
    required int organizationId,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams('/calls/set-rating/$callId');
    if (kDebugMode) {
      //debugPrint('ApiService: setCallRating - Generated path: $path');
    }
    final body = {
      'rating': rating,
      'organization_id': organizationId,
    };

    if (kDebugMode) {
      //debugPrint("API Request: setCallRating (PUT) with path: $path, body: $body");
    }
    final response = await _putRequest(path, body); // заменили на PUT

    if (response.statusCode != 200) {
      throw ('Ошибка при установке рейтинга');
    }
  }

  Future<void> addCallReport({
    required int callId,
    required String report,
    required int organizationId,
  }) async {
    // Используем _appendQueryParams для добавления organization_id и sales_funnel_id
    String path = await _appendQueryParams('/calls/add-report/$callId');
    if (kDebugMode) {
      //debugPrint('ApiService: addCallReport - Generated path: $path');
    }
    final body = {
      'report': report,
      'organization_id': organizationId,
    };

    if (kDebugMode) {
      //debugPrint("API Request: addCallReport (PUT) with path: $path, body: $body");
    }
    final response = await _putRequest(path, body); // заменили на PUT

    if (response.statusCode != 200) {
      throw ('Ошибка при добавлении замечания');
    }
  }

  Future<expDoc.ExpenseDocumentDetail> getClienSalesById(int documentId) async {
    String url = '/expense-documents/$documentId';

    final path = await _appendQueryParams(url);
    if (kDebugMode) {
      debugPrint('ApiService: getIncomingDocumentById - Generated path: $path');
    }

    try {
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final rawData = json.decode(response.body)['result'];
        return expDoc.ExpenseDocumentDetail.fromJson(rawData);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка сервера', response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createRmkSale({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw 'Токен не найден';

      final path = await _appendQueryParams('/rmk-documents');
      final response = await _postRequest(path, payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) {
          return {'success': true};
        }
        final decoded = json.decode(response.body);
        return decoded is Map<String, dynamic>
            ? decoded
            : {'success': true, 'result': decoded};
      }

      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(
        message ?? 'Неизвестная ошибка при создании продажи РМК',
        response.statusCode,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<expense.ExpenseResponse> getRmkSales({
    int page = 1,
    int perPage = 20,
    String? query,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? approved,
    int? deleted,
    int? storageId,
  }) async {
    var url = '/rmk-documents?page=$page&per_page=$perPage';
    if (query != null && query.isNotEmpty) {
      url += '&search=$query';
    }
    if (dateFrom != null) {
      url += '&date_from=${dateFrom.toIso8601String()}';
    }
    if (dateTo != null) {
      url += '&date_to=${dateTo.toIso8601String()}';
    }
    if (approved != null) {
      url += '&approved=$approved';
    }
    if (deleted != null) {
      url += '&deleted=$deleted';
    }
    if (storageId != null) {
      url += '&storage_id=$storageId';
    }

    final path = await _appendQueryParams(url);
    final response = await _getRequest(path);
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final rawResult = decoded['result'];
      final rawData = rawResult is Map<String, dynamic>
          ? rawResult
          : {'data': rawResult ?? const [], 'pagination': null};
      return expense.ExpenseResponse.fromJson(rawData);
    }

    final message = _extractErrorMessageFromResponse(response);
    throw ApiException(
      message ?? 'Ошибка загрузки продаж РМК',
      response.statusCode,
    );
  }

  Future<expDoc.ExpenseDocumentDetail> getRmkSaleById(int documentId) async {
    final path = await _appendQueryParams('/rmk-documents/$documentId');
    final response = await _getRequest(path);
    if (response.statusCode == 200) {
      final rawData = json.decode(response.body)['result'];
      return expDoc.ExpenseDocumentDetail.fromJson(rawData);
    }

    final message = _extractErrorMessageFromResponse(response);
    throw ApiException(message ?? 'Ошибка сервера', response.statusCode);
  }

  Future<void> updateUnit(
      {required MeasureUnitModel supplier, required int id}) async {
    final path = await _appendQueryParams('/unit/$id');
    if (kDebugMode) {
      //debugPrint('ApiService: updateSupplier - Generated path: $path');
    }
    final organizationId = await getSelectedOrganization() ?? '';
    final salesFunnelId = await getSelectedSalesFunnel() ?? '';
    final body = {
      'name': supplier.name,
      'short_name': supplier.shortName,
      'organization_id': organizationId,
      'sales_funnel_id': salesFunnelId,
    };

    final response = await _patchRequest(path, body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return;
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(message ?? 'Ошибка обновления', response.statusCode);
      }
    } else {
      final message = _extractErrorMessageFromResponse(response);
      throw ApiException(message ?? 'Ошибка обновления', response.statusCode);
    }
  }

  Future<List<SupplierCurrency>> getCurrencies() async {
    final organizationId = await getSelectedOrganization();
    String path = '/currency';
    if (organizationId != null && organizationId.isNotEmpty) {
      path += '?organization_id=$organizationId';
    }
    final response = await _getRequest(path);

    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки валют: ${response.body}');
    }

    final data = json.decode(response.body);
    dynamic result = data['result'];
    if (result is Map<String, dynamic>) {
      result = result['data'] ?? result['result'] ?? result['currencies'];
    }

    if (result is List) {
      return result
          .whereType<Map<String, dynamic>>()
          .map(SupplierCurrency.fromJson)
          .toList();
    }

    return [];
  }

  /// Получение данных о неликвидных товарах
  Future<IlliquidGoodsResponse> getIlliquidGoods({
    String? from,
    String? to,
  }) async {
    try {
      // Формируем параметры запроса
      Map<String, String> queryParams = {};

      if (from != null) queryParams['from'] = from;
      if (to != null) queryParams['to'] = to;

      var path = await _appendQueryParams('/dashboard/illiquid-goods');

      if (queryParams.isNotEmpty) {
        path +=
            '?${Uri.encodeQueryComponent(queryParams.entries.map((e) => '${e.key}=${e.value}').join('&'))}';
      }

      if (kDebugMode) {
        debugPrint('ApiService: getIlliquidGoods - Generated path: $path');
      }

      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return IlliquidGoodsResponse.fromJson(data);
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка при получении данных о неликвидных товарах!',
          response.statusCode,
        );
      }
    } catch (e) {
      throw e;
    }
  }

  /// Загрузка данных топ-продаж для конкретного периода
  Future<AllTopSellingData> getTopSellingGoodsForPeriod(
    TopSellingTimePeriod period, {
    int perPage = 7,
  }) async {
    final query = ['per_page=$perPage', 'period=${period.name}'].join('&');
    final path =
        await _appendQueryParams('/dashboard/top-selling-goods?$query');

    debugPrint(
        "ApiService: getTopSellingGoodsForPeriod path: $path for period: ${period.name}");

    try {
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final topSellingResponse = TopSellingGoodsResponse.fromJson(data);

        return AllTopSellingData(
          period: period,
          data: topSellingResponse.result,
        );
      } else {
        final message = _extractErrorMessageFromResponse(response);
        throw ApiException(
          message ?? 'Ошибка загрузки данных для периода ${period.name}',
          response.statusCode,
        );
      }
    } catch (e) {
      debugPrint("Error fetching data for period $period: $e");
      rethrow;
    }
  }
}
