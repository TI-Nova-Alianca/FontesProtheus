#include 'protheus.ch'
#include 'parmtype.ch'

User Function claudia ()
	//u_help("Nada para executar")

	//u_help("associados")
	//U_BatFunAssoc()
	//u_help("Executa Margens")
	//U_BATMARDAT()

	//u_help("Tela")
	//TelaTeste()

	//u_help("envMargem")
	//u_envMargem()
	//U_HELP("GNRE")
	//_AtuGNRE()

	//u_help("isento")
	//_AtuISENTO()
	//u_help("CIELO")
	//Cielo()
	//u_help("ALMOX1")
	//Almox1()
	//u_help("ALMOX2")
	//Almox2()
	// u_help('Solicitante')
	// Solicitante()
	//u_help("Coordenadores")
	//Coordenadores()
	//u_help("Teste de baixa")
	//BaixaAut()

	// Atualiza clientes inativos
	//u_help("Atualiza clientes ativos")
	//ClientesInativos()

	// Atualiza representantes inativos
	u_help("Representantes Inativos")
	RepInativos()
Return
//
// Atualiza representantes inativos
Static Function RepInativos()
	Local _aDados := {}
	Local _x      := 0

	_oSQL := ClsSQL():New ()  
	_oSQL:_sQuery := "" 		
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 		SA3.R_E_C_N_O_ "
	_oSQL:_sQuery += " FROM SA3010 SA3 "
	_oSQL:_sQuery += " LEFT JOIN LKSRV_MERCANETPRD.MercanetPRD.dbo.DB_TB_REPRES REP "
	_oSQL:_sQuery += " 		ON DB_TBREP_CODORIG = A3_COD "
	_oSQL:_sQuery += " WHERE SA3.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND SA3.A3_ATIVO = 'N' "  // BLOQUEADOS
	_oSQL:_sQuery += " AND DB_TBREP_SIT_VENDA<>2 " // 1 = ATIVO/ 2 = INATIVO
	_oSQL:_sQuery += " ORDER BY A3_COD "

	_aDados := aclone (_oSQL:Qry2Array ())

	For _x := 1 to Len(_aDados)
		U_AtuMerc ("SA3", _aDados[_x,1])
	Next

Return
//
// Atualiza clientes inativos protheus-> Mercanet
Static Function ClientesInativos()
	Local _aDados := {}
	Local _x      := 0

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
	_oSQL:_sQuery += " 	AND A1_MSBLQL <> '1') "
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	* "
	_oSQL:_sQuery += " FROM C "
	_oSQL:_sQuery += " WHERE SITUACAO_MERC = 3 "
	_oSQL:_sQuery += " ORDER BY COD_PROTHEUS "
	_aDados := aclone (_oSQL:Qry2Array ())

	For _x := 1 to Len(_aDados)
		U_AtuMerc ("SA1", _aDados[_x,1])
	Next

Return

// Static Function TelaTeste()
// 		_aBoletos := {}
// 		aadd (_aBoletos, {.T.,"teste","3333","44444"})


// 		_aColunas = {}
// 		aadd (_aColunas, {2, "Serie",  45, "@!"})
// 		aadd (_aColunas, {3, "Numero", 65, "@!"})
// 		aadd (_aColunas, {4, "Banco",  45, "@!"})
		
// 		// Markbrowse para o usuario selecionar os boletos
// 		U_MBArray (@_aBoletos, "Selecione boletos a imprimir", _aColunas, 1, 600, 400)
		
// Return
// //
// // --------------------------------------------------------------------------
// // Grava retorno da margem contribuicao
// User Function EnvMargem ()
// 	local _wFilial 	 := "01"
// 	local _wPedido	 := "279710"
// 	local _wCliente  := "017532"
// 	local _wLoja 	 := "01"
// 	local _aNaWeb    := {}
// 	local _sErros    := ""
// 	local _XmlRet    := ""
// 	local _x         := 0
// 	//local _y         := 0

// 	u_logIni ()

// 	If empty(_sErros)
// 		sa1 -> (dbsetorder(1)) // A1_FILIAL + A1_COD + A1_LOJA
// 		DbSelectArea("SA1")
// 		If ! dbseek(xFilial("SA1") + _wCliente + _wLoja, .F.)
// 			_sErros := " Cliente " + _wCliente +"/"+ _wLoja +" não encontrado. Verifique!"
// 		Else
// 			_wNomeCli := sa1->a1_nome
// 		EndIf
// 	EndIf
// 	If empty(_sErros)
// 		sc5 -> (dbsetorder(3)) // C5_FILIAL + C5_CLIENTE + C5_LOJACLI + C5_NUM
// 		DbSelectArea("SC5")
		
// 		If dbseek(_wFilial + _wCliente + _wLoja + _wPedido, .F.)
// 			_oSQL := ClsSQL():New ()  
// 			_oSQL:_sQuery := "" 		
// 			_oSQL:_sQuery += " SELECT "
// 			_oSQL:_sQuery += " 	 	DESCRITIVO "
// 			_oSQL:_sQuery += " FROM VA_VEVENTOS "
// 			_oSQL:_sQuery += " WHERE CODEVENTO  = 'SC5009' "
// 			_oSQL:_sQuery += " AND FILIAL       = '" + _wFilial  + "' "
// 			_oSQL:_sQuery += " AND CLIENTE      = '" + _wCliente + "' "
// 			_oSQL:_sQuery += " AND LOJA_CLIENTE = '" + _wLoja    + "' "
// 			_oSQL:_sQuery += " AND PEDVENDA     = '" + _wPedido  + "' "
// 			_oSQL:_sQuery += " ORDER BY HORA, DESCRITIVO" 
// 			_aItem := aclone (_oSQL:Qry2Array ())

// 			_XmlRet := "<BuscaItensPedBloq>"
// 			For _x:=1 to Len(_aItem)
// 				_aNaWeb := STRTOKARR(_aItem[_x,1],"|")

// 				_XmlRet += "<BuscaItensPedBloqItem>"
// 				_XmlRet += "<Filial>"        + _wFilial 	  + "</Filial>"
// 				_XmlRet += "<Pedido>"		 + _wPedido       + "</Pedido>"
// 				_XmlRet += "<Cliente>" 		 + _wCliente 	  + "</Cliente>" 
// 				_XmlRet += "<Nome>"			 + _wNomeCli	  + "</Nome>"   
// 				_XmlRet += "<Loja>"			 + _wLoja 		  + "</Loja>"	 
// 				_XmlRet += "<Produto>" 		 + alltrim(_aNaWeb[ 2]) + "</Produto>"
// 				_XmlRet += "<Quantidade>" 	 + alltrim(_aNaWeb[ 3]) + "</Quantidade>"
// 				_XmlRet += "<PrcVenda>" 	 + alltrim(_aNaWeb[ 4]) + "</PrcVenda>"
// 				_XmlRet += "<PrcCusto>" 	 + alltrim(_aNaWeb[ 5]) + "</PrcCusto>"
// 				_XmlRet += "<Comissao>" 	 + alltrim(_aNaWeb[ 6]) + "</Comissao>"
// 				_XmlRet += "<ICMS>" 		 + alltrim(_aNaWeb[ 7]) + "</ICMS>"
// 				_XmlRet += "<PISCOF>" 		 + alltrim(_aNaWeb[ 8]) + "</PISCOF>"
// 				_XmlRet += "<Rapel>" 		 + alltrim(_aNaWeb[ 9]) + "</Rapel>"
// 				_XmlRet += "<Frete>" 		 + alltrim(_aNaWeb[10]) + "</Frete>"
// 				_XmlRet += "<Financeiro>" 	 + alltrim(_aNaWeb[11]) + "</Financeiro>"
// 				_XmlRet += "<MargemVlr>" 	 + alltrim(_aNaWeb[12]) + "</MargemVlr>"
// 				_XmlRet += "<MargemPercent>" + alltrim(_aNaWeb[13]) + "</MargemPercent>"
// 				_XmlRet += "</BuscaItensPedBloqItem>"
// 			Next
// 			_XmlRet += "</BuscaItensPedBloq>"
// 			u_log2 ('info', _XmlRet)
// 		Else
// 			_sErros := "Pedido " + _wPedido + " não encontrado para o cliente "	+ _wCliente +"/"+ _wLoja 		
// 		EndIf		
// 	EndIf
// 	 nHandle := FCreate("c:\temp\logXML.txt")
// 	FWrite(nHandle,_XmlRet )
// 	FClose(nHandle)

