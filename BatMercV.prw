// Programa.:  BatMercV
// Autor....:  Claudia Lionço
// Data.....:  06/01/2022
// Descricao:  Verificações referentes ao Mercanet
//             Criado para ser executado via batch.
//
//  #TipoDePrograma    #Batch
//  #Descricao         #Verificações referentes ao Mercanet
//  #PalavasChave      #Mercanet #integracao #verificacoes
//  #TabelasPrincipais #
//  #Modulos 		   #
//
// Historico de alteracoes:
// 04/03/2022 - Sandra  - Alteração do grupo A10 para 134 GLPI 11712
//						  U_ZZUNU ({'A10'}, "Verificações Mercanet - Clientes"
//						  U_ZZUNU ({'A10'}, "Verificações Mercanet - Representantes"
// 11/04/2022 - Claudia - Retirado o CNPJ 18694748000105 da consulta. GLPI: 11899
// 08/11/2022 - Robert  - Passa a usar funcao U_LkServer() para apontar para o banco do Mercanet.
//

// -------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'totvs.ch'

User Function BatMercV()
    local _sLinkSrv := ""

	// Define se deve apontar para o banco de producao ou de homologacao.
	_sLinkSrv = U_LkServer ('MERCANET')
	if empty (_sLinkSrv)
		u_help ("Sem definicao para comunicacao com banco de dados do Mercanet.",, .t.)
	else

		// Verificação de clientes inativos Protheus/Mercanet
		_oBatch:Mensagens += "Verificação de clientes inativos Protheus/Mercanet"
		ClientesInativos()

		RepInativos()
	endif

	u_log ('Mensagens do batch:', _oBatch:Mensagens)
Return
//
// -------------------------------------------------------------------------------
// Verificação de clientes inativos Protheus/Mercanet
Static Function ClientesInativos()

	_aCols = {}

	_aCols = {}
	aadd (_aCols, {'Cod.Protheus'       ,    'left' ,  ''})
	aadd (_aCols, {'Nome Protheus'      ,    'left' ,  ''})
	aadd (_aCols, {'CNPJ/CPF Protheus'  ,    'left' ,  ''})
	aadd (_aCols, {'Situação Protheus'  ,    'left' ,  ''})
	aadd (_aCols, {'Cod.Mercanet'       ,    'left' ,  ''})
	aadd (_aCols, {'Nome Mercanet'      ,    'left' ,  ''})
	aadd (_aCols, {'CNPJ/CPF Mercanet'  ,    'left' ,  ''})
	aadd (_aCols, {'Situação Mercanet'  ,    'left' ,  ''}) 
	
	_oSQL := ClsSQL():New ()  
	_oSQL:_sQuery := "" 		
	_oSQL:_sQuery += " WITH C "
	_oSQL:_sQuery += " AS "
	_oSQL:_sQuery += " (SELECT "
	_oSQL:_sQuery += " 		SA1.R_E_C_N_O_ "
	_oSQL:_sQuery += " 	   ,A1_COD AS COD_PROTHEUS "
	_oSQL:_sQuery += " 	   ,A1_NOME AS NOME_PROTHEUS "
	_oSQL:_sQuery += " 	   ,A1_CGC AS CGC_PROTHEUS "
	_oSQL:_sQuery += " 	   ,A1_MSBLQL AS SITUACAO_PROTHEUS "
	_oSQL:_sQuery += " 	   ,DB_CLI_CODIGO AS COD_MERC "
	_oSQL:_sQuery += " 	   ,DB_CLI_NOME AS NOME_MERC "
	_oSQL:_sQuery += " 	   ,DB_CLI_CGCMF AS CGC_MERC "
	_oSQL:_sQuery += " 	   ,DB_CLI_SITUACAO AS SITUACAO_MERC "
	_oSQL:_sQuery += " 	FROM SA1010 SA1 "
	_oSQL:_sQuery += " 	LEFT JOIN LKSRV_MERCANETPRD.MercanetPRD.dbo.DB_CLIENTE CLI "
	_oSQL:_sQuery += " 		ON CLI.DB_CLI_CGCMF COLLATE Latin1_General_CI_AI = A1_CGC COLLATE Latin1_General_CI_AI "
	_oSQL:_sQuery += " 	WHERE SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 	AND A1_MSBLQL = '1' "
	_oSQL:_sQuery += " 	AND DB_CLI_SITUACAO = 0 "
	_oSQL:_sQuery += " 	UNION ALL "
	_oSQL:_sQuery += " 	SELECT "
	_oSQL:_sQuery += " 		SA1.R_E_C_N_O_ "
	_oSQL:_sQuery += " 	   ,A1_COD AS COD_PROTHEUS "
	_oSQL:_sQuery += " 	   ,A1_NOME AS NOME_PROTHEUS "
	_oSQL:_sQuery += " 	   ,A1_CGC AS CGC_PROTHEUS "
	_oSQL:_sQuery += " 	   ,A1_MSBLQL AS SITUACAO_PROTHEUS "
	_oSQL:_sQuery += " 	   ,DB_CLI_CODIGO AS COD_MERC "
	_oSQL:_sQuery += " 	   ,DB_CLI_NOME AS NOME_MERC "
	_oSQL:_sQuery += " 	   ,DB_CLI_CGCMF AS CGC_MERC "
	_oSQL:_sQuery += " 	   ,DB_CLI_SITUACAO AS SITUACAO_MERC "
	_oSQL:_sQuery += " 	FROM SA1010 SA1 "
	_oSQL:_sQuery += " 	LEFT JOIN LKSRV_MERCANETPRD.MercanetPRD.dbo.DB_CLIENTE CLI "
	_oSQL:_sQuery += " 		ON CLI.DB_CLI_CGCMF COLLATE Latin1_General_CI_AI = A1_CGC COLLATE Latin1_General_CI_AI "
	_oSQL:_sQuery += " 	WHERE SA1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 	AND A1_MSBLQL = '2' "
	_oSQL:_sQuery += " 	AND DB_CLI_SITUACAO = 3) "
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   COD_PROTHEUS "
	_oSQL:_sQuery += "    ,NOME_PROTHEUS "
	_oSQL:_sQuery += "    ,CGC_PROTHEUS "
	_oSQL:_sQuery += "    ,CASE "
	_oSQL:_sQuery += " 			WHEN SITUACAO_PROTHEUS = 1 THEN 'INATIVO' "
	_oSQL:_sQuery += " 		ELSE 'ATIVO' "
	_oSQL:_sQuery += " 	  END AS STATUS_PROTHEUS "
	_oSQL:_sQuery += "    ,COD_MERC "
	_oSQL:_sQuery += "    ,NOME_MERC "
	_oSQL:_sQuery += "    ,CGC_MERC "
	_oSQL:_sQuery += "    ,CASE "
	_oSQL:_sQuery += " 			WHEN SITUACAO_MERC = 3 THEN 'INATIVO' "
	_oSQL:_sQuery += " 		ELSE 'ATIVO' "
	_oSQL:_sQuery += "    END AS STATUS_MERCANET "
	_oSQL:_sQuery += " FROM C "
	_oSQL:_sQuery += " WHERE CGC_PROTHEUS NOT IN ('92685460000119', '97944823587', '00213985000133','18694748000105') "

	u_log (_oSQL:_sQuery)
	if len (_oSQL:Qry2Array (.T., .F.)) > 0

		_sMsg = _oSQL:Qry2HTM ("Clientes com status divergentes. Data de verificacao: " + dtoc(date()-1), _aCols, "", .F.)
		u_log (_sMsg)
		U_ZZUNU ({'134'}, "Verificações Mercanet - Clientes", _sMsg, .F., cEmpAnt, cFilAnt, "") // CLientes
	endif
