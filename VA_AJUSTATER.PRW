//  Programa...: VA_AJUSTATER
//  Autor......: Catia Cardoso
//  Data.......: 07/12/2016
//  Descricao..: Ajusta terceiros conforme planilia da Liane
//
//  Historico de alteracoes:

#include "totvs.ch"
#include "protheus.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"
#INCLUDE "tbiconn.ch"

User Function VA_AJUSTATER()

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

	For _i := 2 To Len(aDados)
	
		_wfilial   = strzero(val(alltrim(aDados[ _i, 1] )) , 2)
		_wemissao  = alltrim(aDados[ _i, 2] )
		_wproduto  = alltrim(aDados[ _i, 3] )
		_wproduto  = substr(_wproduto + '               ', 1 , 15)
		
		
		
		if substr(_wemissao,7,4) + substr(_wemissao,4,2) < '201211'
			_wdoc      = strzero(val(alltrim(aDados[ _i, 4] )) , 6)+ '   '
		else
			_wdoc      = strzero(val(alltrim(aDados[ _i, 4] )) , 9)
		endif			
		
		_wcliente  = strzero(val(alltrim(aDados[ _i, 5] )) , 6)
		_wloja     = strzero(val(alltrim(aDados[ _i, 6] )) , 2)
		_wserie    = alltrim(aDados[ _i, 7] )
		if len (_wserie) != 3
			_wserie = substr(_wserie + '   ', 1 , 3)
		endif
		_wtesATUAL = alltrim(aDados[ _i, 8] )
		_wtesNOVO  = alltrim(aDados[ _i, 9] )
		
		if _wtesNOVO != ''
			_wchave   = _wfilial + _wdoc + _wserie + _wcliente + _wloja  //+ _wproduto
		
			//u_showmemo (_wchave)
				
			DbSelectArea("SD2")
   			DbSetOrder(3) // D2_FILIAL, D2_DOC, D2_SERIE, D2_CLIENTE, D2_LOJA, D2_COD
   			DbSeek(_wchave, .F.)
			Do While !eof() .and. _wfilial = SD2->D2_FILIAL .and. _wdoc == SD2->D2_DOC .and. _wserie == D2_SERIE .and. _wcliente == D2_CLIENTE .and. _wloja == D2_LOJA 
	
				_wchave   = _wfilial + _wdoc + _wserie + _wcliente + _wloja + _wproduto
				
   			    if _wproduto == SD2->D2_COD
   			    	
   			    	reclock("SD2", .F.)
						SD2->D2_TES := _wtesNOVO
					MsUnLock()
				
					_wcont := _wcont+1
				endif	
				SD2 -> (dbskip ())				
			
			enddo
			
		endif			
  next        

endif

MsgAlert("Atualizados : "  + cvaltochar(_wcont)+" itens de terceiros.")
return
