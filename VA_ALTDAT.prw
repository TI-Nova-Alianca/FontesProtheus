#Include "PROTHEUS.CH"
//----------------------------------------------------------------------------------
// Tela para alteração da data de liberação na tela de bloqueio e liberação de lote
//Bruno Silva - 23/07/14                                                                                                            
//----------------------------------------------------------------------------------
User Function VA_ALTDAT()

//Private cTitle := "Alterar Data de Liberação" 
Private cTitle := "Alterar Data Prevista de Liberação" 
Private dDatLib := SDD->DD_VADPLIB
Static cDoc :=  SDD->DD_DOC

  DEFINE MSDIALOG oDlg TITLE cTitle FROM 000, 000  TO 200, 300 PIXEL

    @ 071, 077 BUTTON oButOk PROMPT "Alterar" SIZE 037, 012 ACTION Alterar() OF oDlg PIXEL
    @ 071, 025 BUTTON oButSair PROMPT "Sair" SIZE 037, 012 ACTION oDlg:End() OF oDlg PIXEL
//    @ 039, 042 SAY oSay1 PROMPT "Data da Liberação" SIZE 050, 007 OF oDlg PIXEL
    @ 039, 042 SAY oSay1 PROMPT "Data prev.Liberação" SIZE 050, 007 OF oDlg PIXEL
    @ 050, 042 MSGET oGet1 VAR dDatLib SIZE 060, 010 OF oDlg PIXEL
    @ 008, 042 SAY oSay2 PROMPT "Documento" SIZE 030, 007 OF oDlg PIXEL
    @ 019, 042 MSGET oGet2 VAR cDoc SIZE 060, 010 OF oDlg READONLY PIXEL
  ACTIVATE MSDIALOG oDlg CENTERED
Return

Static Function Alterar() 
If ! MsgYesNo("Confirma alteração da data de liberação?",cTitle)
	Return
EndIf  

dbSelectArea("SDD")
dbSetOrder(1)
dbSeek(xFilial("SDD") + SDD->DD_DOC)

If Found()
	RecLock("SDD",.F.)
	SDD->DD_VADPLIB := dDatLib
	msUnlock()
	MsgInfo("Data alterada com sucesso!",cTitle)
	oDlg:End()
EndIf

Return