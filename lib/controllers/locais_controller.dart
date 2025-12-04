import 'package:mapafit/models/local_model.dart';
import 'package:mapafit/repositories/locais_repository.dart';
class LocaisController {
  final LocaisRepository _repository;
  
  LocaisController(this._repository);

  Future<List<Local>> buscarLocais({double? latitude, double? longitude}) async {
    try {
      return await _repository.fetchLocais(
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Cadastra um novo local
  Future<void> cadastrarLocal(Local local) async {
    try {
      await _repository.cadastrarLocal(local);
    } catch (e) {
      rethrow;
    }
  }
}
