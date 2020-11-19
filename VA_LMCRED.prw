// Programa...: VA_LMCRED
// Autor......: Catia Cardoso
// Data.......: 18/08/2015
// Descricao..: Manutencao de Limites de Credito
//
// Historico de alteracoes:
// 05/10/2015 - Catia - opcao para visualizar o cadastro do cliente 
// 19/02/2016 - Catia - parametro de selecionar Fisica/Juridica
// 21/01/2017 - Catia - alteracao para que desconsidere clientes que compra a vista - condicao 097
// 16/02/2018 - Catia - criado parametro maior ou menor para data de compra
// 04/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25
//
// ---------------------------------------------------------------------------------------------------
#include 'totvs.ch'

User Function VA_LMCRED()
	local _aCores   := U_L_LMCRED (.T.)
	//Local cArqTRB   := ""
	//Local cInd1     := ""
	//Local nI        := 0
	Local aStruct   := {}
	Local aHead 	:= {}
	Local I			:= 0
	
	cPerg   := "VA_LMCRED"
	
	if ! u_zzuvl ('036', __cUserId, .T.)
		return
	endif
	
	_ValidPerg()
	
    if Pergunte(cPerg,.T.) 

		//Campos que aparecerão na MBrowse, como não é baseado no SX3 deve ser criado.
		AAdd( aHead, { "Cliente"         ,{|| TRB->CODIGO}  ,"C", 06 , 0, "" } )
		AAdd( aHead, { "Loja"            ,{|| TRB->LOJA}    ,"C", 02 , 0, "" } )
		AAdd( aHead, { "Nome_Cli"        ,{|| TRB->NOME}    ,"C", 30 , 0, "" } )
		AAdd( aHead, { "Bloqueado"       ,{|| TRB->BLOQ}    ,"C", 04 , 0, "" } )
		AAdd( aHead, { "Risco"           ,{|| TRB->RISCO}   ,"C", 01 , 0, "" } )
		AAdd( aHead, { "Limite Atual"    ,{|| TRB->LC}      ,"N", 12 , 2, "@E 9,999,999.99" } )
		AAdd( aHead, { "Vencimento"      ,{|| TRB->VENCLC}  ,"C", 10 , 0, "" } )
		AAdd( aHead, { "MED Atraso"      ,{|| TRB->METR}    ,"N", 03 , 0, "" } )
		AAdd( aHead, { "Limite Calculado",{|| TRB->LC_CALC} ,"N", 12 , 2, "@E 9,999,999.99" } )
		AAdd( aHead, { "Maior Saldo"     ,{|| TRB->MSALDO}  ,"N", 12 , 2, "@E 9,999,999.99" } )
		AAdd( aHead, { "PRI Compra"      ,{|| TRB->PRICOM}  ,"C", 10 , 0, "" } )
		AAdd( aHead, { "ULT Compra"      ,{|| TRB->ULTCOM}  ,"C", 10 , 0, "" } )
		AAdd( aHead, { "Nro Compras"     ,{|| TRB->NROCOM}  ,"N", 04 , 0, "" } )
		AAdd( aHead, { "Maior Compra"    ,{|| TRB->MCOMPRA} ,"N", 12 , 2, "@E 9,999,999.99" } )
		AAdd( aHead, { "Pessoa"          ,{|| TRB->PESSOA}  ,"C", 20 , 0, "" } )
		
		// define estrutura do arquivo de trabalho	
		AAdd( aStruct, { "CODIGO"  , "C", 06, 0 } )
		AAdd( aStruct, { "LOJA"    , "C", 02, 0 } )
		AAdd( aStruct, { "NOME"    , "C", 30, 0 } )
		AAdd( aStruct, { "BLOQ"    , "C", 04, 0 } )
		AAdd( aStruct, { "ULTCOM"  , "C", 10, 0 } )
		AAdd( aStruct, { "PRICOM"  , "C", 10, 0 } )
		AAdd( aStruct, { "METR"    , "N", 04, 0 } )
		AAdd( aStruct, { "MSALDO"  , "N", 12, 2 } )
		AAdd( aStruct, { "NROCOM"  , "N", 04, 0 } )
		AAdd( aStruct, { "MCOMPRA" , "N", 12, 2 } )
		AAdd( aStruct, { "RISCO"   , "C", 01, 0 } )
		AAdd( aStruct, { "LC"      , "N", 12, 2 } )
		AAdd( aStruct, { "VENCLC"  , "C", 10, 0 } )
		AAdd( aStruct, { "LC_CALC" , "N", 12, 2 } )
		AAdd( aStruct, { "PESSOA"  , "C", 20, 0 } )
		
