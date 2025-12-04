import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:mapafit/models/local_model.dart';
import 'package:mapafit/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaisRepository extends ChangeNotifier {
  List<Local> _locais = [];
  static const String _locaisCacheKey = 'locais_cache';
  static const String _locaisCacheTimestampKey = 'locais_cache_timestamp';
  static const Duration _cacheDuration = Duration(hours: 1);

  List<Local> get locais => _locais;

  Future<List<Local>> fetchLocais({double? latitude, double? longitude}) async {
    final Map<String, dynamic> queryParams = {};
    if (latitude != null && longitude != null) {
      queryParams['latitude'] = latitude;
      queryParams['longitude'] = longitude;
    }

    // Bypass cache if filtering by location, as this should always be fresh.
    if (queryParams.isNotEmpty) {
      log('Buscando locais por coordenadas (sem cache): $queryParams');
      return _fetchFromApi(queryParams);
    }

    // Try fetching from cache first
    final cachedLocais = await _getLocaisFromCache();
    if (cachedLocais != null) {
      log('Locais carregados do cache.');
      _locais = cachedLocais;
      notifyListeners();
      return _locais;
    }

    // If cache is invalid or empty, fetch from API
    log('Cache de locais inválido ou expirado. Buscando da API.');
    return _fetchFromApi(null);
  }

  Future<List<Local>> _fetchFromApi(Map<String, dynamic>? queryParams) async {
    try {
      final response = await ApiService().get(
        '/locais',
        queryParams: queryParams,
      );

      log('Resposta bruta de /locais (tipo ${response?.runtimeType}): $response');

      if (response is num || response is String || response is bool) {
        log('Resposta inesperada do endpoint /locais: tipo ${response.runtimeType} - retornando lista vazia');
        _locais = [];
        notifyListeners();
        return _locais;
      }

      List<dynamic> rawList = [];
      if (response == null) {
        rawList = [];
      } else if (response is List) {
        rawList = response;
      } else if (response is Map<String, dynamic>) {
        dynamic candidate = response['data'] ?? response['locais'];
        if (candidate is List) {
          rawList = candidate;
        } else if (candidate is Map<String, dynamic>) {
          rawList = [candidate];
        } else {
          rawList = [response];
        }
      }

      final entries = rawList.whereType<Map<String, dynamic>>().toList();
      _locais = entries.map((data) => Local.fromJson(data)).toList();

      // Save to cache only if it's a general fetch (no query params)
      if (queryParams == null || queryParams.isEmpty) {
        await _saveLocaisToCache(_locais);
      }

      log('Total de locais carregados da API: ${_locais.length}');
      notifyListeners();
      return _locais;
    } catch (e) {
      log('Erro ao buscar locais: $e');
      rethrow;
    }
  }

  Future<List<Local>?> _getLocaisFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_locaisCacheTimestampKey);
      final cachedData = prefs.getString(_locaisCacheKey);

      if (timestamp == null || cachedData == null) return null;

      final isCacheValid = DateTime.now().millisecondsSinceEpoch - timestamp < _cacheDuration.inMilliseconds;

      if (isCacheValid) {
        final List<dynamic> decodedData = jsonDecode(cachedData);
        return decodedData.map((item) => Local.fromJson(item)).toList();
      }
      return null;
    } catch (e) {
      log('Erro ao ler cache de locais: $e');
      return null;
    }
  }

  Future<void> _saveLocaisToCache(List<Local> locais) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedData = jsonEncode(locais.map((local) => local.toJson()).toList());
      await prefs.setString(_locaisCacheKey, encodedData);
      await prefs.setInt(_locaisCacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      log('Locais salvos no cache.');
    } catch (e) {
      log('Erro ao salvar locais no cache: $e');
    }
  }

  Future<void> cadastrarLocal(Local local) async {
    try {
      await ApiService().post(
        '/locais',
        body: local.toJson(),
      );
      // Invalidate cache and refetch
      await _clearCache();
      await fetchLocais();
    } catch (e) {
      log('Erro ao cadastrar local: $e', error: e);
      rethrow;
    }
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_locaisCacheKey);
    await prefs.remove(_locaisCacheTimestampKey);
    log('Cache de locais invalidado.');
  }

  /// Retorna os locais apenas do cache (não faz requisição à API).
  /// Atualiza o estado interno `_locais` e notifica listeners se o cache existir e for válido.
  Future<List<Local>?> getLocaisFromCacheOnly() async {
    final cached = await _getLocaisFromCache();
    if (cached != null) {
      _locais = cached;
      notifyListeners();
    }
    return cached;
  }
}
