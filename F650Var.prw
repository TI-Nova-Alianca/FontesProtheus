// Programa:   F650Var
// Autor:      Robert Koch
// Data:       16/06/2010
// Cliente:    Alianca
// Descricao:  P.E. para manipulacao de valores na impressao do relatorio de comunicacao bancaria (FINR650)
// 
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function F650Var ()
	local aValores := aclone (paramixb [1])
	
	// Chama ponto de entrada do processamento do retorno de CNAB a receber (FINA200) para que haja
	// consistencia entre o relatorio e a recepcao bancaria.
	
	ExecBlock("F200VAR",.F.,.F.,{aValores})
return