Return
//
// -------------------------------------------------------------------------------
// Verificação de clientes inativos Protheus/Mercanet
Static Function RepInativos()

	_aCols = {}

	_aCols = {}
	aadd (_aCols, {'Cod.Protheus'       ,    'left' ,  ''})
	aadd (_aCols, {'Nome Protheus'      ,    'left' ,  ''})
	aadd (_aCols, {'Situação Protheus'  ,    'left' ,  ''})
	aadd (_aCols, {'Cod.Mercanet'       ,    'left' ,  ''})
	aadd (_aCols, {'Nome Mercanet'      ,    'left' ,  ''})
	aadd (_aCols, {'Situação Mercanet'  ,    'left' ,  ''}) 
	
	_oSQL := ClsSQL():New ()  
	_oSQL:_sQuery := "" 		
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   A3_COD "
	_oSQL:_sQuery += "    ,SA3.A3_NOME "
	_oSQL:_sQuery += "    ,A3_ATIVO "
	_oSQL:_sQuery += "    ,DB_TBREP_CODIGO "
	_oSQL:_sQuery += "    ,DB_TBREP_NOME "
	_oSQL:_sQuery += "    ,DB_TBREP_SIT_VENDA  "  
	_oSQL:_sQuery += " FROM SA3010 SA3 "
	_oSQL:_sQuery += " LEFT JOIN LKSRV_MERCANETPRD.MercanetPRD.dbo.DB_TB_REPRES REP "
	_oSQL:_sQuery += " 	ON DB_TBREP_CODORIG = A3_COD "
	_oSQL:_sQuery += " WHERE SA3.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND SA3.A3_ATIVO = 'S'  "
	_oSQL:_sQuery += " AND DB_TBREP_SIT_VENDA = 2  "
	_oSQL:_sQuery += " AND A3_COD NOT IN ('000001') "
	_oSQL:_sQuery += " UNION ALL "
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   A3_COD "
	_oSQL:_sQuery += "    ,SA3.A3_NOME "
	_oSQL:_sQuery += "    ,A3_ATIVO "
	_oSQL:_sQuery += "    ,DB_TBREP_CODIGO "
	_oSQL:_sQuery += "    ,DB_TBREP_NOME "
	_oSQL:_sQuery += "    ,DB_TBREP_SIT_VENDA "
	_oSQL:_sQuery += " FROM SA3010 SA3 "
	_oSQL:_sQuery += " LEFT JOIN LKSRV_MERCANETPRD.MercanetPRD.dbo.DB_TB_REPRES REP "
	_oSQL:_sQuery += " 	ON DB_TBREP_CODORIG = A3_COD "
	_oSQL:_sQuery += " WHERE SA3.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND SA3.A3_ATIVO = 'N'  "
	_oSQL:_sQuery += " AND DB_TBREP_SIT_VENDA = 1  "
	_oSQL:_sQuery += " AND A3_COD NOT IN ('000001') "
	_oSQL:_sQuery += " ORDER BY A3_COD "

	u_log (_oSQL:_sQuery)
	if len (_oSQL:Qry2Array (.T., .F.)) > 0

		_sMsg = _oSQL:Qry2HTM ("Representantes com status divergentes. Data de verificacao: " + dtoc(date()-1), _aCols, "", .F.)
		u_log (_sMsg)
		U_ZZUNU ({'134'}, "Verificações Mercanet - Representantes", _sMsg, .F., cEmpAnt, cFilAnt, "") // CLientes
	endif
Return

