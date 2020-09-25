// Programa.:  BatPreEnt
// Autor....:  Catia Cardoso       
// Data.....:  07/05/2015     
// Descricao:  Verificacoes diarias -  Email de Produtos Recebidos no dia anterior
//             Criado para ser executado via batch.
//			   QUEM RECEBE EH O PESSOAL DO ADMINISTRATIVO DA PRODUCAO
// Historico de alteracoes:
// 01/06/2015 - Desconsiderar os itens PA e VD
// --------------------------------------------------------------------------
user function BatADMP_Recebidos(_sQueFazer)
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _oSQL     := NIL
	local _sMsg     := ""
//	local _sDest    := ""
	local _aCols    := {}
	local _sArqLog2 := iif (type ("_sArqLog") == "C", _sArqLog, "")
	_sArqLog := U_NomeLog (.t., .f.)
	u_logIni ()

   if alltrim (upper (_sQueFazer)) == "OC"
	   _aCols = {}
	   aadd (_aCols, {'Dt.Entrega'  ,    'left' ,  ''})
	   aadd (_aCols, {'Cod.Forn'    ,    'left' ,  ''})
	   aadd (_aCols, {'Fornecedor'  ,    'left' ,  ''})
	   aadd (_aCols, {'Nota Fiscal' ,    'left' ,  ''})
	   aadd (_aCols, {'Produto'     ,    'left' ,  ''})
	   aadd (_aCols, {'Descrição'   ,    'left' ,  ''})
	   aadd (_aCols, {'UN'          ,    'left' ,  ''})
	   aadd (_aCols, {'Quantidade'  ,    'right',  ''})
		
	   // le todas as notas que entraram no dia anterior
	   _oSQL := ClsSQL():New ()
	   _oSQL:_sQuery := ""
	   _oSQL:_sQuery += " SELECT SD1.D1_DTDIGIT, SD1.D1_FORNECE"
	   _oSQL:_sQuery += "	   	, SA2.A2_NOME"
       _oSQL:_sQuery += "		, SD1.D1_DOC, SD1.D1_COD, SD1.D1_DESCRI, SD1.D1_UM"
	   _oSQL:_sQuery += "		, dbo.FormataValor (SD1.D1_QUANT, 4, 15) AS QUANT"
	   _oSQL:_sQuery += "    FROM " + RetSQLName ("SD1") + " AS SD1 "
	   _oSQL:_sQuery += " 		    INNER JOIN " + RetSQLName ("SB1") + " AS SB1 "
	   _oSQL:_sQuery += " 		    			ON (SB1.D_E_L_E_T_ = ''"
	   _oSQL:_sQuery += " 		    				AND SB1.B1_COD = SD1.D1_COD"
	   _oSQL:_sQuery += " 		    				AND SB1.B1_TIPO !='PA'"
	   _oSQL:_sQuery += " 		    				AND SB1.B1_TIPO !='VD')"
  	   _oSQL:_sQuery += " 		    INNER JOIN " + RetSQLName ("SF1") + " AS SF1 "
	   _oSQL:_sQuery += "				ON (SF1.D_E_L_E_T_ = ''"
	   _oSQL:_sQuery += "					AND SF1.F1_FILIAL   = SD1.D1_FILIAL"
	   _oSQL:_sQuery += "					AND SF1.F1_EMISSAO  = SD1.D1_EMISSAO"
	   _oSQL:_sQuery += "					AND SF1.F1_FORNECE  = SD1.D1_FORNECE"
	   _oSQL:_sQuery += "					AND SF1.F1_LOJA     = SD1.D1_LOJA"
	   _oSQL:_sQuery += "					AND SF1.F1_DOC      = SD1.D1_DOC"
	   _oSQL:_sQuery += "					AND SF1.F1_SERIE    = SD1.D1_SERIE"
	   _oSQL:_sQuery += "					AND SF1.F1_TIPO    != 'C'"
	   _oSQL:_sQuery += "					AND SF1.F1_ESPECIE !='CTR'"
	   _oSQL:_sQuery += "					AND SF1.F1_ESPECIE !='CTE')"
	   _oSQL:_sQuery += " 		    INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
	   _oSQL:_sQuery += "				ON (SF4.D_E_L_E_T_ = ''"
	   _oSQL:_sQuery += "					AND SF4.F4_CODIGO  = SD1.D1_TES"
	   _oSQL:_sQuery += "					AND SF4.F4_ESTOQUE = 'S')"
	   _oSQL:_sQuery += " 		    INNER JOIN " + RetSQLName ("SA2") + " AS SA2 "
	   _oSQL:_sQuery += "				ON (SA2.D_E_L_E_T_ = ''"
	   _oSQL:_sQuery += "					AND SA2.A2_COD    = SD1.D1_FORNECE"
	   _oSQL:_sQuery += "					AND SA2.A2_LOJA   = SD1.D1_LOJA)"
	   _oSQL:_sQuery += "	WHERE SD1.D_E_L_E_T_ = ''"
   	   _oSQL:_sQuery += "	  AND SD1.D1_FILIAL = '01'"	
   	   _oSQL:_sQuery += "	  AND SD1.D1_DTDIGIT = '" + dtos (date()-1) + "'"
   	   _oSQL:_sQuery += "	  AND SD1.D1_COD != 'FR01'"
   	   _oSQL:_sQuery += "	  AND SD1.D1_COD != 'FR02'"
   	   _oSQL:_sQuery += "	  AND SD1.D1_COD != '9996'"
   	   _oSQL:_sQuery += "	  AND SD1.D1_COD != '9997'"
   	   _oSQL:_sQuery += "	  AND SD1.D1_COD != '9998'"
   	   _oSQL:_sQuery += "	  AND SD1.D1_TES != '184'"
	   _oSQL:_sQuery += "  ORDER BY SA2.A2_NOME,SD1.D1_DESCRI"
	    
	   //u_showmemo( _oSQL:_sQuery )
	   
	   u_log (_oSQL:_sQuery)
	   if len (_oSQL:Qry2Array (.T., .F.)) > 0
	   
	     _sMsg = _oSQL:Qry2HTM ("ADMP - Itens recebidos em: " + dtoc(date()-1), _aCols, "", .F.)
		  u_log (_sMsg)
		  
  	     U_ZZUNU ({'041'}, "ADMP - Itens recebidos no dia anterior", _sMsg, .F., cEmpAnt, cFilAnt, "") // Administrativo da Producao
	   endif

	endif
	
	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
	_sArqLog = _sArqLog2
return .T.
