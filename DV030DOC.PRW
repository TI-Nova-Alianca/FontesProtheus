#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "APVT100.CH"

// Programa:  DV030DOC
// Autor:     Leandro DWT
// Data:      28/02/2014
// Descricao: Exibe a numeração do Pedido ou Carga na separação apanhe com coletor de dados
//
// Historico de alteracoes:
//
User Function DV030DOC()
	Local cFunExe := PARAMIXB[1]
	
	// Conteudo: DLAPANHE ou DLGXABAST
	If 'DLAPANHE' $ cFunExe
		DLVTCabec(,.F.,.F.,.T.)
		If	Empty(SDB->DB_CARGA)
			@ 02, 00 VTSay PadR("Docto:", VTMaxCol())
			@ 04, 00 VTSay PadR(SDB->DB_DOC+"-"+SDB->DB_SERIE, VTMaxCol())
		Else
			@ 02, 00 VTSay PadR("Carga:", VTMaxCol())
			@ 04, 00 VTSay PadR(SDB->DB_CARGA, VTMaxCol())
		EndIf
		DLVTRodaPe()
	EndIf
Return