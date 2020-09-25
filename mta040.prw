// Programa: MTA040
// Autor:    Alexandre Dalpiaz
// Data:     02/09/06
// Funcao:   PE após inclusao do vendedor
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
User Function MTA040()
	If Inclui
		_aAlias := GetArea()
		DbSelectArea('CTD')
		RecLock('CTD',!DbSeek(xFilial('CTD') + M->A3_COD,.F.))
		CTD->CTD_FILIAL := xFilial('CTD')
		CTD->CTD_ITEM   := M->A3_COD
		CTD->CTD_DESC01 := M->A3_NOME
		CTD->CTD_CLASSE := '2'
		CTD->CTD_BLOQ   := '2'
		CTD->CTD_DTEXIS := iif(empty(CTD->CTD_DTEXIS), dDataBase, CTD->CTD_DTEXIS)
		CTD->CTD_CLOBRG := '2'
		CTD->CTD_ACCLVL := '1'
		MsUnLock()
		RestArea(_aAlias)
	EndIf
Return(M->A3_NOME)
