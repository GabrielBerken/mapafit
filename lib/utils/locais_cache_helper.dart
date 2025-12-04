import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:mapafit/repositories/locais_repository.dart';
import 'package:mapafit/models/local_model.dart';

/// Tenta popular o [LocaisRepository] com os dados do cache local sem fazer requisição ao servidor.
/// Retorna a lista de [Local] se o cache existir, ou null caso contrário.
Future<List<Local>?> populateLocaisFromCacheIfAvailable(BuildContext context) async {
  try {
    final repo = context.read<LocaisRepository>();
    final cached = await repo.getLocaisFromCacheOnly();
    return cached;
  } catch (_) {
    return null;
  }
}

