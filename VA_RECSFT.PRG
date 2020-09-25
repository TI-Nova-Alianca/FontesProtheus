// Programa...: VA_RECSFT
// Autor......: Catia Cardoso
// Data.......: 11/01/2018
// Descricao..: Graca conta contabil correta no SFT - conforme regra do ato coopertivo/não cooperativo  
//
// Historico de alteracoes:
// 12/01/2018 - Catia - tratamento para fretes sobre saidas assumir a conta correta

#include "rwmake.ch"

#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function VA_RECSFT()
local i	:= 0
cPerg   := "VA_RECSFT"
_ValidPerg()

if Pergunte(cPerg,.T.)

	// AJUSTA NOTAS DE SAIDA - CONFORME ATO COOP E NAO COOP E ESPECIE
	_sSQL := ""
	_sSQL += " 	SELECT CASE WHEN SB1.B1_VAATO  = 'N' THEN '401010201002'"  // ato cooperativo NAO	    
	_sSQL += " 			    ELSE '401010101002'" // ato cooperativo SIM		    
	_sSQL += " 		   END"
	_sSQL += " 		, SFT.R_E_C_N_O_"
	_sSQL += " 		, SB1.B1_VAATO"
	_sSQL += "   FROM SFT010 AS SFT"
	_sSQL += " 		INNER JOIN SB1010 AS SB1"
	_sSQL += " 			ON (SB1.B1_COD = SFT.FT_PRODUTO)"
	_sSQL += "		INNER JOIN SD2010 AS SD2"
	_sSQL += "			ON (SD2.D_E_L_E_T_ = ''"
	_sSQL += "				AND SD2.D2_FILIAL  = SFT.FT_FILIAL"
	_sSQL += "				AND SD2.D2_CLIENTE = SFT.FT_CLIEFOR"
	_sSQL += "				AND SD2.D2_LOJA    = SFT.FT_LOJA"
	_sSQL += "				AND SD2.D2_EMISSAO = SFT.FT_ENTRADA"
	_sSQL += "				AND SD2.D2_DOC     = SFT.FT_NFISCAL"
	_sSQL += "				AND SD2.D2_SERIE   = SFT.FT_SERIE"
	_sSQL += "				AND SD2.D2_ITEM    = SFT.FT_ITEM)"
	_sSQL += "		INNER JOIN SF4010 AS SF4"
	_sSQL += "			ON (SF4.F4_CODIGO = SD2.D2_TES"
	_sSQL += "				AND SF4.F4_MARGEM = '1')"
	_sSQL += "  WHERE SFT.D_E_L_E_T_ = ''
	_sSQL += "    AND SFT.FT_FILIAL  BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_sSQL += "    AND SFT.FT_ENTRADA BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
	_sSQL += "    AND SFT.FT_NFISCAL BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	_sSQL += "    AND SFT.FT_SERIE   BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
	_sSQL += "    AND SFT.FT_CFOP    > '5000'"
	_sSQL += " ORDER BY FT_NFISCAL, FT_ITEM"
		
	//u_showmemo(_sSQL)
	_aDados := U_Qry2Array(_sSQL)
	if len (_aDados) > 0
		for i=1 to len(_aDados)
			_wconta = _aDados[i,1]
			_wrecno = _aDados[i,2]

			DbSelectArea("SFT")
			DbGoto(_wrecno)
			reclock("SFT", .F.)
				SFT-> FT_CONTA  = _wconta
			MsUnLock()
		        		
	    next
	endif
	// AJUSTA NOTAS DE ENTRADA DE FRETE SOBRE SAIDAS - FIXA CONTA FRETE SOBRE SAIDAS 
	_sSQL := ""
	_sSQL += " 	SELECT SFT.FT_CONTA"
    _sSQL += " 	 	 , SFT.FT_PRODUTO, SB1.B1_DESC, SFT.FT_ESPECIE"
    _sSQL += " 	 	 , SFT.R_E_C_N_O_"
  	_sSQL += " 	  FROM SFT010 AS SFT"
	_sSQL += " 		INNER JOIN SB1010 AS SB1"
	_sSQL += " 			ON (SB1.B1_COD = SFT.FT_PRODUTO)"
 	_sSQL += " 	 WHERE SFT.D_E_L_E_T_ = ''"
 	_sSQL += "     AND SFT.FT_FILIAL  BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_sSQL += "     AND SFT.FT_ENTRADA BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
	_sSQL += "     AND SFT.FT_NFISCAL BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	_sSQL += "     AND SFT.FT_SERIE   BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
	_sSQL += " 	   AND SFT.FT_CFOP    < '5000'"
   	_sSQL += " 	   AND SFT.FT_ESPECIE = 'CTE'"
   	_sSQL += " 	   AND SFT.FT_PRODUTO IN ('FR01','FR02')"
   	
   	//u_showmemo(_sSQL)
	_aDados := U_Qry2Array(_sSQL)
	if len (_aDados) > 0
		for i=1 to len(_aDados)
			_wrecno = _aDados[i,5]

			DbSelectArea("SFT")
			DbGoto(_wrecno)
			reclock("SFT", .F.)
				SFT-> FT_CONTA  = '403010401002'
			MsUnLock()
		        		
	    next
	endif
				    
endif
		 								
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Filial de          ?", "C",  2, 0,  "",   "SM0", {},  ""})
    aadd (_aRegsPerg, {02, "Filial até         ?", "C",  2, 0,  "",   "SM0", {},  ""})
    aadd (_aRegsPerg, {03, "Data de            ?", "D",  8, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {04, "Data ate           ?", "D",  8, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {05, "Nota fiscal de     ?", "C",  9, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {06, "Nota fiscal ate    ?", "C",  9, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {07, "Serie de           ?", "C",  3, 0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {08, "Serie ate          ?", "C",  3, 0,  "",   "   ", {},  ""})
    
    U_ValPerg (cPerg, _aRegsPerg)
Return
