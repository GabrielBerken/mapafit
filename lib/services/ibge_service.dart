import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:mapafit/models/cidade_model.dart';
import 'package:mapafit/models/estado_model.dart';

class IbgeService {
  final String _baseUrl = 'https://servicodados.ibge.gov.br/api/v1/localidades';

  Future<List<Estado>> getEstados() async {
    final url = Uri.parse('$_baseUrl/estados?orderBy=nome');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = jsonDecode(responseBody);
        return data.map((json) => Estado.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar estados');
      }
    } catch (e) {
      throw Exception('Erro na requisição de estados: $e');
    }
  }

  Future<List<Cidade>> getCidadesPorEstado(int estadoId) async {
    final url = Uri.parse('$_baseUrl/estados/$estadoId/municipios?orderBy=nome');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = jsonDecode(responseBody);
        return data.map((json) => Cidade.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar cidades');
      }
    } catch (e) {
      throw Exception('Erro na requisição de cidades: $e');
    }
  }
}