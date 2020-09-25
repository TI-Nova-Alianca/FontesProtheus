// Programa:   SalvaAmb
// Autor:      Robert Koch / Jeferson Rech
// Data:       23/05/2006
// Descricao:  Utilitario para salvar e restaurar variaveis de ambiente. Util para casos onde
//             sao abertos um getdados sobre outro, etc.
// Utilizacao: Para salvar o ambiente corrente, nao passar nenhum parametro e guardar 
//             o valor de retorno em uma array.
//             Para restaurar, passar como parametro a array guardada na primeira chamada.
//             Ex.:
//             user function teste ()
//                local _aAmb := U_SalvaAmb ()
//                // ... procedimentos ...
//                U_SalvaAmb (_aAmb)
//             return
// 
// Historico de alteracoes:
// 20/07/2006 - Robert - Incluida variavel 'cPerg'
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
user function SalvaAmb (_aAmbiente)
   local _aSalvos  := {}
   local _aAreaAtu := getarea ()
   local _aSalvar  := {}
   local _nVar     := 0
   local _sTipo    := ""

   // Monta lista de variaveis a serem salvas.
   aadd (_aSalvar, "aRotina")
   aadd (_aSalvar, "aRotAuto")
   aadd (_aSalvar, "aHeader")
   aadd (_aSalvar, "aCols")
   aadd (_aSalvar, "N")
   aadd (_aSalvar, "nUsado")
   aadd (_aSalvar, "aTela")
   aadd (_aSalvar, "aGets")
   aadd (_aSalvar, "cCadastro")
   aadd (_aSalvar, "aMemos")
   aadd (_aSalvar, "Inclui")
   aadd (_aSalvar, "Altera")
   aadd (_aSalvar, "lMsHelpAuto")
   aadd (_aSalvar, "lMsErroAuto")
   aadd (_aSalvar, "__LocalDriver")
   aadd (_aSalvar, "cPerg")
                         
   // Adiciona parametros de relatorios
   _nVar = 1
   do while type ("MV_PAR" + strzero (_nVar, 2)) != "U"
      aadd (_aSalvar, "MV_PAR" + strzero (_nVar, 2))
      _nVar ++
   enddo

   // Se nao recebi a area a restaurar, entao presumo que seja para salvar.
   if valtype (_aAmbiente) == "U"

      // Verifica todas as variaveis possiveis
      for _nVar = 1 to len (_aSalvar)

         // Testa se a variavel existe
         _sTipo = type (_aSalvar [_nVar])
         do case
            case _sTipo == "A"
               aadd (_aSalvos, {_aSalvar [_nVar], _sTipo, aclone (&(_aSalvar [_nVar]))})
            case _sTipo $ "NDLMC"
               aadd (_aSalvos, {_aSalvar [_nVar], _sTipo, &(_aSalvar [_nVar])})
            case _sTipo == "U"
               aadd (_aSalvos, {_aSalvar [_nVar], _sTipo, NIL})
         endcase
      next

   elseif valtype (_aAmbiente) == "A"
      for _nVar = 1 to len (_aAmbiente)

         // Restaura todas as variaveis que nao tinham tipo U (NIL).
         // Usa operador & para acessar valor da variavel.
         _sTipo = _aAmbiente [_nVar, 2]
         do case
            case _sTipo == "A"
               &(_aAmbiente [_nVar, 1]) := aclone (_aAmbiente [_nVar, 3])
            case _sTipo $ "NDLMC"
               &(_aAmbiente [_nVar, 1]) := _aAmbiente [_nVar, 3]
         endcase
      next
      _aSalvos := {}
   endif

   restarea (_aAreaAtu)
return _aSalvos
