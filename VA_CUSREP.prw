// Programa...: VA_CUSRE777P
// Autor......: Catia Cardoso
// Data.......: 29/03/2017	
// Descricao..: Atualiza Custo Reposição
//
// Historico de alteracoes:
//
// 03/05/2017 - Catia  - Alterações de escopo - redefinições Diuli
// 04/05/2017 - Catia  - Frete nao estava buscando certo - tem que ser custo e nao valor
// 05/07/2017 - Catia  - bloqueio para nao buscar produtos do tipo PA
// 29/08/2017 - Catia  - novo parametro para nao exibir itens com custo a atualizar = zero
// 26/04/2018 - Catia  - erro de divisao por zero
// 08/05/2018 - Catia  - incluido parametro de ultima compra e alterado o parametro de ultima atualizacao para de/ate
// 12/02/2019 - Catia  - alterado os campos de custo para que tenham 4 decimais
// 04/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 - Arquivo de trabalho
// 27/07/2020 - Robert  - Verificacao de acesso: passa a validar acesso 114 e nao mais 069.
//                      - Inseridas tags para catalogacao de fontes
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #atualizacao
// #Descricao         #Analisa a altera automaticamente o custo de reposicao dos materiais comprados.
// #PalavasChave      #custo_reposicao
// #TabelasPrincipais #SB1
// #Modulos           #EST

// ------------------------------------------------------------------------------------------
#include 'totvs.ch'

User Function VA_CUSREP()
	
	local _aCores  := U_L_CUSREP (.T.)
	//Local cArqTRB  := ""
	//Local cInd1    := ""
	//Local nI       := 0
	Local I        := 0
	Local n        := 0
	Local aStruct  := {}
	Local aHead := {}
	
	cPerg   := "VA_CUSREP"
	
	if ! u_zzuvl ('114', __cUserId, .T.)
		return
	endif
	
	_ValidPerg()
	
    if Pergunte(cPerg,.T.) 
		//Campos que aparecerão na MBrowse, como não é baseado no SX3 deve ser criado.
		AAdd( aHead, { "Produto"             ,{|| TRB->COD}       ,"C", 06 , 0, "" } )
		AAdd( aHead, { "Descrição"           ,{|| TRB->DESCR}      ,"C", 60 , 0, "" } )
		AAdd( aHead, { "Unidade"             ,{|| TRB->UM}        ,"C", 04 , 0, "" } )
		AAdd( aHead, { "Tipo"                ,{|| TRB->TIPO}      ,"C", 02 , 0, "" } )
		AAdd( aHead, { "Grupo"               ,{|| TRB->GRUPO}     ,"C", 04 , 0, "" } )
		AAdd( aHead, { "Bloqueado"           ,{|| TRB->SITUA}     ,"C", 03 , 0, "" } )
		AAdd( aHead, { "Ult.Atualizacao"     ,{|| TRB->ULTATL}    ,"C", 10 , 0, "" } )
		AAdd( aHead, { "Ult.Compra"          ,{|| TRB->COMPRA}    ,"N", 12 , 2, "@E 9,999,999.99" } )
		AAdd( aHead, { "Dt.Ult.Compra"       ,{|| TRB->DUCOMP}    ,"C", 10 , 0, "" } )
		AAdd( aHead, { "Ult.Compra 1"        ,{|| TRB->COMPRA1}   ,"N", 12 , 2, "@E 9,999,999.99" } )
		AAdd( aHead, { "Dt.Ult.Compra1"      ,{|| TRB->DUCOMP1}   ,"C", 10 , 0, "" } )
		AAdd( aHead, { "Ult.Compra 2"        ,{|| TRB->COMPRA2}   ,"N", 12 , 2, "@E 9,999,999.99" } )
		AAdd( aHead, { "Dt.Ult.Compra2"      ,{|| TRB->DUCOMP2}   ,"C", 10 , 0, "" } )
		
		AAdd( aHead, { "Media Ult.Compras"   ,{|| TRB->MEDIA}     ,"N", 12 , 2, "@E 9,999,999.99" } )
		AAdd( aHead, { "Custo Médio"         ,{|| TRB->CUSTMED}   ,"N", 12 , 2, "@E 9,999,999.99" } )
		AAdd( aHead, { "Custo Standard"      ,{|| TRB->CUSTATUAL} ,"N", 12 , 2, "@E 9,999,999.99" } )
		AAdd( aHead, { "Custo a atualizar"   ,{|| TRB->CUSTNEW}   ,"N", 12 , 2, "@E 9,999,999.99" } )
		
		AAdd( aHead, { "Variação"            ,{|| TRB->VARIA}     ,"N", 12 , 2, "@E 9,999,999.99" } )
		AAdd( aHead, { "Manual"              ,{|| TRB->DIGITADO}  ,"C",  1 , 0, "" } )
		
		// define estrutura do arquivo de trabalho	
		AAdd( aStruct, { "COD"       , "C", 06, 0 } )
		AAdd( aStruct, { "DESCR"      , "C", 60, 0 } )
		AAdd( aStruct, { "UM"        , "C", 04, 0 } )
		AAdd( aStruct, { "TIPO"      , "C", 02, 0 } )
		AAdd( aStruct, { "GRUPO"     , "C", 04, 0 } )
		AAdd( aStruct, { "SITUA"     , "C", 03, 0 } )
		AAdd( aStruct, { "ULTATL"    , "C", 10, 0 } )
		AAdd( aStruct, { "COMPRA"    , "N", 12, 2 } )
		AAdd( aStruct, { "DUCOMP"    , "C", 10, 0 } )
		AAdd( aStruct, { "COMPRA1"   , "N", 12, 2 } )
		AAdd( aStruct, { "DUCOMP1"   , "C", 10, 0 } )
		AAdd( aStruct, { "COMPRA2"   , "N", 12, 2 } )
		AAdd( aStruct, { "DUCOMP2"   , "C", 10, 0 } )
		AAdd( aStruct, { "MEDIA"     , "N", 12, 2 } )
		AAdd( aStruct, { "CUSTMED"   , "N", 12, 4 } )
		AAdd( aStruct, { "CUSTNEW"   , "N", 12, 4 } )
		AAdd( aStruct, { "VARIA"     , "N", 12, 2 } )
		AAdd( aStruct, { "CUSTATUAL" , "N", 12, 4 } )
		AAdd( aStruct, { "DIGITADO"  , "C", 01, 0 } )
		
