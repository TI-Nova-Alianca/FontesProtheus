// Programa..: ShowArray
// Autor.....: Robert Koch
// Data......: 20/12/2002
// Descricao.: Mostra uma array em tela, para conferencia.
//
// Parametros: - Matriz a ser mostrada (se nao for matriz, mostra tela simples.
//             - Mensagem a ser mostrada no cabecalho da tela
//             - Array com o titulo de cada coluna
//             - Nivel: nao informar. Usado em chamada recursiva.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Mostra uma array em tela, para conferencia.
// #PalavasChave      #array #mostra_array
// #TabelasPrincipais 
// #Modulos           #todos_modulos
//
// Historico de alteracoes:
// 24/08/2003 - Robert  - Trocada multiline por TWBrowse, que permite passar a linha atual 
//                        como parametro para uma chamada recursiva da propria funcao
//            - Robert  - Melhoramentos gerais
// 05/09/2003 - Robert  - Ajustado para aceitar subarrays de tamanhos diferentes.
// 10/09/2003 - Robert  - Passa a abrir seu proprio arquivo temporario para nao atrapalhar outros.
// 13/07/2005 - Robert  - Gera sempre o dialogo principal, independente do tipo de dado recebido.
// 22/09/2006 - Robert  - Passa a usar fonte monoespacada no browse
// 21/06/2007 - Robert  - Alterada fonte de letras para melhor visualizacao.
//            - Robert  - Passa a usar funcao MsAdvSize para calcular tamanho da tela.
// 14/07/2011 - Robert  - Usa funcao ClassDataArr() para mostrar dados de objetos.
// 16/12/2013 - Robert  - Criado botao de exportacao para planilha.
// 25/10/2016 - Robert  - Exportacao para planilha passa a array original e nao mais a array que 
//                        foi formatada para mostrar em tela.
// 01/07/2020 - Robert  - Verifica se tem interface com o usuario antes de tentar mostrar a tela.
// 23/04/2021 - Claudia - Ajustes para versão R25.
//
// ----------------------------------------------------------------------------------------------------
#include "rwmake.ch"

