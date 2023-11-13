// Programa...: Includes
// Autor......: Robert Koch
// Data.......: 13/01/2012
// Descricao..: Includes diversos para compilacao do projeto, usado por outros programas.
//              Foi criado como .prw por que a pasta de includes eh geralmente 'esquecida'
//
// Historico de alteracoes:
// 29/09/2017 - Robert - Incluidos nomes de colunas de retorno do webservice da E-Sales.
// 12/01/2018 - Robert - Ajustados nomes das colunas do cadastro viticola para buscar dos grupos familiares.
// 10/01/2019 - Robert - Novas colunas cadastro viticola.
// 24/01/2019 - Robert - Criada array .InspecoesSafra
// 01/03/2019 - Robert - Criada tag .InspecoesSafraMisturaNoTombador
//

// Define nomes para colunas da array de cadastros viticolas.
#XTranslate .CadVitCodigo      => 1
#XTranslate .CadVitCodGrpFam   => 2
#XTranslate .CadVitNomeGrpFam  => 3
#XTranslate .CadVitProduto     => 4
#XTranslate .CadVitDescPro     => 5
#XTranslate .CadVitOrganico    => 6
#XTranslate .CadVitSafrVit     => 7
#XTranslate .CadVitVarUva      => 8
#XTranslate .CadVitDescMun     => 9
#XTranslate .CadVitAmostra     => 10  // Indica se deve ser recolhida amostra na proxima safra
#XTranslate .CadVitRecebFisico => 11  // Data do recebimento fisico (todo ano o associado deve nos entregar uma copia)
#XTranslate .CadVitSistCond    => 12
#XTranslate .CadVitSIVIBE      => 13
#XTranslate .CadVitQtColunas   => 13


// Definicoes usadas pelos programas de fretes.
#XTranslate .FreteDocS            => 1
#XTranslate .FreteSerieS          => 2
#XTranslate .FreteVlNegociado     => 3
#XTranslate .FreteUMPeso          => 4
#XTranslate .FretePesoMinimo      => 5
#XTranslate .FreteFreteMinimo     => 6
#XTranslate .FreteFretePeso       => 7
#XTranslate .FretePedagio         => 8
#XTranslate .FreteAdValorem       => 9
#XTranslate .FreteDespacho        => 10
#XTranslate .FreteCAT             => 11
#XTranslate .FreteGRIS            => 12
#XTranslate .FreteTransportadora  => 13
#XTranslate .FreteCliente         => 14
#XTranslate .FreteLoja            => 15
#XTranslate .FreteTipoNF          => 16
#XTranslate .FreteValorFatura     => 17
#XTranslate .FretePesoBruto       => 18
#XTranslate .FreteMinimoAdValorem => 19
#XTranslate .FretePesoFixo1       => 20
#XTranslate .FretePesoFixo2       => 21
#XTranslate .FretePesoFixo3       => 22
#XTranslate .FretePesoFixo4       => 23
#XTranslate .FretePesoFixo5       => 24
#XTranslate .FretePesoFixo6       => 25
#XTranslate .FretePesoFixo7       => 26
#XTranslate .FretePesoFixo8       => 27
#XTranslate .FretePesoFixo9       => 28
#XTranslate .FretePesoFixo10      => 29
#XTranslate .FreteValorFixo1      => 30
#XTranslate .FreteValorFixo2      => 31
#XTranslate .FreteValorFixo3      => 32
#XTranslate .FreteValorFixo4      => 33
#XTranslate .FreteValorFixo5      => 34
#XTranslate .FreteValorFixo6      => 35
#XTranslate .FreteValorFixo7      => 36
#XTranslate .FreteValorFixo8      => 37
#XTranslate .FreteValorFixo9      => 38
#XTranslate .FreteValorFixo10     => 39
#XTranslate .FreteItemZZ3         => 40
#XTranslate .FreteQtColunas       => 40


