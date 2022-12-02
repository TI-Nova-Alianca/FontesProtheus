// Programa...: OM200VCG
// Autor......: Cl�udia Lion�o
// Data.......: 01/12/2022
// Descricao..: P.E. valida��o na aglutina��o de Cargas do M�dulo OMS
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada
// #Descricao         #P.E. valida��o na aglutina��o de Cargas do M�dulo OMS
// #PalavasChave      #montagem_de_carga 
// #TabelasPrincipais #DAK #DAI
// #Modulos           #OMS
//
// Historico de alteracoes:
//
// ------------------------------------------------------------------------------------------------------
User Function OM200VCG()
    Local lRet := .T.
    Local cCargaDest := PARAMIXB[1]	//	Carga de destino.
    Local cSeqDest   := PARAMIXB[2]	//  Caractere	Sequ�ncia da carga de destino.
    Local cCargaOri  := PARAMIXB[3]	//  Carga de origem.
    Local cSeqOri    := PARAMIXB[4]	//	Sequ�ncia da carga de origem.

    _sDest := Posicione("DAK",1, xFilial("DAK") + cCargaDest + cSeqDest, "DAK_VAFULL")
    _sOrig := Posicione("DAK",1, xFilial("DAK") + cCargaOri  + cSeqOri , "DAK_VAFULL")

    If _sDest == 'S' 
        u_Help("Carga " + cCargaDest + " j� enviada para fullsoft! Processo n�o poder� ser executado.")
        lRet := .F.
    EndIf
    If _sOrig == 'S'
        u_Help("Carga " + cCargaOri + " j� enviada para fullsoft! Processo n�o poder� ser executado.")
        lRet := .F.
    EndIf
Return lRet
