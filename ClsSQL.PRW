// Programa:  ClsSQL
// Autor:     Robert Koch
// Data:      14/12/2011
// Descricao: Declaracao de classe de utilitarios para SQL, para uso em outros programas.
//            Poderia trabalhar como uma include, mas prefiro declarar uma funcao de usuario
//            apenas para poder incluir no projeto e manter na pasta dos fontes.
//
// Historico de alteracoes:
// 23/12/2011 - Robert - Criado metodo Qry2Trb.
// 27/12/2011 - Robert - Criado metodo Exec.
// 12/04/2012 - Robert - Criado metodo Qry2HTM.
// 28/06/2012 - Robert - Criados metodos MudaTipo e SetField.
//                     - Criados atributos _aSetField e _sAliasQry.
// 23/08/2012 - Robert - Metodo RetQry passa a receber parametro que permite desabilitar SetField.
// 19/11/2012 - Robert - Criado metodo CaseX3CBox.
// 22/08/2012 - Robert - Criado metodo Qry2XLS.
// 01/02/2014 - Robert - Criado metodo F3Array.
// 22/06/2015 - Robert - Criado metodo InsValues.
// 09/09/2015 - Robert - Criado metodo Array2IN.
// 14/09/2015 - Robert - Removido metodo BaseRepl (nao temos mais servidor de replica).
//                     - Metodo F3Array passa a aceitar parametro 'mostra sempre'.
// 01/04/2016 - Robert - Criado atributo TempoExec.
// 08/04/2016 - Robert - Melhorado calculo de largura de colunas para mostrar via F3Array().
// 24/06/2016 - Robert - Mostra SQL junto com a mensagem quando houver erro no metodo Exec().
// 21/10/2016 - Robert - Revisao geral. Passa a gerar as consultas todas na function _ExecQry
//                     - Passa a guardar uma array com 'aHeader' ref. estrutura do arq.trab. gerado pela query.
// 19/04/2018 - Robert - Desabilitados atributos :TempoExec e :_aHeader para melhora de performance.
//                     - Criado metodo AHeader().
// 06/11/2018 - Robert - Criado parametro para fixar decimais no metodo Copy2Trb.
// 19/08/2019 - Robert - Melhoradas mensagens de erro no metodo Exec() para que verifique, tambem, a funcao TCSQLError().
// 10/10/2019 - Robert - Gera aviso para TI em caso de erro na execucao do SQL.
//

#include "protheus.ch"

// ==========================================================================
// Classe usada para operacoes genericas com arrays.
CLASS ClsSQL

	// Declaracao das propriedades da Classe
	DATA _sQuery
	DATA _xRetQry
	DATA _aSetField
	DATA _sAliasQry
	DATA UltMsg
	DATA TempoExec
	DATA lGeraHead
	DATA aHeader


	// Declaracao dos Metodos da Classe
	METHOD New ()
	METHOD Array2In ()
	METHOD CaseX3CBox ()
	METHOD Copy2Trb ()
	METHOD Exec ()
	METHOD F3Array ()
	METHOD FormatIn ()
	METHOD InsValues ()
	METHOD Log ()
	METHOD MudaTipo ()  // Para uso interno.
	METHOD Qry2Array ()
	METHOD Qry2HTM ()
	METHOD Qry2Str ()
	METHOD Qry2Trb ()
	METHOD Qry2XLS ()
	METHOD RetQry ()
	METHOD SetField ()  // Para uso externo: informar campo e para qual tipo deve ser convertido.
ENDCLASS



// --------------------------------------------------------------------------
METHOD New () Class ClsSQL
	::aHeader    := {}
	::lGeraHead  := .F.
	::_sQuery    := ""
	::_xRetQry   := NIL
	::_aSetField := {}
	::_sAliasQry := ""
	::UltMsg     := ""
Return Self



