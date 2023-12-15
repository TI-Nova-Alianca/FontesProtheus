// Programa...: WS_Alianca
// Autor......: Robert Koch (royalties: http://advploracle.blogspot.com.br/2014/09/webservice-no-protheus-parte-2-montando.html)
// Data.......: 14/07/2017
// Descricao..: Disponibilizacao de Web Services em geral.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #web_service
// #Descricao         #Disponibilizacao de Web Services em geral
// #PalavasChave      #web_service #generico #integracoes #naweb
// #TabelasPrincipais #SD1 #SD2 #SD3
// #Modulos           Todos
//
// Historico de alteracoes:
// ??/08/2017 - Julio   - Implementada gravacao do arquico ZAM
// 31/08/2017 - Robert  - Implementacao execucao de rotinas sem interface com o usurio.
// 30/11/2017 - Robert  - Implementado recalculo de saldo atual de estoque.
// 07/12/2017 - Robert  - Implementado metodo de atualizacao de estrutura de tabela.
// 12/02/2018 - Robert  - Implementado metodo de exportacao de tabelas.
// 02/05/2018 - Robert  - Implementado metodo OndeSeUsa com base no U_CpoUsado().
// 25/05/2018 - Robert  - Passa a preparar o ambiente de acordo com tag <Filial> recebida no XML.
// 18/07/2048 - Robert  - Releitura do XML apos preparar o ambiente (parece perder o XML).
// 29/07/2018 - Robert  - Ajustes diversos funcao _TrEstq().
// 10/09/2018 - Catia   - Ajustes no WS para inclusao de clientes
// 24/10/2018 - Robert  - Criada tag <User>
// 03/11/2018 - Robert  - Metodo OndeSeUsa portado de volta para user function, para poder chamar do menu.
// 15/02/2019 - Andre   - Adicionado novos campos obrigatórios para novos cliente. A1_CNAE, A1_CONTRIB, A1_IENCONT.
// 30/04/2019 - Robert  - Iniciado metodo de retorno de fechamento de safra.
// 10/05/2019 - Robert  - Passa a fazer validacoes iniciais pela funcao U_ValReqWS (para diferenciar de WS externo)
// 08/07/2019 - Robert  - Criado metodo de inclusao de evento generico.
// 30/08/2019 - Andre   - Incluida TAG para Nome Reduzido no cadastro de cliente.
// 05/09/2019 - Sandra  - Excluido campo B1_VAGRWWC
// 05/09/2019 - Claudia - Incluida a gravação do campo A1_VADTINC
// 01/10/2019 - Claudia - Incluida ação ConsultaDeOrcamentos
// 25/11/2019 - Robert  - Ordenacao resultado ConsultaDeOrcamentos
// 24/11/2019 - Robert  - Consulta de orcamentos passa a ler da function VA_FCONS_ORCAMENTO do SQL.
// 02/01/2020 - Claudia - Incluida ação ConsultaKardex
// 09/01/2020 - Robert  - Inclusao e impressao de ticket de carga safra.
//                      - Encerra ambiente no final.
// 20/01/2020 - Robert  - Novos parametros chamada geracao ticket safra.
// 30/01/2020 - Robert  - Consulta de orcamentos passa a tratar tag <modelo>.
// 31/01/2020 - Robert  - Passa a gerar logs em arquivos separados por usuario.
// 06/02/2020 - Robert  - Novos parametros na consulta de orcamentos
//                      - Melhoria nos logs.
// 11/02/2020 - Robert  - Melhorias consulta de orcamentos 'modelo 2020'.
// 24/02/2020 - Robert  - Implementada consulta ao 'monitor' do sistema.
// 11/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 - 
//                        Comentariada a rotina _ExportTbl ()
// 01/04/2020 - Robert  - Criado tratamento para tag FiltroAppend na rotina AtuEstru.
// 13/07/2020 - Robert  - Inseridas tags para catalogacao de fontes.
// 10/08/2020 - Robert  - Inseridas chamadas da funcao UsoRot().
// 18/11/2020 - Sandra/Robert  - Alteração campo A1_GRPTRIB DE 002 para 003
// 04/12/2020 - Robert  - Tags novas na geracao de cargas de safra
//                      - Criada tag <FP> na consulta de orcamentos a ser retornada 
//                        para o NaWeb (GLPI 8900).
// 07/12/2020 - Robert  - Criadas tags <REA_MES> na consulta de orcamentos a ser 
//                        retornada para o NaWeb (GLPI 8893).
// 11/01/2021 - Robert  - Preenche cadastro viticola com zeros a esquerda na 
//                        geracao de cargas de safra.
// 15/01/2021 - Robert  - Acao 'RetTicketCargaSafra' migrada para ws_namob 
//                        (preciso acessar das filiais)
// 15/03/2021 - Claudia - Incluida a ação 'CapitalSocialAssoc'.GLPI: 8824
// 21/05/2021 - Robert  - Melhorado metodo de gravacao e criado metodo de exclusao de 
//                        eventos da tabela SZN (GLPI 10072)
// 28/05/2021 - Cláudia - Comentariado o if conforme GLPI: 9161
// 22/06/2021 - Robert  - Criada acao AgendaEntregaFaturamento (GLPI 10219).
// 12/07/2021 - Robert  - Criado acao ApontarProducao (GLPI 10479).
// 03/08/2021 - Robert  - Apontamento de producao passa a aceitar mais de uma etiqueta 
//                        na mesma chamada (GLPI 10633)
// 11/08/2021 - Robert  - Removidos logs desnecessarios; ajuste tags retorno apontamento 
//                        producao (GLPI 10633)
// 20/08/2021 - Cláudia - Alterado o MSExecAuto MATA030 descontinuado para MVC. GLPI: 10617
// 27/08/2021 - Robert  - Ordem 3 passa a ser ignorada na consulta de orcamentos (GLPI 10849)
// 30/08/2021 - Robert  - Tag ReaMes alterada para RealizadoNoMes na consulta de orcamentos (GLPI 8893)
// 21/09/2021 - Claudia - Incluida a ação "BuscaPedidosBloqueados". GLPI: 7792
// 21/09/2021 - Claudia - Incluida a ação "GravaBloqueioGerencial". GLPI: 7792
// 30/09/2021 - Claudia - Ajustes nos campos da rotina "BuscaPedidosBloqueados". GLPI: 7792
// 06/10/2021 - Claudia - Incluida a rotina _EnvMargem. GLPI: 7792
// 11/10/2021 - Claudia - Criada nova tag <DescBloqueio> na rotina GravaBloqueioGerencial. GLPI: 7792
// 16/12/2021 - Robert  - Novo formato de retorno da funcao U_GeraSZE()
// 01/02/2022 - Robert  - Reimpressao de ticket carga safra.
// 16/02/2022 - Robert  - Criada acao _CanCarSaf - cancelamento de cargas de safra (GLPI 11634)
//                      - Estava permitindo continuar em alguns casos mesmo com tags obrigatorias vazias.
// 20/02/2022 - Robert  - Novas tags de 'carga compartilhada' na geracao de cargas de safra (GLPI 11633).
//                      - Variavel _sErros renomeada para _sErroWS
//                      - Funcao _ExtraiTag() migrada para U_ExTagXML().
// 02/03/2022 - Robert  - Criada acao EntregaFaturamento (GLPI 11698).
// 18/03/2022 - Robert  - Migradas consultas de fech.safra e cota capital da classe WS_NAMob para ca.
// 21/03/2022 - Robert  - Novos parametros chamada metodo fechamento safra.
// 31/03/2022 - Robert  - Nao usa mais data nos nomes do arquivos de log.
// 07/04/2022 - Robert  - Iniciada funcao de alteracao de dados de associados (GLPI 10138)
// 13/04/2022 - Robert  - Continuada funcao de alteracao de dados de associados (GLPI 10138)
// 03/05/2022 - Claudia - Incluida a gravação do campo a1_savblq.GLPI: 11922
// 13/05/2022 - Robert  - Criada consulta de kardex por lote (GLPI 8482)
// 16/05/2022 - Robert  - Criada acao de apontamento de producao com cod.barras (GLPI 11994)
//                      - Passa a trabalhar com um unico arquivo de log (antes
//                        gerava um arqivo de log para cada usuario).
// 26/05/2022 - Robert  - Novos parametros na chamada da funcao U_RastLt().
// 20/07/2022 - Robert  - Novas tags DiasValid e ChaveNFe na gravacao de eventos (GLPI 12336)
// 01/08/2022 - Robert  - Nova tag MotProrrogTit na gravacao de eventos.
// 11/08/2022 - Robert  - Criada opcao de impressao de etiquetas.
// 13/09/2022 - Robert  - Melhorado teste de muita movimentacao no kardex (de SELECT * para SELECT COUNT (*) )
// 22/10/2022 - Robert  - Grava evento temporario de atualizacao do campo f2_DtEntr para depuracao de programas.
// 03/11/2022 - Robert  - No apontamento de etiq.producao, passa a usar o metodo ValCbEmb para validar 
//                        barras embalagem coletiva.
// 04/11/2022 - Claudia - Incluido nome do vendedor na consulta _PedidosBloq/BuscaPedidosBloqueados. GLPI: 12764
// 09/11/2022 - Robert  - Criada acao ImprimeEtiquetaZAG (GLPI 12773)
// 05/12/2022 - Robert  - Criada acao InutilizaEtiqueta.
//                      - Criada tag ObrigarBarrasProd na impressao de etiquetas.
// 08/12/2022 - Robert  - Criada acao TransfEstqExecuta.
// 13/12/2022 - Robert  - Criada acao TransfEstqNegar.
// 09/01/2023 - Robert  - Nao envia mais o cod.da impr. de ticket para a funcao U_GeraSZE.
// 19/01/2023 - Robert  - ClsTrEstq:Libera() nao tenta mais executar a transferencia no final.
// 27/01/2023 - Robert  - Criada acao TransfEstqInformarEndDest (GLPI 13097).
// 31/01/2023 - Robert  - Geracao carga safra passa mandar cargas compartilhadas concatenadas para U_GeraSZE().
// 10/02/2023 - Robert  - Passa a usar a funcao U__Mata300
// 24/02/2023 - Robert  - Criado tratamento para tags <Safra> e <CargaSafra> na gravacao de eventos.
// 13/03/2023 - Robert  - Implementada acao EstruturaComCustos.
// 24/03/2023 - Claudia - Inclusão da gravação da solicitação de manutenção. GLPI: 12910
// 27/03/2023 - Claudia - Incluida a ação 'InsereSolicManut'. GLPI: 12910
// 03/04/2023 - Robert  - Novos parametros chamada ClsAssoc:FechSafra().
// 06/04/2023 - Robert  - Funcao _ImpEtiqZAG() nao retornava mensagens do objeto em caso de erro de impressao.
// 14/04/2023 - Robert  - Nao inclui retorno de algumas acoes no log, devido ao tamanho do retorno.
// 19/04/2023 - Robert  - Solic.transf.em grid: valida todas as linhas antes de dar retorno.
// 20/04/2023 - Robert  - Tratamento para o atributo ClsTrEstq:CodMotivo na transf.estq.por grid.
// 22/05/2023 - Robert  - Passa a permitir exclusao de eventos com origens WPNMARCARPRESENCAS/WPNFOLLOWUPNOTASFISCAIS
// 02/06/2023 - Robert  - Passa a permitir exclusao de eventos com origem WpnAdicionarEventosAssociado
// 21/07/2023 - Robert  - Nova forma de parametrizacao (via atributos) do metodo ClsAssoc:FechSafra() - GLPI 13956
// 18/08/2023 - Claudia - Casting  da quantidade na rotina _TrEstGrid . GLPI 13656
// 24/08/2023 - Claudia - Criada a Ação GravaTituloPgUnimed. GLPI: 13948 
// 25/10/2023 - Cláudia - Incluida a tag <PrcVenItem> na ação BuscaMargemContrib. GLPI: 14414
// 27/10/2023 - Claudia - Incluida a rotina GravaPgtoContaCorrente. GLPI: 14346
// 04/12/2023 - Robert  - Refeitas algumas indentacoes.
// 07/12/2023 - Robert  - Tratamento porta X filial para poder manter sessao aberta.
//

// ---------------------------------------------------------------------------------------------------------------
#INCLUDE "APWEBSRV.CH"
#INCLUDE "PROTHEUS.CH"
#include "tbiconn.ch"
#include "VA_INCLU.prw"
#include "totvs.ch"

// Estrutura de retorno de dados
WSSTRUCT RetornoWS
	WSDATA Resultado AS String
	WSDATA Mensagens AS String OPTIONAL
ENDWSSTRUCT

// // Estrutura de retorno de dados para filial 01
// WSSTRUCT RetornoWS01
// 	WSDATA Resultado AS String
// 	WSDATA Mensagens AS String OPTIONAL
// ENDWSSTRUCT

// --------------------------------------------------------------------------
// WebService
WSSERVICE WS_Alianca DESCRIPTION "Nova Alianca - Executa atualizacoes diversas"
	WSDATA XmlRcv    AS string
	WSDATA Retorno   AS RetornoWS
//	WSDATA Retorno01 AS RetornoWS01

	WSMETHOD IntegraWS DESCRIPTION "Executa integracoes conforme tags do XML."
//	WSMETHOD IntegraWS01 DESCRIPTION "Executa integracoes conforme tags do XML."
ENDWSSERVICE

// --------------------------------------------------------------------------
WSMETHOD IntegraWS WSRECEIVE XmlRcv WSSEND Retorno WSSERVICE WS_Alianca
	local _sError    := ""
	local _sWarning  := ""
	local _aUsuario  := {}  // Guarda dados de identificacao do usuario.
	local _nSegIni   := seconds ()
	local _sExclFIli := ''
	private __cUserId  := ''
	private cUserName  := ''
	private _sWS_Empr  := ""
	private _sWS_Filia := ""
	private _oXML      := NIL
	private _sErroWS   := ""
	private _sMsgRetWS := ""
	private _sAcao     := ""
	private _sArqLog   := GetClassName (::Self) + ".log"

	//WSDLDbgLevel(2)  // Ativa dados para debug no arquivo console.log
	set century on

	// Como nao consigo (ateh agora) manter uma sessao 'aberta' para atender
	// solicitacoes de diferentes filiais, estou configurando web services
	// em portas diferentes, um para cada filial (criar tratamento para outras
	// filiais conforme surgir necessidade)
	// Manter compatibilidade com a porta HTTP configurada no arquivo appserver.ini
	U_Log2 ('debug', '[' + procname () + ']httpHeadIn->HOST = ' + cvaltochar (httpHeadIn->HOST))
	_sExclFIli = ''
	if empty (_sErroWS) .and. ':7901' $ httpHeadIn->HOST
//	if '<FILIAL>01</FILIAL>' $ upper (::XmlRcv)
		_sExclFIli = '01'
	endif

	// Vou fazer uma validacao basica sem extrair de fato os dados do XML, para ganho de performance.
	if empty (_sErroWS) .and. ! empty (_sExclFIli) .and. ! '<FILIAL>' + _sExclFIli + '</FILIAL>' $ upper (::XmlRcv)
		_SomaErro ("Este web service / porta atende somente a requisicoes da filial " + _sExclFIli)
	endif

	// Validacoes gerais e extracoes de dados basicos do XML.
	if empty (_sErroWS)
		U_ValReqWS (GetClassName (::Self), ::XmlRcv, @_sErroWS, @_sWS_Empr, @_sWS_Filia, @_sAcao)
	endif

	// Faz mais uma validacao de porta X filial depois de ter extraido a 
	// filial 'mais corretamente' do XML.
	if empty (_sErroWS) .and. ! empty (_sExclFIli)
		if _sWS_Filia != _sExclFIli
			_SomaErro ("Apos ler o XML verifiquei que este web service atende somente a filial " + _sExclFIli)
		endif
	endif

	if empty (_sErroWS)
		_aUsuario = {__cUserId, cUserName}  // Guarda para uso posterior, pois o PREPARE ENVIRONMENT limpa essas variaveis.
	endif

	// Prepara o ambiente conforme empresa e filial solicitadas.
	if empty (_sErroWS)
		prepare environment empresa _sWS_Empr filial _sWS_Filia
		private __RelDir  := "c:\temp\spool_protheus\"
		set century on
	endif
	if empty (_sErroWS) .and. cFilAnt != _sWS_Filia
//		u_log2 ('erro', 'Nao consegui acessar a filial solicitada.')
		_SomaErro ("Nao foi possivel acessar a filial '" + _sWS_Filia + "' conforme solicitado.")
	endif
	if empty (_sErroWS)
		__cUserId = _aUsuario [1]
		cUserName = _aUsuario [2]
	endif

	// Converte novamente a string recebida para XML, pois a criacao do ambiente parece apagar o XML.
	// Nao vou tratar erros do parser pois teoricamente jah foram tratados na funcao VarReqWS
	if empty (_sErroWS)
		_oXML := XmlParser(::XmlRcv, "_", @_sError, @_sWarning)
	endif

	// Executa a acao especificada no XML.
	if empty (_sErroWS)
		U_Log2 ('info', '[' + procname () + ']Acao solicitada ao web service: ' + _sAcao)
		U_UsoRot ('I', _sAcao, '')

		do case
		case _sAcao == 'ExecutaBatch'
			_ExecBatch ()
		case _sAcao == 'GravaInspecao'
			_GrvInsp ()
		case _sAcao == 'RastrearLote'
			_RastLt ()
		case _sAcao == 'ZAM'
			_ZAM ()
		case _sAcao == 'RefazSaldoAtual'
			_SaldoAtu ()
		case _sAcao == 'AtuEstru'
			_AtuEstru ()
		case _sAcao == 'TransfEstqInsere'
			_TrEstq ('INS')
		case _sAcao == 'TransfEstqAutoriza'
			_TrEstq ('AUT')
		case _sAcao == 'TransfEstqDeleta'
			_TrEstq ('DEL')
		case _sAcao == 'TransfEstqExecuta'
			_TrEstq ('EXE')
		case _sAcao == 'TransfEstqNegar'
			_TrEstq ('NEG')
		case _sAcao == 'TransfEstqInformarEndDest'
			_TrEstq ('IED')
		case _sAcao == 'TransfEstqInsereGrid'
			_TrEstGrid ()
		case _sAcao == 'OndeSeUsa'
			_OndeSeUsa ()
		case _sAcao == 'IncluiCliente'
			_IncCli ()
		case _sAcao == 'AlteraCliente'
			_AltCli ()
		case _sAcao == 'IncluiEvento'
			_IncEvt ()
		case _sAcao == 'ExcluiEvento'
			_DelEvt ()
		case _sAcao == 'IncluiProduto'
			_IncProd ()
		case _sAcao == 'ConsultaDeOrcamentos'
			_ExecConsOrc ()
		case _sAcao == 'IncluiCargaSafra'
			_IncCarSaf ()
		case _sAcao == 'CancelaCargaSafra'
			_CanCarSaf ()
		case _sAcao == 'ConsultaKardex'
			_ExecKardex ()
		case _sAcao == 'ConsultaKardexLote'
			_KardexLt ()
		case _sAcao == 'CapitalSocialAssoc'
			_ExecCapAssoc ()
		case _sAcao == 'AgendaEntregaFaturamento'
			_AgEntFat ()
		case _sAcao == 'EntregaFaturamento'
			_DtEntFat ()
		case _sAcao == 'ApontarProducao'
			_ApontProd ()
		case _sAcao == 'ApontarProducaoEtqCodBar'
			_ApPrEtqCB ()
		case _sAcao == 'BuscaPedidosBloqueados'
			_PedidosBloq ()
		case _sAcao == 'GravaBloqueioGerencial'
			_GrvLibPed ()
		case _sAcao == 'BuscaMargemContrib'
			_EnvMargem ()
		case _sAcao == 'ImprimeTicketCargaSafra'
			_ITkCarSaf ()
		case _sAcao == 'ConsultaFechamentoSafraAssoc'
			_AsFecSaf ()
		case _sAcao == 'ConsultaCapitalSocialAssoc'
			_AsCapSoc ()
		case _sAcao == 'AlteraDadosAssociado'
			_AltAssoc ()
		case _sAcao == 'ImprimeEtiqueta'
			_ImpEtiq ()
		case _sAcao == 'ImprimeEtiquetaZAG'
			_ImpEtiqZAG ()
		case _sAcao == 'InutilizaEtiqueta'
			_InutEtiq ()
		case _sAcao == 'ZZUVincularUsuario'
			_ZZU ('VincularUsuario')
		case _sAcao == 'ConsultaEstruturaComCustos'
			_EstrCust ()
		case _sAcao == 'TesteRobert'
			_TstRobert ()
		case _sAcao == 'InsereSolicManut'
			_IncManut()
		case _sAcao == 'GravaTituloPgUnimed'
			_GrvTituloUnimed ()
		case _sAcao == 'GravaPgtoContaCorrente'
			_GrvPgtoContaCorrente ()
		otherwise
			_SomaErro ("A acao especificada no XML eh invalida: " + _sAcao)
		endcase
		U_UsoRot ('F', _sAcao, '')
	else
		u_log2 ('erro', _sErroWS)
	endif

	// Cria a instância de retorno
	::Retorno := WSClassNew ("RetornoWS")
	::Retorno:Resultado = iif (empty (_sErroWS), "OK", "ERRO")
	::Retorno:Mensagens := ''
	::Retorno:Mensagens += iif (_sErroWS $ ::Retorno:Mensagens, '', _sErroWS)
	::Retorno:Mensagens += iif (_sMsgRetWS $ ::Retorno:Mensagens, '', _sMsgRetWS)

	// Encerra ambiente. Ficou um pouco mais lento, mas resolveu problema que estava dando de,
	// a cada execucao, trazer um cFilAnt diferente. Robert, 09/01/2020.
	// dica em: https://centraldeatendimento.totvs.com/hc/pt-br/articles/360027855031-MP-ADVPL-FINAL-GERA-EXCE%C3%87%C3%83O
	if empty (_sExclFili)
		RPCClearEnv ()
	else
		U_Log2 ('debug', '[' + procname () + ']Vou manter ambiente aberto por que estou numa porta que atende uma filial exclusiva.')
	endif


	// Como algumas opcoes retornam bastante coisa, vou economizar um pouco o log
	if _sAcao $ 'ConsultaKardex/ConsultaDeOrcamentos'
		u_log2 ('info', 'Mensagens WS: (nao gravarei log para esta acao por eh muito longo)')
	else
		u_log2 ('info', 'Mensagens WS: ' + ::Retorno:Mensagens)
	endif
	u_log2 ('info', 'Retorno   WS: ' + ::Retorno:Resultado + ' (' + cvaltochar (seconds () - _nSegIni) + 's.)')
	u_log2 ('info', '')  // Apenas para gerar uma linha vazia
Return .T.


// --------------------------------------------------------------------------
// Atualiza a estrutura de uma tabela (drop + chkfile + append)
static function _AtuEstru ()
	local   _sTabela   := ""
	local   _sFilAppen := ''
	private _sErroAuto := ""  // Variavel alimentada pela funcao U_Help

	if empty (_sErroWS)
		_sTabela   = _ExtraiTag ("_oXML:_WSAlianca:_Tabela", .T., .F.)
		_sFilAppen = _ExtraiTag ("_oXML:_WSAlianca:_FiltroAppend", .F., .F.)
	endif

	if empty (_sErroWS)
		u_log2 ('info', 'Tentando atualizar estrutura da tabela ', _sTabela)
		if ! U_AtuEstru (_sTabela, _sFilAppen)
			_sErroWS = _sErroAuto
		else
			_sMsgRetWS = _sErroAuto
		endif
	endif
Return


