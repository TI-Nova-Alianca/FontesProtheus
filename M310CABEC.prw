// Programa...: M310CABEC
// Autor......: Andre Alves
// Data.......: 06/04/2020
// Descricao..: Manipulação do array aCabec 
//              Executada após a montagem do array Acabec antes das chamadas das rotinas 
//              automáticas que irão gerar 
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Manipulação do array aCabec
// #PalavasChave      #Transferencias #Transferencias_de_produtos #transferencias_entre_filiais 
// #TabelasPrincipais #SC5 #SC6 #SD1 #SF1
// #Modulos   		  #COM 
//
// Historico de alteracoes:
// 06/04/2020 - Andre   - Criado par preencher Frete na tela de transferencia entre filiais.
// 01/09/2021 - Claudia - Incluido a gravação do campo C5_INDPRES que é obrigatório. GLPI: 10881
//
// ---------------------------------------------------------------------------------------------------
User Function M310CABEC
	Local cProg  := PARAMIXB[1]
	Local aCabec := PARAMIXB[2]
	local _sTPFrete := ""
	local _sTransp  := ""

	If cProg == 'MATA410' 
	    _sTPFrete = U_Get ("Informe o tipo de frete:", "C", 1, "", "", sc5 -> c5_tpfrete, .F., '.t.')
	   	aadd(aCabec,{'C5_TPFRETE',_sTPFrete,Nil})

	   	_sTransp = U_Get ("Informe a transportadora:", "C", 6, "", "SA4", sc5 -> c5_transp, .F., '.t.')
	   	aadd(aCabec,{'C5_TRANSP', _sTransp,Nil})

		aadd(aCabec,{'C5_INDPRES', '1',Nil})
	endif
Return(aCabec)
