// Programa.: MT120LOk
// Autor....: Andre Alves
// Data.....: 25/07/2019
// Funcao...: PE 'Linha OK' na manutencao de pedidos de compra.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #PE 'Linha OK' na manutencao de pedidos de compra.
// #PalavasChave      #ponto_de_entrada #pedido_de_compra
// #TabelasPrincipais #SC7
// #Modulos           #COM 
//
// Historico de alteracoes:
// 27/03/2020 - Andre   - Adicionada validação para data de entrega não ser menor que data atual.
// 12/04/2021 - Claudia - Validação Centro de Custo X COnta Contábil
//
// ----------------------------------------------------------------------------------------------------------------------------------------------------
User Function MT120LOk ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()

	u_help("mt120lok")

	// obriga informacao do centro de custo
	if _lRet .and. ! GDDeleted () .and. empty (GDFieldGet ("C7_CC"))
		_wtpprod = fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("C7_PRODUTO"), 'B1_TIPO' )

		if ! substr(alltrim(GDFieldGet ("C1_CONTA")),1,1) $ "4/7"
			_lRet = .T.		// produtos considerados excessao - chamado 
		else 
			u_help ("Obrigatório informar centro de custo para este item.")
			_lRet = .F.
		endif				
	endif
	
	if _lRet .and. ! GDDeleted () .and. (GDFieldGet ("C7_DATPRF") < DATE()) .and. (GDFieldGet ("C7_ENCER") = 'E' )
		U_Help ("Data de entrega não pode ser menor que data atual.")
		_lRet = .F.
	endif

	//validação de Centro de custo X conta contábil
	if GetMv("VA_CUSXCON") == 'S' .and. _lRet // parametro para realizar as validações
		if _lRet .and. ! GDDeleted ()
			if !empty(GDFieldGet("C7_CONTA")) .and. !empty(GDFieldGet("C7_CC"))
				_sConta := U_VA_CUSXCON(GDFieldGet("C7_CONTA"),'1')
				_sCC    := U_VA_CUSXCON(GDFieldGet("C7_CC"   ),'2')

				if alltrim(_sConta) <> alltrim(_sCC)
					u_help ("Divergencia no cadastro de Amarração C.Custo X C.Contabil. Grupo C.Custo:" + alltrim(_sCC) + " Grupo C.Contabil:" + alltrim(_sConta))
					_lRet = .F.
				endif
			endif
		endif
	endif
	
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
	
Return _lRet
