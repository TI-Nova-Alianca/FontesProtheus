// Programa:   F070ACont
// Autor:      Robert Koch
// Data:       08/07/2008
// Descricao:  P.E. antes da contabilizacao na tela de baixa de titulos a receber.
//             Criado inicialmente para gravar campos customizados no SE5.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. antes da contabilizacao na tela de baixa de titulos a receber.
// #PalavasChave      #baixa_de_titulos #contas_a_receber #P.E.
// #TabelasPrincipais #SE5 #ZA5 #ZA4
// #Modulos           #FIN 
//
// Historico de alteracoes:
// 31/07/2008 - Robert  - Gravacao dos campos E5_VADOUTR e E5_VADFRET
// 12/08/2008 - Robert  - Gravacao dos campos E5_VADDEVO e E5_VADDESC
//                      - Nao zerava variaveis publicas depois da gravacao.
// 09/03/2009 - Robert  - Gravacao dos campos E5_VADCMPV e E5_VADAREI.
// 15/10/2009 - Robert  - Gravacao do campo E5_VADMULC.
// 28/07/2010 - Robert  - Agenda recalculo de rapel em batch quando necessario.
//                      - Nao considerava campo E5_PARCELA ao dar update no SE5.
// 02/08/2010 - Robert  - Nao verificada existencia das variaveis publicas antes de ler seu conteudo.
// 15/09/2010 - Robert  - Nao chama mais o recalculo de rapel.
// 15/04/2015 - Catia   - alteracoes para integracao com controle de verbas - descontos em titulos por Verbas
// 08/05/2015 - Catia   - alteracoes para integracao com controle de verbas - baixa de NCC de Verbas
// 10/06/2015 - Catia   - ao gravar a ZA5 - utilizacao de verbas - estava gravando o tipo de liberacao errada
// 15/06/2015 - Catia   - alterado status de utilizacao - testando pelo saldo da verba
// 09/09/2015 - Catia   - estava dando o update em todas as sequencia do SE5 o valor do desconto
// 09/10/2015 - Catia   - não estava buscando a sequencia correta - acrescentado um DESC na ordenação
// 20/08/2019 - Robert  - Revisao geral e testes apos saida da Catia (programa estava em manutencao).
// 28/08/2019 - Robert  - Nao estava gravando as verbas comerciais no ZA5 (GLPI 6573).
// 03/10/2019 - Robert  - Nao lia corretamente o valor do campo E5_VAEncar na atualizacao de verbas.
// 10/10/2019 - Robert  - Passa a atualizar ZA4 pela funcao AtuZA4().
//                      - Gravacao campo ZA5_SEQSE5.
// 11/11/2019 - Robert  - Tratamento campo ZA5_FILIAL (tabela passou de compartilhada para exclusiva). GLPI 6987.
// 03/08/2020 - Cláudia - Incluida a gravação do vendedor da verba e vendedor da nota. GLPI: 8254
// 14/08/2020 - Cláudia - Ajuste de Api em loop, conforme solicitação da versao 25 protheus. GLPI: 7339
// 07/10/2020 - Cláudia - Migrado esse ponto de entrada F70GRSE1, devido a execução da rotina no execauto, 
//						  o qual não é acionado nesse ponto de entrada. GLPI: 8367
//
// -------------------------------------------------------------------------------------------------------------------
User Function F070ACont ()
Return
