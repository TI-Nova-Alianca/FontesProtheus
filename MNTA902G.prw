// Programa...: MNTA902G
// Autor......: Cl�udia Lion�o
// Data.......: 15/12/2021
// Descricao..: Adiciona Bot�es � Barra Lateral �rvore L�gica
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Adiciona Bot�es � Barra Lateral �rvore L�gica
// #PalavasChave      #arvore #impressao_OS #relatorio
// #TabelasPrincipais 
// #Modulos   		  #MNT 
//
// Historico de alteracoes:
//
// ----------------------------------------------------------------------------------
#include"Protheus.ch"
#include"hbutton.ch"
#include"DbTree.ch"
 
User Function MNTA902G()
 
    oPnlBtn2 := PARAMIXB[1]
 
    //Adi��o de bot�o com chamada do relat�rio de OS
    oBtnPE := TBtnBmp2():New( 00,00,27,25,"NG_ICO_VIS_RES_M",,,,{|| U_ImpOS()},oPnlBtn2,"Imp.OS",bOk,.T. ) //"Ponto de Entrada"
    oBtnPE:Align   := CONTROL_ALIGN_TOP
 
Return oPnlBtn2
