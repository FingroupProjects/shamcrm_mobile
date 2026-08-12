part of '../api_service.dart';

extension ApiSalesPlanX on ApiService {
  Future<Map<String, dynamic>> getSalesPlans({
    String? status,
    String? planType,
    int? userId,
    String? search,
    String? periodFrom,
    String? periodTo,
    String sort = 'created_at',
    String direction = 'desc',
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
        'sort': sort,
        'direction': direction,
      };
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (planType != null && planType.isNotEmpty) {
        params['plan_type'] = planType;
      }
      if (userId != null) params['user_id'] = '$userId';
      if (search != null && search.trim().isNotEmpty) {
        params['search'] = search.trim();
      }
      if (periodFrom != null && periodFrom.isNotEmpty) {
        params['period_from'] = periodFrom;
      }
      if (periodTo != null && periodTo.isNotEmpty) {
        params['period_to'] = periodTo;
      }

      final query = params.entries
          .map((e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      final path = await _appendQueryParams('/v3/sales-plans?$query');
      final response = await _getRequest(path);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'success': true, 'data': decoded};
      }
      throw Exception('Failed to load sales plans: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: getSalesPlans error: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSalesPlanById(int id) async {
    try {
      final path = await _appendQueryParams('/v3/sales-plans/$id');
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'success': true, 'data': decoded};
      }
      throw Exception('Failed to load sales plan: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: getSalesPlanById error: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createSalesPlan(Map<String, dynamic> body) async {
    try {
      final organizationId = await getSelectedOrganization();
      final salesFunnelId = await getSelectedSalesFunnel();
      final payload = Map<String, dynamic>.from(body);
      if (organizationId != null && payload['organization_id'] == null) {
        payload['organization_id'] = int.tryParse(organizationId);
      }
      if (salesFunnelId != null && payload['sales_funnel_id'] == null) {
        payload['sales_funnel_id'] = int.tryParse(salesFunnelId);
      }

      final path = await _appendQueryParams('/v3/sales-plans');
      final response = await _postRequest(path, payload);
      final decoded = response.body.isNotEmpty
          ? json.decode(response.body)
          : <String, dynamic>{};

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decoded is Map<String, dynamic>) {
          return {'success': true, ...decoded};
        }
        return {'success': true, 'data': decoded};
      }

      String message = 'error_create_sales_plan';
      if (decoded is Map && decoded['message'] != null) {
        message = decoded['message'].toString();
      }
      return {
        'success': false,
        'message': message,
        'statusCode': response.statusCode,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: createSalesPlan error: $e');
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateSalesPlan(
    int id,
    Map<String, dynamic> body,
  ) async {
    try {
      final path = await _appendQueryParams('/v3/sales-plans/$id');
      final response = await _putRequest(path, body);
      final decoded = response.body.isNotEmpty
          ? json.decode(response.body)
          : <String, dynamic>{};

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decoded is Map<String, dynamic>) {
          return {'success': true, ...decoded};
        }
        return {'success': true, 'data': decoded};
      }

      String message = 'error_update_sales_plan';
      if (decoded is Map && decoded['message'] != null) {
        message = decoded['message'].toString();
      }
      return {
        'success': false,
        'message': message,
        'statusCode': response.statusCode,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: updateSalesPlan error: $e');
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteSalesPlan(int id) async {
    try {
      final path = await _appendQueryParams('/v3/sales-plans/$id');
      final response = await _deleteRequest(path);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'message': 'Deleted successfully'};
      }
      final decoded = response.body.isNotEmpty
          ? json.decode(response.body)
          : <String, dynamic>{};
      return {
        'success': false,
        'message': decoded is Map && decoded['message'] != null
            ? decoded['message'].toString()
            : 'error_delete_sales_plan',
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: deleteSalesPlan error: $e');
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  List<Map<String, dynamic>> _extractSalesPlanRows(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (decoded is! Map) return const [];
    final map = Map<String, dynamic>.from(decoded);
    final result = map['result'];
    final payload = result is Map ? Map<String, dynamic>.from(result) : map;
    final data = payload['data'] ?? map['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> getSalesPlansDashboard() async {
    try {
      final path = await _appendQueryParams('/v3/sales-plans/dashboard');
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final rows = _extractSalesPlanRows(decoded);
        if (rows.isNotEmpty || decoded is Map) {
          return rows;
        }
      }
      throw Exception(
          'Failed to load sales plans dashboard: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: getSalesPlansDashboard error: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSalesPlansLeaderboard({
    String? periodType,
  }) async {
    try {
      var base = '/v3/sales-plans/leaderboard';
      if (periodType != null && periodType.isNotEmpty) {
        base = '$base?period_type=$periodType';
      }
      final path = await _appendQueryParams(base);
      final response = await _getRequest(path);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return _extractSalesPlanRows(decoded);
      }
      throw Exception(
          'Failed to load sales plans leaderboard: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiService: getSalesPlansLeaderboard error: $e');
      }
      rethrow;
    }
  }
}
