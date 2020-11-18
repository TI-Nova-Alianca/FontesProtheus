// Programa:  WS_Alianca
// Autor:     Robert Koch (royalties: http://advploracle.blogspot.com.br/2014/09/webservice-no-protheus-parte-2-montando.html)
// Data:      14/07/2017
// Descricao: Disponibilizacao de Web Services em geral.
//
// Historico de alteracoes:
// ??/08/2017 - Julio   - Implementda gravacao do arquico ZAM
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
// 11/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 - Comentariada a rotina _ExportTbl ()
// 01/04/2020 - Robert  - Criado tratamento para tag FiltroAppend na rotina AtuEstru.
// 13/07/2020 - Robert  - Inseridas tags para catalogacao de fontes.
// 10/08/2020 - Robert  - Inseridas chamadas da funcao UsoRot().
// 18/11/2020 - Sandra/Robert  - Alteração campo A1_GRPTRIB DE 002 para 003

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #web_service
// #PalavasChave      #web_service #generico #integracoes #naweb
// #TabelasPrincipais #SD1 #SD2 #SD3
// #Modulos           
//

// ----------------------------------------------------------------------------------------------------------
#INCLUDE "APWEBSRV.CH"
#INCLUDE "PROTHEUS.CH"
#include "tbiconn.ch"

// Estrutura de retorno de dados
WSSTRUCT RetornoWS
	WSDATA Resultado AS String
	WSDATA Mensagens AS String OPTIONAL
ENDWSSTRUCT

// --------------------------------------------------------------------------
// WebService
WSSERVICE WS_Alianca DESCRIPTION "Nova Alianca - Executa atualizacoes diversas"
	WSDATA XmlRcv  AS string
	WSDATA Retorno AS RetornoWS

	WSMETHOD IntegraWS DESCRIPTION "Executa integracoes conforme tags do XML."
ENDWSSERVICE

// --------------------------------------------------------------------------
WSMETHOD IntegraWS WSRECEIVE XmlRcv WSSEND Retorno WSSERVICE WS_Alianca
	local _sError    := ""
	local _sWarning  := ""
	local _aUsuario  := {}  // Guarda dados de identificacao do usuario.
	local _sArqLog2  := ''
	local _sArqLgOld := ''
	private __cUserId  := ''
	private cUserName  := ''
	private _sWS_Empr  := ""
	private _sWS_Filia := ""
	private _oXML      := NIL
	private _sErros    := ""
	private _sMsgRetWS := ""
	private _sAcao     := ""
	private _sArqLog   := GetClassName (::Self) + "_" + dtos (date ()) + ".log"

	//WSDLDbgLevel(2)  // Ativa dados para debug no arquivo console.log
	set century on

	// Alimenta coluna de observacoes no monitor do sistema.
	PtInternal (1, 'WS_Alianca')

	// Validacoes gerais e extracoes de dados basicos.
	U_ValReqWS (GetClassName (::Self), ::XmlRcv, @_sErros, @_sWS_Empr, @_sWS_Filia, @_sAcao)
//	u_log2 ('DEBUG', 'Apos ValReqWS tenho _sWS_Filia = ' + _sWS_Filia)
	if empty (_sErros)
		_aUsuario = {__cUserId, cUserName}  // Guarda para uso posterior, pois o PREPARE ENVIRONMENT limpa essas variaveis.
	endif

	// Prepara o ambiente conforme empresa e filial solicitadas.
	if empty (_sErros)
		prepare environment empresa _sWS_Empr filial _sWS_Filia
		private __RelDir  := "c:\temp\spool_protheus\"
		set century on
	endif
	if empty (_sErros) .and. cFilAnt != _sWS_Filia
		u_log2 ('erro', 'Nao consegui acessar a filial solicitada.')
		_sErros += "Nao foi possivel acessar a filial '" + _sWS_Filia + "' conforme solicitado."
	endif
	if empty (_sErros)
		__cUserId = _aUsuario [1]
		cUserName = _aUsuario [2]
		//u_log ('setei cUserName=', cusername)
	endif

	// Converte novamente a string recebida para XML, pois a criacao do ambiente parece apagar o XML.
	// Nao vou tratar erros do parser pois teoricamente jah foram tratados na funcao VarReqWS
	if empty (_sErros)
		_oXML := XmlParser(::XmlRcv, "_", @_sError, @_sWarning)
	endif

	// Faz a 'migracao' para outro arquivo de log, para nao misturar processos de diferentes usuarios.
	if empty (_sErros)
		//u_log ('vou mudar arqlog com cUserName=', cusername)
		_sArqLgOld = _sArqLog
		_sArqLog2 = 'WS_Alianca_' + cUserName + "_" + dtos (date ()) + ".log"
		u_log2 ('info', 'Log da thread ' + cValToChar (ThreadID ()) + ' prossegue em outro arquivo: ' + _sArqLog2)
		_sArqLog = _sArqLog2
		u_log2 ('info', '')
		u_log2 ('info', '')
		u_log2 ('info', '###############################################################################################')
		u_log2 ('info', '...continuacao de log da thread ' + cValToChar (ThreadID ()) + ' (gerado por chamada de web service)')
		u_log2 ('info', '')
	endif

	// Executa a acao especificada no XML.
	if empty (_sErros)
		u_log2 ('info', 'Acao solicitada ao web service: ' + _sAcao)
		PtInternal (1, _sAcao)
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
			// nunca consegui fazer funcionar ---> case _sAcao == 'Executar'
			// nunca consegui fazer funcionar ---> _Exec ()
			case _sAcao == 'RefazSaldoAtual'
			_SaldoAtu ()
			case _sAcao == 'AtuEstru'
			_AtuEstru ()
			case _sAcao == 'TransfEstqInsere'
			_TrEstq ('I')
			case _sAcao == 'TransfEstqAutoriza'
			_TrEstq ('A')
			case _sAcao == 'TransfEstqDeleta'
			_TrEstq ('D')
			case _sAcao == 'OndeSeUsa'
			_OndeSeUsa ()
			case _sAcao == 'IncluiCliente'
			_IncCli ()
			case _sAcao == 'AlteraCliente'
			_AltCli ()
			case _sAcao == 'IncluiEvento'
			_IncEvt ()
			case _sAcao == 'IncluiProduto'
			_IncProd ()
			case _sAcao == 'ConsultaDeOrcamentos'
			_ExecConsOrc ()
			case _sAcao == 'IncluiCargaSafra'
			_IncCarSaf ()
			case _sAcao == 'RetTicketCargaSafra'
			_RTkCarSaf ()
			case _sAcao == 'ConsultaKardex'
			_ExecKardex ()
			case _sAcao == 'MonitorProtheus'
			_MonitProt ()
			otherwise
			_sErros += "A acao especificada no XML eh invalida: " + _sAcao
		endcase
		U_UsoRot ('F', _sAcao, '')
	else
		u_log2 ('erro', _sErros)
	endif

	// Cria a instância de retorno
	::Retorno := WSClassNew ("RetornoWS")
	::Retorno:Resultado = iif (empty (_sErros), "OK", "ERRO")
	::Retorno:Mensagens = _sErros + _sMsgRetWS
	u_log2 ('info', '::Retorno:Resultado = ' + ::Retorno:Resultado)
	u_log2 ('info', '::Retorno:Mensagens = ' + ::Retorno:Mensagens)

	// Volta log para o nome original, apenas para 'fechar' a tag de inicio de execucao
	_sArqLog = _sArqLgOld
	u_log2 ('debug', 'Retornando web service com o seguinte resultado: ' + ::Retorno:Resultado)

	// Encerra ambiente. Ficou um pouco mais lento, mas resolveu problema que estava dando de, a cada execucao, trazer um cFilAnt diferente. Robert, 09/01/2020.
	// dica em: https://centraldeatendimento.totvs.com/hc/pt-br/articles/360027855031-MP-ADVPL-FINAL-GERA-EXCE%C3%87%C3%83O
	RPCClearEnv ()

Return .T.



// --------------------------------------------------------------------------
// Atualiza a estrutura de uma tabela (drop + chkfile + append)
static function _AtuEstru ()
	local   _sTabela   := ""
	local   _sFilAppen := ''
	private _sErroAuto := ""  // Variavel alimentada pela funcao U_Help

	u_logIni ()
	if empty (_sErros)
		_sTabela   = _ExtraiTag ("_oXML:_WSAlianca:_Tabela", .T., .F.)
		_sFilAppen = _ExtraiTag ("_oXML:_WSAlianca:_FiltroAppend", .F., .F.)
	endif

	if empty (_sErros)
		u_log ('Tabela:', _sTabela)
		if ! U_AtuEstru (_sTabela, _sFilAppen)
			_sErros = _sErroAuto
		else
			_sMsgRetWS = _sErroAuto
		endif
	endif

	u_logFim ()
