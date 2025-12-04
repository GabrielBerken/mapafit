enum TipoAtividadeFisica {
  Caminhada,
  Corrida,
  Ciclismo,
  Natacao,
  Hidroginastica,
  Musculacao,
  Pilates,
  Futebol,
  LutasArtesMarciais,
  Danca,
}

extension TipoAtividadeFisicaExtension on TipoAtividadeFisica {
  String get nome {
    switch (this) {
      case TipoAtividadeFisica.Caminhada:
        return 'Caminhada';
      case TipoAtividadeFisica.Corrida:
        return 'Corrida';
      case TipoAtividadeFisica.Ciclismo:
        return 'Ciclismo';
      case TipoAtividadeFisica.Natacao:
        return 'Natação';
      case TipoAtividadeFisica.Hidroginastica:
        return 'Hidroginástica';
      case TipoAtividadeFisica.Musculacao:
        return 'Musculação';
      case TipoAtividadeFisica.Pilates:
        return 'Pilates';
      case TipoAtividadeFisica.Futebol:
        return 'Futebol';
      case TipoAtividadeFisica.LutasArtesMarciais:
        return 'Lutas e Artes Marciais';
      case TipoAtividadeFisica.Danca:
        return 'Dança';
    }
  }
}
