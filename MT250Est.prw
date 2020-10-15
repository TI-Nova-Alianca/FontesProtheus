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
//

// ----------------------------------------------------------------
user function MT250Est ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()

	if ! U_ZZUVL ('090', __cUserId, .T.)
		_lRet = .F.
	endif

	if _lRet
		_lRet = _VerFull ()
	endif
	
//	if _lRet
//		_lRet = _LibEst ()
//	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return _lRet

// --------------------------------------------------------------------------
static function _VerFull ()
	local _lRet      := .T.
	local _oSQL      := NIL
	local _sMsg      := ""
	local _sJustif   := ""
	public _oEvtEstF := NIL

	u_logIni ()
	
	if _lRet
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " select count (*)"
		_oSQL:_sQuery +=   " from tb_wms_entrada"
		_oSQL:_sQuery +=  " where nrodoc = '" + sd3 -> d3_doc + "'"
		_oSQL:_sQuery +=    " and status != '9'"
		if _oSQL:RetQry () > 0
			_lRet = .F.
			_sMsg := "Esta entrada de estoque ja foi vista pelo Fullsoft. Para estornar esta producao exclua do Fullsoft, antes, a tarefa de recebimento." + chr (13) + chr (10) + chr (13) + chr (10)
			_sMsg += "Dados adicionais:" + chr (13) + chr (10)
			_sMsg += "Documento: " + sd3 -> d3_doc + chr (13) + chr (10)
			_sMsg += "Etiq/pallet: " + sd3 -> d3_vaetiq
			if u_zzuvl ('029', __cUserId, .F.)
//				_lRet = U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
				if U_MsgNoYes (_sMsg + " Confirma assim mesmo?")
					do while .T.
						_sJustif = U_Get ('Justificativa', 'C', 150, '', '', space (150), .F., '.T.')
						if _sJustif == NIL
							_lRet = .F.
							loop
						endif
						exit
					enddo

					_lRet = .T.

					// Cria evento dedo-duro para posterior gravacao em outro P.E. apos a efetivacao do movimento.
					_oEvtEstF := ClsEvent ():New ()
					_oEvtEstF:CodEven  = 'SD3002'
					_oEvtEstF:Texto    = 'Estorno apontamento pallet ' + alltrim (sd3 -> d3_vaetiq) + '. Justif: ' + _sJustif
					_oEvtEstF:Produto  = sd3 -> d3_cod
					_oEvtEstF:Etiqueta = sd3 -> d3_vaetiq
					_oEvtEstF:OP       = sd3 -> d3_op
					
					_oEvtEstF:Grava()
				endif
			else
				u_help (_sMsg)
				_lRet = .F.
			endif
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
				u_help ("Movimento de guarda (Trans. para Almoxarifado 01) do pallet ainda existe. É necessario excluir antes o movimento de guarda.")
				_lRet = .F.
			endif
		endif
	endif
	u_logFim ()
return _lRet
//
//static function _LibEst ()
//	local _lRet      := .T.
//	
//	if ! U_ZZUVL ('090', __cUserId, .F.)
//		u_help ("Usuário sem permissão para estorno de estoque")
//		_lRet = .F.
//	endif
//return _lRet
