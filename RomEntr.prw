// Programa:   RomEntr
// Autor:      Robert Koch
// Data:       12/08/2014
// Descricao:  Imprime romaneio de entrada de mercadorias.
//
// Historico de alteracoes:
//
// 01/12/2016 - Catia   - Incluido solicitante
// 18/08/2017 - Catia   - Alterada a mascara do campo quantidade para que imprima com 7 decimais
// 07/01/2019 - Andre   - Ajustado para imprimir romaneio e levar paramêtros contidos na nota.
// 09/01/2019 - Andre   - Adicionado colune com Lote Multiplo e Almoxarifado.
// 09/09/2019 - Claudia - Incluida pergunta para impressão do relatório de romaneio de entrada.
// 30/09/2019 - Cláudia - Alterado relatório para modelo TReport, aumentando a letra e realizando a impressão de 3 vias 
//                        quando algum produto do tipo MM ou CL
// 17/10/2019 - Cláudia - Conforme GLPI 6843, retirada a impressão de 3 vias 
// 19/12/2019 - Claudia - Ajuste de layout de campos pois estava cortando em alguns casos o almoxarifado.
// 06/01/2020 - Claudia - Devido aos problemas de campos cortados, foi alterada a letra e layout de impressão do romaneio.
// 08/01/2020 - Claudia - Ajuste das letras e configurações de layout devido a problemas de cortes nas colunas.
// 26/02/2020 - Cláudia - Incluida coluna de lote interno
// 22/03/2022 - Sandra  - Inclusão campos ordem manutenção, solicitação compra - GLPI 11763
// 07/12/2022 - Sandra  - Alterado campo OP de C7_OP  para D1_OP - GLPI 12877
// 25/07/2023 - Sandra  - Alterada a mascara do campo quantidade para que imprima com 4 decimais - GLPI 13974
// 01/04/2024 - Robert  - Trocada funcao U_GravaSX1() por SetMVValue ()
// 04/04/2024 - Robert  - Atribuir parametros (quando recebidos) `as variaveis MV_PAR*
// 

// -------------------------------------------------------------------------------------------------------------------------

#include 'protheus.ch'
//#include 'parmtype.ch'
//#include "totvs.ch"
//#include "report.ch"
//#include "rwmake.ch"
//#include 'topconn.CH'

User function ROMENTR(_sFornece, _sLoja, _sNF, _sSerie)
	Private oReport
	Private cPerg   := "ROMENTR"

	U_Log2 ('debug', '[' + procname () + ']Conferencia parametro 1: >>' + _sFornece + '<<')
	U_Log2 ('debug', '[' + procname () + ']Conferencia parametro 2: >>' + _sLoja    + '<<')
	U_Log2 ('debug', '[' + procname () + ']Conferencia parametro 3: >>' + _sNF      + '<<')
	U_Log2 ('debug', '[' + procname () + ']Conferencia parametro 4: >>' + _sSerie   + '<<')

	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _sFornece != NIL
