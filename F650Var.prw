// Programa.: F650Var
// Autor....: Robert Koch
// Data.....: 16/06/2010
// Cliente..: Alianca
// Descricao: P.E. para manipulacao de valores na impressao do relatorio de comunicacao bancaria (FINR650)
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. para manipulacao de valores na impressao do relatorio de comunicacao bancaria (FINR650)
// #PalavasChave      #CNAB  
// #TabelasPrincipais #SE1 #SE5 #ZB5
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
// 18/01/2023 - Claudia - Verifica��o de juros indevido existente. GLPI: 10907
//
// --------------------------------------------------------------------------
user function F650Var ()
	local aValores := aclone (paramixb [1])
	
	// Chama ponto de entrada do processamento do retorno de CNAB a receber (FINA200) para que haja
	// consistencia entre o relatorio e a recepcao bancaria.
	
	ExecBlock("F200VAR",.F.,.F.,{aValores})

	If aValores[9] > 0
		_nValJuros ++
	EndIf
return

