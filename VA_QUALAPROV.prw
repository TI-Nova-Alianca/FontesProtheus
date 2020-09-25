// Programa...: VA_QUALAPROV
// Autor......: Catia Cardoso
// Data.......: 16/05/2018	
// Descricao..: Atualiza STATUS da ade de produto x fornecedor
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Alteracao
// #Descricao         #Atualiza STATUS da ade de produto x fornecedor
// #PalavasChave      #produto_X_fornecedor #status
// #TabelasPrincipais #SB1 #SA5 
// #Modulos           #COM
//
// Historico de alteracoes:
// 17/08/2020 - Cláudia - Ajuste CriaTrab, conforme solicitação da versao 25 protheus. GLPI: 7339
//
// -----------------------------------------------------------------------------------------------
#include 'totvs.ch'

User Function VA_QUALAPROV()

	Local _aCores  := U_L_QUALAPROV (.T.)
	Local cArqTRB  := ""
	Local cInd1    := ""
	Local nI       := 0
	Local aStruct  := {}
	Local aHead    := {}
	Local I		   := 0
	Local _aArqTrb := {}
	
	cPerg   := "VA_QUALAPROV"
	
	_ValidPerg()
	
    if Pergunte(cPerg,.T.) 

		//Campos que aparecerão na MBrowse, como não é baseado no SX3 deve ser criado.
		AAdd( aHead, { "Produto"             ,{|| TRB->COD}       ,"C", 06 , 0, "" } )
		AAdd( aHead, { "Descrição"           ,{|| TRB->DESCRI}      ,"C", 60 , 0, "" } )
		AAdd( aHead, { "Unidade"             ,{|| TRB->UM}        ,"C", 04 , 0, "" } )
		AAdd( aHead, { "Tipo"                ,{|| TRB->TIPO}      ,"C", 02 , 0, "" } )
		AAdd( aHead, { "Grupo"               ,{|| TRB->GRUPO}     ,"C", 04 , 0, "" } )
		AAdd( aHead, { "Fornece"             ,{|| TRB->FORNECE}   ,"C", 06 , 0, "" } )
		AAdd( aHead, { "Loja"                ,{|| TRB->LOJA}   	  ,"C", 02 , 0, "" } )
		AAdd( aHead, { "Nome"                ,{|| TRB->NOME}      ,"C", 40 , 0, "" } )
		AAdd( aHead, { "Status"              ,{|| TRB->STATUS}    ,"C", 01 , 0, "" } )
		
		// define estrutura do arquivo de trabalho	
		AAdd( aStruct, { "COD"       , "C", 06, 0 } )
		AAdd( aStruct, { "DESCRI"    , "C", 60, 0 } )
		AAdd( aStruct, { "UM"        , "C", 04, 0 } )
		AAdd( aStruct, { "TIPO"      , "C", 02, 0 } )
		AAdd( aStruct, { "GRUPO"     , "C", 04, 0 } )
		AAdd( aStruct, { "FORNECE"   , "C", 06, 0 } )
		AAdd( aStruct, { "LOJA"      , "C", 02, 0 } )
		AAdd( aStruct, { "NOME"      , "C", 40, 0 } )
		AAdd( aStruct, { "STATUS"    , "C", 01, 0 } )
		
		U_ArqTrb ("Cria", "TRB", aStruct, {"DESCRI","COD"}, @_aArqTrb)
		