// Definicoes de colunas da array de fretes nao previstos.
#XTranslate .FrtNaoPrevDoc         => 1
#XTranslate .FrtNaoPrevSerie       => 2
#XTranslate .FrtNaoPrevTipoServico => 3


// Define nomes para as colunas retornadas pelo metodo de leitura de dados de capital social da classe de associados:
#XTranslate .QtCapSaldoNaData                         => 1
#XTranslate .QtCapSaldoImplantadoEnquantoSocio        => 2
#XTranslate .QtCapSaldoResgatadoEnquantoSocio         => 3
#XTranslate .QtCapIntegralizadoEnquantoSocio          => 4
#XTranslate .QtCapResgatesEmAbertoEnquantoSocio       => 5
#XTranslate .QtCapIntegralizEmAbertoEnquantoSocio     => 6
#XTranslate .QtCapResgatesEmAbertoQuandoExSocio       => 7
#XTranslate .QtCapSaldoResgatadoQuandoExSocio         => 8
#XTranslate .QtCapSaidasTransfEnquantoSocio           => 9
#XTranslate .QtCapEntradasTransfEnquantoSocio         => 10
#XTranslate .QtCapIntegralizacaoSobrasEnquantoSocio   => 11
#XTranslate .QtCapIntegralizacaoSobrasEnquantoExSocio => 12
#XTranslate .QtCapResgatesEmAbertoNaData              => 13
#XTranslate .QtCapTotalResgatesEmAberto               => 14
#XTranslate .QtCapRetTXT                              => 15
#XTranslate .QtCapBaixaPorInatividade                 => 16
#XTranslate .QtCapRetXML                              => 17
#XTranslate .QtCapQtColunas                           => 17


// Define nomes para as colunas retornadas pelo metodo de geracao de dados para extrato de conta corrente da classe de associado.
#XTranslate .ExtratoCCFilial    => 1
#XTranslate .ExtratoCCDescFil   => 2
#XTranslate .ExtratoCCData      => 3
#XTranslate .ExtratoCCTM        => 4
#XTranslate .ExtratoCCDC        => 5
#XTranslate .ExtratoCCHist      => 6
#XTranslate .ExtratoCCValor     => 7
#XTranslate .ExtratoCCFornAdt   => 8
#XTranslate .ExtratoCCLojaAdt   => 9
#XTranslate .ExtratoCCObs       => 10
#XTranslate .ExtratoCCCapSocial => 11
#XTranslate .ExtratoCCOrigem    => 12
#XTranslate .ExtratoCCQtColunas => 12


// Define nomes para as colunas usadas pela classe ClsExtrCC para representacao de um extrato de conta corrente de associados.
#XTranslate .ExtrCCFilial       => 1
#XTranslate .ExtrCCDescFil      => 2
#XTranslate .ExtrCCData         => 3
#XTranslate .ExtrCCPrefixo      => 4
#XTranslate .ExtrCCTitulo       => 5
#XTranslate .ExtrCCParcela      => 6
#XTranslate .ExtrCCTM           => 7
#XTranslate .ExtrCCHist         => 8
#XTranslate .ExtrCCValorDebito  => 9
#XTranslate .ExtrCCValorCredito => 10
#XTranslate .ExtrCCSaldo        => 11
#XTranslate .ExtrCCFornAdt      => 12
#XTranslate .ExtrCCLojaAdt      => 13
#XTranslate .ExtrCCObs          => 14
#XTranslate .ExtrCCOrigem       => 15
#XTranslate .ExtrCCZIOrigem     => 16
#XTranslate .ExtrCCQtColunas    => 16


// Define nomes para as colunas da array de previsao de pagamento de safra. 
#XTranslate .PrevPgSafDebCred   => 1
#XTranslate .PrevPgSafDoc       => 2
#XTranslate .PrevPgSafQuant     => 3
#XTranslate .PrevPgSafValor     => 4
#XTranslate .PrevPgSafHist      => 5
#XTranslate .PrevPgSafFilial    => 6
#XTranslate .PrevPgSafSeqSZI    => 7
#XTranslate .PrevPgSafJahPrev   => 8
#XTranslate .PrevPgSafQtColunas => 8


