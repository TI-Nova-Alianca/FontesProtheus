// Programa  : MNTNG
// Autor     : Andre Alves
// Data      : 18/06/2019
// Descricao : PE para validações especificas do aplicativo MNT NG	
//
// https://tdn.engpro.totvs.com.br/pages/releaseview.action?pageId=347448878
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #PE para validações especificas do aplicativo MNT NG	
// #PalavasChave      #manutenção #app
// #TabelasPrincipais #
// #Modulos           #MNT
//
// Historico de alteracoes:
// 21/06/2019 - Andre   - Adicionado validação de datas retroativas.
// 07/04/2021 - Robert  - Faltava declaracao variavel _oObjMnt (GLPI 9774)
// 09/03/2022 - Robert  - Instanciava objeto oWS sempre, mas parece que paramixb[2] muda conforme o caso.
// 16/03/2022 - Robert  - Filtro busca produtos mudado de tipo MM para MM e MC (GLPI 11296)
// 08/04/2022 - Robert  - Criado filtro de OS conforme usuario (cada manutentor visualiza apenas as suas OS) - GLPI 11886
// 26/08/2022 - Robert  - Criado filtro para usuario FELIPE.ESTEVES
// 02/09/2022 - Robert  - Criado filtro para usuarios junior.melgarejo e joao.costa
// 05/09/2022 - Robert  - Nome do Evaldo estava incorreto no filtro de OS.
// 06/09/2022 - Robert  - Criado filtro para alexandre.andrade
//                      - Criada variavel unica para retorno da funcao.
// 02/10/2022 - Robert  - Removido atributo :DiasDeVida da classe ClsAviso.
// 03/10/2022 - Robert  - Trocado grpTI por grupo 122 no envio de avisos.
// 03/10/2022 - Robert  - Impede encerramento OS se tiver pedido de compra aberto (GLPI 12678)
// 17/10/2022 - Robert  - Sai Joao Costa e entra Max Padilha (filtros de OS)
// 25/01/2023 - Sandra  - Filtro busca produtos alterado de tipo MM e MC para tipo MM, MC e II (GLPI 12003)
// 30/01/2023 - Sandra  - Filtro busca produtos alterado de tipo MM, MC e II para MM, MC, II, CL (GLPI 12813)
// 01/02/2023 - Robert/Sandra - Filtro busca produtos passa a ler parametro VA_MNTNG.
// 02/02/2023 - Robert  - Acrescentado usuario vagner.lima no filtro de O.S.
// 05/04/2023 - Robert  - Acrescentado usuario jonathan.brito no filtro de O.S.
// 26/04/2023 - Robert  - Implementados filtros de terceiros e solicitacoes de manut.
// 03/05/2023 - Robert  - Implementados filtros para sandra.sugari e claudia.lionco
//                      - Passa a usar metodo ClsAviso:IntegNaWeb=.f. 
// 04/05/2023 - Claudia - Criado parametro para filtro de usuarios. GLPI: 13504
// 10/05/2023 - Robert  - Passa a validar usuarios pelo campo T1_CODFUNC = __cUserID
//                      - Criado tratamento para o campo T1_VATPFIL
// 28/06/2023 - Robert  - Nao manda mais terceiros para ninguem
// 22/01/2024 - Robert  - Filtra centros de custo (tabela CCT) bloqueados.
//

#include "PROTHEUS.ch"

// Gera uma linha adicional de log no console.log com as queries usadas
// para leitura dos dados e seus tempos.
// ----------------------------------------------------------------------------------------------------------------------------------
USER FUNCTION mntnglog ()
return .t.


// ----------------------------------------------------------------------------------------------------------------------------------
User Function MNTNG()
	local _aAreaAnt  := U_ML_SRArea ()
	local _xRet      := NIL
	Local _sIDdLocal := ''
	local _oObjMnt   := NIL
	local _sCodFunc  := ''
	local _sFiltrar  := ''
	local _oAviso    := NIL
	private _sArqLog := 'U_MNTNG.log'  // Quero usar o mesmo arquivo de log para todos os usuarios.