//		// cria arquivo de trabalho
//		cArqTRB := CriaTrab( aStruct, .T. )
//		dbUseArea( .T., __LocalDriver, cArqTRB, "TRB", .F., .F. )
//		cInd1 := Left( cArqTRB, 7 ) + "1"
//		IndRegua( "TRB", cInd1, "DESC", , , "Criando índices...")
//		cInd2 := Left( cArqTRB, 7 ) + "2"
//		IndRegua( "TRB", cInd2, "COD", , , "Criando índices...")
//		cInd3 := Left( cArqTRB, 7 ) + "3"
//		IndRegua( "TRB", cInd3, "VARIA", , , "Criando índices...")
//		
//		dbClearIndex()
//		dbSetIndex( cInd1 + OrdBagExt() )
//		dbSetIndex( cInd2 + OrdBagExt() )
//		dbSetIndex( cInd3 + OrdBagExt() )

		// cria arquivo de trabalho
		_aArqTrb  := {}
		U_ArqTrb ("Cria", "TRB", aStruct, {"DESCR","COD","VARIA"}, @_aArqTrb)	

		// gera arquivo dados - carrega arquivo de trabalho
		_sSQL := "" 
		_sSQL += " SELECT B1_COD"
		_sSQL += "      , B1_DESC"
		_sSQL += "      , B1_UM"
		_sSQL += "      , B1_TIPO"
		_sSQL += "      , B1_GRUPO"
		_sSQL += "      , CASE WHEN B1_MSBLQL = '1' THEN 'SIM' ELSE 'NAO' END"
		_sSQL += "      , B1_CUSTD"
		_sSQL += "      , dbo.VA_DTOC(B1_UCALSTD)"
		_sSQL += "      , (SELECT ROUND(SUM(B2_VFIM1)/SUM(B2_QFIM),2)"
	    _sSQL += "           FROM SB2010 AS SB2"
        _sSQL += "          WHERE SB2.B2_COD    = SB1.B1_COD"
        _sSQL += "            AND SB2.B2_QFIM > 0"
		_sSQL += "            AND SB2.B2_FILIAL = '" + xFilial("SB2") + "'"
		_sSQL += "          GROUP BY SB2.B2_COD )"   
 		_sSQL += "   FROM " + RetSqlname ("SB1") + " AS SB1 "
		_sSQL += "  WHERE D_E_L_E_T_ = ''"
		_sSQL += "	  AND B1_COD     BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
		_sSQL += "    AND B1_TIPO    BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
		_sSQL += "    AND B1_TIPO    != 'PA'"
		_sSQL += "    AND B1_GRUPO   BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
		_sSQL += "    AND B1_UCALSTD BETWEEN '" + dtos(mv_par08)  + "' AND '" + dtos(mv_par09) + "'"
		_sSQL += "    AND B1_UCOM    BETWEEN '" + dtos(mv_par10)  + "' AND '" + dtos(mv_par11) + "'"
		if mv_par07 == 1
			_sSQL += "    AND B1_MSBLQL = '2'"
		endif
		
		//u_showmemo (_sSQL)
		
		aDados := U_Qry2Array(_sSQL)

		if len (aDados) > 0
			for I=1 to len(aDados)
				DbSelectArea("TRB")
		        RecLock("TRB",.T.)
		        	TRB->COD       = aDados[I,1]
		        	TRB->DESCR     = aDados[I,2]
		        	TRB->UM        = aDados[I,3]
		        	TRB->TIPO      = aDados[I,4]
		        	TRB->GRUPO     = aDados[I,5]
		        	TRB->SITUA     = aDados[I,6]
		        	TRB->ULTATL    = aDados[I,8]
		        	TRB->COMPRA    = 0
		        	TRB->DUCOMP    = ''
		        	TRB->COMPRA1   = 0
		        	TRB->DUCOMP1   = ''
		        	TRB->COMPRA2   = 0
		        	TRB->DUCOMP2   = ''
		        	TRB->MEDIA     = 0
		        	TRB->CUSTATUAL = aDados[I,7]
		        	TRB->VARIA     = 0
		        	TRB->DIGITADO  = ""
		        	TRB->CUSTMED   = aDados[I,9]
		        	
			        // busca dados das ultimas compras
			        _sQuery := ''
			        _sQuery += "SELECT TOP 3 SD1.D1_CUSTO/SD1.D1_QUANT, dbo.VA_DTOC(SD1.D1_DTDIGIT), SD1.D1_QUANT, SD1.D1_DOC, SD1.D1_SERIE, SD1.D1_FORNECE"
			        _sQuery += "     , ISNULL(SD1_FRETE.D1_CUSTO/SD1.D1_QUANT,0) 
			        _sQuery += "     , SD1.D1_TOTAL"
  			        _sQuery += "  FROM SD1010 AS SD1"
					_sQuery += " 	INNER JOIN SF4010 AS SF4"
					_sQuery += "		ON (SF4.F4_CODIGO      = SD1.D1_TES"
					_sQuery += "			AND SF4.F4_ESTOQUE = 'S'"
					_sQuery += "			AND SF4.F4_DUPLIC  = 'S' )"
					_sQuery += "	LEFT JOIN SF8010 AS SF8"
					_sQuery += "		ON (SF8.D_E_L_E_T_ = ''" 				
					_sQuery += "			AND SF8.F8_NFORIG  = SD1.D1_DOC"
					_sQuery += "			AND SF8.F8_SERORIG = SD1.D1_SERIE"
					_sQuery += "			AND SF8.F8_FORNECE = SD1.D1_FORNECE"
					_sQuery += "			AND SF8.F8_LOJA    = SD1.D1_LOJA)"
  					_sQuery += "	LEFT JOIN SD1010 AS SD1_FRETE"
					_sQuery += "		ON (SD1_FRETE.D_E_L_E_T_ = ''"
					_sQuery += "			AND SD1_FRETE.D1_FILIAL  = SF8.F8_FILIAL"
					_sQuery += "			AND SD1_FRETE.D1_DOC     = SF8.F8_NFDIFRE"
					_sQuery += "			AND SD1_FRETE.D1_SERIE   = SF8.F8_SEDIFRE"
					_sQuery += "			AND SD1_FRETE.D1_FORNECE = SF8.F8_TRANSP"
					_sQuery += "			AND SD1_FRETE.D1_LOJA    = SF8.F8_LOJTRAN"
					_sQuery += "			AND SD1_FRETE.D1_COD     = SD1.D1_COD)"
 					_sQuery += " WHERE SD1.D_E_L_E_T_ = ''"
   					_sQuery += "   AND SD1.D1_COD     = '" + TRB->COD + "'"
   					_sQuery += "   AND SD1.D1_TIPO    = 'N'"
   					_sQuery += "   AND SD1.D1_QUANT > 0 "
					_sQuery += " ORDER BY SD1.D1_DTDIGIT DESC"
					_aNotasComp := U_Qry2Array(_sQuery)
					
					//u_showmemo(_sQuery)
					
					if len (_aNotasComp) > 0
						_wmedia := 0
						_wvalor := 0
						_wqtde  := 0
						for n = 1 to len (_aNotasComp)
							do case
								case n = 1
			        				TRB->COMPRA = _aNotasComp[n,1] + _aNotasComp[n,7]
			        				TRB->DUCOMP = _aNotasComp[n,2]
			        				_wcompra = _aNotasComp[n,1]
								case n = 2		        				
			        				TRB->COMPRA1 = _aNotasComp[n,1] + _aNotasComp[n,7]
			        				TRB->DUCOMP1 = _aNotasComp[n,2]
								case n = 3		        				
			        				TRB->COMPRA2 = _aNotasComp[n,1] + _aNotasComp[n,7]
			        				TRB->DUCOMP2 = _aNotasComp[n,2]
							endcase
							_wmedia += _aNotasComp[n,1] + _aNotasComp[n,7]
							_wqtde  += _aNotasComp[n,3]
							_wvalor += _aNotasComp[n,8] + _aNotasComp[n,7]		        					
						next
						// grava a media das ultimas 3 compras
						TRB->MEDIA = _wmedia / len(_aNotasComp)	
						// calcula medio de reposicao
						//TRB->CUSTMED = _wvalor / _wqtde 																	
					endif
					
					// conforme parametro seta o novo custo e calcula a variação		        
					do case
						case mv_par12 == 1
							TRB->CUSTNEW = TRB->CUSTMED
						case mv_par12 == 2
							TRB->CUSTNEW = TRB->MEDIA
						case mv_par12 == 3													
							TRB->CUSTNEW = TRB->COMPRA
					endcase
					
					// calcula variação
					TRB->VARIA   = ((TRB->CUSTNEW * 100) / TRB->CUSTATUAL) - 100
					
				MsUnLock()		        
			next
		endif
		
		if mv_par13 == 1
			DbSelectArea("TRB")
			DbGoTOp()	
			do while ! eof()
				reclock ("TRB", .F.)
					if TRB->CUSTNEW == 0
						dbdelete ()
					endif
				msunlock ()
				Dbskip()
			enddo
		endif
		

		Private aRotina   := {}
		private cCadastro := "Atualização Custo Reposição"
		private _sArqLog  := iif (type ("_sArqLog") == "C", _sArqLog, U_Nomelog ())
			
		aadd (aRotina, {"&Pesquisar"           ,"AxPesqui"       , 0, 1})
		aadd (aRotina, {"&Altera Custo Manual" ,"U_L_ALTCUSTNEW" , 0, 2})
		aadd (aRotina, {"&Atualiza Produto"    ,"U_AP_CUSREP"    , 0, 2})
		aadd (aRotina, {"&Detalha Ult.Compras" ,"U_C_CUSREP"     , 0, 2})
		aadd (aRotina, {"&Consulta Estoque"    ,"U_L_CONSEST"    , 0 ,2})
		aadd (aRotina, {"&Visualiza Produto"   ,"U_V_CUSREP"     , 0 ,2})
		aadd (aRotina, {"&Atualiza Todos"      ,"U_AT_CUSREP"    , 0, 2})
		aadd (aRotina, {"&Legenda"             ,"U_L_CUSREP(.F.)", 0 ,5})
		
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
// -------------------------------------------------------------------------------------
// Atualiza custo de reposicao do produto selecionado
user function AP_CUSREP()
	if TRB->CUSTNEW  >= 0
		// grava log de alteração
		_oEvento:= ClsEvent():new ()
		_oEvento:CodEven   = "ALT001"
		_oEvento:Texto	   = "Alterado custo reposição, rotina VA_CUSREP." 
		if TRB->DIGITADO = "S"
			_oEvento:Texto	  += " (Digitado pelo Usuário)"			
		endif
		_oEvento:Texto     += " De " + cvaltochar (TRB->CUSTATUAL) + " para " + cvaltochar (TRB->CUSTNEW)
		_oEvento:Produto   = TRB->COD
		_oEvento:Alias     = "SB1"
		_oEvento:Hist	   = "1"
		_oEvento:Status	   = "4"
		_oEvento:Sub	   = ""
		_oEvento:Prazo	   = 0
		_oEvento:Flag	   = .T.
		_oEvento:Grava ()
		// atualiza cadastro do produtos
		DbSelectArea("SB1")
		DbSetOrder(1)
		if DbSeek(xFilial("SB1")+ TRB->COD,.F.)
			reclock("SB1", .F.)
				SB1->B1_CUSTD    = TRB->CUSTNEW  
				SB1->B1_UCALSTD  = date ()
	    	MsUnLock()
			// atualiza arquivo de trabalho
			reclock ("TRB", .F.)
				TRB->CUSTATUAL  = TRB->CUSTNEW
    			TRB->ULTATL     = dtoc(date ())
    			// recalcula a variação
				TRB->VARIA   = ((TRB->CUSTNEW * 100) / TRB->CUSTATUAL) - 100
    		MsUnLock()
		endif	    	
	endif    	
