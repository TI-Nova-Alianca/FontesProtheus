// Programa:   VA_ZZ9
// Autor:      Robert Koch
// Data:       30/04/2009
// Descricao:  Tela de manutencao de pre-notas de compra de safra (tabela ZZ9)
// 
// Historico de alteracoes:
// 16/06/2009 - Robert - Informacao de NF de produtor para casos sem DCO.
// 09/06/2015 - Robert - Verifica se o usuario tem acesso pela tabela ZZU.
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
user function VA_ZZ9 ()
   private aRotina   := {}  // Opcoes do menu
   private cCadastro := "Manutencao de previsoes de notas de compra de uva"

	// Verifica se o usuario tem liberacao para uso desta rotina.
	if ! U_ZZUVL ('045', __cUserID, .T., cEmpAnt, cFilAnt)
		return
	endif

   aAdd(aRotina, {"Pesquisar"   , "AxPesqui", 0, 1})
   aAdd(aRotina, {"Visualizar"  , "AxVisual", 0, 2})
   aAdd(aRotina, {"Incluir"     , "AxInclui", 0, 3})
   aAdd(aRotina, {"Alterar"     , "AxAltera", 0, 4})
   aAdd(aRotina, {"Excluir"     , "AxDeleta", 0, 5})
   aAdd(aRotina, {"&NF Produtor", "U_VA_ZZ9N", 0, 4})

   dbSelectArea ("ZZ9")
   dbSetOrder (1)
   mBrowse(0, 0, 100, 100, "ZZ9",,,,, 2)
return



// --------------------------------------------------------------------------
// Preenche numero da NF do produtor em todos os registros relacionados.
user function VA_ZZ9N ()
	local _sSQL    := ""
	local _sNFProd := ""

//	_sNFProd = _Get ("Informe NF produtor", "C", tamsx3 ("ZZ9_NFPROD")[1], "@!", "", space (6), .F., ".T.")
	_sNFProd = U_Get ("Informe NF produtor", "C", tamsx3 ("ZZ9_NFPROD")[1], "@!", "", space (6), .F., ".T.")
	if valtype (_sNFProd) != 'U' .and. ! empty (_sNFProd)
		if ! empty (zz9 -> zz9_dco)
			_sSQL := ""
			_sSQL += "UPDATE " + RetSQLName ("ZZ9")
			_sSQL +=   " SET ZZ9_NFPROD = '" + _sNfProd + "'"
			_sSQL += " WHERE D_E_L_E_T_ = ''"
			_sSQL +=   " AND ZZ9_FILIAL = '" + xfilial ("ZZ9")   + "'"
			_sSQL +=   " AND ZZ9_PRE_NF = '" + zz9 -> zz9_pre_nf + "'"
			_sSQL +=   " AND ZZ9_SAFRA  = '" + zz9 -> zz9_safra  + "'"
			_sSQL +=   " AND ZZ9_PARCEL = '" + zz9 -> zz9_parcel + "'"
			_sSQL +=   " AND ZZ9_FORNEC = '" + zz9 -> zz9_fornec + "'"
			_sSQL +=   " AND ZZ9_LOJA   = '" + zz9 -> zz9_loja   + "'"
			_sSQL +=   " AND ZZ9_NFCOMP = ''"
			_sSQL +=   " AND ZZ9_DCO   != ''"
		else
			_sSQL := ""
			_sSQL += "UPDATE " + RetSQLName ("ZZ9")
			_sSQL +=   " SET ZZ9_NFPROD = '" + _sNfProd + "'"
			_sSQL += " WHERE D_E_L_E_T_ = ''"
			_sSQL +=   " AND ZZ9_FILIAL = '" + xfilial ("ZZ9")   + "'"
			_sSQL +=   " AND ZZ9_PRE_NF = '" + zz9 -> zz9_pre_nf + "'"
			_sSQL +=   " AND ZZ9_SAFRA  = '" + zz9 -> zz9_safra  + "'"
			_sSQL +=   " AND ZZ9_FORNEC = '" + zz9 -> zz9_fornec + "'"
			_sSQL +=   " AND ZZ9_LOJA   = '" + zz9 -> zz9_loja   + "'"
			_sSQL +=   " AND ZZ9_NFCOMP = ''"
			_sSQL +=   " AND ZZ9_DCO    = ''"
		endif
	
		if TCSQLExec (_sSQL) < 0
			msgalert ("Erro ao atualizar tabela.")
		endif
	endif
return


/*
// --------------------------------------------------------------------------
// Monta uma janela com texto e uma linha de get na tela. Usada para solicitar
// algum dado adicional ao usuario.
// Autor: Robert Koch - nov/2002
// Parametros: _sTexto   = texto a ser mostrado antes do get
//             _sTipo    = tipo de dado (C, D, N)
//             _nTamanho = tamanho da variavel a ser lida
//             _sMasc    = mascara (picture) a ser usada
//             _sF3      = para consulta padrao, se tiver. Senao, informar ""
//             _xIni     = inicializador para a variavel
//             _lPass    = se .T. faz leitura de senha (mostra asteriscos)
//             _sValid   = funcao para validacao
//
// Historico de alteracoes:
// 26/06/2003 - Robert - Implementada leitura de senha
// 19/01/2007 - Robert - Incluida opcao de informar funcao para validacao
//                     - Retorna NIL em caso de cancelamento
//
static function _Get (_sTexto, _sTipo, _nTamanho, _sMasc, _sF3, _xIni, _lPass, _sValid)
   local _xRet     := NIL
   local _oDlgGet  := NIL
   local _nLargura := min (max (300, max (len (_sTexto) * 5, _nTamanho * 10)), oMainWnd:nClientwidth / 2)
   private _xDado  // Deixar private para ser vista pela funcao de validacao

   _sF3    = iif (_sF3    == NIL, "",    _sF3)
   _sMasc  = iif (_sMasc  == NIL, "",    _sMasc)
   _lPass  = iif (_lPass  == NIL, .F.,   _lPass)
   _sValid = iif (_sValid == NIL, ".T.", _sValid)

   if _xIni != NIL .and. valtype (_xIni) != _sTipo
      msgbox ("Funcao _GET: inicializador incompativel com tipo de dado!")
      return NIL
   endif

   do case
      case _sTipo == "N"
         _xDado := iif (_xIni == NIL, 0, _xIni)
      case _sTipo == "D"
         _xDado := iif (_xIni == NIL, ctod (""), _xIni)
      case _sTipo == "C" .or. _sTipo == "M"
         _xDado := iif (_xIni == NIL, space (_nTamanho), _xIni)
   endcase

   define MSDialog _oDlgGet from 0, 0 to 120, _nLargura of oMainWnd pixel title "Entrada de dados"
      @ 10, 10 say _sTexto
      if _lPass
         @ 30, 10 get _xDado picture _sMasc size (_nTamanho * 4), 11 F3 _sF3 PASSWORD
      else
         @ 30, 10 get _xDado picture _sMasc size (_nTamanho * 4), 11 F3 _sF3
      endif
      @ 45, 10 bmpbutton type 1 action (iif (&(_sValid), (_xRet := _xDado, _oDlgGet:End ()), NIL))
   activate MSDialog _oDlgGet centered
return _xRet
*/
