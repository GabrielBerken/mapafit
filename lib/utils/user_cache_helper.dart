import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:mapafit/controllers/usuario_controller.dart';
import 'package:mapafit/models/usuario_model.dart';
import 'package:mapafit/services/api_service.dart';
import 'package:mapafit/providers/user_provider.dart';

/// Tenta popular o [UserProvider] com os dados do cache local sem fazer requisição ao servidor.
///
/// Retorna o [Usuario] se encontrado no cache, ou `null` caso contrário.
/// Uso: chamar no `initState` ou logo após navegação para uma página que precise mostrar dados rápidos.
Future<Usuario?> populateUserFromCacheIfAvailable(BuildContext context, {int? userId}) async {
  try {
    final provider = context.read<UserProvider>();
    // Tenta obter id do parâmetro, do provider ou da ApiService
    int? id = userId ?? provider.currentUser?.id;
    if (id == null) {
      id = await ApiService().getCurrentUserId();
      if (id == null) return null;
    }

    final cached = await fetchUserProfileFromCacheOnly(id);
    if (cached != null) {
      provider.updateCurrentUser(cached);
    }
    return cached;
  } catch (e) {
    // Em caso de erro, não interrompe a navegação/UX
    return null;
  }
}
