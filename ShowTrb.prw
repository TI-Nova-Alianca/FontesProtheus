// Programa...: Showtrb
// Autor......: Robert Koch
// Data.......: 21/06/2003
// Cliente....: Generico
// Descricao..: Visualizacao de arquivo em browse.
// Parametros.: _sAlias  -> alias do arquivo a exibir
//              _sMsg    -> Mensagem a ser mostrada no titulo da janela.
//              _aCampos -> vetor com o nome dos campos a exibir. Se nao
//                          informado, mostra todos os campos
//
// Historico de alteracoes:
// 13/07/2005 - Robert - Perdia filtro anterior do arquivo.
// 09/08/2005 - Robert - Implementada rotina de edicao do arquivo.
// 17/08/2005 - Robert - Eliminacao da include rwmake.ch
// 13/07/2010 - Robert - Criado botao de exportacao para Excel
// 22/11/2010 - Robert - Verifica se tem interface com o usuario antes de executar a rotina.
// 16/09/2011 - Robert - Nao editava os campos corretos quando recebia array de campos a mostrar.
//

#include "protheus.ch"   // Habilitar para versao 8.11 e superiores

// --------------------------------------------------------------------------
user function ShowTRB (_sAlias, _sMsg, _aCampos)
	local _aCpos      := {}
	local _aEstrut    := {}
	local _nCampo     := 0
	local _oShowTrb   := NIL
	local _nIndOrig   := (_sAlias) -> (indexord ())
	local _sFiltrAnt  := (_sAlias) -> (dbfilter ())
	local _sChave     := space (100)
	local _sFiltro    := space (100)
	local _aArea      := getarea ()
	local _nIndice    := 0
	local _aIndices   := {}
	
	//u_logIni ()
	if type ("oMainWnd") != "O"  // Se nao tem interface com o usuario
		u_help ("Funcao " + procname () + " nao pode ser executada sem interface com o usuario.")
		return
	endif
	
	_sMsg := iif (_sMsg == NIL, "", _sMsg)
	
	if select (_sAlias) == 0
		msgalert (procname () + ": alias '" + _sAlias + "' nao existe.")
		return
	endif
	
	if _sAlias == NIL
		msgAlert ("Funcao _ShowTrb: informe o alias do arquivo a visualizar.")
		return
	endif
	
	// Monta lista de campos a visualizar
	if _aCampos == NIL
		_aEstrut = (_sAlias) -> (dbstruct ())
		for _nCampo = 1 to len (_aEstrut)
			aadd (_aCpos, {_aEstrut [_nCampo, 1], _aEstrut [_nCampo, 1]})
		next
	else
		for _nCampo = 1 to len (_aCampos)
			//         aadd (_aCpos, {_aCampos [_nCampo], _aCampos [_nCampo]})
			aadd (_aCpos, {_aCampos [_nCampo, 1], _aCampos [_nCampo, 1]})
		next
	endif
	
	// Monta lista de indices (quero fazer um combo box depois...)
	_nIndice = 1
	_aIndices = {}
	do while ! empty (indexkey (_nIndice))
		aadd (_aIndices, cValToChar (_nIndice) + " - " + indexkey (_nIndice))
		_nIndice ++
	enddo
	_nIndice = _nIndOrig
	
	define MSDialog _oShowTrb from 0,0 to oMainWnd:nClientHeight - 30 , oMainWnd:nClientwidth - 10 of oMainWnd pixel title "Arquivo " + _sAlias + " " + _sMsg
	(_sAlias) -> (dbgotop ())
	_oBrwTrb := IW_Browse (0, 0, (_oShowTrb:nClientHeight / 2 - 60), (_oShowTrb:nClientWidth / 2), _sAlias, "", "", _aCpos)
	TSay ():New (_oShowTrb:nClientHeight / 2 - 55, 5,   {||"Indice:"},    _oShowTrb, "",  ,     .F.,   .F.,    .F.,  .T.)  // Para mais opcoes veja include protheus.ch
	TSay ():New (_oShowTrb:nClientHeight / 2 - 55, 60,  {||indexkey ()},  _oShowTrb, "",  ,     .F.,   .F.,    .F.,  .T.)  // Para mais opcoes veja include protheus.ch
	TSay ():New (_oShowTrb:nClientHeight / 2 - 42, 5,   {||"Filtro:"},    _oShowTrb, "",  ,     .F.,   .F.,    .F.,  .T.)  // Para mais opcoes veja include protheus.ch
	TSay ():New (_oShowTrb:nClientHeight / 2 - 55, 200, {||"Pesquisar:"}, _oShowTrb, "",  ,     .F.,   .F.,    .F.,  .T.)  // Para mais opcoes veja include protheus.ch
	@ _oShowTrb:nClientHeight / 2 - 57, 35  get _oGetInd    var _nIndice size 20,  8 of _oShowTrb pixel valid _Indice (_nIndice)
	@ _oShowTrb:nClientHeight / 2 - 45, 35  get _oGetFiltro var _sFiltro size 100, 8 of _oShowTrb pixel valid _Filtra (_sFiltro)
	@ _oShowTrb:nClientHeight / 2 - 57, 230 get _oGetChave  var _sChave  size 100, 8 of _oShowTrb pixel valid _Pesquisa (_sChave)
	TButton ():New(_oShowTrb:nClientHeight / 2 - 55, _oShowTrb:nClientWidth / 2 - 100, "Set deleted on",  _oShowTrb, {|| _SetDel ("ON")},  40, 10,,,, .T.)
	TButton ():New(_oShowTrb:nClientHeight / 2 - 40, _oShowTrb:nClientWidth / 2 - 100, "Set deleted off", _oShowTrb, {|| _SetDel ("OFF")}, 40, 10,,,, .T.)
	TButton ():New(_oShowTrb:nClientHeight / 2 - 55, _oShowTrb:nClientWidth / 2 - 50,  "Planilha", _oShowTrb, {|| U_Trb2XLS (_sAlias)}, 40, 10,,,, .T.)
	SButton():New (_oShowTrb:nClientHeight / 2 - 40, _oShowTrb:nClientWidth / 2 - 50,  1, {|| _oShowTrb:End ()},, .T.)
	_oBrwTrb:oBrowse:bLDblClick := {|| _edita (_aCpos)}
	activate msdialog _oShowTrb centered
	
	set order to (_nIndOrig)
	set filter to &(_sFiltrAnt)
	set deleted on
	restarea (_aArea)
	//u_logFim ()
