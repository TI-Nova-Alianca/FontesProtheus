// Programa...: NxtD3Doc
// Autor......: Robert Koch
// Data.......: 29/11/2014
// Descricao..: Busca proxima sequencia para campo D3_DOC.
//              Criado para poder usar lacunas que ficaram no sequenciamento do campo, devido
//              a estar como 'alteravel' nas telas, e os usuarios (eu, inclusive) digitaram
//              numeros de documento que fizeram pular o sequenciamento.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function NxtD3Doc ()
	local _sRet     := ""
	local _aAreaSD3 := sd3 -> (getarea ())
	local _sDocIni  := ""
		
	// Procura o usar lacunas no D3_DOC. Conforme houver novas lacunas, ajustar este programa.
	if cEmpAnt + cFilAnt == '0101'
		_sDocIni = 'BBBBBB'  // Quando chegar ateh aqui, verificar nova lacuna no D3_DOC e alterar este programa.
		sd3 -> (dbsetorder (2))  // D3_FILIAL+D3_DOC+D3_COD
		sd3 -> (dbseek (xfilial ("SD3") + _sDocIni, .T.))
		//u_log ('Encontrei', sd3 -> d3_doc)
		sd3 -> (dbskip (-1))
		//u_log ('Anterior:', sd3 -> d3_doc)
		_sRet = soma1 (sd3 -> d3_doc)
		
		// Se a sequencia estah toda cheia, deixa retorno vazio para usas funcao original logo adiante.
		if _sRet == _sDocIni
			//u_log ('Doc inicial jah existe')
			_sRet = ''
		endif
	endif
	
	// Se nao achou nada, usa funcao original.
	if empty (_sRet)
		_sRet = nextnumero ("SD3", 2, "D3_DOC", .t.)
	endif

	restarea (_aAreaSD3)
return _sRet
