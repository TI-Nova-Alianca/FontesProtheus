// Programa...: F3ZX5
// Autor......: Robert Koch - TCX021
// Data.......: 07/07/2009
// Descricao..: Browse de uma tabela do ZX5 (tabelas genéricas Alianca) para ser chamado via F3.
//
// Como cadastrar no SXB: selecionar "consulta especifica" e informar U_F3AMG() no campo "expressao"
// Obs.1: O execblock ja deve deixar a tabela posicionada para retorno.
// Obs.2: O execblock deve retornar .T. para que a consulta seja aceita.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #generico
// #Descricao         #Browse de uma tabela do ZX5 (tabelas genéricas Alianca) para ser chamado via F3.
// #PalavasChave      #ZX5 #ZX5_F3 #F3 
// #TabelasPrincipais #ZX5
// #Modulos           #todos
//
// Historico de alteracoes:
// 16/12/2010 - Robert  - Criado tratamento para o campo ZX5_MODO.
// 06/01/2011 - Robert  - Criado parametro para receber expressao para filtragem de registros.
// 11/08/2012 - Robert  - Criado parametro para receber array com nomes de campos para ordenacao do browse.
// 12/05/2021 - Claudia - Ajustada a chamada SX5 para R27. GLPI: 8825
// 01/09/2021 - Robert  - Leitura do SX3 nao filtrava registros deletados.
//

#include "rwmake.ch"

// -----------------------------------------------------------------------------------
User Function F3ZX5 (_sTabela, _sFiltro, _aCposOrd)
	local _aOpcoes  := {}
	local _nOpcao   := 0
	local _aAreaAnt := U_ML_SRArea ()
	local _aCampos  := {}
	local _aCpos    := {}
	local _nCampo   := 0
	local _sCampo   := ""
	local _aLinha   := {}
	local _sTxtSup  := ""
	local _sFilial  := ""
	local _nCpoOrd1 := 0
	local _nCpoOrd2 := 0
	local _x        := 0
	local _i        := 0

	// Busca nome da tabela
	zx5 -> (dbsetorder (1))  // ZX5_FILIAL+ZX5_TABELA+ZX5_CHAVE
	if zx5 -> (dbseek ("  " + "00" + _sTabela, .F.))
		_sTxtSup = "Consulta tabela generica " + _sTabela + " - " + zx5 -> zx5_descri
		_sFilial  = iif (zx5 -> zx5_modo == "C", "  ", cFilAnt)
	endif
	
	// Monta lista dos campos a serem lidos para o browse.
	_aCpos = {}
	for _nCampo = 1 to zx5 -> (fcount ())
		_sCampo = zx5 -> (fieldname (_nCampo))
		if left (_sCampo, 6) == "ZX5_" + _sTabela
			aadd (_aCpos, _sCampo)
		endif
	next
	
	// Monta array de opcoes a mostrar ao usuario.
	_aOpcoes = {}
	dbselectarea ("ZX5")
	zx5 -> (dbsetorder (1))  // ZX5_FILIAL+ZX5_TABELA+ZX5_CHAVE
	zx5 -> (dbseek (_sFilial + _sTabela, .T.))

	do while ! zx5 -> (eof ()) .and. zx5 -> zx5_filial == _sFilial .and. zx5 -> zx5_tabela == _sTabela
		// Aplica filtro, caso tenha sido informado.
		if _sFiltro != NIL .and. ! &(_sFiltro)
			zx5 -> (dbskip ())
			loop
		endif

		_aLinha = {}
		for _nCampo = 1 to len (_aCpos)
			aadd (_aLinha, zx5 -> &(_aCpos [_nCampo]))
		next
		aadd (_aLinha, zx5 -> (recno ()))
		aadd (_aOpcoes, aclone (_aLinha))
		zx5 -> (dbskip ())
	enddo

	_nCpoOrd1 = 0
	_nCpoOrd2 = 0
	
	// Encontra as colunas do browse onde estao os campos a serem usados para ordenacao.
	if valtype (_aCposOrd) == 'A'
		if len (_aCposOrd) >= 1 .and. valtype (_aCposOrd [1]) == 'C'
			_nCpoOrd1 = ascan (_aCpos, _aCposOrd [1])
		endif
	endif

	if valtype (_aCposOrd) == 'A'
		if len (_aCposOrd) >= 2 .and. valtype (_aCposOrd [2]) == 'C'
			_nCpoOrd2 = ascan (_aCpos, _aCposOrd [2])
		endif
	endif

	// Se os campos estao no browse...
	if _nCpoOrd1 > 0
		if _nCpoOrd2 > 0
			_aOpcoes = asort (_aOpcoes,,, {|_x, _y| _x [_nCpoOrd1] + _x [_nCpoOrd2] < _y [_nCpoOrd1] + _y [_nCpoOrd2]})
		else
			_aOpcoes = asort (_aOpcoes,,, {|_x, _y| _x [_nCpoOrd1] < _y [_nCpoOrd1]})
		endif
	endif

	// Monta titulos dos campos para o browse
	_aCampos = {}

	For _x:= 1 to Len(_aCpos)
		_oSQL  := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += " 	   X3_TITULO  "
		_oSQL:_sQuery += "    ,X3_TAMANHO "
		_oSQL:_sQuery += "    ,X3_PICTURE "
	//	_oSQL:_sQuery += " FROM SX3010 "
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SX3")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND X3_CAMPO = '" + _aCpos[_x] + "'"
		_aSX3 := aclone (_oSQL:Qry2Array ())

		For _i:=1 to Len(_aSX3)
			aadd (_aCampos, {_x, _aSX3[_i,1], _aSX3[_i,2] * 5, alltrim (_aSX3[_i,3])})
		Next
	Next

	U_ML_SRArea (_aAreaAnt)

	// Deixa o arquivo posicionado no registro selecionado.
	if len (_aCampos) == 0
		u_help ("Nao foi encontrado nenhum campo para esta consulta.")
	else
		_nOpcao = u_F3Array (_aOpcoes, "Selecione opcao:", _aCampos, NIL, NIL, _sTxtSup, "", .F.)
		if _nOpcao > 0
			zx5 -> (dbgoto (_aOpcoes [_nOpcao, len (_aCampos) + 1]))
		endif
	endif

return (_nOpcao > 0)
