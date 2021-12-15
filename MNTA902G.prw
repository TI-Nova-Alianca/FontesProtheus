// Programa...: MNTA902G
// Autor......: Cláudia Lionço
// Data.......: 15/12/2021
// Descricao..: Adiciona Botões à Barra Lateral Árvore Lógica
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Adiciona Botões à Barra Lateral Árvore Lógica
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
 
    //Adição de botão com chamada do relatório de OS
    oBtnPE := TBtnBmp2():New( 00,00,27,25,"NG_ICO_VIS_RES_M",,,,{|| U_ImpOS()},oPnlBtn2,"Imp.OS",bOk,.T. ) //"Ponto de Entrada"
    oBtnPE:Align   := CONTROL_ALIGN_TOP
 
Return oPnlBtn2