//		// cria arquivo de trabalho
//		cArqTRB := CriaTrab( aStruct, .T. )
//		dbUseArea( .T., __LocalDriver, cArqTRB, "TRB", .F., .F. )
//		cInd1 := Left( cArqTRB, 7 ) + "1"
//		IndRegua( "TRB", cInd1, "CODIGO + LOJA", , , "Criando índices...")
//		cInd2 := Left( cArqTRB, 7 ) + "2"
//		IndRegua( "TRB", cInd2, "NOME", , , "Criando índices...")
//		
//		dbClearIndex()
//		dbSetIndex( cInd1 + OrdBagExt() )
//		dbSetIndex( cInd2 + OrdBagExt() )

		// cria arquivo de trabalho
		_aArqTrb  := {}
		U_ArqTrb ("Cria", "TRB", aStruct, {"CODIGO + LOJA","NOME"}, @_aArqTrb)	
		
		// gera arquivo dados - carrega arquivo de trabalho
		_sSQL := "" 
		_sSQL += " SELECT A1_COD"						// --- 1
		_sSQL += "      , A1_LOJA"						// --- 2
		_sSQL += "      , A1_NOME"						// --- 3
		_sSQL += " 	    , CASE WHEN A1_MSBLQL='1'  THEN 'Sim'"
		_sSQL += " 	           WHEN A1_MSBLQL='2'  THEN 'Nao' END" // --- 4
		_sSQL += "      , dbo.VA_DTOC(A1_ULTCOM)"		// --- 5
		_sSQL += "      , dbo.VA_DTOC(A1_PRICOM)"		// --- 6
		_sSQL += "      , A1_METR"						// --- 7
		_sSQL += "      , ROUND(A1_MSALDO,2)"			// --- 8
		_sSQL += "      , A1_NROCOM"					// --- 9
		_sSQL += "      , ROUND(A1_MCOMPRA,2)"			// --- 10
		_sSQL += "      , A1_RISCO"						// --- 11
		_sSQL += "      , A1_LC"						// --- 12
		_sSQL += "      , dbo.VA_DTOC(A1_VENCLC)"		// --- 13
		_sSQL += "      , 0 AS LC_CALC"					// --- 14
		_sSQL += "      , CASE WHEN A1_PESSOA ='J' THEN 'Juridica'" // --- 15
		_sSQL += "             WHEN A1_PESSOA ='F' THEN 'Fisica' END"
		_sSQL += "   FROM " + RetSqlname ("SA1") + " AS SA1 "
		_sSQL += "  WHERE D_E_L_E_T_ = ''"
		_sSQL += "    AND A1_COD != '000000'" // desprezar cliente de consumidor final
		_sSQL += "    AND A1_COD != '000001'" // desprezar cliente de cunsumidor final
		_sSQL += "	  AND A1_COD BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
		_sSQL += "    AND A1_RISCO != 'A'"
		if mv_par06 == 1
			_sSQL += "    AND A1_ULTCOM > '" + dtos(mv_par05) + "'"

		else
			_sSQL += "    AND A1_ULTCOM < '" + dtos(mv_par05) + "'"							
		endif
		_sSQL += "	  AND A1_CGC NOT LIKE '%88612486%'" // desprezar as transferencias
		// desconsidera os clientes em que a ultima venda foi a vista
		_sSQL += "	  AND EXISTS (SELECT SF2.F2_CLIENTE"
		_sSQL += "	  			    FROM SF2010 AS SF2"
		_sSQL += "	  			   WHERE SF2.D_E_L_E_T_ = ''"
		_sSQL += "	  			     AND SF2.F2_CLIENTE = SA1.A1_COD"
		_sSQL += "	  		         AND SF2.F2_EMISSAO = SA1.A1_ULTCOM"
		_sSQL += "	  		         AND SF2.F2_COND   != '097'"
		_sSQL += "	  		         AND SF2.F2_LOJA    = SA1.A1_LOJA)"
		
		if mv_par03 == 2
			_sSQL += "    AND A1_MSBLQL = '2'"
		endif
		
		if mv_par08 != 1
			if mv_par08 == 2	
				_sSQL += "    AND A1_PESSOA = 'J'"
			else
				_sSQL += "    AND A1_PESSOA = 'F'"	
			endif				
		endif
		
		if mv_par04 != 3
			if mv_par04 = 1
				_sSQL += "    AND A1_RISCO = 'D'"
			else
				_sSQL += "    AND A1_RISCO = 'E'"
			endif				
		endif
		
		//u_showmemo (_sSQL)
		
		aDados := U_Qry2Array(_sSQL)

		if len (aDados) > 0
			for I=1 to len(aDados)
				DbSelectArea("TRB")
		        RecLock("TRB",.T.)
		        	TRB->CODIGO  = aDados[I,1]
		        	TRB->LOJA    = aDados[I,2]
		        	TRB->NOME    = aDados[I,3]
		        	TRB->BLOQ    = aDados[I,4]
		        	TRB->ULTCOM  = aDados[I,5]
		        	TRB->PRICOM  = aDados[I,6]
		        	TRB->METR    = aDados[I,7]
		        	TRB->MSALDO  = aDados[I,8]
		        	TRB->NROCOM  = aDados[I,9]
		        	TRB->MCOMPRA = aDados[I,10]
		        	TRB->RISCO   = aDados[I,11]
		        	TRB->LC      = aDados[I,12]
		        	TRB->VENCLC  = aDados[I,13]
		        	TRB->LC_CALC = aDados[I,14]
		        	TRB->PESSOA  = aDados[I,15]
		        MsUnLock()
				if mv_par07 == 1
					U_R_LMCRED(2)	
				endif		        
			next
		endif

		Private aRotina   := {}
		private cCadastro := "Manutenção Limites de Crédito de Clientes"
		private _sArqLog  := iif (type ("_sArqLog") == "C", _sArqLog, U_Nomelog ())
			
		aadd (aRotina, {"&Pesquisar"             ,"AxPesqui"       , 0, 1})
		aadd (aRotina, {"&Recalcula Limite"      ,"U_R_LMCRED(1)"  , 0, 2})
		aadd (aRotina, {"&Atualiza Cliente"      ,"U_A_LMCRED"     , 0, 2})
		aadd (aRotina, {"&Atualiza Recalculados" ,"U_AR_LMCRED"    , 0, 2})
		aadd (aRotina, {"&Posicao Detalhada"     ,"U_C_LMCRED"     , 0, 2})
		aadd (aRotina, {"&Posicao do Cliente"    ,"U_P_LMCRED"     , 0 ,5})
		aadd (aRotina, {"&Visualiza Cadastro"    ,"U_V_LMCRED"     , 0 ,5})
		aadd (aRotina, {"&Legenda"               ,"U_L_LMCRED(.F.)", 0 ,5})
		
		Private cDelFunc := ".T."
		private _sArqLog := U_NomeLog ()
		u_logId ()
		
		dbSelectArea("TRB")
		dbSetOrder(1)
		    
		///mBrowse(,,,,cString,,,,,2, _aCores)		    	
		mBrowse(,,,,"TRB",aHead,,,,,_aCores)
		
		TRB->(dbCloseArea())
		u_arqtrb ("FechaTodos",,,, @_aArqTrb)
	endif		
