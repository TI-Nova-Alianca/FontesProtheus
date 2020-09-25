////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Programa:  VA_ATULTOC
// Autor:     Bruno Silva 
// Data:      09/02/2010
// Cliente:   Alianca
// Descricao: Função para retornar o último evento de cada nota, conforme tabela SZN, alimentando o campo F2_VAULTOC. (VA_DEN)
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#include "totvs.ch"
#include "protheus.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"
#INCLUDE "tbiconn.ch"

User Function VA_ATULT()
Local _cEvento := ""  

_cQuery := " SELECT ZN_HORA, ZN_DATA, ZN_TEXTO "
_cQuery += " FROM " + RetSQLName("SZN") + " SZN "
_cQuery += " WHERE SZN.D_E_L_E_T_ = '' "
_cQuery += " AND ZN_NFS = '" + SF2->F2_DOC + "' "  
//_cQuery += " AND ZN_NFS = '000000264' 

_cQuery += " AND ZN_SERIES = '" + SF2->F2_SERIE + "' "
//_cQuery += " AND ZN_SERIES = '10'

_cQuery += " AND ZN_STATUS <> '' " 
_cQuery += " ORDER BY ZN_DATA DESC, ZN_HORA DESC "

_aDados := U_Qry2Array(_cQuery)

If Len(_aDados) > 0
	_cEvento := alltrim(_aDados[1][3])
EndIf

Return _cEvento