Return


/*
// --------------------------------------------------------------------------
static function _ExtraiTag (_sTag, _lObrig)
	local _sRet := ""
	//u_logIni ()
	//u_log ('Procurando tag', _sTag)
	if type (_sTag) != "O"
		if _lObrig
			_sErros += "XML invalido: Tag '" + _sTag + "' nao encontrada."
		endif
	else
		_sRet = &(_sTag + ":TEXT")
	endif
	//u_log ('_sRet = ', _sRet)
	//u_logFim ()
return _sRet
*/
// --------------------------------------------------------------------------
static function _ExtraiTag (_sTag, _lObrig, _lValData)
	local _sRet    := ""
	local _lDataOK := .T.
	local _nPos    := 0
	//u_logIni ()
	//u_log ('Procurando tag', _sTag)
	if type (_sTag) != "O"
		if _lObrig
			_sErros += "XML invalido: Tag '" + _sTag + "' nao encontrada."
		endif
	else
		_sRet = &(_sTag + ":TEXT")
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
					_sErros += "Data deve ser informada no formato AAAAMMDD"
				endif
			endif
		endif
	endif
	//u_log ('_sRet = ', _sRet)
	//u_logFim ()
return _sRet


// --------------------------------------------------------------------------
static function _ExecBatch ()
	local _sSeqBatch := ""
	private _oBatch    := ClsBatch ():New ()

	u_logIni ()
	_sSeqBatch = _ExtraiTag ("_oXML:_WSAlianca:_Sequencia", .T., .F.)

	if empty (_sErros)
		zz6 -> (dbsetorder (1))  // ZZ6_FILIAL+ZZ6_SEQ
		if ! zz6 -> (dbseek (xfilial ("ZZ6") + _sSeqBatch, .F.))
			_sErros += "Sequencia nao localizada na tabela ZZ6"
		else
			_oBatch := ClsBatch ():New (zz6 -> (recno ()))
			if ! _sWS_Filia $ _oBatch:FilDes
				_sErros += "Batch nao se destina a esta filial."
			else
				_oBatch:Executa ()
				// u_log ('Retorno do batch:', _oBatch:Retorno)
			endif
		endif
	endif

	if _oBatch:Retorno == 'N'
		_sErros += "Batch nao executado" + ' ' + _oBatch:Mensagens
	endif
	_sMsgRetWS += _oBatch:Comando + ' ' + _oBatch:Mensagens

	u_logFim ()
Return

/* nunca consegui fazer funcionar
// --------------------------------------------------------------------------
static function _Exec ()
	local _sRotina  := ""
	local _sGrpPerg := ""
	local _nPerg    := 0
	local _sResp    := ''
	local _sTipo    := ''

	// u_logIni ()
	_sRotina  = alltrim (_ExtraiTag ("_oXML:_WSAlianca:_Rotina", .T., .F.))
	_sGrpPerg = _ExtraiTag ("_oXML:_WSAlianca:_GrpPerg", .T., .F.)

	if empty (_sErros) .and. right (_sRotina, 1) != ')'
		_sErros += "Rotina a ser chamada deve finalizar por )"
	endif

	// Leitura das perguntas em loop, pois nao sei quantas serao recebidas.
	if empty (_sErros)
		_nPerg = 1
		do while .T.
			_sTipo = _ExtraiTag ("_oXML:_WSAlianca:_TipoParam" + strzero (_nPerg, 2), .F., .F.)
			_sResp = _ExtraiTag ("_oXML:_WSAlianca:_RespParam" + strzero (_nPerg, 2), .F., .F.)
			if ! empty (_sTipo) .and. ! empty (_sResp)
				// Converte tipo de dado, caso necessario.
				if _sTipo == "D"
					_sResp = stod (_sResp)
				elseif _sTipo == "N"
					_sResp = val (_sResp)
				endif
				U_GravaSX1 (_sGrpPerg, strzero (_nPerg, 2), _sResp)
			else
				exit
			endif
		enddo
		(&_sComando)
	endif
	_sMsgRetWS += _oBatch:Comando + ' ' + _oBatch:Mensagens

	// u_logFim ()
Return
*/


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

	if empty (_sErros) .and. empty (cUserName)
		_sErros += "Usuario nao identificado."
	endif

	if empty (_sErros)
		_sTipoInsp = _ExtraiTag ("_oXML:_WSAlianca:_TipoInspecao", .T., .F.)
		_sProduto  = _ExtraiTag ("_oXML:_WSAlianca:_Produto",      .T., .F.)
		_sResult   = _ExtraiTag ("_oXML:_WSAlianca:_Resultado",    .T., .F.)
		_sLote     = _ExtraiTag ("_oXML:_WSAlianca:_Lote",         (_sTipoInsp == 'Lote'), .F.)
		_sNF       = _ExtraiTag ("_oXML:_WSAlianca:_NF",           (_sTipoInsp == 'NF'), .F.)
		_sSerie    = _ExtraiTag ("_oXML:_WSAlianca:_Serie",        (_sTipoInsp == 'NF'), .F.)
		_sFornece  = _ExtraiTag ("_oXML:_WSAlianca:_Fornecedor",   (_sTipoInsp == 'NF'), .F.)
		_sLoja     = _ExtraiTag ("_oXML:_WSAlianca:_Loja",         (_sTipoInsp == 'NF'), .F.)
	endif

	if empty (_sErros) .and. _sTipoInsp == 'NF'
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
			_sErros += "Nao foi encontrada NF de entrada com os parametros informados " + _oSQL:_sQuery
		endif
	endif
	if empty (_sErros)
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

// --------------------------------------------------------------------------
static function _RastLt ()
	local _sProduto  := ""
	local _sLote     := ""
	local _sMapa     := ""
	local _oSQL      := NIL
	local _sChave    := ""

	// u_logIni ()
	if empty (_sErros)
		_sProduto  = _ExtraiTag ("_oXML:_WSAlianca:_Produto", .T., .F.)
		_sLote     = _ExtraiTag ("_oXML:_WSAlianca:_Lote", .T., .F.)
	endif

	if empty (_sErros)
		_sMapa = U_RastLt (_sWS_Filia, _sProduto, _sLote, 0, NIL)
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
			_sErros += "Erro na gravacao: " + _oSQL:_sQuery
		endif
	endif

	// u_logFim ()
Return

// --------------------------------------------------------------------------
// Recalculo do saldo atual em estoque
static function _SaldoAtu ()
	local _sProduto  := ""
	local _sPerg     := ""
	local _oSQL      := NIL
	local _sUltExec  := ""

	//u_logIni ()
	if empty (_sErros)
		_sProduto  = _ExtraiTag ("_oXML:_WSAlianca:_Produto", .T., .F.)
	endif

	if empty (_sErros)

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
		u_log ("Iniciando MATA300 (refaz saldo atual)")
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
			_sErros += "Erro no processo"
		else
			_sMsgRetWS = _sUltExec
		endif
	endif

	//u_logFim ()
Return

// --------------------------------------------------------------------------
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
//	local _sMSG    := ""

	u_logIni ()

	if empty (_sErros) .and. empty (cUserName)
		_sErros += "Usuario nao identificado."
	endif

	if empty (_sErros)
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

	if empty (_sErros) .and. _sIAE <> "E"
		if empty(_sFILIAL)
			_sErros += "Filial invalida."
		endif

		if empty(_sDATAPT) .or. (StoD(_sDATAPT) > date())
			_sErros += "Data do Apontamento invalida."
		endif

		SN1 -> (dbsetorder (1))
		if empty(_sMAQCOD) .or. ! SN1 -> (dbseek (_sFILIAL + AllTrim(_sMAQCOD), .F.))
			_sErros += "Maquina invalida."
		endif

		if empty(_sDATINI) .or. (StoD(_sDATINI) > date())
			_sErros += "Data Inicial invalida."
		endif

		if empty(_sHORINI)
			_sErros += "Hora Inicial invalida."
		endif

		if empty(_sDATFIM) .or. (StoD(_sDATFIM) > date())
			_sErros += "Data Final invalida."
		endif

		if empty(_sHORFIM)
			_sErros += "Hora Final invalida."
		endif

		if (AllTrim(_sDATINI) + AllTrim(_sHORINI)) > (DtoS(date()) + SubStr(time(),1,5))
			_sErros += "Data Inicial nao pode ser maior do que hoje."
		endif

		if (AllTrim(_sDATFIM) + AllTrim(_sHORFIM)) > (DtoS(date()) + SubStr(time(),1,5))
			_sErros += "Data Final nao pode ser maior do que hoje."
		endif

		//if (AllTrim(_sDATINI) + AllTrim(_sHORINI) > AllTrim(_sDATFIM) + AllTrim(_sHORFIM)) .and. .not. Empty(_sDATFIM)
		//	_sErros += "Periodo invalido."
		//endif

		//if empty(_sTEMPO) .and. .not. Empty(_sDATFIM)
		//	_sErros += "Tempo invalido."
		//endif

		if .not. empty(AllTrim(_sTIPCOD)) .and. ! U_ExistZX5("45", _sTIPCOD)
			_sErros += "Tipo invalido."
		endif

		if empty(_sUSUCOD)
			_sErros += "Usuario invalido."
		endif
	endif

	if empty (_sErros)
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
				_sErros += "Evento ja cadastrado."
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
				_sErros += "Evento nao cadastrado."
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
				_sErros += "Evento nao cadastrado."
			endif
		endif
	endif

	u_logFim ()
