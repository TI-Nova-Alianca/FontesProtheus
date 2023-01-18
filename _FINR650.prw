// Programa...: _FINR650
// Autor......: Cl�udia Lion�o
// Data.......: 10/08/2022
// Descricao..: Relat�rio retorno do CNAB 
//              Customizado para poder trazer a tela de eventos de juros indevidos
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relat�rio
// #Descricao         #Relat�rio retorno do CNAB 
// #PalavasChave      #CNAB  
// #TabelasPrincipais #SE1 #SE5 #ZB5
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
// 10/08/2022 - Claudia - Incluida grava��o de eventos de juros indevidos. GLPI: 12454
// 18/01/2023 - Claudia - Verifica��o de juros indevido existente. GLPI: 10907
//
// ---------------------------------------------------------------------------------------------------------------
User Function _FINR650()
    local _cMens    := ""
	Private _nValJuros := 0
	
    // chama relatorio
    FINR650()

	If _nValJuros > 0
		_cMens := "Deseja abrir a tela de eventos CNAB - Juros indevidos?"
		If msgyesno(_cMens,"Confirmar")
			U_VA_CNABEV()
		EndIf
	EndIf
Return