return



// --------------------------------------------------------------------------
static function _SetDel (_sQueFazer)
	if _sQueFazer == "ON"
		set deleted on
	else
		set deleted off
	endif
	_oBrwTrb:oBrowse:Refresh ()
return



// --------------------------------------------------------------------------
static function _Indice (_nIndice)
	if empty (indexkey (_nIndice))
		msgalert ("Indice nao existe")
		return
	endif
	set order to (_nIndice)
	_oGetInd:Refresh ()
	_oBrwTrb:oBrowse:Refresh ()
return .T.



// --------------------------------------------------------------------------
static function _Filtra (_sFiltro)
	set filter to &(_sFiltro)
	_oBrwTrb:oBrowse:Refresh ()
return .T.



// --------------------------------------------------------------------------
static function _Pesquisa (_sChave)
	dbseek (_sChave, .T.)
	_oBrwTrb:oBrowse:Refresh ()
return .T.



// --------------------------------------------------------------------------
// Abre celula para edicao. Como esta classe nao possui os metodos lEditCol e
// nem lEditCell (ateh a versao 8.11), fiz um get na posicao correspondente.
// Funcao montada c/exemplo do prog. PSAL.PRW de Cristina Ogura (Microsiga SP)
static function _Edita (_aCpos)
	//   local _sCampo  := FieldName (_oBrwTrb:oBrowse:nColPos)
	local _sCampo  := _aCpos [_oBrwTrb:oBrowse:nColPos, 1]
	local _xVar    := &(_sCampo)
	local _oDlg    := NIL
	local _oBtn    := NIL
	local _sPict   := ""
	local _aEstrut := dbstruct ()
	local _nCampo  := ascan (_aEstrut, {|_aVal| _aVal [1] == _sCampo})
	local _xValAnt := (alias ()) -> &(_sCampo)
	
	// Monta picture conforme o campo sendo lido
	do case
		case valtype (&(_sCampo)) == "N"
			if _aEstrut [_nCampo, 4] > 0
				_sPict = padl ("." + replicate ("9", _aEstrut [_nCampo, 4]), _aEstrut [_nCampo, 3], "9")
			else
				_sPict = replicate ("9", _aEstrut [_nCampo, 3])
			endif
		case valtype (&(_sCampo)) == "C"
			_sPict = ""
		case valtype (&(_sCampo)) == "D"
			_sPict = "@D"
	endcase
	
	// Obtem as coordenadas da celula (lugar onde a janela de edicao deve ficar)
	oRect := tRect():New(0,0,0,0)
	_oBrwTrb:oBrowse:GetCellRect(_oBrwTrb:oBrowse:nColPos,,oRect)
	aDim  := {oRect:nTop,oRect:nLeft,oRect:nBottom,oRect:nRight}
	
	// Monta dialogo de tamanho 0, para ter onde colocar o get.
	DEFINE MSDIALOG _oDlg OF _oBrwTrb:oBrowse:oWnd FROM 0, 0 TO 0, 0 STYLE nOR( WS_VISIBLE, WS_POPUP ) PIXEL
	
	// Gera get sobre a celula, dando a impressao que a mesma estah sendo editada.
	@ 0,0 GET oGet1 VAR _xVar SIZE 0,0 OF _oDlg picture _sPict PIXEL
	oGet1:Move(-2,-2, (aDim[ 4 ] - aDim[ 2 ]) + 4, aDim[ 3 ] - aDim[ 1 ] + 4 )
	
	// Botao de tamanho 0 para pegar o 'enter'.
	@ 0, 0 BUTTON _oBtn PROMPT "ze" SIZE 0,0 OF _oDlg
	_oBtn:bGotFocus := {|| _oDlg:nLastKey := VK_RETURN, _oDlg:End(0)}
	ACTIVATE MSDIALOG _oDlg ON INIT _oDlg:Move(aDim[1],aDim[2],aDim[4]-aDim[2], aDim[3]-aDim[1])
	
	// Grava o novo valor no arquivo.
	reclock (alias (), .F.)
	&(_sCampo) := _xVar
	msunlock ()
	u_log ("RECNO", transform ((alias ()) -> (recno ()), "9999999999"), "campo", _sCampo, "Valor anterior:", _xValAnt, "novo valor:", _xVar)
	
	// Atualiza o browse em tela.
	_oBrwTrb:oBrowse:Refresh ()
return
