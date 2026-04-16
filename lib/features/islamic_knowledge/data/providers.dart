import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_dio.dart';
import '../domain/repositories/knowledge_repository.dart';
import 'datasources/knowledge_local_datasource.dart';
import 'repositories/knowledge_repository_impl.dart';

final knowledgeRepositoryProvider = Provider<KnowledgeRepository>(
  (ref) =>
      KnowledgeRepositoryImpl(KnowledgeLocalDataSource(ref.read(dioProvider))),
);
