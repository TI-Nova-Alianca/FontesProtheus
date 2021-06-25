//  Programa...: VA_CLIDEV
//  Autor......: Cláudia Lionço
//  Data.......: 20/01/2021
//  Descricao..: Relatório de títulos vencidos/clientes inadimplentes 
//
// #TipoDePrograma    #relatorio
// #Descricao         #Relatório de títulos vencidos/clientes inadimplentes 
// #PalavasChave      #titulos_vencidos #clientes_inadimplentes
// #TabelasPrincipais #SE1 
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
// 25/06/2021 - Claudia - Incluido o programa U_VA_CLIPER. GLPI:10329
//
// --------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_CLIDEV()
	Private cPerg   := "VA_CLIDEV"
	
	_ValidPerg()
	Pergunte(cPerg,.T.)
	
	Do Case
            Case mv_par01 == 1 // Indice
                  U_VA_CLIIND()
            Case mv_par01 == 2 // Titulos em atraso/periodo
                  U_VA_CLIPER()
	      Case mv_par01 == 3 // Títulos em atraso - Analitico
                  U_VA_CLIATIT()
		Case mv_par01 == 4 // Clientes em atraso
                  U_VA_CLITATR()
            Case mv_par01 == 5 // Titulos já quitados em atraso
                  U_VA_CLITITA()
           

	EndCase
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT         TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Opção 		", "N", 1,  0,  "",   "   ", {"Indice","Titulos/Periodo","Títulos","Clientes", "Pagos em atraso"}			,"Define o tipo de impressão"})
    U_ValPerg (cPerg, _aRegsPerg)
Return
