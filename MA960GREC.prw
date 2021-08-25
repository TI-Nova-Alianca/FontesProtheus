// Programa...: MA960GREC
// Autor......: Cláudia Lionço
// Data.......: 24/08/2021
// Descricao..: Ponto de Entrada para preenchimento dos campos F6_TIPOGNU, F6_DOCORIG, 
//              F6_DETRECE e F6_CODPROD de acordo com o código de receita e UF.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de Entrada para preenchimento dos campos F6_TIPOGNU, F6_DOCORIG, F6_DETRECE e F6_CODPROD de acordo com o código de receita e UF.
// #PalavasChave      #GNRE 
// #TabelasPrincipais #
// #Modulos   		  #FIS 
//
// Historico de alteracoes:
//
//---------------------------------------------------------------------------------
#include "protheus.ch" 

User Function MA960GREC()
 
    Local aParam   := {0, '', '', 0, ''}    // Parâmetros de retorno default
    Local cReceita := PARAMIXB[1]           // Código de Receita da guia atual
    //Local cUF      := PARAMIXB[2]           // Sigla da UF da guia atual

    //nHandle := FCreate("c:\temp\logGNRE.txt")
    //_sTexto := "receita " + cReceita
    //FWrite(nHandle,_sTexto )

    //_sTexto := "UF " + cUF
   // FWrite(nHandle,_sTexto )
    
    If Alltrim(cReceita) $ '100099/100102/100129'    // Valida o Código de Receita --e sigla da UF da guia atual
        aParam := {10, '1', Alltrim(cReceita), 0, ''}        // Retorna os campos F6_TIPOGNU, F6_DOCORIG, F6_DETRECE, F6_CODPROD e F6_CODAREA de acordo com o código de receita e sigla da UF da guia atual.
    EndIf

    //FClose(nHandle)
Return aParam