Return
// ---------------------------------------------------------------------------------------------------
// posicao do cliente
user function P_LMCRED()
	// posicioina o SA1 no cliente do browse
	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial()+ TRB->CODIGO + TRB->LOJA)
	// chama função padrao da posicao de cliente
	a450F4Con()
	DbSelectArea("TRB")
return
// ---------------------------------------------------------------------------------------------------
// recalcula limite
user function R_LMCRED(_wmanual)  // 1= No browse, 2= Ja trazendo os limites recalculados
	_wvendas     := 0
	_wdevolucoes :=	0
		
	_sSQL := " "
    _sSQL += " SELECT SUM(D2_TOTAL) AS TOTAL_PEDIDO"
	_sSQL += "   FROM " + RetSQLName ("SD2") + " AS SD2 "
	_sSQL += " 	INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
	_sSQL += " 		ON (SF4.D_E_L_E_T_ = ''"
	_sSQL += " 			AND SF4.F4_CODIGO = SD2.D2_TES"
	_sSQL += " 			AND SF4.F4_MARGEM = '1')"
	_sSQL += "  WHERE SD2.D_E_L_E_T_  = ''"
	_sSQL += "    AND SD2.D2_FILIAL   = '" + xfilial ("SD2") + "'"
	_sSQL += "    AND SD2.D2_SERIE    = '10'" 
	_sSQL += "    AND SD2.D2_EMISSAO >= '" + dtos(date()-365) + "'"
	_sSQL += "    AND SD2.D2_CLIENTE  = '" + TRB->CODIGO + "'"
	_sSQL += "    AND SD2.D2_LOJA     = '" + TRB->LOJA + "'"
	_sSQL += " GROUP BY D2_FILIAL, D2_CLIENTE, D2_LOJA"
	
	_wvendas := U_Qry2Array(_sSQL)
	if len(_wvendas) > 0
		_wvendas := _wvendas[1,1]
		// busca devolucoes para deduzir do total da venda
		_sSQL := " "
		_sSQL += "    SELECT SUM(D1_TOTAL)"
  		_sSQL += "      FROM " + RetSQLName ("SD1") + " AS SD1 "
		_sSQL += "    		INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
		_sSQL += "    				ON (SF4.D_E_L_E_T_ = ''"
		_sSQL += "    					AND SF4.F4_CODIGO = SD1.D1_TES"
		_sSQL += "    					AND SF4.F4_MARGEM = '2')"
 		_sSQL += "    WHERE SD1.D_E_L_E_T_  = ''"
   		_sSQL += "    	AND SD1.D1_FILIAL   = '" + xfilial ("SD2") + "'"
   		_sSQL += "    	AND SD1.D1_DTDIGIT >= '" + dtos(date()-365) + "'"
   		_sSQL += "    	AND SD1.D1_FORNECE  = '" + TRB->CODIGO + "'"
   		_sSQL += "    	AND SD1.D1_LOJA     = '" + TRB->LOJA + "'"
		_sSQL += "    GROUP BY D1_FILIAL, D1_FORNECE, D1_LOJA"
		
		_wdevolucoes := U_Qry2Array(_sSQL)
		if len(_wdevolucoes) > 0
			_wdevolucoes := _wdevolucoes[1,1]
		else			
			_wdevolucoes := 0 
		endif
		
		wlimite := _wvendas - _wdevolucoes
		if wlimite > 0
			do case
				case TRB->METR > 7
					wlimite = wlimite*.70
				case TRB->METR > 10
			 		wlimite = wlimite*.50
			 	otherwise	
					wlimite = TRB->MSALDO			 				 	
			endcase
			reclock("TRB", .F.)
				TRB->LC_CALC = CEILING(wlimite)
    		MsUnLock()
		endif
	else
		if _wmanual = 1
			msgalert("Cliente sem compra nos ultimos 12 meses. Atualizando Cadastro para Risco 'E'")
			// atualiza cadastro do cliente
	    	DbSelectArea("SA1")
			DbSetOrder(1)
			DbSeek(xFilial()+ TRB->CODIGO + TRB->LOJA)
			If Found()
				reclock("SA1", .F.)
					SA1->A1_RISCO  = 'E'
	    			SA1->A1_LC     = 0
	    			SA1->A1_VENCLC = ctod('')
	    		MsUnLock()
			endif
		endif			
	endif  	
