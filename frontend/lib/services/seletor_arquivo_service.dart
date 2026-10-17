import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';

import '../models/arquivo_selecionado.dart';

/// Abre o seletor nativo de arquivos. Fica atrás de uma abstração para o
/// controller não depender do pacote `file_picker` diretamente.
abstract class SeletorArquivoService {
  Future<ArquivoSelecionado?> selecionarDocumento();

  /// Converte um arquivo arrastado para a tela (web/desktop) no nosso modelo.
  Future<ArquivoSelecionado> deXFile(XFile arquivo);
}

class FilePickerSeletorArquivoService implements SeletorArquivoService {
  @override
  Future<ArquivoSelecionado?> selecionarDocumento() async {
    final arquivo = await FilePicker.pickFile(
      dialogTitle: 'Selecione o contrato, edital ou proposta',
      type: FileType.custom,
      allowedExtensions: ArquivoSelecionado.extensoesPermitidas,
    );
    if (arquivo == null) return null;
    return ArquivoSelecionado(
      nome: arquivo.name,
      tamanhoBytes: arquivo.lengthSync() ?? await arquivo.length() ?? 0,
      lerBytes: arquivo.readAsBytes,
    );
  }

  @override
  Future<ArquivoSelecionado> deXFile(XFile arquivo) async {
    return ArquivoSelecionado(
      nome: arquivo.name,
      tamanhoBytes: await arquivo.length(),
      lerBytes: arquivo.readAsBytes,
    );
  }
}