// --------------------------------------------------------------------------
// Recebe uma array unidimensional e monta clausula para uso com comando IN do SQL.
METHOD Array2In (_aArray) Class ClsSQL
	local _sRet := ""
	local _nPos := 0
	
	if valtype (_aArray) != "A"
		::UltMsg += "Metodo " + procname () + ": Parametro recebido deve ser do tipo array."
	else
		for _nPos = 1 to len (_aArray)
			_sRet += _aArray [_nPos] + iif (_nPos < len (_aArray), '/', '')
		next
	endif
return FormatIn (_sRet, '/')



// --------------------------------------------------------------------------
// Monta uma clausula CASE para uso em query, retornando dados conforme o campo X3_CBOX.
METHOD CaseX3CBox (_sCampo) Class ClsSQL
	local _sRet      := ""
	local _aAreaSX3  := sx3 -> (getarea ())
	local _aOpcoes   := {}
	local _nOpcao    := 0

	sx3 -> (dbsetorder (2))
	if sx3 -> (dbseek (_sCampo, .F.)) .and. ! empty (sx3 -> x3_cbox)
		_sRet = " CASE " + upper (_sCampo) + " "
		_aOpcoes = U_SeparaCpo (sx3 -> x3_cbox, ';')
		for _nOpcao = 1 to len (_aOpcoes)
			_sRet += " WHEN '" + left (_aOpcoes [_nOpcao], at ('=', _aOpcoes [_nOpcao]) - 1) + "' "
			_sRet += " THEN '" + substr (_aOpcoes [_nOpcao], at ('=', _aOpcoes [_nOpcao]) + 1) + "' "
		next
		_sRet += ' END '
	else
		u_help ('[' + procname () + ']' + ": Campo '" + _sCampo + "' nao existe no SX3 ou nao tem opcoes no X3_CBOX.")
	endif
	restarea (_aAreaSX3)
return _sRet



// --------------------------------------------------------------------------
// Copia o resultado da query para um arquivo de trabalho real.
METHOD Copy2Trb (_lSetField, _nDecFixo) Class ClsSQL
	//local _sAliasQ   := ""
	local _sArqTrb   := ""
	local _nCampo    := 0
	local _nQtCampos := 0
	local _aAreaAnt  := U_ML_SRArea ()
	local _aEstrut   := {}

	_lSetField = iif (_lSetField == NIL, .T., _lSetField)
	::_sAliasQry = ::Qry2Trb (_lSetField)
	_aEstrut = (::_sAliasQry) -> (dbstruct ())

	// Altera campos numericos para o tamanho maximo, mantendo os decimais.
	if valtype (_nDecFixo) == "N"
		for _nCampo = 1 to len (_aEstrut)
			if _aEstrut [_nCampo, 2] == 'N'
				_aEstrut [_nCampo, 3] = 18 //- _nDecFixo - 1
				_aEstrut [_nCampo, 4] = _nDecFixo
			endif
		next
	endif
	//u_log (_aEstrut)
	_sArqTrb = CriaTrab (_aEstrut, .T.)

	_nQtCampos = (::_sAliasQry) -> (fcount ())
	use (_sArqTrb) exclusive new alias '_trb'
	(::_sAliasQry) -> (dbgotop ())
	do while ! (::_sAliasQry) -> (eof ())
		reclock ('_trb', .T.)
		for _nCampo = 1 to _nQtCampos
			_trb -> &(fieldname (_nCampo)) = (::_sAliasQry) -> &(fieldname (_nCampo))
		next
		msunlock ()
		(::_sAliasQry) -> (dbskip ())
	enddo
	(::_sAliasQry) -> (dbclosearea ())
return '_trb'



