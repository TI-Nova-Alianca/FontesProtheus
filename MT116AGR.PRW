// Programa...: MT116AGR		
// Autor......: Catia Cardoso
// Data.......: 18/03/2016
// Descricao..: P.E. APOS A GRAVACAO de Conhecimentos de Fretes
//
// Historico de alteracoes:
// 20/09/2018 - ?      - Gravacao da tabela SZH quando tinha mais de uma nota por conhecimento nao estava gravando corretamente o rateio do frete
// 30/03/2020 - Robert - Ajuste gravacao ZH_ITNFE para novo tamanho (de 2 para 4, igual ao D1_ITEM)
//

// -------------------------------------------------------------

User Function MT116AGR()

	local _aAmbAnt   := U_SalvaAmb ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _lRet      := .T.
	local _warray    := aclone (aParametros)
	local _wopcao      := _warray [1]
	local _wc116NumNF  := _warray [8]
	local _wc116SerNF  := _warray [9]
	local _wc116Fornece:= _warray [10]
	local _wc116Loja   := _warray [11]
	local _wn116Valor  := _warray [13]
	
	//u_showarray(_warray)

	do case 
		case _wopcao = 2 // inclusao
			_lRet = U_GravaSZH (_wc116NumNF, _wc116SerNF, _wc116Fornece, _wc116Loja, _wn116Valor)
		case _wopcao = 1 // exclui
			_lRet = _ExcluiSZH (_wc116NumNF, _wc116SerNF, _wc116Fornece, _wc116Loja, _wn116Valor)
	endcase
		
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
	
Return(_lRet)

// ----------------------------------
// Exclui SZH - dados fretes Entradas
// ----------------------------------
static function _ExcluiSZH (_wc116NumNF, _wc116SerNF, _wc116Fornece, _wc116Loja, _wn116Valor)
	local i	:= 0
	
	_lRet = .T.
	// deleta os registros referentes a este conhecimento na SZH
	_sSQL  = ""
	_sSQL += " SELECT R_E_C_N_O_"
  	_sSQL += "   FROM SZH010"
 	_sSQL += "  WHERE D_E_L_E_T_ = ''"
   	_sSQL += "    AND ZH_TPFRE   = 'E'" 
   	_sSQL += "    AND ZH_FORNECE = '" + _wc116Fornece + "'"
   	_sSQL += "    AND ZH_LOJA    = '" + _wc116Loja + "'"
	_sSQL += "    AND ZH_NFFRETE = '" + _wc116NumNF + "'"
	_sSQL += "    AND ZH_SERFRET = '" + _wc116SerNF + "'"
	_aDeleta := U_Qry2Array(_sSQL)
   	
   	//u_showarray (_aDeleta)
   	
   	if len(_aDeleta)> 0
    	for i=1 to len(_aDeleta)
    		_wregistro = _aDeleta[i,1]
    		// posiciona
    		DbSelectArea("SZH")
        	DbSetOrder(4)
        	if DbSeek(_wregistro ,.F.)
    			// marca como deletado
    			reclock ("SZH", .T.)
					szh -> D_E_L_E_T_  = '*'
				MsUnLock()
			endif										
		next
	endif
	
Return(_lRet)

