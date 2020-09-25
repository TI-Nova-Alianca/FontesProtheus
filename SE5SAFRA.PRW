// Programa...: SE5SAFRA	
// Autor......: Catia Cardoso
// Data.......: 02/05/2018
// Descricao..: Le SE5 - localiza os lancamentos referentes ao retorno de pagamentos da safra
//
// Historico de alteracoes:
// 05/03/2019 - Robert - Criado parametro para selecionar tipo de titulo.
//                     - Regua de processamento.
// 26/08/2019 - Robert - Nao verifica mais o tipo de titulo (temos FAT,ND, DP, ...)
//

// ------------------------------------------------------------------------------------
User Function SE5_SAFRA()
	cPerg   := "SE5_SAFRA"
	_ValidPerg()
	if Pergunte(cPerg,.T.)
		processa ({|| _AndaLogo ()})
	endif
Return

// --------------------------------------------------------------------------
static function _AndaLogo ()
	local i	:= 0
	
	_sQuery := ""
	_sQuery += "  SELECT SZI.R_E_C_N_O_ AS REC1" 
	_sQuery += "       , SZI.ZI_SEQ"
	_sQuery += "       , SE5.R_E_C_N_O_ AS REC2"
	_sQuery += "       , SE5.E5_CLIFOR"
	_sQuery += "       , SE5.E5_LOJA"
	_sQuery += "    FROM SE5010 AS SE5"
	_sQuery += "  		INNER JOIN SZI010 AS SZI"
	_sQuery += "  			ON (SZI.D_E_L_E_T_ = ''"
	_sQuery += "  				AND SZI.ZI_ASSOC   = SE5.E5_CLIFOR"
	_sQuery += "  				AND SZI.ZI_LOJASSO = SE5.E5_LOJA"
	_sQuery += "  				AND SZI.ZI_DOC     = SE5.E5_NUMERO"
	_sQuery += "  				AND SZI.ZI_PARCELA = SE5.E5_PARCELA)"
	_sQuery += "  WHERE SE5.D_E_L_E_T_ = ''"
	_sQuery += "    AND SE5.E5_FILIAL  = '01'"
	_sQuery += "    AND SE5.E5_DATA    = '" + dtos(mv_par01) + "'"
	_sQuery += "    AND SE5.E5_RECPAG  = 'P'"
	_sQuery += "    AND SE5.E5_ORIGEM  = 'FINA430'"
	_sQuery += "    AND SE5.E5_NATUREZ = '120201'"
	_sQuery += "    AND SE5.E5_BANCO   = '041'"
	//u_showmemo (_sQuery)
	
	_aDados := U_Qry2Array(_sQuery)
	procregua (len (_aDados))
	if len (_aDados) > 0
		for i=1 to len(_aDados)
			incproc ()
			_wszirecno = _aDados[i,1]
			_wsziseq   = _aDados[i,2]
			_wse5recno = _aDados[i,3]
			_wfornece  = _aDados[i,4]
			_wloja     = _aDados[i,5]
			// atualiza SZI
			DbSelectArea("SZI")
			dbgoto(_wszirecno)
			_oCtaCorr := ClsCtaCorr ():New (szi -> ( recno() ))
			_oCtaCorr:AtuSaldo ()
			u_log (_oCtaCorr:UltMsg)
			// grava chave no SE5
			_wchave = 'SZI' + _wfornece + _wloja + _wsziseq
			// atualiza SE5
			DbSelectArea("SE5")
			dbgoto(_wse5recno)
			reclock("SE5", .F.)
			SE5-> E5_VACHVEX  = _wchave  
			MsUnLock()
		next
	endif
Return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	aadd (_aRegsPerg, {01, "Data do Pagamento     ?", "D", 8,  0,  "",   "   ", {}  , ""})
//	aadd (_aRegsPerg, {02, "Tipo de titulo        ?", "C", 3,  0,  "",   "   ", {}  , ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
