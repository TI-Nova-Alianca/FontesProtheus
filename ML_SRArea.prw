// Programa:   ML_SRArea
// Autor:      Robert Koch
// Data:       23/06/2003
// Descricao:  Utilitario para salvar e restaurar a area atual de todos os arquivos
//             abertos no momento da chamada.
// Utilizacao: Para salvar a area corrente, nao passar nenhum parametro e guardar 
//             o valor de retorno em uma array.
//             Para restaurar, passar como parametro a array guardada na primeira chamada.
//             Ex.:
//             user function teste ()
//                local _aArea := U_ML_SRAREA ()
//                // ... procedimentos ...
//                U_ML_SRAREA (_aArea)
//             return
// 
// Historico de alteracoes:
// 26/02/2004 - Robert - Passa a testar se o arquivo ainda esta aberto antes de restaurar seu alias.
// 27/05/2005 - Robert - Opcoes 'SALVA' e 'RESTAURA' trocadas por 'S' e 'R'
// 19/07/2005 - Robert - Deixava sem alias atual ao salvar. Logo, dava erro ao ser chamada 2 vezes seguidas.
// 13/09/2005 - Robert - Assume operacao a realizar conforme tipo do parametro recebido.
// 11/10/2005 - Robert - Ajustes na restauracao das areas de trabalho originais.
//                     - Executava restarea apos restaurar (auto anulava-se a si mesma...)
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
user function ML_SRArea (_aAreaRest)
   local _aAreaAnt := {}
   local _nAlias   := 0
   local _xRet
   local _aAreaAtu := getarea ()
                         
   // Se nao recebi a area a restaurar, entao presumo que seja para salvar.
   if valtype (_aAreaRest) == "U"
      aadd (_aAreaAnt, {alias (), indexord (), recno ()})  // O primeiro eh o alias atual
      _nAlias = 1
      dbselectarea (_nAlias)
      do while alias () != ""
         if ascan (_aAreaAnt, {|_aVal| _aVal [1] == alias ()}) == 0
            aadd (_aAreaAnt, {alias (), indexord (), recno ()})
         endif
         _nAlias ++
         dbselectarea (_nAlias)
      enddo
      _xRet := _aAreaAnt
      restarea (_aAreaAtu)

   elseif valtype (_aAreaRest) == "A"
      for _nAlias = len (_aAreaRest) to 1 step -1  // Restaura "de re'", eh claro...
         _sAlias = _aAreaRest [_nAlias, 1]
         if ! empty (_sAlias) .and. select (_sAlias) != 0  // Algum arquivo pode nao estar mais aberto.
            dbselectarea (_sAlias)
            dbsetorder (_aAreaRest [_nAlias, 2])
            dbgoto (_aAreaRest [_nAlias, 3])
         endif
      next
      _xRet := NIL

   else
      msgbox (procname () + ": parametro incorreto recebido da funcao " + procname (1))
   endif

return _xRet

