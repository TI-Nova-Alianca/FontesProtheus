// Programa:  RetSQL
// Autor:     Robert Koch
// Data:      17/11/2006
// Cliente:   Generico
// Descricao: Busca o retorno de uma query, quando esse resultado for um dado simples.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function RetSQL (_sQuery)
   local _aAreaAnt := U_ML_SRArea ()
   local _sAliasQ  := ""
   local _xRet     := NIL

   _sAliasQ = GetNextAlias ()
   DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
   U_TCSetFld (_sAliasQ)
   _xRet = (_sAliasQ) -> (fieldget (1))
   (_sAliasQ) -> (dbclosearea ())

   U_ML_SRArea (_aAreaAnt)
return _xRet
