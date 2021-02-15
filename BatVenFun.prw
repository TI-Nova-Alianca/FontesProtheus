// Programa..: BatVenFun
// Autor.....: Cláudia Lionço
// Data......: 22/07/2020
// Descricao.: Verificações de vendas para funcionários enviados para RH. GLPI:8132 
//
// #TipoDePrograma    #Batch
// #PalavasChave      #venda_funcionario #venda #RH #compras_funcionarios
// #TabelasPrincipais #SL1 #SL4 #ZAD
// #Modulos 		  #LOJ #RH
//
// Historico de alteracoes:
// 15/02/2021 - Alterada datas para primeira e ultima do mes. GLPI: 9410
//
// --------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function BatVenFun()
	Local _aAreaAnt := U_ML_SRArea ()
	Local _oSQL     := NIL
	Local _sMsg     := ""
	Local _sArqLog2 := iif (type ("_sArqLog") == "C", _sArqLog, "")
	Local _dDtIni   := FirstDate(Date())
	Local _dDtFin   := Date()
	
	_sArqLog := U_NomeLog (.t., .f.)
	u_logId()
	u_logIni()

	//u_help(DTOS(_dDtIni) + " - "+ DTOS(_dDtFin))

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH C"
	_oSQL:_sQuery += " AS"
	_oSQL:_sQuery += " (SELECT
	_oSQL:_sQuery += " 		ZAD.ZAD_NOME AS NOME"
	_oSQL:_sQuery += " 	   ,SL1.L1_VACGC AS CPF"
	_oSQL:_sQuery += " 	   ,SL4.L4_VALOR AS VALOR"
	_oSQL:_sQuery += " 	FROM SL1010 AS SL1"
	_oSQL:_sQuery += " 	INNER JOIN SL4010 AS SL4"
	_oSQL:_sQuery += " 		ON (SL4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND SL4.L4_FILIAL = SL1.L1_FILIAL"
	_oSQL:_sQuery += " 		AND SL4.L4_NUM = SL1.L1_NUM"
	_oSQL:_sQuery += " 		AND SL4.L4_FORMA = 'CO'"
	_oSQL:_sQuery += " 		AND SL4.L4_ADMINIS LIKE '%900%')"
	_oSQL:_sQuery += " 	INNER JOIN ZAD010 AS ZAD"
	_oSQL:_sQuery += " 		ON (ZAD.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND ZAD.ZAD_CPF = L1_CGCCLI"
	_oSQL:_sQuery += " 		AND ZAD.ZAD_SITUA IN ('1', '2')" // -- busca so os ativos e afastados
	_oSQL:_sQuery += " 		AND ZAD.ZAD_FFILIA BETWEEN '' AND 'zzzz'"
	_oSQL:_sQuery += " 		)"
	_oSQL:_sQuery += " 	WHERE SL1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND SL1.L1_FILIAL BETWEEN '' AND 'zzzz'"
	_oSQL:_sQuery += " 	AND SL1.L1_EMISNF BETWEEN '" + DTOS(_dDtIni) + "' AND '"+ DTOS(_dDtFin) + "'"
	_oSQL:_sQuery += " 	AND SL1.L1_DOC != ''"
	_oSQL:_sQuery += " 	UNION ALL"
	_oSQL:_sQuery += " 	SELECT DISTINCT"
	_oSQL:_sQuery += " 		ZAD.ZAD_NOME AS NOME"
	_oSQL:_sQuery += " 	   ,SL1.L1_VACGC AS CPF"
	_oSQL:_sQuery += " 	   ,(SL4.L4_VALOR * -1) AS VALOR"
	_oSQL:_sQuery += " 	FROM SD1010 SD1"
	_oSQL:_sQuery += " 	RIGHT JOIN SL1010 SL1"
	_oSQL:_sQuery += " 		ON (SL1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND SD1.D1_NFORI = SL1.L1_DOC"
	_oSQL:_sQuery += " 		AND SD1.D1_SERIORI = SL1.L1_SERIE"
	_oSQL:_sQuery += " 		AND SD1.D1_FORNECE = SL1.L1_CLIENTE"
	_oSQL:_sQuery += " 		AND SD1.D1_LOJA = SL1.L1_LOJA"
	_oSQL:_sQuery += " 		)"
	_oSQL:_sQuery += " 	INNER JOIN SL4010 AS SL4"
	_oSQL:_sQuery += " 		ON (SL4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND SL4.L4_FILIAL = SL1.L1_FILIAL"
	_oSQL:_sQuery += " 		AND SL4.L4_NUM = SL1.L1_NUM"
	_oSQL:_sQuery += " 		AND SL4.L4_FORMA = 'CO'"
	_oSQL:_sQuery += " 		AND SL4.L4_ADMINIS LIKE '%900%')"
	_oSQL:_sQuery += " 	INNER JOIN ZAD010 AS ZAD"
	_oSQL:_sQuery += " 		ON (ZAD.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 		AND ZAD.ZAD_CPF = L1_CGCCLI"
	_oSQL:_sQuery += " 		AND ZAD.ZAD_SITUA IN ('1', '2')"
	_oSQL:_sQuery += " 		AND ZAD.ZAD_FFILIA BETWEEN '' AND 'zzzz'"
	_oSQL:_sQuery += " 		)"
	_oSQL:_sQuery += " 	WHERE SD1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 	AND SD1.D1_FILIAL BETWEEN '' AND 'zzzz'"
	_oSQL:_sQuery += " 	AND SD1.D1_EMISSAO BETWEEN '" + DTOS(_dDtIni) + "' AND '"+ DTOS(_dDtFin) + "')"
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += " 	   NOME"
	_oSQL:_sQuery += "    ,CPF"
	_oSQL:_sQuery += "    ,CAST(SUM(VALOR) as VARCHAR)  AS TOTAL
	_oSQL:_sQuery += " FROM C"
	_oSQL:_sQuery += " GROUP BY NOME"
	_oSQL:_sQuery += " 		,CPF"
	_oSQL:_sQuery += " HAVING SUM(VALOR) > 300"
	_oSQL:_sQuery += " ORDER BY NOME	"
	
	u_log (_oSQL:_sQuery)
	
	If Len (_oSQL:Qry2Array (.F., .F.)) > 0
		_aCols := {}
		
	   AADD (_aCols, {'FUNCIONÁRIO' ,    'left' ,  ''})
	   AADD (_aCols, {'CPF'    		,    'left' ,  ''})
	   AADD (_aCols, {'VALOR TOTAL' ,    'right',  ''})
												
		
		_sMsg = _oSQL:Qry2HTM ("Compras de Funcionários (Acima R$ 300,00) - Período de " + DTOC(_dDtIni) + " até " + DTOC(_dDtFin), _aCols, "", .F.,.T.)
		u_log (_sMsg)
		U_ZZUNU ({'110'}, 'Notificação - Compra de funcionários. Período de ' + DTOC(_dDtIni) + ' até ' + DTOC(_dDtFin) , _sMsg, .F.)
	EndIf


	U_ML_SRArea (_aAreaAnt)
	_sArqLog = _sArqLog2
Return 
