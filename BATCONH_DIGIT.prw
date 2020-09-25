// Programa.:  BatConhDigit
// Autor....:  Catia Cardoso       
// Data.....:  02/06/2015     
// Descricao:  Verificacoes diarias -  Email de Conhecimentos digitados dia anterior
//             Criado para ser executado via batch.
// Historico de alteracoes:
// --------------------------------------------------------------------------
user function BatConhDigit(_sQueFazer)
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
	   
	   aadd (_aCols, {'CTe'         ,    'left'  ,  ''})
	   aadd (_aCols, {'Dt.Emissao'  ,    'left'  ,  ''})
	   aadd (_aCols, {'Danfe'       ,    'left'  ,  ''})
	   aadd (_aCols, {'Cliente'     ,    'left'  ,  ''})
	   aadd (_aCols, {'Cidade'      ,    'left'  ,  ''})
	   aadd (_aCols, {'Estado'      ,    'left'  ,  ''})
	   aadd (_aCols, {'Peso'        ,    'right' ,  '@E 9,999,999.99'})
	   aadd (_aCols, {'Valor'       ,    'right' ,  '@E 999,999.99'})
	   aadd (_aCols, {'Valor/Kg'    ,    'right' ,  '@E 9,999.99'})
	   aadd (_aCols, {'Frete Perc.' ,    'right' ,  '@E 9,999.99'})
	   
	   // le todas as notas que entraram no dia anterior
	   _oSQL := ClsSQL():New ()
	   _oSQL:_sQuery := ""
	   _oSQL:_sQuery += " SELECT SF1.F1_DOC"
       _oSQL:_sQuery += "      , SF1.F1_EMISSAO"
	   _oSQL:_sQuery += "      , SZH.ZH_NFSAIDA"
	   _oSQL:_sQuery += "      , SA1.A1_NOME"
	   _oSQL:_sQuery += "      , SA1.A1_MUN"
	   _oSQL:_sQuery += "      , SA1.A1_EST"
	   _oSQL:_sQuery += "      , ROUND(SF2.F2_PBRUTO,2) AS PESO"
	   _oSQL:_sQuery += "      , ROUND(SUM(SZH.ZH_RATEIO),2) AS FRETE"
	   _oSQL:_sQuery += "      , CASE WHEN SUM(SF2.F2_PBRUTO) > 0 THEN ROUND(SUM(SZH.ZH_RATEIO)/SF2.F2_PBRUTO,2) ELSE 0 END AS FRETE_KG"
	   _oSQL:_sQuery += "      , CASE WHEN (SUM(SF2.F2_VALBRUT)+SUM(SF2.F2_ICMSRET)) >0 THEN ROUND(SUM(SZH.ZH_RATEIO)/(SUM(SF2.F2_VALBRUT)+SUM(SF2.F2_ICMSRET))*100,2) ELSE 0 END AS FRETE_X_PERC"
       _oSQL:_sQuery += "   FROM " + RetSQLName ("SF1") + " AS SF1 "
       _oSQL:_sQuery += " 		INNER JOIN " + RetSQLName ("SZH") + " AS SZH "
	   _oSQL:_sQuery += "			ON (SZH.D_E_L_E_T_ = ''"
	   _oSQL:_sQuery += "				AND SZH.ZH_FILIAL  = SF1.F1_FILIAL"
	   _oSQL:_sQuery += "				AND SZH.ZH_FORNECE = SF1.F1_FORNECE"
	   _oSQL:_sQuery += "				AND SZH.ZH_LOJA    = SF1.F1_LOJA"
	   _oSQL:_sQuery += "				AND SZH.ZH_NFFRETE = SF1.F1_DOC"
	   _oSQL:_sQuery += "				AND SZH.ZH_SERFRET = SF1.F1_SERIE)"
	   _oSQL:_sQuery += " 		INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
	   _oSQL:_sQuery += "			ON (SF2.D_E_L_E_T_ = ''"
	   _oSQL:_sQuery += "				AND SF2.F2_FILIAL = SZH.ZH_FILIAL"
	   _oSQL:_sQuery += "				AND SF2.F2_DOC    = SZH.ZH_NFSAIDA"
	   _oSQL:_sQuery += "				AND SF2.F2_SERIE  = SZH.ZH_SERNFS)"
	   _oSQL:_sQuery += " 		INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
	   _oSQL:_sQuery += "			ON (SA1.D_E_L_E_T_  = ''"
	   _oSQL:_sQuery += "				AND SA1.A1_COD  = SF2.F2_CLIENTE"
	   _oSQL:_sQuery += "				AND SA1.A1_LOJA = SF2.F2_LOJA)"
       _oSQL:_sQuery += " WHERE SF1.F1_FILIAL  = '01'" // fixo para matriz
       _oSQL:_sQuery += "	AND SF1.F1_DTDIGIT = '" + dtos (date()-1) + "'"
       _oSQL:_sQuery += "	AND SF1.F1_ESPECIE IN ('CTE','CTR')"
       _oSQL:_sQuery += "	AND SF1.F1_VAFLAG  !='S'"
       _oSQL:_sQuery += " GROUP BY SF1.F1_DOC, SF1.F1_EMISSAO, SZH.ZH_NFSAIDA, SA1.A1_NOME, SA1.A1_MUN, SA1.A1_EST, SF2.F2_PBRUTO"
       _oSQL:_sQuery += " ORDER BY SF1.F1_DOC"
	    
	   //u_showmemo( _oSQL:_sQuery )
	   
	   u_log (_oSQL:_sQuery)
	   if len (_oSQL:Qry2Array (.T., .F.)) > 0
	   
	     _sMsg = _oSQL:Qry2HTM ("CONH DIGIT - Conhecimentos digitados em: " + dtoc(date()-1), _aCols, "", .F.)
		  u_log (_sMsg)
		  
  	     U_ZZUNU ({'007'}, "CONH DIGIT - Conhecimentos digitados no dia anterior", _sMsg, .F., cEmpAnt, cFilAnt, "") // Administrativo da Producao
	   endif

	endif
	
	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
	_sArqLog = _sArqLog2
return .T.
