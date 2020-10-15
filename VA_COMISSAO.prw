//  Programa...: VA_COMISSAO
//  Autor......: Cláudia Lionço
//  Data.......: 25/06/2020
//  Cliente....: Alianca
//  Descricao..: Relatório de Comissoes - Reescrito para novo modelo TREPORT 
//			     e alterações de verbas/comissões.
//
// #TipoDePrograma    #relatorio
// #PalavasChave      #comissoes #verbas #bonificação #comissões #representante #comissão
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
    aadd (_aRegsPerg, {01, "Opção 		", "N", 1,  0,  "",   "   ", {"Relatório","Email","Grv.Ajustes"}			,"Define se irá gerar o relatório/ e-mail para vendedor ou gravar os registros de ajustes manualmente."})
    U_ValPerg (cPerg, _aRegsPerg)
Return
