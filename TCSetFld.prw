// Programa:  TCSetFld
// Autor:     Robert Koch
// Data:      08/11/2006
// Cliente:   Generico
// Descricao: Recebe um alias gerado via query e executa TCSetField para os campos que encontras no SX3.
//
// Historico de alteracoes:
// 15/05/2215 - Robert - Faltava declaracao local da variavel _nCampo.
//

// --------------------------------------------------------------------------
user function TCSetFld (_sAlias)
   //local _aCampos   := {}
   local _aAreaAnt  := U_ML_SRArea ()
   local _nCampo    := 0

   // Altera tipo de campos cfe. dicionario de dados.
   sx3 -> (dbsetorder (2))
   for _nCampo = 1 to (_sAlias) -> (fcount ())
      if sx3 -> (dbseek (padr (alltrim ((_sAlias) -> (FieldName (_nCampo))), 10, " "), .F.))
         if sx3 -> x3_tipo $ "ND"  // Numerico ou data
            TCSetField (_sAlias, sx3 -> x3_campo, sx3 -> x3_tipo, sx3 -> x3_tamanho, sx3 -> x3_decimal)
         endif
      endif
   next

   U_ML_SRArea (_aAreaAnt)
return