//	U_Log2 ('debug', '[' + procname () + ']' + __cUserId + "(" + alltrim (cUserName) + ")")

	// Verifica em que momento estah sendo chamado este P.E.
	_sIDdLocal := PARAMIXB[1]

	// Valida cancelamento da ordem
	If _sIDdLocal == "CANCEL_VALID"
		If FWJsonDeserialize(PARAMIXB[2]:GetContent(),@_oObjMnt) //Parse da string no formato Json
			If Empty(_oObjMnt:message )//verifica campo observação foi passado vazio
				_xRet = "A observação do cancelamento é obrigatória."
			EndIf
		else
			_xRet = ''
			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'E'
			_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
			_oAviso:Titulo     = 'Erro ao desserializar objeto _oObjMnt'
			_oAviso:Texto      = 'Nao foi possivel desserializar objeto no ponto de entrada ' + procname () + " com IdLocal = " + _sIDdLocal + ". Mais detalhes em " + _sArqLog
			_oAviso:InfoSessao = .T.
			_oAviso:Grava ()
		EndIf


	// Filtro para centros de custo
	ElseIf _sIDdLocal == "FILTER_COSTCENTER"
		_xRet = "AND CTT_BLOQ != '1'"
		U_Log2 ('info', '[' + procname () + ']Filtrando c.custo: _xRet = ' + _xRet)


// nao consegui abrir a documentacao em https://tdn.engpro.totvs.com.br/pages/releaseview.action?pageId=347448878	// Filtro para executantes de S.S. com o usuario logado.
// nao consegui abrir a documentacao em https://tdn.engpro.totvs.com.br/pages/releaseview.action?pageId=347448878	ElseIf _sIDdLocal == "FILTER_EXECUTOR"
// nao consegui abrir a documentacao em https://tdn.engpro.totvs.com.br/pages/releaseview.action?pageId=347448878		_xRet = ""
// nao consegui abrir a documentacao em https://tdn.engpro.totvs.com.br/pages/releaseview.action?pageId=347448878		U_Log2 ('info', '[' + procname () + ']Filtrando executor: _xRet = ' + _xRet)


	// Filtro para ordens de servico
	ElseIf _sIDdLocal == "FILTER_ORDER"
		_xRet = ''

		// Mandar somente as OS direcionadas ao manutentor atual (desde que nao seja um manutentor 'power')
		_LeFuncion (@_sCodFunc, @_sFiltrar)
		if _sFiltrar == 'S'
			_xRet := ""
			_xRet += "AND EXISTS ("
			_xRet +=     "SELECT * FROM " + RetSQLName ("STL")
			_xRet +=     " WHERE D_E_L_E_T_ = ''"
			_xRet +=       " AND TL_FILIAL  = TJ_FILIAL"
			_xRet +=       " AND TL_ORDEM   = TJ_ORDEM"
			_xRet +=       " AND TL_CODIGO  = '" + _sCodFunc + "')"
		endif
		U_Log2 ('info', '[' + procname () + ']Filtrando OS: _xRet = ' + _xRet)


	// Filtro para busca de produtos
	elseif _sIDdLocal == "FILTER_PRODUCT"
		_xRet = "AND B1_TIPO IN " + FormatIn (GetMv ("VA_MNTNG"), "/")
		U_Log2 ('info', '[' + procname () + ']Filtrando produtos: _xRet = ' + _xRet)


	// Filtro para solicitacoes de manutencao.
	elseif _sIDdLocal == "FILTER_REQUEST"
		_xRet = ''
		_xRet += "AND TQB_SOLUCA NOT IN ('E', 'C')"  // Encerradas e Canceladas nao pretendo enviar nunca
		
		// Mandar somente as SC distribuidas (desde que nao seja um manutentor 'power')
		_LeFuncion (@_sCodFunc, @_sFiltrar)
		if _sFiltrar == 'S'
			_xRet += "AND TQB_SOLUCA = 'D'"
		endif
		U_Log2 ('info', '[' + procname () + ']Filtrando sol.manut: _xRet = ' + _xRet)


	// Filtro para terceiros
	ElseIf _sIDdLocal == "FILTER_THIRDPART"
	//	_xRet = " AND A2_TIPO = 'J'
		_xRet = " AND 0=1"  // Nao queremos enviar nenhum fornecedor, poisnao usamos pelo app.
		U_Log2 ('info', '[' + procname () + ']Filtrando terceiros: _xRet = ' + _xRet)


	ElseIf _sIDdLocal == "FINISH_VALID_ORDER"
		If FWJsonDeserialize(PARAMIXB[2]:GetContent(), @_oObjMnt)
			U_Log2 ('info', '[' + procname () + ']Validando encerramento OS ' + _oObjMnt:ORDER)
			If Empty(_oObjMnt:observation ) //verifica campo observação foi passado vazio
				_xRet = "Campo observação deve ser informado."
			EndIf
			if STOD(substr(_oObjMnt:startDate, 1, 8)) < date () -3 .and. STOD(substr(_oObjMnt:startDate, 1, 8)) > date () 
				_xRet = "Data inicial nao pode ser menor do que data de hoje."
			endif
			if STOD(substr(_oObjMnt:endDate, 1, 8)) < date () -3 .and. STOD(substr(_oObjMnt:endDate, 1, 8)) > date ()
				_xRet = "Data final nao pode ser menor do que data de hoje."
			endif
			
			// Verifica se tem pedido de compra em aberto relacionado a esta OS
			_xRet = _VerPdCom (_oObjMnt:ORDER)
			
			if ! empty (_xRet)
				U_Log2 ('aviso', '[' + procname () + ']Msg retorno validacao encerramento: ' + _xRet)
			endif
		else
			_xRet = ''
			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'E'
			_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
			_oAviso:Titulo     = 'Erro ao desserializar objeto _oObjMnt'
			_oAviso:Texto      = 'Nao foi possivel desserializar objeto no ponto de entrada ' + procname () + " com IdLocal = " + _sIDdLocal + ". Mais detalhes em " + _sArqLog
			_oAviso:InfoSessao = .T.
			_oAviso:Grava ()
		EndIf
		
	EndIf

	U_ML_SRArea (_aAreaAnt)
