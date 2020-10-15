//  Programa...: VA_COMISSAO
//  Autor......: Cl�udia Lion�o
//  Data.......: 25/06/2020
//  Cliente....: Alianca
//  Descricao..: Relat�rio de Comissoes - Reescrito para novo modelo TREPORT 
//			     e altera��es de verbas/comiss�es.
//
// #TipoDePrograma    #relatorio
// #PalavasChave      #comissoes #verbas #bonifica��o #comiss�es #representante #comiss�o
// #TabelasPrincipais #SE3 #SE1 #SF2 #SD2 #SE5 #SA3
// #Modulos 		  #FIN 
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_COMISSAO()
	Private cPerg   := "VA_COMISSAO"
	
	_ValidPerg()
	Pergunte(cPerg,.T.)
	
	Do Case
		Case mv_par01 == 1
			U_VA_COMREL() // Relatorio de conferencia
		Case mv_par01 == 2
			U_VA_COMMAIL()// PDF para envio por email
		Case mv_par01 == 3
			U_BatVerbas(2)// Grava registros na tabela ZB0
	EndCase
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT         TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Op��o 		", "N", 1,  0,  "",   "   ", {"Relat�rio","Email","Grv.Ajustes"}			,"Define se ir� gerar o relat�rio/ e-mail para vendedor ou gravar os registros de ajustes manualmente."})
    U_ValPerg (cPerg, _aRegsPerg)
Return