// 	u_logFim ()
// Return
// //
// // ------------------------------------------------------------------
// Static Function _AtuGNRE()
// 	Local _x    := 0
// 	Local _aSB5 := {}

// 	_oSQL := ClsSQL():New ()
// 	_oSQL:_sQuery := ""
// 	_oSQL:_sQuery += "	SELECT "
// 	_oSQL:_sQuery += "		 B1_COD AS PRODUTO "
// 	_oSQL:_sQuery += "		,B1_GRTRIB AS GRTRIB "
// 	_oSQL:_sQuery += "		,B1_TIPO AS TIPO "
// 	_oSQL:_sQuery += "		,CASE "
// 	_oSQL:_sQuery += "				WHEN B1_GRTRIB IN ('005', '006', '007') THEN 68 "
// 	_oSQL:_sQuery += "				WHEN B1_GRTRIB IN ('001', '002', '003', '004', '008', '009', '010', '011', '012', '013', '014', '015', '016', '017') THEN 81 "
// 	_oSQL:_sQuery += "				ELSE " 
// 	_oSQL:_sQuery += "				'' "
// 	_oSQL:_sQuery += "			END AS CODGNRE "
// 	_oSQL:_sQuery += "		FROM SB1010 SB1 "
// 	_oSQL:_sQuery += "		LEFT JOIN SB5010 SB5 "
// 	_oSQL:_sQuery += "			ON SB5.D_E_L_E_T_ = '' "
// 	_oSQL:_sQuery += "				AND SB5.B5_COD = B1_COD "
// 	_oSQL:_sQuery += "		WHERE SB1.D_E_L_E_T_ = '' "
// 	_oSQL:_sQuery += "		AND B1_TIPO IN ('PA', 'MR') "
// 	_oSQL:Log ()
// 	_aSB5:= _oSQL:Qry2Array ()
	
	
//  	nHandle := FCreate("c:\temp\GNRE_SB5.txt")
// 	DbSelectArea("SB5")
// 	DbSetOrder(1)
//  	For _x := 1 to Len(_aSB5)
//  		if DbSeek(xFilial("SB5") + _aSB5[_x, 1])	
// 			reclock("SB5", .F.)
// 				SB5->B5_CODGNRE := _aSB5[_x, 4]
// 			MsUnLock()
// 			_sTexto := "Produto: "+ _aSB5[_x, 1] + " Cod GNRE: " + str(_aSB5[_x, 4]) + Chr(13) + Chr(10)
// 			FWrite(nHandle,_sTexto )
// 		endif
//  	Next
// 	FClose(nHandle)
// Return


//
// ------------------------------------------------------------------
// Static Function Almox1()
// 	// Ajusta cadastro produtos em lote

// 	sb1 -> (dbsetorder (1))
// 	sb1 -> (dbgotop ())

// 	do while !sb1 -> (eof ())
// 		if sb1 -> b1_tipo = 'MM'
// 			regtomemory ("SB1", .F., .F.)
			
// 			// Grava evento de alteracao
// 			_oEvento := ClsEvent():new ()
// 			_oEvento:AltCadast ("SB1", m->b1_cod, sb1 -> (recno ()), 'GLPI:10102 - AJUSTA LOCPAD DE 60 PARA 02', .F.)

// 			reclock ("SB1", .f.)
// 				sb1 -> B1_LOCPAD = '02'
// 			msunlock ()
// 		endif
// 		sb1 -> (dbskip ())
// 	enddo
// Return
//
// ------------------------------------------------------------------
// Static Function Almox2()
// 	local _x := 0

// 	U_help("Exec Almox 2 14/07/2021")
// 	_oSQL := ClsSQL():New ()
// 	_oSQL:_sQuery := ""
// 	_oSQL:_sQuery += " SELECT "
// 	_oSQL:_sQuery += " 	  SB1.B1_COD "
// 	_oSQL:_sQuery += " FROM SB1010 SB1 "
// 	_oSQL:_sQuery += " INNER JOIN SB2010 SB2 "
// 	_oSQL:_sQuery += " 	ON SB2.D_E_L_E_T_ = '' "
// 	_oSQL:_sQuery += " 		AND B2_COD = B1_COD "
// 	_oSQL:_sQuery += " 		AND SB2.B2_QATU > 0
// 	_oSQL:_sQuery += " WHERE SB1.D_E_L_E_T_ = '' "
// 	_oSQL:_sQuery += "  AND SB1.B1_COD IN ('602129','606305','606317','606320','606321','606322','606323','606325','606327','606328','606329','606331','606332')"
// 	_oSQL:_sQuery += " AND SB1.B1_TIPO in ('MM','MC')  "
// 	_oSQL:Log ()
// 	_aSB1:= _oSQL:Qry2Array ()
	
// 	For _x := 1 to Len(_aSB1)
// 		CriaSB2 (_aSB1[_x, 1], '02')
// 	Next

// Return
//
// ------------------------------------------------------------------
// Static Function BaixaAut()
// 	Local x := 0

// 	// Busca dados do título para fazer a baixa
// 	_oSQL:= ClsSQL ():New ()
// 	_oSQL:_sQuery := ""
// 	_oSQL:_sQuery += " SELECT "
// 	_oSQL:_sQuery += " 	   SE1.E1_FILIAL"	// 01
// 	_oSQL:_sQuery += "    ,SE1.E1_PREFIXO"	// 02
// 	_oSQL:_sQuery += "    ,SE1.E1_NUM"		// 03
// 	_oSQL:_sQuery += "    ,SE1.E1_PARCELA"	// 04
// 	_oSQL:_sQuery += "    ,SE1.E1_VALOR"	// 05
// 	_oSQL:_sQuery += "    ,SE1.E1_CLIENTE"	// 06
// 	_oSQL:_sQuery += "    ,SE1.E1_LOJA"		// 07
// 	_oSQL:_sQuery += "    ,SE1.E1_EMISSAO"	// 08
// 	_oSQL:_sQuery += "    ,SE1.E1_TIPO"		// 09
// 	_oSQL:_sQuery += "    ,SE1.E1_BAIXA"	// 10
// 	_oSQL:_sQuery += "    ,SE1.E1_SALDO"	// 11
// 	_oSQL:_sQuery += "    ,SE1.E1_STATUS "	// 12
// 	_oSQL:_sQuery += "    ,SE1.E1_ADM "	    // 13
// 	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " AS SE1 "
// 	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
// 	_oSQL:_sQuery += " AND SE1.E1_FILIAL  = '10'"
// 	_oSQL:_sQuery += " AND SE1.E1_BAIXA   = ''"
// 	_oSQL:_sQuery += " AND SE1.E1_EMISSAO ='20210614'"
// 	_oSQL:_sQuery += " AND SE1.E1_TIPO IN ('CC','CD')"
// 	_oSQL:Log ()

