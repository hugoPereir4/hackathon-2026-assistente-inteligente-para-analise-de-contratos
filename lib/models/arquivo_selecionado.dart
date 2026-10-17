import 'dart:typed_data';

/// Arquivo escolhido pelo usuário (pelo seletor ou arrastando), independente
/// do pacote que o forneceu. Os bytes só são lidos na hora do envio.
class ArquivoSelecionado {
  // Mesmas regras do DocumentSerializer (MAX_DOCUMENT_UPLOAD_SIZE e só .pdf).
  static const int tamanhoMaximoMb = 10;
  static const int tamanhoMaximoBytes = tamanhoMaximoMb * 1024 * 1024;
  static const List<String> extensoesPermitidas = ['pdf'];

  final String nome;
  final int tamanhoBytes;
  final Future<Uint8List> Function() lerBytes;

  const ArquivoSelecionado({
    required this.nome,
    required this.tamanhoBytes,
    required this.lerBytes,
  });

  String get extensao {
    final ponto = nome.lastIndexOf('.');
    return ponto == -1 ? '' : nome.substring(ponto + 1).toLowerCase();
  }

  bool get extensaoValida => extensoesPermitidas.contains(extensao);

  bool get tamanhoValido => tamanhoBytes > 0 && tamanhoBytes <= tamanhoMaximoBytes;
}