// --------------------------------------------------------------------------
// Executa comando no banco de dados.
METHOD Exec () Class ClsSQL
	local _lRet     := .T.
	local _nRetTOP  := 0
	local _sErroSQL := ''

	_nRetTOP = TCSQLExec (::_sQuery)
	if _nRetTOP < 0
		_sErroSQL = alltrim (TCSQLError ())
		if ! empty (_sErroSQL)
			_lRet = .F.
			::UltMsg = _sErroSQL
			u_help ("Erro DbAccess '" + cvaltochar (_nRetTOP) + "' durante a atualizacao dos dados!" + chr (13) + chr (10) + chr (13) + chr (10) + _sErroSQL)
			if type ('_oBatch') == 'O'
				_oBatch:Mensagens += "Erro DbAcces: " + cvaltochar (_nRetTOP)
			endif
			
			// Grava aviso. A gravacao do aviso, se executada direto via SQL, gera erro de estouro de pilha. Nao descobri o motivo. Robert, 10/10/2019.
			if existblock ("GRVAVISO")
				U_GrvAviso ('E', 'grpTI', _sErroSQL, procname (1) + '==>' + procname (2) + '==>' + procname (3), 0)
			endif
		else
			::UltMsg = "Erro DbAccess '" + cvaltochar (_nRetTOP) + "' ao executar: " + ::_sQuery
		endif
	endif
return _lRet



// --------------------------------------------------------------------------
// Exporta o resultado da query para array e mostra em tela via funcao F3Array.
METHOD F3Array (_sMsgTit, _lSempre) Class ClsSQL
	local _aAreaAnt  := U_ML_SRArea ()
	local _nCampo    := 0
	local _aEstrut   := {}
	//local _sAliasQ   := ""
	local _aCols     := {}
	local _sNomeCol  := ""
	local _oResult   := NIL
	local _nRet      := 0
	local _nTamCol   := 0
	local _nLinha    := 0

	_lSempre := iif (_lSempre == NIL, .T., _lSempre)  // Indica se sempre deve apresentar a tela de browse, mesmo que vazia.

	// Gera array com o resultado da query e cabecalhos de colunas na primeira linha.
	_oResult := ClsAUtil ():New (aclone (::Qry2Array (.T., .T.)))
	
	// Gera array com definicao das colunas. Para saber o tamanho de cada coluna, a solucao mais lenta,
	// porem com melhor apresentacao, foi varrer cada coluna procurando o maior conteudo.
	if len (_oResult:_aArray) > 0
		for _nCampo = 1 to len (_oResult:_aArray [1])
			_sNomeCol = alltrim (_oResult:_aArray [1, _nCampo])
			_nTamCol = len (_sNomeCol)
			for _nLinha = 1 to len (_oResult:_aArray)
				_nTamCol = max (_nTamCol, len (cvaltochar (_oResult:_aArray [_nLinha, _nCampo])))
			next
			//aadd (_aCols, {_nCampo, _sNomeCol, len (_sNomeCol) * 8, ''})
			aadd (_aCols, {_nCampo, _sNomeCol, _nTamCol * 4, ''})
		next
	endif

	// Remove primeira linha da array.
	_oResult:Del (1, 1)

	// Mostra a array em tela.
	if _lSempre .or. len (_oResult:_aArray) > 0
		_nRet = U_F3Array (_oResult:_aArray, '', _aCols, NIL, NIL, _sMsgTit, '', .T., 'C')
	else
		_nRet = 0
	endif
	U_ML_SRArea (_aAreaAnt)
return _nRet



// --------------------------------------------------------------------------
// Retorna o resultado da query formatado para uso no comando IN do SQL.
METHOD FormatIn () Class ClsSQL
	
	// Passa resultado da query para string.
	::_xRetQry = ::Qry2Str (1, '/')
	
return FormatIn (::_xRetQry, '/')