// --------------------------------------------------------------------------
// Executa batch
static function _ExecBatch ()
	local _sSeqBatch := ""
	private _oBatch    := ClsBatch ():New ()

	u_logIni ()
	_sSeqBatch = _ExtraiTag ("_oXML:_WSAlianca:_Sequencia", .T., .F.)

	if empty (_sErroWS)
		zz6 -> (dbsetorder (1))  // ZZ6_FILIAL+ZZ6_SEQ
		if ! zz6 -> (dbseek (xfilial ("ZZ6") + _sSeqBatch, .F.))
			_SomaErro ("Sequencia nao localizada na tabela ZZ6")
		else
			_oBatch := ClsBatch ():New (zz6 -> (recno ()))
			if ! _sWS_Filia $ _oBatch:FilDes
				_SomaErro ("Batch nao se destina a esta filial.")
			else
				_oBatch:Executa ()
				// u_log ('Retorno do batch:', _oBatch:Retorno)
			endif
		endif
	endif

	if _oBatch:Retorno == 'N'
		_SomaErro ("Batch nao executado" + ' ' + _oBatch:Mensagens)
	endif
	_sMsgRetWS += _oBatch:Comando + ' ' + _oBatch:Mensagens

	u_logFim ()
Return
//
// --------------------------------------------------------------------------
static function _GrvInsp ()
	local _oSQL      := NIL
	local _sProduto  := ""
	local _sLote     := ""
	local _sNF       := ""
	local _sSerie    := ""
	local _sFornece  := ""
	local _sLoja     := ""
	local _sResult   := ""
	local _sTipoInsp := ""

	// u_logIni ()

	if empty (_sErroWS) .and. empty (cUserName)
		_SomaErro ("Usuario nao identificado.")
	endif

	if empty (_sErroWS)
		_sTipoInsp = _ExtraiTag ("_oXML:_WSAlianca:_TipoInspecao", .T., .F.)
		_sProduto  = _ExtraiTag ("_oXML:_WSAlianca:_Produto",      .T., .F.)
		_sResult   = _ExtraiTag ("_oXML:_WSAlianca:_Resultado",    .T., .F.)
		_sLote     = _ExtraiTag ("_oXML:_WSAlianca:_Lote",         (_sTipoInsp == 'Lote'), .F.)
		_sNF       = _ExtraiTag ("_oXML:_WSAlianca:_NF",           (_sTipoInsp == 'NF'), .F.)
		_sSerie    = _ExtraiTag ("_oXML:_WSAlianca:_Serie",        (_sTipoInsp == 'NF'), .F.)
		_sFornece  = _ExtraiTag ("_oXML:_WSAlianca:_Fornecedor",   (_sTipoInsp == 'NF'), .F.)
		_sLoja     = _ExtraiTag ("_oXML:_WSAlianca:_Loja",         (_sTipoInsp == 'NF'), .F.)
	endif

	if empty (_sErroWS) .and. _sTipoInsp == 'NF'
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT COUNT (*)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SD1") + " SD1 "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND D1_FILIAL  = '" + _sWS_Filia  + "'"
		_oSQL:_sQuery +=   " AND D1_DOC     = '" + _sNF      + "'"
		_oSQL:_sQuery +=   " AND D1_SERIE   = '" + _sSerie   + "'"
		_oSQL:_sQuery +=   " AND D1_FORNECE = '" + _sFornece + "'"
		_oSQL:_sQuery +=   " AND D1_LOJA    = '" + _sLoja    + "'"
		_oSQL:_sQuery +=   " AND D1_COD     = '" + _sProduto + "'"
		_oSQL:_sQuery +=   " AND D1_LOTECTL = '" + _sLote    + "'"
		_oSQL:Log ()
		if _oSQL:RetQry (1, .F.) < 1
			_SomaErro ("Nao foi encontrada NF de entrada com os parametros informados " + _oSQL:_sQuery)
		endif
	endif
	if empty (_sErroWS)
		reclock ("ZZE", .T.)
		zze -> zze_filial = _sWS_Filia
		zze -> zze_produt = _sProduto
		zze -> zze_lote   = _sLote
		zze -> zze_data   = date ()
		zze -> zze_hora   = left (time (), 5)
		zze -> zze_user   = cUserName
		zze -> zze_result = _sResult
		if _sTipoInsp == 'NF'
			zze -> zze_nf     = _sNF
			zze -> zze_serie  = _sSerie
			zze -> zze_fornec = _sFornece
			zze -> zze_loja   = _sLoja
		endif
		msunlock ()
		_sMsgRetWS += "Registro gravado na tabela ZZE"
	endif

	// u_logFim ()
Return
//
// --------------------------------------------------------------------------
// RastrearLote
static function _RastLt ()
	local _sProduto  := ""
	local _sLote     := ""
	local _sMapa     := ""
	local _oSQL      := NIL
	local _sChave    := ""
	local _nQtBase   := 0

	// u_logIni ()
	if empty (_sErroWS)
		_sProduto  = _ExtraiTag ("_oXML:_WSAlianca:_Produto", .T., .F.)
		_sLote     = _ExtraiTag ("_oXML:_WSAlianca:_Lote", .T., .F.)
		_nQtBase   = _ExtraiTag ("_oXML:_WSAlianca:_QtBase", .F., .F.)
		_nQtBase = iif (empty (_nQtBase), 1, _nQtBase)
	endif

	if empty (_sErroWS)
		_sMapa = U_RastLt (_sWS_Filia, _sProduto, _sLote, 0, NIL, _nQtBase, 'A')
		u_log ('')
		u_log (_sMapa)
		_sChave = 'RAST' + dtos (date ()) + strtran (time (), ':', '')
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "INSERT INTO VA_TEXTOS (CHAVE, D_E_L_E_T_, TEXTO)"
		_oSQL:_sQuery += " VALUES ('" + _sChave + "',"
		_oSQL:_sQuery +=          "' ',"
		_oSQL:_sQuery +=          "'" + _sMapa + "')"
		//_oSQL:Log ()
		if _oSQL:Exec ()
			_sMsgRetWS = _sChave
		else
			_SomaErro ("Erro na gravacao: " + _oSQL:_sQuery)
		endif
	endif

	// u_logFim ()
Return
//
// --------------------------------------------------------------------------
// Recalculo do saldo atual em estoque
static function _SaldoAtu ()
	local _sProduto  := ""
//	local _sPerg     := ""
//	local _oSQL      := NIL
//	local _sUltExec  := ""

	//u_logIni ()
	if empty (_sErroWS)
		_sProduto  = _ExtraiTag ("_oXML:_WSAlianca:_Produto", .T., .F.)
	endif

	if empty (_sErroWS)
/*
		// Guarda ultimo log deste processo para posteriormente verificar se gerou novo log.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT MAX (CV8_DATA + CV8_HORA)"
		_oSQL:_sQuery += " FROM " + RetSQLName ("CV8")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND CV8_FILIAL = '" + xfilial ("CV8") + "'"
		_oSQL:_sQuery += " AND CV8_PROC = 'MATA300'"
		//_oSQL:Log ()
		_sUltExec = _oSQL:RetQry (1, .F.)

		// Atualiza perguntas da rotina e executa 'refaz saldo atual'.
		_sPerg := "MTA300"
		U_GravaSX1 (_sPerg, "01", "")      // Alm. inicial
		U_GravaSX1 (_sPerg, "02", "zz")    // Alm. final
		U_GravaSX1 (_sPerg, "03", _sProduto)  // Produto inicial
		U_GravaSX1 (_sPerg, "04", _sProduto)  // Produto final
		U_GravaSX1 (_sPerg, "05", 1)       // Zera saldo dos produtos MOD = Sim
		U_GravaSX1 (_sPerg, "06", 1)       // Zera CM dos produtos MOD = Sim
		U_GravaSX1 (_sPerg, "07", 2)       // Trava registros do SB2 = Nao
		U_GravaSX1 (_sPerg, "08", 2)       // Seleciona filiais = Nao
		U_Log2 ('info', "Iniciando MATA300 (refaz saldo atual)")
		MATA300 (.T.)

		// Verifica se rodou com sucesso.
		_oSQL:_sQuery := "SELECT CV8_DATA + ' ' + CV8_HORA + ' ' + rtrim (CV8_MSG)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("CV8")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND CV8_FILIAL = '" + xfilial ("CV8") + "'"
		_oSQL:_sQuery +=   " AND CV8_PROC   = 'MATA300'"
		_oSQL:_sQuery +=   " AND CV8_INFO   = '2'"
		_oSQL:_sQuery +=   " AND CV8_DATA + CV8_HORA > '" + _sUltExec + "'"
		_oSQL:_sQuery +=   " AND UPPER (CV8_USER) = '" + alltrim (upper (cUserName)) + "'"
		_oSQL:Log ()
		_sUltExec = _oSQL:RetQry (1, .F.)
		if empty (_sUltExec)
			_SomaErro ("Erro no processo")
		else
			_sMsgRetWS = _sUltExec
		endif
*/
		if ! U__Mata300 (_sProduto, _sProduto, '', 'zz')
			_SomaErro ("Erro no processo")
		else
			_sMsgRetWS = 'Saldo reprocessado.'
		endif
	endif

	//u_logFim ()
Return
//
// --------------------------------------------------------------------------
// ZAM
static function _ZAM ()
	local _sFILIAL := ""
	local _sDATAPT := ""
	local _sMAQCOD := ""
	local _sDATINI := ""
	local _sDATFIM := ""
	local _sHORINI := ""
	local _sHORFIM := ""
	local _sTEMPO  := ""
	local _sTIPCOD := ""
	local _sOBS    := ""
	local _sUSUCOD := ""
	local _sIAE    := ""

	u_logIni ()

	if empty (_sErroWS) .and. empty (cUserName)
		_SomaErro ("Usuario nao identificado.")
	endif

	if empty (_sErroWS)
		_sFILIAL = _ExtraiTag ("_oXML:_WSAlianca:_FILIAL", .T., .F.)
		_sDATAPT = _ExtraiTag ("_oXML:_WSAlianca:_DATAPT", .T., .F.)
		_sMAQCOD = _ExtraiTag ("_oXML:_WSAlianca:_MAQCOD", .T., .F.)
		_sDATINI = _ExtraiTag ("_oXML:_WSAlianca:_DATINI", .T., .T.)
		_sDATFIM = _ExtraiTag ("_oXML:_WSAlianca:_DATFIM", .T., .T.)
		_sHORINI = _ExtraiTag ("_oXML:_WSAlianca:_HORINI", .T., .F.)
		_sHORFIM = _ExtraiTag ("_oXML:_WSAlianca:_HORFIM", .T., .F.)
		_sTEMPO  = _ExtraiTag ("_oXML:_WSAlianca:_TEMPO" , .T., .F.)
		_sTIPCOD = _ExtraiTag ("_oXML:_WSAlianca:_TIPCOD", .T., .F.)
		_sOBS    = _ExtraiTag ("_oXML:_WSAlianca:_OBS"   , .T., .F.)
		_sUSUCOD = _ExtraiTag ("_oXML:_WSAlianca:_USUCOD", .T., .F.)
		_sIAE    = _ExtraiTag ("_oXML:_WSAlianca:_IAE"   , .T., .F.)
	endif

	if empty (_sErroWS) .and. _sIAE <> "E"
		if empty(_sFILIAL)
			_SomaErro ("Filial invalida.")
		endif

		if empty(_sDATAPT) .or. (StoD(_sDATAPT) > date())
			_SomaErro ("Data do Apontamento invalida.")
		endif

		SN1 -> (dbsetorder (1))
		if empty(_sMAQCOD) .or. ! SN1 -> (dbseek (_sFILIAL + AllTrim(_sMAQCOD), .F.))
			_SomaErro ("Maquina invalida.")
		endif

		if empty(_sDATINI) .or. (StoD(_sDATINI) > date())
			_SomaErro ("Data Inicial invalida.")
		endif

		if empty(_sHORINI)
			_SomaErro ("Hora Inicial invalida.")
		endif

		if empty(_sDATFIM) .or. (StoD(_sDATFIM) > date())
			_SomaErro ("Data Final invalida.")
		endif

		if empty(_sHORFIM)
			_SomaErro ("Hora Final invalida.")
		endif

		if (AllTrim(_sDATINI) + AllTrim(_sHORINI)) > (DtoS(date()) + SubStr(time(),1,5))
			_SomaErro ("Data Inicial nao pode ser maior do que hoje.")
		endif

		if (AllTrim(_sDATFIM) + AllTrim(_sHORFIM)) > (DtoS(date()) + SubStr(time(),1,5))
			_SomaErro ("Data Final nao pode ser maior do que hoje.")
		endif

		if .not. empty(AllTrim(_sTIPCOD)) .and. ! U_ExistZX5("45", _sTIPCOD)
			_SomaErro ("Tipo invalido.")
		endif

		if empty(_sUSUCOD)
			_SomaErro ("Usuario invalido.")
		endif
	endif

	if empty (_sErroWS)
		if _sIAE = "I"
			ZAM -> (dbsetorder (1))  // ZAM_FILIAL + ZAM_MAQCOD + ZAM_DATINI + ZAM_HORINI
			if ! ZAM -> (dbseek (_sFILIAL + _sMAQCOD + "     " + _sDATINI + _sHORINI, .F.))
				reclock ("ZAM", .T.)
				ZAM -> ZAM_FILIAL = _sFILIAL
				ZAM -> ZAM_DATAPT = StoD(_sDATAPT)
				ZAM -> ZAM_MAQCOD = _sMAQCOD + "     "
				ZAM -> ZAM_DATINI = StoD(_sDATINI)
				ZAM -> ZAM_DATFIM = StoD(_sDATFIM)
				ZAM -> ZAM_HORINI = _sHORINI
				ZAM -> ZAM_HORFIM = _sHORFIM
				ZAM -> ZAM_TEMPO  = _sTEMPO
				ZAM -> ZAM_TIPCOD = _sTIPCOD
				ZAM -> ZAM_OBS    = _sOBS
				ZAM -> ZAM_USUCOD = _sUSUCOD
				msunlock ()
				_sMsgRetWS += "Evento incluido com sucesso."
			else
				_SomaErro ("Evento ja cadastrado.")
			endif
		endif

		if _sIAE = "A"
			u_log(_sFILIAL + _sMAQCOD + _sDATINI + _sHORINI)
			ZAM -> (dbsetorder (1))  // ZAM_FILIAL + ZAM_MAQCOD + ZAM_DATINI + ZAM_HORINI
			if ZAM -> (dbseek (_sFILIAL + _sMAQCOD + "     " + _sDATINI + _sHORINI, .F.))
				reclock ("ZAM", .F.)
				ZAM -> ZAM_DATAPT = StoD(_sDATAPT)
				ZAM -> ZAM_DATFIM = StoD(_sDATFIM)
				ZAM -> ZAM_HORFIM = _sHORFIM
				ZAM -> ZAM_TEMPO  = _sTEMPO
				ZAM -> ZAM_TIPCOD = _sTIPCOD
				ZAM -> ZAM_OBS    = _sOBS
				ZAM -> ZAM_USUCOD = _sUSUCOD
				msunlock ()
				_sMsgRetWS += "Evento alterado com sucesso."
			else
				_SomaErro ("Evento nao cadastrado.")
			endif
		endif

		if _sIAE = "E"
			ZAM -> (dbsetorder (1))  // ZAM_FILIAL + ZAM_MAQCOD + ZAM_DATINI + ZAM_HORINI
			if ZAM -> (dbseek (_sFILIAL + _sMAQCOD + "     " + _sDATINI + _sHORINI, .F.))
				reclock ("ZAM", .F.)
				ZAM -> (dbdelete ())
				msunlock ()
				_sMsgRetWS += "Evento excluido com sucesso."
			else
				_SomaErro ("Evento nao cadastrado.")
			endif
		endif
	endif

	u_logFim ()
Return
//
// --------------------------------------------------------------------------
// Interface para incluir eventos genericos
static function _IncEvt ()
	local _oEvento := NIL
	local _dDtEvt  := ''
