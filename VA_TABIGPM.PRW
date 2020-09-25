//  Programa...: VA_TABIGPM
//  Autor......: Catia Cardoso
//  Data.......: 26/10/2016
//  Descricao..: Importa tabela de IGPM
//
//  Historico de alteracoes:

#include "totvs.ch"
#include "protheus.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"
#INCLUDE "tbiconn.ch"

User Function VA_TABIGPM()
	AxCadastro("ZAI","Tabela IPGM",".T.","U_VALZAI()")
Return

// --------------------------------------------------------------------------
// Valida 'Tudo OK'
user function VALZAI()
	local _lRet := .T.
	local _aAreaAnt := U_ML_SRArea ()

	
	if substr( dtos(M->ZAI_DATA) ,7 ,2) != '01' 
		msgalert ("Deve ser usada a data do primeiro dia util do mês.")
		_lRet = .F.
	endif
		
	if _lRet
		ZAI -> (dbsetorder (1))
		if ZAI -> (dbseek (xfilial ("ZAI") + dtos(M->ZAI_DATA), .F.))
			msgalert ("Valor IGPM já cadastrado para esta data! ")
			_lRet = .F.
		endif
	endif
		
	U_ML_SRArea (_aAreaAnt)
return _lRet



/*
User Function VA_TABIGPM()


chkfile("ZAI")
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

	For _i = 2 To Len(aDados)

		_wano = alltrim(aDados[ _i, 1] )
		for _wmes = 1 to 12
			_wdata  = _wano + strzero(_wmes,2) + '01'
			_wvalor = val(strtran (aDados[ _i, _wmes+1], ",", "."))
			
			reclock("ZAI", .T.)
				ZAI->ZAI_DATA := stod(_wdata)
				ZAI->ZAI_IGPM := _wvalor
			MsUnLock()
			_wcont := _wcont+1
        next
	next                

endif

MsgAlert("Importados : "  + cvaltochar(_wcont)+" registros.")
return
*/