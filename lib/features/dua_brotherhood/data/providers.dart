import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_dio.dart';
import '../domain/repositories/dua_brotherhood_repository.dart';
import 'datasources/dua_brotherhood_api_service.dart';
import 'datasources/dua_queue_local_datasource.dart';
import 'repositories/dua_brotherhood_repository_impl.dart';

final duaBrotherhoodRepositoryProvider = Provider<DuaBrotherhoodRepository>((
  ref,
) {
  return DuaBrotherhoodRepositoryImpl(
    DuaBrotherhoodApiService(ref.read(dioProvider)),
    DuaQueueLocalDataSource(),
  );
});
