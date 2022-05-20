// Programa...: TRB2XLS
// Autor......: Robert Koch
// Data.......: 18/09/2009
// Descricao..: Exporta arquivo (DBF/DTC/TOP/...) para CSV e abre no MS Excel.
//
// Historico de alteracoes:
// 13/07/2010 - Robert - Parametro _lFixaChar passa a ter valor default .F. (antes nao tinha tratamento)
// 15/09/2010 - Robert - Nao gera mais aviso em tela quando o MS-Excel nao estiver instalado.
// 02/05/2011 - Robert - Possibilidade de remover espacoes de colunas tipo caracter.
// 27/07/2015 - Robert - Parametro _lSemEspac passa a ser .T. por default.
//                     - Remove ';' dos dados quando exportacao para formato CSV.
// 05/05/2021 - Robert - Criado parametro para informar se tenta ou nao abrir o arquivo apos exportacao (GLPI 9973).
//                     - Criado parametro para informar o nome do arquivo destino (GLPI 9973).
// 19/05/2022 - Robert - Melhorada abertura automatica do arquivo gerado.
//

// --------------------------------------------------------------------------
// Param: - _sAlias...: alias do arquivo a exportar
//        - _lFixaChar: .T. = Gera campos caracter com tamanho fixo; .F. = gera como numeros
//        - _lSemEspac: .T. = Elimina espacos (alltrim) nos campos tipo caracter
//        - _lAbrir...: .T. = abre o arquivo apos exportacao.
user function TRB2XLS (_sAlias, _lFixaChar, _lSemEspac, _lAbrir, _sArqDest)
	local _aAreaAnt  := U_ML_SRArea ()
	local _sNomeArq  := CriaTrab ({}, .F.)
	local _sArq      := MsDocPath () + "\" + _sNomeArq
	local _sTmpPath  := AllTrim (GetTempPath ())
	local oExcelApp  := NIL
	local _nCampo    := 0
	local _nHdl      := 0
	local _sCrLf     := chr (13) + chr (10)
	local _xDado     := NIL
	local _aEstrut   := (_sAlias) -> (dbstruct ())
	local _lTemLetra := .F.
	local _sProg     := ""
	local _sTipoArq  := "CSV"
	local _sCSV      := ""
	local _sHTM      := ""
	local _nPos		 := 0
	
	_lFixaChar := iif (_lFixaChar == NIL, .F., _lFixaChar)
	_lSemEspac := iif (_lSemEspac == NIL, .T., _lSemEspac)
	_lAbrir    := iif (_lAbrir    == NIL, .T., _lAbrir)
		
	// Define o programa a ser chamado e o tipo do arquivo.
	If empty (_sProg) .and. ApOleClient ('MsExcel')
		_sProg = "MsExcel"
	endif

	// Monta inicio de HTML, mesmo que nao use depois.
	_sHTM := ''
	_sHTM += _sCrLf +  '<html>'
	_sHTM += _sCrLf +  '<head>'
	_sHTM += _sCrLf +  '<title>Exportacao de dados para planilha</title>'
	_sHTM += _sCrLf +  '<Stylesheet HRef="./Folha_estilo.css"/>'
	_sHTM += _sCrLf +  '</head>'
	_sHTM += _sCrLf +  '<body>'
	_sHTM += _sCrLf +  '<table>' // width="98%" border="1" cellspacing="0" cellpadding="3" align="center">'
	_sHTM += _sCrLf +  '<tr>'

	// Cria arquivo onde serao gerados os dados.
	if _sArqDest == NIL
		_sArq += "." + _sTipoArq
	else
		_sArq = _sArqDest + "." + _sTipoArq
		_sNomeArq = _sArqDest
	endif
	U_Log2 ('debug', 'exportando para ' + _sArq)
	_nHdl := MsfCreate (_sArq, 0)

	// Monta nomes de colunas no arquivo, tanto em CSV como em HTML. Depois grava um dos dois.
	for _nCampo = 1 to len (_aEstrut)
		_sCSV += (_sAlias) -> (fieldname (_nCampo)) + iif (_nCampo < len (_aEstrut), ";", "")  // Nomes das colunas, sem ';' no final.
		_sHTM += _sCrLf + '<td class=xl66 width="' + cvaltochar (max (100, _aEstrut [_nCampo, 3] * 10)) + '">' + alltrim ((_sAlias) -> (fieldname (_nCampo))) + '</td>'
	next
	_sCSV += _sCrLf
	_sHTM += _sCrLf + '</tr>'
	if _sTipoArq == "CSV"
		fWrite (_nHdl, _sCSV)
	elseif _sTipoArq == "HTM"
		fWrite (_nHdl, _sHTM)
	endif

	// Passa os dados para o arquivo criado
	(_sAlias) -> (dbgotop ())
	do while ! (_sAlias) -> (eof ())
		_sCSV = ""
		_sHTM = "<tr>"
		for _nCampo = 1 to len (_aEstrut)
			_xDado = cvaltochar ((_sAlias) -> (fieldget (_nCampo)))

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

			if _sTipoArq == "CSV"
				
				// Remove ponto-e-virgula (se existir) por que eh o caracter de separacao de colunas do formato CSV.
				_xDado = strtran (_xDado, ';', ' ')
				
				_sCSV += _xDado + iif (_nCampo < len (_aEstrut), ";", "")  // Dados do registro, sem ';' no final.
			elseif _sTipoArq == "HTM"
				_sHTM += _sCrLf + '<td>' + _xDado + '</td>' + iif (_nCampo < len (_aEstrut), "", "</tr>")
			endif
		next

		// Grava registro a registro para nao ficar com uma string grande demais.
		if _sTipoArq == "CSV"
			fWrite (_nHdl, _sCSV + _sCrLf)
		elseif _sTipoArq == "HTM"
			fWrite (_nHdl, _sHTM)
		endif

		(_sAlias) -> (dbskip ())
	enddo
	fClose (_nHdl)
	
	// Copia o arquivo para a pasta temporaria da estacao e deleta-o da pasta de documentos
	CpyS2T (_sArq, _sTmpPath, .T.)
	delete file (_sArq)
	
	if _lAbrir
		If _sProg == 'MsExcel'
			oExcelApp := MsExcel():New()
			oExcelApp:WorkBooks:Open (_sTmpPath + _sNomeArq + "." + _sTipoArq) // Abre uma planilha
			oExcelApp:SetVisible(.T.)
		else
			winexec ("cmd /c start " + _sTmpPath + _sNomeArq + "." + _sTipoArq)
		endif
	endif
	
	U_ML_SRArea (_aAreaAnt)
return
