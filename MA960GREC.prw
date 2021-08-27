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
// 27/08/2021 - Claudia - Incluida novas validações. GLPI: 10838 e 10839
//
//---------------------------------------------------------------------------------
#include "protheus.ch" 

User Function MA960GREC()
 
    Local aParam   := {0, '', '', 0, ''}    // Parâmetros de retorno default
    Local cReceita := PARAMIXB[1]           // Código de Receita da guia atual
    Local cUF      := PARAMIXB[2]           // Sigla da UF da guia atual

    nHandle := FCreate("c:\temp\logGNRE.txt")
    _sTexto := "receita " + cReceita
    FWrite(nHandle,_sTexto )

    _sTexto := "UF " + cUF
    FWrite(nHandle,_sTexto )

    Do Case
        Case Alltrim(cReceita) $ '100099/100102/100110/100129' .and. cUF == 'MT'    
            Do Case
                Case Alltrim(cReceita) == '100099'
                    aParam := {10, '1', '000017', 0, ''}  

                Case Alltrim(cReceita) == '100102'
                    aParam := {10, '1', '000055', 0, ''}  

                Case Alltrim(cReceita) == '100110'
                    aParam := {10, '1', '000056', 0, ''} 

                Case Alltrim(cReceita) == '100129'
                    aParam := {10, '1', '000057', 0, ''} 

            EndCase   

        Case Alltrim(cReceita) $ '100099/100102/100110/100129' .and. cUF == 'RJ'   
            aParam := {24, '2', '', 0, ''} 

        Case  Alltrim(cReceita) $ '100099/100102/100110/100129' .and. cUF == 'MG' 
            _sTexto := cUF
            FWrite(nHandle,_sTexto )  

            _sTexto := "RECEITA: " + Alltrim(cReceita)
            FWrite(nHandle,_sTexto )  

            If Alltrim(cReceita) == '100129'
                aParam := {10, '1', '000051', 0, ''} 
                _sTexto := "1"
                FWrite(nHandle,_sTexto )
            Else  
                aParam := {10, '1', '', 0, ''} 
                _sTexto := "2"
                FWrite(nHandle,_sTexto )    
            EndIf 

        Otherwise   
            aParam := {10, '1', '', 0, ''}                      // Retorna os campos F6_TIPOGNU, F6_DOCORIG, F6_DETRECE, F6_CODPROD e F6_CODAREA de acordo com o código de receita e sigla da UF da guia atual.
            _sTexto := "Otherwise"
            FWrite(nHandle,_sTexto )    
    EndCase

    FClose(nHandle)
Return aParam