// Define nomes para as colunas da array de saldos de associados.
#XTranslate .SaldoAssocCapNaoSocialDebito  => 1
#XTranslate .SaldoAssocCapNaoSocialCredito => 2
#XTranslate .SaldoAssocCapSocialDebito     => 3
#XTranslate .SaldoAssocCapSocialCredito    => 4
#XTranslate .SaldoAssocQtColunas           => 4


// Define nomes para as colunas da array de retorno do webservice de cotacao de frete da E-Sales (entregou.com).
#XTranslate .ESalesRetCodTransp => 1
#XTranslate .ESalesRetCNPJ      => 2
#XTranslate .ESalesRetNOME      => 3
#XTranslate .ESalesRetMODAL     => 4
#XTranslate .ESalesRetTPFRETE   => 5
#XTranslate .ESalesRetSTTABELA  => 6
#XTranslate .ESalesRetROTA      => 7
#XTranslate .ESalesRetCDTABELA  => 8
#XTranslate .ESalesRetVLRFRETE  => 9
#XTranslate .ESalesRetVLRTAXA   => 10
#XTranslate .ESalesRetVLRTOTAL  => 11
#XTranslate .ESalesRetDTPREV    => 12
#XTranslate .ESalesRetDIASENT   => 13
#XTranslate .ESalesRetErroFrete => 14
#XTranslate .ESalesRetQtColunas => 14

// Define nomes para as colunas da array de inspecoes de cargas de recebiento de safra.
#XTranslate .InspecoesSafraSituacao          => 1
#XTranslate .InspecoesSafraVarNaoPrevCadVit  => 2
#XTranslate .InspecoesSafraEntrCadCpo        => 3
#XTranslate .InspecoesSafraMisturaNoTombador => 4
#XTranslate .InspecoesSafraAgendaOri         => 5
#XTranslate .InspecoesSafraQtColunas         => 5

// Define nomes para as colunas da array de detalhes do calculo dos precos da uva.
#XTranslate .PrcUvaColGrau               => 1
#XTranslate .PrcUvaColPercAgioAlianca    => 2
#XTranslate .PrcUvaColPercAgioMOC        => 3
#XTranslate .PrcUvaColVlrAgioEntrada     => 4  // Guarda valor apenas para conferencia do calculo
#XTranslate .PrcUvaColVlrAgioCompra      => 5  // Guarda valor apenas para conferencia do calculo
#XTranslate .PrcUvaColVlrAgioMOC         => 6  // Guarda valor apenas para conferencia do calculo
#XTranslate .PrcUvaColPrcEntrada         => 7
#XTranslate .PrcUvaColPrcCompra          => 8
#XTranslate .PrcUvaColPrcMOC             => 9
#XTranslate .PrcUvaQtColunas             => 9

