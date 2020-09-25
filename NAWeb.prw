// Programa...: NAWeb
// Autor......: Júlio Pedroni
// Data.......: 17/05/2017
// Descricao..: Função para chamar a aplicação web.
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
User Function NAWEB()
	local _cMenu := FunDesc() 
	local _CProg := ''
	LOCAL _nPosi := at('(NAWEB', _cMenu) + 6
	
	If _nPosi > 0
		_CProg = SubStr(_cMenu, _nPosi, 4)
		processa({||_AbreNaWeb(AllTrim(GetMV('VA_NAWEB')) + _ConvCod(__cUserId) + ',' + AllTrim(_cProg))}, 'Aguarde...')
	Else
		U_Help('Programa WEB não encontrado!')
	EndIf
Return
//
// --------------------------------------------------------------------------
Static Function _AbreNaWeb(_sUrl)
	Local _I := 0
	
	ShellExecute( "Open", _sUrl, "", "", 1 )
	ProcRegua(10)
	For _I := 1 to 10
		IncProc()
		Sleep(500)
	EndFor
Return
//
// --------------------------------------------------------------------------
Static Function _ConvCod(_cUserId)
	local _nValor := 0
	local _cRetor := ''
	
    _nValor := Val(_cUserId) * Val(_cUserId) 
	_nValor += Year(Date())  - 1000
	_nValor += Month(Date()) * 1000
	_cRetor := CValtoChar(_nValor)
Return _cRetor
//