// 	_aTitulo := aclone (_oSQL:Qry2Array ())

// 	If len(_aTitulo) <= 0
// 		u_log("TÍTULO NÃO ENCONTRADO")
// 	Else
// 		For x:=1 to len(_aTitulo)	
// 			lMsErroAuto := .F.				
// 			// Cupom lojas e NF Lojas
// 			_sMotBaixa := 'DEBITO CC' 
// 			_sHist     := 'Baixa Cielo'	
// 			_nVlrLiq   := _aTitulo[x,5]
// 			//_nVlrAcr   := 0.01
// 			//_nVlrDec   := 0
// 			_sBanco    := '041'
// 			_sAgencia  := '0568 '
// 			_sConta    := '0606136809'


// 			//executar a rotina de baixa automatica do SE1 gerando o SE5 - DO VALOR LÍQUIDO
// 			_aAutoSE1 := {}
// 			aAdd(_aAutoSE1, {"E1_FILIAL" 	, _aTitulo[x,1]	    				, Nil})
// 			aAdd(_aAutoSE1, {"E1_PREFIXO" 	, _aTitulo[x,2]	    				, Nil})
// 			aAdd(_aAutoSE1, {"E1_NUM"     	, _aTitulo[x,3]	    				, Nil})
// 			aAdd(_aAutoSE1, {"E1_PARCELA" 	, _aTitulo[x,4]	    				, Nil})
// 			aAdd(_aAutoSE1, {"E1_CLIENTE" 	, _aTitulo[x,6] 					, Nil})
// 			aAdd(_aAutoSE1, {"E1_LOJA"    	, _aTitulo[x,7] 					, Nil})
// 			aAdd(_aAutoSE1, {"E1_TIPO"    	, _aTitulo[x,9] 					, Nil})
// 			AAdd(_aAutoSE1, {"AUTMOTBX"		, _sMotBaixa  						, Nil})
// 			AAdd(_aAutoSE1, {"AUTBANCO"  	, _sBanco 							, Nil})  	
// 			AAdd(_aAutoSE1, {"AUTAGENCIA"   , _sAgencia	    				    , Nil})  
// 			AAdd(_aAutoSE1, {"AUTCONTA"  	, _sConta							, Nil})
// 			AAdd(_aAutoSE1, {"AUTDTBAIXA"	, dDataBase   		 				, Nil})
// 			AAdd(_aAutoSE1, {"AUTDTCREDITO"	, dDataBase		 					, Nil})
// 			AAdd(_aAutoSE1, {"AUTHIST"   	, _sHist    					    , Nil})
// 			AAdd(_aAutoSE1, {"AUTJUROS"  	, 0         						, Nil})
// 			AAdd(_aAutoSE1, {"AUTDESCONT"	, 0         					    , Nil})
// 		    AAdd(_aAutoSE1, {"AUTMULTA"  	, 0         						, Nil})
// 			//AAdd(_aAutoSE1, {"AUTACRESC" 	, _nVlrAcr							, Nil})
// 	        //AAdd(_aAutoSE1, {"AUTDECRESC" 	, _nVlrDec							, Nil})
// 			AAdd(_aAutoSE1, {"AUTVALREC"  	, _nVlrLiq							, Nil})
		
// 			_aAutoSE1 := aclone (U_OrdAuto (_aAutoSE1))  // orderna conforme dicionário de dados

// 			 cPerg = 'FIN070'
// 			 _aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
// 			 U_GravaSX1 (cPerg, "01", 1)    // testar mostrando o lcto contabil depois pode passar para nao
// 			 U_GravaSX1 (cPerg, "04", 1)    // esse movimento tem que contabilizar
// 			 U_GravaSXK (cPerg, "01", "1", 'G' )
// 			 U_GravaSXK (cPerg, "04", "1", 'G' )

// 			MSExecAuto({|x,y| Fina070(x,y)},_aAutoSE1,3,.F.,5) // rotina automática para baixa de títulos

// 			If lMsErroAuto
// 				u_log(memoread (NomeAutoLog ()))
// 				u_log("IMPORTAÇÃO NÃO REALIZADA")
// 			Else
// 				u_log("IMPORTAÇÃO REALIZADA")
// 			Endif
			
// 			U_GravaSXK (cPerg, "01", "1", 'D' )
// 			U_GravaSXK (cPerg, "04", "1", 'D' )

// 			U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina  
// 		Next
// 	EndIf
// Return
//
// ------------------------------------------------------------------
//
// Static Function Coordenadores()
// 	Local _aDados 	:= {}
// 	Local _i 		:=0

// 	_aDados = U_LeCSV ('C:\Temp\coordenadores.csv', ';')

// 	for _i := 1 to len (_aDados)
// 		_sCliente := _aDados[_i, 1]
// 		_sLoja    := _aDados[_i, 2]
// 		_sVend    := _aDados[_i, 3]
// 		_sGerente := _aDados[_i, 4]

// 		If dbSeek(xFilial("AI0") + _sCliente + _sLoja ) 
// 			Reclock("AI0",.F.)
//                 AI0->AI0_VAGERE := alltrim(_sGerente)
//             AI0->(MsUnlock())
// 		Else
// 			Reclock("AI0",.T.)
// 				AI0->AI0_CODCLI := _sCliente
// 				AI0->AI0_LOJA   := _sLoja
// 				AI0->AI0_VAGERE := alltrim(_sGerente)
// 			AI0->(MsUnlock())

// 		EndIf
// 	Next
// 	u_help("Feito!")
// Return
//
// ------------------------------------------------------------------
// Bandeira/parcela/NSU/Vlr.Bruto/Vlr,Liq.
// Static Function Cielo()
// 	Local _aDados 	:= {}
// 	Local _aTexto   := {}
// 	Local _i 		:= 0
// 	Local _x        := 0

// 	nHandle := FCreate("c:\temp\titulos_cielo.csv")
// 	_aDados = U_LeCSV ('C:\Temp\cielo.csv', ';')

// 	_sTexto := " FILIAL; TITULO; PREFIXO; PARCELA;CLIENTE;LOJA;NSU;AUTORIZACAO;BANDEIRA;VALOR TITULO; VLR.BRUTO CIELO;VLR.LIQ CIELO"+ chr (13) + chr (10)
// 	FWrite(nHandle,_sTexto )

// 	for _i := 1 to len (_aDados)
// 		_sBandeira := _aDados[_i, 1]
// 		_sParc     := _aDados[_i, 2]
// 		_sNSU      := _aDados[_i, 3]
// 		_VlrBrt    := _aDados[_i, 4]
// 		_VlrLiq    := _aDados[_i, 5]