return     
// ---------------------------------------------------------------------------------------------------
// Atualiza cadastro de clientes
user function A_LMCRED()
	if TRB->LC_CALC > 0
		_wano := substr(dtos(dDataBase),1,4)
		_wvenc = _wano + '1231'
	    // atualiza cadastro do cliente
	    DbSelectArea("SA1")
		DbSetOrder(1)
		DbSeek(xFilial()+ TRB->CODIGO + TRB->LOJA)
		If Found()
			reclock("SA1", .F.)
				SA1->A1_VENCLC = stod(_wvenc)
				SA1->A1_RISCO  = 'D'
	    		SA1->A1_LC     = TRB->LC_CALC
	    	MsUnLock()
			// atualiza arquivo de trabalho
			DbSelectArea("TRB")
			DbSetOrder(1)
			DbSeek(TRB->CODIGO + TRB->LOJA)
			reclock("TRB", .F.)
	    		TRB->LC     = TRB->LC_CALC
	    		TRB->VENCLC = DTOC(STOD(_wvenc))
	    	MsUnLock()
		endif	    	
	else
		msgalert("Limite não recalculado")
	endif    	
return     
// ---------------------------------------------------------------------------------------------------
// Atualiza todos os clientes com limite recalculado
user function AR_LMCRED()
	
	DbSelectArea("TRB")
	DbGoTOp()	
	do while ! eof()
		if TRB->LC_CALC > 0
			_wano := substr(dtos(dDataBase),1,4)
			_wvenc = _wano + '1231'
	    	// atualiza cadastro do cliente
	    	DbSelectArea("SA1")
			DbSetOrder(1)
			DbSeek(xFilial()+ TRB->CODIGO + TRB->LOJA)
			If Found()
				reclock("SA1", .F.)
					SA1->A1_VENCLC = stod(_wvenc)
					SA1->A1_RISCO  = 'D'
	    			SA1->A1_LC     = TRB->LC_CALC
	    		MsUnLock()
				// atualiza arquivo de trabalho
				DbSelectArea("TRB")
				DbSetOrder(1)
				DbSeek(TRB->CODIGO + TRB->LOJA)
				reclock("TRB", .F.)
	    			TRB->LC      = TRB->LC_CALC
	    			TRB->VENCLC  = DTOC(STOD(_wvenc))
	    			TRB->LC_CALC = 0
	    		MsUnLock()
			endif	    	
		endif
		Dbskip()
	enddo		    	