//		// cria arquivo de trabalho
//		cArqTRB := CriaTrab( aStruct, .T. )
//		dbUseArea( .T., __LocalDriver, cArqTRB, "TRB", .F., .F. )
//		cInd1 := Left( cArqTRB, 7 ) + "1"
//		IndRegua( "TRB", cInd1, "DESC", , , "Criando índices...")
//		cInd2 := Left( cArqTRB, 7 ) + "2"
//		IndRegua( "TRB", cInd2, "COD", , , "Criando índices...")
//		
//		dbClearIndex()
//		dbSetIndex( cInd1 + OrdBagExt() )
//		dbSetIndex( cInd2 + OrdBagExt() )

		// gera arquivo dados - carrega arquivo de trabalho
		_sSQL := "" 
		_sSQL += " SELECT SB1.B1_COD"
     	_sSQL += " 	    , SB1.B1_DESC"
     	_sSQL += " 		, SB1.B1_UM"
     	_sSQL += " 		, SB1.B1_TIPO"
	 	_sSQL += " 		, SB1.B1_GRUPO"
	 	_sSQL += " 		, SA5.A5_FORNECE"
	 	_sSQL += " 		, SA2.A2_LOJA"
	 	_sSQL += " 		, SA2.A2_NOME"
	 	_sSQL += " 		, SA5.A5_VAAPROV"
 		_sSQL += "   FROM SA5010 AS SA5"
		_sSQL += " 		INNER JOIN SB1010 AS SB1"
		_sSQL += " 			ON (SB1.D_E_L_E_T_ = ''"
		_sSQL += "    			AND B1_TIPO  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
		_sSQL += "    			AND B1_GRUPO BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
		_sSQL += " 				AND SB1.B1_COD = SA5.A5_PRODUTO)"
		_sSQL += " 		INNER JOIN SA2010 AS SA2"
		_sSQL += " 			ON (SA2.D_E_L_E_T_ = ''"
		_sSQL += " 				AND SA2.A2_COD = SA5.A5_FORNECE"
		_sSQL += " 				AND SA2.A2_LOJA = SA5.A5_LOJA)"
		_sSQL += " WHERE SA5.D_E_L_E_T_ = ''"
  		_sSQL += "   AND SA5.A5_FORNECE BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
		_sSQL += "	 AND SA5.A5_PRODUTO BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
		//u_showmemo (_sSQL)
		aDados := U_Qry2Array(_sSQL)
		if len (aDados) > 0
			for I=1 to len(aDados)
				DbSelectArea("TRB")
		        RecLock("TRB",.T.)
		        	TRB->COD       = aDados[I,1]
		        	TRB->DESCRI    = aDados[I,2]
		        	TRB->UM        = aDados[I,3]
		        	TRB->TIPO      = aDados[I,4]
		        	TRB->GRUPO     = aDados[I,5]
		        	TRB->FORNECE   = aDados[I,6]
		        	TRB->LOJA      = aDados[I,7]
		        	TRB->NOME      = aDados[I,8]
		        	TRB->STATUS    = aDados[I,9]
				MsUnLock()		        
			next
		endif
		
		Private aRotina   := {}
		private cCadastro := "Qualidadade - Status Produto"
		private _sArqLog  := iif (type ("_sArqLog") == "C", _sArqLog, U_Nomelog ())
			
		aadd (aRotina, {"&Pesquisar"          ,"AxPesqui"          , 0, 1})
		aadd (aRotina, {"&Altera Produto"     ,"U_AP_SA5"          , 0, 2})
		aadd (aRotina, {"&Altera Todos"       ,"U_AT_SA5"          , 0, 2})
		aadd (aRotina, {"&Consulta Histórico" ,"U_CONSULT()"       , 0, 2})
		aadd (aRotina, {"&Visualiza Cadastro" ,"U_VISUAL_SB1"      , 0, 2})
		aadd (aRotina, {"&Legenda"            ,"U_L_QUALAPROV(.F.)", 0 ,5})
		
		Private cDelFunc := ".T."
		private _sArqLog := U_NomeLog ()Þ
		u_logId ()
		
		dbSelectArea("TRB")
		dbSetOrder(1)
		    
		mBrowse(,,,,"TRB",aHead,,,,,_aCores)
		
		TRB->(dbCloseArea())
		u_arqtrb ("FechaTodos",,,, @_aArqTrb)       
	endif		
