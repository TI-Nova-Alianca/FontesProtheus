// Programa...: _Mata310
// Autor......: Cláudia Lionço
// Data.......: 01/09/2021
// Descricao..: Tela Customizada de transferencias de produtos entre filiais MATA310
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processo
// #Descricao         #Tela Customizada de transferencias de produtos entre filiais MATA310
// #PalavasChave      #transferencia_entre_filiais #Transferencias_de_produtos 
// #TabelasPrincipais #SC5 #SC6 #SD1 #SF1
// #Modulos   		  #COM 
//
// Historico de alteracoes:
//
// ---------------------------------------------------------------------------------------------
#include "rwmake.ch"  
#include "protheus.ch"

User Function _Mata310()
        // Chamada do Processo de transferencia
        MATA310()

        // Transmissao.
    	// Variaveis usadas pelas rotinas da NFe
        U_SpedAut ('S', sf2 -> f2_serie, sf2 -> f2_doc, sf2 -> f2_doc)

Return
