
// Programa...: LJ7016
// Autor......: Cl�udia Lion�o
// Data.......: 19/02/2021
// Descricao..: P.E. Customiza��o da barra de fun��es
//              https://tdn.totvs.com/pages/releaseview.action?pageId=6791060
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. Customiza��o da barra de fun��es
// #PalavasChave      #barra_de_funcoes
// #TabelasPrincipais #
// #Modulos   		  #LOJA 
//
// Historico de alteracoes:
//
// ---------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function LJ7016()
    Local _aDados := {}
    Local nAtalho := Paramixb[2]
    Local aAtalho := {}

    /*Defini��o do array de retorno
    1 - T�tulo para o Menu (caracter)
    2 - T�tulo para o Bot�o (caracter)
    3 - Resource (objeto)
    4 - Fun��o a ser executada (f�rmula)
    5 - Aparece na ToolBar lateral (l�gico)
    6 - Habilitado? (l�gico)
    7 - Grupo ( inteiro, 1 = grava��o, 2 = detalhes, 3 = Estoque e 4 = Outros )
    8 - Tecla de Atalho (vetor): � um Array com a seguinte defini��o: 1 - identifica��o (inteiro) 2 - comandos (caracter)
    */

    nAtalho++
    aAtalho := Lj7Atalho(nAtalho) 
    AAdd(_aDados, {"Tabelas de Pre�o" , "Tabelas de Pre�o" , "RELATORIO", { || U_LJTABPRE( ) }, .T., .T., 4, aAtalho} ) 

Return(_aDados)
//
// ----------------------------------------------------------------------------------------------
// Tela com descri��o das tabelas
User Function LJTABPRE()                        
    Local oGroup1
    Local oListBox1
    Local nListBox1 := 1
    Static oDlg

    DEFINE MSDIALOG oDlg TITLE "Tabelas de Pre�o" FROM 000, 000  TO 205, 330 COLORS 0, 16777215 PIXEL

        @ 004, 003 GROUP oGroup1 TO 099, 162 PROMPT "Tabelas de Pre�o" OF oDlg COLOR 0, 16777215 PIXEL
        @ 017, 014 LISTBOX oListBox1 VAR nListBox1 ITEMS {"01 - Gondola","02 - Cx Fechada","03 - Associados/Funcion�rios","04 - Parceiros revenda","05 - Feirinha/comunidades","06 - Comercial externo","07 - Comercial externo 2","08 - Tumeleiro","09 - Promo��es/Black Friday"} SIZE 138, 071 OF oDlg COLORS 0, 16777215 PIXEL

    ACTIVATE MSDIALOG oDlg CENTERED

Return
