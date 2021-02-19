
// Programa...: LJ7016
// Autor......: Cláudia Lionço
// Data.......: 19/02/2021
// Descricao..: P.E. Customização da barra de funções
//              https://tdn.totvs.com/pages/releaseview.action?pageId=6791060
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. Customização da barra de funções
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

    /*Definição do array de retorno
    1 - Título para o Menu (caracter)
    2 - Título para o Botão (caracter)
    3 - Resource (objeto)
    4 - Função a ser executada (fórmula)
    5 - Aparece na ToolBar lateral (lógico)
    6 - Habilitado? (lógico)
    7 - Grupo ( inteiro, 1 = gravação, 2 = detalhes, 3 = Estoque e 4 = Outros )
    8 - Tecla de Atalho (vetor): É um Array com a seguinte definição: 1 - identificação (inteiro) 2 - comandos (caracter)
    */

    nAtalho++
    aAtalho := Lj7Atalho(nAtalho) 
    AAdd(_aDados, {"Tabelas de Preço" , "Tabelas de Preço" , "RELATORIO", { || U_LJTABPRE( ) }, .T., .T., 4, aAtalho} ) 

Return(_aDados)
//
// ----------------------------------------------------------------------------------------------
// Tela com descrição das tabelas
User Function LJTABPRE()                        
    Local oGroup1
    Local oListBox1
    Local nListBox1 := 1
    Static oDlg

    DEFINE MSDIALOG oDlg TITLE "Tabelas de Preço" FROM 000, 000  TO 205, 330 COLORS 0, 16777215 PIXEL

        @ 004, 003 GROUP oGroup1 TO 099, 162 PROMPT "Tabelas de Preço" OF oDlg COLOR 0, 16777215 PIXEL
        @ 017, 014 LISTBOX oListBox1 VAR nListBox1 ITEMS {"01 - Gondola","02 - Cx Fechada","03 - Associados/Funcionários","04 - Parceiros revenda","05 - Feirinha/comunidades","06 - Comercial externo","07 - Comercial externo 2","08 - Tumeleiro","09 - Promoções/Black Friday"} SIZE 138, 071 OF oDlg COLORS 0, 16777215 PIXEL

    ACTIVATE MSDIALOG oDlg CENTERED

Return
