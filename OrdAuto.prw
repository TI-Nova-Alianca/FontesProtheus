// Programa...: OrdAuto
// Autor......: Robert Koch
// Data.......: 15/06/2003
// Cliente....: Generico
// Descricao..: Ordena array para uso em rotina automatica conforme ordem dos
//              campos no SX3. Isso por que, se os campos forem enviados fora de
//              ordem, os gatilhos podem fazer as coisas mais inusitadas...

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Generico
// #Descricao         #Ordena lista de campos para rotinas automaticas.
// #PalavasChave      #generico
// #TabelasPrincipais #
// #Modulos           #Todos

// Historico de alteracoes:
// 02/03/2006 - Robert - Nao aceitava campos que nao constam no SX3.
// 07/03/2022 - Robert - Verifica nivel de acesso e se os campos encontram-se em uso (GLPI 11721)
// 09/03/2022 - Robert - Verifica se o campo encontra-se usado pelo modulo atual
// 11/03/2022 - Robert - Erro de 'campo nao usado' aparecia em tela. Mudado para log de erro (causava panico desnecessario entre os usuarios)
// 24/08/2022 - Robert - Valida tipo do campo X tipo da variavel recebida.
// 28/03/2023 - Robert - Criada excecao nos avisos para campos especificos como ATUEMP/AUTBANCO/AUTAGENCIA/AUTCONTA
//

// --------------------------------------------------------------------------
user function OrdAuto (_aMatriz)
	local _aMat     := {}
	local _aMatNova := {}
	local _nLinha   := 0
	local _sOrdem   := ""
	local _aAreaSX3 := sx3 -> (getarea ())

	// Monta uma matriz equivalente, com a ordem dos campos no SX3
	sx3 -> (dbsetorder (2))
	for _nLinha = 1 to len (_aMatriz)

		// Como algumas rotinas automaticas aceitam 'campos' nao presentes no
		// SX3 (por exemplo 'INDEX' ou 'AUTEXPLODE') tento deixa-los na primeira
		// posicao ou na ultima.
		if sx3 -> (dbseek (padr (_aMatriz [_nLinha, 1], 10, ' '), .F.))  // Preenche com especos por que jah tive problemas, por exemplo, ao passar E2_VRETIR quando devia ter passado E2_VRETIRF.

			// Em 24/08/2022 tive problema com campo caracter e que mandei tipo numerico.
			if valtype (_aMatriz [_nLinha, 2]) != sx3 -> x3_tipo
				U_Log2 ('erro', "[" + procname () + "]Campo '" + _aMatriz [_nLinha, 1] + "' consta com tipo '" + sx3 -> x3_tipo + "' no configurador, mas recebi tipo '" + valtype (_aMatriz [_nLinha, 2]) + "'.")
				u_logpcham ()
			endif

			// Em 07/03/2022 tive problema com campo que foi tirado de uso por um UPDDISTR (GLPI 11721)
			if ! X3Uso (sx3 -> x3_usado)
				U_Log2 ('erro', "[" + procname () + "]Campo '" + _aMatriz [_nLinha, 1] + "' nao encontra-se 'usado' e pode nao ser considerado pela rotina automatica.")
				u_logpcham ()
			endif

			if cNivel < sx3 -> x3_nivel
				U_Log2 ('erro', "[" + procname () + "]Campo '" + _aMatriz [_nLinha, 1] + "' possui nivel " + cvaltochar (sx3 -> x3_nivel) + ", mas o usuario atual possui nivel menor (" + cvaltochar (cNivel) + "). Campo pode nao ser considerado pela rotina automatica.")
				u_logpcham ()
			endif

			_sOrdem = sx3 -> x3_ordem
		else
			_sOrdem = iif (_nLinha == 1, "  ", "ZZ")
			if ! upper (alltrim (_aMatriz [_nLinha, 1])) $ "ATUEMP/AUTBANCO/AUTAGENCIA/AUTCONTA"  // Alguns campos chave em determinadas telas.
				U_Log2 ('aviso', '[' + procname () + "]Campo '" + _aMatriz [_nLinha, 1] + "' nao encontrado no SX3. Vai ficar ordenado na posicao '" + _sOrdem + "'")
			endif
		endif
		aadd (_aMat, {_aMatriz [_nLinha, 1], _aMatriz [_nLinha, 2], _aMatriz [_nLinha, 3], _sOrdem})
	next

	// Ordena campos cfe. SX3
	_aMat := asort (_aMat,,, {|_x, _y| _x [4] < _y [4]})

	// Remonta a matriz original ordenada.
	for _nLinha = 1 to len (_aMat)
		aadd (_aMatNova, {_aMat [_nLinha, 1], _aMat [_nLinha, 2], _aMat [_nLinha, 3]})
	next

	restarea (_aAreaSX3)
return _aMatNova