// 		_oSQL := ClsSQL():New ()
// 		_oSQL:_sQuery := ""
// 		_oSQL:_sQuery += " SELECT "
// 		_oSQL:_sQuery += " 	   E1_FILIAL "
// 		_oSQL:_sQuery += "    ,E1_NUM "
// 		_oSQL:_sQuery += "    ,E1_PREFIXO "
// 		_oSQL:_sQuery += "    ,E1_PARCELA "
// 		_oSQL:_sQuery += "    ,E1_CLIENTE "
// 		_oSQL:_sQuery += "    ,E1_LOJA "
// 		_oSQL:_sQuery += "    ,E1_NSUTEF "
// 		_oSQL:_sQuery += "    ,E1_CARTAUT "
// 		_oSQL:_sQuery += "    ,E1_VALOR "
// 		_oSQL:_sQuery += " FROM " + RetSqlName("SE1")
// 		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
// 		_oSQL:_sQuery += " AND E1_NSUTEF    = '"+ alltrim(_sNSU)  +"' "
// 		_oSQL:_sQuery += " AND E1_PARCELA   = '"+ alltrim(_sParc) +"' "
// 		_oSQL:Log ()
// 		_aTexto:= _oSQL:Qry2Array ()

// 		For _x := 1 to Len(_aTexto)
// 			_sFilial := _aTexto[_x, 1]
// 			_sNum    := _aTexto[_x, 2]
// 			_sPrefix := _aTexto[_x, 3]
// 			_sParc   := _aTexto[_x, 4]
// 			_sCliente:= _aTexto[_x, 5]
// 			_sLoja   := _aTexto[_x, 6]
// 			_sNsu    := _aTexto[_x, 7]
// 			_sAut    := _aTexto[_x, 8]
// 			_nValor  := _aTexto[_x, 9]

// 			_sTexto := _sFilial +";"+ _sNum +";"+ _sPrefix +";"+ _sParc +";"+ _sCliente +";"+ _sLoja +";"+ _sNsu +";"+ _sAut +";"+ _sBandeira +";"+ str(_nValor) +";"+ _VlrBrt +";"+ _VlrLiq + chr (13) + chr (10)
// 			FWrite(nHandle,_sTexto )
// 		Next

// 	Next
// 	FClose(nHandle)
// Return
//
// ------------------------------------------------------------------
// Static Function Solicitante()
// 	Local _aDados 	:= {}
// 	Local _i 		:=0

// 	_aDados = U_LeCSV ('C:\Temp\solicitante.csv', ';')

// 	for _i := 1 to len (_aDados)
// 		_sFilial  := _aDados[_i, 1]
// 		_sNumero  := _aDados[_i, 2]
// 		_sFornec  := _aDados[_i, 3]
// 		_dEmissao := _aDados[_i, 4]
// 		_sSolicit := _aDados[_i, 5]

// 		_oSQL := ClsSQL():New ()
// 		_oSQL:_sQuery := ""
// 		_oSQL:_sQuery += " UPDATE  " + RetSqlName("SC7")
// 		_oSQL:_sQuery += " 		SET C7_SOLICIT = '" + _sSolicit +"'"
// 		_oSQL:_sQuery += " WHERE C7_FILIAL = '" + _sFilial  + "'"
// 		_oSQL:_sQuery += " AND C7_NUM      = '" + _sNumero  + "'" 
// 		_oSQL:_sQuery += " AND C7_FORNECE  = '" + _sFornec  + "'" 
// 		_oSQL:_sQuery += " AND C7_EMISSAO  = '" + _dEmissao + "'" 
// 		_oSQL:Exec ()
// 	Next
// return
//
// User function ClauBatVerbas(_nTipo, _sFilial)
// 	Local _aDados   := {}
// 	Local _aVend    := {}
// 	Local _x		:= 0
// 	Local _i		:= 0
// 	Private cPerg   := "BatVerbas"
	
// 	_dDtaIni := STOD('20160101')
// 	_dDtaFin  := LastDate ( _dDtaIni)
	
// 	While _dDtaIni <= STOD('20201231')
// 		u_logIni ()
// 		_sErroAuto := ''  // Para a funcao u_help gravar mensagens
// 		u_log ( DTOS(_dDtaIni) +'-' + DTOS(_dDtaFin))
// 		_sSQL := " DELETE FROM ZB0010" 
// 		_sSQL += " WHERE ZB0_FILIAL= '" +_sFilial +"' AND ZB0_DATA BETWEEN '" + DTOS(_dDtaIni) + "' AND '" + DTOS(_dDtaFin) + "'"
// 		u_log (_sSQL)
		
// 		If TCSQLExec (_sSQL) < 0
// 			if type ('_oBatch') == 'O'
// 				_oBatch:Mensagens += 'Erro ao limpar tabela ZB0010'
// 				_oBatch:Retorno = 'N'  // "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente
// 			else
// 				u_help ('Erro ao limpar tabela ZB0010',, .t.)
// 			endif
// 		Else
// 			_oSQL:= ClsSQL ():New ()
// 			_oSQL:_sQuery := ""
// 			_oSQL:_sQuery += " SELECT DISTINCT
// 			_oSQL:_sQuery += " 	   E3_VEND AS VENDEDOR
// 			_oSQL:_sQuery += "    ,A3_NOME AS NOM_VEND
// 			_oSQL:_sQuery += "    FROM " + RetSQLName ("SE3") + " AS SE3 "
// 			_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA3") + " AS SA3 "
// 			_oSQL:_sQuery += " 	ON (SA3.D_E_L_E_T_ = ''"
// 			//_oSQL:_sQuery += "              AND SA3.A3_COD IN('205','299')"
// 			//_oSQL:_sQuery += " 			AND SA3.A3_MSBLQL != '1'
// 			//_oSQL:_sQuery += " 			AND SA3.A3_ATIVO != 'N'
// 			_oSQL:_sQuery += " 			AND SA3.A3_COD = SE3.E3_VEND)
// 			_oSQL:_sQuery += " WHERE E3_FILIAL = '" + xFilial('SE3') + "' "   
// 			_oSQL:_sQuery += " AND E3_VEND BETWEEN ' ' and 'ZZZ'"
// 			_oSQL:_sQuery += " AND E3_EMISSAO BETWEEN '" + dtos (_dDtaIni) + "' AND '" + dtos (_dDtaFin) + "'"
// 			_oSQL:_sQuery += " AND E3_BAIEMI = 'B'
// 			_oSQL:_sQuery += " AND SE3.D_E_L_E_T_ = ''

// 			_oSQL:Log ()
// 			_aVend := _oSQL:Qry2Array ()
			
// 			For _i := 1 to Len(_aVend)
// 				_aDados := U_VA_COMVERB(_dDtaIni, _dDtaFin, _aVend[_i,1], 3, _sFilial)
				