Return

// --------------------------------------------------------------------------
// Interface para incluir eventos genericos
static function _IncEvt ()
	local _oEvento := NIL
	local _dDtEvt  := ''
	u_logIni ()
	_oEvento := ClsEvent ():New ()
	_oEvento:Filial  = cFilAnt
	if empty (_sErros) ; _dDtEvt = _ExtraiTag ("_oXML:_WSAlianca:_DataEvento", .F., .T.) ; endif
	if empty (_sErros)
		if empty (_dDtEvt)
			_oEvento:DtEvento = date ()
		else
			if len (_dDtEvt) != 8
				_sErros += "Data do evento deve ser informada no formato AAAAMMDD"
			else
				_oEvento:DtEvento = stod (_dDtEvt)
			endif
		endif
	endif
	if empty (_sErros) ; _oEvento:HrEvento   = _ExtraiTag ("_oXML:_WSAlianca:_HoraEvento", .F., .F.) ;   endif
	if empty (_sErros)
		if empty (_oEvento:HrEvento)
			_oEvento:HrEvento = time ()
		else
			if len (_oEvento:HrEvento) != 8 .or. substr (_oEvento:HrEvento, 3, 1) != ':' .or. substr (_oEvento:HrEvento, 6, 1) != ':'
				_sErros += "Hora do evento deve ser informada no formato HH:MM:SS"
			endif
		endif
	endif
	if empty (_sErros) ; _oEvento:CodEven    = _ExtraiTag ("_oXML:_WSAlianca:_CodigoEvento",     .T., .F.) ;   endif
	if empty (_sErros) ; _oEvento:Texto      = _ExtraiTag ("_oXML:_WSAlianca:_Texto",            .T., .F.) ;   endif
	if empty (_sErros) ; _oEvento:NFSaida    = _ExtraiTag ("_oXML:_WSAlianca:_NFSaida",          .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:SerieSaid  = _ExtraiTag ("_oXML:_WSAlianca:_SerieNFSaida",     .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:ParcTit    = _ExtraiTag ("_oXML:_WSAlianca:_ParcelaTitulo",    .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:NFEntrada  = _ExtraiTag ("_oXML:_WSAlianca:_NFEntrada",        .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:SerieEntr  = _ExtraiTag ("_oXML:_WSAlianca:_SerieNFEntrada",   .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:Produto    = _ExtraiTag ("_oXML:_WSAlianca:_Produto",          .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:PedVenda   = _ExtraiTag ("_oXML:_WSAlianca:_PedidoVenda",      .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:Cliente    = _ExtraiTag ("_oXML:_WSAlianca:_Cliente",          .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:LojaCli    = _ExtraiTag ("_oXML:_WSAlianca:_LojaCliente",      .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:Fornece    = _ExtraiTag ("_oXML:_WSAlianca:_Fornecedor",       .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:LojaFor    = _ExtraiTag ("_oXML:_WSAlianca:_LojaFornecedor",   .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:MailTo     = _ExtraiTag ("_oXML:_WSAlianca:_MailTo",           .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:MailToZZU  = _ExtraiTag ("_oXML:_WSAlianca:_MailToZZU",        .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:Alias      = _ExtraiTag ("_oXML:_WSAlianca:_Alias",            .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:Recno      = val (_ExtraiTag ("_oXML:_WSAlianca:_RecnoAlias",  .F., .F.)) ;   endif
	if empty (_sErros) ; _oEvento:CodAlias   = _ExtraiTag ("_oXML:_WSAlianca:_CodAlias",         .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:Chave      = _ExtraiTag ("_oXML:_WSAlianca:_ChaveAlias",       .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:OP         = _ExtraiTag ("_oXML:_WSAlianca:_OP",               .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:Etiqueta   = _ExtraiTag ("_oXML:_WSAlianca:_Etiqueta",         .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:CodProceda = _ExtraiTag ("_oXML:_WSAlianca:_CodigoProceda",    .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:Transp     = _ExtraiTag ("_oXML:_WSAlianca:_Transportadora",   .F., .F.) ;   endif
	if empty (_sErros) ; _oEvento:TranspReds = _ExtraiTag ("_oXML:_WSAlianca:_TranspRedespacho", .F., .F.) ;   endif
	if empty (_sErros)
		if ! _oEvento:Grava ()
			_sErros += "Erro na gravacao do objeto evento"
		else
			_sMsgRetWS = "Evento gravado com sucesso"
		endif
	endif
	u_logFim ()
Return


// --------------------------------------------------------------------------
// Interface para a classe de transferencias de estoque.
static function _TrEstq (_sQueFazer)
	local _sDocZAG := ""
	local _oTrEstq := NIL

	do case
		case _sQueFazer == 'I'  // Inserir
		_oTrEstq := ClsTrEstq ():New ()
		if empty (_sErros) ; _oTrEstq:FilOrig  = padr (_ExtraiTag ("_oXML:_WSAlianca:_FilialOrigem",    .T., .F.), 2) ;     endif
		if empty (_sErros) ; _oTrEstq:FilDest  = padr (_ExtraiTag ("_oXML:_WSAlianca:_FilialDestino",   .T., .F.), 2) ;    endif
		if empty (_sErros) ; _oTrEstq:ProdOrig = padr (_ExtraiTag ("_oXML:_WSAlianca:_ProdutoOrigem",   .T., .F.), 15) ;   endif
		if empty (_sErros) ; _oTrEstq:ProdDest = padr (_ExtraiTag ("_oXML:_WSAlianca:_ProdutoDestino",  .T., .F.), 15) ;  endif
		if empty (_sErros) ; _oTrEstq:AlmOrig  = padr (_ExtraiTag ("_oXML:_WSAlianca:_AlmoxOrigem",     .T., .F.), 2) ;      endif
		if empty (_sErros) ; _oTrEstq:AlmDest  = padr (_ExtraiTag ("_oXML:_WSAlianca:_AlmoxDestino",    .T., .F.), 2) ;     endif
		if empty (_sErros) ; _oTrEstq:LoteOrig = padr (_ExtraiTag ("_oXML:_WSAlianca:_LoteOrigem",      .T., .F.), 10) ;      endif
		if empty (_sErros) ; _oTrEstq:LoteDest = padr (_ExtraiTag ("_oXML:_WSAlianca:_LoteDestino",     .T., .F.), 10) ;     endif
		if empty (_sErros) ; _oTrEstq:EndOrig  = padr (_ExtraiTag ("_oXML:_WSAlianca:_EnderecoOrigem",  .T., .F.), 15) ;  endif
		if empty (_sErros) ; _oTrEstq:EndDest  = padr (_ExtraiTag ("_oXML:_WSAlianca:_EnderecoDestino", .T., .F.), 15) ; endif
		if empty (_sErros) ; _oTrEstq:QtdSolic = val  (_ExtraiTag ("_oXML:_WSAlianca:_QtdSolic",        .T., .F.)) ;            endif
		if empty (_sErros) ; _oTrEstq:Motivo   =       _ExtraiTag ("_oXML:_WSAlianca:_Motivo",          .T., .F.) ;               endif
		if empty (_sErros) ; _oTrEstq:OP       = padr (_ExtraiTag ("_oXML:_WSAlianca:_OP",              .T., .F.), 14) ;              endif
		if empty (_sErros) ; _oTrEstq:ImprEtq  =       _ExtraiTag ("_oXML:_WSAlianca:_Impressora",      .F., .F.) ;           endif
		if empty (_sErros)
			_oTrEstq:UsrIncl = cUserName
			_oTrEstq:DtEmis  = date ()
			if _oTrEstq:Grava ()
				u_log2 ('INFO', 'Gravou ZAG. ' + _oTrEstq:UltMsg)
				//_sMsgRetWS = "Gravacao realizada." + _oTrEstq:UltMsg
				_sMsgRetWS = _oTrEstq:UltMsg
			else
				u_log2 ('erro', 'Nao gravou ZAG. ' + _oTrEstq:UltMsg)
				_sErros += "Erro na gravacao."
				_sMsgRetWS = _oTrEstq:UltMsg
			endif
		endif

		case _sQueFazer == 'A'  // Autorizar
		if empty (_sErros) ; _sDocZAG = _ExtraiTag ("_oXML:_WSAlianca:_DocTransf", .T., .F.) ; endif
		if empty (_sErros)
			zag -> (dbsetorder (1))  // ZAG_FILIAL+ ZAG_DOC
			if ! zag -> (dbseek (xfilial ("ZAG") + _sDocZAG, .F.))
				_sErros += "Documento '" + _sDocZAG + "' nao localizado na tabela ZAG"
			else
				_oTrEstq := ClsTrEstq ():New (zag -> (recno ()))
				_oTrEstq:Libera ()
				_sMsgRetWS = _oTrEstq:UltMsg
			endif
		endif

		case _sQueFazer == 'D'  // Deletar
		if empty (_sErros) ; _sDocZAG = _ExtraiTag ("_oXML:_WSAlianca:_DocTransf", .T., .F.) ; endif
		if empty (_sErros)
			zag -> (dbsetorder (1))  // ZAG_FILIAL+ ZAG_DOC
			if ! zag -> (dbseek (xfilial ("ZAG") + _sDocZAG, .F.))
				_sErros += "Documento '" + _sDocZAG + "' nao localizado na tabela ZAG"
			else
				_oTrEstq := ClsTrEstq ():New (zag -> (recno ()))
				if ! _oTrEstq:Exclui ()
					_sErros += _oTrEstq:UltMsg
				else
					_sMsgRetWS = _oTrEstq:UltMsg
				endif
			endif
		endif
	endcase
Return


// --------------------------------------------------------------------------
// Verifica onde determinada string eh usada. Geralmente serve para pesquisar por
// nomes de campos, nicknames de gatilhos, etc.
static function _OndeSeUsa ()
	local _sCampo  := ""

	if empty (_sErros)
		_sCampo  = _ExtraiTag ("_oXML:_WSAlianca:_Campo", .T., .F.)
	endif
	if empty (_sErros)
		_sMsgRetWS = U_OndeSeUsa (_sCampo)
	endif
Return

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

	if empty (_sErros)
		_wB1_COD    = _ExtraiTag ("_oXML:_WSAlianca:_B1_COD",    .T., .F.)
		_wB1_DESC   = _ExtraiTag ("_oXML:_WSAlianca:_B1_DESC",   .T., .F.)
		_wB1_TIPO   = _ExtraiTag ("_oXML:_WSAlianca:_B1_TIPO",   .T., .F.)
		_wB1_UM     = _ExtraiTag ("_oXML:_WSAlianca:_B1_UM",     .T., .F.)
		_wB1_LOCPAD = _ExtraiTag ("_oXML:_WSAlianca:_B1_LOCPAD", .T., .F.)
		_wB1_GRUPO  = _ExtraiTag ("_oXML:_WSAlianca:_B1_GRUPO",  .T., .F.)
	endif

	If empty (_sErros)

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
  //	aAdd(_aProduto, {"B1_VAGRWWC" ,"000"	 	  	 , Nil})
		aAdd(_aProduto, {"B1_GRTRIB" ,_wB1_TIPO	 	  	 , Nil})

		u_log (_aProduto)
		//Chamando a inclusão - Modelo 1
		lMsErroAuto := .F.

		FWMVCRotAuto(oModel,"SB1",3,{{"SB1MASTER",_aProduto}})

		//Se houve erro no ExecAuto, mostra mensagem
		If lMsErroAuto
			u_log ('Erro na rotina automatica')
			if ! empty (_sErroAuto)
				_sErros += _sErroAuto
			endif
			if ! empty (NomeAutoLog ())
				_sErros += U_LeErro (memoread (NomeAutoLog ()))
			endif
		Else
			u_log ('rotina automatica OK')
			_sMsgRetWS = 'Produto criado codigo ' + sb1 -> b1_cod
		EndIf

	EndIf
	u_logFim ()
Return Nil

// --------------------------------------------------------------------------
// Inclui novo cliente (cadastro em tela simplificada do NaWeb)
static function _IncCli ()
	local _aCliente := {}
	local _wnome := ""
	local _wtipo := ""
	local _wcgc := ""
	local _wtel := ""
	local _wemail := ""
	local _west := ""
	local _wcidade := ""
	local _wbairro := ""
	local _wend := ""
	local _wcep := ""
	local _wcodmun := ""
	local _wcodmun2 := ""
	local _wregiao := ""
	local _nreduz := ""

	u_logIni ()

	if empty (_sErros)
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
		_wregiao = _ExtraiTag ("_oXML:_WSAlianca:_Regiao",       .T., .F.)
		_nreduz  = _ExtraiTag ("_oXML:_WSAlianca:_NomeReduzido", .T., .F.)
	endif

	if empty (_sErros)

		// Cria variavel para receber possiveis erros da funcao U_Help().
		private _sErroAuto := ""

		_aCliente :={	 {"A1_NOME"   , _wnome                 ,Nil},;
		{"A1_PESSOA" , _wtipo                 ,Nil},;
		{"A1_END"    , _wend                  ,Nil},;
		{"A1_BAIRRO" , _wbairro               ,Nil},;
		{"A1_EST"    , _west                  ,Nil},;
		{"A1_CEP"    , _wcep                  ,Nil},;
		{"A1_MUN"    , _wcidade               ,Nil},;
		{"A1_TEL"    , _wtel                  ,Nil},;
		{"A1_EMAIL"  , _wemail                ,Nil},;
		{"A1_CGC"    , _wcgc                  ,Nil},;
		{"A1_COD_MUN", _wcodmun               ,Nil},;
		{"A1_CMUN"   , _wcodmun2              ,Nil},;
		{"A1_REGIAO" , "SUL"                  ,Nil},;
		{"A1_NREDUZ" , _nreduz                ,Nil},;
		{"A1_LOJA"   , "01"                   ,Nil},;
		{"A1_VEND"   , "001"                  ,Nil},;
		{"A1_MALA"   , "S"                    ,Nil},;
		{"A1_TIPO"   , "F"                    ,Nil},;
		{"A1_BCO1"   , "CX1"                  ,Nil},;
		{"A1_RISCO"  , "E"                    ,Nil},;
		{"A1_PAIS"   , "105"                  ,Nil},;
		{"A1_SATIV1" , "08.04"                ,Nil},;
		{"A1_VAMDANF", _wemail                ,Nil},;
		{"A1_CODPAIS", "01058"                ,Nil},;
		{"A1_MSBLQL" , "2"                    ,Nil},;
		{"A1_SIMPNAC", "2"                    ,Nil},;
		{"A1_VABARAP", "0"                    ,Nil},;
		{"A1_CONTA"  , "101020201001"         ,Nil},;
		{"A1_COND"   , "097"				   ,Nil},;
		{"A1_VAUEXPO", ddatabase			   ,Nil},;
		{"A1_VERBA"  , "2"					   ,Nil},;
		{"A1_GRPTRIP", "003"				   ,Nil},;
		{"A1_FORMA"  , "3"                    ,Nil},;
		{"A1_LOJAS"  , "S"                    ,Nil},;
		{"A1_CNAE"   , "0"                    ,Nil},;
		{"A1_CONTRIB", "2"                    ,Nil},;
		{"A1_VADTINC", date()                 ,Nil},;
		{"A1_IENCONT", "2"                    ,Nil} }

		// Ordena campos cfe. dicionario de dados.
		_aCliente = aclone (U_OrdAuto (_aCliente))

		u_log (_aCliente)

		lMsErroAuto := .F.
		MSExecAuto({|x,y| Mata030(x,y)},_aCliente,3)
		If lMsErroAuto
			u_log ('Erro na rotina automatica')
			if ! empty (_sErroAuto)
				_sErros += _sErroAuto
			endif
			if ! empty (NomeAutoLog ())
				_sErros += U_LeErro (memoread (NomeAutoLog ()))
			endif
		else
			u_log ('rotina automatica OK')
			_sMsgRetWS = 'Cliente criado codigo ' + sa1 -> a1_cod + '/' + sa1 -> a1_loja
		endif
	endif
	u_logFim ()
return

// --------------------------------------------------------------------------
// Altera cliente (cadastro em tela simplificada do NaWeb)
static function _AltCli ()
//	local _aCliente := {}
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

	if empty (_sErros)
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

	if empty (_sErros)
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
			_sErros += 'Nao foi possivel alterar o cadastro'
		else
			u_log ('rotina automatica OK')
			_sMsgRetWS = 'Cliente alterado codigo ' + _wcodcli
		endif

	endif
return

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

	u_logIni ()
	
//	// busca valores de entrada
	if empty (_sErros)
		_wFilialIni   = _ExtraiTag ("_oXML:_WSAlianca:_FilialIni"	, .T., .F.)
		_wFilialFin   = _ExtraiTag ("_oXML:_WSAlianca:_FilialFin"	, .T., .F.)
		_wAno         = _ExtraiTag ("_oXML:_WSAlianca:_Ano"			, .T., .F.)
		_wDataInicial = _ExtraiTag ("_oXML:_WSAlianca:_DataInicial"	, .T., .F.)
		_wDataFinal   = _ExtraiTag ("_oXML:_WSAlianca:_DataFinal"	, .T., .F.)
		_sModelo      = _ExtraiTag ("_oXML:_WSAlianca:_Modelo"		, .T., .F.)
	endif
	If empty(_sErros) .and. _sModelo == '2020'
		_aPerfNA      = U_SeparaCpo (_ExtraiTag ("_oXML:_WSAlianca:_Perfis", .T., .F.), ',')
		u_log ('Perfis deste usuario como recebido no XML:', _aPerfNA)
		// Complementa 5 posicoes caso necessario
		do while len (_aPerfNA) < 5
			aadd (_aPerfNA, 'null')
		enddo
		u_log ('Perfis deste usuario ajustados:', _aPerfNA)
	endif
	If empty(_sErros)
		_oSQL := ClsSQL():New ()
		if _sModelo == '2019'
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "with C AS ("
			_oSQL:_sQuery += "SELECT *,"
			_oSQL:_sQuery +=       " ORDEM AS CHAVE_ORDENACAO_1, "
			_oSQL:_sQuery +=       " 999999999999999 - SUM (REA) OVER (PARTITION BY DESC_N1, DESC_N2) AS CHAVE_ORDENACAO_2"
			_oSQL:_sQuery +=  " FROM VA_FCONS_ORCAMENTO_524 "
			_oSQL:_sQuery +=  " ('" + _wFilialIni + "'"
			_oSQL:_sQuery +=   ",'" + _wFilialFin + "'"
			_oSQL:_sQuery +=   ",'" + _wAno       + "'"
			_oSQL:_sQuery +=   ",'" + substr (_wDataInicial, 5, 2) + "'"
			_oSQL:_sQuery +=   ",'" + substr (_wDataFinal, 5, 2) + "')"		
			_oSQL:_sQuery += ")"
			_oSQL:_sQuery += " SELECT ORDEM, DESC_N1, DESC_N2, CONTA, DESCRICAO, FILIAL, CC,"
			_oSQL:_sQuery +=        " SUM (ORC_ANO) AS ORC_ANO, "
			_oSQL:_sQuery +=        " SUM (ORC) AS ORC,"
			_oSQL:_sQuery +=        " SUM (REA) AS REA,"
			_oSQL:_sQuery +=        " SUM (REA_ANT) AS REA_ANT"
			_oSQL:_sQuery +=   " FROM C"		
			_oSQL:_sQuery +=  " GROUP BY ORDEM, DESC_N1, DESC_N2, CHAVE_ORDENACAO_1, CHAVE_ORDENACAO_2, CONTA, DESCRICAO, FILIAL, CC"
			_oSQL:_sQuery +=  " ORDER BY CHAVE_ORDENACAO_1, CHAVE_ORDENACAO_2, CONTA"
		elseif _sModelo == '2020'
			_oSQL:_sQuery += "with C AS ("
			_oSQL:_sQuery +=  " SELECT ORDEM, DESC_N1, DESC_N2, NIVEL, CONTA, DESCRICAO,"
			_oSQL:_sQuery +=         " SUM (ORC_ANO)    AS ORC_ANO,"
			_oSQL:_sQuery +=         " SUM (ORC_ANO_AV) AS ORC_ANO_AV,"
			_oSQL:_sQuery +=         " SUM (ORC_PER)    AS ORC_PER,"
			_oSQL:_sQuery +=         " SUM (ORC_PER_AV) AS ORC_PER_AV,"
			_oSQL:_sQuery +=         " SUM (REA_PER)    AS REA_PER,"
			_oSQL:_sQuery +=         " SUM (REA_PER_AV) AS REA_PER_AV,"
			_oSQL:_sQuery +=         " SUM (REA_ANT)    AS REA_ANT,"
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
		else
			_sErros += "Modelo de orcamento '" + _sModelo + "' desconhecido ou sem tratamento no web service."
		endif
		_oSQL:Log ()
	endif

	If empty(_sErros)
		_sAliasQ = _oSQL:Qry2Trb (.F.)
		(_sAliasQ) -> (dbgotop ())

		_XmlRet += "<ConsultaDeOrcamento>"
		_XmlRet += 		"<Ano>" + _wAno + "</Ano>"
		_XmlRet += 		"<DataInicial>"+ _wDataInicial +"</DataInicial>"
		_XmlRet += 		"<DataFinal>"+ _wDataFinal +"</DataFinal>"
		_XmlRet += 		"<Orcamento>"

		Do While ! (_sAliasQ) -> (EOF ()) .and. empty (_sErros)
			_XmlRet += 		"<OrcamentoItem>"
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
				_XmlRet += 			"<Ordem>" 			 + IIf(Empty(alltrim((_sAliasQ) -> ordem))				,'-' 	, alltrim((_sAliasQ) -> ordem))				+ "</Ordem>"
				_XmlRet += 			"<DescN1>"			 + IIf(Empty(alltrim((_sAliasQ) -> desc_n1))			,'-' 	, alltrim((_sAliasQ) -> desc_n1))			+ "</DescN1>"
				_XmlRet += 			"<DescN2>"			 + IIf(Empty(alltrim((_sAliasQ) -> desc_n2))			,'-' 	, alltrim((_sAliasQ) -> desc_n2))			+ "</DescN2>"
				_XmlRet += 			"<Conta>"			 + IIf(Empty(alltrim((_sAliasQ) -> conta))				,'0' 	, alltrim((_sAliasQ) -> conta))				+ "</Conta>"
				_XmlRet += 			"<CtiDesc01>"		 + IIf(Empty(alltrim((_sAliasQ) -> descricao))			,'-' 	, alltrim((_sAliasQ) -> descricao))			+ "</CtiDesc01>"
				_XmlRet += 			"<OrcadoAno>"		 + alltrim (Transform (                                                 (_sAliasQ) -> orc_ano,     "999999999999.99")) + "</OrcadoAno>"
				_XmlRet += 			"<OrcadoAnoAV>"		 + alltrim (Transform (iif (abs ((_sAliasQ) -> orc_ano_AV) > 999999, 0, (_sAliasQ) -> orc_ano_AV), "999999999999.99")) + "</OrcadoAnoAV>"  // Trunca para um valor fixo em caso de valores de percentuais exorbitantes.
				_XmlRet += 			"<Orcado>"			 + alltrim (Transform (                                                 (_sAliasQ) -> orc_per,     "999999999999.99")) + "</Orcado>"
				_XmlRet += 			"<OrcadoAV>"		 + alltrim (Transform (iif (abs ((_sAliasQ) -> orc_per_AV) > 999999, 0, (_sAliasQ) -> orc_per_AV), "999999999999.99")) + "</OrcadoAV>"  // Trunca para um valor fixo em caso de valores de percentuais exorbitantes.
				_XmlRet += 			"<Realizado>"		 + alltrim (Transform (                                                 (_sAliasQ) -> rea_per,     "999999999999.99")) + "</Realizado>"
				_XmlRet += 			"<RealizadoAV>"		 + alltrim (Transform (iif (abs ((_sAliasQ) -> rea_per_AV) > 999999, 0, (_sAliasQ) -> rea_per_AV), "999999999999.99")) + "</RealizadoAV>"  // Trunca para um valor fixo em caso de valores de percentuais exorbitantes.
				_XmlRet += 			"<RealizadoAnt>"	 + alltrim (Transform (                                                 (_sAliasQ) -> rea_ant,     "999999999999.99")) + "</RealizadoAnt>"
				_XmlRet += 			"<RealizadoAntAV>"	 + alltrim (Transform (iif (abs ((_sAliasQ) -> rea_ant_AV) > 999999, 0, (_sAliasQ) -> rea_ant_AV), "999999999999.99")) + "</RealizadoAntAV>"  // Trunca para um valor fixo em caso de valores de percentuais exorbitantes.
				_XmlRet += 			"<Destacar>"		 + (_sAliasQ) -> destacar + "</Destacar>"
				_XmlRet += 			"<FilCC>"			 + alltrim ((_sAliasQ) -> FiltraCC) + "</FilCC>"
			else
				_sErros += "Modelo de orcamento '" + _sModelo + "' desconhecido ou sem tratamento na montagem do XML"
			endif
			_XmlRet += 		"</OrcamentoItem>"
			(_sAliasQ) -> (dbskip ())
		EndDo

		_XmlRet += 		"</Orcamento>"
		_XmlRet += "</ConsultaDeOrcamento>"
		
		(_sAliasQ) -> (dbclosearea ())
		
		_sMsgRetWS := _XmlRet
	EndIf
	u_logFim ()
Return 


// --------------------------------------------------------------------------
// Inclusao de cargas de recebimento de uva durante a safra.
static function _IncCarSaf ()
	local _oAssoc    := NIL
	local _sSafra    := ''
	local _sBalanca  := ''
	local _sAssoc    := ''
	local _sLoja     := ''
//	local _dDtCheg   := ctod ('')
//	local _sHrCheg   := ''
	local _sSerieNF  := ''
	local _sNumNF    := ''
	local _sChvNfPe  := ''
	local _sPlacaVei := ''
	local _sObs      := ''
	local _sCadVit   := ''
	local _sVaried   := ''
	local _sEmbalag  := ''
	local _sTombador := 0
	local _aItensCar := {}
	local _sLote     := ''
	local _sSenhaOrd := ''
	local _sCPFCarg  := ''
	local _sInscCarg := ''
	local _sImpTkCar := ''
	local _oSQL      := NIL
	local _aRegSA2   := {}

	u_log2 ('info', 'Iniciando web service de geracao de carga.')
	u_log2 ('debug', 'cFilAnt:' + cFilAnt)
	if empty (_sErros) ; _sSafra    = _ExtraiTag ("_oXML:_WSAlianca:_Safra",             .T., .F.) ; endif
	if empty (_sErros) ; _sBalanca  = _ExtraiTag ("_oXML:_WSAlianca:_Balanca",           .T., .F.) ; endif
	if empty (_sErros) ; _sAssoc    = _ExtraiTag ("_oXML:_WSAlianca:_Associado",         .T., .F.) ; endif
	if empty (_sErros) ; _sLoja     = _ExtraiTag ("_oXML:_WSAlianca:_Loja",              .T., .F.) ; endif
	if empty (_sErros) ; _sCPFCarg  = _ExtraiTag ("_oXML:_WSAlianca:_CPF",               .F., .F.) ; endif
	if empty (_sErros) ; _sInscCarg = _ExtraiTag ("_oXML:_WSAlianca:_IE",                .F., .F.) ; endif
	if empty (_sErros) ; _sImpTkCar = _ExtraiTag ("_oXML:_WSAlianca:_ImprTk",            .F., .F.) ; endif
	if empty (_sErros) ; _sSerieNF  = _ExtraiTag ("_oXML:_WSAlianca:_SerieNFProdutor",   .T., .F.) ; endif
	if empty (_sErros) ; _sNumNF    = _ExtraiTag ("_oXML:_WSAlianca:_NumeroNFProdutor",  .T., .F.) ; endif
	if empty (_sErros) ; _sChvNFPe  = _ExtraiTag ("_oXML:_WSAlianca:_ChaveNFPe",         .T., .F.) ; endif
	if empty (_sErros) ; _sPlacaVei = _ExtraiTag ("_oXML:_WSAlianca:_PlacaVeiculo",      .T., .F.) ; endif
	if empty (_sErros) ; _sTombador = _ExtraiTag ("_oXML:_WSAlianca:_Tombador",          .T., .F.) ; endif
	if empty (_sErros) ; _lAmostra  = (upper (_ExtraiTag ("_oXML:_WSAlianca:_ColetarAmostra",    .T., .F.)) == 'S') ; endif
	if empty (_sErros) ; _sObs      = _ExtraiTag ("_oXML:_WSAlianca:_Obs",               .F., .F.) ; endif
	if empty (_sErros) ; _sSenhaOrd = _ExtraiTag ("_oXML:_WSAlianca:_Senha",             .F., .F.) ; endif
	if empty (_sErros)
//		if _sAssoc $ '012373/012791/012792'  // Nao associados que vou instanciar para que a carga seja aceita.
//			_oAssoc := ClsAssoc ():New ()
//			_oAssoc:Codigo = _sAssoc
//			_oAssoc:Loja   = _sLoja
//			_oAssoc:Nome   = fBuscaCpo ("SA2", 1, xfilial ("SA2") + _sAssoc + _sLoja, "A2_NOME")
//			u_log2 ('aviso', 'Instanciando nao associado: ' + _oAssoc:Codigo + '/' + _oAssoc:Loja)
//		else
			// A partir de 2021 o app de safra manda tambem CPF e inscricao, para os casos em que foi gerado 'lote de entrega'
			// pelo caderno de campo, e lah identifica apenas o grupo familiar. A inscricao e o CPF serao conhecidos somente
			// no momento em que o associado chegar aqui com o talao de produtor.
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
				_sErros += "Nao foi localizado nenhum fornecedor pelos parametros informados (cod/loja/CPF/IE)"
			elseif len (_aRegSA2) > 1
				_sErros += "Foi localizado MAIS DE UM fornecedor pelos parametros informados (cod/loja/CPF/IE)"
			else
				_oAssoc := ClsAssoc ():New (_aRegSA2 [1, 1], _aRegSA2 [1, 2])
				if valtype (_oAssoc) != 'O'
					_sErros += "Impossivel instanciar objeto ClsAssoc. Verifique codigo e loja informados " + _sErroAuto
				endif
			endif
//		endif
	endif

	// Leitura dos itens de forma repetitiva (tentei ler em array mas nao funcionou e tenho pouco tempo pra ficar testando...)
	if empty (_sErros) ; _sCadVit  = _ExtraiTag ("_oXML:_WSAlianca:_cadastroViticola1", .T., .F.) ; endif
	if empty (_sErros) ; _sVaried  = _ExtraiTag ("_oXML:_WSAlianca:_variedade1",        .T., .F.) ; endif
	if empty (_sErros) ; _sEmbalag = _ExtraiTag ("_oXML:_WSAlianca:_Embalagem1",        .T., .F.) ; endif
	if empty (_sErros) ; _sLote    = _ExtraiTag ("_oXML:_WSAlianca:_Lote1",             .F., .F.) ; endif
	if empty (_sErros)
		aadd (_aItensCar, {_sCadVit, _sVaried, _sEmbalag, _sLote})
	endif
	//
	if empty (_sErros) ; _sCadVit  = _ExtraiTag ("_oXML:_WSAlianca:_cadastroViticola2", .F., .F.) ; endif
	if empty (_sErros) ; _sVaried  = _ExtraiTag ("_oXML:_WSAlianca:_variedade2",        .F., .F.) ; endif
	if empty (_sErros) ; _sEmbalag = _ExtraiTag ("_oXML:_WSAlianca:_Embalagem2",        .F., .F.) ; endif
	if empty (_sErros) ; _sLote    = _ExtraiTag ("_oXML:_WSAlianca:_Lote2",             .F., .F.) ; endif
	if empty (_sErros) .and. ! empty (_sCadVit)  // Pode nao ter 2 itens na carga
		aadd (_aItensCar, {_sCadVit, _sVaried, _sEmbalag, _sLote})
	endif
	//
	if empty (_sErros) ; _sCadVit  = _ExtraiTag ("_oXML:_WSAlianca:_cadastroViticola3", .F., .F.) ; endif
	if empty (_sErros) ; _sVaried  = _ExtraiTag ("_oXML:_WSAlianca:_variedade3",        .F., .F.) ; endif
	if empty (_sErros) ; _sEmbalag = _ExtraiTag ("_oXML:_WSAlianca:_Embalagem3",        .F., .F.) ; endif
	if empty (_sErros) ; _sLote    = _ExtraiTag ("_oXML:_WSAlianca:_Lote3",             .F., .F.) ; endif
	if empty (_sErros) .and. ! empty (_sCadVit)  // Pode nao ter 3 itens na carga
		aadd (_aItensCar, {_sCadVit, _sVaried, _sEmbalag, _sLote})
	endif
	u_log2 ('info', 'Itens da carga:')
	u_log2 ('info', _aItensCar)
	if empty (_sErros)
		if len (_aItensCar) == 0
			_sErros += "Nenhum item informado para gerar carga."
		else
			_sMsgRetWS = U_GeraSZE (_oAssoc,_sSafra,_sBalanca,_sSerieNF,_sNumNF,_sChvNfPe,_sPlacaVei,_sTombador,_sObs,_aItensCar, _lAmostra, _sSenhaOrd, _sImpTkCar)
		endif
	endif

	u_log2 ('info', 'Finalizando web service de geracao de carga.')
Return



// --------------------------------------------------------------------------
// Retorna texto ticket carga safra
static function _RTkCarSaf ()
	local _sSafra    := ''
	local _sBalanca  := ''
	local _sCarga    := ''
	local _lAmostra  := .F.
	local _sSenhaOrd := ''

	u_logIni ()
	u_log ('cFilAnt:', cFilAnt)
	if empty (_sErros) ; _sSafra    = _ExtraiTag ("_oXML:_WSAlianca:_Safra",             .T., .F.) ; endif
	if empty (_sErros) ; _sBalanca  = _ExtraiTag ("_oXML:_WSAlianca:_Balanca",           .T., .F.) ; endif
	if empty (_sErros) ; _sCarga    = _ExtraiTag ("_oXML:_WSAlianca:_Carga",             .T., .F.) ; endif
	if empty (_sErros) ; _lAmostra  = (upper (_ExtraiTag ("_oXML:_WSAlianca:_ColetarAmostra",    .T., .F.)) == 'S') ; endif
	if empty (_sErros) ; _sSenhaOrd = _ExtraiTag ("_oXML:_WSAlianca:_Senha",             .F., .F.) ; endif
	if empty (_sErros)
		sze -> (dbsetorder (1))  // ZE_FILIAL+ZE_SAFRA+ZE_CARGA
		if ! sze -> (dbseek (xfilial ("SZE") + _sSafra + _sCarga, .F.))
			_sErros += "Carga nao localizada na filial '" + cFilAnt + "' para a safra '" + _sSafra + "'"
		endif
	endif
	if empty (_sErros) .and. sze -> ze_status = 'C'
		_sErros += "Carga '" + sze -> ze_carga + "' cancelada."
	endif
	if empty (_sErros) .and. sze -> ze_local != _sBalanca
		_sErros += "Carga '" + sze -> ze_carga + "' foi gerada pela balanca '" + sze -> ze_local + "'."
	endif
	if empty (_sErros)
		private _lImpTick  := .T.         // Variavel usada pelo programa de impressao do ticket
	//	private _lColAmCar := _lAmostra   // Variavel usada pelo programa de impressao do ticket
	//	private _sOrDesSaf := _sSenhaOrd  // Variavel usada pelo programa de impressao do ticket
		_sMsgRetWS = U_va_rusTk (1, '', 1, {}, 'QUICKPRINTER', .t.)
	endif

	u_logFim ()
Return



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
	local _aRetQry      := {}

	u_logIni ()
	
	// busca valores de entrada
	if empty (_sErros)
		_wFilial      = 	_ExtraiTag ("_oXML:_WSAlianca:_Filial"		, .T., .F.)
		_wProduto     =     _ExtraiTag ("_oXML:_WSAlianca:_Produto"		, .T., .F.)
		_wAlmox    	  =     _ExtraiTag ("_oXML:_WSAlianca:_Almox"		, .T., .F.)
		_wDataInicial = 	_ExtraiTag ("_oXML:_WSAlianca:_DataInicial"	, .T., .F.)
		_wDataFinal   = 	_ExtraiTag ("_oXML:_WSAlianca:_DataFinal"	, .T., .F.)
	endif
	
	if empty(_wFilial)		;_sErros += "Campo <filial> não preenchido"			;endif
	if empty(_wProduto)		;_sErros += "Campo <produto> não preenchido"		;endif
	if empty(_wAlmox)		;_sErros += "Campo <almoxarifado> não preenchido"	;endif
	if empty(_wDataInicial)	;_sErros += "Campo <data inicial> não preenchido"	;endif
	if empty(_wDataFinal)	;_sErros += "Campo <data final> não preenchido"		;endif

	_oSQL := ClsSQL():New ()  
	_oSQL:_sQuery := ""		
	_oSQL:_sQuery += " SELECT * FROM " + RetSQLName ("SD3")
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND D3_FILIAL = '" + _wFilial + "'"
	_oSQL:_sQuery += " AND D3_COD    = '" + _wProduto + "'"
	_oSQL:_sQuery += " AND D3_LOCAL  = '" + _wAlmox + "'"
	_oSQL:_sQuery += " AND D3_EMISSAO BETWEEN '" + _wDataInicial + "' AND '" + _wDataFinal + "'"
	_oSQL:Log ()
	_aRetQry  = aclone (_oSQL:Qry2Array ())
		
	If len(_aRetQry)> 2000  // 5000
		_sErros := "Este item possui muita movimentacao. Selecione um periodo menor!"
	EndIf
	
	If empty(_sErros)

		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""		
		_oSQL:_sQuery += " SELECT * FROM dbo.VA_FKARDEX('" + _wFilial + "', '" + _wProduto + "', '" + _wAlmox + "', '" + _wDataInicial + "', '" + _wDataFinal + "') "	
		_oSQL:Log ()
		_sAliasQ = _oSQL:Qry2Trb (.F.)
		(_sAliasQ) -> (dbgotop ())

		_XmlRet += "<ConsultaKardex>" //+ chr (13) + chr (10)
		_XmlRet += 		"<DataInicial>"+ _wDataInicial +"</DataInicial>" //+ chr (13) + chr (10)
		_XmlRet += 		"<DataFinal>"+ _wDataFinal +"</DataFinal>" //+ chr (13) + chr (10)
		_XmlRet += 		"<Registro>" //+ chr (13) + chr (10)

		While (_sAliasQ)->(!Eof())	
			_sNome := StrTran((_sAliasQ) -> Nome , '&', '' )  
			_XmlRet += "<RegistroItem>"
				
			_XmlRet += 		"<Linha>" 		  + alltrim(str((_sAliasQ) -> Linha))														+ "</Linha>" 			//+ chr (13) + chr (10)
			_XmlRet += 		"<Data>"		  + IIf((alltrim((_sAliasQ) -> data))=='//'	,'', alltrim((_sAliasQ) -> data)) 				+ "</Data>"				//+ chr (13) + chr (10)
			_XmlRet += 		"<Doc>"		 	  + alltrim((_sAliasQ) -> Doc)																+ "</Doc>"				//+ chr (13) + chr (10)
			_XmlRet += 		"<Serie>"		  + alltrim((_sAliasQ) -> Serie)															+ "</Serie>"			//+ chr (13) + chr (10)
			_XmlRet += 		"<Qt_Entrada>"	  + alltrim(str((_sAliasQ) -> Qt_Entrada))													+ "</Qt_Entrada>"		//+ chr (13) + chr (10)
			_XmlRet += 		"<Qt_Saida>"	  + alltrim(str((_sAliasQ) -> Qt_Saida))													+ "</Qt_Saida>"			//+ chr (13) + chr (10)
			_XmlRet += 		"<Saldo>"		  + alltrim(str((_sAliasQ) -> Saldo))														+ "</Saldo>"			//+ chr (13) + chr (10)
			_XmlRet += 		"<NumSeq>"	 	  + alltrim((_sAliasQ) -> NumSeq)															+ "</NumSeq>"			//+ chr (13) + chr (10)
			_XmlRet += 		"<Movimento>"	  + alltrim((_sAliasQ) -> Movimento)														+ "</Movimento>"		//+ chr (13) + chr (10)
			_XmlRet += 		"<OP>"	 		  + alltrim((_sAliasQ) -> OP)																+ "</OP>"				//+ chr (13) + chr (10)
			_XmlRet += 		"<TES>" 		  + alltrim((_sAliasQ) -> TES)																+ "</TES>"				//+ chr (13) + chr (10)
			_XmlRet += 		"<CFOP>" 		  + alltrim((_sAliasQ) -> CFOP)																+ "</CFOP>"				//+ chr (13) + chr (10)
			_XmlRet += 		"<Lote>" 		  + alltrim((_sAliasQ) -> Lote)																+ "</Lote>"				//+ chr (13) + chr (10)
			_XmlRet += 		"<Etiqueta>" 	  + alltrim((_sAliasQ) -> Etiqueta)															+ "</Etiqueta>"			//+ chr (13) + chr (10)
			_XmlRet += 		"<Usuario>" 	  + alltrim((_sAliasQ) -> Usuario)															+ "</Usuario>"			//+ chr (13) + chr (10)
			_XmlRet += 		"<CliFor>" 		  + alltrim((_sAliasQ) -> CliFor)															+ "</CliFor>"			//+ chr (13) + chr (10)
			_XmlRet += 		"<Loja>" 		  + alltrim((_sAliasQ) -> Loja)																+ "</Loja>"				//+ chr (13) + chr (10)
			_XmlRet += 		"<Nome>" 		  + alltrim (_sNome)																		+ "</Nome>"				//+ chr (13) + chr (10)
			_XmlRet += 		"<Motivo>" 		  + alltrim((_sAliasQ) -> Motivo)															+ "</Motivo>"			//+ chr (13) + chr (10)
			_XmlRet += 		"<Nf_Orig>" 	  + alltrim((_sAliasQ) -> Nf_Orig)															+ "</Nf_Orig>"			//+ chr (13) + chr (10)
			_XmlRet += 		"<Data_Inclusao>" + IIf((alltrim((_sAliasQ)->Data_Inclusao))=='//' ,'', alltrim((_sAliasQ)->Data_Inclusao)) + "</Data_Inclusao>"	//+ chr (13) + chr (10)
			_XmlRet += 		"<Hora_Inclusao>" + alltrim((_sAliasQ) -> Hora_Inclusao)													+ "</Hora_Inclusao>"	//+ chr (13) + chr (10)
			_XmlRet += 		"<Sequencia>" 	  + alltrim((_sAliasQ) -> Sequencia)														+ "</Sequencia>"		//+ chr (13) + chr (10)
			_XmlRet += 		"</RegistroItem>"
			
			(_sAliasQ) -> (dbskip ())
		EndDo

		_XmlRet += 		"</Registro>" 	//+ chr (13) + chr (10)
		_XmlRet += "</ConsultaKardex>" 	//+ chr (13) + chr (10)
		
		(_sAliasQ) -> (dbclosearea ())
		
		_sMsgRetWS := _XmlRet
	EndIf
	u_logFim ()
Return 



// --------------------------------------------------------------------------
// Executa rotina semelhante ao antigo 'monitor' do sistema
Static function _MonitProt ()
	local _oRPCSrv := NIL
	local _aRPCRet := {}
	local _nRPCRet := 0
	local _sRetMon := ''
	local _aServicos := {}
	local _nServico  := 0
	local _sAmbs     := ''
//	local _sPortaMon := ''

	u_logIni ()

	if empty (_sErros)
		_sAmbs     = _ExtraiTag ("_oXML:_WSAlianca:_Ambientes", .F., .F.)
//		_sPortaMon = _ExtraiTag ("_oXML:_WSAlianca:_Porta",    .F., .F.)

		// Cria lista de servicos e portas a serem verificados
		_aServicos = {}
		//nao precisa, pois estou indo em cada um dos slaves --> aadd (_aServicos, {'Master', 1290, 'ALIANCA'})
		if empty (_sAmbs) .or. 'SLAVE1' $ upper (_sAmbs); aadd (_aServicos, {'slave1', 1291, 'ALIANCA'}) ; endif
		if empty (_sAmbs) .or. 'SLAVE2' $ upper (_sAmbs); aadd (_aServicos, {'slave2', 1292, 'ALIANCA'}) ; endif
		if empty (_sAmbs) .or. 'SLAVE3' $ upper (_sAmbs); aadd (_aServicos, {'slave3', 1293, 'ALIANCA'}) ; endif
		if empty (_sAmbs) .or. 'SLAVE4' $ upper (_sAmbs); aadd (_aServicos, {'slave4', 1294, 'ALIANCA'}) ; endif
		if empty (_sAmbs) .or. 'SLAVE5' $ upper (_sAmbs); aadd (_aServicos, {'slave5', 1295, 'ALIANCA'}) ; endif
		if empty (_sAmbs) .or. 'EXTERNO' $ upper (_sAmbs); aadd (_aServicos, {'externo', 1298, 'ALIANCA'}) ; endif
		if empty (_sAmbs) .or. 'LOJAS' $ upper (_sAmbs); aadd (_aServicos, {'lojas', 1247, 'ALIANCA'}) ; endif
		if empty (_sAmbs) .or. 'TESTE' $ upper (_sAmbs); aadd (_aServicos, {'Teste', 1280, 'TESTE'}) ; endif
		if empty (_sAmbs) .or. 'TESTEFISCAL' $ upper (_sAmbs); aadd (_aServicos, {'TesteFiscal', 1281, 'TESTEFISCAL'}) ; endif
		if empty (_sAmbs) .or. 'TESTEMEDIO' $ upper (_sAmbs); aadd (_aServicos, {'TesteMedio', 1282, 'TESTEMEDIO'}) ; endif

		// Se recebida alguma porta na chamada, acrescenta-a junto na lista.
//		if ! empty (_sPortaMon)
//			aadd (_aServicos, {'Porta_' + _sPortaMon, val (_sPortaMon), 'Porta_' + _sPortaMon})
//		endif

		_sRetMon := '<monitorProtheus>'
		for _nServico = 1 to len (_aServicos)
			u_log ("Vou verificar ", _aServicos [_nServico, 1], _aServicos [_nServico, 2])
			_oRPCSrv := TRpc ():New (_aServicos [_nServico, 3])
			if valtype (_oRPCSrv) != "O"
				u_log ("Protheus: Nao foi possivel instanciar objeto RPC para comunicacao com o servico " + _aServicos [_nServico, 1] + ' na porta ' + cvaltochar (_aServicos [_nServico, 2]))
			else
				if ! _oRPCSrv:Connect ('192.168.1.3', _aServicos [_nServico, 2])
					u_log ("Protheus: Nao foi possivel estabelecer conexao RPC com o servico solicitado: " + _aServicos [_nServico, 1] + ' na porta ' + cvaltochar (_aServicos [_nServico, 2]))
				else
					_aRPCRet := _oRPCSrv:CallProc ('GetUserInfoArray ()')
					if len (_aRPCRet) == 0
						u_log ("Servidor RPC retornou dados em formato desconhecido.")
					else
						for _nRPCRet = 1 to len (_aRPCRet)
							_sRetMon += '<sessao>'
							_sRetMon += '<servico>'          + _aServicos [_nServico, 1]            + '</servico>'
							_sRetMon += '<usuario>'          +             _aRPCRet [_nRPCRet,  1]  + '</usuario>'
							_sRetMon += '<computador>'       +             _aRPCRet [_nRPCRet,  2]  + '</computador>'
							_sRetMon += '<thread>'           + cvaltochar (_aRPCRet [_nRPCRet,  3]) + '</thread>'
							_sRetMon += '<server>'           +             _aRPCRet [_nRPCRet,  4]  + '</server>'
							_sRetMon += '<funcao>'           +             _aRPCRet [_nRPCRet,  5]  + '</funcao>'
							_sRetMon += '<ambiente>'         +             _aRPCRet [_nRPCRet,  6]  + '</ambiente>'
							_sRetMon += '<inicio>'           +    strtran (_aRPCRet [_nRPCRet,  7], chr (10), '')  + '</inicio>'
							_sRetMon += '<instrucoes>'       + cvaltochar (_aRPCRet [_nRPCRet,  9]) + '</instrucoes>'
							_sRetMon += '<instrPorSegundo>'  + cvaltochar (_aRPCRet [_nRPCRet, 10]) + '</instrPorSegundo>'
							_sRetMon += '<obs>'              +    strtran (strtran (alltrim (_aRPCRet [_nRPCRet, 11]), '  ', ' '), '  ', ' ') + '</obs>'
							_sRetMon += '<memoria>'          + cvaltochar (_aRPCRet [_nRPCRet, 12]) + '</memoria>'
							_sRetMon += '<id_DbAccess>'      +             _aRPCRet [_nRPCRet, 13]  + '</id_DbAccess>'
							_sRetMon += '<id_CTree>'         + cvaltochar (_aRPCRet [_nRPCRet, 14]) + '</id_CTree>'
							_sRetMon += '<tipoThread>'       +             _aRPCRet [_nRPCRet, 15]  + '</tipoThread>'
							_sRetMon += '<tempoInatividade>' +             _aRPCRet [_nRPCRet, 16]  + '</tempoInatividade>'
							_sRetMon += '</sessao>'
						next
					endif
				endif
			endif
		next
		_sRetMon += '</monitorProtheus>'
	endif

	if empty (_sErros)
		_sMsgRetWS := _sRetMon
	endif

	u_logFim ()
return