return     
// -------------------------------------------------------------------------------------
// Atualiza todos os produtos
user function AT_CUSREP()
	_lRet = U_MsgNoYes ("Confirma Atualização de todos os produtos selecionados ?")
	if _lRet = .F.
		return
	endif
	
	DbSelectArea("TRB")
	DbGoTOp()	
	do while ! eof()
		if TRB->CUSTNEW  >= 0
			// grava log de alteração 
			_oEvento:= ClsEvent():new ()
			_oEvento:CodEven   = "ALT001"
			_oEvento:Texto	   = "Alterado custo reposição, rotina VA_CUSREP " 
			if TRB->DIGITADO = "S"
				_oEvento:Texto	  += "Digitado pelo Usuário"			
			endif
			_oEvento:Texto     += " De " + cvaltochar (TRB->CUSTATUAL) + " para " + cvaltochar (TRB->CUSTNEW)
			_oEvento:Produto   = TRB->COD
			_oEvento:Alias     = "SB1"
			_oEvento:Hist	   = "1"
			_oEvento:Status	   = "4"
			_oEvento:Sub	   = ""
			_oEvento:Prazo	   = 0
			_oEvento:Flag	   = .T.
			_oEvento:Grava ()
			// atualiza cadastro do produtos
			DbSelectArea("SB1")
			DbSetOrder(1)
			if DbSeek(xFilial("SB1")+ TRB->COD,.F.)
				reclock("SB1", .F.)
					SB1->B1_CUSTD    = TRB->CUSTNEW  
					SB1->B1_UCALSTD  = date ()
		    	MsUnLock()
				// atualiza arquivo de trabalho
				reclock ("TRB", .F.)
					TRB->CUSTATUAL  = TRB->CUSTNEW
	    			TRB->ULTATL     = dtoc(date ())
	    			// recalcula a variação
					TRB->VARIA   = ((TRB->CUSTNEW * 100) / TRB->CUSTATUAL) - 100
	    		MsUnLock()
			endif
		endif
		Dbskip()
	enddo		    	
