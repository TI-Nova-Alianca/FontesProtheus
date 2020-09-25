// Programa...: OrdAuto
// Autor......: Robert Koch
// Data.......: 15/06/2003
// Cliente....: Generico
// Descricao..: Ordena array para uso em rotina automatica conforme ordem dos
//              campos no SX3. Isso por que, se os campos forem enviados fora de
//              ordem, os gatilhos podem fazer as coisas mais inusitadas...
// Historico de alteracoes:            
// 02/03/2006 - Robert - Nao aceitava campos que nao constam no SX3.
//

// --------------------------------------------------------------------------
user function OrdAuto (_aMatriz)
   local _aMat     := {}
   local _aMatNova := {}
   local _nLinha   := 0
   local _sOrdem   := ""
   local _aAreaSX3 := sx3 -> (getarea ())

   // Monta uma matriz equivalente, com a ordem dos campos no SX3
   sx3 -> (dbsetorder (2))
   for _nLinha = 1 to len (_aMatriz)

      // Como algumas rotinas automaticas aceitam 'campos' nao presentes no
      // SX3 (por exemplo 'INDEX' ou 'AUTEXPLODE') tento deixa-los na primeira
      // posicao ou na ultima.
      if sx3 -> (dbseek (_aMatriz [_nLinha, 1], .F.))
         _sOrdem = sx3 -> x3_ordem
      else
         _sOrdem = iif (_nLinha == 1, "  ", "ZZ")
      endif
      aadd (_aMat, {_aMatriz [_nLinha, 1], _aMatriz [_nLinha, 2], _aMatriz [_nLinha, 3], _sOrdem})
   next

   // Ordena campos cfe. SX3
   _aMat := asort (_aMat,,, {|_x, _y| _x [4] < _y [4]})
   
   // Remonta a matriz original ordenada.
   for _nLinha = 1 to len (_aMat)
      aadd (_aMatNova, {_aMat [_nLinha, 1], _aMat [_nLinha, 2], _aMat [_nLinha, 3]})
   next

   restarea (_aAreaSX3)
return _aMatNova