// 				u_log ( DTOS(_dDtaIni) +'-' + DTOS(_dDtaFin) +'/'+_aVend[_i,1])
// 				For _x := 1 to Len(_aDados)
// 					If alltrim(_aDados[_x,17]) == ''
// 						_dDtPgto := STOD('19000101')
// 					Else
// 						_dDtPgto := STOD(_aDados[_x,17])
// 					EndIf
// 					dbselectArea("ZB0")
// 					RecLock("ZB0",.T.)
// 						ZB0 -> ZB0_FILIAL	:= _aDados[_x,14]		
// 						ZB0 -> ZB0_NUM		:= _aDados[_x,4]	
// 						ZB0 -> ZB0_SEQ		:= _aDados[_x,15]		                                      
// 						ZB0 -> ZB0_DATA		:= stod(_aDados[_x,16])	
// 						ZB0 -> ZB0_TIPO		:= _aDados[_x,13]
// 						ZB0 -> ZB0_ACRDES   := _aDados[_x,12]
// 						ZB0 -> ZB0_VENDCH   := _aVend[_i,1]
// 						ZB0 -> ZB0_VENVER  	:= _aDados[_x,2]
// 						ZB0 -> ZB0_VENNF 	:= _aDados[_x,3]
// 						ZB0 -> ZB0_DOC		:= _aDados[_x,5]	
// 						ZB0 -> ZB0_PREFIX	:= _aDados[_x,6]
// 						ZB0 -> ZB0_CLI		:= _aDados[_x,7]
// 						ZB0 -> ZB0_LOJA		:= _aDados[_x,8]
// 						ZB0 -> ZB0_VLBASE	:= _aDados[_x,10]
// 						ZB0 -> ZB0_VLCOMS  	:= _aDados[_x,11]
// 						ZB0 -> ZB0_PERCOM   := _aDados[_x,9]
// 						ZB0 -> ZB0_DTAPGT   := _dDtPgto 

// 					MsUnLock() 
// 				Next
// 			Next
// 		EndIf
// 		_dDtaIni  := MonthSum(_dDtaIni,1)
// 		_dDtaFin  := LastDate(_dDtaIni)
// 	EndDo 

// 	u_help("Processo finalizado com sucesso")
// Return

// static function comissoes()
// 	Local _aDados 	:= {}
// 	Local _aCom     := {}
// 	Local i 		:= 0
// 	Local _x        := 0
// 	Local _oSQL  := ClsSQL ():New ()

// 	 nHandle := FCreate("c:\temp\retorComissao.csv")

// 	_sLinha := 'VEND;FILIAL;DOCUMENTO;SERIE;PARCELA;CLIENTE;LOJA;TOTAL_NF;IPI_NF;ST_NF;FRETE_NF;BASE_TIT;VALOR_TIT;VLR_DESCONTO;VLR_RECEBIDO;QTD_PARCELAS;BASE;MEDIA_COMISSAO;COMISSAO' + chr (13) + chr (10)
// 	FWrite(nHandle,_sLinha )

// 	_aDados = U_LeCSV ('C:\Temp\comissao.csv', ';')

// 	For i:=1 to Len(_aDados)
// 		_sFilial 	:= _aDados[i,1]
// 		_sDocumento := _aDados[i,2]
// 		_sSerie 	:= _aDados[i,3]
// 		_sParc 		:= _aDados[i,4]
// 		_sCliente 	:= _aDados[i,5]
// 		_sLoja 		:= _aDados[i,6]

