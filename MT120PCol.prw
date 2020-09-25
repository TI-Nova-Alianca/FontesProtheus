// Programa: MT120PCol
// Autor:    Robert Koch
// Data:     24/08/2012
// Funcao:   PE 'Linha OK' na manutencao de pedidos de compra / autorizacoes de entrega.
//           Criado inicialmente para validacoes ref. obra Flores da Cunha.
//
// Historico de alteracoes:
// 06/09/2012 - Robert - Considerava duas vezes o item atual na verificacao de saldos PIF.
// 03/12/2015 - Robert - Validacoes de CC com campo B1_VARATEI.
// 06/02/2018 - Robert - Desabilitadas validacoes ref. obra da planta de Lagoa Bela.
// 14/08/2018 - Catia  - Validações SA5 tabela de produto x fornecedor para TODO item com B1_TIPO DIFERENTE de GG
// 06/11/2019 - Cláudia - Alterada a validação para que caso não existir o código fornecedor inserido na tabela, não permita a gravação.
//
// --------------------------------------------------------------------------------------------------------------
user function MT120PCol ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	//private _sArqLog := U_NomeLog ()

	if _lRet
		_lRet = _VProdForn ()
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet

// --------------------------------------
// Validacoes tabela Produto x Fornecedor
// --------------------------------------
static function _VProdForn ()
	local _lRet     := .T.

	if ! GDDeleted ()
		// verifica se o item é diferente de GG
		_wtipo = fbuscacpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("C7_PRODUTO"),  "B1_TIPO")
		if _wtipo != 'GG' .and. _wtipo != 'AI' 
			// verifica se existe amarracao na SA5
			_sSQL := ""
			_sSQL += "SELECT A5_CODPRF AS A5_CODPRF"
  			_sSQL += "  FROM " + RetSQLName ("SA5") 
 			_sSQL += " WHERE D_E_L_E_T_ = ''"
   			_sSQL += "   AND A5_PRODUTO = '" + GDFieldGet ("C7_PRODUTO") + "'" 
   	 		_sSQL += "   AND A5_FORNECE = '" + cA120Forn + "'"
   			_sSQL += "   AND A5_LOJA    = '" + cA120Loj + "'"
   			
   			 dbUseArea(.T., "TOPCONN", TCGenQry(,,_sSQL), "TRA", .F., .T.)
   			 TRA->(DbGotop())	
   			 
   			while  TRA->(!Eof())	
	   			if empty(TRA -> A5_CODPRF)
	   				u_help ("Produto sem amarração produto x fornecedor")
	   				_lRet = .F.	   				
				endIf
				TRA->(DbSkip())
			enddo
			TRA->(DbCloseArea())
			DbSelectArea("SC7")
	
//   			_aDados := U_Qry2Array(_sSQL)
//   			if len(_aDados) = 0 
//				u_help ("Produto sem amarração produto x fornecedor")
//				_lRet = .F.
//			endif
		endif			
	endif

return _lRet