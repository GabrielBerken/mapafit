import 'dart:developer';
import 'package:mapafit/models/conquista_model.dart';
import 'package:mapafit/services/api_service.dart';

Future<List<Conquista>> fetchConquistas(int userId) async {
  try {
    final response = await ApiService().get('/usuarios/me/conquistas');

    if (response is Map<String, dynamic> && response.containsKey('conquistas')) {
      final List<dynamic> conquistasList = response['conquistas'];
      return conquistasList.map((json) => Conquista.fromJson(json)).toList();
    } else if (response is List) {
      return response.map((json) => Conquista.fromJson(json)).toList();
    } else {
      log('Resposta inesperada ao buscar conquistas para usuario $userId: tipo ${response?.runtimeType} - retornando lista vazia');
      log('Corpo da resposta: $response');
      return <Conquista>[];
    }
  } catch (e) {
    throw Exception('Erro ao buscar conquistas: $e');
  }
}

Future<void> registrarEvento(int userId, String tipoEvento) async {
  try {
    await ApiService().post(
      '/eventos/registrar',
      body: {
        'usuarioId': userId,
        'tipo': tipoEvento, // Ex: 'CHECKIN_COMPLETO', 'AVALIACAO_FEITA'
      },
    );
  } catch (e) {
    // Não relançamos a exceção para não interromper o fluxo do usuário
    // caso a gamificação falhe
  }
}