// 		_oSQL:_sQuery := ""
// 		_oSQL:_sQuery += " WITH C"
// 		_oSQL:_sQuery += " AS"
// 		_oSQL:_sQuery += " (SELECT"
// 		_oSQL:_sQuery += " 		SF2.F2_VEND1 AS VEND"
// 		_oSQL:_sQuery += " 	   ,SE1.E1_FILIAL AS FILIAL"
// 		_oSQL:_sQuery += " 	   ,SE1.E1_NUM AS DOCUMENTO"
// 		_oSQL:_sQuery += " 	   ,SE1.E1_PREFIXO AS SERIE"
// 		_oSQL:_sQuery += " 	   ,SE1.E1_PARCELA AS PARCELA"
// 		_oSQL:_sQuery += " 	   ,SE1.E1_CLIENTE AS CLIENTE"
// 		_oSQL:_sQuery += " 	   ,SE1.E1_LOJA AS LOJA"
// 		_oSQL:_sQuery += " 	   ,F2_VALBRUT AS TOTAL_NF"
// 		_oSQL:_sQuery += " 	   ,F2_VALIPI AS IPI_NF"
// 		_oSQL:_sQuery += " 	   ,F2_ICMSRET AS ST_NF"
// 		_oSQL:_sQuery += " 	   ,F2_FRETE AS FRETE_NF"
// 		_oSQL:_sQuery += " 	   ,E1_BASCOM1 AS BASE_TIT"
// 		_oSQL:_sQuery += " 	   ,E1_VENCTO AS VENCIMENTO"
// 		_oSQL:_sQuery += " 	   ,E1_VALOR AS VALOR_TIT"
// 		_oSQL:_sQuery += " 	   ,ISNULL((SELECT"
// 		_oSQL:_sQuery += " 				ROUND(SUM(E5_VALOR), 2)"
// 		_oSQL:_sQuery += " 			FROM SE5010 AS SE52"
// 		_oSQL:_sQuery += " 			WHERE SE52.E5_FILIAL = E5_FILIAL"
// 		_oSQL:_sQuery += " 			AND SE52.D_E_L_E_T_ != '*'"
// 		_oSQL:_sQuery += " 			AND SE52.E5_RECPAG = 'R'"
// 		_oSQL:_sQuery += " 			AND SE52.E5_SITUACA != 'C'"
// 		_oSQL:_sQuery += " 			AND SE52.E5_NUMERO = SE1.E1_NUM"
// 		_oSQL:_sQuery += " 			AND (SE52.E5_TIPODOC = 'DC'"
// 		_oSQL:_sQuery += " 			OR (SE52.E5_TIPODOC = 'CP'"
// 		_oSQL:_sQuery += " 			AND SE52.E5_DOCUMEN NOT LIKE '% RA %'))"
// 		_oSQL:_sQuery += " 			AND SE52.E5_PREFIXO = SE1.E1_PREFIXO"
// 		_oSQL:_sQuery += " 			AND SE52.E5_PARCELA = SE1.E1_PARCELA"
// 		_oSQL:_sQuery += " 			GROUP BY SE52.E5_FILIAL"
// 		_oSQL:_sQuery += " 					,SE52.E5_RECPAG"
// 		_oSQL:_sQuery += " 					,SE52.E5_NUMERO"
// 		_oSQL:_sQuery += " 					,SE52.E5_PARCELA"
// 		_oSQL:_sQuery += " 					,SE52.E5_PREFIXO)"
// 		_oSQL:_sQuery += " 		, 0) AS VLR_DESCONTO"
// 		_oSQL:_sQuery += " 	   ,ISNULL((SELECT"
// 		_oSQL:_sQuery += " 				ROUND(SUM(E5_VALOR), 2)"
// 		_oSQL:_sQuery += " 			FROM SE5010 AS SE53"
// 		_oSQL:_sQuery += " 			WHERE SE53.E5_FILIAL = SE1.E1_FILIAL"
// 		_oSQL:_sQuery += " 			AND SE53.D_E_L_E_T_ != '*'"
// 		_oSQL:_sQuery += " 			AND SE53.E5_RECPAG = 'R'"
// 		_oSQL:_sQuery += " 			AND SE53.E5_NUMERO = E1_NUM"
// 		_oSQL:_sQuery += " 			AND (SE53.E5_TIPODOC = 'VL'"
// 		_oSQL:_sQuery += " 			OR (SE53.E5_TIPODOC = 'CP'"
// 		_oSQL:_sQuery += " 			AND SE53.E5_DOCUMEN LIKE '% RA %'))"
// 		_oSQL:_sQuery += " 			AND SE53.E5_PREFIXO = SE1.E1_PREFIXO"
// 		_oSQL:_sQuery += " 			AND SE53.E5_PARCELA = SE1.E1_PARCELA"
// 		_oSQL:_sQuery += " 			GROUP BY SE53.E5_FILIAL"
// 		_oSQL:_sQuery += " 					,SE53.E5_RECPAG"
// 		_oSQL:_sQuery += " 					,SE53.E5_NUMERO"
// 		_oSQL:_sQuery += " 					,SE53.E5_PARCELA"
// 		_oSQL:_sQuery += " 					,SE53.E5_PREFIXO)"
// 		_oSQL:_sQuery += " 		, 0) AS VLR_RECEBIDO"
// 		_oSQL:_sQuery += "	,(SELECT"
// 		_oSQL:_sQuery += "		count(SE12.E1_PARCELA)"
// 		_oSQL:_sQuery += "	FROM SE1010 SE12"
// 		_oSQL:_sQuery += "	WHERE SE12.D_E_L_E_T_=''"
// 		_oSQL:_sQuery += "  AND SE12.E1_FILIAL  = '" + _sFilial + "'"
// 		_oSQL:_sQuery += "	AND SE12.E1_NUM     = '" + _sDocumento + "'"
// 		_oSQL:_sQuery += "	AND SE12.E1_PREFIXO = '" + _sSerie + "'" 
// 		//_oSQL:_sQuery += "	AND SE12.E1_PARCELA = '" + _sParc + "'"
// 		_oSQL:_sQuery += "  AND SE12.E1_CLIENTE = '" + _sCliente + "'"
// 		_oSQL:_sQuery += "  AND SE12.E1_LOJA    = '" + _sLoja + "'"
// 		_oSQL:_sQuery += "	) AS QTD_PARC"
// 		_oSQL:_sQuery += "	,SE1.E1_COMIS1 AS E1_COM "
// 		_oSQL:_sQuery += " 	FROM SE1010 SE1"
// 		_oSQL:_sQuery += " 	LEFT JOIN SF2010 AS SF2"
// 		_oSQL:_sQuery += " 		ON (SF2.D_E_L_E_T_ = ''"
// 		_oSQL:_sQuery += " 		AND SF2.F2_FILIAL = SE1.E1_FILIAL"
// 		_oSQL:_sQuery += " 		AND SF2.F2_DOC = SE1.E1_NUM"
// 		_oSQL:_sQuery += " 		AND SF2.F2_SERIE = SE1.E1_PREFIXO"
// 		_oSQL:_sQuery += " 		AND SF2.F2_CLIENTE = SE1.E1_CLIENTE"
// 		_oSQL:_sQuery += " 		AND SF2.F2_LOJA = SE1.E1_LOJA)"
// 		_oSQL:_sQuery += " 	WHERE SE1.D_E_L_E_T_ = ''"
// 		_oSQL:_sQuery += " 	AND E1_FILIAL IN ('01', '16'))"
// 		_oSQL:_sQuery += " SELECT"
// 		_oSQL:_sQuery += " 	    VEND"
// 		_oSQL:_sQuery += " 	   ,FILIAL"
// 		_oSQL:_sQuery += " 	   ,DOCUMENTO"
// 		_oSQL:_sQuery += " 	   ,SERIE"
// 		_oSQL:_sQuery += " 	   ,PARCELA"
// 		_oSQL:_sQuery += "	   ,CLIENTE"
// 		_oSQL:_sQuery += " 	   ,LOJA"
// 		_oSQL:_sQuery += "     ,TOTAL_NF"
// 		_oSQL:_sQuery += "     ,IPI_NF"
// 		_oSQL:_sQuery += "     ,ST_NF"
// 		_oSQL:_sQuery += "     ,FRETE_NF"
// 		_oSQL:_sQuery += "     ,BASE_TIT"
// 		_oSQL:_sQuery += "     ,VALOR_TIT"
// 		_oSQL:_sQuery += "     ,VLR_DESCONTO"
// 		_oSQL:_sQuery += "     ,VLR_RECEBIDO"
// 		_oSQL:_sQuery += "     ,QTD_PARC"
//    		_oSQL:_sQuery += "     ,(VLR_RECEBIDO -(IPI_NF/QTD_PARC) - (ST_NF/QTD_PARC) -(FRETE_NF/QTD_PARC)) AS BASE_LIB"
//    		_oSQL:_sQuery += "     ,E1_COM AS MEDIA_COMISSAO"
//    		_oSQL:_sQuery += "     ,(VLR_RECEBIDO -(IPI_NF/QTD_PARC) - (ST_NF/QTD_PARC) -(FRETE_NF/QTD_PARC)) * (E1_COM) / 100 AS COMISSAO"
// 		_oSQL:_sQuery += " FROM C"
// 		_oSQL:_sQuery += " WHERE FILIAL  = '" + _sFilial + "'"
// 		_oSQL:_sQuery += " AND DOCUMENTO = '" + _sDocumento + "'"
// 		_oSQL:_sQuery += " AND SERIE     = '" + _sSerie + "'"
// 		_oSQL:_sQuery += " AND PARCELA   = '" + _sParc + "'"
// 		_oSQL:_sQuery += " AND CLIENTE   = '" + _sCliente + "'"
// 		_oSQL:_sQuery += " AND LOJA      = '" + _sLoja + "'"
// 		_oSQL:_sQuery += " GROUP BY VEND"
// 		_oSQL:_sQuery += " 	    ,FILIAL"
// 		_oSQL:_sQuery += " 	    ,DOCUMENTO"
// 		_oSQL:_sQuery += " 	    ,SERIE"
// 		_oSQL:_sQuery += " 	    ,PARCELA"
// 		_oSQL:_sQuery += "	    ,CLIENTE"
// 		_oSQL:_sQuery += " 	    ,LOJA"
// 		_oSQL:_sQuery += " 		,TOTAL_NF"
// 		_oSQL:_sQuery += " 		,IPI_NF"
// 		_oSQL:_sQuery += " 		,ST_NF"
// 		_oSQL:_sQuery += " 		,FRETE_NF"
// 		_oSQL:_sQuery += " 		,BASE_TIT"
// 		_oSQL:_sQuery += " 		,VALOR_TIT"
// 		_oSQL:_sQuery += " 		,VLR_DESCONTO"
// 		_oSQL:_sQuery += " 		,VLR_RECEBIDO"
// 		_oSQL:_sQuery += " 		,QTD_PARC"
// 		_oSQL:_sQuery += "		,E1_COM"
// 		_aCom := aclone (_oSQL:Qry2Array ())


// 		For _x:=1 to Len(_aCom)
// 			_sLinha := alltrim(_aCom[_x,1]) +';' 
// 			_sLinha += alltrim(_aCom[_x,2]) +';' 
// 			_sLinha += alltrim(_aCom[_x,3]) +';' 
// 			_sLinha += alltrim(_aCom[_x,4]) +';' 
// 			_sLinha += alltrim(_aCom[_x,5]) +';' 
// 			_sLinha += alltrim(_aCom[_x,6]) +';' 
// 			_sLinha += alltrim(_aCom[_x,7]) +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x, 8])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x, 9])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,10])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,11])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,12])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,13])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,14])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,15])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,16])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,17])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,18])),'.',',') +';' 
// 			_sLinha += StrTran(alltrim(str(_aCom[_x,19])),'.',',') + chr (13) + chr (10)
			
