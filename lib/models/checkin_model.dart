
import 'package:mapafit/models/local_model.dart';

class Checkin {
  final int id;
  final DateTime inicio;
  final DateTime? fim;
  final Local? local;


  Checkin({
    required this.id,
    required this.inicio,
    this.fim,
    this.local,
  });

  factory Checkin.fromJson(Map<String, dynamic> json) {
    return Checkin(
      id: json['id'],
      inicio: DateTime.parse(json['inicio']),
      fim: json['fim'] != null ? DateTime.parse(json['fim']) : null,
      local: Local.fromJson(json['local']),
    );
  }
}