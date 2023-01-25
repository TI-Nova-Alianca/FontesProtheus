// Programa...: ImpDanfe
// Autor......: Robert Koch
// Data.......: 20/11/2011
// Descricao..: Chama (re)impressao de DANFe.
//
// Historico de alteracoes:
// 07/02/2012 - Robert - Quando chamado do menu, fica em loop para agilizar nova impressao.
// 07/04/2015 - Robert - Acrescentada funcao U_ML_SRArea () pois pode ser chamado a partir de outros programas.
// 24/01/2023 - Robert - Trocada funcao U_GravaSX1 por SetMVValue
//

#INCLUDE "PROTHEUS.CH"
#INCLUDE "APWIZARD.CH"
#INCLUDE "FILEIO.CH"
#INCLUDE "SPEDNFE.ch"
#INCLUDE "TBICONN.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"

// --------------------------------------------------------------------------
User Function ImpDanfe (_sEntSai, _sNFIni, _sNFFim, _sSerie)
	local _aAreaAnt  := U_ML_SRArea ()

	if _sEntSai != NIL .and. _sNFIni != NIL .and. _sNFFim != NIL .and. _sSerie != NIL
	//	U_GravaSX1 ("NFSIGW", "01", _sNFIni)
	//	U_GravaSX1 ("NFSIGW", "02", _sNFFim)
	//	U_GravaSX1 ("NFSIGW", "03", _sSerie)
	//	U_GravaSX1 ("NFSIGW", "04", iif (_sEntSai == 'E', 1, 2))  // 1=Entrada;2=Saida
	//	U_GravaSX1 ("NFSIGW", "05", 2)  // Imprime no verso: 1=Sim; 2=Nao

		SetMVValue ("NFSIGW", "MV_PAR01", _sNFIni)
		SetMVValue ("NFSIGW", "MV_PAR02", _sNFFim)
		SetMVValue ("NFSIGW", "MV_PAR03", padr (_sSerie, 3))
		SetMVValue ("NFSIGW", "MV_PAR04", iif (_sEntSai == 'E', 1, 2))  // 1=Entrada;2=Saida
		SetMVValue ("NFSIGW", "MV_PAR05", 2)  // Imprime no verso: 1=Sim; 2=Nao
	endif

	// Variaveis necessarias para a impressao.
	Private AFILBRW := {}
	Private cCondicao :=" "
	cCondicao := "F2_FILIAL=='"+xFilial("SF2")+"'"
	AFILBRW	 := {'SF2',cCondicao}

	do while .T.
		SpedDanfe()
		if ! (funname () == "IMPDANFE" .and. msgyesno ("Imprimir outro DANFe?"))
			exit
		endif
	enddo

	U_ML_SRArea (_aAreaAnt)
return
