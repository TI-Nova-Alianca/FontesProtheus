// Programa...: QuebraTXT
// Autor......: Robert Koch
// Data.......: 01/08/2003
// Descricao..: Retorna o texto passado separado em linhas, conforme tamanho maximo da
//              linha informado, separando as palavras, se possivel.
// 
// Historico de alteracoes:
// 01/02/2005 - Robert - Nao tratava chr(13) no texto (comum em campos memo)
//

//#INCLUDE "rwmake.ch"

// --------------------------------------------------------------------------
user function QuebraTxt (_sTexto, _nTamLin)
   local _aLinhas := {}
   local _nPos    := 0
   local _nChar   := 0
   local _sLinha  := ""
   
   do while len (_sTexto) > 0
      
      // Encontra o ultimo espaco dentro do tamanho da linha
      _nPos = rat (" ", left (_sTexto, _nTamLin))
      if _nPos == 0 .or. (_nPos <= len (_sTexto) .and. len (_sTexto) <= _nTamLin)  // Pega ultima palavra do texto.
         _nPos = _nTamLin
      endif

      // Cria uma linha para esta parte do texto
      _sLinha = left (_sTexto, _nPos)

      // Como a linha pode ter CR pode ser necessario fazer a quebra de linhas.
      // Para isso, vou ter que varrer toda a linha.
      _lTemEnter = .F.
      _nChar = 1
      do while _nChar <= len (_sLinha)
         if substr (_sLinha, _nChar, 1) == chr (13)
            aadd (_aLinhas, left (_sLinha, _nChar - 1))
            _sLinha = substr (_sLinha, _nChar + 2)  // Para 'pular' o chr(13) e o chr(10)
            _lTemEnter = .T.
            exit

         // Se chegou ateh aqui eh por que leu toda a linha e nao achou ENTER.
         elseif _nChar >= len (_sLinha)
            aadd (_aLinhas, _sLinha)
         endif
         _nChar ++
      enddo

      // Remove do texto a parte inserida na linha
      _sTexto = stuff (_sTexto, 1, _nPos, "")

      // Se fiz uma quebra de linha, vou jogar o restante da linha de volta para
      // o texto original para comecar tudo novamente.
      if _lTemEnter
         _sTexto = _sLinha + _sTexto
      endif
   enddo

return _aLinhas
