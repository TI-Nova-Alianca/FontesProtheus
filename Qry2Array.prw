// Programa:  Qry2Array
// Autor:     Robert Koch
// Data:      24/10/2006
// Cliente:   Generico
// Descricao: Gera array multidimensional a partir de uma query (util para gerar multiline, por exemplo)
//
// Historico de alteracoes:
// 02/12/2010 - Robert - Execucao do comando TCSetField passa a ser opcional (ganho de performance).
//                     - Trocada funcao U_ML_SRArea por GetArea para ganho de performance.
//                     - Passa a retornar nomes dos campos na array, caso seja solicitado.
//

// --------------------------------------------------------------------------
user function Qry2Array (_sQuery, _lSetField, _lRetNomes)
	local _aLinha    := {}
	local _aArray    := {}
	//local _aCampos   := {}
	local _aAreaQry  := GetArea ()
	local _aAreaSX3  := {}
	//local _aEstrut   := {}
	local _nCampo	 := 0
	local _sAliasQ   := ""
	
	_lSetField = iif (_lSetField == NIL, .T., _lSetField)
	_lRetNomes = iif (_lRetNomes == NIL, .F., _lRetNomes)

	// Executa a query para saber quais os campos retornados.
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
	
	// Altera tipo de campos data cfe. dicionario de dados.
	if _lSetField
		dbselectarea ("SX3")
		_aAreaSX3 = GetArea ()
		sx3 -> (dbsetorder (2))
		for _nCampo = 1 to (_sAliasQ) -> (fcount ())
			if sx3 -> (dbseek (padr (alltrim ((_sAliasQ) -> (FieldName (_nCampo))), 10, " "), .F.))
				if sx3 -> x3_tipo $ "ND"  // Numerico ou data
					TCSetField (_sAliasQ, sx3 -> x3_campo, sx3 -> x3_tipo, sx3 -> x3_tamanho, sx3 -> x3_decimal)
				endif
			endif
		next
		RestArea (_aAreaSX3)
	endif

	_aArray = {}

	// Insere na array uma linha com os nomes dos campos
	if _lRetNomes
		aadd (_aArray, array (len ((_saliasQ) -> (dbstruct ()))))
		for _nCampo = 1 to (_sAliasQ) -> (fcount ())
			_aArray [1, _nCampo] = (_sAliasQ) -> (fieldName (_nCampo))
		next
	endif

	// Passa dados para a array
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())
		_aLinha = {}
		for _nCampo = 1 to (_sAliasQ) -> (fcount ())
			aadd (_aLinha, (_sAliasQ) -> (fieldget (_nCampo)))
		next
		aadd (_aArray, aclone (_aLinha))
		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())
	
	RestArea (_aAreaQry)
return _aArray
