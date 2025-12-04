import 'dart:developer';

import 'package:mapafit/models/checkin_model.dart';
import 'package:mapafit/services/api_service.dart';

/// Realiza o check-in de um usuário em um local.
Future<Checkin> performCheckIn({
  required int userId,
  required int localId,
  required int tipoAtividadeId,
}) async {
  try {
    // Muitos endpoints Spring usam @RequestParam para parâmetros simples.
    // Para garantir compatibilidade enviamos os três parâmetros na query string.
    final endpoint = '/api/checkins/checkin'
        '?userId=${Uri.encodeQueryComponent(userId.toString())}'
        '&localId=${Uri.encodeQueryComponent(localId.toString())}'
        '&tipoAtividadeId=${Uri.encodeQueryComponent(tipoAtividadeId.toString())}';
    final response = await ApiService().post(
      endpoint,
    );
    return Checkin.fromJson(response);
  } on Exception catch (e) {
    final error = e.toString();
    if (error.contains('404')) {
      throw Exception('Usuário ou local não encontrado.');
    } else if (error.contains('409')) {
      throw Exception('Você já possui um check-in ativo. Finalize-o antes de iniciar um novo.');
    }
    log(error);
  throw Exception('Não foi possível realizar o check-in: $e');
    // rethrow;
  }
}

Future<String> getCheckInStatus({required int checkinId}) async {
  try {
    final response = await ApiService().get(
      '/api/checkins/checkin-status',
      queryParams: {'checkinId': checkinId.toString()},
    );

    log('Status: $response');
    if (response is Map<String, dynamic> && response.containsKey('status')) {
      return response['status'] as String;
    } else {
      throw Exception('Formato de resposta de status de check-in inesperado');
    }
  } on Exception catch (e) {
    if (e.toString().contains('404')) {
      throw Exception('Check-in não encontrado.');
    }
    log('Erro ao verificar status do check-in: $e');
    throw Exception('Não foi possível verificar o status do check-in: $e');
  }
}

/// Realiza o checkout.
Future<Checkin> performCheckOut({required int checkinId}) async {
  try {
    final endpoint = '/api/checkins/checkout?checkinId=${Uri.encodeQueryComponent(checkinId.toString())}';
    final response = await ApiService().post(
      endpoint,
    );
    return Checkin.fromJson(response);
  } on Exception catch (e) {
    if (e.toString().contains('404')) {
      throw Exception('Check-in não encontrado para realizar o checkout.');
    }
    throw Exception('Não foi possível realizar o checkout: $e');
  }
}


Future<List<Checkin>> buscaCheckins({
  required int userId
}) async {
  try {
    final endpoint = '/api/checkins'
        '?userId=${Uri.encodeQueryComponent(userId.toString())}';
    final response = await ApiService().get(
      endpoint,
    );
    return List<Checkin>.from(response.map((x) => Checkin.fromJson(x)));
  } on Exception catch (e) {
    final error = e.toString();
    if (error.contains('404')) {
      throw Exception('Usuário não encontrado.');
    } 
    log(error);
    throw Exception('Não foi possível buscar os check-ins: $e');
    // rethrow;
  }
}
