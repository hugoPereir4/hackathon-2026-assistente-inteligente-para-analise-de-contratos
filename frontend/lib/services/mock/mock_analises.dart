/// Gera um `analysis_json` de exemplo no formato da IA (schema_version 2),
/// baseado na resposta real enviada pelo time do backend.
abstract final class MockAnalises {
  static Map<String, dynamic> gerar({required String docType, required int score}) {
    final boa = score >= 75;
    final hoje = DateTime.now();
    String daqui(int dias) => hoje.add(Duration(days: dias)).toIso8601String().substring(0, 10);
    Map<String, String> ev(String trecho, String clausula) =>
        {'trecho': trecho, 'clausula': clausula};

    final requisitos = [
      {
        'id': 'req-1',
        'descricao': 'Possuir certificação ISO 9001',
        'obrigatorio': true,
        'resultado': 'atende',
        'justificativa': "O fato confirmado 'fatos.iso_9001' indica que a empresa possui a certificação.",
        'evidencia': ev('A CONTRATADA deverá possuir certificação ISO 9001.',
            'Cláusula 4 - Requisitos obrigatórios'),
      },
      {
        'id': 'req-2',
        'descricao': 'Disponibilizar suporte 24 horas por dia, sete dias por semana',
        'obrigatorio': true,
        'resultado': boa ? 'atende' : 'nao_atende',
        'justificativa': boa
            ? 'O perfil informa suporte 24x7.'
            : "O fato confirmado 'fatos.suporte_24x7' indica que a empresa não oferece suporte 24 horas.",
        'evidencia': ev('A CONTRATADA deverá disponibilizar suporte 24 horas por dia, sete dias por semana.',
            'Cláusula 4 - Requisitos obrigatórios'),
      },
      {
        'id': 'req-3',
        'descricao': 'Possuir certificação ISO 27001',
        'obrigatorio': true,
        'resultado': boa ? 'atende' : 'desconhecido',
        'justificativa': boa
            ? 'O perfil informa a certificação ISO 27001.'
            : 'Não há informações no contexto da empresa confirmando a certificação ISO 27001.',
        'evidencia': ev('A CONTRATADA deverá possuir certificação ISO 27001.',
            'Cláusula 4 - Requisitos obrigatórios'),
      },
      {
        'id': 'req-4',
        'descricao': 'Faturamento anual de 2025 de no mínimo R\$ 1.000.000,00',
        'obrigatorio': true,
        'resultado': 'atende',
        'justificativa': 'O faturamento informado para 2025 é de R\$ 1.200.000,00, acima do mínimo.',
        'evidencia': ev('O faturamento anual de 2025 da CONTRATADA deverá ser de, no mínimo, R\$ 1.000.000,00.',
            'Cláusula 4 - Requisitos obrigatórios'),
      },
    ];
    final atendidos = requisitos.where((r) => r['resultado'] == 'atende').length;
    final parcialmenteAtendidos =
        requisitos.where((r) => r['resultado'] == 'parcialmente_atende').length;
    final naoAtendidos = requisitos.where((r) => r['resultado'] == 'nao_atende').length;
    final desconhecidos = requisitos.length - atendidos - parcialmenteAtendidos - naoAtendidos;

    return {
      'schema_version': 2,
      'resumo': docType == 'tender'
          ? 'Edital de pregão eletrônico para contratação de empresa de desenvolvimento e '
              'sustentação de sistemas web, com vigência de 12 meses a partir da assinatura.'
          : 'Contrato de prestação de serviços para desenvolvimento de um sistema de gestão de '
              'estoque entre Horizonte Comércio Demo LTDA e Aurora Tecnologia Demo LTDA.',
      'papel_empresa': {
        'papel': 'fornecedora',
        'justificativa': 'A empresa é identificada no documento como CONTRATADA.',
        'evidencia': ev('a Aurora Tecnologia Demo LTDA, denominada CONTRATADA, para desenvolver um sistema.',
            'Cláusula 1 - Partes e objeto'),
      },
      'prazos': [
        {
          'id': 'prazos-1',
          'descricao': 'Assinatura do contrato',
          'data': daqui(3),
          'evidencia': ev('A assinatura ocorrerá na data indicada.', 'Cláusula 3 - Prazos'),
        },
        {
          'id': 'prazos-2',
          'descricao': 'Primeira entrega',
          'prazo_relativo': 'em até 30 dias',
          'evento_referencia': 'assinatura',
          'evidencia': ev('A primeira entrega deverá ocorrer em até 30 dias após a assinatura.',
              'Cláusula 3 - Prazos'),
        },
        {
          'id': 'prazos-3',
          'descricao': 'Vigência do contrato',
          'prazo_relativo': '12 meses',
          'evento_referencia': 'assinatura',
          'evidencia': ev('A vigência será de 12 meses a partir da assinatura.', 'Cláusula 3 - Prazos'),
        },
        {
          'id': 'prazos-4',
          'descricao': 'Aprovação ou rejeição de cada entrega',
          'prazo_relativo': 'em até cinco dias úteis',
          'evento_referencia': 'seu recebimento',
          'evidencia': ev('A CONTRATANTE deverá aprovar ou rejeitar cada entrega em até cinco dias úteis.',
              'Cláusula 5 - Obrigações'),
        },
      ],
      'valores': [
        {
          'descricao': 'Valor total do contrato',
          'categoria': 'valor_total',
          'moeda': 'R\$',
          'montante': '180000.00',
          'aproximado': false,
          'evidencia': ev('O valor total é de R\$ 180.000,00, pago em seis parcelas mensais.',
              'Cláusula 2 - Valor e pagamento'),
        },
        {
          'descricao': 'Parcela mensal',
          'categoria': 'pagamento',
          'moeda': 'R\$',
          'montante': '30000.00',
          'aproximado': false,
          'evidencia': ev('seis parcelas mensais de R\$ 30.000,00, após aprovação das entregas.',
              'Cláusula 2 - Valor e pagamento'),
        },
        {
          'descricao': 'Multa por atraso na primeira entrega',
          'categoria': 'multa',
          'percentual': '2',
          'aproximado': false,
          'evidencia': ev('O atraso na primeira entrega acarretará multa de 2% sobre o valor total.',
              'Cláusula 6 - Penalidades'),
        },
      ],
      'obrigacoes': [
        {
          'descricao': 'Disponibilizar suporte 24 horas por dia, sete dias por semana',
          'parte_responsavel': 'CONTRATADA',
          'evidencia': ev('A CONTRATADA deverá disponibilizar suporte 24 horas por dia.',
              'Cláusula 4 - Requisitos obrigatórios'),
        },
        {
          'descricao': 'Apresentar relatório mensal de execução',
          'parte_responsavel': 'CONTRATADA',
          'evidencia': ev('A CONTRATADA deverá apresentar relatório mensal de execução.',
              'Cláusula 5 - Obrigações'),
        },
        {
          'descricao': 'Aprovar ou rejeitar cada entrega em até cinco dias úteis após seu recebimento',
          'parte_responsavel': 'CONTRATANTE',
          'prazo_id': 'prazos-4',
          'evidencia': ev('A CONTRATANTE deverá aprovar ou rejeitar cada entrega em até cinco dias úteis.',
              'Cláusula 5 - Obrigações'),
        },
      ],
      'riscos': [
        {
          'descricao': 'Multa de 2% sobre o valor total em caso de atraso na primeira entrega',
          'severidade': 'media',
          'impacto': 'Prejuízo financeiro decorrente da aplicação da multa contratual.',
          'recomendacao': 'Garantir o cumprimento do prazo de 30 dias após a assinatura.',
          'evidencia': ev('O atraso na primeira entrega acarretará multa de 2% sobre o valor total do contrato.',
              'Cláusula 6 - Penalidades'),
        },
        if (!boa)
          {
            'descricao': 'Exigência de suporte 24x7 que a empresa não oferece hoje',
            'severidade': 'alta',
            'impacto': 'Descumprimento de requisito obrigatório pode impedir a contratação.',
            'recomendacao': 'Avaliar parceria ou plantão terceirizado antes de assinar.',
            'evidencia': ev('A CONTRATADA deverá disponibilizar suporte 24 horas por dia.',
                'Cláusula 4 - Requisitos obrigatórios'),
          },
      ],
      'requisitos': requisitos,
      'perguntas_pendentes': [
        if (!boa)
          {
            'id': 'pergunta-1',
            'pergunta': 'A empresa possui certificação ISO 27001?',
            'requisito_ids': ['req-3'],
            'fato_chave': 'iso_27001',
            'sobre_papel': false,
            'destino': 'company_fact',
            'fato_rotulo': 'Possui certificação ISO 27001',
            'tipo_valor': 'booleano',
          },
      ],
      'aderencia': {
        'score': score,
        'cobertura': ((requisitos.length - desconhecidos) * 100 / requisitos.length).round(),
        'total': requisitos.length,
        'avaliados': requisitos.length - desconhecidos,
        'atendidos': atendidos,
        'parcialmente_atendidos': parcialmenteAtendidos,
        'nao_atendidos': naoAtendidos,
        'desconhecidos': desconhecidos,
      },
      'outcome': boa ? 'good_fit' : (naoAtendidos > 0 ? 'incompatible' : 'insufficient_data'),
      'metadados': {
        'analisado_em': hoje.toUtc().toIso8601String(),
        'modelo': 'mock',
      },
    };
  }
}