user function ShowArray (_aMatOrig, _sMensagem, _aTitulos, _nNivel)
   local _oBrowse   := NIL  // Browse da array. Deixar declarado como local para que ainda exista ao retornar de chamada recursiva
   local _oDlgArray := NIL  // Dialogo usado para o browse
   local _oLinAtu   := NIL  // Objeto get a ser atualizado na troca de linha. Deixar declarado como local para que ainda exista ao retornar de chamada recursiva
   local _aMatriz   := {}   // Matriz mostrada no browse. Nao mostro a original por conter dados de diferentes tipos.
   local _nLin      := 0    // Indice de linha
   local _nCol      := 0    // Indice de coluna
   local _sDadoNovo := ""   // Dado original transformado em string para colocar em _aMatriz
   local _aLinha    := {}   // Nova linha composta pelos dados da matriz original, a ser incluida em _aMatriz
   local _xDadoOrig := NIL  // Dado lido de _aMatOrig, que vai ser convertido para _sDadoNovo
   local _nTamLinha := 0    // Tamanho de cada linha. Para verificar se sao diferentes.
   local _sTipoDado := ""   // Tipo de dado de cada linha. Para verificar se sao diferentes.
   local _sAlias    := ""   // Alias de trabalho para o browse
   local _aAreaAnt  := {}
   local _aSize     := {}
   local _aArqTrb   := {}

   _sMensagem := iif (_sMensagem != NIL, _sMensagem, "")
   _nNivel    := iif (_nNivel    != NIL, _nNivel,    1)
   _aTitulos  := iif (_aTitulos  != NIL, _aTitulos,  {})

   // Se recebi uma matriz, tenho que fazer os tratamentos para visualizacao. Se nao foi uma matriz,
   // tem tratamento direto dentro do dialogo.
   if valtype (_aMatOrig) == "A" .and. len (_aMatOrig) > 0

      // Se a matriz original tem subarrays de tamanhos diferentes, monto _aMatriz "`a mao"
      _lTamDifer = .F.
      _nTamLinha = iif (valtype (_aMatOrig [1]) == "A", len (_aMatOrig [1]), 1)
      _sTipoDado = valtype (_aMatOrig [1])

      for _nLin = 2 to len (_aMatOrig)
         if valtype (_aMatOrig [_nLin]) != _sTipoDado .or. (valtype (_aMatOrig [_nLin]) == "A" .and. len (_aMatOrig [_nLin]) != _nTamLinha)
            _lTamDifer = .T.
         endif
      next

      // Transforma todos os dados em string e joga para a nova matriz
      for _nLin = 1 to len (_aMatOrig)
         _aLinha = {}

         // Caso seja uma matriz unidimensional, tem apenas uma coluna e busco
         // o dado original de outra forma.
         for _nCol = 1 to iif (valtype (_aMatOrig [_nLin]) == "A" .and. ! _lTamDifer, len (_aMatOrig [_nLin]), 1)

            if valtype (_aMatOrig [_nLin]) == "A"
               _xDadoOrig := iif (_lTamDifer, {}, _aMatOrig [_nLin, _nCol])
            else
               _xDadoOrig := _aMatOrig [_nLin]
            endif

            // Transforma o dado original em string
            do case
            case valtype (_xDadoOrig) == "N"
               _sDadoNovo = alltrim (str (_xDadoOrig))
            case valtype (_xDadoOrig) == "D"
               _sDadoNovo = dtoc (_xDadoOrig)
            case valtype (_xDadoOrig) == "L"
               _sDadoNovo = iif (_xDadoOrig, ".T.", ".F.")
            case valtype (_xDadoOrig) == "M"
               _sDadoNovo = "MEMO"
            case valtype (_xDadoOrig) == "A"
               _sDadoNovo = "ARRAY [" + alltrim (str (len (_xDadoOrig))) + "]"
            case _xDadoOrig == NIL
               _sDadoNovo = "NIL"
            case valtype (_xDadoOrig) == "U"
               _sDadoNovo = "?Undef?"
            case valtype (_xDadoOrig) == "C"
               _sDadoNovo = alltrim (_xDadoOrig)
            endcase
            aadd (_aLinha, _sDadoNovo)
         next
         aadd (_aMatriz, aclone (_aLinha))
      next

      // Agora que tenho todos os dados em formato string, posso montar as larguras e titulos
      // Se recebi uma matriz unidimensional...
      if valtype (_aMatriz [1]) != "A"
         if len (_aTitulos) == 0
            _aTitulos  := {"Col1"}
         endif
         _aLargCols := {0}
         for _nLin = 1 to len (_aMatriz)
            _aLargCols [1] = max (_aLargCols [1], len (alltrim (_aMatriz [_nLin])) * 5)
         next
      else  // Recebi uma matriz multidimensional
         // Se encontrar mais colunas que recebi em _aTitulos, completo o resto.
         for _nCol = 1 to len (_aMatriz [1])
            if len (_aTitulos) < _nCol
               aadd (_aTitulos, "Col " + alltrim (str (_nCol)))
            endif
         next
         _aLargCols := array (len (_aMatriz [1]))
         afill (_aLargCols, 0)
         for _nLin = 1 to len (_aMatriz)
            for _nCol = 1 to len (_aMatriz [_nLin])
               _aLargCols [_nCol] = max (_aLargCols [_nCol], ;
                                         max (len (alltrim (_aMatriz [_nLin, _nCol])), len (alltrim (_aTitulos [_nCol]))) * 4)
            next
         next
      endif
   endif

   if type ("oMainWnd") != 'O'
      msgalert ("Funcao " + procname () + " nao encontrou ambiente grafico (interface com usuario) para mostrar a array recebida.", 'alert')
   else

      // A classe TWBrowse exige um 'alias' para trabalhar em cima. Por isso, como 
      // eu nao quero confusao com o alias atual do programa chamador, abro outro.
      _aAreaAnt = getarea ()
      _sAlias = "_ShowArr" + strzero (_nNivel, 2)
      
      aCampos := {}
      AADD(aCampos,{"Bah", "C", 1, 0})

      U_ArqTrb ("Cria", _sAlias, aCampos, {}, @_aArqTrb)

      //dbusearea (.T.,, criatrab ({{"Bah", "C", 1, 0}}, .T.), _sAlias, .T., .T.)
   
      // Gera posicoes para a janela na tela
      _aSize := MsAdvSize()
      
      // Ocupa a altura reservada para a barra de botoes.
      // _aSize [6] += iif (type ("oApp:lFlat") != "U" .and. oApp:lFlat, 20, 30)
      _aSize [4] = _aSize [6] / 2
      _aSize [4] -= 30
   
      _oDlgArray := MSDialog ():New (_aSize [1], ;  // Superior
                                     _aSize [1], ;  // Esquerda
                                     _aSize [6], ;  // Inferior
                                     _aSize [5], ;  // Direita
                                     "ShowArray - nivel " + alltrim (str (_nNivel)) + " - " + _sMensagem, ;  // Caption
                                     , ;  // Reservado
                                     , ;  // Reservado
                                     , ;  // Reservado
                                     , ;  // Reservado
                                     , ;  // Cor do texto
                                     , ;  // Cor do fundo
                                     , ;  // Reservado
                                     oMainWnd, ;  // Janela pai
                                     .T., ;  // Pixels. Se .F. eh em caracteres
                                     , ;  // Reservado
                                     , ;  // Reservado
                                     ,)   // Reservado
   
         if valtype (_aMatOrig) != "A" .and. valtype (_aMatOrig) != "O"
            @ 10, 10 say "Elemento simples (nao array) recebido:"
            @ 20, 10 say "Tipo de dado: " + valtype (_aMatOrig)
            @ 30, 10 say "Tamanho: " + iif (valtype (_aMatOrig) $ "CM", alltrim (str (len (_aMatOrig))), "")
            @ 40, 10 say "Conteudo: " + cValToChar (_aMatOrig)
         elseif valtype (_aMatOrig) == "O"
            msgalert ("Recebi uma variavel tipo 'objeto'. Vou tentar abrir seus dados a seguir.", 'info')
            U_ShowArray (ClassDataArr (_aMatOrig), "Objeto",,_nNivel + 1)
         elseif len (_aMatOrig) == 0
            @ 10, 10 say "Matriz vazia!"
         else
            _oBrowse := TWBrowse ():New (5, ;  // Superior
                                         5, ;  // Esquerda
                                         _oDlgArray:nClientWidth / 2 - 10, ;  // Largura
                                         _oDlgArray:nClientHeight / 2 - 38, ;  // Altura
                                         , ;  // Campos (se fosse em cima de um arquivo
                                         _aTitulos, ;   // Cabecalhos colunas
                                         _aLargCols, ;  // Larguras colunas
                                         _oDlgArray, ;  // Janela pai
                                         , ;     //  <cField> The expression for the SELECT <cField> FOR ... TO ... clause. It is a string expression.
                                         , ;     //  <uVal1> The expression for the SELECT ... FOR <uVal1> TO ... clause. It may be of any type and it is used to perform a SEEK of it when doing the <oBrw>:GoTop()
                                         , ;     //  <uVal2> The expression for the SELECT ... FOR ... TO <uVal2> clause. It may be of any type and it is used to look or the latest selected value. By default FiveWin will look for the nearest value where the index key changes.
                                         {|| _oLinAtu:Refresh ()}, ;  //  <bChange> A codeblock to evaluate every time a new row in the browse is selected.
                                         , ;     // <bLDblClick> A codeblock to evaluate when left double clicking with the mouse on the browse.
                                         , ;     // <bRClick>    A codeblock to evaluate when right clicking with the mouse on the browse.
                                         , ;     // <oFont>      The font object to use to display the text of the rows. By default it takes the font of its container object.
                                         , ;     // <oCursor>    An optional cursor object to change the appareance of the mouse when the mouse is over the browse. By default the mouse will look with the standard arrow.
                                         , ;     // <nClrFore>   A numeric value indicating the RGB color to use for the text color of the browse.
                                         , ;     // <nClrBack>   A numeric value indicating the RGB color to use for the background color of the browse.
                                         , ;     // <cMsg>       An optional message to display on the buttonbar -if the defined- of its container object.
                                         .F., ;  // <lUpdate>    A logical value indicating that this control must be automatically :Refresh() ed when doing a <oDlg>:Update() to its container object.
                                         _sAlias, ;     // <cAlias>     The alias where this browse must operate. By default the browse assumes the current selected workarea.
                                         .T., ;  // <lPixel>     If the coordinates nRow and nCol supplied should be considered as pixels.
                                         , ;     // <bWhen>      A codeblock to evaluate to enable or disable the control.
                                         .F., ;  // <lDesign>    If the browse should be moved around when clicking the mouse over it. By default is .f.. If you change it into .t., even at run-time- you will be able to drag around the control with the click of the mouse.
                                         , ;     // <bValid>     A codeblock to control if this control should leave or not the focus.
                                         , ;     // <bLClick>    A codeblock to evaluate when left clicking the mouse over it. This codeblock will be evaluated besides changing the selected browse row.
                                         )       // [\{<{uAction}>\}]  // Adicionado pela Microsiga, creio.
   
            _oBrowse:oFont := TFont():New ("Courier New", 7, 16)
            _oBrowse:SetArray (_aMatriz)
            _oBrowse:bLine := {|| _aMatriz [_oBrowse:nAT]}
            _oBrowse:bLDblClick := {|| U_ShowArray (_aMatOrig [_oBrowse:nAT], "Subarray " + alltrim (str (_oBrowse:nAT)),,_nNivel + 1)}
   
            // Informacoes gerais
            @ (_oDlgArray:nClientHeight / 2 - 25), 10  say "Dimensao da matriz: " + alltrim (str (_oBrowse:nLen)) + " x " + alltrim (str (iif (valtype (_aMatOrig [1]) != "A", 0, len (_aMatOrig [1]))))
            @ (_oDlgArray:nClientHeight / 2 - 25), 100 say "Linha atual:"
            @ (_oDlgArray:nClientHeight / 2 - 25), 130 get _oBrowse:nAT picture "9999" when .F. object _oLinAtu
         endif
         //@ (_oDlgArray:nClientHeight / 2 - 30), (_oDlgArray:nClientWidth / 2 - 150) button 'Planilha' action (U_AColsXLS (_aMatriz))
         @ (_oDlgArray:nClientHeight / 2 - 30), (_oDlgArray:nClientWidth / 2 - 150) button 'Planilha' action (U_AColsXLS (_aMatOrig))
         @ (_oDlgArray:nClientHeight / 2 - 30), (_oDlgArray:nClientWidth / 2 - 40) bmpbutton type 1 action (_oDlgArray:End ())
         _oDlgArray:Activate (   , ;     // ?
                                 , ;     // ?
                                 , ;     // ?
                              .F., ;     // Centralizado
                                 , ;     // {|Self|<bValid>}  // Bloco de codigo. Se retornar falso, nao permite que o dialogo seja fechado.
                                 , ;     // ?
                              )          // [{|Self|<bInit>}]  // Bloco de codigo a ser executado na inicializacao do dialogo
      (_sAlias) -> (dbclosearea ())
      restarea (_aAreaAnt)
   endif
return
