//  Programa...: VA_CTASSOC
//  Data.......: 28/10/2015
//  Descricao..: Importa Banco/Agencia e Conta de Associados para o SA2
//
//  Historico de alteracoes:

#include "totvs.ch"
#include "protheus.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"
#INCLUDE "tbiconn.ch"

User Function VA_CTASSOC()

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

Static Function importar(_caminho)

Local cArq    := _caminho
Local cLinha  := ""
Local aDados  := {}
//Local aJaTem  := {}
//Local aCab    := {}   
//Local aItens  := {}
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
	
	//u_showarray (aDados)
	
	For _i := 3 To Len(aDados)

		_wcpf     = alltrim(aDados[_i,1])
		_wbanco   = alltrim(aDados[_i,2])
		_wagencia = strzero(val(alltrim(aDados[_i,3])),5)
		_wdigagen = alltrim(aDados[_i,4])
		_wconta   = alltrim(aDados[_i,5])
		_wdigcon  = alltrim(aDados[_i,6])
		_wcodigo  = fBuscaCpo ('SA2', 3, xfilial('SA2') + _wcpf , "A2_COD")
		
		if _wcodigo != ''
			_sSQL := ""
			_sSQL += " UPDATE SA2010"
			_sSQL += "    SET A2_BANCO   = '" + _wbanco + "'"
			_sSQL += "    	, A2_AGENCIA = '" + _wagencia + "'"
			_sSQL += "    	, A2_DVAGE   = '" + _wdigagen + "'"
			_sSQL += "    	, A2_NUMCON  = '" + _wconta + "'"
			_sSQL += "    	, A2_DVCTA   = '" + _wdigcon + "'"
			_sSQL += "  WHERE A2_COD     = '" + _wcodigo + "'"
						
			if TCSQLExec (_sSQL) < 0
	           	u_showmemo(_sSQL)
	           	return
	        endif
        endif
        	
   		_wcont++
  	next        

endif

MsgAlert("Atualizados : "  + cvaltochar(_wcont)+" associados.")
return
