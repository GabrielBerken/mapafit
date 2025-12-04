import 'dart:developer';
import 'package:mapafit/models/avaliacao_model.dart';
import 'package:mapafit/services/api_service.dart';

/// Envia uma nova avaliação para o backend.
Future<void> enviarAvaliacao({
  required int localId,
  required int userId,
  required double nota,
  String? comentario,
}) async {
  try {
    await ApiService().post(
      '/avaliacoes',
      body: {
        'localId': localId,
        'usuarioId': userId,
        'nota': nota,
        'comentario': comentario,
      },
    );
  } catch (e) {
    throw Exception('Erro ao enviar avaliação: $e');
  }
}

/// Busca todas as avaliações de um usuário específico.
Future<List<Avaliacao>> fetchAvaliacoesPorUsuario(int userId) async {
  try {
    final response = await ApiService().get(
      '/avaliacoes',
      queryParams: {'usuarioId': userId.toString()},
    );

    if (response is List) {
      return response.map((json) => Avaliacao.fromJson(json)).toList();
    }

    log('Resposta inesperada ao buscar avaliacoes para usuario $userId: tipo ${response?.runtimeType} - retornando lista vazia');
    return <Avaliacao>[];
  } catch (e) {
    throw Exception('Erro ao buscar avaliações do usuário: $e');
  }
}

Future<void> atualizarAvaliacao({
  required int avaliacaoId,
  required double nota,
  String? comentario,
}) async {
  try {
    await ApiService().put(
      '/avaliacoes/$avaliacaoId',
      body: {'nota': nota, 'comentario': comentario},
    );
  } catch (e) {
    throw Exception('Erro ao atualizar avaliação: $e');
  }
}