Return _xRet


// --------------------------------------------------------------------------
// Verifica se tem pedido de compra em aberto relacionado a esta OS
static function _VerPdCom (_sOrdem)
	local _sRetPdCom := ''
	local _sPdCom    := ''
	local _oSQL      := NIL

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT ISNULL (STRING_AGG (C7_NUM, ','), '')"
	_oSQL:_sQuery +=  " FROM (SELECT DISTINCT C7_NUM"
	_oSQL:_sQuery +=          " FROM " + RetSQLName ("SC7") + " SC7"
	_oSQL:_sQuery +=         " WHERE SC7.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=           " AND SC7.C7_FILIAL  = '" + xfilial ("SC7") + "'"
	_oSQL:_sQuery +=           " AND SC7.C7_OP      like '" + _sOrdem + "%'"
	_oSQL:_sQuery +=           " AND SC7.C7_QUANT   > SC7.C7_QUJE"
	_oSQL:_sQuery +=           " AND SC7.C7_RESIDUO != 'S'"
	_oSQL:_sQuery +=        ") AS SUB"  // Tive que fazer uma subquery para poder usar STRING_AGG
	_sPdCom = alltrim (_oSQL:RetQry (1, .f.))
	if ! empty (_sPdCom)
		_sRetPdCom = "Ped.compra vinculados: " + _sPdCom + ". Encerramento da OS nao permitido."
	endif
return _sRetPdCom


// --------------------------------------------------------------------------
// Leitura de funcionario para ver se aplica filtros.
// Nao fiz no inicio do programa por que este P.E. eh chamado muitas vezes, a
// partir de diversos lugares, durante a sincronizacao, e ficaria lento demais.
static function _LeFuncion (_sCodFunc, _sFiltrar)
	local _oSQL      := NIL
	local _aRetST1   := {}

	// Define o codigo de funcionario (campo T1_CODFUNC) para que o usuario receba somente as OS designadas para ele.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += "SELECT T1_CODFUNC, T1_VATPFIL"
	_oSQL:_sQuery +=  " FROM " + RetSQLName ("ST1") + " ST1"
	_oSQL:_sQuery += " WHERE ST1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=   " AND ST1.T1_FILIAL  = '" + xfilial ("ST1") + "'"
	_oSQL:_sQuery +=   " AND ST1.T1_CODUSU  = '" + __cUserID + "'"
//	_oSQL:Log ('[' + procname () + ']')
	_aRetST1 := aclone (_oSQL:RetFixo (1, "ao consultar __cUserID '" + __cUserId + "' na tabela ST1", .F.))
//	U_Log2 ('debug', _aRetST1)
	if len (_aRetST1) == 1
		_sCodFunc = _aRetST1 [1, 1]
		_sFiltrar = _aRetST1 [1, 2]
	else
		_sCodFunc = ''
		_sFiltrar = 'S'  // Na duvida, vou filtrar.
	endif

	if empty (_sCodFunc) .or. empty (_sFiltrar)
		_oAviso := ClsAviso ():New ()
		_oAviso:Tipo       = 'E'
		_oAviso:DestinZZU  = {'122'}  // 122 = grupo da TI
		_oAviso:Titulo     = 'Usuario sem tratamento para filtrar OS'
		_oAviso:Texto      = "Usuario '" + __cUserId + "' (" + alltrim (cUserName) + ") sem tratamento (ou nao identificado pelo campo T1_CODUSU) para filtrar OS no ponto de entrada " + procname () + ". Mais detalhes em " + _sArqLog
		_oAviso:InfoSessao = .T.
		_oAviso:IntegNaWeb = .F.  // Nao tenta integrar neste momento (nao ha urgencia)
		_oAviso:Grava ()
	endif

//	U_Log2 ('debug', '[' + procname () + ']' + __cUserId + "(" + alltrim (cUserName) + ") " + _sCodFunc + ' ' + _sFiltrar)
return