Return
//
// ------------------------------------------------------------------------------------
// Atualiza status da qualidade
user function AP_SA5()
	local _lRet := .T.
	
	if ! u_zzuvl ('022', __cUserId, .T.)
		return
	endif
	
	// solicita novo status
	_sOldStatus = TRB->STATUS
	_sNewStatus = U_Get ("Status Qualidade - Item: "+ TRB->COD, "C", 1, "@!", "", _sOldStatus, .F., '.T.')
	if _sNewStatus = '' .or. ! _sNewStatus $ 'ARE' 
		u_help ("Status Invalido. Usar <A>Aprovado <R>Reprovado <E>Em Teste")
		_lret = .F.
		return
	endif
	
	if _lret .and. _sOldStatus <> _sNewStatus
		// grava log de alteração
		_oEvento:= ClsEvent():new ()
		_oEvento:CodEven   = "ALT001"
		_oEvento:Texto	   = "Alterado STATUS Qualidade rotina VA_QUALAPROV." 
		_oEvento:Texto     += " De " + _sOldStatus + " para " + _sNewStatus 
		_oEvento:Produto   = TRB->COD
		_oEvento:Alias     = "SA5"
		_oEvento:Hist	   = "1"
		_oEvento:Status	   = "4"
		_oEvento:Sub	   = ""
		_oEvento:Prazo	   = 0
		_oEvento:Flag	   = .T.
		_oEvento:Grava ()
		// atualiza cadastro do produtos
		DbSelectArea("SA5")
		DbSetOrder(1)
		if DbSeek(xFilial("SA5")+ TRB->FORNECE + TRB->LOJA + TRB->COD,.F.)
			reclock("SA5", .F.)
				SA5->A5_VAAPROV  = _sNewStatus  
	    	MsUnLock()
	    	// buscar recno
	    	_wrecno = 1
    		_sSQL := ""
    		_sSQL += " SELECT MAX(R_E_C_N_O_)"
    		_sSQL += "   FROM ZBB010"
    		aDados := U_Qry2Array(_sSQL)
    		if len (aDados) > 0
    			_wrecno = aDados[1,1] + 1
    		endif
	    	// atualiza tabela de historico de alteracoes
			reclock ("ZBB", .T.)
				ZBB_FILIAL  = xfilial ("TRB")
				ZBB_FORNEC	= TRB->FORNECE
				ZBB_LOJA	= TRB->LOJA
				ZBB_COD		= TRB->COD
				ZBB_DATA	= DTOS(date())
				ZBB_HORA	= time()
				ZBB_USER	= cusername
				ZBB_SATUAL	= _sNewStatus
				ZBB_SANTES	= _sOldStatus
				R_E_C_N_O_  = _wrecno 
    		MsUnLock()
    		reclock ("TRB", .F.)
				TRB->STATUS  = _sNewStatus
			msunlock ()      
		endif	    	
	endif  