// Define nomes para colunas de arrays usadas na ClsTbUva
#XTranslate .TbUvaGruposCodigo          => 1
#XTranslate .TbUvaGruposDescricao       => 2
#XTranslate .TbUvaGruposGrauBase        => 3
#XTranslate .TbUvaGruposPrcGrauBase     => 4
#XTranslate .TbUvaGruposGrauMinParaAgio => 5
#XTranslate .TbUvaGruposPrcMinimo       => 6
#XTranslate .TbUvaGruposAcrEspaldPR     => 7
#XTranslate .TbUvaGruposAcrEspaldAA     => 8
#XTranslate .TbUvaGruposAcrEspaldA      => 9
#XTranslate .TbUvaGruposAcrEspaldB      => 10
#XTranslate .TbUvaGruposAcrEspaldC      => 11
#XTranslate .TbUvaGruposAcrEspaldD      => 12
#XTranslate .TbUvaGruposAcrEspaldDS     => 13
#XTranslate .TbUvaGruposAcrLatadaA      => 14
#XTranslate .TbUvaGruposAcrLatadaB      => 15
#XTranslate .TbUvaGruposAcrLatadaD      => 16
#XTranslate .TbUvaGruposAcrLatadaDS     => 17
#XTranslate .TbUvaGruposListaUvas       => 18
#XTranslate .TbUvaGruposPrecos          => 19
#XTranslate .TbUvaGruposAgiosGraus      => 20
#XTranslate .TbUvaGruposQtColunas       => 20
//
#XTranslate .TbUvaGruposListaUvasCodBase            => 1
#XTranslate .TbUvaGruposListaUvasDescrBase          => 2
#XTranslate .TbUvaGruposListaUvasCodEmConversao     => 3
#XTranslate .TbUvaGruposListaUvasDescrEmConversao   => 4
#XTranslate .TbUvaGruposListaUvasCodBordadura       => 5
#XTranslate .TbUvaGruposListaUvasDescrBordadura     => 6
#XTranslate .TbUvaGruposListaUvasCodOrganica        => 7
#XTranslate .TbUvaGruposListaUvasDescrOrganica      => 8
#XTranslate .TbUvaGruposListaUvasCodFinaClas_comum  => 9
#XTranslate .TbUvaGruposListaUvasDescrFinaClasComum => 10
#XTranslate .TbUvaGruposListaUvasCodParaEspumante   => 11
#XTranslate .TbUvaGruposListaUvasDescrParaEspumante => 12
#XTranslate .TbUvaGruposListaUvasFinaOuComum        => 13
#XTranslate .TbUvaGruposListaUvasCor                => 14
#XTranslate .TbUvaGruposListaUvasTintorea           => 15
#XTranslate .TbUvaGruposListaUvasQtColunas          => 15
//
#XTranslate .TbUvaGruposGrausGrau                      => 1
#XTranslate .TbUvaGruposGrausAgioSobreGrauBase         => 2
#XTranslate .TbUvaGruposGrausPrCompraCodBase           => 3
#XTranslate .TbUvaGruposGrausPrCompraCodEmConversao    => 4
#XTranslate .TbUvaGruposGrausPrCompraCodBordadura      => 5
#XTranslate .TbUvaGruposGrausPrCompraCodOrganica       => 6
#XTranslate .TbUvaGruposGrausPrCompraCodFinaClas_comum => 7
#XTranslate .TbUvaGruposGrausPrCompraCodParaEspumante  => 8
#XTranslate .TbUvaGruposGrausPrMOCCodBase              => 9
#XTranslate .TbUvaGruposGrausPrMOCCodEmConversao       => 10
#XTranslate .TbUvaGruposGrausPrMOCCodBordadura         => 11
#XTranslate .TbUvaGruposGrausPrMOCCodOrganica          => 12
#XTranslate .TbUvaGruposGrausPrMOCCodFinaClas_comum    => 13
#XTranslate .TbUvaGruposGrausPrMOCCodParaEspumante     => 14
#XTranslate .TbUvaGruposGrausQtColunas                 => 14

// acho que nao vou usar  #XTranslate .TbUvaVariedCod       => 1
// acho que nao vou usar  #XTranslate .TbUvaVariedDesc      => 2
// acho que nao vou usar  #XTranslate .TbUvaVariedGrupo     => 3
// acho que nao vou usar  #XTranslate .TbUvaVariedVarUva    => 4
// acho que nao vou usar  #XTranslate .TbUvaVariedCor       => 5
// acho que nao vou usar  #XTranslate .TbUvaVariedTintorea  => 6
// acho que nao vou usar  #XTranslate .TbUvaVariedOrganica  => 7
// acho que nao vou usar  #XTranslate .TbUvaVariedCodBase   => 8
// acho que nao vou usar  #XTranslate .TbUvaVariedQtColunas => 8
