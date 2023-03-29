// Programa...: VA_CUSTPER
// Autor......: Catia Cardoso
// Data.......: 18/08/2015
// Descricao..: Custo de itens no perído
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Custo de itens no perído
// #PalavasChave      #custo_de_itens 
// #TabelasPrincipais #SB1 #SB9
// #Modulos           #CUS 
//
// Historico de alteracoes:
// 29/04/2021 - Sandra - Solicitada a volta do relatório pela Liane
// 27/03/2023 - Robert - Acrescentadas colunas de cred.PIS/COF
//                     - Nao lista mais as uvas (grupo 0400)
//                     - Passa a listar custo total
//

#include 'totvs.ch'

// --------------------------------------------------------------------
User Function VA_CUSTPER()
	cPerg   := "VA_LMCRED"
	_ValidPerg()

	if Pergunte(cPerg,.T.) 
		_sSQL := " "
		_sSQL += " SELECT SB9.B9_FILIAL"
		_sSQL += "      , ' ' + SB9.B9_COD"
		_sSQL += "      , SB1.B1_DESC"
		_sSQL += "      , SB1.B1_UM"
		_sSQL += "      , SB1.B1_TIPO"
		_sSQL += "      , SB9.B9_QINI"
		_sSQL += "      , ROUND(B9_VINI1,7)"
		_sSQL += "      , ROUND((B9_VINI1*1.65/100),7)"
		_sSQL += "      , ROUND((B9_VINI1*7.6/100),7)"
		_sSQL += "   FROM " + RetSQLName ("SB9") + " SB9"
		_sSQL += "      INNER JOIN " + RetSQLName ("SB1") + " SB1"
		_sSQL += "         ON (SB1.D_E_L_E_T_ = ''"
		_sSQL += "             AND SB1.B1_COD = SB9.B9_COD"
		_sSQL += "             AND SB1.B1_TIPO IN ('ME', 'PS', 'MP')"
		_sSQL += "             AND SB1.B1_GRUPO != '0400'"  // Uvas nao participam
		_sSQL += "            )"
		_sSQL += "  WHERE SB9.D_E_L_E_T_ = ''"
		_sSQL += "    AND SB9.B9_DATA = '" + dtos(mv_par01) + "'"
		_sSQL += "    AND SB9.B9_QINI > 0"

		_aDados := U_Qry2Array(_sSQL)
		_aCols = {}
		aadd (_aCols, {1,  "Filial"        , 30,  "@!"})
		aadd (_aCols, {2,  "Produto"       , 30,  "@!"})
		aadd (_aCols, {3,  "Descricao"     , 140, "@!"})
		aadd (_aCols, {4,  "Unidade"       , 30,  "@!"})
		aadd (_aCols, {5,  "Tipo"          , 40,  "@!"})
		aadd (_aCols, {6,  "Quantidade"    , 40,  "@E 999,999.9999"})
		aadd (_aCols, {7,  "Custo tot.estq", 20,  "@E 999,999.999999999"})
		aadd (_aCols, {8,  "Cred PIS"      , 20,  "@E 999,999.999999999"})
		aadd (_aCols, {9,  "Cred COFINS"   , 20,  "@E 999,999.999999999"})

		U_F3Array (_aDados, "Consulta Custo do Período", _aCols, oMainWnd:nClientWidth - 50, NIL, "")
	endif
Return


// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
	aadd (_aRegsPerg, {01, "Data final Período        ?", "D", 8, 0,  "",   "   ", {},""})
	U_ValPerg (cPerg, _aRegsPerg)
Return