// --------------------------------------------------------------------------
// Muda os tipos das colunas. Deve ser executado logo apos a execucao da query
// e antes que o resultado da mesma seja usado para alguma coisa.
METHOD MudaTipo () Class ClsSQL
	local _aCampos   := {}
	local _nCampo    := 0
	local _aAreaQry  := GetArea ()
	local _aAreaSX3  := {}

	// Varre SX3 procurando campos de mesmo nome dos existentes na query.
	dbselectarea ("SX3")
	_aAreaSX3 = GetArea ()
	sx3 -> (dbsetorder (2))
	for _nCampo = 1 to (::_sAliasQry) -> (fcount ())
		if sx3 -> (dbseek (padr (alltrim ((::_sAliasQry) -> (FieldName (_nCampo))), 10, " "), .F.))
			if sx3 -> x3_tipo $ "ND"  // Numerico ou data
				TCSetField (::_sAliasQry, sx3 -> x3_campo, sx3 -> x3_tipo, sx3 -> x3_tamanho, sx3 -> x3_decimal)
			endif
		endif
	next
	RestArea (_aAreaSX3)

	// Verifica se a rotina chamadora especificou algum campo adicional para mudanca de tipo.
	for _nCampo = 1 to len (::_aSetField)
		if (::_sAliasQry) -> (FieldPos (::_aSetField [_nCampo, 1])) > 0
			//u_log (::_aSetField [_nCampo, 1])
			TCSetField (::_sAliasQry, ::_aSetField [_nCampo, 1], ::_aSetField [_nCampo, 2], ::_aSetField [_nCampo, 3], ::_aSetField [_nCampo, 4])
		endif
	next
	
	RestArea (_aAreaQry)
return



// --------------------------------------------------------------------------
// Gera comando INSERT VALUES
METHOD InsValues (_sTabela, _aDados) Class ClsSQL
	local _nCampo := 0

	::_sQuery = ""
	::_sQuery += "INSERT INTO " + _sTabela + " ("
	for _nCampo = 1 to len (_aDados)
		::_sQuery += _aDados [_nCampo, 1]
		::_sQuery += iif (_nCampo < len (_aDados), ',', '')
	next
	::_sQuery += ") VALUES ("
	for _nCampo = 1 to len (_aDados)
		::_sQuery += iif (valtype (_aDados [_nCampo, 2]) == 'C', "'", "") + cvaltochar (_aDados [_nCampo, 2]) + iif (valtype (_aDados [_nCampo, 2]) == 'C', "'", "") 
		::_sQuery += iif (_nCampo < len (_aDados), ',', '')
	next
	::_sQuery += ")"
//	u_log (::_sQuery)
	::Exec ()
return



// --------------------------------------------------------------------------
// Grava query atual em arquivo de log para depuracao.
METHOD Log (_lQuebra) Class ClsSQL
	if _lQuebra != NIL .and. _lQuebra
		u_logQry ('[' + procname (1) + '] ' + ::_sQuery)
	else
		u_log ('[' + procname (1) + '] ' + ::_sQuery)
	endif
return



// --------------------------------------------------------------------------
// Passa resultado da query para array.
METHOD Qry2Array (_lSetField, _lRetNomes) Class ClsSQL
	local _aLinha    := {}
	local _aArray    := {}
	local _aCampos   := {}
	local _nCampo    := 0
	local _aAreaQry  := GetArea ()
	local _aEstrut   := {}

	_lSetField = iif (_lSetField == NIL, .T., _lSetField)
	_lRetNomes = iif (_lRetNomes == NIL, .F., _lRetNomes)

	// Executa a query para saber quais os campos retornados.
	_ExecQry (::self)

	// Altera tipo de campos data cfe. dicionario de dados.
	if _lSetField
		::MudaTipo ()
	endif

	_aArray = {}

	// Insere na array uma linha com os nomes dos campos, caso solicitado.
	if _lRetNomes
		aadd (_aArray, array (len ((::_sAliasQry) -> (dbstruct ()))))
		for _nCampo = 1 to (::_sAliasQry) -> (fcount ())
			_aArray [1, _nCampo] = (::_sAliasQry) -> (fieldName (_nCampo))
		next
	endif

	// Passa dados para a array
	(::_sAliasQry) -> (dbgotop ())
	do while ! (::_sAliasQry) -> (eof ())
		_aLinha = {}
		for _nCampo = 1 to (::_sAliasQry) -> (fcount ())
			aadd (_aLinha, (::_sAliasQry) -> (fieldget (_nCampo)))
		next
		aadd (_aArray, aclone (_aLinha))
		(::_sAliasQry) -> (dbskip ())
	enddo
	(::_sAliasQry) -> (dbclosearea ())

	::_xRetQry = aclone (_aArray)

	RestArea (_aAreaQry)