// 			FWrite(nHandle,_sLinha )
// 		Next
// 	Next
// 	FClose(nHandle)
// return

// // INSERE DESCRICAO CC NO SC7
// Static function descCC()
// 	Local _aDados := {}
// 	Local i       := 0

// 	u_help('começa')

// 	_oSQL := ClsSQL():New ()
// 	_oSQL:_sQuery := ""
// 	_oSQL:_sQuery += " SELECT"
// 	_oSQL:_sQuery += " 	   C7_FILIAL"
// 	_oSQL:_sQuery += "    ,C7_NUM"
// 	_oSQL:_sQuery += "    ,C7_ITEM"
// 	_oSQL:_sQuery += "    ,C7_SEQUEN"
// 	_oSQL:_sQuery += "    ,CTT_DESC01"
// 	_oSQL:_sQuery += " FROM SC7010"
// 	_oSQL:_sQuery += " INNER JOIN CTT010 CTT"
// 	_oSQL:_sQuery += " 	ON (CTT.D_E_L_E_T_ = ''"
// 	_oSQL:_sQuery += " 			AND C7_CC = CTT_CUSTO)"
// 	_oSQL:_sQuery += " WHERE C7_EMISSAO >= '20201201'"
// 	_oSQL:_sQuery += " AND C7_CC <> ''"
// 	_oSQL:_sQuery += " AND C7_VACCDES = ''"
// 	_oSQL:_sQuery += " ORDER BY C7_FILIAL, C7_EMISSAO "
// 	_aDados := _oSQL:Qry2Array ()


// 	For i:=1 to Len(_aDados)
// 			dbSelectArea("SC7")
// 			dbSetOrder(1) // c7_filial, c7_num, c7_item, c7_sequen                                                                                                                                  
// 			dbSeek(_aDados[i,1] + _aDados[i,2]  + _aDados[i,3] + _aDados[i,4] )
			
// 			If Found() // Avalia o retorno da pesquisa realizada
// 				RECLOCK("SC7", .F.)
				
// 				SC7->C7_VACCDES := _aDados[i,5] 
				
// 				MSUNLOCK()     // Destrava o registro
// 			EndIf		
// 	Next
// Return
// // ----------------------------------------------------------------------------
// // Importa CSV obs financeiro
//
// static Function ImpOBSFin()
// Local _aDados 	:= {}
// Local _i 		:=0
// local _oEvento 	:= NIL

// 	_aDados = U_LeCSV ('C:\Temp\obs.csv', ';')

// 	//u_log (len(_aDados))

// 	for _i := 1 to len (_aDados)

// 		If Len(alltrim(_aDados [_i, 1])) <= 6
// 			_oEvento    := NIL

// 			_oEvento := ClsEvent():new ()
// 			_oEvento:CodEven   = "SA1004"
// 			_oEvento:DtEvento  = date()
// 			_oEvento:Texto	   = _aDados [_i, 3]
// 			_oEvento:Cliente   = PADL(_aDados [_i, 1],6,'0')
// 			_oEvento:LojaCli   = PADL(_aDados [_i, 2],2,'0')
// 			_oEvento:Grava ()

// 			_Cliente := PADL(_aDados [_i, 2],2,'0')
// 		else
// 			u_log ("---AJUSTE:" +alltrim(_Cliente) + alltrim(_aDados [_i, 1]))
// 		EndIf
// 	Next
// return
//
//Static Function _ajusteZA5()
//	local _i := 0
//	
//	cQuery := " SELECT"
//	cQuery += " 	ZA5_FILIAL"
//	cQuery += "    ,ZA5_NUM"
//	cQuery += "    ,ZA5_SEQ"
//	cQuery += "    ,ZA5_DOC"
//	cQuery += "    ,ZA5_PREFIX"
//	cQuery += "    ,ZA5_CLI
//	cQuery += "    ,ZA5_LOJA"
//	cQuery += "    ,ZA5_VENVER"
//	cQuery += "    ,ZA5_VENNF"
//	cQuery += " FROM ZA5010"
//	cQuery += " WHERE D_E_L_E_T_ = ''"
//	cQuery += " AND ZA5_VENVER = ''"
//	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
//	
//	TRA->(DbGotop())
//	While TRA->(!Eof())
//		
//		if alltrim( TRA->ZA5_PREFIX) == ''
//			_serie := '10'
//		else
//			_serie := TRA->ZA5_PREFIX
//		EndIf
//		
//		_oSQL:= ClsSQL ():New ()
//		_oSQL:_sQuery := ""
//		_oSQL:_sQuery += " SELECT F2_VEND1 FROM SF2010"
//		_oSQL:_sQuery += " WHERE F2_DOC		='"+ TRA->ZA5_DOC +"'"
//		_oSQL:_sQuery += " AND F2_SERIE		='"+ _serie +"'"
//		_oSQL:_sQuery += " AND F2_CLIENTE	='"+ TRA->ZA5_CLI +"'"
//		_oSQL:_sQuery += " AND F2_LOJA		='"+ TRA->ZA5_LOJA +"'"
//		_aVend := _oSQL:Qry2Array ()
//				
//		For _i := 1 to Len(_aVend)
//		
//			dbSelectArea("ZA5")
//			dbSetOrder(1) // ZA5_FILIAL+ZA5_NUM+ZA5_SEQ                                                                                                                                      
//			dbSeek( tra-> ZA5_FILIAL + tra->ZA5_NUM + alltrim(str(tra->ZA5_SEQ)))
//			
//			If Found() // Avalia o retorno da pesquisa realizada
//				RECLOCK("ZA5", .F.)
//				
//				ZA5->ZA5_VENVER := _aVend[_i,1]
//				ZA5->ZA5_VENNF  := _aVend[_i,1]
//				
//				MSUNLOCK()     // Destrava o registro
//			EndIf		
//		Next
//				
//		DBSelectArea("TRA")
//		dbskip()
//	Enddo
//Return
//	local _oSQL     := NIL
//	
//	u_help ("Atualiza comprador")
//	
//	cQuery := " SELECT C7_FILIAL, C7_USER, C7_NUM, C7_FORNECE, C7_EMISSAO "
//	cQuery += " FROM " + RetSqlName("SC7")"
//	cQuery += " WHERE D_E_L_E_T_=''"
//	cQuery += " AND C7_EMISSAO>='20190101'"
//	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
//	
//	TRA->(DbGotop())
//	
//	While TRA->(!Eof())	
//		_oSQL := ClsSQL():New ()
//		_oSQL:_sQuery := ""
//		_oSQL:_sQuery += " UPDATE  " + RetSqlName("SC7")
//		_oSQL:_sQuery +=   " SET C7_COMNOM = '" + UsrFullName(tra -> c7_user) +"'"
//		_oSQL:_sQuery += " WHERE C7_FILIAL = '" +  tra->c7_filial + "'"
//		_oSQL:_sQuery += " AND C7_NUM = '"+ tra -> c7_num +"'" 
//		_oSQL:_sQuery += " AND C7_FORNECE = '"+ tra -> c7_fornece +"'" 
//		_oSQL:_sQuery += " AND C7_EMISSAO = '"+ tra -> c7_emissao +"'" 
//		_oSQL:Exec ()
//		
//		DBSelectArea("TRA")
//		dbskip()
//	Enddo
//	
//	TRA->(DbCloseArea())
//	u_help("Compradores atualizados")
//
//	if type ('__cUserId') == 'U' .or. type ('cUserName') == 'U'
//		u_log ('Preparando ambiente')
//		prepare environment empresa '01' filial '01' modulo '05'
//		private cModulo   := 'FAT'
//		private __cUserId := "000210"
//		private cUserName := "claudia.lionco"
//		private __RelDir  := "c:\temp\spool_protheus\"
//		set century on
//	endif
//	//
//	if ! alltrim(upper(cusername)) $ 'ROBERT.KOCH/ADMINISTRADOR/CATIA.CARDOSO/ANDRE.ALVES/CLAUDIA.LIONCO'
//		msgalert ('Nao te conheco, nao gosto de ti e nao vou te deixar continuar. Vai pra casa.', procname ())
//		return
//	endif
//	//
//	private _sArqLog := procname () + "_" + alltrim (cUserName) + cEmpAnt + ".log"
//	delete file (_sArqLog)
//	u_logId ()
//	if U_Semaforo (procname ()) == 0
//		u_help ('Bloqueio de semaforo na funcao ' + procname ())
//	else
//		PtInternal (1, 'U_Claudia')
//		U_UsoRot ('I', procname (), '')
//		
//		processa ({|| _AndaLogo ()})
//		u_logDH ('Processo finalizado')
//		
//		U_UsoRot ('F', procname (), '')
//	endif
//return

