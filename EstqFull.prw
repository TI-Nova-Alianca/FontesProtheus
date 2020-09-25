// Programa...: EstqFull
// Autor......: Robert Koch
// Data.......: 15/04/2015
// Descricao..: Tela de consulta de comparativo de estoques Protheus X FullWMS
//
// Historico de alteracoes:
// 05/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 - Pergunte em Loop 
//
// --------------------------------------------------------------------------
User Function EstqFull (_sFilial, _sProdIni, _sProdFim)
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()
	private cPerg     := "EstqFull"

	if _sFilial == NIL
		_ValidPerg ()
		Pergunte (cPerg, .T.)
		
		processa ({|| _Tela (cFilAnt, mv_par01, mv_par02)})
//		do while Pergunte (cPerg, .T.)
//			processa ({|| _Tela (cFilAnt, mv_par01, mv_par02)})
//		enddo
	else
		processa ({|| _Tela (_sFilial, _sProdIni, _sProdFim)})
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
Return
//
// --------------------------------------------------------------------------
Static Function _Tela (_sFilial, _sProdIni, _sProdFim)
	local _oSQL        := NIL
	_oSQL := ClsSQL ():New ()
	
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT RTRIM (B2_COD) AS PRODUTO, RTRIM (B1_DESC) AS DESCRICAO, B2_QATU AS QT_PROTHEUS, DISPONIVEL AS DISPON_FULL, AVARIA AS AVARIA_FULL, BLOQUEADO AS BLOQ_FULL, RECEBIMENTO AS RECEBTO_FULL, LIB_RECEBIMENTO AS LIB_RECEB_FULL, MOVIMENTACAO AS MOVIM_FULL, DISP_PARA_FAT, DIFERENCA"
	_oSQL:_sQuery +=   " FROM dbo.VA_VCOMPARA_ESTQ_FULLWMS V,"
	_oSQL:_sQuery +=          RetSQLName ("SB1") + " SB1 "
	_oSQL:_sQuery +=  " WHERE V.EMPRESA      = '" + cEmpAnt + "'"
	_oSQL:_sQuery +=    " AND V.B2_FILIAL    = '" + _sFilial + "'"
	_oSQL:_sQuery +=    " AND V.B2_COD       BETWEEN '" + _sProdIni + "' AND '" + _sProdIni + "'"
	_oSQL:_sQuery +=    " AND SB1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_oSQL:_sQuery +=    " AND SB1.B1_COD     = V.B2_COD"
	_oSQL:_sQuery +=  "	ORDER BY COD_ITEM "
	_oSQL:F3Array ()
Return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}

	// Perguntas para a entrada da rotina
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Produto inicial               ", "C", 15, 0,  "",   "SB1", {},    ""})
	aadd (_aRegsPerg, {02, "Produto final                 ", "C", 15, 0,  "",   "SB1", {},    ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
