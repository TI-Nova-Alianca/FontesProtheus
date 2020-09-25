// Programa...: ZX5_36
// Autor......: Cláudia Lionço
// Data.......: 23/04/2020
// Descricao..: Edicao de registros do ZX5 com chave especifica
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function ZX5_36 ()

	If U_ZZUVL ('045')
		U_ZX5A (4, "36", "U_ZX5_36LO ()", "allwaystrue ()")
	Endif
Return
// --------------------------------------------------------------------------
// Linha OK
User Function ZX5_36LO ()
	Local _lRet := .T.
	Local _x	:= 0
	Local _aCod := {}
	Local _oSQL := NIL
	Local _Err  := 0
	
	// Verifica linha duplicada.
	If _lRet .and. ! GDDeleted ()
		_lRet = GDCheckKey ({"ZX5_36COD"}, 4)
	Endif
    // Verifica nucleo
	If _lRet .and. ! GDDeleted ()
 		_sCod:= SubStr(GDFieldGet("ZX5_36COD"),1,2)   
 		
 		_oSQL := ClsSQL ():New ()
 		_oSQL:_sQuery := " SELECT DISTINCT ZAN_NUCLEO "
 		_oSQL:_sQuery += " FROM " + RetSQLName ("ZAN")
 		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
 		_oSQL:_sQuery += " AND  ZAN_NUCLEO = '" + AllTrim(_sCod) + "'"
 		_aCod := aclone (_oSQL:Qry2Array ())
 		
 		If len(_aCod) < 1
 			_lRet := .F.
 			u_help("O código inserido não pertence a nenhum grupo familiar ativo. Verifique!")
 		EndIf
	EndIf
	// verifica subnucleo
	If _lRet .and. GDDeleted ()
		_sCod := GDFieldGet("ZX5_36COD")
		
		_oSQL := ClsSQL ():New ()
 		_oSQL:_sQuery := " SELECT DISTINCT ZAN_SUBNUC "
 		_oSQL:_sQuery += " FROM " + RetSQLName ("ZAN")
 		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
 		_oSQL:_sQuery += " AND  ZAN_SUBNUC = '" + AllTrim(_sCod) + "'"
 		_aCod := aclone (_oSQL:Qry2Array ())
 		
 		If len(_aCod) >= 1
 			_lRet := .F.
 			u_help("O código de subnucleo é utilizado em um grupo familiar ativo. Não poderá ser excluido!")
 		EndIf
	EndIf
Return _lRet