return	  	
//
// ------------------------------------------------------------------------------------
// Atualiza todos os produtos
user function AT_SA5()
	_lRet = .T.
	
	if ! u_zzuvl ('022', __cUserId, .T.)
		return
	endif
	
	_sOldStatus = TRB->STATUS
	_sNewStatus = U_Get ("Novo Status Qualidade para TODOS os itens selecionados", "C", 1, "@!", "", _sOldStatus, .F., '.T.')
	if _sNewStatus = '' .or. ! _sNewStatus $ 'ARE'
		u_help ("Status Invalido. Usar <A>Aprovado <R>Reprovado <E>Em Teste")
		_lret = .F.
		return
	endif
	
	_lRet = U_MsgNoYes ("Confirma Atualização de TODOS os produtos selecionados ?")
	if _lRet = .F.
		return
	endif
	
	if _lRet
		DbSelectArea("TRB")
		DbGoTOp()	
		do while ! eof()
			// atualiza SA5
			// grava log de alteração
			_oEvento:= ClsEvent():new ()
			_oEvento:CodEven   = "ALT001"
			_oEvento:Texto	   = "Alterado STATUS Qualidade rotina VA_QUALAPROV." 
			_oEvento:Texto     += " De " + _sOldStatus + " para " + _sNewStatus 
			_oEvento:Produto   = TRB->COD
			_oEvento:Alias     = "SA5"
			_oEvento:Hist	   = "1"
			_oEvento:Status	   = "4"
			_oEvento:Sub	   = ""
			_oEvento:Prazo	   = 0
			_oEvento:Flag	   = .T.
			_oEvento:Grava ()
			// atualiza cadastro do produtos
			DbSelectArea("SA5")
			DbSetOrder(1)
			if DbSeek(xFilial("SA5")+ TRB->FORNECE + TRB->LOJA + TRB->COD,.F.)
				reclock("SA5", .F.)
					SA5->A5_VAAPROV  = _sNewStatus  
		    	MsUnLock()
		    	// buscar recno
		    	_wrecno = 1
	    		_sSQL := ""
	    		_sSQL += " SELECT MAX(R_E_C_N_O_)"
	    		_sSQL += "   FROM ZBB010"
	    		aDados := U_Qry2Array(_sSQL)
	    		if len (aDados) > 0
	    			_wrecno = aDados[1,1] + 1
	    		endif
		    	// atualiza tabela de historico de alteracoes
				reclock ("ZBB", .T.)
					ZBB_FILIAL  = xfilial ("TRB")
					ZBB_FORNEC	= TRB->FORNECE
					ZBB_LOJA	= TRB->LOJA
					ZBB_COD		= TRB->COD
					ZBB_DATA	= DTOS(date())
					ZBB_HORA	= time()
					ZBB_USER	= cusername
					ZBB_SATUAL  = _sNewStatus
					ZBB_SANTES  = _sOldStatus
					R_E_C_N_O_  = _wrecno 
	    		MsUnLock()
	    		DbSelectArea("TRB")
	    		reclock ("TRB", .F.)
					TRB->STATUS  = _sNewStatus
				msunlock ()
			endif			
			Dbskip()
		enddo
	endif				    		