return     
// -------------------------------------------------------------------------------------
// Consulta detalhada
user function C_CUSREP()
	// -- vendas
	_sSQL := " "
    _sSQL += " SELECT TOP 10"
	_sSQL += " 		  SD1.D1_DOC, SD1.D1_SERIE, SD1.D1_FORNECE"
	_sSQL += " 		, dbo.VA_DTOC(SD1.D1_DTDIGIT), SD1.D1_COD, SD1.D1_DESCRI"
	_sSQL += " 		, SD1.D1_QUANT, SD1.D1_VUNIT"
  	_sSQL += "		, SD1.D1_VALICM/SD1.D1_QUANT AS VLR_ICMS"
  	_sSQL += "		, SD1.D1_VALIMP5/SD1.D1_QUANT AS VLR_COF"
  	_sSQL += "		, SD1.D1_VALIMP6/SD1.D1_QUANT AS VLR_PIS"
  	_sSQL += "		, SD1.D1_CUSTO/SD1.D1_QUANT  AS CUSTO"
  	_sSQL += "   	, SF8.F8_NFDIFRE, SF8.F8_SEDIFRE, SF8.F8_TRANSP"
  	_sSQL += "   	, ISNULL(SD1_FRETE.D1_TOTAL,0) AS FRETE"
  	_sSQL += "   	, ISNULL(SD1_FRETE.D1_CUSTO,0) AS CUSTO_FRETE"
  	_sSQL += "   	, ISNULL(SD1_FRETE.D1_CUSTO/SD1.D1_QUANT,0)"
  	_sSQL += "   	, (SD1.D1_CUSTO/SD1.D1_QUANT) + ISNULL(SD1_FRETE.D1_CUSTO/ SD1.D1_QUANT,0) AS CUSTO_REPOSICAO" 	
 	_sSQL += "   FROM SD1010 AS SD1"
	_sSQL += " 		INNER JOIN SF4010 AS SF4"
	_sSQL += " 			ON (SF4.F4_CODIGO      = SD1.D1_TES"
	_sSQL += " 				AND SF4.F4_ESTOQUE = 'S'"
	_sSQL += " 				AND SF4.F4_DUPLIC  = 'S' )"
	_sSQL += "   	LEFT JOIN SF8010 AS SF8
	_sSQL += "   		ON (SF8.D_E_L_E_T_ = '' 				
	_sSQL += "   			AND SF8.F8_NFORIG  = SD1.D1_DOC
	_sSQL += "   			AND SF8.F8_SERORIG = SD1.D1_SERIE
	_sSQL += "   			AND SF8.F8_FORNECE = SD1.D1_FORNECE
	_sSQL += "   			AND SF8.F8_LOJA    = SD1.D1_LOJA)
  	_sSQL += "   	LEFT JOIN SD1010 AS SD1_FRETE
	_sSQL += "   		ON (SD1_FRETE.D_E_L_E_T_ = ''
	_sSQL += "   			AND SD1_FRETE.D1_FILIAL  = SF8.F8_FILIAL
	_sSQL += "   			AND SD1_FRETE.D1_DOC     = SF8.F8_NFDIFRE
	_sSQL += "   			AND SD1_FRETE.D1_SERIE   = SF8.F8_SEDIFRE
	_sSQL += "   			AND SD1_FRETE.D1_FORNECE = SF8.F8_TRANSP
	_sSQL += "   			AND SD1_FRETE.D1_LOJA    = SF8.F8_LOJTRAN
	_sSQL += "   			AND SD1_FRETE.D1_COD     = SD1.D1_COD)
 	_sSQL += " WHERE SD1.D_E_L_E_T_ = ''"
   	_sSQL += " 	 AND SD1.D1_TIPO    = 'N'"
   	_sSQL += " 	 AND SD1.D1_COD     = '" + TRB->COD + "'"
   	_sSQL += " 	 AND SD1.D1_QUANT   > 0" 
	_sSQL += " ORDER BY SD1.D1_DTDIGIT DESC" 
    
    //u_showmemo(_sSQL)
    
    _aDados := U_Qry2Array(_sSQL)
    _aCols = {}
    aadd (_aCols, { 1,  "NF Entrada"      , 30,  "@!"})
    aadd (_aCols, { 2,  "Serie"           , 10,  "@!"})
    aadd (_aCols, { 3,  "Fornecedor"      , 30,  "@!"})
    aadd (_aCols, { 4,  "Data"            , 40,  "@D"})
    aadd (_aCols, { 5,  "Produto"         , 30,  "@!"})
    aadd (_aCols, { 6,  "Descricao"       , 30,  "@!"})
    aadd (_aCols, { 7,  "Quantidade"      , 45,  "@E 999,999.99"})
    aadd (_aCols, { 8,  "Vlr Unitario"    , 45,  "@E 999,999.99"})
    aadd (_aCols, { 9,  "Vlr Icms"        , 45,  "@E 999,999.99"})
    aadd (_aCols, {10,  "Vlr Cofins"      , 45,  "@E 999,999.99"})
    aadd (_aCols, {11,  "Vlr Pis"         , 45,  "@E 999,999.99"})
    aadd (_aCols, {12,  "Custo"           , 45,  "@E 999,999.99"})
    aadd (_aCols, {13,  "Conhecimento"    , 30,  "@!"})
    aadd (_aCols, {14,  "Serie"           , 10,  "@!"})
    aadd (_aCols, {15,  "Transportador"   , 30,  "@!"})
    aadd (_aCols, {16,  "Vlr Frete"       , 45,  "@E 999,999.99"})
    aadd (_aCols, {17,  "Custo Frete"     , 45,  "@E 999,999.99"})
    aadd (_aCols, {18,  "Frete p/UN"      , 45,  "@E 999,999.99"})
    aadd (_aCols, {19,  "VLR Repos+Frete" , 45,  "@E 999,999.99"})
    
    U_F3Array (_aDados, "Consulta Ultimas notas Compras + Frete", _aCols, oMainWnd:nClientWidth - 50, NIL, "")
	
