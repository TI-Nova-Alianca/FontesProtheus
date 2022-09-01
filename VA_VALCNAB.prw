
//  Programa...: VA_VALCNAB
//  Autor......: Cláudia Lionço
//  Data.......: 01/09/2022
//  Descricao..: Verificação totalizador CNAB
//
//  #TipoDePrograma    #relatorio
//  #Descricao         #Relatório de importações
//  #PalavasChave      #cartao #titulos #
//  #TabelasPrincipais #SE1 
//  #Modulos 		  #FIN 
//
//  Historico de alteracoes:
//
// --------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User Function VA_VALCNAB()
	Local _aDados 	:= {}
	Local _i 		:= 0
	Local _nTotal   := 0

    cPerg:='VA_VALCNAB'

    _ValidPerg()
	If Pergunte(cPerg,.T.)

        _sArquivo := alltrim(mv_par01) + alltrim(mv_par02)
        If !file(_sArquivo)
            u_help("Não existe o arquivo no caminho especificado!")
        else
            _aDados = U_LeCSV (_sArquivo, ';')

            //nHandle := FCreate("c:\temp\log.txt")
            For _i := 1 to len (_aDados)
                _slinha   := _aDados[_i, 1]
                _sEhLinha := SUBSTRING(_slinha,15,3)
                
                If alltrim(_sEhLinha) == '000'
                    
                    _nValor   := val(SUBSTRING(_slinha,105,30))/100
                    _nTotal += _nValor
                    //FWrite(nHandle,str(_nValor)+ chr(13)+chr(10))
                EndIf
            Next
            u_help("Valor total:" + str(_nTotal))
        //FClose(nHandle)
        EndIf
    EndIf
Return
//
// -------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                      PERGUNTA             TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Caminho          ", "C", 20, 0,  "",   "   ", {},                         		 ""})
    aadd (_aRegsPerg, {02, "Nome arquivo     ", "C", 20, 0,  "",   "   ", {},                         		 ""})

    U_ValPerg (cPerg, _aRegsPerg)
Return