return _aArray



// --------------------------------------------------------------------------
// Passa resultado da query para tabela em formato HTML.
// Util para envio simplificado de e-mails, por exemplo.
// Args: _sTitTab:   Texto a ser usado como titulo (primeira linha) da tabela
//       _aCols:     Definicao de colunas para geracao do HTML
//       _sArgsTbl:  Argumentos para a montagem de tabela em HTML. Ex.:  'width="90%" border="1" cellspacing="0" cellpadding="3" align="center"'
//       _lDestUlt:  Destacar em negrito (.T.) ou nao (.F.) e ultima linha da tabela.
//       _lRetNomes: Indica se deve incluir nomes de colunas no resultado da query.
METHOD Qry2HTM (_sTitTab, _aCols, _sArgsTbl, _lDestUlt, _lRetNomes) Class ClsSQL
	local _oAUtil  := NIL
	local _nCol    := 0
	
	_lRetNomes := iif (_lRetNomes == NIL, .F., _lRetNomes)

	// Se a consulta ainda nao foi executada...
	if valtype (::_xRetQry) != "A"
		if _aCols == NIL  // Se nao recebi definicao de colunas para o HTML...
			::_xRetQry = ::Qry2Array (.F., _lRetNomes)
		else
			::_xRetQry = ::Qry2Array (.F., _lRetNomes)
		endif
	endif

	//u_log (::_xRetQry)

	// Cria objeto array com os dados da query.
	if len (::_xRetQry) > 0
		_oAUtil := ClsAUtil():New (::_xRetQry)

		// Se nao receber definicao de colunas, gera automaticamente.
		if _aCols == NIL .and. len (::_xRetQry) >= 1
			_aCols = {}
			for _nCol = 1 to len (::_xRetQry [1])
				aadd (_aCols, {::_xRetQry [1, _nCol], "left", ""})
			next

			// Remove a primeira linha da array, pois contem os nomes das colunas.
			_oAUtil:Del (1, 1)
		endif

		// Usa metodo de geracao de HTML com os dados da array.
		::_xRetQry = _oAUtil:ConvHTM (_sTitTab, _aCols, _sArgsTbl, _lDestUlt)
	endif
return ::_xRetQry



// --------------------------------------------------------------------------
// Passa resultado da query para string, concatenando dados da coluna.
// Parametros: - Coluna da query (se nao especificado, assume a primeira)
//             - Caracter separador (se nao especificado, assume '')
METHOD Qry2Str (_nColuna, _sSeparad) Class ClsSQL
	local _sRet    := ""
	local _aRetQry := {}
	local _i       := 0

	_nColuna  := iif (_nColuna  == NIL, 1,  _nColuna)
	_sSeparad := iif (_sSeparad == NIL, '', _sSeparad)

	_aRetQry = ::Qry2Array (.F., .F.)
	for _i = 1 to len (_aRetQry)
		_sRet += _aRetQry [_i, _nColuna] + iif (_i < len (_aRetQry), _sSeparad, '')
	next
	
	::_xRetQry = _sRet

return _sRet



// --------------------------------------------------------------------------
// Passa resultado da query para arquivo de trabalho.
METHOD Qry2Trb (_lSetField) Class ClsSQL

	_ExecQry (::self)

	// Altera tipo de campos cfe. dicionario de dados.
	if _lSetField != NIL .and. _lSetField
		::MudaTipo ()
	endif

