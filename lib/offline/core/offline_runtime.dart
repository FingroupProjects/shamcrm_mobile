import 'package:crm_task_manager/offline/core/local_cache_repository.dart';
import 'package:crm_task_manager/offline/core/network_profile_service.dart';
import 'package:crm_task_manager/offline/core/offline_telemetry_service.dart';
import 'package:crm_task_manager/offline/core/outbox_service.dart';
import 'package:crm_task_manager/offline/core/request_scheduler.dart';
import 'package:crm_task_manager/offline/db/app_database.dart';

class OfflineRuntime {
  OfflineRuntime._({
    required this.database,
    required this.networkProfileService,
    required this.requestScheduler,
    required this.telemetryService,
    required this.outboxService,
    required this.localCacheRepository,
  });

  static OfflineRuntime? _instance;

  final AppDatabase database;
  final NetworkProfileService networkProfileService;
  final RequestScheduler requestScheduler;
  final OfflineTelemetryService telemetryService;
  final OutboxService outboxService;
  final LocalCacheRepository localCacheRepository;

  static OfflineRuntime get instance {
    final runtime = _instance;
    if (runtime == null) {
      throw StateError('OfflineRuntime is not initialized');
    }
    return runtime;
  }

  static Future<OfflineRuntime> initialize() async {
    if (_instance != null) {
      return _instance!;
    }

    final database = AppDatabase();
    final telemetryService = OfflineTelemetryService();
    final networkProfileService = NetworkProfileService.instance;
    await networkProfileService.initialize();
    final requestScheduler =
        RequestScheduler(networkProfileService: networkProfileService);
    final runtime = OfflineRuntime._(
      database: database,
      networkProfileService: networkProfileService,
      requestScheduler: requestScheduler,
      telemetryService: telemetryService,
      outboxService: OutboxService(
        database: database,
        scheduler: requestScheduler,
        networkProfileService: networkProfileService,
        telemetryService: telemetryService,
      ),
      localCacheRepository: LocalCacheRepository(database),
    );

    await runtime.outboxService.initialize();
    _instance = runtime;
    return runtime;
  }
}
