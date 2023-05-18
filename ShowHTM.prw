// Programa:  ShowHTM
// Autor:     Robert Koch
// Data:      02/03/2012
// Descricao: Dialogo em tela para visualizacao de HTML.
//
// Historico de alteracoes:
// 30/11/2017 - Robert - Converte quebra de linha para '<br'
// 18/05/2023 - Robert - Parametro para selecionar se abre 'dentro' do sistema ou no navegador padrao.
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
User Function ShowHTM (_sHTM, _sOnde)
	local _oDlg := NIL
	local _oBrw := NIL
	local _sNomeArq := CriaTrab ({}, .F.) + '.HTML'
	local _sArq     := MsDocPath () + "\" + _sNomeArq
	local _nHdl := 0
	local _sTmpPath := AllTrim (GetTempPath ())

	_sHTM = iif (valtype (_sHTM) != "C", cvaltochar (_sHTM), _sHTM)
	_sHTM = strtran (_sHTM, chr (13) + chr (10), '<br>')

	// Cria arquivo temporario onde serao gerados os dados.
	_nHdl := MsfCreate (_sArq, 0)
	fWrite (_nHdl, _sHTM)
	fClose (_nHdl)

	// Copia o arquivo para a pasta temporaria da estacao e deleto-o do servidor.
	CpyS2T (_sArq , _sTmpPath, .T. )
	delete file (_sArq)

	if _sOnde == 'I'  // funcao interna do sistema
		define msdialog _oDlg from 0, 0 to oMainWnd:nClientHeight - 300, oMainWnd:nClientwidth - 150 of oMainWnd pixel title ""
		_oBrw := TIBrowser():New (5, ;  // Limite superior
								5, ;  // Limite esquerdo
								_oDlg:nClientWidth / 2 - 10, ;  // Largura
								_oDlg:nClientHeight / 2 - 30, ;  // Altura
								_sTmpPath + _sNomeArq, ;  // Pagina inicial
								_oDlg)  // Dialogo onde serah criado.
		@ (_oDlg:nClientHeight / 2 - 25), (_oDlg:nClientWidth / 2 - 40) bmpbutton type 1 action close (_oDlg)
		activate msdialog _oDlg center  // on init (close _oDlg)
	elseif _sOnde == 'N'  // navegador do sistema operacional
		u_log2 ('debug', '[' + procname () + '] Abrindo arquivo ' + _sTmpPath + _sNomeArq)
		winexec ("cmd /c start " + _sTmpPath + _sNomeArq)
	else
		u_help ("Sem tratamento para opcao '" + _sOnde + "'",, .t.)
	endif
return
