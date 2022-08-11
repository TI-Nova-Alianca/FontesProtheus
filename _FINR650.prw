// Programa...: _FINR650
// Autor......: Cláudia Lionço
// Data.......: 10/08/2022
// Descricao..: Relatório retorno do CNAB 
//              Customizado para poder trazer a tela de eventos de juros indevidos
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatório
// #Descricao         #Relatório retorno do CNAB 
// #PalavasChave      #CNAB  
// #TabelasPrincipais #SE1 #SE5 #ZB5
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
// 10/08/2022 - Claudia - Incluida gravação de eventos de juros indevidos. GLPI: 12454
//
// ---------------------------------------------------------------------------------------------------------------

User Function _FINR650()
    local _cMens := ""
    
    // chama relatorio
    FINR650()
	_cMens := "Deseja abrir a tela de eventos CNAB - Juros indevidos?"

	If msgyesno(_cMens,"Confirmar")
		U_VA_CNABEV()
	EndIf
Return