return ::_sAliasQry



// --------------------------------------------------------------------------
// Exporta o resultado da query para planilha.
// Parametros: _lSetField: Seta tipos de campos conforme SX3.
//             _lFixaChar: Campos tipo caracter que contem somente numeros (muito comum em campos chave) ficarao com um apostrofo no inicio para que o Excel nao os interprete como numericos.
//             _lSemEspac: Executa 'alltrim()' nos campos.
METHOD Qry2XLS (_lSetField, _lFixaChar, _lSemEspac) Class ClsSQL
	local _aAreaAnt  := U_ML_SRArea ()
	local _sNomeArq  := CriaTrab ({}, .F.)
	local _sArq      := MsDocPath () + "\" + _sNomeArq
	local _sTmpPath  := AllTrim (GetTempPath ())
	local _oExcelApp := NIL
	local _nCampo    := 0
	local _nHdl      := 0
	local _sCrLf     := chr (13) + chr (10)
	local _xDado     := NIL
	local _aEstrut   := {}
	local _lTemLetra := .F.
	local _sCSV      := ""
	local _nPos      := 0

	_lSetField := iif (_lSetField == NIL, .T., _lSetField)
	_lFixaChar := iif (_lFixaChar == NIL, .F., _lFixaChar)
	_lSemEspac := iif (_lSemEspac == NIL, .F., _lSemEspac)

	// Executa a query.
	_ExecQry (::self)
	
	// Altera tipo de campos data cfe. dicionario de dados.
	if _lSetField
		::MudaTipo ()
	endif

	// Cria arquivo temporario onde serao gerados os dados.
	_sArq += ".CSV"
	_nHdl := MsfCreate (_sArq, 0)

	// Monta nomes de colunas no arquivo.
	_aEstrut = (::_sAliasQry) -> (dbstruct ())
	for _nCampo = 1 to len (_aEstrut)
		_sCSV += (::_sAliasQry) -> (fieldname (_nCampo)) + iif (_nCampo < len (_aEstrut), ";", "")  // Nomes das colunas, sem ';' no final.
	next
	_sCSV += _sCrLf
	fWrite (_nHdl, _sCSV)

	// Passa os dados para o arquivo criado
	(::_sAliasQry) -> (dbgotop ())
	do while ! (::_sAliasQry) -> (eof ())
		_sCSV = ""
		for _nCampo = 1 to len (_aEstrut)
			_xDado = cvaltochar ((::_sAliasQry) -> (fieldget (_nCampo)))

			// Valores numericos ficam com ponto decimal, mas o Excel quer virgula.
			if _aEstrut [_nCampo, 2] == "N"
				_xDado = strtran (_xDado, ".", ",")
			endif
			
			// Campos tipo caracter que contem somente numeros (muito comum em campos chave) ficarao
			// com um apostrofo no inicio para que o Excel nao os interprete como numericos.
			if _aEstrut [_nCampo, 2] == "C"
				if _lFixaChar .and. ! empty (_xDado)
					_lTemLetra = .F.
					for _nPos = 1 to len (_xDado)
						if isalpha (substr (_xdado, _npos, 1))
							_lTemLetra = .T.
							exit
						endif
					next
					if ! _lTemLetra
						_xDado = "'" + strtran (_xDado, ".", ",")
					endif
				endif
				if _lSemEspac
					_xDado = alltrim (_xDado)
				endif
			endif

			_sCSV += _xDado + iif (_nCampo < len (_aEstrut), ";", "")  // Dados do registro, sem ';' no final.
		next

		// Grava registro a registro para nao ficar com uma string grande demais.
		fWrite (_nHdl, _sCSV + _sCrLf)

		(::_sAliasQry) -> (dbskip ())
	enddo
	fClose (_nHdl)
	
	// Copia o arquivo para a pasta temporaria da estacao e deleta-o da pasta de documentos.
	CpyS2T (_sArq, _sTmpPath, .T.)
	delete file (_sArq)
	
	// Define o programa a ser chamado.
	If ApOleClient ('MsExcel')
		_oExcelApp := MsExcel():New()
		_oExcelApp:WorkBooks:Open (_sTmpPath + _sNomeArq + ".CSV") // Abre uma planilha
		_oExcelApp:SetVisible(.T.)
	else
		//u_log ('[' + procname () + '] Abrindo arquivo ' + _sTmpPath + _sNomeArq + ".CSV")
		winexec ("cmd /c start " + _sTmpPath + _sNomeArq + ".CSV")
	endif
	
	U_ML_SRArea (_aAreaAnt)