return
// -------------------------------------------------------------------------------------
// consulta saldo em estoque
user function L_CONSEST ()
	MaViewSB2 (TRB->COD)
return
// -------------------------------------------------------------------------------------
// visualiza cadastro de produtos
user function V_CUSREP ()
	sb1 -> (dbsetorder (1))
	if sb1 -> (dbseek (xfilial ("SB1") + TRB->COD, .F.))
		A010Visul ("SB1", sb1 -> (recno ()), 2)
	endif	
return
//
// -------------------------------------------------------------------------------------
user function L_ALTCUSTNEW()
	local _lRet := .T.
	// solicita novo valor
	if _lRet
		_sOldCust = TRB->CUSTNEW
		_sNewCust = U_Get ("Custo Reposição", "N", 14, "@E 999,999.9999", "", _sOldCust, .F., '.T.')
		
		if _lRet
			reclock ("TRB", .F.)
				TRB->CUSTNEW  = _sNewCust
				TRB->DIGITADO = "S" 
				// recalcula a variação
				TRB->VARIA   = ((TRB->CUSTNEW * 100) / TRB->CUSTATUAL) - 100
			msunlock ()      
		endif
	endif
return
// -------------------------------------------------------------------------------------
// Mostra legenda
user function L_CUSREP (_lRetCores)
	local _aCores  := {}
	local _aCores2 := {}
	
    aadd (_aCores, {"TRB->CUSTATUAL > 0", 'BR_AZUL'    , 'Produto com Custo Reposição'})
    aadd (_aCores, {"TRB->CUSTATUAL = 0", 'BR_AMARELO' , 'Produto sem Custo Reposição'})
    
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
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Produto de                    ?", "C", 6, 0,  "",   "SB1", {},  ""})
	aadd (_aRegsPerg, {02, "Produto ate                   ?", "C", 6, 0,  "",   "SB1", {},  ""})
	aadd (_aRegsPerg, {03, "Tipo produto inicial          ?", "C", 2, 0,  "",   "02 ", {},  ""})
	aadd (_aRegsPerg, {04, "Tipo produto final            ?", "C", 2, 0,  "",   "02 ", {},  ""})
	aadd (_aRegsPerg, {05, "Grupo produto inicial         ?", "C", 4, 0,  "",   "SBM", {},  ""})
	aadd (_aRegsPerg, {06, "Grupo produto final           ?", "C", 4, 0,  "",   "SBM", {},  ""})
	aadd (_aRegsPerg, {07, "Considera Bloqueados          ?", "N", 1, 0,  "",   "   ", {"Nao","Sim"}, ""})
	aadd (_aRegsPerg, {08, "Data Ultima Atualização de    ?", "D", 8, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {09, "Data Ultima Atualização até   ?", "D", 8, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {10, "Data Ultima Compra de         ?", "D", 8, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {11, "Data Ultima Compra até        ?", "D", 8, 0,  "",   "   ", {},  ""})
	aadd (_aRegsPerg, {12, "Atualizar reposição pela      ?", "N", 1, 0,  "",   "   ", {"Custo Medio","Med.Ult.3.Compras","Ultima Compra"}, ""})
	aadd (_aRegsPerg, {13, "Exibir custo a atualizar zero ?", "N", 1, 0,  "",   "   ", {"Nao","Sim"}, ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return