//		U_GravaSX1 (cPerg, "01", _sFornece)
//		U_GravaSX1 (cPerg, "02", _sLoja)
//		U_GravaSX1 (cPerg, "03", _sNF)
//		U_GravaSX1 (cPerg, "04", _sSerie)

		SetMVValue(cPerg, "MV_PAR01", _sFornece)
		SetMVValue(cPerg, "MV_PAR02", _sLoja)
		SetMVValue(cPerg, "MV_PAR03", _sNF)
		SetMVValue(cPerg, "MV_PAR04", _sSerie)
		mv_par01 = _sFornece
		mv_par02 = _sLoja
		mv_par03 = _sNF
		mv_par04 = _sSerie
	endif
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return

Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	//Local oSection2:= Nil
	//Local oFunction
	
	oReport := TReport():New("ROMENTR","Romaneio de Entrada",cPerg,{|oReport| PrintReport(oReport)},"Romaneio de Entrada")
	
	oReport:SetPortrait()
	//oReport:SetLandscape()
	//oReport:SetTotalInLine(.F.)
	oReport:SetLineHeight(50)
	//oReport:SetColSpace(1)
	//oReport:SetLeftMargin(0)
	oReport:cFontBody := "Arial"
	//oReport:nFontBody := 10
	//oReport:lParamPage := .F.

	//SESSÃO 1 CUPONS
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 

	TRCell():New(oSection1,"COLUNA1", 	"" ,"Produto"	  ,	    				   ,18,/*lPixel*/,{||  },"LEFT",.t.,,,0,.f.,,,.f.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Descrição"	  ,	    				   ,35,/*lPixel*/,{||	},"LEFT",.t.,,,0,.f.,,,.f.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Quant."      ,"@E 999,999,999.9999"   ,15,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,0,.f.,,,.f.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"UM"		  ,    					   , 4,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,0,.f.,,,.f.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Solicitante" ,       				   ,22,/*lPixel*/,{|| 	},"LEFT",.t.,,,0,.f.,,,.f.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Pedido" 	  ,						   ,22,/*lPixel*/,{|| 	},"LEFT",.t.,,,0,.f.,,,.f.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Lote M."	  ,						   ,10,/*lPixel*/,{|| 	},"RIGHT",.t.,"RIGHT",,0,.f.,,,.f.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Almox"		  ,						   ,6,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,0,.f.,,,.f.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Lote Int."	  ,						   ,10,/*lPixel*/,{|| 	},"RIGHT",.t.,"RIGHT",,0,.f.,,,.f.)
    TRCell():New(oSection1,"COLUNA10", 	"" ,"Or. Serviço" ,						   ,10,/*lPixel*/,{|| 	},"RIGHT",.t.,"RIGHT",,0,.f.,,,.f.)
    TRCell():New(oSection1,"COLUNA11", 	"" ,"Nº Solic"    ,						   ,10,/*lPixel*/,{|| 	},"RIGHT",.t.,"RIGHT",,0,.f.,,,.f.)

Return(oReport)

Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local cQuery    := ""		
	//Local nVia      := 0
	//Local nQtdProd  := 0
    
	sf1 -> (dbsetorder (1))  // F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
	If ! sf1 -> (dbseek (xfilial ("SF1") + mv_par03 + mv_par04 + mv_par01 + mv_par02, .F.))
		u_help ("NF não encontrada!")
	Else

		cQuery := ""
		cQuery += " SELECT D1_COD "
		cQuery += " , D1_DESCRI "
		cQuery += " , D1_QUANT "	
		cQuery += " , D1_UM "
		cQuery += " , D1_VAVOLQT "
		cQuery += " , D1_VAVOLES "
		cQuery += " , D1_PEDIDO "
		cQuery += " , D1_ITEMPC "
		cQuery += " , CASE WHEN SC1.C1_SOLICIT <> '' THEN SC1.C1_SOLICIT ELSE SC7.C7_COMNOM END AS SOLICITANTE "
		cQuery += " , SA5.A5_LOTEMUL AS LOTE_MULTIPLO "
		cQuery += " , D1_LOCAL "
		cQuery += " , D1_TP "
		cQuery += " , D1_LOTECTL "
		cQuery += " , SUBSTRING(D1_OP,1,6) AS OP "
   		cQuery += " , C7_NUMSC "
		cQuery += " FROM " + RetSQLName ("SD1") + " SD1"
		cQuery += " LEFT JOIN SC1010 AS SC1"
		cQuery += " 		ON (SC1.D_E_L_E_T_ = ''"
		cQuery += " 		    AND SD1.D1_PEDIDO != ''"
		cQuery += " 			AND SC1.C1_FILIAL   = SD1.D1_FILIAL"
		cQuery += " 			AND SC1.C1_PEDIDO   = SD1.D1_PEDIDO"
		cQuery += " 			AND SC1.C1_ITEMPED  = SD1.D1_ITEMPC)"
		cQuery += " LEFT JOIN SA5010 AS SA5 "
		cQuery += "		ON ( SA5.A5_FORNECE = SD1.D1_FORNECE"
		cQuery += "			 AND SA5.A5_PRODUTO = SD1.D1_COD"
        cQuery += "			 AND SA5.A5_LOJA = SD1.D1_LOJA"
        cQuery += "			 AND SA5.D_E_L_E_T_ = '' )"
		cQuery += "LEFT JOIN SC7010 AS SC7 "
	    cQuery += "		ON ( SC7.D_E_L_E_T_ = '' "
		cQuery += "			 AND  SC7.C7_NUM = SD1.D1_PEDIDO "
		cQuery += "			 AND  SC7.C7_FILIAL = SD1.D1_FILIAL "
		cQuery += "			 AND  SC7.C7_ITEM = SD1.D1_ITEMPC "
		cQuery += "	         AND  SC7.C7_PRODUTO = SD1.D1_COD) "

		cQuery += " WHERE SD1.D_E_L_E_T_ != '*'"
		cQuery += "   AND SD1.D1_FILIAL   = '" + xfilial ("SD1") + "'"
		cQuery += "   AND SD1.D1_FORNECE  = '" + mv_par01 + "'"
		cQuery += "   AND SD1.D1_LOJA     = '" + mv_par02 + "'"
		cQuery += "   AND SD1.D1_DOC      = '" + mv_par03 + "'"
		cQuery += "   AND SD1.D1_SERIE    = '" + mv_par04 + "'"
		cQuery += " ORDER BY D1_COD"
		U_Log2 ('debug', '[' + procname () + ']' + cQuery)
		dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
		
//		// Verifica se tem produto MM ou CL para imprimir 3 vias
//		TRA->(DbGotop())
//		While TRA->(!Eof())
//			nQtdProd += 1 
//			If alltrim(TRA-> D1_TP)=='MM' .or. alltrim(TRA-> D1_TP)=='CL'
//				nVia += 1
//			EndIf
//			DBSelectArea("TRA")
//			dbskip()
//		enddo
		//
//		If nVia > 0
//			nRepete := 3
//		Else
//			nRepete := 2
//		EndIf
		
//		For x:=1 to nRepete
			// Imprime linha NF
			_sLinImp := 'Nota fiscal/serie: ' + sf1 -> f1_doc + '/' + sf1 -> f1_serie + '    Tipo: ' + sf1 -> f1_tipo + '  '
			If sf1 -> f1_tipo $ 'BD'
				_sLinImp += 'Cliente/loja:    ' + mv_par01 + '/' + mv_par02 + " - " + fBuscaCpo ("SA1", 1, xfilial ("SA1") + mv_par01 + mv_par02, "A1_NOME")
			Else
				_sLinImp += 'Fornecedor/loja: ' + mv_par01 + '/' + mv_par02 + " - " + fBuscaCpo ("SA2", 1, xfilial ("SA2") + mv_par01 + mv_par02, "A2_NOME")
			EndIf
					
			// Imprime 1º via
			oReport:PrintText(" ",,100)
			oReport:PrintText(_sLinImp,,100)
			oReport:PrintText(" ",,100)
			
			oSection1:Init()
			oSection1:SetHeaderSection(.T.)
			
			TRA->(DbGotop())
			
			While TRA->(!Eof())	
				oSection1:Cell("COLUNA1")	:SetBlock   ({|| TRA->D1_COD  	 					})
				oSection1:Cell("COLUNA2")	:SetBlock   ({|| TRA->D1_DESCRI   					})
				oSection1:Cell("COLUNA3")	:SetBlock   ({|| TRA->D1_QUANT 	  					})
				oSection1:Cell("COLUNA4")	:SetBlock   ({|| TRA->D1_UM	  						})
				oSection1:Cell("COLUNA5")	:SetBlock   ({|| TRA->SOLICITANTE 					})
				oSection1:Cell("COLUNA6")	:SetBlock   ({|| TRA->D1_PEDIDO +'/'+ TRA->D1_ITEMPC})
				oSection1:Cell("COLUNA7")	:SetBlock   ({|| TRA->LOTE_MULTIPLO   				})
				oSection1:Cell("COLUNA8")	:SetBlock   ({|| TRA->D1_LOCAL    					})
				oSection1:Cell("COLUNA9")	:SetBlock   ({|| TRA->D1_LOTECTL    				})
				oSection1:Cell("COLUNA10")	:SetBlock   ({|| OP                 			   	})
				oSection1:Cell("COLUNA11")	:SetBlock   ({|| TRA->C7_NUMSC      				})
				oSection1:PrintLine()
				
				DBSelectArea("TRA")
				dbskip()
			enddo
			oReport:PrintText(" ",,100)
			
//			If nRepete == 2 .and. nQtdProd <= 6
//				Do Case 
//					Case nQtdProd = 6
//						nX := 8
//					Case nQtdProd = 5
//						nX := 10
//					Case nQtdProd = 4
//						nX := 12
//					Case nQtdProd = 3
//						nX := 14
//					Case nQtdProd = 2
//						nX := 16
//					Case nQtdProd = 1 
//						nX := 18
//				EndCase
//				
//				For y:=1 to nX
//					oReport:PrintText(" ")
//				Next
//			EndIf
//			
//			Do Case
//				Case x == 1
//					oReport:PrintText("1º Via - Recebimento Fiscal      					Data de emissão:" + alltrim(DTOC(date())) + " 	Hora:" + time(),,100)
//				Case x == 2
//					oReport:PrintText("2º Via - Almoxarifado     							Data de emissão:" + alltrim(DTOC(date())) + " 	Hora:" + time(),,100)
//				Case x == 3
//					oReport:PrintText("3º Via - Manutenção      							Data de emissão:" + alltrim(DTOC(date())) + " 	Hora:" + time(),,100)
//			EndCase
//			
//			oReport:PrintText("----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------",,0)
//		Next
		oSection1:Finish()
		TRA->(DbCloseArea())
    EndIf
Return

//---------------------- PERGUNTAS
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Fornecedor                    ", "C", 6,  0,  "",   "SA2", {},    ""})
	aadd (_aRegsPerg, {02, "Loja                          ", "C", 2,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {03, "NF                            ", "C", 9,  0,  "",   "SF1", {},    ""})
	aadd (_aRegsPerg, {04, "Serie                         ", "C", 3,  0,  "",   "   ", {},    ""})

	U_ValPerg (cPerg, _aRegsPerg, {})
return