// --------------------------------------------------------------------------
//static function _AndaLogo ()
//	local _sQuery    := ""
//	local _sAliasQ   := ""
//	local _oEvento   := NIL
//	local _aArqTrb   := {}
//	local _aRetSQL   := {}
//	local _nRetSQL   := 0
//	local _sCRLF     := chr (13) + chr (10)
//	local _oSQL      := NIL
//	local _lContinua := .T.
//	local _aDados    := {}
//	PRIVATE _oBatch  := ClsBatch():New ()  // Deixar definido para quando testar rotinas em batch.
//	procregua (100)
//	incproc ()
//	
//	//processa ({|| _AtualizaProduto ()})
//	
//	//processa ({|| _AtualizaRepresentante()})
//	
//	//processa ({|| _AtualizaMercanet()})
//	
//	u_help ("Nada definido", procname ())
//return
//-------------------------------------------------------------------------------------------------
//Static function _AtualizaMercanet()
//
//	_oSQL := ClsSQL ():New ()
//	_oSQL:_sQuery := ""
//	_oSQL:_sQuery += " SELECT R_E_C_N_O_ "
//	_oSQL:_sQuery += " FROM " + RetSQLName ("SA1")
//	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
//	_oSQL:_sQuery += " AND A1_FILIAL = '" + xfilial ("SA1") + "'"  // Deixar esta opcao para poder ler os campos memo.
//	_oSQL:_sQuery += " AND A1_VEND = '317'"
//	_oSQL:Log ()
//	_aDados = aclone (_oSQL:Qry2Array ())
//	
//	For _nLinha := 1 To Len(_aDados)
//		sa1 -> (dbgoto (_aDados [_nLinha, 1]))
//		U_LOG (SA1 -> A1_COD)
//		U_AtuMerc ("SA1", sa1 -> (recno ()))
//	next
//	
//Return
//-------------------------------------------------------------------------------------------------
//Static function _AtualizaRepresentante ()
//
//	u_help ("Alterar comissão do vendedor 317")
//	// Ajusta vendedor de 258 para 317
//	sa1 -> (dbsetorder (1))
//	sa1 -> (dbgotop ())
//	//
//	do while ! sa1 -> (eof ())
//		u_log ('Verificando item', sa1 -> a1_vend)
//		if alltrim(sa1 -> a1_vend) == '317'
//			//u_help ('Verificando item '+ sa1 -> a1_vend + '-'+ sa1 -> a1_cod)
//			// Cria variaveis para uso na gravacao do evento de alteracao
//			regtomemory ("SA1", .F., .F.)
//			sComissao := 5
//			
//			// Grava evento de alteracao
//			_oEvento := ClsEvent():new ()
//			_oEvento:AltCadast ("SA1", sComissao, sa1 -> (recno ()), '', .F.)
//			_oEvento:Grava()
//			
//			U_AtuMerc ("SA1", sa1 -> (recno ()))
//			
//			reclock ("SA1", .f.)
//				sa1 -> a1_comis = sComissao
//			msunlock ()
//			
//			u_log ('alterado')
//			
//			//exit
//		else
//			u_log ('Nada a alterar')
//		endif
//		//
//		sa1 -> (dbskip ())
//	enddo
//Return


////-------------------------------------------------------------------------------------------------
//Static function _AtualizaProduto ()
//	// Ajusta cadastro produtos em lote (altera codigos de barras itens que NAO TEM codigo EAN)
//	sb1 -> (dbsetorder (1))
//	sb5 -> (dbsetorder (1))
//	sb1 -> (dbgotop ())
//	//
//	do while ! sb1 -> (eof ())
//		u_log ('Verificando item', sb1 -> b1_cod, SB1 -> B1_DESC)
//		if sb1->b1_p_brt != sb1->b1_pesbru
//		
//			// Cria variaveis para uso na gravacao do evento de alteracao
//			regtomemory ("SB1", .F., .F.)
//			m->b1_pesbru := sb1->b1_p_brt
//			
//			// Grava evento de alteracao
//			_oEvento := ClsEvent():new ()
//			_oEvento:AltCadast ("SB1", m->b1_cod, sb1 -> (recno ()), '', .F.)
//	
//			reclock ("SB1", .f.)
//			sb1 -> b1_pesbru = m->b1_pesbru
//			msunlock ()
//			//exit
//		else
//			u_log ('nada a alterar')
//		endif
//		//
//		sb1 -> (dbskip ())
//	enddo
//
//Return
//-------------------------------------------------------------------------------------------------
// Static function _AtuISENTO ()

// 	u_help ("Alterar ISENTO")
// 	sa1 -> (dbsetorder (1))
// 	sa1 -> (dbgotop ())
// 	//
// 	do while ! sa1 -> (eof ())
// 		u_log ('Verificando item', sa1 -> a1_inscr)
// 		if alltrim(sa1 -> a1_inscr) == 'ISENTO' .or. alltrim(sa1 -> a1_inscr) == 'ISENTA'
// 			// Cria variaveis para uso na gravacao do evento de alteracao
// 			regtomemory ("SA1", .F., .F.)
			
// 			// Grava evento de alteracao
// 			_oEvento := ClsEvent():new ()
// 			_oEvento:AltCadast ("SA1", "ISENTO", sa1 -> (recno ()), '', .F.)
// 			_oEvento:Grava()
			
// 			U_AtuMerc ("SA1", sa1 -> (recno ()))
			
// 			reclock ("SA1", .f.)
// 				sa1 -> a1_inscr = ''
// 			msunlock ()
			
// 			u_log ('alterado')
			
// 			//exit
// 		else
// 			u_log ('Nada a alterar')
// 		endif
// 		sa1 -> (dbskip ())
// 	enddo
// Return
//-----------------------------------------------------------------------------------