return



// --------------------------------------------------------------------------
// Retorna o resultado da query.
METHOD RetQry (_nColuna, _lSetField) Class ClsSQL
	local _aAreaAnt := GetArea ()
	
	_nColuna := iif (_nColuna == NIL, 1, _nColuna)
	_ExecQry (::self)

	if _lSetField == NIL .or. _lSetField
		U_TCSetFld (::_sAliasQry)
	endif
	::_xRetQry = (::_sAliasQry) -> (fieldget (_nColuna))
	(::_sAliasQry) -> (dbclosearea ())
	
	RestArea (_aAreaAnt)
return ::_xRetQry



// --------------------------------------------------------------------------
// Adiciona campos `a array de campos para mudar tipo.
METHOD SetField (_sColuna, _sTipo, _nTamanho, _nDecimal) Class ClsSQL
	aadd (::_aSetField, {_sColuna, _sTipo, _nTamanho, _nDecimal})
return


/* nao chaguei a usar por que a procedure estava noutro database e nao era executada.
// --------------------------------------------------------------------------
// Executa uma stored procedure no banco de dados.
METHOD SPExec (_sProc, _xPar01, _xPar02, _xPar03, _xPar04, _xPar05, _xPar06, _xPar07, _xPar08, _xPar09, _xPar10) Class ClsSQL
	local _aRetTOP := 0
	U_LOG ('[' + procname () + ']', _sProc, _xPar01, _xPar02, _xPar03, _xPar04, _xPar05, _xPar06, _xPar07, _xPar08, _xPar09, _xPar10)
	_aRetTOP = TCSPExec (_sProc, _xPar01, _xPar02, _xPar03, _xPar04, _xPar05, _xPar06, _xPar07, _xPar08, _xPar09, _xPar10)
	u_log ('Retorno da procedure:', _aRetTOP)
return _aRetTOP
*/


// --------------------------------------------------------------------------
// Executa a query no banco de dados.
static function _ExecQry (_oSelf)
	local _nCampo := 0
	// habilitar para ajudar a identificar queries lentas -->	local _nSegIni   := seconds ()

	_oSelf:_sAliasQry = GetNextAlias ()
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _oSelf:_sQuery), _oSelf:_sAliasQry, .f., .t.)

	// Gera array com as definicoes de colunas (default = nao gerar, para ganho de performance).
	if _oSelf:lGeraHead
		_oSelf:aHeader = {}
		_aEstrut = aclone ((_oSelf:_sAliasQry) -> (dbstruct ()))
		for _nCampo = 1 to len (_aEstrut)
			aadd (_oSelf:aHeader, {_aEstrut [_nCampo, 1], ;
			                   _aEstrut [_nCampo, 1], ;
			                   "", ;
			                   _aEstrut [_nCampo, 2], ;
			                   _aEstrut [_nCampo, 3], ;
			                   "", ;
			                   "", ;
			                   _aEstrut [_nCampo, 2]})
		next
	endif

	// Habilitar esta linha para ajudar a identificar queries lentas.
//	u_log ('[' + transform (seconds () - _nSegIni, '@E 999999999.9999') + '] ' + _oSelf:_sQuery)
return