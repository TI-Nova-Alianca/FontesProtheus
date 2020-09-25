// Programa...: ArqTrb
// Autor......: Robert Koch
// Data.......: 19/09/2002
// Descricao..: Cria ou deleta arquivos de trabalho e seus indices.
// Parametros: operacao -> "CRIA"        = cria novo arquivo de trabalho c/ o alias especificado
//                         "FECHA"       = fecha o arq. trab. com o alias especificado
//                         "FECHATODOS"  = fecha todos os arq. trab. criados por esta rotina.
//                         "DEIXAABERTO" = Elimina este arq. de trabalho da lista interna sem fecha-lo.
//             alias    -> Alias pelo qual o arq. trabalho vai ser acessado
//             campos   -> Array com estrutura de campos no modelo dbstruct()
//             indices  -> Array de strings com as expressoes para indices. Se nao informada,
//                         nao sera criado nenhum indice.
//             arqlist  -> Array local do programa chamador onde serao guardados os nomes fisicos dos
//                         de arquivos de dados e indices criados. Deve ser passada pelo programa
//                         chamador por referencia (com @ no inicio).
//
// Historico de alteracoes:
// 02/04/2003 - Robert - Possibilita a criacao de mais de um indice
// 28/05/2003 - Robert - Aceita a chamada sem o vetor de indices
// 17/09/2003 - Robert - Criado parametro 'DeixaAberto'
// 25/02/2004 - Robert - Passado de static para user function
// 05/04/2004 - Robert - Criado parametro para passar por referencia a array de arquivos
// 29/08/2015 - Robert - Funcao msgalert trocada por u_help.
// 24/10/2019 - Robert - Adequacao para usar a classe FWTemporaryTable e nao mais o driver ISAM (exigencia release 12.1.25 do Protheus)
// 26/02/2020 - Robert - Acrescentados alguns nomes de campos `a lista de palavras reservadas.
//
// --------------------------------------------------------------------------
user function ArqTrb (_sOperacao, _sAlias, _aCampos, _aIndices, _aArqList)
	local _nArq     := 0   // Contador de arquivos
	local _nIndice  := 0   // Contador de indices
	local _sIndice  := ''
	local _aIndAux  := {}
	local _oTempTbl := NIL

	if _aIndices == NIL
		_aIndices := {}
	endif
	
	if _aArqList == NIL
		u_help ('Erro ' + procname () + ": Variavel para lista de arquivos nao informada. Verifique programa chamador: " + procname (1))
		return
	endif
	
	do case
		case upper (_sOperacao) == "CRIA"
			//u_log ('criando alias ' + _sAlias + ' com os campos:', _aCampos)
			if ascan (_aArqList, {|_aVal| _aVal [1] == _sAlias}) > 0
				u_help ('Erro ' + procname () + ": Alias " + _sAlias + " ja existe. Verifique programa chamador: " + procname (1))
				return .F.
			endif

			// Verifica nomes de campos que me deram erro, provavelmente por que o SQL nao aceita.
			if ascan (_aCampos, {|_x| upper (alltrim (_x [1])) $ 'PERCENT/DESC/ASC/ORDER/GROUP'}) > 0
				u_help ('Erro ' + procname () + ": uso de nome de campo nao permitido (palavra reservada do SQL)")
				return .F.
			endif

			_oTempTbl := FWTemporaryTable():New (_sAlias)
			_oTempTbl:SetFields (_aCampos)

			// Transforma a lista de indices (campos concatenados com '+') para o formato exigido pela classe.
			for _nIndice = 1 to len (_aIndices)
			//	u_log ('adicionando indice:', _aIndices [_nIndice])
				_sIndice = strtran (_aIndices [_nIndice], ' ', '')  // Remove espacos

				// Se tiver funcoes aplicadas (DTOS, ALLTRIM, SUBSTRING, ...) tem que remover no programa chamador.
				if '(' $ _sIndice .or. ')' $ _sIndice
					u_help ('Erro ' + procname () + ': Nao eh suportado o uso de funcoes na definicao dos indices. Revisar: ' + _sIndice)
					return .F.
				endif

				_aIndAux = StrTokArr (_sIndice, '+')
				_oTempTbl:AddIndex (strzero (_nIndice, 2), _aIndAux)
			next
			_oTempTbl:Create ()

			// Guarda o arq. criado e seus indices na lista geral de arq. criados.
			aadd (_aArqList, {_sAlias, _oTempTbl})
			//u_log ('novo _aArqList:', _aArqList)
			//u_logObj (_aArqList [len (_aArqList), 2])
			
		// Fecha o alias informado e seus indices
		case upper (_sOperacao) == "FECHA"
			//u_log ('Fechando alias', _sAlias)
			_nArq = ascan (_aArqList, {|_aVal| _aVal [1] == _sAlias})
			if _nArq != 0
				_oTempTbl = _aArqList [_nArq, 2]
				_oTempTbl:Delete ()
				afill (_aArqList [_nArq], "")
				//u_log ('fechei')
			endif

		// Fecha todos os arq. criados e seus indices
		case upper (_sOperacao) == "FECHATODOS"
			for _nArq = 1 to len (_aArqList)
				if _aArqList [_nArq, 1] != ""
					//u_log ('Fechando todos: alias', _aArqList [_nArq, 1])
					_oTempTbl = _aArqList [_nArq, 2]
					_oTempTbl:Delete ()
				endif
			next
			_aArqList = {}
			
		// 'Esquece' este arquivo de trabalho. Elimina-o da lista, deixando-o aberto.
		// Isto eh util para casos em que a rotina chamadora vai terminar e deixar o
		// arquivo aberto para outra rotina, por exemplo.
		case upper (_sOperacao) == "DEIXAABERTO"
			_nArq = ascan (_aArqList, {|_aVal| _aVal [1] == _sAlias})
			if _nArq != 0
				afill (_aArqList [_nArq], "")
			endif		
	endcase
	
		/* Versao original
	local  _nArq     := 0   // Contador de arquivos
	local  _sArqInd  := ""  // Nome do arquivo de indice a ser criado
	local  _sArqDBF  := ""  // Nome do arquivo DBF a ser criado
	local  _nIndice  := 0   // Contador de indices
	local  _aArqInd  := {}  // Arquivos de indices criados para o arquivo atual
	
	if _aIndices == NIL
		_aIndices := {}
	endif
	if _aArqList == NIL
		u_help (procname () + ": Variavel para lista de arquivos nao informada. Verifique programa chamador: " + procname (1))
		return
	endif
	
	do case
		case upper (_sOperacao) == "CRIA"
			if ascan (_aArqList, {|_aVal| _aVal [1] == _sAlias}) > 0
				u_help (procname () + ": Alias " + _sAlias + " ja existe. Verifique programa chamador: " + procname (1))
				return .F.
			endif
			_sArqDBF = criatrab (_aCampos, .T.)
			dbusearea (.T.,, _sArqDBF, _sAlias, .F., .F.)
			
			// Cria um arquivo para cada indice
			for _nIndice = 1 to len (_aIndices)
				_sArqInd = criatrab ("", .F.)
				//u_log ('Criando indice no arquivo', _sArqInd)
				index on &(_aIndices [_nIndice]) to (_sArqInd)
				aadd (_aArqInd, _sArqInd)
				//u_log (_aArqInd)
			next
			
			// Fecha o ultimo indice criado e reabre todos
			set index to
			for _nIndice = 1 to len (_aArqInd)
				//u_log ('Abrindo indice', _nIndice, _aArqInd [_nIndice])
				dbsetindex (_aArqInd [_nIndice])  // Abre indices
			next
			
			// Guarda o arq. criado e seus indices na lista geral de arq. criados.
			aadd (_aArqList, {_sAlias, _sArqDBF, _aArqInd})
			
			
		// Fecha o alias informado e seus indices
		case upper (_sOperacao) == "FECHA"
			_nArq = ascan (_aArqList, {|_aVal| _aVal [1] == _sAlias})
			if _nArq != 0
				(_sAlias) -> (dbclosearea ())
				ferase (_aArqList [_nArq, 2] + ".dbf")
				for _nIndice = 1 to len (_aArqList [_nArq, 3])
					ferase (_aArqList [_nArq, 3, _nIndice] + OrdBagExt ())
				next
				afill (_aArqList [_nArq], "")
			endif
			
			
		// Fecha todos os arq. criados e seus indices
		case upper (_sOperacao) == "FECHATODOS"
			for _nArq = 1 to len (_aArqList)
				if _aArqList [_nArq, 1] != ""
					(_aArqList [_nArq, 1]) -> (dbclosearea ())
					ferase (_aArqList [_nArq, 2] + ".dbf")
					for _nIndice = 1 to len (_aArqList [_nArq, 3])
						ferase (_aArqList [_nArq, 3, _nIndice] + OrdBagExt ())
					next
				endif
			next
			_aArqList = {}
			

		// 'Esquece' este arquivo de trabalho. Elimina-o da lista, deixando-o aberto.
		// Isto eh util para casos em que a rotina chamadora vai terminar e deixar o
		// arquivo aberto para outra rotina, por exemplo.
		case upper (_sOperacao) == "DEIXAABERTO"
			_nArq = ascan (_aArqList, {|_aVal| _aVal [1] == _sAlias})
			if _nArq != 0
				afill (_aArqList [_nArq], "")
			endif
			
	endcase
*/

return .T.
