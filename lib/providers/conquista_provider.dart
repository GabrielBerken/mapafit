import 'package:flutter/material.dart';
import 'package:mapafit/controllers/conquista_controller.dart';
import 'package:mapafit/models/conquista_model.dart';

class ConquistaProvider with ChangeNotifier {
  List<Conquista> _conquistas = [];
  bool _isLoading = false;
  String? _error;

  List<Conquista> get conquistas => _conquistas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> carregarConquistas(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _conquistas = await fetchConquistas(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}