return     
// ---------------------------------------------------------------------------------------------------
// Consulta detalhada
user function C_LMCRED()
	// -- vendas
	_sSQL := " "
    _sSQL += " SELECT 'VENDA'       		  AS TIPO"
    _sSQL += "      , D2_CLIENTE    		  AS CLIENTE"
    _sSQL += "      , D2_LOJA       		  AS LOJA" 
    _sSQL += "      , A1_NOME       		  AS NOME"
    _sSQL += "      , dbo.VA_DTOC(D2_EMISSAO) AS DATA"
    _sSQL += "      , D2_DOC        		  AS NOTA"
    _sSQL += "      , D2_SERIE      		  AS SERIE"
    _sSQL += "      , SUM(D2_TOTAL) 		  AS VLR_NF"
	_sSQL += "   FROM " + RetSQLName ("SD2") + " AS SD2 "
	_sSQL += " 	INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
	_sSQL += " 		ON (SF4.D_E_L_E_T_ = ''"
	_sSQL += " 			AND SF4.F4_CODIGO = SD2.D2_TES"
	_sSQL += " 			AND SF4.F4_MARGEM = '1')"
	_sSQL += " 	INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
	_sSQL += " 		ON (SA1.D_E_L_E_T_ = ''"
	_sSQL += " 			AND SA1.A1_COD  = SD2.D2_CLIENTE
	_sSQL += " 			AND SA1.A1_LOJA = SD2.D2_LOJA)"
	_sSQL += "  WHERE SD2.D_E_L_E_T_  = ''"
	_sSQL += "    AND SD2.D2_FILIAL   = '" + xfilial ("SD2") + "'"
	_sSQL += "    AND SD2.D2_SERIE    = '10'" 
	_sSQL += "    AND SD2.D2_EMISSAO >= '" + dtos(date()-365) + "'"
	_sSQL += "    AND SD2.D2_CLIENTE  = '" + TRB->CODIGO + "'"
	_sSQL += "    AND SD2.D2_LOJA     = '" + TRB->LOJA + "'"
	_sSQL += " GROUP BY D2_FILIAL, D2_CLIENTE, D2_LOJA, A1_NOME, D2_EMISSAO, D2_DOC, D2_SERIE"
	_sSQL += " UNION ALL"
	// -- devolucoes
	_sSQL += " SELECT 'DEV'         		  AS TIPO"
    _sSQL += "      , D1_FORNECE    		  AS CLIENTE"
    _sSQL += "      , D1_LOJA       		  AS LOJA" 
    _sSQL += "      , A1_NOME       		  AS NOME"
    _sSQL += "      , dbo.VA_DTOC(D1_DTDIGIT) AS DATA"
    _sSQL += "      , D1_DOC        		  AS NOTA"
    _sSQL += "      , D1_SERIE      		  AS SERIE"
    _sSQL += "      , SUM(D1_TOTAL) 		  AS VLR_NF"
  	_sSQL += "   FROM " + RetSQLName ("SD1") + " AS SD1 "
	_sSQL += " 		INNER JOIN " + RetSQLName ("SF4") + " AS SF4 "
	_sSQL += " 				ON (SF4.D_E_L_E_T_ = ''"
	_sSQL += " 					AND SF4.F4_CODIGO = SD1.D1_TES"
	_sSQL += " 					AND SF4.F4_MARGEM = '2')"
	_sSQL += " 		INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
	_sSQL += " 				ON (SA1.D_E_L_E_T_ = ''"
	_sSQL += " 					AND SA1.A1_COD  = SD1.D1_FORNECE"
	_sSQL += " 					AND SA1.A1_LOJA = SD1.D1_LOJA)"
	_sSQL += "    WHERE SD1.D_E_L_E_T_  = ''"
   	_sSQL += "    	AND SD1.D1_FILIAL   = '" + xfilial ("SD2") + "'"
   	_sSQL += "    	AND SD1.D1_DTDIGIT >= '" + dtos(date()-365) + "'"
   	_sSQL += "    	AND SD1.D1_FORNECE  = '" + TRB->CODIGO + "'"
   	_sSQL += "    	AND SD1.D1_LOJA     = '" + TRB->LOJA + "'"
	_sSQL += "    GROUP BY D1_FILIAL, D1_FORNECE, D1_LOJA,  D1_DTDIGIT, A1_NOME, D1_DOC, D1_SERIE"
	_sSQL += "    ORDER BY NOTA DESC"
	
	_aDados := U_Qry2Array(_sSQL)
    _aCols = {}
    aadd (_aCols, {1,  "Tipo"        , 30,  "@!"})
    aadd (_aCols, {2,  "Cli/Forn"    , 30,  "@!"})
    aadd (_aCols, {3,  "Loja"        , 10,  "@!"})
    aadd (_aCols, {4,  "Razão Social", 140,  "@!"})
    aadd (_aCols, {5,  "Data"        , 40,  "@D"})
    aadd (_aCols, {6,  "Nota"        , 40,  "@!"})
    aadd (_aCols, {7,  "Serie"       , 20,  "@!"})
    aadd (_aCols, {8,  "Total"       , 45,  "@E 999,999.99"})
    
    U_F3Array (_aDados, "Consulta Vendas e Devoluções do Cliente", _aCols, oMainWnd:nClientWidth - 50, NIL, "")
