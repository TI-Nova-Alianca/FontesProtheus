//  Programa...: VA_PERCOMP
//  Autor......: Catia Cardoso
//  Data.......: 23/01/2017
//  Descricao..: Gera percentuais de composicao preço - Mercanet 
// 
//  Historico de alterações
//  02/02/2017 - Catia - 

#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_PERCOMP()

	cPerg   := "VA_PERCOMP"
		
	_ValidPerg()
    if Pergunte(cPerg,.T.)
			
		// monta consulta   
    	_sQuery := " "
    	_sQuery += " SELECT SA1.A1_VEND 	 AS VEND"
    	_sQuery += "      , VPC.CODCLI 	     AS CODCLI"
    	_sQuery += "      , SA1.A1_NOME 	 AS NOME"
    	_sQuery += "      , SA1.A1_EST  	 AS EST"
    	_sQuery += "      , VPC.CODPRO 	     AS CODPRO"
    	_sQuery += "      , SB1.B1_DESC      AS DESCRI"
    	_sQuery += "      , VPC.CUSTOPRO     AS CUSTO"
		_sQuery += "      , VPC.MARGEM       AS MARGEM"
		_sQuery += "      , VPC.RAPEL        AS RAPEL"
		_sQuery += "      , VPC.COMIS        AS COMIS"
		_sQuery += "      , VPC.ICMS         AS ICMS"
		_sQuery += "      , VPC.PISCOF       AS PISCOF"
		_sQuery += "      , VPC.PFRETE       AS PFRETE"
		_sQuery += "      , VPC.FINAN        AS FINAN"
		_sQuery += "      , VPC.PERTOT       AS PERTOT"
		_sQuery += "      , VPC.COMPOSICAO   AS PR_COMP"
		_sQuery += "      , VPC.PR_PRATICADO AS PR_ATUAL"
		_sQuery += "      , VPC.MARGEM_ATUAL AS MARGEM_ATUAL"
		_sQuery += "      , VPC.MARGEM_BLQ   AS MARGEM_BLQ"
  		_sQuery += "   FROM MER_PERCOMP AS VPC"
  		if mv_par07 = 1
  			_sQuery += " WHERE VPC.PR_PRATICADO > 0 " 
		endif  			   
  		_sQuery += "	  INNER JOIN SA1010 AS SA1" 			
  		_sQuery += "		ON (SA1.D_E_L_E_T_ = ''"
  		if val(mv_par01) + val(mv_par02) > 0
  			_sQuery += "		AND SA1.A1_VEND BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
  		endif				
  		if val(mv_par01) + val(mv_par02) > 0
  			_sQuery += "		AND SA1.A1_COD BETWEEN '" + mv_par02 + "' AND '" + mv_par03 + "'"
  		endif				
  		_sQuery += "			AND SA1.A1_COD = VPC.CODCLI)" 		
  		_sQuery += "	  INNER JOIN SB1010 AS SB1" 			
  		_sQuery += "		ON (SB1.D_E_L_E_T_ = ''"
  		if val(mv_par03) + val(mv_par04) > 0
  			_sQuery += "		AND SB1.B1_COD BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
  		endif				
  		_sQuery += "			AND SB1.B1_COD = VPC.CODPRO)"   		
  				
		_aDados := U_Qry2Array(_sQuery)
		if len(_aDados) > 0 
			do while .t.
				_aCols = {}
	
				aadd (_aCols, {1,  "VENDEDOR"       ,  30,  "@!"})
				aadd (_aCols, {2,  "CLIENTE"        ,  30,  "@!"})
				aadd (_aCols, {3,  "RAZAO SOCIAL"   ,  90,  "@!"})
				aadd (_aCols, {4,  "UF"             ,  10,  "@!"})
		    	aadd (_aCols, {5,  "PRODUTO"        ,  30,  "@!"})
		    	aadd (_aCols, {6,  "DESCRICAO"      ,  30,  "@!"})
		    	aadd (_aCols, {7,  "CUSTO"          ,  40,  "@E 999.99"})
		    	aadd (_aCols, {8,  "MARGEM IDEAL"   ,  35,  "@E 999.99"})
		    	aadd (_aCols, {9,  "RAPEL"          ,  35,  "@E 999.99"})
		    	aadd (_aCols, {10, "COMIS"          ,  35,  "@E 999.99"})
		    	aadd (_aCols, {11, "ICMS"           ,  35,  "@E 999.99"})
		    	aadd (_aCols, {12, "PISCOF"         ,  35,  "@E 999.99"})
		    	aadd (_aCols, {13, "FRETE"          ,  35,  "@E 999.99"})
		    	aadd (_aCols, {14, "FINANC"         ,  35,  "@E 999.99"})
		    	aadd (_aCols, {15, "%TOTAL"         ,  35,  "@E 999.99"})
		    	aadd (_aCols, {16, "PR COMPOSICAO"  ,  35,  "@E 9,999.99"})
		    	aadd (_aCols, {17, "PR PRATICADO"   ,  35,  "@E 9,999.99"})
		    	aadd (_aCols, {18, "MARGEM ATUAL"   ,  35,  "@E 999.99"})
		    	aadd (_aCols, {19, "MARGEM BLOQUEIO",  35,  "@E 999.99"})
		    	
				_wlinha = U_F3Array (_aDados, "Gera Percentuais para Composição Preço - Mercanet", _aCols, oMainWnd:nClientWidth - 50, oMainWnd:nClientHeight -15 , "", "", .T., 'C' )

				if _wlinha = 0
					exit
				endif
			enddo				
		
		else
			msgalert("Não foram encontrados dados para consulta")
		endif
	endif
return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Vendedor de            ?", "C",  6, 0,  "",   "SA3", {},  ""})
    aadd (_aRegsPerg, {02, "Vendedor até           ?", "C",  6, 0,  "",   "SA3", {},  ""})
    aadd (_aRegsPerg, {03, "Cliente de             ?", "C",  6, 0,  "",   "SA1", {},  ""})
    aadd (_aRegsPerg, {04, "Cliente até            ?", "C",  6, 0,  "",   "SA1", {},  ""})
    aadd (_aRegsPerg, {05, "Produto de             ?", "C",  4, 0,  "",   "SB1", {},  ""})
    aadd (_aRegsPerg, {06, "Produto até            ?", "C",  4, 0,  "",   "SB1", {},  ""})
    aadd (_aRegsPerg, {07, "Só MIX do cliente      ?", "N",  1, 0,  "",   "   ", {"Sim","Nao"},             ""})
    
    U_ValPerg (cPerg, _aRegsPerg)
Return