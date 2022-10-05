// Programa...: MT250Est
// Autor......: Robert Koch
// Data.......: 09/12/2014
// Descricao..: P.E. para validar o estorno do apontamento de producao.
//              Criado inicialmente para integracao com Fullsoft.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Valida se vai permitir o estorno de apontamento de OP.
// #PalavasChave      #estorno_apontamento_OP #FULLWMS # ordem_de_producao
// #TabelasPrincipais #SD3
// #Modulos           #PCP #EST

// Historico de alteracoes:
// 17/08/2018 - Robert  - Grava evento quando envolver FullWMS.
// 28/05/2019 - Andre   - Adicionado validacao que não permite exclusao do apontamento sem antes excluir movimento de guarda.
// 13/06/2019 - Robert  - Verificava movimento de 'guarda' da etiqueta mesmo quando etiqueta vazia.
// 27/08/2019 - Cláudia - Incluida rotina _LibEst(liberar estorno) para verificar se usuário tem permissão para executar o processo.
// 15/10/2020 - Robert  - Validacao de acesso do usuario passa a ser feita antes de verificar o FullWMS (mais demorado).
//                      - Incluidas tags para catalogo de fontes.
// 03/03/2021 - Robert  - Desabilitado gravação do Evento
// 05/10/2021 - Robert  - Desabilitado contorno que permitia ao grupo 029 estornar apont.de etiq.jah vista pelço FullWMS (o pessoal estorna producao sem se importar em fazer o ajuste na integracao com FullWMS).
// 08/10/2021 - Robert  - Nao considerava status_protheus = 'C' na validacao da integracao com FullWMS (GLPI 10041).
// 05/10/2022 - Robert  - Valida tabela tb_wms_entrada pelo 'codfor' e nao mais por 'nrodoc'.
//

// ----------------------------------------------------------------
user function MT250Est ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()

	if ! U_ZZUVL ('090', __cUserId, .T.)
		_lRet = .F.
	endif

//	if _lRet
	if _lRet .and. ! empty (sd3 -> d3_vaetiq)
		_lRet = _VerFull ()
	endif
	
	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return _lRet


// --------------------------------------------------------------------------
static function _VerFull ()
	local _lRet      := .T.
	local _oSQL      := NIL
	local _sMsg      := ""
	public _oEvtEstF := NIL

	if _lRet
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " select count (*)"
		_oSQL:_sQuery +=   " from tb_wms_entrada"
//		_oSQL:_sQuery +=  " where nrodoc = '" + sd3 -> d3_doc + "'"
		_oSQL:_sQuery +=  " where codfor = '" + sd3 -> d3_vaetiq + "'"
		_oSQL:_sQuery +=    " and status != '9'"
		_oSQL:_sQuery +=    " and status_protheus != 'C'"
		_oSQL:Log ('[' + procname () + ']')
		if _oSQL:RetQry () > 0
			_lRet = .F.
			_sMsg := "Esta entrada de estoque ja foi aceita pelo FullWMS. Para estornar esta producao exclua do Fullsoft, antes, a tarefa de recebimento (ou cancele operacao de guarda da etiqueta)." + chr (13) + chr (10) + chr (13) + chr (10)
			_sMsg += "Dados adicionais:" + chr (13) + chr (10)
			_sMsg += "Documento: " + sd3 -> d3_doc + chr (13) + chr (10)
			_sMsg += "Etiq/pallet: " + sd3 -> d3_vaetiq
			u_help (_sMsg, _oSQL:_sQuery, .t.)
			_lRet = .F.
		endif
	endif
	
	if _lRet
		if ! empty (sd3 -> d3_vaetiq)
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT COUNT (*)"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD3") + " SD3 "
			_oSQL:_sQuery +=  " WHERE D3_VAETIQ = '" + sd3 -> d3_vaetiq + "'"
			_oSQL:_sQuery +=    " AND D3_CF = 'RE4'"
			_oSQL:_sQuery +=    " AND D3_ESTORNO != 'S'"
			_oSQL:_sQuery +=    " AND D3_LOCAL = '" + sd3 -> d3_local + "'"
			_oSQL:_sQuery +=    " AND D3_COD = '" + sd3 -> d3_cod + "'"
			_oSQL:Log ()
			if _oSQL:RetQry () > 0
				u_help ("Movimento de guarda (Trans. para Almoxarifado 01) do pallet ainda existe. É necessario excluir antes o movimento de guarda.", _oSQL:_sQuery, .t.)
				_lRet = .F.
			endif
		endif
	endif
return _lRet