return
// ---------------------------------------------------------------------------------------------------
user function V_LMCRED()
	// posiciona o SA1 e chama função visualizar
	DbSelectArea("SA1")
	DbSetOrder(1)
	DbSeek(xFilial()+ TRB->CODIGO + TRB->LOJA)
	A030Visual('SA1',1,2)
return	
// ---------------------------------------------------------------------------------------------------
// Mostra legenda
user function L_LMCRED (_lRetCores)
	local _aCores   := {}
	local _aCores2  := {}
	local _i		:= 0
	
    aadd (_aCores, {"TRB->LC > 0 ", 'BR_AZUL'    , 'Limite já definido'})
    aadd (_aCores, {"TRB->LC = 0 ", 'BR_AMARELO' , 'Limite não definido'})
    aadd (_aCores, {"TRB->LC > 0 .and. TRB->VENCLC < dtos(dDatabase()", 'BR_LARANJA' , 'Limite Vencido'})
    
	if ! _lRetCores
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 2], _aCores [_i, 3]})
		next
		BrwLegenda (cCadastro, "Legenda", _aCores2)
	else
		for _i = 1 to len (_aCores)
			aadd (_aCores2, {_aCores [_i, 1], _aCores [_i, 2]})
		next
		return _aCores
	endif
return
// ---------------------------------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Cliente de             ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {02, "Cliente ate            ?", "C", 6, 0,  "",   "SA1", {},  ""})
	aadd (_aRegsPerg, {03, "Considera Bloqueados   ?", "N", 1, 0,  "",   "   ", {"Sim", "Nao"}, ""})
	aadd (_aRegsPerg, {04, "Risco                  ?", "N", 1, 0,  "",   "   ", {"D","E","Ambos"},   ""})
	aadd (_aRegsPerg, {05, "Ultima Compra          ?", "D", 8, 0,  "",   "   ", {},""})
	aadd (_aRegsPerg, {06, "Ultima Compra          ?", "N", 1, 0,  "",   "   ", {"Maior ou igual","Menor ou igual"},""})
	aadd (_aRegsPerg, {07, "Recalcula intervalo    ?", "N", 1, 0,  "",   "   ", {"Sim", "Nao"}, ""})
	aadd (_aRegsPerg, {08, "Tipo Cliente           ?", "N", 1, 0,  "",   "   ", {"Ambos","Jurídica","Física"},   ""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
