enum TipoAcesso {
  Pago,
  Gratuito
}

extension TipoAcessoExtension on TipoAcesso {
  String get nome {
    switch (this) {
      case TipoAcesso.Pago:
        return 'Pago';
      case TipoAcesso.Gratuito:
        return 'Gratuíto';
    }
  }
  static TipoAcesso fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pago':
        return TipoAcesso.Pago;
      case 'gratuíto':
      case 'gratuito': // Incluímos a forma sem acento como alternativa
        return TipoAcesso.Gratuito;
      default:
        throw Exception('TipoAcesso inválido: $value');
    }
  }
}
