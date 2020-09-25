// Programa:  ShowMemo
// Autor:     Robert Koch - TCX021
// Data:      23/07/2008
// Cliente:   Generico
// Descricao: Dialogo em tela para visualizacao de strings grandes / memos / arquivos texto.
//
// Historico de alteracoes:
// 30/07/2013 - Robert - Criada opcao de visualizar como arquivo XML.
// 11/11/2015 - Robert - Passa a retornar o texto editado (antes nao retornava nada).
// 13/11/2015 - Robert - Tratamento para quando nao tiver interface com o usuario.
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
User Function ShowMemo (_sTexto, _sTitulo)
	local _oDlg     := NIL
	local _oGetMemo := NIL

	_sTexto  := iif (valtype (_sTexto) != "C", cvaltochar (_sTexto), _sTexto)
	_sTitulo := iif (_sTitulo == NIL, "", _sTitulo)

	if type ("oMainWnd") == "O"  // Se tem interface com o usuario
		define msdialog _oDlg from 0, 0 to oMainWnd:nClientHeight - 250, oMainWnd:nClientwidth - 250 of oMainWnd pixel title _sTitulo
		@ 5, 5 get _sTexto MEMO size (_oDlg:nClientWidth / 2 - 10), (_oDlg:nClientHeight / 2 - 35) when .T. object _oGetMemo // Se colocar when .F., nao tem barra de rolagem
		@ (_oDlg:nClientHeight / 2 - 25), 5 button "Ver como XML" action (_AbreXML (_sTexto))
		@ (_oDlg:nClientHeight / 2 - 25), (_oDlg:nClientWidth / 2 - 40) bmpbutton type 1 action close (_oDlg)
		_oGetMemo:oFont := TFont():New ("Courier New", 7, 16)
		activate msdialog _oDlg center
	else
		u_help (_sTexto)
	endif
return _sTexto



// --------------------------------------------------------------------------
// Grava XML gerado em um arquivo temporario e abre-o com o programa associado.
static function _AbreXML (_sXML)
	local _sNomeArq := CriaTrab ({}, .F.)
	local _sArq     := MsDocPath () + "\" + _sNomeArq + ".XML"
	local _sTmpPath := AllTrim (GetTempPath ())
	local _nHdl     := 0

	// Cria arquivo temporario onde serao gerados os dados.
	_nHdl := MsfCreate (_sArq, 0)
	fWrite (_nHdl, _sXML)
	fClose (_nHdl)
		
	// Copia o arquivo para a pasta temporaria da estacao e deleta-o da pasta de documentos
	CpyS2T (_sArq , _sTmpPath, .T. )
	delete file (_sArq)
	winexec ("cmd /c start " + _sTmpPath + _sNomeArq + ".xml")
return