// ---------------------------------
// Grava SZH - dados fretes Entradas
// ---------------------------------
user function GravaSZH (_wc116NumNF, _wc116SerNF, _wc116Fornece, _wc116Loja, _wn116Valor)
	local i	:= 0
	local j	:= 0
	
	_lRet = .T.
	// BUSCA NO SF8 AS NOTAS QUE FORAM AMARRADAS A ESTE CONHECIMENTO    
   	_sSQL  = "" 
   	_sSQL += " SELECT SF8.F8_DTDIGIT, SF8.F8_NFORIG, SF8.F8_SERORIG, SF8.F8_FORNECE, SF8.F8_LOJA, SF8.F8_TIPO"
  	_sSQL += "   FROM SF8010 AS SF8"
 	_sSQL += "  WHERE SF8.D_E_L_E_T_  = ''"
 	_sSQL += "    AND SF8.F8_FILIAL   = '" + xfilial ("SF8") + "'"
   	_sSQL += "    AND SF8.F8_NFDIFRE  = '" + _wc116NumNF + "'"
   	_sSQL += "    AND SF8.F8_SEDIFRE  = '" + _wc116SerNF + "'"
   	_sSQL += "    AND SF8.F8_TRANSP   = '" + _wc116Fornece + "'"
   	_sSQL += "    AND SF8.F8_LOJTRAN  = '" + _wc116Loja + "'"
   	_aNotas := U_Qry2Array(_sSQL)
   	
   	//u_showarray (_aNotas)
   	
   	_wtotalnotas := 0
   	if len(_aNotas)> 0
   		
   		for i=1 to len(_aNotas)
   			_wdocorig   = _aNotas[i,2]
   			_wserieorig = _aNotas[i,3]
   			_wfornece   = _aNotas[i,4]
   			_wljfornece = _aNotas[i,5]
   			_wtipo      = _aNotas[i,6]
			// soma o total das notas para fazer o rateio do frete corretamente
   			_wtotalnotas = _wtotalnotas + fBuscaCpo ('SF1', 1, xfilial('SF1') + _wdocorig + _wserieorig + _wfornece + _wljfornece, "F1_VALBRUT")
		next
   		
    	for i=1 to len(_aNotas)
    	    
			_wdocorig   = _aNotas[i,2]
			_wserieorig = _aNotas[i,3]
			_wfornece   = _aNotas[i,4]
			_wljfornece = _aNotas[i,5]
			_wtipo      = _aNotas[i,6]
								
			// BUSCA ITENS DAS NOTA - PARA MONTAR O RATEIO
			_sSQL  = "" 
			_sSQL += " SELECT D1_ITEM, D1_TIPO, D1_COD, D1_QUANT, D1_TOTAL, D1_VALIPI, D1_ICMSRET"
			_sSQL += "   FROM SD1010"
			_sSQL += "  WHERE D1_FILIAL  = '" + xfilial ("SD1") + "'" 
			_sSQL += "    AND D1_DOC     = '" + _wdocorig + "'"
			_sSQL += "    AND D1_SERIE   = '" + _wserieorig + "'"
			_sSQL += "    AND D1_FORNECE = '" + _wfornece + "'"
			_sSQL += "    AND D1_LOJA    = '" + _wljfornece + "'"
			_sSQL += "    AND D_E_L_E_T_ = ''"
			_aItens := U_Qry2Array(_sSQL)
    		//u_showarray (_aItens)
    		
			if len(_aItens) > 0
				// CRIA REGISTRO NO SZH - PARA CADA ITEM DA NF
				for j=1 to len(_aItens)
				//	_witemnfe = substr(_aItens[j,1],3,2)
					_witemnfe = _aItens[j,1]  // Todos os campos passados para 4 posicoes (GLPI 7735)
					_wtiponfe = _aItens[j,2]
					_wvlritem = (_aItens[j,5] + _aItens[j,6] + _aItens[j,7])
					reclock ("SZH", .T.)
						szh -> zh_filial  = xfilial ("SZH") 
						szh -> zh_fornece = _wc116Fornece
						szh -> zh_loja    = _wc116Loja
						szh -> zh_NFFrete = _wc116NumNF
						szh -> zh_SerFret = _wc116SerNF
						szh -> zh_Data    = ddatabase		
						szh -> zh_TpFre   = 'E'
						szh -> zh_NFentr  = _wdocorig
						szh -> zh_Srnfent = _wserieorig
						szh -> zh_ItNFE   = _witemnfe
						szh -> zh_TpNFEnt = _wtiponfe
						szh -> zh_CliFor  = _wfornece
						szh -> zh_LjCliFor= _wljfornece
						szh -> zh_SeqEntr = "1"
						szh -> zh_Rateio  = round ( _wvlritem * _wn116Valor / _wtotalnotas, 2)
						szh -> zh_TpDesp  = "1"
					MsUnLock()											
		 		next
			endif		 		
		next
	endif	
return _lRet
