//  Programa...: VA_ITENSMPR
//  Autor......: Catia Cardoso
//  Data.......: 09/02/2015
//  Descricao..: Altera Cadastro de Produtos
//
//  Historico de alteracoes:
//  19/02/2015 - Catia - estava dando erro de bloqueio
//  13/06/2019 - Catia - alterado para gravar os campos Codbar, DUN, GTIN

#include "totvs.ch"
#include "protheus.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"
#INCLUDE "tbiconn.ch"

User Function VA_ITENSMPR()

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


Static Function close()
Return


Static Function diretorio()

_caminho := cGetFile('*.*','Arquivos (Todos)',1,,.T.,GETF_LOCALHARD + GETF_NETWORKDRIVE)

Return

Static Function importar(_caminho)

Local cArq    := _caminho
Local cLinha  := ""
Local aDados  := {}
Local aJaTem  := {}
Local aCab    := {}   
Local aItens  := {}
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

	For _i := 4 To Len(aDados)

		_wcodprod = alltrim(aDados[ _i, 1] )
		DbSelectArea("SB1")
   		DbSetOrder(1)
   		
   		IncProc("Codigo Item : " + _wcodprod)
		
   		if DbSeek (xFilial("SB1") + _wcodprod )
   		
   			reclock("SB1", .F.)
   				SB1->B1_POSIPI  := aDados[ _i, 4]
   				SB1->B1_SEGUM   := aDados[ _i, 6]
   				SB1->B1_CONV    := aDados[ _i, 7]
   				SB1->B1_TIPCONV := aDados[ _i, 8]
   				SB1->B1_CODBAR  := aDados[ _i, 9]
   				SB1->B1_CODGTIN := aDados[ _i, 12]
			MsUnLock()
		endif
		if DbSeek (xFilial("SB5") + _wcodprod )	
			reclock("SB5", .F.)
				SB5->B5_2CODBAR := aDados[ _i, 8]
   				SB5->B5_UMDIPI  := aDados[ _i, 14]
   				SB5->B5_CONVDIP := aDados[ _i, 15]
			MsUnLock()
		endif
		_wcont := _wcont+1
	next        
endif

MsgAlert("Atualizados : "  + cvaltochar(_wcont)+" itens.")
return