return     
//
// ------------------------------------------------------------------------------------
// Consulta
user function CONSULT ()
	_sQuery := ""
	_sQuery += " SELECT ZBB.ZBB_COD"
	_sQuery += "      , SB1.B1_DESC"
	_sQuery += "      , ZBB.ZBB_FORNEC, ZBB.ZBB_LOJA"
	_sQuery += "      , SA2.A2_NOME"
	_sQuery += "	  , dbo.VA_DTOC(ZBB.ZBB_DATA) AS DATA"
	_sQuery += "	  , ZBB.ZBB_HORA, ZBB.ZBB_USER"
	_sQuery += "      , CASE WHEN ZBB_SANTES='A' THEN 'Aprovado'"
	_sQuery += "             WHEN ZBB_SANTES='R' THEN 'Reprovado'"
	_sQuery += "             WHEN ZBB_SANTES='E' THEN 'Em Teste'"
	_sQuery += "        END"
	_sQuery += "      , CASE WHEN ZBB_SATUAL='A' THEN 'Aprovado'"
	_sQuery += "             WHEN ZBB_SATUAL='R' THEN 'Reprovado'"
	_sQuery += "             WHEN ZBB_SATUAL='E' THEN 'Em Teste'"
	_sQuery += "        END" 
	_sQuery += "   FROM ZBB010 AS ZBB"
	_sQuery += "   		INNER JOIN SA2010 AS SA2"
	_sQuery += "   			ON (SA2.D_E_L_E_T_ = ''"
	_sQuery += "   				AND SA2.A2_COD = ZBB.ZBB_FORNEC"
	_sQuery += "   				AND SA2.A2_LOJA = ZBB.ZBB_LOJA)"
	_sQuery += "   		INNER JOIN SB1010 AS SB1"
	_sQuery += "   			ON (SB1.D_E_L_E_T_ = ''"
	_sQuery += "   				AND SB1.B1_COD = ZBB.ZBB_COD)"
 	_sQuery += "  WHERE ZBB.D_E_L_E_T_ = ''"
   	_sQuery += "    AND ZBB.ZBB_COD    = '" + TRB->COD + "'" 
   	_sQuery += "    AND ZBB.ZBB_FORNEC = '" + TRB->FORNECE + "'"
   	_sQuery += "    AND ZBB.ZBB_LOJA   = '" + TRB->LOJA + "'"
	_sQuery += " ORDER BY ZBB.ZBB_FORNEC, ZBB.ZBB_LOJA, ZBB.ZBB_COD, ZBB.ZBB_DATA DESC, ZBB.ZBB_HORA"
	
	//u_showmemo (_sQuery)
	
	_aDados := U_Qry2Array(_sQuery)
	if len(_aDados) > 0 
		_aCols = {}
	
    	aadd (_aCols, { 1, "Produto"       	   , 50,  "@!"})
    	aadd (_aCols, { 2, "Descricao"         ,100,  "@!"})
    	aadd (_aCols, { 3, "Fornecedor"   	   , 30,  "@!"})
    	aadd (_aCols, { 4, "Loja"       	   , 10,  "@!"})
    	aadd (_aCols, { 5, "Nome"       	   ,100,  "@!"})
    	aadd (_aCols, { 6, "Data"       	   , 30,  "@D"})
    	aadd (_aCols, { 7, "Hora"   	   	   , 30,  "@!"})
    	aadd (_aCols, { 8, "Alterado por"      , 50,  "@!"})
		aadd (_aCols, { 9, "Alterado de"       , 50,  "@!"})
    	aadd (_aCols, {10, "Alterado para"     , 50,  "@!"})
        
		U_F3Array (_aDados, "Consulta Historio de Alterações - Status Qualidade", _aCols, oMainWnd:nClientWidth - 400, oMainWnd:nClientHeight -200 , "", "", .T., 'C' )
	else
		msgalert("Não foram encontrados dados para consulta")
	endif
return
//
// ------------------------------------------------------------------------------------
// visualiza cadastro de produtos
user function VISUAL_SB1 ()
	sb1 -> (dbsetorder (1))
	if sb1 -> (dbseek (xfilial ("SB1") + TRB->COD, .F.))
		A010Visul ("SB1", sb1 -> (recno ()), 2)
	endif	
return
//
// ------------------------------------------------------------------------------------
// Mostra legenda
user function L_QUALAPROV (_lRetCores)
	local _aCores   := {}
	local _aCores2  := {}
	local _i		:= 0
	
	aadd (_aCores, {"TRB->STATUS ='A'", 'BR_VERDE'    , 'Aprovado'})
    aadd (_aCores, {"TRB->STATUS ='E'", 'BR_AZUL'     , 'Em Teste'})
    aadd (_aCores, {"TRB->STATUS ='R'", 'BR_VERMELHO' , 'Reprovado'})
    
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
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Produto de               ?", "C", 6, 0,  "",   "SB1", {},  ""})
	aadd (_aRegsPerg, {02, "Produto ate              ?", "C", 6, 0,  "",   "SB1", {},  ""})
	aadd (_aRegsPerg, {03, "Tipo produto inicial     ?", "C", 2, 0,  "",   "02 ", {},  ""})
	aadd (_aRegsPerg, {04, "Tipo produto final       ?", "C", 2, 0,  "",   "02 ", {},  ""})
	aadd (_aRegsPerg, {05, "Grupo produto inicial    ?", "C", 4, 0,  "",   "SBM", {},  ""})
	aadd (_aRegsPerg, {06, "Grupo produto final      ?", "C", 4, 0,  "",   "SBM", {},  ""})
	aadd (_aRegsPerg, {07, "Fornecedor inicial       ?", "C", 6, 0,  "",   "SA2", {},  ""})
	aadd (_aRegsPerg, {08, "Fornecedor final         ?", "C", 6, 0,  "",   "SA2", {},  ""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
