// Programa:   AmbTeste
// Autor:      Robert Koch
// Data:       08/11/2022
// Descricao:  Retorna .T. se entender que encontra-se em embiente de testes (nao producao)

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Retorna .T. se entender que encontra-se em embiente de testes (nao producao)
// #PalavasChave      #auxiliar #uso_generico
// #TabelasPrincipais 
// #Modulos           #todos_modulos

// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function AmbTeste ()
	local _lBaseTST := .F.
	
	if "TESTE" $ upper (GetEnvServer()) .or. "PADRAO" $ upper (GetEnvServer()) 
		U_Log2 ('debug', '[' + procname () + '.' + procname (1) + '.' + procname (2) + '.' + procname (3) + ']Entendo que estou operando em ambiente de teste / homologacao.')
		_lBaseTST = .T.
	endif
return _lBaseTst
