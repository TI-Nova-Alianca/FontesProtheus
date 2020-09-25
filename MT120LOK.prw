// Programa: MT120LOk
// Autor:    Andre Alves
// Data:     25/07/2019
// Funcao:   PE 'Linha OK' na manutencao de pedidos de compra.
//           
//
// Historico de alteracoes:
// 27/03/2020 - Andre    - Adicionada validação para data de entrega não ser menor que data atual.

// ----------------------------------------------------------------------------------------------------------------------------------------------------
user function mt120lok ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
//	local _lUsaRat  := .F.

		// obriga informacao do centro de custo
	if _lRet .and. ! GDDeleted () .and. empty (GDFieldGet ("C7_CC"))
		_wtpprod = fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("C7_PRODUTO"), 'B1_TIPO' )
		//if ! _wtpprod $ 'MR/MP/PS/ME/PP/PI/VD/PA/SP/MA/UC/EP/ML/MX/MB/MT/CL/II'
		//if ! _wtpprod $ GetMV ("VA_GRPSB1")
			//if _wtpprod = 'GG' .and. alltrim(GDFieldGet ("C7_PRODUTO")) $'7103/7110/7082/7087/7066/7159/7012/7013/7050/7048/7122/7061'
			if ! substr(alltrim(GDFieldGet ("C1_CONTA")),1,1) $ "4/7"
				// produtos considerados excessao - chamado 
				_lRet = .T.	
			else 
				msgalert ("Obrigatório informar centro de custo para este item.")
				_lRet = .F.
			endif				
		//endif
	endif
	
	if _lRet .and. ! GDDeleted () .and. (GDFieldGet ("C7_DATPRF") < DATE()) .and. (GDFieldGet ("C7_ENCER") = 'E' )
		U_Help ("Data de entrega não pode ser menor que data atual.")
		_lRet = .F.
	endif
	
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
	

return _lRet