//	U_Log2 ('info', 'Iniciando ' + procname ())
	_oEvento := ClsEvent ():New ()
	_oEvento:Filial  = cFilAnt

	// Data e hora: se nao informadas no XML, assume o momento da gravacao.
	if empty (_sErroWS) ; _dDtEvt = _ExtraiTag ("_oXML:_WSAlianca:_DtEvento", .F., .T.) ; endif
		if empty (_sErroWS)
			if empty (_dDtEvt)
				_oEvento:DtEvento = date ()
			else
				if len (_dDtEvt) != 8
					_SomaErro ("Data do evento deve ser informada no formato AAAAMMDD")
				else
					_oEvento:DtEvento = stod (_dDtEvt)
				endif
			endif
		endif
		if empty (_sErroWS) ; _oEvento:HrEvento   = _ExtraiTag ("_oXML:_WSAlianca:_HrEvento", .F., .F.) ;   endif
			if empty (_sErroWS)
				if empty (_oEvento:HrEvento)
					_oEvento:HrEvento = time ()
				else
					if len (_oEvento:HrEvento) != 8 .or. substr (_oEvento:HrEvento, 3, 1) != ':' .or. substr (_oEvento:HrEvento, 6, 1) != ':'
						_SomaErro ("Hora do evento deve ser informada no formato HH:MM:SS")
					endif
				endif
			endif
			if empty (_sErroWS) ; _oEvento:CodEven    = _ExtraiTag ("_oXML:_WSAlianca:_CodEven",      .T., .F.) ;   endif
				if empty (_sErroWS) .and. ! U_ExistZX5 ('54', _oEvento:CodEven)
					_SomaErro ("Codigo do evento " + _oEvento:CodEven + " nao cadastrado na tabela 54 do arquivo ZX5.")
				endif
				if empty (_sErroWS) ; _oEvento:Origem     = _ExtraiTag ("_oXML:_WSAlianca:_Origem",         .T., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:Texto      = _ExtraiTag ("_oXML:_WSAlianca:_Texto",          .T., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:NFSaida    = _ExtraiTag ("_oXML:_WSAlianca:_NFSaida",        .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:SerieSaid  = _ExtraiTag ("_oXML:_WSAlianca:_SerieSaid",      .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:ParcTit    = _ExtraiTag ("_oXML:_WSAlianca:_ParcTit",        .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:NFEntrada  = _ExtraiTag ("_oXML:_WSAlianca:_NFEntrada",      .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:SerieEntr  = _ExtraiTag ("_oXML:_WSAlianca:_SerieEntr",      .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:Produto    = _ExtraiTag ("_oXML:_WSAlianca:_Produto",        .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:PedVenda   = _ExtraiTag ("_oXML:_WSAlianca:_PedVenda",       .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:Cliente    = _ExtraiTag ("_oXML:_WSAlianca:_Cliente",        .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:LojaCli    = _ExtraiTag ("_oXML:_WSAlianca:_LojaCli",        .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:Fornece    = _ExtraiTag ("_oXML:_WSAlianca:_Fornece",        .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:LojaFor    = _ExtraiTag ("_oXML:_WSAlianca:_LojaFor",        .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:MailTo     = _ExtraiTag ("_oXML:_WSAlianca:_MailTo",         .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:MailToZZU  = _ExtraiTag ("_oXML:_WSAlianca:_MailToZZU",      .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:Alias      = _ExtraiTag ("_oXML:_WSAlianca:_Alias",          .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:Recno      = val (_ExtraiTag ("_oXML:_WSAlianca:_Recno",     .F., .F.)) ;  endif
				if empty (_sErroWS) ; _oEvento:CodAlias   = _ExtraiTag ("_oXML:_WSAlianca:_CodAlias",       .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:Chave      = _ExtraiTag ("_oXML:_WSAlianca:_Chave",          .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:OP         = _ExtraiTag ("_oXML:_WSAlianca:_OP",             .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:Etiqueta   = _ExtraiTag ("_oXML:_WSAlianca:_Etiqueta",       .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:CodProceda = _ExtraiTag ("_oXML:_WSAlianca:_CodProceda",     .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:Transp     = _ExtraiTag ("_oXML:_WSAlianca:_Transp",         .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:TranspReds = _ExtraiTag ("_oXML:_WSAlianca:_TranspReds",     .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:DiasValid  = val (_ExtraiTag ("_oXML:_WSAlianca:_DiasValid", .F., .F.)) ;  endif
				if empty (_sErroWS) ; _oEvento:ChaveNFe   = _ExtraiTag ("_oXML:_WSAlianca:_ChaveNFe",       .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:MotProrTit = _ExtraiTag ("_oXML:_WSAlianca:_MotProrrogTit",  .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:Safra      = _ExtraiTag ("_oXML:_WSAlianca:_Safra",          .F., .F.) ;   endif
				if empty (_sErroWS) ; _oEvento:CargaSafra = _ExtraiTag ("_oXML:_WSAlianca:_CargaSafra",     .F., .F.) ;   endif
				if empty (_sErroWS)
					if ! _oEvento:Grava ()
						_SomaErro ("Erro na gravacao do objeto evento")
					else
						_sMsgRetWS = "Evento gravado com sucesso"
					endif
				endif
				Return


// --------------------------------------------------------------------------
// Interface para deletar eventos genericos
static function _DelEvt ()
	local _oEvento := NIL
	local _nRegSZN := 0
	if empty (_sErroWS) ; _nRegSZN = val (_ExtraiTag ("_oXML:_WSAlianca:_RecnoSZN",      .T., .F.)) ;   endif
		if empty (_sErroWS)
			_oEvento := ClsEvent ():New (_nRegSZN)

			// Permitirei exclusao somente de algumas origens de eventos (GLPI 9161).
			//	if ! alltrim (upper (_oEvento:Origem)) $ upper ('WPNFATSOLICITACAOPRORROGACAO/WPNFATEVENTOSNOTASMOV/TRNVA_VEVENTOS/WPNFATAGENDARENTREGA')
			//	if ! alltrim (upper (_oEvento:Origem)) $ upper ('WPNFATSOLICITACAOPRORROGACAO/WPNFATEVENTOSNOTASMOV/TRNVA_VEVENTOS/WPNFATAGENDARENTREGA/WPNMARCARPRESENCAS/WPNFOLLOWUPNOTASFISCAIS')
			if ! alltrim (upper (_oEvento:Origem)) $ upper ('WPNFATSOLICITACAOPRORROGACAO/WPNFATEVENTOSNOTASMOV/TRNVA_VEVENTOS/WPNFATAGENDARENTREGA/WPNMARCARPRESENCAS/WPNFOLLOWUPNOTASFISCAIS/WpnAdicionarEventosAssociado')
				_SomaErro ("Eventos com esta origem nao podem ser excluidos manualmente.")
			endif
		endif
		if empty (_sErroWS)
			_oEvento:Exclui ()
		endif
		Return


// --------------------------------------------------------------------------
// Interface para a classe de transferencias de estoque.
static function _TrEstq (_sQueFazer)
	local _sDocZAG  := ""
	local _oTrEstq  := NIL
	local _sMotZAG  := ''
	local _sNEndDst := ''

	do case
	case _sQueFazer == 'INS'  // Inserir
		_oTrEstq := ClsTrEstq ():New ()
		if empty (_sErroWS) ; _oTrEstq:FilOrig  = padr (_ExtraiTag ("_oXML:_WSAlianca:_FilialOrigem",    .T., .F.), 2) ;  endif
		if empty (_sErroWS) ; _oTrEstq:FilDest  = padr (_ExtraiTag ("_oXML:_WSAlianca:_FilialDestino",   .T., .F.), 2) ;  endif
		if empty (_sErroWS) ; _oTrEstq:ProdOrig = padr (_ExtraiTag ("_oXML:_WSAlianca:_ProdutoOrigem",   .T., .F.), 15) ; endif
		if empty (_sErroWS) ; _oTrEstq:ProdDest = padr (_ExtraiTag ("_oXML:_WSAlianca:_ProdutoDestino",  .T., .F.), 15) ; endif
		if empty (_sErroWS) ; _oTrEstq:AlmOrig  = padr (_ExtraiTag ("_oXML:_WSAlianca:_AlmoxOrigem",     .T., .F.), 2) ;  endif
		if empty (_sErroWS) ; _oTrEstq:AlmDest  = padr (_ExtraiTag ("_oXML:_WSAlianca:_AlmoxDestino",    .T., .F.), 2) ;  endif
		if empty (_sErroWS) ; _oTrEstq:LoteOrig = padr (_ExtraiTag ("_oXML:_WSAlianca:_LoteOrigem",      .F., .F.), 10) ; endif
		if empty (_sErroWS) ; _oTrEstq:LoteDest = padr (_ExtraiTag ("_oXML:_WSAlianca:_LoteDestino",     .F., .F.), 10) ; endif
		if empty (_sErroWS) ; _oTrEstq:EndOrig  = padr (_ExtraiTag ("_oXML:_WSAlianca:_EnderecoOrigem",  .F., .F.), 15) ; endif
		if empty (_sErroWS) ; _oTrEstq:EndDest  = padr (_ExtraiTag ("_oXML:_WSAlianca:_EnderecoDestino", .F., .F.), 15) ; endif
		if empty (_sErroWS) ; _oTrEstq:QtdSolic = val  (_ExtraiTag ("_oXML:_WSAlianca:_QtdSolic",        .T., .F.)) ;     endif
		if empty (_sErroWS) ; _oTrEstq:Motivo   =       _ExtraiTag ("_oXML:_WSAlianca:_Motivo",          .T., .F.) ;      endif
		if empty (_sErroWS) ; _oTrEstq:OP       = padr (_ExtraiTag ("_oXML:_WSAlianca:_OP",              .F., .F.), 14) ; endif
		if empty (_sErroWS) ; _oTrEstq:ImprEtq  =       _ExtraiTag ("_oXML:_WSAlianca:_Impressora",      .F., .F.) ;      endif
		if empty (_sErroWS)
			_oTrEstq:UsrIncl = cUserName
			_oTrEstq:DtEmis  = date ()
			if _oTrEstq:Grava ()
				u_log2 ('INFO', 'Gravou ZAG. ' + _oTrEstq:UltMsg)
				_sMsgRetWS = _oTrEstq:UltMsg
			else
				u_log2 ('erro', 'Nao gravou ZAG. ' + _oTrEstq:UltMsg)
				_SomaErro ("Erro na gravacao.")
				_sMsgRetWS = _oTrEstq:UltMsg
			endif
		endif
	case _sQueFazer $ 'AUT/DEL/EXE/NEG'  // [A]utorizar;[D]eletar;[E]xecutar;[N]egar
		if empty (_sErroWS) ; _sDocZAG = _ExtraiTag ("_oXML:_WSAlianca:_DocTransf", .T., .F.) ; endif
		if empty (_sErroWS)
			zag -> (dbsetorder (1))  // ZAG_FILIAL+ ZAG_DOC + ZAG_SEQ
			if ! zag -> (dbseek (xfilial ("ZAG") + _sDocZAG, .F.))
				_SomaErro ("Documento '" + _sDocZAG + "' nao localizado na tabela ZAG")
			else
				_oTrEstq := ClsTrEstq ():New (zag -> (recno ()))
				if empty (_oTrEstq:Docto)
					_SomaErro ("Nao foi possivel instanciar objeto _oTrEstq")
				else
					do case
					case _sQueFazer == 'AUT'  // Autorizar
						_oTrEstq:Libera ()
						_oTrEstq:Executa ()  // Tenta executar, pois as liberacoes podem ter tido exito.
						_sMsgRetWS = _oTrEstq:UltMsg
					case _sQueFazer == 'DEL'  // Deletar
						if ! _oTrEstq:Exclui ()
							_SomaErro (_oTrEstq:UltMsg)
						else
							_sMsgRetWS = _oTrEstq:UltMsg
						endif
					case _sQueFazer == 'EXE'  // Executar (pode ter dado erro na tentativa anterior)
						if ! _oTrEstq:Executa (.T.)
							_SomaErro (_oTrEstq:UltMsg)
						else
							_sMsgRetWS = _oTrEstq:UltMsg
						endif
					case _sQueFazer == 'NEG'  // Negar (usuario nao aceitou a transferencia)
						_sMotZAG = _ExtraiTag ("_oXML:_WSAlianca:_Motivo", .T., .F.)
						if empty (_sErroWS)
							if ! _oTrEstq:Negar (_sMotZAG)
								_SomaErro (_oTrEstq:UltMsg)
							else
								_sMsgRetWS = _oTrEstq:UltMsg
							endif
						endif
					case _sQueFazer == 'IED'  // Informar Endereco Destino
						_sNEndDst = _ExtraiTag ("_oXML:_WSAlianca:_NovoEndDest", .T., .F.)
						if empty (_sErroWS)
							if ! _oTrEstq:NovoEndDst (_sNEndDst)
								_SomaErro (_oTrEstq:UltMsg)
							else
								_sMsgRetWS = _oTrEstq:UltMsg
							endif
						endif
					otherwise
						_SomaErro ("Opcao desconhecida na rotina " + procname ())
					endcase
				endif

			endif
		endif
	otherwise
		_SomaErro ("Acao desconhecida na rotina " + procname ())
	endcase
Return


// --------------------------------------------------------------------------
// Interface para inserir solic.transf.estq. com tela 'em grid' (varios itens)
static function _TrEstGrid ()
	local _sFilOrig  := ''
	local _sFilDest  := ''
	local _sOP       := ''
	local _sImprEtq  := ''
	local _nItem     := 0
	local _lTodosOK  := .F.
	local _sRetGrid  := ''
	local _aIdGrid   := {}

	// Algumas tags serao unicas, como se fosse um cabecalho de tela.
	if empty (_sErroWS) ; _sFilOrig = padr (_ExtraiTag ("_oXML:_WSAlianca:_FilialOrigem",    .t., .F.), 2)  ; endif
	if empty (_sErroWS) ; _sFilDest = padr (_ExtraiTag ("_oXML:_WSAlianca:_FilialDestino",   .t., .F.), 2)  ; endif
	if empty (_sErroWS) ; _sOP      = padr (_ExtraiTag ("_oXML:_WSAlianca:_OP",              .f., .F.), 14) ; endif
	if empty (_sErroWS) ; _sImprEtq =       _ExtraiTag ("_oXML:_WSAlianca:_Impressora",      .f., .F.)      ; endif
	if empty (_sErroWS) .and. type ("_oXML:_WSAlianca:_TransfEstqItens") != 'O'
		_SomaErro ("Tag '_oXML:_WSAlianca:_TransfEstqItens' deve estar presente no XML.")
	endif

	// Se eu tiver recebido mais de um item (a tag <item> pode se repetir), o
	// o tipo do objeto vai ser 'array'. Para trabalhar mais adiante com um
	// soh trecho de programa, usarei nomes de objetos _oTrEstq1, _oTrEstq2, ...
	// Tentei trabalhar com uma array e guardar objetos nela, mas comecei a ter
	// problemas de misturar dados entre os objetos. Entao achei melhor criar
	// um objeto para cada item do XML recebido. O acesso a cada objeto fica
	// chato de fazer por que preciso do '&', mas posso criar quantos objetos
	// forem necessarios.
	if type ("_oXML:_WSAlianca:_TransfEstqItens:_Item") == 'A'  // Mais de um item no XML
		if len (_oXML:_WSAlianca:_TransfEstqItens:_Item) > 99
			_SomaErro ("Limite maximo de 99 itens.")  // Na verdade, espero ficar abaixo de 10
		endif
		_nItem = 1
		do while empty (_sErroWS) .and. _nItem <= len (_oXML:_WSAlianca:_TransfEstqItens:_Item)
			U_Log2 ('debug', '[' + procname () + ']Lendo item ' + cvaltochar (_nItem) + ' do XML')
			&('_oTrEstq' + cvaltochar (_nItem)) := ClsTrEstq ():New ()
			&('_oTrEstq' + cvaltochar (_nItem)):FilOrig  = _sFilOrig
			&('_oTrEstq' + cvaltochar (_nItem)):FilDest  = _sFilDest
			&('_oTrEstq' + cvaltochar (_nItem)):OP       = _sOP
			&('_oTrEstq' + cvaltochar (_nItem)):ImprEtq  = _sImprEtq
			&('_oTrEstq' + cvaltochar (_nItem)):UsrIncl  = cUserName
			&('_oTrEstq' + cvaltochar (_nItem)):DtEmis   = date ()
			if empty (_sErroWS) ; &('_oTrEstq' + cvaltochar (_nItem)):IdGrid    =       _ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item[" + cvaltochar (_nItem) + "]:_ItemId",          .T., .F.)      ; endif
			if empty (_sErroWS) ; &('_oTrEstq' + cvaltochar (_nItem)):ProdOrig  = padr (_ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item[" + cvaltochar (_nItem) + "]:_ProdutoOrigem",   .T., .F.), 15) ; endif
			if empty (_sErroWS) ; &('_oTrEstq' + cvaltochar (_nItem)):ProdDest  = padr (_ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item[" + cvaltochar (_nItem) + "]:_ProdutoDestino",  .T., .F.), 15) ; endif
			if empty (_sErroWS) ; &('_oTrEstq' + cvaltochar (_nItem)):AlmOrig   = padr (_ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item[" + cvaltochar (_nItem) + "]:_AlmoxOrigem",     .T., .F.), 2)  ; endif
			if empty (_sErroWS) ; &('_oTrEstq' + cvaltochar (_nItem)):AlmDest   = padr (_ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item[" + cvaltochar (_nItem) + "]:_AlmoxDestino",    .T., .F.), 2)  ; endif
			if empty (_sErroWS) ; &('_oTrEstq' + cvaltochar (_nItem)):LoteOrig  = padr (_ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item[" + cvaltochar (_nItem) + "]:_LoteOrigem",      .F., .F.), 10) ; endif
			if empty (_sErroWS) ; &('_oTrEstq' + cvaltochar (_nItem)):LoteDest  = padr (_ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item[" + cvaltochar (_nItem) + "]:_LoteDestino",     .F., .F.), 10) ; endif
			if empty (_sErroWS) ; &('_oTrEstq' + cvaltochar (_nItem)):EndOrig   = padr (_ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item[" + cvaltochar (_nItem) + "]:_EnderecoOrigem",  .F., .F.), 15) ; endif
			if empty (_sErroWS) ; &('_oTrEstq' + cvaltochar (_nItem)):EndDest   = padr (_ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item[" + cvaltochar (_nItem) + "]:_EnderecoDestino", .F., .F.), 15) ; endif
			if empty (_sErroWS) ; &('_oTrEstq' + cvaltochar (_nItem)):QtdSolic  = Val(StrTran(_ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item[" + cvaltochar (_nItem) + "]:_QtdSolic",  .T., .F.),",","."))      ; endif
			if empty (_sErroWS) ; &('_oTrEstq' + cvaltochar (_nItem)):CodMotivo =       _ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item[" + cvaltochar (_nItem) + "]:_Motivo",          .T., .F.)      ; endif
			if empty (_sErroWS) ; &('_oTrEstq' + cvaltochar (_nItem)):Motivo    =       _ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item[" + cvaltochar (_nItem) + "]:_Obs",             .F., .F.)      ; endif
				_nItem ++
			enddo

	elseif type ("_oXML:_WSAlianca:_TransfEstqItens:_Item") == 'O'  // Um item apenas no XML
		_oTrEstq1 := ClsTrEstq ():New ()
		_oTrEstq1:FilOrig  = _sFilOrig
		_oTrEstq1:FilDest  = _sFilDest
		_oTrEstq1:OP       = _sOP
		_oTrEstq1:ImprEtq  = _sImprEtq
		_oTrEstq1:UsrIncl  = cUserName
		_oTrEstq1:DtEmis   = date ()
		if empty (_sErroWS) ; _oTrEstq1:IdGrid    =       _ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item:_ItemId",          .T., .F.)      ; endif
		if empty (_sErroWS) ; _oTrEstq1:ProdOrig  = padr (_ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item:_ProdutoOrigem",   .T., .F.), 15) ; endif
		if empty (_sErroWS) ; _oTrEstq1:ProdDest  = padr (_ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item:_ProdutoDestino",  .T., .F.), 15) ; endif
		if empty (_sErroWS) ; _oTrEstq1:AlmOrig   = padr (_ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item:_AlmoxOrigem",     .T., .F.), 2)  ; endif
		if empty (_sErroWS) ; _oTrEstq1:AlmDest   = padr (_ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item:_AlmoxDestino",    .T., .F.), 2)  ; endif
		if empty (_sErroWS) ; _oTrEstq1:LoteOrig  = padr (_ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item:_LoteOrigem",      .F., .F.), 10) ; endif
		if empty (_sErroWS) ; _oTrEstq1:LoteDest  = padr (_ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item:_LoteDestino",     .F., .F.), 10) ; endif
		if empty (_sErroWS) ; _oTrEstq1:EndOrig   = padr (_ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item:_EnderecoOrigem",  .F., .F.), 15) ; endif
		if empty (_sErroWS) ; _oTrEstq1:EndDest   = padr (_ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item:_EnderecoDestino", .F., .F.), 15) ; endif
		if empty (_sErroWS) ; _oTrEstq1:QtdSolic  = Val(StrTran(_ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item:_QtdSolic",        .T., .F.),",","."))    ; endif
		if empty (_sErroWS) ; _oTrEstq1:CodMotivo =       _ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item:_Motivo",          .T., .F.)      ; endif
		if empty (_sErroWS) ; _oTrEstq1:Motivo    =       _ExtraiTag ("_oXML:_WSAlianca:_TransfEstqItens:_Item:_Obs",             .F., .F.)      ; endif
	endif

	// Se nao consegui ler as tags do XML, nem adianta prosseguir.
	if empty (_sErroWS)

		// Antes de gravar qualquer coisa, preciso ver se todos os itens podem ser aceitos.
		_lTodosOK = .T.
		_nItem = 1
		//	do while empty (_sErroWS) .and. type ('_oTrEstq' + cvaltochar (_nItem)) == 'O' //valtype (&('_oTrEstq' + cvaltochar (_nItem))) == 'O'
		do while type ('_oTrEstq' + cvaltochar (_nItem)) == 'O'
			if ! &('_oTrEstq' + cvaltochar (_nItem)):PodeIncl ()
				U_Log2 ('aviso', '[' + procname () + ']A solicitacao abaixo (item ' + cvaltochar (_nItem) + ' do XML) nao vai ser aceita:')
				u_logObj (&('_oTrEstq' + cvaltochar (_nItem)), .t., .f.)
				_lTodosOK = .F.
			endif
			_nItem ++
		enddo

		// Prepara variavel para dar retorno de cada item. Como quero dar o retorno
		// para todos os itens, limparei mensagens previas de erro.
		_sErroWS = ''
		_sRetGrid = '<RetornoSolicitacao>'
		_nItem = 1
		do while type ('_oTrEstq' + cvaltochar (_nItem)) == 'O' //valtype (&('_oTrEstq' + cvaltochar (_nItem))) == 'O'
			_sRetGrid += '<Itens>'
			_sRetGrid += '<ItemId>' + &('_oTrEstq' + cvaltochar (_nItem)):IdGrid + '</ItemId>'

			// Situacao que nao deverah ocorrer.
			if ascan (_aIdGrid, &('_oTrEstq' + cvaltochar (_nItem)):IdGrid) > 0
				&('_oTrEstq' + cvaltochar (_nItem)):UltMsg = "Tag ItemID (" + &('_oTrEstq' + cvaltochar (_nItem)):IdGrid + ") ja informada anteriormente."
				_lTodosOK = .F.
			else
				aadd (_aIdGrid, &('_oTrEstq' + cvaltochar (_nItem)):IdGrid)
			endif

			// Se todos estao ok (deverao ser aceitos), jah posso grava-los.
			if _lTodosOK
				if ! &('_oTrEstq' + cvaltochar (_nItem)):Grava ()
					_sRetGrid += "<Retorno>ERRO:" + &('_oTrEstq' + cvaltochar (_nItem)):UltMsg + "</Retorno>"
					U_Log2 ('erro', '[' + procname () + ']Erro ao gravar a solicitacao abaixo (item ' + cvaltochar (_nItem) + ' do XML):')
					u_logObj (&('_oTrEstq' + cvaltochar (_nItem)), .t., .f.)
				else
					//		_sRetGrid += "<Retorno>OK:Gerada solicitacao " + &('_oTrEstq' + cvaltochar (_nItem)):Docto + '/' + &('_oTrEstq' + cvaltochar (_nItem)):Seq + "</Retorno>"
					_sRetGrid += "<Retorno>OK</Retorno>"
			//		U_Log2 ('debug', '[' + procname () + ']Gravei solicitacao ' + cvaltochar (_nItem) + ', que ficou assim:')
					u_logObj (&('_oTrEstq' + cvaltochar (_nItem)), .t., .f.)
				endif
			else  // Vou apenas retornar se os itens seriam ou nao aceitos
				if ! empty (&('_oTrEstq' + cvaltochar (_nItem)):UltMsg)
					_sRetGrid += "<Retorno>ERRO:" + &('_oTrEstq' + cvaltochar (_nItem)):UltMsg + "</Retorno>"
				else
					_sRetGrid += "<Retorno>OK</Retorno>"
				endif
			endif
			_sRetGrid += '</Itens>'
			_nItem ++
		enddo
		_sRetGrid += '</RetornoSolicitacao>'
		_sMsgRetWS = _sRetGrid
	endif
	U_Log2 ('debug', '[' + procname () + ']' + _sMsgRetWS)
return


// --------------------------------------------------------------------------
// Verifica onde determinada string eh usada. Geralmente serve para pesquisar por
// nomes de campos, nicknames de gatilhos, etc.
static function _OndeSeUsa ()
	local _sCampo  := ""

	if empty (_sErroWS)
		_sCampo  = _ExtraiTag ("_oXML:_WSAlianca:_Campo", .T., .F.)
	endif
	if empty (_sErroWS)
		_sMsgRetWS = U_OndeSeUsa (_sCampo)
	endif
Return
//
// --------------------------------------------------------------------------
// Inclui novo produto (cadastro em tela simplificada do NaWeb)
static function _IncProd()
	local _wB1_COD    := ""
	local _wB1_DESC   := ""
	local _wB1_TIPO   := ""
	local _wB1_UM     := ""
	local _wB1_LOCPAD := ""
	local _wB1_GRUPO  := ""
	Local _aProduto := {}

	u_logIni ()

	if empty (_sErroWS)
		_wB1_COD    = _ExtraiTag ("_oXML:_WSAlianca:_B1_COD",    .T., .F.)
		_wB1_DESC   = _ExtraiTag ("_oXML:_WSAlianca:_B1_DESC",   .T., .F.)
		_wB1_TIPO   = _ExtraiTag ("_oXML:_WSAlianca:_B1_TIPO",   .T., .F.)
		_wB1_UM     = _ExtraiTag ("_oXML:_WSAlianca:_B1_UM",     .T., .F.)
		_wB1_LOCPAD = _ExtraiTag ("_oXML:_WSAlianca:_B1_LOCPAD", .T., .F.)
		_wB1_GRUPO  = _ExtraiTag ("_oXML:_WSAlianca:_B1_GRUPO",  .T., .F.)
	endif

	If empty (_sErroWS)

		// Cria variavel para receber possiveis erros da funcao U_Help() e variáveis que são utilizadas nas funções
		private _sErroAuto := ""
		Private oModel := Nil
		Private lMsErroAuto := .F.
		Private aRotina := {}
		Private INCLUI := .T.
		Private ALTERA := .F.

		oModel := FwLoadModel ("MATA010")

		//Adicionando os dados do ExecAuto cab
		aAdd(_aProduto, {"B1_COD" 	 ,_wB1_COD    		 , Nil})
		aAdd(_aProduto, {"B1_DESC"   ,_wB1_DESC   		 , Nil})
		aAdd(_aProduto, {"B1_TIPO"   ,_wB1_TIPO   		 , Nil})
		aAdd(_aProduto, {"B1_UM"     ,_wB1_UM     		 , Nil})
		aAdd(_aProduto, {"B1_LOCPAD" ,_wB1_LOCPAD 		 , Nil})
		aAdd(_aProduto, {"B1_GRUPO"  ,_wB1_GRUPO  		 , Nil})
		aAdd(_aProduto, {"B1_POSIPI" ,"00000000" 		 , Nil})
		aAdd(_aProduto, {"B1_ORIGEM" ,"0" 		  		 , Nil})
		aAdd(_aProduto, {"B1_GRPEMB" ,"00" 		  		 , Nil})
		aAdd(_aProduto, {"B1_CODLIN" ,"00" 		  		 , Nil})
		aAdd(_aProduto, {"B1_VAMARCM" ,"00"	 	  		 , Nil})
		aAdd(_aProduto, {"B1_GARANT" ,"2"	 	  		 , Nil})
		aAdd(_aProduto, {"B1_VARMAAL" ,"00000000000000"	 , Nil})
		aAdd(_aProduto, {"B1_GRTRIB" ,_wB1_TIPO	 	  	 , Nil})

		u_log (_aProduto)
		//Chamando a inclusão - Modelo 1
		lMsErroAuto := .F.

		FWMVCRotAuto(oModel,"SB1",3,{{"SB1MASTER",_aProduto}})

		//Se houve erro no ExecAuto, mostra mensagem
		If lMsErroAuto
			u_log ('Erro na rotina automatica')
			if ! empty (_sErroAuto)
				_SomaErro (_sErroAuto)
			endif
			if ! empty (NomeAutoLog ())
				_SomaErro (U_LeErro (memoread (NomeAutoLog ())))
			endif
		Else
			u_log ('rotina automatica OK')
			_sMsgRetWS = 'Produto criado codigo ' + sb1 -> b1_cod
		endif

	endif
	u_logFim ()
Return Nil
//
// --------------------------------------------------------------------------
// Inclui novo cliente (cadastro em tela simplificada do NaWeb)
static function _IncCli ()
	local _wnome 	:= ""
	local _wtipo 	:= ""
	local _wcgc 	:= ""
	local _wtel 	:= ""
	local _wemail 	:= ""
	local _west 	:= ""
	local _wcidade 	:= ""
	local _wbairro 	:= ""
	local _wend 	:= ""
	local _wcep 	:= ""
	local _wcodmun 	:= ""
	local _wcodmun2 := ""

	u_logIni ()

	if empty (_sErroWS)
		_wNome   = _ExtraiTag ("_oXML:_WSAlianca:_Nome",         .T., .F.)
		_wTipo   = _ExtraiTag ("_oXML:_WSAlianca:_Pessoa",       .T., .F.)
		_wCGC    = _ExtraiTag ("_oXML:_WSAlianca:_CGC",          .T., .F.)
		_wTel    = _ExtraiTag ("_oXML:_WSAlianca:_Tel",          .T., .F.)
		_wEMail  = _ExtraiTag ("_oXML:_WSAlianca:_EMail",        .T., .F.)
		_wEst    = _ExtraiTag ("_oXML:_WSAlianca:_Est",          .T., .F.)
		_wCidade = _ExtraiTag ("_oXML:_WSAlianca:_Cidade",       .T., .F.)
		_wBairro = _ExtraiTag ("_oXML:_WSAlianca:_Bairro",       .T., .F.)
		_wEnd    = _ExtraiTag ("_oXML:_WSAlianca:_End",          .T., .F.)
		_wCEP    = _ExtraiTag ("_oXML:_WSAlianca:_CEP",          .T., .F.)
		_wcodMun = _ExtraiTag ("_oXML:_WSAlianca:_CodMun",       .T., .F.)
		_wcodMun2= _ExtraiTag ("_oXML:_WSAlianca:_CodMun2",      .T., .F.)
		//_wregiao = _ExtraiTag ("_oXML:_WSAlianca:_Regiao",       .T., .F.)
		//_nreduz  = _ExtraiTag ("_oXML:_WSAlianca:_NomeReduzido", .T., .F.)
	endif

	if empty (_sErroWS)
		oModel := FWLoadModel("MATA030")
		oModel:SetOperation(3)
		oModel:Activate()

		//Monta array de dados para inclusao do cadastro.
		oSA1Mod:= oModel:getModel("MATA030_SA1")
		oSA1Mod:SetValue("A1_NOME"		, _wnome 			)
		oSA1Mod:SetValue("A1_PESSOA"	, _wtipo 			)
		oSA1Mod:SetValue("A1_TIPO"		, "F"				)
		oSA1Mod:SetValue("A1_NREDUZ"	, _wnome			)
		oSA1Mod:SetValue("A1_END"		, _wend 			)
		oSA1Mod:SetValue("A1_EST"		, _west				)
		oSA1Mod:SetValue("A1_MUN"		, _wcidade			)
		oSA1Mod:SetValue("A1_COD_MUN"	, _wcodmun			)
		oSA1Mod:SetValue("A1_CMUN"		, _wcodmun2			)
		oSA1Mod:SetValue("A1_BAIRRO"	, _wbairro			)
		oSA1Mod:SetValue("A1_CEP"		, _wcep				)
		oSA1Mod:SetValue("A1_TEL"		, _wtel				)
		oSA1Mod:SetValue("A1_REGIAO"	, "SUL"				)
		oSA1Mod:SetValue("A1_LOJA"		, "01"				)
		oSA1Mod:SetValue("A1_VEND"		, "001"				)
		oSA1Mod:SetValue("A1_MALA"		, "S"				)
		oSA1Mod:SetValue("A1_CGC"		, _wcgc				)
		oSA1Mod:SetValue("A1_BCO1"		, "CX1"				)
		oSA1Mod:SetValue("A1_RISCO"		, "E"				)
		oSA1Mod:SetValue("A1_PAIS"		, "105"				)
		oSA1Mod:SetValue("A1_SATIV1"	, "08.04"			)
		oSA1Mod:SetValue("A1_FORMA"		, "2"				)
		oSA1Mod:SetValue("A1_EMAIL"		, _wemail			)
		oSA1Mod:SetValue("A1_VAMDANF"	, _wemail			)
		oSA1Mod:SetValue("A1_CODPAIS"	, "01058"			)
		oSA1Mod:SetValue("A1_MSBLQL"	, "2"				)
		oSA1Mod:SetValue("A1_SIMPNAC"	, "2"				)
		oSA1Mod:SetValue("A1_VABARAP"	, "0"				)
		oSA1Mod:SetValue("A1_CONTA"		, "101020201001" 	)
		oSA1Mod:SetValue("A1_COND"		, "097" 			)
		oSA1Mod:SetValue("A1_VAUEXPO"	, ddatabase 		)
		oSA1Mod:SetValue("A1_IENCONT"	, "2"				)
		oSA1Mod:SetValue("A1_CONTRIB"	, "2"				)
		oSA1Mod:SetValue("A1_CNAE"		, "0000-0/00"		)
		oSA1Mod:SetValue("A1_GRPTRIB"	, "003"				)
		oSA1Mod:SetValue("A1_FORMA"		, "3"				)
		oSA1Mod:SetValue("A1_LOJAS"		, "S"				)
		oSA1Mod:SetValue("A1_VADTINC"	, date()			)
		oSA1Mod:SetValue("A1_VAEMLF"	, _wemail			)
		oSA1Mod:SetValue("A1_VACGCFI"	, _wcgc				)
		oSA1Mod:SetValue("A1_SAVBLQ"	, 'S'				)

		If oModel:VldData() 	// Tenta realizar o Commit
			If oModel:CommitData()
				u_log('GRAVOU')
			Else
				u_log('NÃO GRAVOU')

				aErro := oModel:GetErrorMessage()

				//Monta o Texto que será mostrado na tela
				u_log("Id do formulário de origem:"  + ' [' + AllToChar(aErro[01]) + ']')
				u_log("Id do campo de origem: "      + ' [' + AllToChar(aErro[02]) + ']')
				u_log("Id do formulário de erro: "   + ' [' + AllToChar(aErro[03]) + ']')
				u_log("Id do campo de erro: "        + ' [' + AllToChar(aErro[04]) + ']')
				u_log("Id do erro: "                 + ' [' + AllToChar(aErro[05]) + ']')
				u_log("Mensagem do erro: "           + ' [' + AllToChar(aErro[06]) + ']')
				u_log("Mensagem da solução: "        + ' [' + AllToChar(aErro[07]) + ']')
				u_log("Valor atribuído: "            + ' [' + AllToChar(aErro[08]) + ']')
				u_log("Valor anterior: "             + ' [' + AllToChar(aErro[09]) + ']')
			endif
		Else 					// Se não conseguir validar as informações, altera a variável para false
			u_log('Erro na rotina automatica')
			aErro := oModel:GetErrorMessage()

			//Monta o Texto que será mostrado na tela
			u_log("Id do formulário de origem:"  + ' [' + AllToChar(aErro[01]) + ']')
			u_log("Id do campo de origem: "      + ' [' + AllToChar(aErro[02]) + ']')
			u_log("Id do formulário de erro: "   + ' [' + AllToChar(aErro[03]) + ']')
			u_log("Id do campo de erro: "        + ' [' + AllToChar(aErro[04]) + ']')
			u_log("Id do erro: "                 + ' [' + AllToChar(aErro[05]) + ']')
			u_log("Mensagem do erro: "           + ' [' + AllToChar(aErro[06]) + ']')
			u_log("Mensagem da solução: "        + ' [' + AllToChar(aErro[07]) + ']')
			u_log("Valor atribuído: "            + ' [' + AllToChar(aErro[08]) + ']')
			u_log("Valor anterior: "             + ' [' + AllToChar(aErro[09]) + ']')
		endif
	endif
	u_logFim ()
return
//
// --------------------------------------------------------------------------
// Altera cliente (cadastro em tela simplificada do NaWeb)
static function _AltCli ()
	local _wnome 	:= ""
	local _wtipo 	:= ""
	local _wcgc 	:= ""
	local _wtel 	:= ""
	local _wemail 	:= ""
	local _west 	:= ""
	local _wcidade 	:= ""
	local _wbairro 	:= ""
	local _wend 	:= ""
	local _wcep 	:= ""
	local _wcodmun 	:= ""
	local _wcodmun2 := ""
	local _wregiao 	:= ""

	if empty (_sErroWS)
		_wNome   = _ExtraiTag ("_oXML:_WSAlianca:_Nome",    .T., .F.)
		_wTipo   = _ExtraiTag ("_oXML:_WSAlianca:_Pessoa",  .T., .F.)
		_wCGC    = _ExtraiTag ("_oXML:_WSAlianca:_CGC",     .T., .F.)
		_wTel    = _ExtraiTag ("_oXML:_WSAlianca:_Tel",     .T., .F.)
		_wEMail  = _ExtraiTag ("_oXML:_WSAlianca:_EMail",   .T., .F.)
		_wEst    = _ExtraiTag ("_oXML:_WSAlianca:_Est",     .T., .F.)
		_wCidade = _ExtraiTag ("_oXML:_WSAlianca:_Cidade",  .T., .F.)
		_wBairro = _ExtraiTag ("_oXML:_WSAlianca:_Bairro",  .T., .F.)
		_wEnd    = _ExtraiTag ("_oXML:_WSAlianca:_End",     .T., .F.)
		_wCEP    = _ExtraiTag ("_oXML:_WSAlianca:_CEP",     .T., .F.)
		_wcodMun = _ExtraiTag ("_oXML:_WSAlianca:_CodMun",  .T., .F.)
		_wcodMun2= _ExtraiTag ("_oXML:_WSAlianca:_CodMun2", .T., .F.)
		_wregiao = _ExtraiTag ("_oXML:_WSAlianca:_Regiao",  .T., .F.)
	endif

	if empty (_sErroWS)
		// busca codigo do cliente pelo CPF
		_wcodcli := fBuscaCpo ('SA1', 3, xfilial('SA1') + _wcgc , "A1_COD")
		// altera os campos na tabela de clientes
		_sSQL := ""
		_sSQL += " UPDATE SA1010"
		_sSQL += "    SET A1_NOME    = '" + _wnome + "'"
		_sSQL += "      , A1_END     = '" + _wend  + "'"
		_sSQL += "      , A1_BAIRRO  = '" + _wbairro + "'"
		_sSQL += "      , A1_EST     = '" + _west + "'"
		_sSQL += "      , A1_CEP     = '" + _wcep + "'"
		_sSQL += "      , A1_MUN     = '" + _wcidade + "'"
		_sSQL += "      , A1_TEL     = '" + _wtel + "'"
		_sSQL += "      , A1_EMAIL   = '" + _wemail + "'"
		_sSQL += "      , A1_COD_MUN = '" + _wcodmun + "'"
		_sSQL += "      , A1_CMUN    = '" + _wcodmun2 + "'"
		_sSQL += "      , A1_REGIAO  = '" + _wregiao + "'"
		_sSQL += "      , A1_NREDUZ  = '" + left(_wnome,20) + "'"
		_sSQL += "  WHERE D_E_L_E_T_ = ''"
		_sSQL += "    AND A1_COD     = '" + _wcodcli  + "'"
		u_log (_sSQL)
		if TCSQLExec (_sSQL) < 0
			_SomaErro ('Nao foi possivel alterar o cadastro')
		else
			u_log ('rotina automatica OK')
			_sMsgRetWS = 'Cliente alterado codigo ' + _wcodcli
		endif
	endif
return
//
// --------------------------------------------------------------------------
// Executa consulta de orcamentos
Static function _ExecConsOrc()
	local _wFilialIni   := ""
	local _wFilialFin   := ""
	local _wAno			:= 0
	local _wDataInicial := ""
	local _wDataFinal   := ""
	local _oSQL      	:= NIL
	local _sAliasQ   	:= ""
	local _XmlRet       := ""
	local _sModelo      := ""
	local _aPerfNA      := {}

	// busca valores de entrada
	if empty (_sErroWS)
		_wFilialIni   = _ExtraiTag ("_oXML:_WSAlianca:_FilialIni"	, .T., .F.)
		_wFilialFin   = _ExtraiTag ("_oXML:_WSAlianca:_FilialFin"	, .T., .F.)
		_wAno         = _ExtraiTag ("_oXML:_WSAlianca:_Ano"			, .T., .F.)
		_wDataInicial = _ExtraiTag ("_oXML:_WSAlianca:_DataInicial"	, .T., .F.)
		_wDataFinal   = _ExtraiTag ("_oXML:_WSAlianca:_DataFinal"	, .T., .F.)
		_sModelo      = _ExtraiTag ("_oXML:_WSAlianca:_Modelo"		, .T., .F.)
	endif
	If empty(_sErroWS) .and. _sModelo == '2020'
		_aPerfNA      = U_SeparaCpo (_ExtraiTag ("_oXML:_WSAlianca:_Perfis", .T., .F.), ',')
		//u_log2 ('debug', 'Perfis deste usuario como recebido no XML:')
		//u_log2 ('debug', _aPerfNA)

		// Complementa 5 posicoes caso necessario
		do while len (_aPerfNA) < 5
			aadd (_aPerfNA, 'null')
		enddo
		//u_log ('Perfis deste usuario ajustados:', _aPerfNA)
	endif
	If empty(_sErroWS)
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery += "with C AS ("
		_oSQL:_sQuery +=  " SELECT ORDEM, DESC_N1, DESC_N2, NIVEL, CONTA, DESCRICAO,"
		_oSQL:_sQuery +=         " SUM (ORC_ANO)    AS ORC_ANO,"
		_oSQL:_sQuery +=         " MAX (ORC_ANO_FP) AS ORC_ANO_FP,"
		_oSQL:_sQuery +=         " SUM (ORC_ANO_AV) AS ORC_ANO_AV,"
		_oSQL:_sQuery +=         " SUM (ORC_PER)    AS ORC_PER,"
		_oSQL:_sQuery +=         " MAX (ORC_PER_FP) AS ORC_PER_FP,"
		_oSQL:_sQuery +=         " SUM (ORC_PER_AV) AS ORC_PER_AV,"
		_oSQL:_sQuery +=         " SUM (REA_MES)    AS REA_MES,"
		_oSQL:_sQuery +=         " MAX (REA_MES_FP) AS REA_MES_FP,"
		_oSQL:_sQuery +=         " SUM (REA_MES_AV) AS REA_MES_AV,"
		_oSQL:_sQuery +=         " SUM (REA_PER)    AS REA_PER,"
		_oSQL:_sQuery +=         " MAX (REA_PER_FP) AS REA_PER_FP,"
		_oSQL:_sQuery +=         " SUM (REA_PER_AV) AS REA_PER_AV,"
		_oSQL:_sQuery +=         " SUM (REA_ANT)    AS REA_ANT,"
		_oSQL:_sQuery +=         " MAX (REA_ANT_FP) AS REA_ANT_FP,"
		_oSQL:_sQuery +=         " SUM (REA_ANT_AV) AS REA_ANT_AV,"
		_oSQL:_sQuery +=         " DESTACAR, FILTRACC"
		_oSQL:_sQuery +=  " FROM VA_FCONS_ORCAMENTO_525 "
		_oSQL:_sQuery +=  " ('" + _wFilialIni + "'"
		_oSQL:_sQuery +=   ",'" + _wFilialFin + "'"
		_oSQL:_sQuery +=   ",'" + _wAno       + "'"
		_oSQL:_sQuery +=   ",'" + substr (_wDataInicial, 5, 2) + "'"
		_oSQL:_sQuery +=   ",'" + substr (_wDataFinal, 5, 2) + "'"
		_oSQL:_sQuery +=   "," + _aPerfNA [1] + "," + _aPerfNA [2] + "," + _aPerfNA [3] + "," + _aPerfNA [4] + "," + _aPerfNA [5] + ")"
		_oSQL:_sQuery += " GROUP BY ORDEM,DESC_N1,DESC_N2,NIVEL,CONTA,DESCRICAO, DESTACAR, FILTRACC"
		_oSQL:_sQuery += ")"
		_oSQL:_sQuery += " SELECT * FROM C"
		_oSQL:_sQuery += " ORDER BY ORDEM, DESC_N1, DESC_N2, 999999999999999 - SUM(REA_PER) OVER (PARTITION BY DESC_N1, DESC_N2), CONTA"
		_oSQL:Log ()
	endif

	If empty(_sErroWS)
		_sAliasQ = _oSQL:Qry2Trb (.F.)
		(_sAliasQ) -> (dbgotop ())

		_XmlRet += "<ConsultaDeOrcamento>"
		_XmlRet += 		"<Ano>" + _wAno + "</Ano>"
		_XmlRet += 		"<DataInicial>"+ _wDataInicial +"</DataInicial>"
		_XmlRet += 		"<DataFinal>"+ _wDataFinal +"</DataFinal>"
		_XmlRet += 		"<Orcamento>"

		Do While ! (_sAliasQ) -> (EOF ()) .and. empty (_sErroWS)
			_XmlRet += 		"<OrcamentoItem>"
			/*
			if _sModelo == '2019'
				_XmlRet += 			"<Ordem>" 		 + IIf(Empty(alltrim((_sAliasQ) -> ordem))			,'-' 		, alltrim((_sAliasQ) -> ordem))			+ "</Ordem>"
				_XmlRet += 			"<DescN1>"		 + IIf(Empty(alltrim((_sAliasQ) -> desc_n1))		,'-' 		, alltrim((_sAliasQ) -> desc_n1))		+ "</DescN1>"
				_XmlRet += 			"<DescN2>"		 + IIf(Empty(alltrim((_sAliasQ) -> desc_n2))		,'-' 		, alltrim((_sAliasQ) -> desc_n2))		+ "</DescN2>"
				_XmlRet += 			"<Conta>"		 + IIf(Empty(alltrim((_sAliasQ) -> conta))			,'0' 		, alltrim((_sAliasQ) -> conta))			+ "</Conta>"
				_XmlRet += 			"<CtiDesc01>"	 + IIf(Empty(alltrim((_sAliasQ) -> descricao))		,'-' 		, alltrim((_sAliasQ) -> descricao))		+ "</CtiDesc01>"
				_XmlRet += 			"<CC>"			 + IIf(Empty(alltrim((_sAliasQ) -> cc))				,'0' 		, alltrim((_sAliasQ) -> cc))			+ "</CC>"
				_XmlRet += 			"<Filial>"		 + IIf(Empty(alltrim((_sAliasQ) -> filial))			,'00'		, alltrim((_sAliasQ) -> filial))		+ "</Filial>"
				_XmlRet += 			"<OrcadoAno>"	 + IIf(Empty(alltrim(str((_sAliasQ) -> orc_ano)))	,'0' 		, alltrim(str((_sAliasQ) -> orc_ano)))	+ "</OrcadoAno>"
				_XmlRet += 			"<Orcado>"		 + IIf(Empty(alltrim(str((_sAliasQ) -> orc)))		,'0' 		, alltrim(str((_sAliasQ) -> orc)))		+ "</Orcado>"
				_XmlRet += 			"<Realizado>"	 + IIf(Empty(alltrim(str((_sAliasQ) -> rea)))		,'0' 		, alltrim(str((_sAliasQ) -> rea)))		+ "</Realizado>"
				_XmlRet += 			"<RealizadoAnt>" + IIf(Empty(alltrim(str((_sAliasQ) -> rea_ant)))   ,'0' 		, alltrim(str((_sAliasQ) -> rea_ant)))	+ "</RealizadoAnt>"
			elseif _sModelo == '2020'
			*/
			_XmlRet += 			"<Ordem>" 			 + IIf(Empty(alltrim((_sAliasQ) -> ordem))				,'-' 	, alltrim((_sAliasQ) -> ordem))				+ "</Ordem>"
			_XmlRet += 			"<DescN1>"			 + IIf(Empty(alltrim((_sAliasQ) -> desc_n1))			,'-' 	, alltrim((_sAliasQ) -> desc_n1))			+ "</DescN1>"
			_XmlRet += 			"<DescN2>"			 + IIf(Empty(alltrim((_sAliasQ) -> desc_n2))			,'-' 	, alltrim((_sAliasQ) -> desc_n2))			+ "</DescN2>"
			_XmlRet += 			"<Conta>"			 + IIf(Empty(alltrim((_sAliasQ) -> conta))				,'0' 	, alltrim((_sAliasQ) -> conta))				+ "</Conta>"
			_XmlRet += 			"<CtiDesc01>"		 + IIf(Empty(alltrim((_sAliasQ) -> descricao))			,'-' 	, alltrim((_sAliasQ) -> descricao))			+ "</CtiDesc01>"
			_XmlRet += 			"<OrcadoAno>"		 + alltrim (Transform (                                                 (_sAliasQ) -> orc_ano,     "999999999999.99")) + "</OrcadoAno>"
			_XmlRet += 			"<OrcadoAnoFP>"		 +                                                                      (_sAliasQ) -> orc_ano_fp                       + "</OrcadoAnoFP>"
			_XmlRet += 			"<OrcadoAnoAV>"		 + alltrim (Transform (iif (abs ((_sAliasQ) -> orc_ano_AV) > 999999, 0, (_sAliasQ) -> orc_ano_AV), "999999999999.99")) + "</OrcadoAnoAV>"  // Trunca para um valor fixo em caso de valores de percentuais exorbitantes.
			_XmlRet += 			"<Orcado>"			 + alltrim (Transform (                                                 (_sAliasQ) -> orc_per,     "999999999999.99")) + "</Orcado>"
			_XmlRet += 			"<OrcadoFP>"		 +                                                                      (_sAliasQ) -> orc_per_fp                       + "</OrcadoFP>"
			_XmlRet += 			"<OrcadoAV>"		 + alltrim (Transform (iif (abs ((_sAliasQ) -> orc_per_AV) > 999999, 0, (_sAliasQ) -> orc_per_AV), "999999999999.99")) + "</OrcadoAV>"  // Trunca para um valor fixo em caso de valores de percentuais exorbitantes.
			_XmlRet += 			"<RealizadoNoMes>"	 + alltrim (Transform (                                                 (_sAliasQ) -> rea_mes,     "999999999999.99")) + "</RealizadoNoMes>"
			_XmlRet += 			"<RealizadoNoMesFP>" +                                                                      (_sAliasQ) -> rea_mes_fp                       + "</RealizadoNoMesFP>"
			_XmlRet += 			"<RealizadoNoMesAV>" + alltrim (Transform (iif (abs ((_sAliasQ) -> rea_mes_AV) > 999999, 0, (_sAliasQ) -> rea_mes_AV), "999999999999.99")) + "</RealizadoNoMesAV>"  // Trunca para um valor fixo em caso de valores de percentuais exorbitantes.
			_XmlRet += 			"<Realizado>"		 + alltrim (Transform (                                                 (_sAliasQ) -> rea_per,     "999999999999.99")) + "</Realizado>"
			_XmlRet += 			"<RealizadoFP>"		 +                                                                      (_sAliasQ) -> rea_per_fp                       + "</RealizadoFP>"
			_XmlRet += 			"<RealizadoAV>"		 + alltrim (Transform (iif (abs ((_sAliasQ) -> rea_per_AV) > 999999, 0, (_sAliasQ) -> rea_per_AV), "999999999999.99")) + "</RealizadoAV>"  // Trunca para um valor fixo em caso de valores de percentuais exorbitantes.
			_XmlRet += 			"<RealizadoAnt>"	 + alltrim (Transform (                                                 (_sAliasQ) -> rea_ant,     "999999999999.99")) + "</RealizadoAnt>"
			_XmlRet += 			"<RealizadoAntFP>"	 +                                                                      (_sAliasQ) -> rea_ant_fp                       + "</RealizadoAntFP>"
			_XmlRet += 			"<RealizadoAntAV>"	 + alltrim (Transform (iif (abs ((_sAliasQ) -> rea_ant_AV) > 999999, 0, (_sAliasQ) -> rea_ant_AV), "999999999999.99")) + "</RealizadoAntAV>"  // Trunca para um valor fixo em caso de valores de percentuais exorbitantes.
			_XmlRet += 			"<Destacar>"		 + (_sAliasQ) -> destacar + "</Destacar>"
			_XmlRet += 			"<FilCC>"			 + alltrim ((_sAliasQ) -> FiltraCC) + "</FilCC>"
			//else
			//	_SomaErro ("Modelo de orcamento '" + _sModelo + "' desconhecido ou sem tratamento na montagem do XML")
			//endif
			_XmlRet += 		"</OrcamentoItem>"

			(_sAliasQ) -> (dbskip ())
		EndDo

		_XmlRet += 		"</Orcamento>"
		_XmlRet += "</ConsultaDeOrcamento>"

		(_sAliasQ) -> (dbclosearea ())

		_sMsgRetWS := _XmlRet
	endif
//	u_logFim ()
Return


// --------------------------------------------------------------------------
// Inclusao de cargas de recebimento de uva durante a safra.
static function _IncCarSaf ()
	local _oAssoc    := NIL
	local _sSafra    := ''
	local _sBalanca  := ''
	local _sAssoc    := ''
	local _sLoja     := ''
	local _sSerieNF  := ''
	local _sNumNF    := ''
	local _sChvNfPe  := ''
	local _sPlacaVei := ''
	local _sObs      := ''
	local _sCadVit   := ''
	local _sVaried   := ''
	local _sEmbalag  := ''
	local _sTombador := ''
	local _aItensCar := {}
	local _sLote     := ''
	local _sSenhaOrd := ''
	local _sCPFCarg  := ''
	local _sInscCarg := ''
	local _oSQL      := NIL
	local _aRegSA2   := {}
	local _sSivibe   := ''
	local _sEspumant := ''
	local _sCargaC1  := ''
	local _sCargaC2  := ''
	local _sCompart  := ''
	local _lAmostra  := .F.

	u_log2 ('info', 'Iniciando web service de geracao de carga.')
//	U_PerfMon ('I', 'WSGerarCargaSafra')  // Para metricas de performance

	if empty (_sErroWS) ; _sSafra    = _ExtraiTag ("_oXML:_WSAlianca:_Safra",                  .T., .F.) ; endif
	if empty (_sErroWS) ; _sBalanca  = _ExtraiTag ("_oXML:_WSAlianca:_Balanca",                .T., .F.) ; endif
	if empty (_sErroWS) ; _sAssoc    = _ExtraiTag ("_oXML:_WSAlianca:_Associado",              .F., .F.) ; endif
	if empty (_sErroWS) ; _sLoja     = _ExtraiTag ("_oXML:_WSAlianca:_Loja",                   .F., .F.) ; endif
	if empty (_sErroWS) ; _sCPFCarg  = _ExtraiTag ("_oXML:_WSAlianca:_CPF",                    .F., .F.) ; endif
	if empty (_sErroWS) ; _sInscCarg = _ExtraiTag ("_oXML:_WSAlianca:_IE",                     .F., .F.) ; endif
	if empty (_sErroWS) ; _sSerieNF  = _ExtraiTag ("_oXML:_WSAlianca:_SerieNFProdutor",        .T., .F.) ; endif
	if empty (_sErroWS) ; _sNumNF    = _ExtraiTag ("_oXML:_WSAlianca:_NumeroNFProdutor",       .T., .F.) ; endif
	if empty (_sErroWS) ; _sChvNFPe  = _ExtraiTag ("_oXML:_WSAlianca:_ChaveNFPe",              .F., .F.) ; endif
	if empty (_sErroWS) ; _sTombador = _ExtraiTag ("_oXML:_WSAlianca:_Tombador",               .T., .F.) ; endif
	if empty (_sErroWS) ; _sPlacaVei = _ExtraiTag ("_oXML:_WSAlianca:_PlacaVeiculo",           .T., .F.) ; endif
	if empty (_sErroWS) ; _lAmostra  = (upper (_ExtraiTag ("_oXML:_WSAlianca:_ColetarAmostra", .T., .F.)) == 'S') ; endif
	if empty (_sErroWS) ; _sObs      = _ExtraiTag ("_oXML:_WSAlianca:_Obs",                    .F., .F.) ; endif
	if empty (_sErroWS) ; _sSenhaOrd = _ExtraiTag ("_oXML:_WSAlianca:_Senha",                  .F., .F.) ; endif
	if empty (_sErroWS) ; _sCargaC1  = _ExtraiTag ("_oXML:_WSAlianca:_CargaCompartilhada1",    .f., .F.) ; endif
	if empty (_sErroWS) ; _sCargaC2  = _ExtraiTag ("_oXML:_WSAlianca:_CargaCompartilhada2",    .f., .F.) ; endif

	// A partir de 2021 o app de safra manda tambem CPF e inscricao, para os casos em que foi gerado 'lote de entrega'
	// pelo caderno de campo, e lah identifica apenas o grupo familiar. A inscricao e o CPF serao conhecidos somente
	// no momento em que o associado chegar aqui com o talao de produtor.
	if empty (_sErroWS)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT A2_COD, A2_LOJA"
		_oSQL:_sQuery += " FROM " + RetSQLName ("SA2") + " SA2 "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND A2_FILIAL = '" + xfilial ("SA2") + "'"
		if ! empty (_sAssoc)
			_oSQL:_sQuery += " AND A2_COD    = '" + _sAssoc + "'"
		endif
		if ! empty (_sLoja)
			_oSQL:_sQuery += " AND A2_LOJA   = '" + _sLoja + "'"
		endif
		if ! empty (_sCPFCarg)
			_oSQL:_sQuery += " AND A2_CGC   = '" + _sCPFCarg + "'"
		endif
		if ! empty (_sInscCarg)
			_oSQL:_sQuery += " AND A2_INSCR = '" + _sInscCarg + "'"
		endif
		_oSQL:Log ()
		_aRegSA2 = aclone (_oSQL:Qry2Array (.F., .F.))
		if len (_aRegSA2) == 0
			_SomaErro ("Nao foi localizado nenhum fornecedor pelos parametros informados (cod/loja/CPF/IE)")
		elseif len (_aRegSA2) > 1
			_SomaErro ("Foi localizado MAIS DE UM fornecedor pelos parametros informados (cod/loja/CPF/IE)")
		else
			_oAssoc := ClsAssoc ():New (_aRegSA2 [1, 1], _aRegSA2 [1, 2])
			if valtype (_oAssoc) != 'O'
				_SomaErro ("Impossivel instanciar objeto ClsAssoc. Verifique codigo e loja informados " + _sErroAuto)
			endif
		endif
	endif

	// Leitura dos itens de forma repetitiva (tentei ler em array mas nao funcionou e tenho pouco tempo pra ficar testando...)
	if empty (_sErroWS) ; _sCadVit   = strzero (val (_ExtraiTag ("_oXML:_WSAlianca:_cadastroViticola1", .T., .F.)), 5) ; endif
	if empty (_sErroWS) ; _sVaried   = _ExtraiTag ("_oXML:_WSAlianca:_variedade1",        .T., .F.) ; endif
	if empty (_sErroWS) ; _sEmbalag  = _ExtraiTag ("_oXML:_WSAlianca:_Embalagem1",        .F., .F.) ; endif
	if empty (_sErroWS) ; _sLote     = _ExtraiTag ("_oXML:_WSAlianca:_Lote1",             .F., .F.) ; endif
	if empty (_sErroWS) ; _sSivibe   = _ExtraiTag ("_oXML:_WSAlianca:_Sivibe1",           .F., .F.) ; endif
	if empty (_sErroWS) ; _sEspumant = _ExtraiTag ("_oXML:_WSAlianca:_Espumante1",        .F., .F.) ; endif
	if empty (_sErroWS)
		aadd (_aItensCar, {_sCadVit, _sVaried, _sEmbalag, _sLote, _sSivibe, _sEspumant})
	endif
	//
	if empty (_sErroWS) ; _sCadVit   = strzero (val (_ExtraiTag ("_oXML:_WSAlianca:_cadastroViticola2", .F., .F.)), 5) ; endif
	if empty (_sErroWS) ; _sVaried   = _ExtraiTag ("_oXML:_WSAlianca:_variedade2",        .F., .F.) ; endif
	if empty (_sErroWS) ; _sEmbalag  = _ExtraiTag ("_oXML:_WSAlianca:_Embalagem2",        .F., .F.) ; endif
	if empty (_sErroWS) ; _sLote     = _ExtraiTag ("_oXML:_WSAlianca:_Lote2",             .F., .F.) ; endif
	if empty (_sErroWS) ; _sSivibe   = _ExtraiTag ("_oXML:_WSAlianca:_Sivibe2",           .F., .F.) ; endif
	if empty (_sErroWS) ; _sEspumant = _ExtraiTag ("_oXML:_WSAlianca:_Espumante2",        .F., .F.) ; endif
	if empty (_sErroWS) .and. ! empty (_sVaried) .and. ! empty (_sCadVit)  // Pode nao ter 2 itens na carga
		aadd (_aItensCar, {_sCadVit, _sVaried, _sEmbalag, _sLote, _sSivibe, _sEspumant})
	endif
	//
	if empty (_sErroWS) ; _sCadVit   = strzero (val (_ExtraiTag ("_oXML:_WSAlianca:_cadastroViticola3", .F., .F.)), 5) ; endif
	if empty (_sErroWS) ; _sVaried   = _ExtraiTag ("_oXML:_WSAlianca:_variedade3",        .F., .F.) ; endif
	if empty (_sErroWS) ; _sEmbalag  = _ExtraiTag ("_oXML:_WSAlianca:_Embalagem3",        .F., .F.) ; endif
	if empty (_sErroWS) ; _sLote     = _ExtraiTag ("_oXML:_WSAlianca:_Lote3",             .F., .F.) ; endif
	if empty (_sErroWS) ; _sSivibe   = _ExtraiTag ("_oXML:_WSAlianca:_Sivibe3",           .F., .F.) ; endif
	if empty (_sErroWS) ; _sEspumant = _ExtraiTag ("_oXML:_WSAlianca:_Espumante2",        .F., .F.) ; endif
	if empty (_sErroWS) .and. ! empty (_sVaried) .and. ! empty (_sCadVit)  // Pode nao ter 3 itens na carga
		aadd (_aItensCar, {_sCadVit, _sVaried, _sEmbalag, _sLote, _sSivibe, _sEspumant})
	endif
	//u_log2 ('info', 'Itens da carga:')
	//u_log2 ('info', _aItensCar)
	if empty (_sErroWS)
		if len (_aItensCar) == 0
			_SomaErro ("Nenhum item informado para gerar carga.")
		else
			_sCompart = _sCargaC1 + iif (! empty (_sCargaC2), '/', '') + _sCargaC2
			U_GeraSZE (_oAssoc,_sSafra,_sBalanca,_sSerieNF,_sNumNF,_sChvNfPe,_sPlacaVei,_sTombador,_sObs,_aItensCar, _lAmostra, _sSenhaOrd, NIL, _sCompart)
		endif
	endif

	u_log2 ('info', 'Finalizando web service de geracao de carga.')
Return


// --------------------------------------------------------------------------
// Cancelamento de cargas de recebimento de uva durante a safra.
static function _CanCarSaf ()
	local _sSafra    := ''
	local _sCarga    := ''
	private _sMotCanWS := ''  // Deixar PRIVATE para ser vista pelo programa de gravacao do cancelamento.
	private _ZFEMBALAG    := 'GRANEL'  // Deixar private para ser vista por outras rotinas.

	u_log2 ('info', 'Iniciando web service de cancelamento de carga de safra.')

	if empty (_sErroWS) ; _sSafra    = _ExtraiTag ("_oXML:_WSAlianca:_Safra",  .T., .F.) ; endif
	if empty (_sErroWS) ; _sCarga    = _ExtraiTag ("_oXML:_WSAlianca:_Carga",  .T., .F.) ; endif
	if empty (_sErroWS) ; _sMotCanWS = _ExtraiTag ("_oXML:_WSAlianca:_MotivoCancCarga", .T., .F.) ; endif
	if empty (_sErroWS)
		sze -> (dbsetorder (1))  // ZE_FILIAL, ZE_SAFRA, ZE_CARGA, R_E_C_N_O_, D_E_L_E_T_
		if ! sze -> (dbseek (xfilial ("SZE") + _sSafra + _sCarga, .F.))
			_SomaErro ("Carga '" + _sCarga + "' nao encontrada para a safra '" + _sSafra + "' na filial '" + xfilial ("SZE") + "'.")
		else
			U_VA_RUS2 (5, .F.)
		endif
	endif
return


// --------------------------------------------------------------------------
// Envia ticket carga safra para a impressora (intencao usar quando necessario reimpressao)
static function _ITkCarSaf ()
	local _sSafra    := ''
	local _sCarga    := ''

	if empty (_sErroWS) ; _sSafra = _ExtraiTag ("_oXML:_WSAlianca:_Safra", .T., .F.) ; endif
	if empty (_sErroWS) ; _sCarga = _ExtraiTag ("_oXML:_WSAlianca:_Carga", .T., .F.) ; endif
	if empty (_sErroWS)
		sze -> (dbsetorder (1))  // ZE_FILIAL+ZE_SAFRA+ZE_CARGA
		if ! sze -> (dbseek (xfilial ("SZE") + _sSafra + _sCarga, .F.))
			_SomaErro ('Carga ' + sze -> ze_carga + ' nao localizada na filial ' + cFilAnt + ' / safra ' + _sSafra + '.')
		endif
		if empty (_sErroWS) .and. sze -> ze_status = 'C'
			_SomaErro ('Carga ' + sze -> ze_carga + ' cancelada.')
		endif
		if empty (_sErroWS)
			// A partir de 2023 estou comecando a migrar as cargas de safra para orientacao a objeto.
			if type ("_oCarSaf") != 'O'
				private _oCarSaf  := ClsCarSaf ():New (sze -> (recno ()))
			endif
			if empty (_oCarSaf:Carga)
				u_help ("Impossivel instanciar carga (ou carga invalida recebida).",, .t.)
				_SomaErro ('Objeto CARGA SAFRA invalido.')
			endif
		endif
	endif

	if empty (_sErroWS)

		// Define impressora de ticket e alimenta as respectivas variaveis (que jah devem ter escopo PRIVATE).
		_oCarSaf:DefImprTk ()
		if _oCarSaf:ImprimeTk (1)

			_sMsgRetWS += 'Ticket enviado para ' + _oCarSaf:PortImpTk
		endif
	endif
return


// --------------------------------------------------------------------------
// Executa consulta de Kardex
Static function _ExecKardex()
	local _wFilial   	:= ""
	local _wProduto		:= ""
	local _wAlmox 		:= ""
	local _wDataInicial := ""
	local _wDataFinal   := ""
	local _oSQL      	:= NIL
	local _sAliasQ   	:= ""
	local _XmlRet       := ""

	// busca valores de entrada
	if empty (_sErroWS)
		_wFilial      = 	_ExtraiTag ("_oXML:_WSAlianca:_Filial"		, .T., .F.)
		_wProduto     =     _ExtraiTag ("_oXML:_WSAlianca:_Produto"		, .T., .F.)
		_wAlmox    	  =     _ExtraiTag ("_oXML:_WSAlianca:_Almox"		, .T., .F.)
		_wDataInicial = 	_ExtraiTag ("_oXML:_WSAlianca:_DataInicial"	, .T., .F.)
		_wDataFinal   = 	_ExtraiTag ("_oXML:_WSAlianca:_DataFinal"	, .T., .F.)
	endif

	if empty(_wFilial)		; _SomaErro ("Campo <filial> não preenchido")       ;endif
	if empty(_wProduto)		; _SomaErro ("Campo <produto> não preenchido")      ;endif
	if empty(_wAlmox)		; _SomaErro ("Campo <almoxarifado> não preenchido") ;endif
	if empty(_wDataInicial)	; _SomaErro ("Campo <data inicial> não preenchido") ;endif
	if empty(_wDataFinal)	; _SomaErro ("Campo <data final> não preenchido")	;endif

	if empty(_sErroWS)
		// Faz um teste inicial para verificar se pode gerar muitos registros,
		// pois tinhamos usuarios listando 100 anos de movimentacao!
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT count (*)"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD3")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND D3_FILIAL = '" + _wFilial + "'"
		_oSQL:_sQuery += " AND D3_COD    = '" + _wProduto + "'"
		_oSQL:_sQuery += " AND D3_LOCAL  = '" + _wAlmox + "'"
		_oSQL:_sQuery += " AND D3_EMISSAO BETWEEN '" + _wDataInicial + "' AND '" + _wDataFinal + "'"
	//	_oSQL:Log ('[' + procname () + ']')
		if _osql:RetQry (1, .f.) > 2000
			_sErroWS := "Este item possui muita movimentacao. Selecione um periodo menor!"
		endif
	endif

	if empty(_sErroWS)
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT *"
		_oSQL:_sQuery +=  " FROM dbo.VA_FKARDEX('" + _wFilial + "', '" + _wProduto + "', '" + _wAlmox + "', '" + _wDataInicial + "', '" + _wDataFinal + "') "
		_oSQL:Log ('[' + procname () + ']')
		_sAliasQ = _oSQL:Qry2Trb (.F.)
		(_sAliasQ) -> (dbgotop ())

		_XmlRet += "<ConsultaKardex>"
		_XmlRet += 		"<DataInicial>"+ _wDataInicial +"</DataInicial>"
		_XmlRet += 		"<DataFinal>"+ _wDataFinal +"</DataFinal>"
		_XmlRet += 		"<Registro>"

		While (_sAliasQ)->(!Eof())
			_sNome := StrTran((_sAliasQ) -> Nome , '&', '' )
			_XmlRet += "<RegistroItem>"

			_XmlRet += 		"<Linha>" 		  + alltrim(str((_sAliasQ) -> Linha))														+ "</Linha>"
			_XmlRet += 		"<Data>"		  + IIf((alltrim((_sAliasQ) -> data))=='//'	,'', alltrim((_sAliasQ) -> data)) 				+ "</Data>"
			_XmlRet += 		"<Doc>"		 	  + alltrim((_sAliasQ) -> Doc)																+ "</Doc>"
			_XmlRet += 		"<Serie>"		  + alltrim((_sAliasQ) -> Serie)															+ "</Serie>"
			_XmlRet += 		"<Qt_Entrada>"	  + alltrim(str((_sAliasQ) -> Qt_Entrada))													+ "</Qt_Entrada>"
			_XmlRet += 		"<Qt_Saida>"	  + alltrim(str((_sAliasQ) -> Qt_Saida))													+ "</Qt_Saida>"
			_XmlRet += 		"<Saldo>"		  + alltrim(str((_sAliasQ) -> Saldo))														+ "</Saldo>"
			_XmlRet += 		"<NumSeq>"	 	  + alltrim((_sAliasQ) -> NumSeq)															+ "</NumSeq>"
			_XmlRet += 		"<Movimento>"	  + alltrim((_sAliasQ) -> Movimento)														+ "</Movimento>"
			_XmlRet += 		"<OP>"	 		  + alltrim((_sAliasQ) -> OP)																+ "</OP>"
			_XmlRet += 		"<TES>" 		  + alltrim((_sAliasQ) -> TES)																+ "</TES>"
			_XmlRet += 		"<CFOP>" 		  + alltrim((_sAliasQ) -> CFOP)																+ "</CFOP>"
			_XmlRet += 		"<Lote>" 		  + alltrim((_sAliasQ) -> Lote)																+ "</Lote>"
			_XmlRet += 		"<Etiqueta>" 	  + alltrim((_sAliasQ) -> Etiqueta)															+ "</Etiqueta>"
			_XmlRet += 		"<Usuario>" 	  + alltrim((_sAliasQ) -> Usuario)															+ "</Usuario>"
			_XmlRet += 		"<CliFor>" 		  + alltrim((_sAliasQ) -> CliFor)															+ "</CliFor>"
			_XmlRet += 		"<Loja>" 		  + alltrim((_sAliasQ) -> Loja)																+ "</Loja>"
			_XmlRet += 		"<Nome>" 		  + alltrim (_sNome)																		+ "</Nome>"
			_XmlRet += 		"<Motivo>" 		  + alltrim((_sAliasQ) -> Motivo)															+ "</Motivo>"
			_XmlRet += 		"<Nf_Orig>" 	  + alltrim((_sAliasQ) -> Nf_Orig)															+ "</Nf_Orig>"
			_XmlRet += 		"<Data_Inclusao>" + IIf((alltrim((_sAliasQ)->Data_Inclusao))=='//' ,'', alltrim((_sAliasQ)->Data_Inclusao)) + "</Data_Inclusao>"
			_XmlRet += 		"<Hora_Inclusao>" + alltrim((_sAliasQ) -> Hora_Inclusao)													+ "</Hora_Inclusao>"
			_XmlRet += 		"<Sequencia>" 	  + alltrim((_sAliasQ) -> Sequencia)														+ "</Sequencia>"
			_XmlRet += 		"</RegistroItem>"

			(_sAliasQ) -> (dbskip ())
		EndDo

		_XmlRet += 		"</Registro>"
		_XmlRet += "</ConsultaKardex>"

		(_sAliasQ) -> (dbclosearea ())

		_sMsgRetWS := _XmlRet
	endif
Return


// --------------------------------------------------------------------------
// Executa consulta de Kardex por lote
Static function _KardexLt()
	local _wFilial   	:= ""
	local _wProduto		:= ""
	local _sLote		:= ""
	local _wDataInicial := ""
	local _wDataFinal   := ""
	local _oSQL      	:= NIL
	local _sAliasQ   	:= ""
	local _XmlRet       := ""

	// busca valores de entrada
	if empty (_sErroWS)
		_wFilial      = 	_ExtraiTag ("_oXML:_WSAlianca:_Filial"		, .T., .F.)
		_wProduto     =     _ExtraiTag ("_oXML:_WSAlianca:_Produto"		, .T., .F.)
		_sLote   	  =     _ExtraiTag ("_oXML:_WSAlianca:_Lote"		, .T., .F.)
		_wDataInicial = 	_ExtraiTag ("_oXML:_WSAlianca:_DataInicial"	, .T., .T.)
		_wDataFinal   = 	_ExtraiTag ("_oXML:_WSAlianca:_DataFinal"	, .T., .T.)
	endif

	If empty(_sErroWS)

		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT * FROM dbo.VA_FKARDEX_LOTE('" + _wFilial + "', '" + _wProduto + "', '" + _sLote + "', '" + _wDataInicial + "', '" + _wDataFinal + "') "
		_oSQL:Log ()
		_sAliasQ = _oSQL:Qry2Trb (.F.)
		(_sAliasQ) -> (dbgotop ())

		_XmlRet += "<ConsultaKardexLote>"
		_XmlRet += 		"<DataInicial>"+ _wDataInicial +"</DataInicial>"
		_XmlRet += 		"<DataFinal>"+ _wDataFinal +"</DataFinal>"
		_XmlRet += 		"<Registro>"

		While (_sAliasQ)->(!Eof())
			_sNome := StrTran((_sAliasQ) -> Nome , '&', '' )
			_XmlRet += "<RegistroItem>"

			_XmlRet += 		"<Linha>" 		  + alltrim(str((_sAliasQ) -> Linha))														+ "</Linha>" 			//+ chr (13) + chr (10)
			_XmlRet += 		"<Data>"		  + IIf((alltrim((_sAliasQ) -> data))=='//'	,'', alltrim((_sAliasQ) -> data)) 				+ "</Data>"				//+ chr (13) + chr (10)
			_XmlRet += 		"<Doc>"		 	  + alltrim((_sAliasQ) -> Doc)																+ "</Doc>"				//+ chr (13) + chr (10)
			_XmlRet += 		"<Serie>"		  + alltrim((_sAliasQ) -> SerieNF)															+ "</Serie>"			//+ chr (13) + chr (10)
			_XmlRet += 		"<Qt_Entrada>"	  + alltrim(str((_sAliasQ) -> Qt_Entrada))													+ "</Qt_Entrada>"		//+ chr (13) + chr (10)
			_XmlRet += 		"<Qt_Saida>"	  + alltrim(str((_sAliasQ) -> Qt_Saida))													+ "</Qt_Saida>"			//+ chr (13) + chr (10)
			_XmlRet += 		"<Saldo>"		  + alltrim(str((_sAliasQ) -> Saldo))														+ "</Saldo>"			//+ chr (13) + chr (10)
			_XmlRet += 		"<NumSeq>"	 	  + alltrim((_sAliasQ) -> NumSeq)															+ "</NumSeq>"			//+ chr (13) + chr (10)
			_XmlRet += 		"<Movimento>"	  + alltrim((_sAliasQ) -> Movimento)														+ "</Movimento>"		//+ chr (13) + chr (10)
			_XmlRet += 		"<OP>"	 		  + alltrim((_sAliasQ) -> OP)																+ "</OP>"				//+ chr (13) + chr (10)
			_XmlRet += 		"<TES>" 		  + alltrim((_sAliasQ) -> TES)																+ "</TES>"				//+ chr (13) + chr (10)
			_XmlRet += 		"<CFOP>" 		  + alltrim((_sAliasQ) -> CFOP)																+ "</CFOP>"				//+ chr (13) + chr (10)
			_XmlRet += 		"<Almox>" 		  + alltrim((_sAliasQ) -> Almox)															+ "</Almox>"
			_XmlRet += 		"<Endereco>" 	  + alltrim((_sAliasQ) -> Endereco)															+ "</Endereco>"
			_XmlRet += 		"<Etiqueta>" 	  + alltrim((_sAliasQ) -> Etiqueta)															+ "</Etiqueta>"			//+ chr (13) + chr (10)
			_XmlRet += 		"<Usuario>" 	  + alltrim((_sAliasQ) -> Usuario)															+ "</Usuario>"			//+ chr (13) + chr (10)
			_XmlRet += 		"<CliFor>" 		  + alltrim((_sAliasQ) -> CliFor)															+ "</CliFor>"			//+ chr (13) + chr (10)
			_XmlRet += 		"<Loja>" 		  + alltrim((_sAliasQ) -> Loja)																+ "</Loja>"				//+ chr (13) + chr (10)
			_XmlRet += 		"<Nome>" 		  + alltrim (_sNome)																		+ "</Nome>"				//+ chr (13) + chr (10)
			_XmlRet += 		"<Motivo>" 		  + alltrim((_sAliasQ) -> Motivo)															+ "</Motivo>"			//+ chr (13) + chr (10)
			_XmlRet += 		"<Nf_Orig>" 	  + alltrim((_sAliasQ) -> Nf_Orig)															+ "</Nf_Orig>"			//+ chr (13) + chr (10)
			_XmlRet += 		"<LoteFor>" 	  + alltrim((_sAliasQ) -> Lote_Fornecedor)													+ "</LoteFor>"			//+ chr (13) + chr (10)
			_XmlRet += 		"<Data_Inclusao>" + IIf((alltrim((_sAliasQ)->Data_Inclusao))=='//' ,'', alltrim((_sAliasQ)->Data_Inclusao)) + "</Data_Inclusao>"	//+ chr (13) + chr (10)
			_XmlRet += 		"<Hora_Inclusao>" + alltrim((_sAliasQ) -> Hora_Inclusao)													+ "</Hora_Inclusao>"	//+ chr (13) + chr (10)
			_XmlRet += 		"<Sequencia>" 	  + alltrim((_sAliasQ) -> Sequencia)														+ "</Sequencia>"		//+ chr (13) + chr (10)
			_XmlRet += 		"</RegistroItem>"

			(_sAliasQ) -> (dbskip ())
		EndDo

		_XmlRet += 		"</Registro>" 	//+ chr (13) + chr (10)
		_XmlRet += "</ConsultaKardexLote>" 	//+ chr (13) + chr (10)

		(_sAliasQ) -> (dbclosearea ())

		_sMsgRetWS := _XmlRet
	endif
Return


//
// -------------------------------------------------------------------------------------------------
// Associados - retorna texto do capital social
Static Function _ExecCapAssoc ()
	Local   _sAssoc    := ""
	Local   _sLoja     := ""
	Local   _sRet      := ''
	Private _sErroAuto := ""  // Variavel alimentada pela funcao U_Help

	//u_logIni ()

	if empty (_sErroWS) ; _sAssoc = _ExtraiTag ("_oXML:_WSAlianca:_Assoc", .T., .F.) ; endif
		if empty (_sErroWS) ; _sLoja  = _ExtraiTag ("_oXML:_WSAlianca:_Loja", .T., .F.)  ; endif

			if empty (_sErroWS)
				_oAssoc := ClsAssoc ():New (_sAssoc, _sLoja)
				if valtype (_oAssoc) != 'O'
					_SomaErro ("Impossivel instanciar objeto ClsAssoc. Verifique codigo e loja informados " + _sErroAuto)
				endif
			endif

			if empty (_sErroWS)
				_sRet = _oAssoc:SldQuotCap (dDataBase, .T.) [.QtCapRetTXT]

				if empty (_sRet)
					_SomaErro ("Retorno invalido metodo SldQuotCap " + _oAssoc:UltMsg)
				else
					_sMsgRetWS = _sRet
				endif
			endif
			//u_logFim ()
			Return _sMsgRetWS
//
// --------------------------------------------------------------------------
// Grava agendamento de entrega de faturamento.
Static function _AgEntFat ()
	local _sNF      := ''
	local _sSerie   := ''
	local _dDtAgend := ctod ('')

	if empty (_sErroWS) ; _sNF      = _ExtraiTag ("_oXML:_WSAlianca:_NF", .T., .F.) ; endif
		if empty (_sErroWS) ; _sSerie   = _ExtraiTag ("_oXML:_WSAlianca:_Serie", .T., .F.) ; endif
			if empty (_sErroWS) ; _dDtAgend = stod (_ExtraiTag ("_oXML:_WSAlianca:_DtAgend", .T., .T.)) ; endif
				if empty (_sErroWS)
					sf2 -> (dbsetorder (1))
					if ! sf2 -> (dbseek (xfilial ("SF2") + _sNf + _sSerie, .F.))
						_SomaErro ("NF/serie " + _sNF + '/' + _sSerie + ' de saida nao localizada.')
					else
						reclock ("SF2", .F.)
						sf2 -> f2_vadagen = _dDtAgend
						msunlock ()
						_sMsgRetWS = 'Registro atualizado.'
					endif
				endif
				return
//
// --------------------------------------------------------------------------
// Gera apontamento de producao.
static function _ApontProd ()
	local _sEtqApont := ''
	local _dDtProd   := ctod ('')
	local _sTnoProd  := ''
	local _aAutoSD3  := {}
	local _sMotProd  := ''
	local _sSeqEtiq  := ''
	local _lEtiqOK   := .T.
	local _sMsgEtiq  := ''

	if empty (_sErroWS) ; _sTnoProd  = _ExtraiTag ("_oXML:_WSAlianca:_Turno", .T., .F.) ; endif
		if empty (_sErroWS) ; _dDtProd   = stod (_ExtraiTag ("_oXML:_WSAlianca:_DtProd", .T., .T.)) ; endif
			if empty (_sErroWS) ; _sMotProd  = _ExtraiTag ("_oXML:_WSAlianca:_Motivo", .F., .F.) ; endif

				_sMsgRetWS += '<ApontaProd>'

				// Loop de repeticao para o caso de haver mais de uma OP ou mais de uma etiqueta.
				_sSeqEtiq = '01'
				do while _sSeqEtiq <= '99'  // Mais que isso jah tah de brincadeira, neh ?
					U_Log2 ('debug', 'Iniciando com _sSeqEtiq = ' + _sSeqEtiq)
					_lEtiqOK  = .T.
					_sMsgEtiq = ''
					if empty (_sErroWS)
						_sEtqApont = _ExtraiTag ("_oXML:_WSAlianca:_Etiq" + _sSeqEtiq, .F., .F.)
					endif
					U_Log2 ('debug', '_sEtqApont = ' + _sEtqApont)
					if empty (_sErroWS) .and. empty (_sEtqApont)
						// Se eu ainda estava na primeira etiqueta e a tag encontra-se vazia, eh por que nao veio nenhuma etiqueta.
						if _sSeqEtiq == '01'
							_SomaErro ("Nao foi informado nenhum numero de etiqueta.")
							exit
						else
							// Jah processei todas as etiquetas e posso sair do loop
							U_Log2 ('debug', 'Jah processei todas as etiquetas e posso sair do loop')
							exit
						endif
					endif

					// Validacoes etiqueta.
					if empty (_sErroWS) .and. ! empty (_sEtqApont)
						za1 -> (dbsetorder (1))  // ZA1_FILIAL, ZA1_CODIGO, R_E_C_N_O_, D_E_L_E_T_
						if ! za1 -> (dbseek (xfilial ("ZA1") + _sEtqApont, .F.))
							_sMsgEtiq += "Etiqueta '" + _sEtqApont + "' nao encontrada."
							_lEtiqOK = .F.
						else
							if za1 -> za1_apont == 'S'
								_sMsgEtiq += "Etiqueta '" + _sEtqApont + "' ja gerou apontamento de producao."
								_lEtiqOK = .F.
							endif
							if za1 -> za1_apont == 'E'
								_sMsgEtiq += "Etiqueta '" + _sEtqApont + "' ja foi apontada e ESTORNADA. Nao pode ser apontada novamente. Gere nova etiqueta."
								_lEtiqOK = .F.
							endif
							if za1 -> za1_impres != 'S'
								_sMsgEtiq += "Etiqueta '" + _sEtqApont + "' ainda nao impressa."
								_lEtiqOK = .F.
							endif
							if empty (za1 -> za1_op)
								_sMsgEtiq += "Etiqueta '" + _sEtqApont + "' nao relacionada com nenhuma OP."
								_lEtiqOK = .F.
							else
								sc2 -> (dbsetorder (1))  // C2_FILIAL, C2_NUM, C2_ITEM, C2_SEQUEN, C2_ITEMGRD, R_E_C_N_O_, D_E_L_E_T_
								if ! sc2 -> (dbseek (xfilial ("SC2") + za1 -> za1_op, .F.))
									_sMsgEtiq += "OP '" + alltrim (za1 -> za1_op) + "' (relacionada com a etiqueta '" + _sEtqApont + "') nao foi localizada."
									_lEtiqOK = .F.
								else
									if ! empty (sc2 -> c2_datrf)
										_sMsgEtiq += "OP '" + alltrim (za1 -> za1_op) + "' (relacionada com a etiqueta '" + _sEtqApont + "') ja encontra-se encerrada."
										_lEtiqOK = .F.
									endif
								endif
							endif
						endif
					endif

					if _lEtiqOK
						if empty (_sErroWS)
							_aAutoSD3 = {}
							aadd (_aAutoSD3, {"D3_OP",      za1 -> za1_op,  NIL})
							aadd (_aAutoSD3, {"D3_VAETIQ",  za1 -> za1_codigo, NIL})
							aadd (_aAutoSD3, {"D3_VADTPRD", _dDtProd,   NIL})
							aadd (_aAutoSD3, {"D3_VATURNO", _sTnoProd,  NIL})
							if ! empty (_sMotProd)
								aadd (_aAutoSD3, {"D3_VAMOTIV", _sMotProd,  NIL})
							endif
							aadd (_aAutoSD3, {"ATUEMP",     "T",        NIL})  // Para que sempre seja feita a baixa dos empenhos.
							_aAutoSD3 := aclone (U_OrdAuto (_aAutoSD3))
							//U_Log2 ('debug', _aAutoSD3)
							lMsErroAuto  := .F.
							_sErroAuto := ''
							U_Log2 ('info', 'Executando MATA250')
							MATA250 (_aAutoSD3, 3)
							If lMsErroAuto
								if ! empty (_sErroAuto)
									_sMsgEtiq += _sErroAuto + '; '
									_lEtiqOK = .F.
								endif
								if ! empty (NomeAutoLog ())
									_sMsgEtiq += U_LeErro (memoread (NomeAutoLog ())) + '; '
									_lEtiqOK = .F.
								endif
								u_log2 ('erro', 'Rotina automatica retornou erro: ' + _sErroWS)
								// Se a variavel _sErroWS tiver dados, o processo vai ser abortado.
								// Vou limpar por garantia, por que ela eh atualizada dentro da funcao U_Help, que muitas vezes eh
								// usada em pontos de entrada e validacoes de campo.
								_sErroWS = ''
							else
								_sMsgEtiq += "Apontamento gerado com sucesso (seq." + sd3 -> d3_numseq + ")"
							endif
						endif
					endif

					U_Log2 ('debug', _sMsgEtiq)

					// Monta trecho da mensagem de retorno referente a etiqueta atual.
					_sMsgRetWS += '<ApontaProdtem>'
					_sMsgRetWS += '<Etiq>' + _sEtqApont + '</Etiq>'
					_sMsgRetWS += '<result>' + iif (_lEtiqOK, 'OK', 'ERRO') + '</result>'
					_sMsgRetWS += '<msg>' + _sMsgEtiq + '</msg>'
					_sMsgRetWS += '</ApontaProdtem>'

					_sSeqEtiq = soma1 (_sSeqEtiq)
				enddo
				_sMsgRetWS += '</ApontaProd>'
				return


// --------------------------------------------------------------------------
// Gera apontamento de producao a partir de etiqueta+codigo barras do produto.
// A intencao eh evitar que seja apontada uma etiqueta que tenha sido colada
// em um pallet de outro produto. 
static function _ApPrEtqCB ()
	local _sEtqApont := ''
	local _dDtProd   := ctod ('')
	local _sTnoProd  := ''
	local _aAutoSD3  := {}
	local _sMotProd  := ''
	local _sCodBarAp := ''

	if empty (_sErroWS) ; _sEtqApont =       _ExtraiTag ("_oXML:_WSAlianca:_Etiq",     .T., .F.)  ; endif
		if empty (_sErroWS) ; _sCodBarAp =       _ExtraiTag ("_oXML:_WSAlianca:_CodBarra", .T., .F.)  ; endif
			if empty (_sErroWS) ; _sTnoProd  =       _ExtraiTag ("_oXML:_WSAlianca:_Turno",    .T., .F.)  ; endif
				if empty (_sErroWS) ; _dDtProd   = stod (_ExtraiTag ("_oXML:_WSAlianca:_DtProd",   .T., .T.)) ; endif
					if empty (_sErroWS) ; _sMotProd  =       _ExtraiTag ("_oXML:_WSAlianca:_Motivo",   .T., .F.)  ; endif

						// Validacao inicial do numero da etiqueta.
						if empty (_sErroWS)
							_oEtiq := ClsEtiq ():New (_sEtqApont)
							if _oEtiq:Codigo != _sEtqApont
								_SomaErro ("Numero de etiqueta invalido.")
							endif
						endif

						// Valida codigo de barras lido na embalagem coletiva.
						if empty (_sErroWS)
							if ! _oEtiq:ValCbEmb (_sCodBarAp)
								_SomaErro (_oEtiq:UltMsg)
							endif
						endif

						if empty (_sErroWS)
							if ! _oEtiq:PodeApont (_oEtiq:Quantidade, 0)
								// Dentro do metodo PodeApont() jah deve estar sendo chamada a
								// funcao U_Help(), que deve alimentar a variavel _sErroWS.
								// Apenas para garantir, vou acrescentar algum conteudo a ela.
								_SomaErro ('.')
							endif
						endif

						// Gera oapontamento de producao
						if empty (_sErroWS)
							_aAutoSD3 = {}
							aadd (_aAutoSD3, {"D3_OP",      za1 -> za1_op,  NIL})
							aadd (_aAutoSD3, {"D3_VAETIQ",  za1 -> za1_codigo, NIL})
							aadd (_aAutoSD3, {"D3_VADTPRD", _dDtProd,   NIL})
							aadd (_aAutoSD3, {"D3_VATURNO", _sTnoProd,  NIL})
							aadd (_aAutoSD3, {"D3_VAMOTIV", _sMotProd,  NIL})
							aadd (_aAutoSD3, {"ATUEMP",     "T",        NIL})  // Para que sempre seja feita a baixa dos empenhos.
							_aAutoSD3 := aclone (U_OrdAuto (_aAutoSD3))
							U_Log2 ('debug', _aAutoSD3)
							lMsErroAuto  := .F.
							_sErroAuto := ''
							U_Log2 ('info', 'Executando MATA250')
							MATA250 (_aAutoSD3, 3)
							If lMsErroAuto
								if ! empty (_sErroAuto)
									_SomaErro (_sErroAuto)
								elseif ! empty (NomeAutoLog ())
									_SomaErro (U_LeErro (memoread (NomeAutoLog ())))
								endif
								u_log2 ('erro', 'Rotina automatica retornou erro: ' + _sErroWS)
							else
								_sMsgRetWS += "Apontamento gerado com sucesso (d3_numseq = " + sd3 -> d3_numseq + ")"
							endif
						endif
						return


// --------------------------------------------------------------------------
// Realiza bloqueio/desbloqueio de pedidos
Static Function _PedidosBloq()
	local _oSQL     := NIL
	local _XmlRet   := ""
	local _aPed     := {}
	local _aItem    := {}
	local _x        := 0
	local _y        := 0

//	u_logIni ()

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   C5_FILIAL "
	_oSQL:_sQuery += "    ,C5_NUM "
	_oSQL:_sQuery += "    ,C5_EMISSAO "
	_oSQL:_sQuery += "    ,C5_CLIENTE "
	_oSQL:_sQuery += "    ,C5_LOJACLI "
	_oSQL:_sQuery += "    ,A1_NOME "
	_oSQL:_sQuery += "    ,A1_EST "
	_oSQL:_sQuery += "    ,C5_VAVLFAT "
	_oSQL:_sQuery += "    ,C5_VAMCONT "
	_oSQL:_sQuery += "    ,C5_VAPRPED "
	_oSQL:_sQuery += "    ,C5_STATUS "
	_oSQL:_sQuery += "    ,C5_VABLOQ "
	_oSQL:_sQuery += "    ,C5_VEND1 +'- '+ SA3.A3_NOME "
	_oSQL:_sQuery += "    ,C5_VAUSER "
	_oSQL:_sQuery += "    ,C5_TIPO "
	_oSQL:_sQuery += "    ,C5_TPFRETE "
	_oSQL:_sQuery += "    ,C5_PEDCLI "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SC5") + " SC5 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND A1_COD = C5_CLIENTE "
	_oSQL:_sQuery += " 		AND A1_LOJA = C5_LOJACLI "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA3") + " SA3 "
	_oSQL:_sQuery += "  ON SA3.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA3.A3_COD = SC5.C5_VEND1 "
	_oSQL:_sQuery += " WHERE SC5.D_E_L_E_T_   = '' "
	_oSQL:_sQuery += " AND C5_VABLOQ  != ''	 "		// Pedido com bloqueio
	_oSQL:_sQuery += " AND C5_LIBEROK != ''	 "		// Pedido com 'liberacao comercial (SC9 gerado)
	_oSQL:_sQuery += " AND C5_NOTA != 'XXXXXXXXX' " // Residuo eliminado (nao sei por que as vezes grava com 9 posicoes)
	_oSQL:_sQuery += " AND C5_NOTA != 'XXXXXX'  " 	// Residuo eliminado (nao sei por que as vezes grava com 6 posicoes)
	//_oSQL:Log ()
	_aPed := aclone(_oSQL:Qry2Array ())

	_XmlRet += "<BuscaPedidosBloqueados>"
	_XmlRet += "	<Registro>"

	For _x:= 1 to Len(_aPed)
		_sBloq := _aPed[_x,12]
		Do Case
		Case 'X'$_sBloq
			_sDescLgd := 'Liberacao negada'

		Case !'X'$_sBloq.and.'M'$_sBloq.and.'P'$_sBloq
			_sDescLgd := 'Bloq.por margem e preco'

		Case !'X'$_sBloq.and.'F'$_sBloq
			_sDescLgd := 'Bonif.sem faturamento'

		Case !'X'$_sBloq.and.'P'$_sBloq
			_sDescLgd := 'Bloq.por preco'

		Case !'X'$_sBloq.and.'M'$_sBloq
			_sDescLgd := 'Bloq.por margem'

		Case !'X'$_sBloq.and.'A'$_sBloq
			_sDescLgd := 'Bloq.%reajuste'

		Case !'X'$_sBloq.and.'B'$_sBloq
			_sDescLgd := 'Bloq.bonificação'
		otherwise
			_sDescLgd := " "
		EndCase

		_sNome    := strtran(U_NoAcento(_aPed[_x, 6]), '&', 'e')
		_sUsuario := strtran(U_NoAcento(_aPed[_x,14]), '&', 'e')

		_XmlRet += "		<RegistroItem>"
		_XmlRet += "			<Filial>"			+ _aPed[_x, 1] 					+ "</Filial>"
		_XmlRet += "			<Pedido>"			+ _aPed[_x, 2] 					+ "</Pedido>"
		_XmlRet += "			<Emissao>"			+ DTOS(_aPed[_x, 3]) 			+ "</Emissao>"
		_XmlRet += "			<Cliente>"			+ _aPed[_x, 4] 					+ "</Cliente>"
		_XmlRet += "			<Loja>"				+ _aPed[_x, 5] 					+ "</Loja>"
		_XmlRet += "			<Nome>"				+ _sNome     					+ "</Nome>"
		_XmlRet += "			<Uf>"				+ _aPed[_x, 7] 					+ "</Uf>"
		_XmlRet += "			<ValorFaturamento>"	+ alltrim(str(_aPed[_x, 8])) 	+ "</ValorFaturamento>"
		_XmlRet += "			<MargemContr>"		+ alltrim(str(_aPed[_x, 9])) 	+ "</MargemContr>"
		_XmlRet += "			<VarPrcAnt>"		+ alltrim(str(_aPed [_x,10])) 	+ "</VarPrcAnt>"
		_XmlRet += "			<Status>"			+ _aPed[_x,11] 					+ "</Status>"
		_XmlRet += "			<Bloqueio>"			+ _aPed[_x,12] 					+ "</Bloqueio>"
		_XmlRet += "			<Vendedor>"			+ _aPed[_x,13] 					+ "</Vendedor>"
		_XmlRet += "			<Usuario>"			+ _sUsuario  					+ "</Usuario>"
		_XmlRet += "			<TipoPed>"			+ _aPed[_x,15] 					+ "</TipoPed>"
		_XmlRet += "			<TipoFrete>"		+ _aPed[_x,16] 					+ "</TipoFrete>"
		_XmlRet += "			<PedidoCliente>"	+ _aPed[_x,17] 					+ "</PedidoCliente>"
		_XmlRet += "			<DescBloqueio>"	    + _sDescLgd    					+ "</DescBloqueio>"

		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += " 	   C6_FILIAL "
		_oSQL:_sQuery += "    ,C6_ITEM "
		_oSQL:_sQuery += "    ,C6_PRODUTO "
		_oSQL:_sQuery += "    ,C6_DESCRI "
		_oSQL:_sQuery += "    ,C6_UM "
		_oSQL:_sQuery += "    ,C6_QTDVEN "
		_oSQL:_sQuery += "    ,C6_PRCVEN "
		_oSQL:_sQuery += "    ,C6_PRUNIT "
		_oSQL:_sQuery += "    ,C6_VALOR "
		_oSQL:_sQuery += "    ,C6_TES "
		_oSQL:_sQuery += " FROM " + RetSQLName ("SC6") + " SC6 "
		_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
		_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " 		AND A1_COD  = SC6.C6_CLI "
		_oSQL:_sQuery += " 		AND A1_LOJA = SC6.C6_LOJA "
		_oSQL:_sQuery += " WHERE SC6.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " AND SC6.C6_FILIAL = '" + _aPed[_x, 1] + "'"
		_oSQL:_sQuery += " AND SC6.C6_NUM    = '" + _aPed[_x, 2] + "'"
		_oSQL:_sQuery += " AND SC6.C6_CLI    = '" + _aPed[_x, 4] + "'"
		_oSQL:_sQuery += " AND SC6.C6_LOJA   = '" + _aPed[_x, 5] + "'"
		//_oSQL:Log ()
		_aItem := aclone (_oSQL:Qry2Array ())

		_XmlRet += "		<ItensPedido>"
		For _y:= 1 to Len(_aItem)
			_XmlRet += "		<ItensPedidoItem> "
			_XmlRet += "			<Filial>"		+ _aItem[_y, 1] 				+ "</Filial>"
			_XmlRet += "			<Item>"			+ _aItem[_y, 2] 				+ "</Item>"
			_XmlRet += "			<Produto>"		+ _aItem[_y, 3] 				+ "</Produto>"
			_XmlRet += "			<Descricao>"	+ _aItem[_y, 4] 				+ "</Descricao>"
			_XmlRet += "			<Unidade>"		+ _aItem[_y, 5] 				+ "</Unidade>"
			_XmlRet += "			<QtdVendida>"	+ alltrim(str(_aItem[_y, 6])) 	+ "</QtdVendida>"
			_XmlRet += "			<PrcVenda>"		+ alltrim(str(_aItem[_y, 7])) 	+ "</PrcVenda>"
			_XmlRet += "			<PrcUnitario>"	+ alltrim(str(_aItem[_y, 8])) 	+ "</PrcUnitario>"
			_XmlRet += "			<Valor>"		+ alltrim(str(_aItem[_y, 9])) 	+ "</Valor>"
			_XmlRet += "			<Tes>"			+ _aItem[_y,10] 				+ "</Tes>"
			_XmlRet += "		</ItensPedidoItem> "
		Next
		_XmlRet += "		</ItensPedido>"
		_XmlRet += "		</RegistroItem>"
	Next
	_XmlRet += "	</Registro>"
	_XmlRet += "</BuscaPedidosBloqueados>"

	u_log2 ('info', _XmlRet)

	_sMsgRetWS := _XmlRet
//	u_logFim ()
Return
//
// --------------------------------------------------------------------------
// Grava retorno da liberaçao gerencial de pedidos
Static Function _GrvLibPed ()
	local _wFilial 	 := ""
	local _wPedido	 := ""
	local _wCliente  := ""
	local _wLoja 	 := ""

//	u_logIni ()

	If empty(_sErroWS)
		_wFilial   := _ExtraiTag ("_oXML:_WSAlianca:_Filial"	, .T., .F.)
		_wPedido   := _ExtraiTag ("_oXML:_WSAlianca:_Pedido"	, .T., .F.)
		_wCliente  := _ExtraiTag ("_oXML:_WSAlianca:_Cliente"	, .T., .F.)
		_wLoja     := _ExtraiTag ("_oXML:_WSAlianca:_Loja"		, .T., .F.)
		_wBloqLib  := _ExtraiTag ("_oXML:_WSAlianca:_BloqLib"	, .T., .F.) // Retorna L - libera / B - Bloqueia
	endif

	If empty(_sErroWS)
		sa1 -> (dbsetorder(1)) // A1_FILIAL + A1_COD + A1_LOJA
		DbSelectArea("SA1")
		If ! dbseek(xFilial("SA1") + _wCliente + _wLoja, .F.)
			_sErroWS := " Cliente " + _wCliente +"/"+ _wLoja +" não encontrado. Verifique!"
		endif
	endif

	If empty(_sErroWS)
		sc5 -> (dbsetorder(3)) // C5_FILIAL + C5_CLIENTE + C5_LOJACLI + C5_NUM
		DbSelectArea("SC5")

		If dbseek(_wFilial + _wCliente + _wLoja + _wPedido, .F.)
			If empty(sc5 -> c5_vabloq)
				_sErroWS := " Pedido já liberado!"
			Else
				If alltrim(_wBloqLib) == 'L'    	// Libera pedido
					U_SC5LBGL()
				Else
					If alltrim(_wBloqLib) == 'B'	// Bloqueia pedido
						U_SC5LBGN()
					endif
				endif
			endif
		Else
			_sErroWS := "Pedido " + _wPedido + " não encontrado para o cliente "	+ _wCliente +"/"+ _wLoja
		endif
	endif

//	u_logFim ()
Return
//
// --------------------------------------------------------------------------
// Grava retorno da margem contribuicao
Static Function _EnvMargem ()
	local _wFilial 	 := ""
	local _wPedido	 := ""
	local _wCliente  := ""
	local _wLoja 	 := ""
	local _aNaWeb    := {}
	local _XmlRet    := ""
	local _x         := 0
	local _lContPrc  :=.F.

//	u_logIni ()

	If empty(_sErroWS)
		_wFilial   := _ExtraiTag ("_oXML:_WSAlianca:_Filial"	, .T., .F.)
		_wPedido   := _ExtraiTag ("_oXML:_WSAlianca:_Pedido"	, .T., .F.)
		_wCliente  := _ExtraiTag ("_oXML:_WSAlianca:_Cliente"	, .T., .F.)
		_wLoja     := _ExtraiTag ("_oXML:_WSAlianca:_Loja"		, .T., .F.)
	endif

	u_log2 ('info', "Pedido:"+ _wPedido + " Cliente:" + PADR(_wCliente, 6,' ') + "-" + _wLoja)

	If empty(_sErroWS)
		sa1 -> (dbsetorder(1)) 		// A1_FILIAL + A1_COD + A1_LOJA
		DbSelectArea("SA1")

		If ! dbseek(xFilial("SA1") + PADR(_wCliente, 6,' ') + _wLoja, .F.)
			_sErroWS := " Cliente " + _wCliente +"/"+ _wLoja +" não encontrado. Verifique!"
		Else
			_wNomeCli := sa1->a1_nome
		endif
	endif

	If empty(_sErroWS)
		sc5 -> (dbsetorder(3)) // C5_FILIAL + C5_CLIENTE + C5_LOJACLI + C5_NUM
		DbSelectArea("SC5")

		If dbseek(_wFilial + _wCliente + _wLoja + _wPedido, .F.)
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT "
			_oSQL:_sQuery += " 	 	DESCRITIVO "
			_oSQL:_sQuery += " FROM VA_VEVENTOS "
			_oSQL:_sQuery += " WHERE CODEVENTO  = 'SC5009' "
			_oSQL:_sQuery += " AND FILIAL       = '" + _wFilial  + "' "
			_oSQL:_sQuery += " AND CLIENTE      = '" + _wCliente + "' "
			_oSQL:_sQuery += " AND LOJA_CLIENTE = '" + _wLoja    + "' "
			_oSQL:_sQuery += " AND PEDVENDA     = '" + _wPedido  + "' "
			_oSQL:_sQuery += " ORDER BY HORA, DESCRITIVO"
			_aItem := aclone (_oSQL:Qry2Array ())

			_XmlRet := "<BuscaItensPedBloq>"
			For _x:=1 to Len(_aItem)
				_aNaWeb := STRTOKARR(_aItem[_x,1],"|")

				if Len(_aNaWeb) == 14
					_lContPrc :=.T.
				endif

				_XmlRet += "<BuscaItensPedBloqItem>"
				_XmlRet += "<Filial>"        + _wFilial 	  + "</Filial>"
				_XmlRet += "<Pedido>"		 + _wPedido       + "</Pedido>"
				_XmlRet += "<Cliente>" 		 + _wCliente 	  + "</Cliente>"
				_XmlRet += "<Nome>"			 + _wNomeCli	  + "</Nome>"
				_XmlRet += "<Loja>"			 + _wLoja 		  + "</Loja>"
				_XmlRet += "<Produto>" 		 + alltrim(_aNaWeb[ 2]) + "</Produto>"
				_XmlRet += "<Quantidade>" 	 + alltrim(_aNaWeb[ 3]) + "</Quantidade>"
				_XmlRet += "<PrcVenda>" 	 + alltrim(_aNaWeb[ 4]) + "</PrcVenda>"
				_XmlRet += "<PrcCusto>" 	 + alltrim(_aNaWeb[ 5]) + "</PrcCusto>"
				_XmlRet += "<Comissao>" 	 + alltrim(_aNaWeb[ 6]) + "</Comissao>"
				_XmlRet += "<ICMS>" 		 + alltrim(_aNaWeb[ 7]) + "</ICMS>"
				_XmlRet += "<PISCOF>" 		 + alltrim(_aNaWeb[ 8]) + "</PISCOF>"
				_XmlRet += "<Rapel>" 		 + alltrim(_aNaWeb[ 9]) + "</Rapel>"
				_XmlRet += "<Frete>" 		 + alltrim(_aNaWeb[10]) + "</Frete>"
				_XmlRet += "<Financeiro>" 	 + alltrim(_aNaWeb[11]) + "</Financeiro>"
				_XmlRet += "<MargemVlr>" 	 + alltrim(_aNaWeb[12]) + "</MargemVlr>"
				_XmlRet += "<MargemPercent>" + alltrim(_aNaWeb[13]) + "</MargemPercent>"
				if _lContPrc
					_XmlRet += "<PrcVenItem>" + alltrim(_aNaWeb[14]) + "</PrcVenItem>"
				else
					_XmlRet += "<PrcVenItem> 0 </PrcVenItem>"
				endif
				_XmlRet += "</BuscaItensPedBloqItem>"
			Next
			_XmlRet += "</BuscaItensPedBloq>"
			u_log2 ('info', _XmlRet)
		Else
			_sErroWS := "Pedido " + _wPedido + " não encontrado para o cliente "	+ _wCliente +"/"+ _wLoja
		endif
	endif
	_sMsgRetWS := _XmlRet
//	u_logFim ()
Return


// --------------------------------------------------------------------------
// Grava data de entrega da nota de venda.
// A ideia eh importar do Entregou, mas alguns casos podem precisar atualizacao manual.
Static function _DtEntFat ()
	local _sNF     := ''
	local _sSerie  := ''
	local _dDtEntr := ctod ('')

	if empty (_sErroWS) ; _sNF     = _ExtraiTag ("_oXML:_WSAlianca:_NF", .T., .F.) ; endif
		if empty (_sErroWS) ; _sSerie  = _ExtraiTag ("_oXML:_WSAlianca:_Serie", .T., .F.) ; endif
			if empty (_sErroWS) ; _dDtEntr = stod (_ExtraiTag ("_oXML:_WSAlianca:_DtEntrega", .T., .T.)) ; endif
				if empty (_sErroWS)
					sf2 -> (dbsetorder (1))
					if ! sf2 -> (dbseek (xfilial ("SF2") + _sNf + _sSerie, .F.))
						_SomaErro ("NF/serie " + _sNF + '/' + _sSerie + ' de saida nao localizada.')
					else

						// Grava evento temporario (nao estou descobrindo em que momento este campo eh atualizado)
						_oEvento := ClsEvent():new ()
						_oEvento:Filial     = SF2 -> F2_FILIAL
						_oEvento:Texto     := 'Atualizando campo F2_DTENTR de ' + dtoc (sf2 -> f2_DtEntr) + ' para ' + dtoc (_dDtEntr)
						_oEvento:Texto     += " Pilha: " + U_LogPCham ()
						_oEvento:CodEven    = "DEBUG"
						_oEvento:NFSaida    = sf2 -> f2_doc
						_oEvento:SerieSaid  = sf2 -> f2_Serie
						_oEvento:Cliente    = sf2 -> f2_cliente
						_oEvento:LojaCli    = sf2 -> f2_loja
						_oEvento:DiasValid = 60  // Manter o evento por alguns dias, depois disso vai ser deletado.
						_oEvento:Grava ()

						reclock ("SF2", .F.)
						sf2 -> f2_DtEntr = _dDtEntr
						msunlock ()
						_sMsgRetWS = 'Registro atualizado.'
					endif
				endif
				return


// --------------------------------------------------------------------------
// Associados - consulta fechamento de safra.
static function _AsFecSaf ()
	local   _sAssoc    := ""
	local   _sLoja     := ""
	local   _sSafra    := ""
	local   _oAssoc    := NIL
	local   _sRet      := ''
	private _sErroAuto := ""  // Variavel alimentada pela funcao U_Help

	U_Log2 ('debug', '[' + procname () + ']iniciando...')
	if empty (_sErroWS) ; _sAssoc = U_ExTagXML ("_oXML:_WSAlianca:_Assoc", .T., .F.) ; endif
		if empty (_sErroWS) ; _sLoja  = U_ExTagXML ("_oXML:_WSAlianca:_Loja",  .T., .F.) ; endif
			if empty (_sErroWS) ; _sSafra = U_ExTagXML ("_oXML:_WSAlianca:_Safra", .T., .F.) ; endif
				if empty (_sErroWS)
					_oAssoc := ClsAssoc ():New (_sAssoc, _sLoja)
					if valtype (_oAssoc) != 'O'
						_SomaErro ("Impossivel instanciar objeto ClsAssoc. Verifique codigo e loja informados " + _sErroAuto)
					endif
				endif
				if empty (_sErroWS)
					U_Log2 ('debug', '[' + procname () + ']parametrizando...')
					if empty (_sErroWS) ; _oAssoc:FSDFunrur    = .t. ;endif // Habilitar resto da linha quando o NaWeb estiver mandando as tags ---> (U_ExTagXML ("_oXML:_WSAlianca:_descontoFUNRURAL",  .F., .F.) == 'S') ; endif
						if empty (_sErroWS) ; _oAssoc:FSFrete      = .t. ;endif // Habilitar resto da linha quando o NaWeb estiver mandando as tags ---> (U_ExTagXML ("_oXML:_WSAlianca:_freteSafra",        .F., .F.) == 'S') ; endif
							if empty (_sErroWS) ; _oAssoc:FSLctosCC    = .t. ;endif // Habilitar resto da linha quando o NaWeb estiver mandando as tags ---> (U_ExTagXML ("_oXML:_WSAlianca:_lctoCC",            .F., .F.) == 'S') ; endif
								if empty (_sErroWS) ; _oAssoc:FSNFEntrada  = .t. ;endif // Habilitar resto da linha quando o NaWeb estiver mandando as tags ---> (U_ExTagXML ("_oXML:_WSAlianca:_nfEntrada",         .F., .F.) == 'S') ; endif
									if empty (_sErroWS) ; _oAssoc:FSNFCompra   = .t. ;endif // Habilitar resto da linha quando o NaWeb estiver mandando as tags ---> (U_ExTagXML ("_oXML:_WSAlianca:_nfCompra",          .F., .F.) == 'S') ; endif
										if empty (_sErroWS) ; _oAssoc:FSNFComplem  = .t. ;endif // Habilitar resto da linha quando o NaWeb estiver mandando as tags ---> (U_ExTagXML ("_oXML:_WSAlianca:_nfComplemento",     .F., .F.) == 'S') ; endif
											if empty (_sErroWS) ; _oAssoc:FSNFPrdProp  = .t. ;endif // Habilitar resto da linha quando o NaWeb estiver mandando as tags ---> (U_ExTagXML ("_oXML:_WSAlianca:_nfProdPropria",     .F., .F.) == 'S') ; endif
												if empty (_sErroWS) ; _oAssoc:FSPrevPagto  = .t. ;endif // Habilitar resto da linha quando o NaWeb estiver mandando as tags ---> (U_ExTagXML ("_oXML:_WSAlianca:_faturaPagamento",   .F., .F.) == 'S') ; endif
													if empty (_sErroWS) ; _oAssoc:FSRegraPagto = .t. ;endif // Habilitar resto da linha quando o NaWeb estiver mandando as tags ---> (U_ExTagXML ("_oXML:_WSAlianca:_regraPagamento",    .F., .F.) == 'S') ; endif
														if empty (_sErroWS) ; _oAssoc:FSResVaried  = .t. ;endif // Habilitar resto da linha quando o NaWeb estiver mandando as tags ---> (U_ExTagXML ("_oXML:_WSAlianca:_resumoVariedade",   .F., .F.) == 'S') ; endif
															if empty (_sErroWS) ; _oAssoc:FSResVarGC   = .t. ;endif // Habilitar resto da linha quando o NaWeb estiver mandando as tags ---> (U_ExTagXML ("_oXML:_WSAlianca:_resumoVarGrauClas", .F., .F.) == 'S') ; endif
																_oAssoc:FSSafra      = _sSafra

																//	//                         _sSafra, _lFSNFE, _lFSNFC, _lFSNFV, _lFSNFP, _lFSPrPg, _lFSRgPg, _lFSVlEf, _lFSResVGM, _lFSFrtS, _lFSLcCC, _lFSResVGC, _lFSFunrur
																//	_sRet = _oAssoc:FechSafra (_sSafra, .t.,     .t.,     .t.,     .t.,     .t.,      .t.,      .t.,      .t.,        .t.,      .t.,      .t.,        .t.)
																_sRet = _oAssoc:FechSafra ()
																U_Log2 ('debug', '[' + procname () + ']' + _sRet)
																if empty (_sRet)
																	_SomaErro ("Retorno invalido metodo FechSafra " + _oAssoc:UltMsg)
																else
																	_sMsgRetWS = _sRet
																endif
															endif
															return


// --------------------------------------------------------------------------
// Associados - consulta capital social.
static function _AsCapSoc ()
	local   _sAssoc    := ""
	local   _sLoja     := ""
	local   _sRet      := ''
	private _sErroAuto := ""  // Variavel alimentada pela funcao U_Help

	if empty (_sErroWS) ; _sAssoc = U_ExTagXML ("_oXML:_WSAlianca:_Assoc", .T., .F.) ; endif
		if empty (_sErroWS) ; _sLoja  = U_ExTagXML ("_oXML:_WSAlianca:_Loja", .T., .F.)  ; endif
			if empty (_sErroWS)
				_oAssoc := ClsAssoc ():New (_sAssoc, _sLoja)
				if valtype (_oAssoc) != 'O'
					_SomaErro ("Impossivel instanciar objeto ClsAssoc. Verifique codigo e loja informados " + _sErroAuto)
				endif
			endif
			if empty (_sErroWS)
				_sRet = _oAssoc:SldQuotCap (date ()) [.QtCapRetXML]
				if empty (_sRet)
					_SomaErro ("Retorno invalido metodo SldQuotCap " + _oAssoc:UltMsg)
				else
					_sMsgRetWS = _sRet
				endif
			endif
			return


// --------------------------------------------------------------------------
// Atualiza cadastro de associados
static function _AltAssoc ()
//	local   _sAssoc    := ""
//	local   _sLoja     := ""
	local   _oSQL      := NIL
	local   _sMsgRet   := ''
	local   _aRegSA2   := {}
	local   _sCPF      := ''
	local   _sCodigo   := ''
	local   _sLoja     := ''
	local   _sInscr    := ''
	local   _sNome     := ''
	local   _sRG       := ''
	local   _sTelPref  := ''
	local   _sTelef2   := ''
	local   _dDtNasc   := ctod ('')
	local   _sEMail    := ''
	local   _sEndereco := ''
	local   _sCEP      := ''
	private _sErroAuto := ""  // Variavel alimentada pela funcao U_Help

	if empty (_sErroWS) ; _sCPF       = U_ExTagXML ("_oXML:_WSAlianca:_CPF",             .T., .F.) ; endif
		if empty (_sErroWS) ; _sCodigo    = U_ExTagXML ("_oXML:_WSAlianca:_CodProtheus",     .T., .F.) ; endif
			if empty (_sErroWS) ; _sLoja      = U_ExTagXML ("_oXML:_WSAlianca:_Loja",            .T., .F.) ; endif
				if empty (_sErroWS) ; _sInscr     = U_ExTagXML ("_oXML:_WSAlianca:_InscEstadual",    .T., .F.) ; endif
					if empty (_sErroWS) ; _sNome      = U_ExTagXML ("_oXML:_WSAlianca:_Nome",            .F., .F.) ; endif
						if empty (_sErroWS) ; _sRG        = U_ExTagXML ("_oXML:_WSAlianca:_RG",              .F., .F.) ; endif
							if empty (_sErroWS) ; _sTelPref   = U_ExTagXML ("_oXML:_WSAlianca:_telPreferencial", .F., .F.) ; endif
								if empty (_sErroWS) ; _sTelef2    = U_ExTagXML ("_oXML:_WSAlianca:_telefone2",       .F., .F.) ; endif
									if empty (_sErroWS) ; _dDtNasc    = U_ExTagXML ("_oXML:_WSAlianca:_dtnasc",          .F., .T.) ; endif
										if empty (_sErroWS) ; _sEMail     = U_ExTagXML ("_oXML:_WSAlianca:_email",           .F., .F.) ; endif
											if empty (_sErroWS) ; _sEndereco  = U_ExTagXML ("_oXML:_WSAlianca:_endereco",        .T., .F.) ; endif
												if empty (_sErroWS) ; _sCEP       = U_ExTagXML ("_oXML:_WSAlianca:_CEP",             .F., .F.) ; endif
													if empty (_sErroWS)
														//U_Log2 ('debug', '[' + procname () + ']Pesquisando SA2 com o CPF >>' + _sCPF + '<<')
														_oSQL := ClsSQL ():New ()
														_oSQL:_sQuery := ""
														_oSQL:_sQuery += "SELECT A2_COD, A2_LOJA"
														_oSQL:_sQuery +=  " FROM " + RetSQLName ("SA2") + " SA2"
														_oSQL:_sQuery += " WHERE SA2.D_E_L_E_T_ = ''"
														_oSQL:_sQuery +=   " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
														_oSQL:_sQuery +=   " AND SA2.A2_COD     = '" + _sCodigo + "'"
														_oSQL:_sQuery +=   " AND SA2.A2_LOJA    = '" + _sLoja   + "'"
														_oSQL:_sQuery +=   " AND SA2.A2_INSC    = '" + _sInscr  + "'"
														_oSQL:_sQuery +=   " AND SA2.A2_VARG    = '" + _sCPF    + "'"
														_oSQL:Log ()
														_aRegSA2 := _oSQL:RetFixo (1, 'ao procurar associado pelo cod+loja+CPF+insc.est.', .F.)
														if len (_aRegSA2) == 1
															_oAssoc := ClsAssoc ():New (sa2 -> a2_cod, sa2 -> a2_loja)
															if valtype (_oAssoc) != 'O'
																_SomaErro ("Impossivel instanciar objeto ClsAssoc. Verifique codigo e loja informados " + _sErroAuto)
															else
																u_logobj (_oAssoc)
															endif
														else
															_SomaErro ("Impossivel identificar associado.")
														endif
													endif
													if empty (_sErroWS)
														_sMsgRetWS = _sMsgRet
													endif
													return


// --------------------------------------------------------------------------
// Imprime uma etiqueta da tabela ZA1.
static function _ImpEtiq ()
	local _sEtiq    := ''
	local _sCodImpr := ''
	local _sCBProd  := ''

	if empty (_sErroWS) ; _sEtiq    = _ExtraiTag ("_oXML:_WSAlianca:_Etiqueta",          .T., .F.) ; endif
		if empty (_sErroWS) ; _sCodImpr = _ExtraiTag ("_oXML:_WSAlianca:_CodImpressora",     .T., .F.) ; endif
			if empty (_sErroWS) ; _sCBProd  = _ExtraiTag ("_oXML:_WSAlianca:_ObrigarBarrasProd", .F., .F.) ; endif

				// Validacao inicial do numero da etiqueta.
				if empty (_sErroWS)
					_oEtiq := ClsEtiq ():New (_sEtiq)
					if _oEtiq:Codigo != _sEtiq
						_SomaErro ("Numero de etiqueta invalido.")
					else

						// Eventualmente posso obrigar a listar as barras do produto.
						if _sCBProd == 'S'
							_oEtiq:ImprCBProd = 'S'
						endif

						if ! _oEtiq:Imprime (_sCodImpr)
							_SomaErro ('Erro na rotina de impressao')
						else
							_sMsgRetWS += _oEtiq:UltMsg
						endif
					endif
				endif
				return


// --------------------------------------------------------------------------
// Imprime uma etiqueta gerada para atender a uma sol.transf. da tabela ZAG.
static function _ImpEtiqZAG ()
	local _sDocZAG  := ''
	local _sCodImpr := ''
	local _oTrEstq  := NIL
	local _oEtiq    := NIL

	if empty (_sErroWS) ; _sDocZAG  = _ExtraiTag ("_oXML:_WSAlianca:_DocZAG",        .T., .F.) ; endif
	if empty (_sErroWS) ; _sCodImpr = _ExtraiTag ("_oXML:_WSAlianca:_CodImpressora", .T., .F.) ; endif

	// Validacao inicial do numero da etiqueta.
	if empty (_sErroWS)
		zag -> (dbsetorder (1))  // ZAG_FILIAL+ ZAG_DOC + ZAG_SEQ
		if ! zag -> (dbseek (xfilial ("ZAG") + _sDocZAG, .F.))
			_SomaErro ("Documento '" + _sDocZAG + "' nao localizado na tabela ZAG")
		else
			_oTrEstq := ClsTrEstq ():New (zag -> (recno ()))

			// Se nao tem etiqueta, eh possivel que tenha dado problema na
			// geracao da mesma. Vou tentar gerar novamente.
			if empty (_oTrEstq:Etiqueta)
				U_Log2 ('debug', '[' + procname () + ']nao tem etiq.ainda. Vou gerar.')
				_oTrEstq:ImprEtq = _sCodImpr
				if ! _oTrEstq:GeraEtiq (.T.)
					_SomaErro (_oTrEstq:UltMsg)
				else
					_sMsgRetWS += _oTrEstq:UltMsg
				endif
			else
				U_Log2 ('debug', '[' + procname () + ']jah tem a etiq ' + _oTrEstq:Etiqueta + ' Vou imprimir.')
				_oEtiq := ClsEtiq ():New (_oTrEstq:Etiqueta)
				if _oEtiq:Codigo != _oTrEstq:Etiqueta
					_SomaErro ("Numero de etiqueta invalido.")
				else
					//	U_Log2 ('debug', '[' + procname () + ']_sCodImpr = ' + _sCodImpr)
					if ! _oEtiq:Imprime (_sCodImpr)
						_SomaErro ('Erro na impressao.' + _oEtiq:UltMsg)
					else
						// Como tive casos de falta de algum cadastro, o pessoal
						// apenas atualizou cadastro e tentou reimprimir a
						// etiqueta, na esperanca de que jah fosse reenviada para
						// o FullWMS. Nao custa nada dar uma maozinha...
						_oEtiq:EnviaFull (.f.)

						_sMsgRetWS += _oEtiq:UltMsg
					endif
				endif
			endif
		endif
	endif
return


// --------------------------------------------------------------------------
// Inutiliza uma etiqueta da tabela ZA1.
static function _InutEtiq ()
	local _sEtiq    := ''

	if empty (_sErroWS) ; _sEtiq    = _ExtraiTag ("_oXML:_WSAlianca:_Etiqueta",      .T., .F.) ; endif

		// Validacao inicial do numero da etiqueta.
		if empty (_sErroWS)
			_oEtiq := ClsEtiq ():New (_sEtiq)
			if _oEtiq:Codigo != _sEtiq
				_SomaErro ("Numero de etiqueta invalido.")
			else
				if ! _oEtiq:Inutiliza (.F.)
					_SomaErro (_oEtiq:UltMsg)
				else
					_sMsgRetWS += _oEtiq:UltMsg
				endif
			endif
		endif
		return


// --------------------------------------------------------------------------
// Operacoes com a tabela ZZU (grupos de usuarios)
static function _ZZU (_sQueFazer)
	local _sCodZZU   := ''

	if empty (_sErroWS) ; _sCodZZU = _ExtraiTag ("_oXML:_WSAlianca:_GrupoZZU", .T., .F.) ; endif
		if empty (_sErroWS)
// usar isto quando criar function para o ZX5		_oTabGen := ClsTabGen ():New (_sCodZZU)
// usar isto quando criar function para o ZX5		if empty (_oTabGen:CodTabela)
// usar isto quando criar function para o ZX5			_SomaErro (_oTabGen:UltMsg)
// usar isto quando criar function para o ZX5		endif
		endif
		if empty (_sErroWS)
			do case
			case _sQueFazer == 'VincularUsuario'
				_SomaErro ('Metodo ainda nao 100% implementado')
				// _sMsgRetWS += _oTabGen:UltMsg
			otherwise
				_SomaErro ('Operacao ' + _sQueFazer + ' desconhecida na rotina ' + procname ())
			endcase
		endif
		return


// --------------------------------------------------------------------------
// Consulta estrutura com custos.
static function _EstrCust ()
	local _oSQL      := NIL
	local _sProdIni  := ''
	local _sProdFim  := ''
	local _sTpPrdIni := ''
	local _sTpPrdFim := ''
	local _sLComIni  := ''
	local _sLComFim  := ''

	if empty (_sErroWS) ; _sProdIni  = _ExtraiTag ("_oXML:_WSAlianca:_ProdutoInicial",        .F., .F.) ; endif
		if empty (_sErroWS) ; _sProdFim  = _ExtraiTag ("_oXML:_WSAlianca:_ProdutoFinal",          .F., .F.) ; endif
			if empty (_sErroWS) ; _sTpPrdIni = _ExtraiTag ("_oXML:_WSAlianca:_TipoProdutoInicial",    .F., .F.) ; endif
				if empty (_sErroWS) ; _sTpPrdFim = _ExtraiTag ("_oXML:_WSAlianca:_TipoProdutoFinal",      .F., .F.) ; endif
					if empty (_sErroWS) ; _sLComIni  = _ExtraiTag ("_oXML:_WSAlianca:_LinhaComercialInicial", .F., .F.) ; endif
						if empty (_sErroWS) ; _sLComFim  = _ExtraiTag ("_oXML:_WSAlianca:_LinhaComercialFinal",   .F., .F.) ; endif

							// Verifica se vai gerar muitos produtos
							if empty (_sErroWS)
								_oSQL := ClsSQL ():New ()
								_oSQL:_sQuery := ""
								_oSQL:_sQuery += "SELECT count (*)"
								_oSQL:_sQuery +=  " FROM " + RetSQLName ("SB1") + " SB1"
								_oSQL:_sQuery += " WHERE SB1.D_E_L_E_T_ = ''"
								_oSQL:_sQuery +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
								_oSQL:_sQuery +=   " AND SB1.B1_TIPO    BETWEEN '" + _sTpPrdIni + "' AND '" + _sTpPrdFim + "'"
								_oSQL:_sQuery +=   " AND SB1.B1_COD     BETWEEN '" + _sProdIni  + "' AND '" + _sProdFim  + "'"
								_oSQL:_sQuery +=   " AND SB1.B1_CODLIN  BETWEEN '" + _sLComIni  + "' AND '" + _sLComFim  + "'"
								_oSQL:_sQuery +=   " AND EXISTS (SELECT *"  // Quero conat somente itens que tenham estrutura.
								_oSQL:_sQuery +=                 " FROM " + RetSQLName ("SG1") + " SG1"
								_oSQL:_sQuery +=                " WHERE SG1.D_E_L_E_T_ = ''"
								_oSQL:_sQuery +=                  " AND SG1.G1_FILIAL  = '" + xfilial ("SG1") + "'"
								_oSQL:_sQuery +=                  " AND SG1.G1_COD     = SB1.B1_COD)"
								_oSQL:Log ('[' + procname () + ']')
								if _oSQL:RetQry (1, .f.) > 10
									_SomaErro ("A selecao feita buscaria " + cvaltochar (_oSQL:_xRetQry) + " produtos, um processamento muito grande. Mude a selecao de modo a retornar menos produtos.")
								endif
							endif
							if empty (_sErroWS)
								U_GravaSX1 ('VA_CCR2', '01', U_TamFixo (_sProdIni,  tamsx3 ("B1_COD")[1]))
								U_GravaSX1 ('VA_CCR2', '02', U_TamFixo (_sProdFim,  tamsx3 ("B1_COD")[1]))
								U_GravaSX1 ('VA_CCR2', '03', U_TamFixo (_sTpPrdIni, tamsx3 ("B1_TIPO")[1]))
								U_GravaSX1 ('VA_CCR2', '04', U_TamFixo (_sTpPrdFim, tamsx3 ("B1_TIPO")[1]))
								U_GravaSX1 ('VA_CCR2', '05', 1)  // 1=apenas pais ativos; 2=todos
								U_GravaSX1 ('VA_CCR2', '06', U_TamFixo (_sLComIni,  tamsx3 ("B1_CODLIN")[1]))
								U_GravaSX1 ('VA_CCR2', '07', U_TamFixo (_sLComFim,  tamsx3 ("B1_CODLIN")[1]))
								_sMsgRetWS += u_va_ccr2 (.t., .t.)
							endif
							return


// --------------------------------------------------------------------------
// Acrescenta na string de retorno de erros uma nova mensagem (se ainda nao contiver)
static function _SomaErro (_sMsg)
	local _sMsgAux := alltrim (cvaltochar (_sMsg))
	if ! _sMsgAux $ _sErroWS
		_sErroWS += iif (empty (_sErroWS), '', '; ') + _sMsgAux
	endif
return


// --------------------------------------------------------------------------
// Testes Robert
static function _TstRobert ()
	U_Log2 ('debug', '[' + procname () + ']porta: ' + cvaltochar (GetServerPort ()) + ']Cozinhando um pouco...')
	sleep (20000)
	U_Log2 ('debug', '[' + procname () + ']porta: ' + cvaltochar (GetServerPort ()) + ']Liberando')
return


// --------------------------------------------------------------------------
// Inclui solicitação de manutenção
static function _IncManut()
	local _sFilial   	:= ""
	local _sCodBem   	:= ""
	local _sNomeBem  	:= ""
	local _sCC       	:= ""
	local _sData     	:= ""
	local _sHora     	:= ""
	local _sUsuario  	:= ""
	local _sRamal    	:= ""
	local _sSituacao 	:= ""
	local _sServico  	:= ""
	local _sTpServ   	:= ""
	local _sNomeServ 	:= ""
	local _sCodSolic 	:= ""
	local _sNomeSolic  	:= ""
	local _sEmailSolic 	:= ""
	local _sBemParado  	:= ""
	local _sOrigem      := ""
	local _sErroWS      := ""
	local _aSolic		:= {}

	u_logIni ()

	If empty(_sErroWS)

		_sFilial   	:= _ExtraiTag ("_oXML:_WSAlianca:_Filial"			, .T., .F.)
		_sCodBem   	:= _ExtraiTag ("_oXML:_WSAlianca:_CodBem"			, .T., .F.)
		_sNomeBem  	:= _ExtraiTag ("_oXML:_WSAlianca:_NomeBem"			, .T., .F.)
		_sCC       	:= _ExtraiTag ("_oXML:_WSAlianca:_CentroCusto"		, .T., .F.)
		_sData     	:= _ExtraiTag ("_oXML:_WSAlianca:_DataAbertura"		, .T., .F.)
		_sHora     	:= _ExtraiTag ("_oXML:_WSAlianca:_HoraAbertura"		, .T., .F.)
		_sUsuario  	:= _ExtraiTag ("_oXML:_WSAlianca:_Usuario"			, .T., .F.)
		_sRamal    	:= _ExtraiTag ("_oXML:_WSAlianca:_Ramal"			, .T., .F.)
		_sSituacao 	:= _ExtraiTag ("_oXML:_WSAlianca:_Situacao"			, .T., .F.)
		_sServico  	:= _ExtraiTag ("_oXML:_WSAlianca:_ServicoAExecutar"	, .T., .F.)
		_sTpServ   	:= _ExtraiTag ("_oXML:_WSAlianca:_TipoServico"		, .T., .F.)
		_sNomeServ 	:= _ExtraiTag ("_oXML:_WSAlianca:_NomeServico"		, .T., .F.)
		_sCodSolic 	:= _ExtraiTag ("_oXML:_WSAlianca:_CodSolicitante"	, .T., .F.)
		_sNomeSolic := _ExtraiTag ("_oXML:_WSAlianca:_NomeSolicitante"	, .T., .F.)
		_sEmailSolic:= _ExtraiTag ("_oXML:_WSAlianca:_EmailSolicitante"	, .T., .F.)
		_sBemParado := _ExtraiTag ("_oXML:_WSAlianca:_BemParado"		, .T., .F.)
		_sOrigem    := _ExtraiTag ("_oXML:_WSAlianca:_Origem"			, .T., .F.)

	endif

	If empty(_sErroWS)

		_aSolic := {{"TQB_FILIAL", _sFilial		,Nil},;
			{"TQB_CODBEM", _sCodBem		,Nil},;
			{"TQB_CCUSTO", _sCC			,Nil},;
			{"TQB_DTABER", date()		,Nil},;
			{"TQB_HOABER", _sHora		,Nil},;
			{"TQB_USUARI", _sUsuario	,Nil},;
			{"TQB_RAMAL ", _sRamal		,Nil},;
			{"TQB_SOLUCA", _sSituacao	,Nil},;
			{"TQB_DESCSS", _sServico	,Nil},;
			{"TQB_CDSERV", _sTpServ		,Nil},;
			{"TQB_NMSERV", _sNomeServ	,Nil},;
			{"TQB_CDSOLI", _sCodSolic	,Nil},;
			{"TQB_EMSOLI", _sEmailSolic ,Nil},;
			{"TQB_ORIGEM", _sOrigem		,Nil},;
			{"TQB_PARADA", _sBemParado	,Nil} }

		Private lMSHelpAuto := .t. // Nao apresenta erro em tela
		Private lMSErroAuto := .f. // Caso a variavel torne-se .T. apos MsExecAuto, apresenta erro em tela

		MSExecAuto( {|x,z,y,w| MNTA280(x,z,y,w)}, , , _aSolic )

		If lMsErroAuto
			_sMsgRetWS	+= memoread (NomeAutoLog())
		else
			_sMsgRetWS	+= 'Registro gravado com sucesso!'
		Endif

	endif

	u_logFim ()
return

// --------------------------------------------------------------------------
// Extrair tag do XML original
static function _ExtraiTag (_sTag, _lObrig, _lValData)
	local _sRet    := ""
	local _lDataOK := .T.
	local _nPos    := 0

//	U_Log2 ('debug', '[' + procname () + ']Tentando ler a tag ' + _sTag)
//	U_Log2 ('debug', '[' + procname () + ']Type:' + type (_sTag))
	if type (_sTag) != "O"
		if _lObrig
			_SomaErro ("XML invalido: Tag '" + _sTag + "' nao encontrada.")
		endif
	else
		_sRet = &(_sTag + ":TEXT")
//		U_Log2 ('debug', '[' + procname () + ']Li a tag ' + _sTag + ' e obtive: ' + _sRet)
		if empty (_sRet) .and. _lObrig
			_SomaErro ("XML invalido: valor da tag '" + _sTag + "' deve ser informado.")
		endif
		if _lValData  // Preciso validar formato da data
			if ! empty (_sRet)
				if len (_sRet) != 8
					_lDataOK = .F.
				else
					for _nPos = 1 to len (_sRet)
						if ! IsDigit (substr (_sRet, _nPos, 1))
							_lDataOK = .F.
							exit
						endif
					next
				endif
				if ! _lDataOK
					_SomaErro ("Data deve ser informada no formato AAAAMMDD")
				endif
			endif
		endif
	endif
return _sRet

// --------------------------------------------------------------------------
// Grava Titulo referente a unimed - associados
Static Function _GrvTituloUnimed()
	local _oCtaCorr := NIL
	local _sUsuario := ""
	local _sFilial  := ""
	local _sFornece := ""
	local _sLoja    := ""
	local _sDtEmi   := ""
	local _sDtVenc  := ""
	local _sOBS     := ""

	u_logIni ()

	/* 	<WSAlianca>
			<User>daiana.ribas</User>
			<IDAplicacao>gg2gj256y5f2c5b89</IDAplicacao>
			<Empresa>01</Empresa>
			<Filial>07</Filial>
			<Fornecedor>002382</Fornecedor>
			<Loja>01</Loja>
			<Sequencial>02</Sequencial>
			<MesReferencia>032023</MesReferencia>
			<DtEmissao>20230824</DtEmissao>
			<DtVencimento>20230831</DtVencimento>
			<Valor>394,43</Valor>
			<OBs>UNIMED 03/2023 - ADELAR PARISOTTO</OBs>
			<Acao>GravaTituloPgUnimed</Acao>
		</WSAlianca> */
		
	If empty(_sErroWS)
		_sUsuario   := _ExtraiTag ("_oXML:_WSAlianca:_User"				, .T., .F.)
		_sFilial   	:= _ExtraiTag ("_oXML:_WSAlianca:_Filial"			, .T., .F.)
		_sFornece   := _ExtraiTag ("_oXML:_WSAlianca:_Fornecedor"		, .T., .F.)
		_sLoja  	:= _ExtraiTag ("_oXML:_WSAlianca:_Loja"				, .T., .F.)
		_sSeq       := _ExtraiTag ("_oXML:_WSAlianca:_Sequencial"		, .T., .F.)
		_sDtEmi     := _ExtraiTag ("_oXML:_WSAlianca:_DtEmissao"		, .T., .F.)
		_sDtVenc    := _ExtraiTag ("_oXML:_WSAlianca:_DtVencimento"		, .T., .F.)
		_sOBS     	:= _ExtraiTag ("_oXML:_WSAlianca:_OBs"				, .T., .F.)
		_sMesRef  	:= _ExtraiTag ("_oXML:_WSAlianca:_MesReferencia"	, .T., .F.)
		_nValor     := Val(StrTran(_ExtraiTag ("_oXML:_WSAlianca:_Valor", .T., .F.),",","."))

		_sNumero 	:= alltrim(_sMesRef) + alltrim(_sSeq)
	EndIf

	If empty(_sErroWS)

		_oCtaCorr:= ClsCtaCorr():New ()
		_oCtaCorr:Assoc    = _sFornece
		_oCtaCorr:Loja     = _sLoja
		_oCtaCorr:TM       = '29'
		_oCtaCorr:DtMovto  = stod(_sDtEmi)
		_oCtaCorr:VctoSE2  = stod(_sDtVenc)
		_oCtaCorr:Valor    = _nValor
		_oCtaCorr:SaldoAtu = _nValor
		_oCtaCorr:Usuario  = _sUsuario
		_oCtaCorr:Histor   = _sOBS
		_oCtaCorr:MesRef   = _sMesRef
		_oCtaCorr:Doc      = _sNumero
		_oCtaCorr:Serie    = 'UNJ'
		_oCtaCorr:Origem   = "NAWEB"
		_oCtaCorr:Parcela  = ''

		if _oCtaCorr:PodeIncl ()
			if ! _oCtaCorr:Grava (.F., .F.)
				_sErroWS   += 'Titulo Nº ' + _sNumero + ' não gravado!' + _oCtaCorr:UltMsg
			else
				if empty(_sErroWS)
					_sMsgRetWS += 'Titulo Nº ' + _sNumero + ' gravado com sucesso!' + _oCtaCorr:UltMsg
				endif
			endif
		else
			_sErroWS   += "Atualização da conta corrente para o associado '" + _sFornece + '/' + _sLoja + "'" + " não permitido. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg
		endif
	EndIf

	u_logFim ()
Return

// --------------------------------------------------------------------------
// Grava baixas de títulos no conta corrente - associados
Static Function _GrvPgtoContaCorrente()
	local _oCtaCorr := NIL
	local _sUsuario := ""
	local _sFilial  := ""
	local _sFornece := ""
	local _sLoja    := ""
	local _sDtEmi   := ""
	local _sDtVenc  := ""
	local _sOBS     := ""

	u_logIni ()

	/* 	<WSAlianca>
			<User>daiana.ribas</User>
			<IDAplicacao>gg2gj256y5f2c5b89</IDAplicacao>
			<Empresa>01</Empresa>
			<Filial>07</Filial>
			<Fornecedor>002382</Fornecedor>
			<Loja>01</Loja>
			<Sequencial>02</Sequencial>
			<Parcela>A</Parcela>
			<TipoMovimento>29</TipoMovimento>
			<MesReferencia>032023</MesReferencia>
			<DtEmissao>20230824</DtEmissao>
			<DtVencimento>20230831</DtVencimento>
			<Valor>394,43</Valor>
			<OBs>NOME DO TIPO DE MOVIMENTO + MES E ANO DE REFERENCIA + NOME DO ASSOCIADO</OBs>
			<TipoPrograma>1</TipoPrograma>
			<Acao>GravaPgtoContaCorrente</Acao>
		</WSAlianca> 
		
		TipoPrograma : 
		* 1 - Unimed
		* 2 - Analises
		*/
		
	If empty(_sErroWS)
		_sUsuario   := _ExtraiTag ("_oXML:_WSAlianca:_User"				, .T., .F.)
		_sFilial   	:= _ExtraiTag ("_oXML:_WSAlianca:_Filial"			, .T., .F.)
		_sFornece   := _ExtraiTag ("_oXML:_WSAlianca:_Fornecedor"		, .T., .F.)
		_sLoja  	:= _ExtraiTag ("_oXML:_WSAlianca:_Loja"				, .T., .F.)
		if alltrim(_sTipoPrg) == '1'
			_sSeq       := _ExtraiTag ("_oXML:_WSAlianca:_Sequencial"		, .T., .F.)
			_sTpMov     := '29'
			_sParcela   := ''
			_sSerie     := 'UNJ'
		else
			_sSeq       := ''
			_sParcela   := _ExtraiTag ("_oXML:_WSAlianca:_Parcela"			, .T., .F.)
			_sTpMov     := _ExtraiTag ("_oXML:_WSAlianca:_TipoMovimento"	, .T., .F.)
			_sSerie     := 'ANS'
		endif
		_sMesRef  	:= _ExtraiTag ("_oXML:_WSAlianca:_MesReferencia"	, .T., .F.)
		_sDtEmi     := _ExtraiTag ("_oXML:_WSAlianca:_DtEmissao"		, .T., .F.)
		_sDtVenc    := _ExtraiTag ("_oXML:_WSAlianca:_DtVencimento"		, .T., .F.)
		_sOBS     	:= _ExtraiTag ("_oXML:_WSAlianca:_OBs"				, .T., .F.)
		_sTipoPrg  	:= _ExtraiTag ("_oXML:_WSAlianca:_TipoPrograma"		, .T., .F.)
		
		_nValor     := Val(StrTran(_ExtraiTag ("_oXML:_WSAlianca:_Valor", .T., .F.),",","."))
		
		If alltrim(_sTipoPrg) == '1'
			_sNumero := alltrim(_sMesRef) + alltrim(_sSeq)
		Else
			_sNumero := Day2Str(date()) + Month2Str(Date()) + Year2Str(Date())
		EndIf		
	EndIf

	If empty(_sErroWS)
		_oCtaCorr:= ClsCtaCorr():New ()
		_oCtaCorr:Assoc    = _sFornece
		_oCtaCorr:Loja     = _sLoja
		_oCtaCorr:TM       = _sTpMov
		_oCtaCorr:DtMovto  = stod(_sDtEmi)
		_oCtaCorr:VctoSE2  = stod(_sDtVenc)
		_oCtaCorr:Valor    = _nValor
		_oCtaCorr:SaldoAtu = _nValor
		_oCtaCorr:Usuario  = _sUsuario
		_oCtaCorr:Histor   = _sOBS
		_oCtaCorr:MesRef   = _sMesRef
		_oCtaCorr:Doc      = _sNumero
		_oCtaCorr:Serie    = _sSerie
		_oCtaCorr:Origem   = "NAWEB"
		_oCtaCorr:Parcela  = _sParcela

		if _oCtaCorr:PodeIncl ()
			if ! _oCtaCorr:Grava (.F., .F.)
				_sErroWS   += 'Titulo Nº ' + _sNumero + ' não gravado!' + _oCtaCorr:UltMsg
			else
				if empty(_sErroWS)
					_sMsgRetWS += 'Titulo Nº ' + _sNumero + ' gravado com sucesso!' + _oCtaCorr:UltMsg
				endif
			endif
		else
			_sErroWS   += "Atualização da conta corrente para o associado '" + _sFornece + '/' + _sLoja + "'" + " não permitido. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg
		endif
	EndIf

	u_logFim ()
Return
