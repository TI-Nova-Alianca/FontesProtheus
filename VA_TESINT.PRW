// Programa : VA_TESINT
// Autor    : Catia Cardoso
// Data     : 25/04/2019
// Descricao: Importa TES Inteligente - tabela  
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------

#include "totvs.ch"
#include "protheus.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"
#INCLUDE "tbiconn.ch"

User Function VA_TESINT()
	
	_caminho := ""
	
	// tela para selecionar o arquivo texto no disco local para ser lido/atualizado
	DEFINE DIALOG oDlg TITLE "Usar Arquivo (.CSV)" FROM 180,180 TO 370,640 PIXEL
	@ 005, 005 To 090, 228 //linha, coluna TO linha, coluna
	@ 020, 025 Say "Selecione o arquivo base:"
	@ 045, 025 Say "Caminho:"
	@ 045, 055 Get _caminho  SIZE 140,20
	oTButton1 := TButton():New(045,195,"...",oDlg,{||diretorio()},10,10,,,.F.,.T.,.F.,,.F.,,,.F.)
	oTButton2 := TButton():New(070,078,"Atualizar",oDlg,{||processa(importar(_caminho))},35,10,,,.F.,.T.,.F.,,.F.,,,.F.)
	oTButton3 := TButton():New(070,138,"Sair",oDlg,{||close(oDlg)},35,10,,,.F.,.T.,.F.,,.F.,,,.F.)
	ACTIVATE DIALOG oDlg CENTERED
return

// Static Function close()
// Return


Static Function diretorio()

_caminho := cGetFile('*.*','Arquivos (Todos)',1,,.T.,GETF_LOCALHARD + GETF_NETWORKDRIVE)

Return
*/

Static Function importar(_caminho)

Local cArq    := _caminho
Local cLinha  := ""
Local aDados  := {}
//Local aJaTem  := {}
//Local aCab    := {}   
//Local aItens  := {}
Local i		  := 0
Local _i	  := 0

Private lMsErroAuto := .F. // Determina se houve alguma inconsistencia na execucao da rotina 

Close(oDlg)

If !File(cArq)
	MsgStop("O arquivo '" + cArq + "' não foi encontrado. Atualização não realizada!","ATENCAO")
	Return
EndIf

FT_FUSE(cArq)
ProcRegua(FT_FLASTREC())
FT_FGOTOP()
While !FT_FEOF()
	cLinha := FT_FREADLN()
	AADD(aDados,Separa(cLinha,";",.T.))
	FT_FSKIP()
EndDo   

_wcont :=0

if Len (aDados) > 0
	For _i := 1 To Len(aDados)
		_wgrpprod = aDados[ _i, 1] 
		_westado  = aDados[ _i, 2]
		_wtpcli   = 'S'
		_wtesven  = aDados[ _i, 4]
		_wtesbon  = aDados[ _i, 5]
		
		for i = 1 to 2
		    // verifica se o conhecimento esta marcado como cancelado
		    _sSQL := ""
		    _sSQL += " SELECT 1"
		    _sSQL += "   FROM SFM010"
		    _sSQL += "  WHERE FM_TIPO    = '" + iif (i=1, '01','04') + "'"
		    _sSQL += "    AND FM_GRPROD  = '" + _wgrpprod + "'"
		    _sSQL += "    AND FM_EST     = '" + _westado + "'"
		    _sSQL += "    AND FM_TIPOCLI = '" + _wtpcli + "'" 
		    _sSQL += "    AND FM_TS      = '" + iif (i=1, _wtesven, _wtesbon) + "'"
    	
		    aExiste := U_Qry2Array(_sSQL)
		    if len(aExiste) = 0
				*/
				_wcont ++
				// grava as 2 operacoes VENDA e BONIFICACAO
				DbSelectArea("SFM")
				reclock ("SFM", .T.)
					SFM-> FM_FILIAL  = xfilial("SFM")
					SFM-> FM_TIPO    = iif (i=1, '01','04')
					SFM-> FM_GRPROD  = _wgrpprod
					SFM-> FM_EST     = _westado
					SFM-> FM_TIPOCLI = _wtpcli
					SFM-> FM_TS      = iif (i=1, _wtesven, _wtesbon)
				msunlock ()
			endif	
        next
	next
else
	u_help ("Nenhum registro importado")	          
endif

if _wcont > 0
	u_help ("Registros importados com sucesso")
endif
