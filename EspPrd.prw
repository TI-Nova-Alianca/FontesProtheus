// Programa:   EspPrd
// Autor:      Robert Koch
// Data:       06/08/2015
// Descricao:  Tratamentos especificacoes tecnicas de produtos.
//             Criado inicialmente para chamar consulta de arquivo PDF em tela.
// 
// Historico de alteracoes:
// 06/10/2015 - Robert - Recebe a extensao do arquivo por parametro.
//

// --------------------------------------------------------------------------
user function EspPrd (_sProduto, _sExtensao)
	local _aAreaAnt  := U_ML_SRArea ()
	local _sArq      := ""
	local _lContinua := .T.

	u_logIni ()
	sb1 -> (dbsetorder (1))
	if _lContinua .and. ! sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
		u_help ("Produto '" + _sProduto + "' nao cadastrado!")
		_lContinua = .F.
	endif
	if _lContinua
		_sArq = "\\192.168.1.5\esp_mat\" + sb1 -> b1_tipo + '\' + alltrim (_sProduto) + '.' + _sExtensao
	endif

	if _lContinua

		// Como a funcao FILE exige uma letra de unidade mapeada, optei por nao testar a existencia do arquivo.
		//if ! file (_sArq)
		//	u_help ("Arquivo '" + _sArq + "' nao existe ou nao encontra-se disponivel para acesso.")
		//endif
		winexec ("cmd /c start " + _sArq)

	endif

	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return
