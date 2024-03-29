//  Programa...: ML_GARANTIAS
//  Autor......: Catia Cardoso
//  Data.......: 30/07/2018
//  Cliente....: Alianca
//  Descricao..: Relat�rio de Cobran�a / Garantias / Bancos
//
//  Historico de alteracoes:
//  01/08/2018 - Andr�   - Ajustado relat�rio em PDF e inclu�do e-mails de destino.
//  09/08/2018 - Catia   - ajustado para que considera o vencimento dos titulos >= 
//  20/11/2018 - Sandra  - Alterado e-mail de aline.trentin@novaalianca.coop.br 
//                         para financeiro@novaalianca.coop.br 
//  05/09/2023 - Claudia - Incluidos portadores com garantia, por�m sem titulos emitidos.
//                         Alterado para novo modelo de impress�o de relatorio. GLPI: 14173
//
// ----------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include "totvs.ch"

User Function ML_GARANTIAS()
	Private oReport
	//Private cPerg := "ML_GARANTIA"
	
	oReport := ReportDef()
	oReport:PrintDialog()

Return
//
// ----------------------------------------------------------------------------------------------
// Cabe�alho da rotina
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	Local oBreak1

	oReport := TReport():New("ML_GARANTIAS","Resumo por Portador Cobran�a/Garantias",,{|oReport| PrintReport(oReport)},"Resumo por Portador Cobran�a/Garantias")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetLandscape()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1"	, 	"" ,"Filial"		,	  						, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2"	, 	"" ,"Portador"     	,       					,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3"	, 	"" ,"Descri��o"  	,       					,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4"	, 	"" ,"Qtd.T�tulos"  	, "@E 99999999999"      	,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5"	, 	"" ,"Vlr.Garantia" 	, "@E 999,999,999.99"      	,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6"	, 	"" ,"Vlr.Saldo"    	, "@E 999,999,999.99"      	,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7"	, 	"" ,"Sobra/Falta"	, "@E 999,999,999.99"   	,25,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8"	, 	"" ,"Percentual"	, "@E 999.99"   			,20,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)

    oBreak1 := TRBreak():New(oSection1,oSection1:Cell("COLUNA1"),"Total por filial")
	TRFunction():New(oSection1:Cell("COLUNA4")	,,"SUM"	,oBreak1,"Total T�tulos "   	, "@E 99999999", NIL, .F., .T.)
	TRFunction():New(oSection1:Cell("COLUNA5")	,,"SUM"	,oBreak1,"Total Vlr.Garantia "  , "@E 99,999,999.99", NIL, .F., .T.)
	TRFunction():New(oSection1:Cell("COLUNA6")	,,"SUM"	,oBreak1,"Total Vlr.Saldo "   	, "@E 99,999,999.99", NIL, .F., .T.)
    TRFunction():New(oSection1:Cell("COLUNA7")	,,"SUM"	,oBreak1,"Total Sobra/Falta "   , "@E 99,999,999.99", NIL, .F., .T.)
	
Return(oReport)
//
// ----------------------------------------------------------------------------------------------
// Impress�o
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local _x        := 0

	oSection1:Init()
	oSection1:SetHeaderSection(.T.)

	_oSQL := ClsSQL():New ()  
	_oSQL:_sQuery := "" 		
	_oSQL:_sQuery += " WITH C "
	_oSQL:_sQuery += " AS "
	_oSQL:_sQuery += " (SELECT "
	_oSQL:_sQuery += " 		SE1.E1_FILIAL AS FILIAL "
	_oSQL:_sQuery += " 	   ,SE1.E1_PORTADO AS PORTADOR "
	_oSQL:_sQuery += " 	   ,SUM(SE1.E1_SALDO) AS SALDO "
	_oSQL:_sQuery += " 	   ,COUNT(SE1.R_E_C_N_O_) AS QUANT_TIT "
	_oSQL:_sQuery += " 	FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " 	WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 	AND SE1.E1_SALDO > 0 "
	_oSQL:_sQuery += " 	AND SE1.E1_TIPO NOT IN ('NCC', 'RA') "
	_oSQL:_sQuery += " 	AND SE1.E1_VENCREA >= '20230906' "
	_oSQL:_sQuery += " 	GROUP BY SE1.E1_FILIAL "
	_oSQL:_sQuery += " 			,SE1.E1_PORTADO) "
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   C.FILIAL "
	_oSQL:_sQuery += "    ,C.PORTADOR "
	_oSQL:_sQuery += "    ,ISNULL((SELECT TOP 1 "
	_oSQL:_sQuery += " 			SA6.A6_NOME "
	_oSQL:_sQuery += " 		FROM " + RetSQLName ("SA6") + " SA6 "
	_oSQL:_sQuery += " 		WHERE SA6.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA6.A6_BLOCKED = '2' "
	_oSQL:_sQuery += " 		AND SA6.A6_FILIAL = C.FILIAL "
	_oSQL:_sQuery += " 		AND SA6.A6_COD = C.PORTADOR "
	_oSQL:_sQuery += " 		ORDER BY SA6.R_E_C_N_O_) "
	_oSQL:_sQuery += " 	   , 'CARTEIRA') AS PORT_DESC "
	_oSQL:_sQuery += "    ,C.QUANT_TIT "
	_oSQL:_sQuery += "    ,ISNULL((SELECT "
	_oSQL:_sQuery += " 			SUM(SA6.A6_GARANT) "
	_oSQL:_sQuery += " 		FROM " + RetSQLName ("SA6") + " SA6 "
	_oSQL:_sQuery += " 		WHERE SA6.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA6.A6_FILIAL = C.FILIAL "
	_oSQL:_sQuery += " 		AND SA6.A6_BLOCKED = '2' "
	_oSQL:_sQuery += " 		AND SA6.A6_COD = C.PORTADOR) "
	_oSQL:_sQuery += " 	, 0) AS GARANTIA "
	_oSQL:_sQuery += "    ,C.SALDO "
	_oSQL:_sQuery += "    ,C.SALDO - ISNULL((SELECT "
	_oSQL:_sQuery += " 			SUM(SA6.A6_GARANT) "
	_oSQL:_sQuery += " 		FROM " + RetSQLName ("SA6") + " SA6 "
	_oSQL:_sQuery += " 		WHERE SA6.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 		AND SA6.A6_FILIAL = C.FILIAL "
	_oSQL:_sQuery += " 		AND SA6.A6_BLOCKED = '2' "
	_oSQL:_sQuery += " 		AND SA6.A6_COD = C.PORTADOR) "
	_oSQL:_sQuery += " 	, 0) AS SOBRA_FALTA "
	_oSQL:_sQuery += "    ,ROUND(C.SALDO / (SUM(C.SALDO) OVER (PARTITION BY FILIAL)) * 100, 2) AS PERCENTUAL "
	_oSQL:_sQuery += "    ,SUM(C.SALDO) OVER (PARTITION BY FILIAL) AS TOT_FILIAL "
	_oSQL:_sQuery += " FROM C "

	_oSQL:_sQuery += " UNION ALL "

	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   A6_FILIAL AS FILIAL "
	_oSQL:_sQuery += "    ,A6_COD AS PORTADOR "
	_oSQL:_sQuery += "    ,A6_NOME AS PORT_DESC "
	_oSQL:_sQuery += "    ,0 AS QUANT_TIT "
	_oSQL:_sQuery += "    ,A6_GARANT AS GARANTIA "
	_oSQL:_sQuery += "    ,0 AS SALDO "
	_oSQL:_sQuery += "    ,0 AS SOBRA_FALTA "
	_oSQL:_sQuery += "    ,0 AS PERCENTUAL "
	_oSQL:_sQuery += "    ,0 AS TOT_FILIAL "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SA6") 
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND A6_BLOCKED = '2' "
	_oSQL:_sQuery += " AND A6_GARANT > 0 "
	_oSQL:_sQuery += " AND A6_COD NOT IN (SELECT "
	_oSQL:_sQuery += " 		SE1.E1_PORTADO "
	_oSQL:_sQuery += " 	FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " 	WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 	AND SE1.E1_SALDO > 0 "
	_oSQL:_sQuery += " 	AND SE1.E1_TIPO NOT IN ('NCC', 'RA') "
	_oSQL:_sQuery += " 	AND SE1.E1_VENCREA >= '20230906' "
	_oSQL:_sQuery += " 	GROUP BY SE1.E1_FILIAL "
	_oSQL:_sQuery += " 			,SE1.E1_PORTADO) "
	_oSQL:_sQuery += " ORDER BY FILIAL, PERCENTUAL DESC "
	_oSQL:Log ()
	_aDados := _oSQL:Qry2Array ()

	For _x := 1 to Len(_aDados)


		oSection1:Cell("COLUNA1")	:SetBlock   ({|| _aDados[_x, 1] }) 
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _aDados[_x, 2] }) 
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| _aDados[_x, 3] }) 
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| _aDados[_x, 4] }) 
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| _aDados[_x, 5] }) 
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| _aDados[_x, 6] }) 
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| _aDados[_x, 7] }) 
		oSection1:Cell("COLUNA8")	:SetBlock   ({|| _aDados[_x, 8] }) 
		
		oSection1:PrintLine()
	Next

	oSection1:Finish()
Return


// #include "rwmake.ch"
// #include "fivewin.ch"
// #include "topconn.ch"
// #include "PROTHEUS.CH"
// #include "TBICONN.CH"
// #include "COLORS.CH"
// #include "FWPrintSetup.ch"
// #include "RPTDEF.CH"

// #IFNDEF WINDOWS
//     #DEFINE PSAY SAY
// #ENDIF

// User function ML_GARANTIAS()
// 	cPerg   := "ML_GARANTIAS"
    	
//     _ValidPerg()
//     if Pergunte(cPerg,.T.)
// 		if mv_par01 = 2  // se opcao email - executa rotina em separa para leitura da query
// 			// gera PDF e manda por email					
// 			_GeraPDF_Email()
// 		else
// 			// relatorio normal
//     		RptStatus({|| RptDetail()})
// 		endif    		
// 	endif
// Return
// //
// // --------------------------------------------------------------------------------------------
// Static Function RptDetail()

// 	cString := "SE1"
//     cDesc1  := "Resumo por Portador Cobran�a/Garantias"
// 	cDesc2  := ""
// 	cDesc3  := ""
// 	tamanho := "G"
// 	aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
// 	aLinha  := {}
// 	nLastKey:= 0
// 	wnrel   := "ML_GARANTIAS"
// 	nTipo   := 0
// 	titulo  := "Resumo por Portador Cobran�a/Garantias"
	
// 	wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.,"",,tamanho)
// 	If nLastKey == 27
//    		Return
// 	Endif

// 	SetDefault(aReturn,cString)
// 	If nLastKey == 27
//    		Return
// 	Endif
    
//     SetRegua(LastRec())
//     nTipo := IIF(aReturn[4]==1,15,18)
//     li    := 80
//     m_pag := 1
    
//     cabec1:="FILIAL    PORTADOR                                  QUANTIDADE              VLR.GARANTIA           VLR.SALDO              SOBRA/FALTA    PERCENTUAL"
//     cabec2:="                                                       TITULOS"

// 	_sQuery := ""
// 	_ExeQuery()
//     //u_showmemo(_sQuery)
 	
//     _sAliasQ = GetNextAlias ()
//     DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
//     count to _nRecCount
//     procregua (_nRecCount)
    
//     _aTotFil  = {0,0,0,0,0,0}
//     _aTotGer  = {0,0,0,0,0,0}
//     _FilAnt = ''
    
//     (_sAliasQ) -> (DBGoTop ())

//      Do While ! (_sAliasQ) -> (Eof ())
//  	    IF _FilAnt != "" .and. _FilAnt != (_sAliasQ) -> FILIAL
//             // imprime totais da filial
//             If li>65
//                 cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
//             Endif        
//             @ li,  18 PSAY "TOTAL DA FILIAL --> " + _FilAnt 
//     	    @ li,  54 PSAY _aTotFil[1]   Picture "@E 999999"
// 			@ li,  74 PSAY _aTotFil[2]   Picture "@E 999,999,999.99"
// 			@ li,  94 PSAY _aTotFil[3]   Picture "@E 999,999,999.99"
// 			@ li, 119 PSAY _aTotFil[4]   Picture "@E 999,999,999.99"
// 			@ li, 139 PSAY _aTotFil[5]   Picture "@E 999.99"
// 			li ++					
//     		li ++
    		
//     		_aTotGer[1] += _aTotFil[1] 
//    			_aTotGer[2] += _aTotFil[2] 
//    			_aTotGer[3] += _aTotFil[3]
//    			_aTotGer[4] += _aTotFil[4] 
//    			_aTotGer[5] = 100
    		
//             _aTotFil[1]  := 0
//             _aTotFil[2]  := 0
//             _aTotFil[3]  := 0
//             _aTotFil[4]  := 0
//             _aTotFil[5]  := 100
            
//         Endif

// 	   	If li>65
// 	       	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
// 	   	Endif
	   
//         @ li,  04 PSAY (_sAliasQ) -> FILIAL
//         @ li,  10 PSAY (_sAliasQ) -> PORTADOR
// 		@ li,  18 PSAY (_sAliasQ) -> PORT_DESC
// 		@ li,  55 PSAY (_sAliasQ) -> QUANT_TIT    Picture "@E 999999"
// 		@ li,  75 PSAY (_sAliasQ) -> GARANTIA     Picture "@E 999,999,999.99"
// 		@ li,  95 PSAY (_sAliasQ) -> SALDO        Picture "@E 999,999,999.99"
// 		@ li, 120 PSAY (_sAliasQ) -> SOBRA_FALTA  Picture "@E 999,999,999.99"
// 		@ li, 140 PSAY (_sAliasQ) -> PERCENTUAL   Picture "@E 999.99"
// 		li ++
		
// 		_aTotFil[1] += (_sAliasQ) -> QUANT_TIT
//    		_aTotFil[2] += (_sAliasQ) -> GARANTIA
//    		_aTotFil[3] += (_sAliasQ) -> SALDO
//    		_aTotFil[4] += (_sAliasQ) -> SOBRA_FALTA
//    		_aTotFil[5] = 100 
   		
//    		_FilAnt = (_sAliasQ) -> FILIAL
   		
//     	(_sAliasQ) -> (dbskip())
//      enddo
       	 
//      if _aTotFil[1] > 0
//         // imprime totais da filial  
//         If li>65
//             cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
//         Endif        
//         @ li,  18 PSAY "TOTAL DA FILIAL --> " + _FilAnt
//         @ li,  54 PSAY _aTotFil[1]   Picture "@E 999999"
// 		@ li,  74 PSAY _aTotFil[2]   Picture "@E 999,999,999.99"
// 		@ li,  94 PSAY _aTotFil[3]   Picture "@E 999,999,999.99"
// 		@ li, 119 PSAY _aTotFil[4]   Picture "@E 999,999,999.99"
// 		@ li, 139 PSAY _aTotFil[5]   Picture "@E 999.99"
// 		li ++
// 		li ++
		
// 		_aTotGer[1] += _aTotFil[1] 
//    		_aTotGer[2] += _aTotFil[2] 
//    		_aTotGer[3] += _aTotFil[3]
//    		_aTotGer[4] += _aTotFil[4] 
//    		_aTotGer[5] = 100
   		
//     Endif
    
//     if _aTotGer[1] > 0
//    		If li>65
//            	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
//        	Endif
//     	li ++
//         @ li,  18 PSAY "TOTAL GERAL ---> "
//         @ li,  54 PSAY _aTotGer[1]   Picture "@E 999999"
// 		@ li,  74 PSAY _aTotGer[2]   Picture "@E 999,999,999.99"
// 		@ li,  94 PSAY _aTotGer[3]   Picture "@E 999,999,999.99"
// 		@ li, 119 PSAY _aTotGer[4]   Picture "@E 999,999,999.99"
// 		@ li, 139 PSAY _aTotGer[5]   Picture "@E 999.99"
//     	li ++
//     endif
 
//      Set Device To Screen

//      If aReturn[5]==1
//            Set Printer TO
//            dbcommitAll()
//            ourspool(wnrel)
//      Endif

//      MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)

// Return
// //
// // -------------------------------------------------------------------------------------
// Static Function _ExeQuery()
// 	_sQuery := ""
// 	_sQuery += " WITH C AS ("
// 	_sQuery += " 	SELECT SE1.E1_FILIAL		 AS FILIAL"
//     _sQuery += "  		 , SE1.E1_PORTADO		 AS PORTADOR"
// 	_sQuery += "  		 , SUM(SE1.E1_SALDO)	 AS SALDO"
// 	_sQuery += "  		 , COUNT(SE1.R_E_C_N_O_) AS QUANT_TIT"
//   	_sQuery += " 	  FROM SE1010 AS SE1"
//  	_sQuery += " 	 WHERE SE1.D_E_L_E_T_ = ''"
//    	_sQuery += " 	   AND SE1.E1_SALDO > 0"
//    	_sQuery += " 	   AND SE1.E1_TIPO NOT IN ('NCC', 'RA')"
//    	_sQuery += " 	   AND SE1.E1_VENCREA >= '" + dtos (date()+1) + "'"
// 	_sQuery += "     GROUP BY SE1.E1_FILIAL, SE1.E1_PORTADO)"
// 	_sQuery += " SELECT C.FILIAL, C.PORTADOR"
//     _sQuery += "  	  , ISNULL((SELECT TOP 1 SA6.A6_NOME"
// 	_sQuery += "       			  FROM SA6010 AS SA6"
//     _sQuery += "      			 WHERE SA6.D_E_L_E_T_ = ''"
// 	_sQuery += " 	   			   AND SA6.A6_BLOCKED = '2'"
// 	_sQuery += " 	   			   AND SA6.A6_FILIAL  = C.FILIAL"
// 	_sQuery += " 	   			   AND SA6.A6_COD     = C.PORTADOR"
// 	_sQuery += " 	   			 ORDER BY SA6.R_E_C_N_O_ ) ,'CARTEIRA'  ) AS PORT_DESC"
// 	_sQuery += " 	 , C.QUANT_TIT"
// 	_sQuery += "   	 , ISNULL((SELECT SUM(SA6.A6_GARANT)"
// 	_sQuery += " 			 	 FROM SA6010 AS SA6"
// 	_sQuery += " 				WHERE SA6.D_E_L_E_T_ = ''"
// 	_sQuery += " 		      	  AND SA6.A6_FILIAL  = C.FILIAL"
// 	_sQuery += " 			  	  AND SA6.A6_BLOCKED = '2'"
// 	_sQuery += " 			      AND SA6.A6_COD     = C.PORTADOR ),0) AS GARANTIA"
//     _sQuery += " 	 , C.SALDO"
// 	_sQuery += " 	 , C.SALDO - ISNULL((SELECT SUM(SA6.A6_GARANT)"
// 	_sQuery += " 			 			   FROM SA6010 AS SA6"
// 	_sQuery += " 						  WHERE SA6.D_E_L_E_T_ = ''"
// 	_sQuery += " 		      				AND SA6.A6_FILIAL  = C.FILIAL"
// 	_sQuery += " 			  				AND SA6.A6_BLOCKED = '2'"
// 	_sQuery += " 			  				AND SA6.A6_COD     = C.PORTADOR ),0) AS SOBRA_FALTA"
//     _sQuery += "  	, ROUND(C.SALDO /(SUM(C.SALDO) OVER (PARTITION BY FILIAL))*100,2) AS PERCENTUAL"
// 	_sQuery += "  	, SUM(C.SALDO) OVER (PARTITION BY FILIAL) AS TOT_FILIAL"
// 	_sQuery += " FROM C"
// 	_sQuery += " ORDER BY C.FILIAL, ROUND(C.SALDO /(SUM(C.SALDO) OVER (PARTITION BY FILIAL))*100,2) DESC"
	
// Return
// //
// // -------------------------------------------------------------------------------------
// Static Function _GeraPDF_Email()

// 	Private _oSQL        := ClsSQL():New ()
// 	Private oPrint       := TMSPrinter():New(OemToAnsi(''))
// 	Private oBrush       := TBrush():New(,4)
// 	Private oPen         := TPen():New(0,5,CLR_BLACK)
// 	Private oFont12n     := TFont():New('Tahoma',12,12,,.T.,,,,.T.,.F.)
// 	Private oFont13      := TFont():New('Tahoma',13,13,,.T.,,,,.T.,.F.)
// 	Private oFont22      := TFont():New('Arial',22,22,,.T.,,,,.T.,.F.)
// 	Private nLinha       := 0
	
// 	// se nao existir a pasta cria e add ao _cPathPDF
// 	cDestino := "\sigaadv\"
// 	makedir (cDestino)
// 	_cPathPDF := "S:\Protheus12\protheus_data\sigaadv\"
	
// 	_cFile := "Cobranca"
// 	delete file(cDestino + _cFile)
	
// 	// define objeto
// 	oPrint := FWMSPrinter():New(_cFile, IMP_PDF, .T., , .T.)
// 	oPrint:SetResolution(72)
// 	oPrint:SetLandscape()
// 	oPrint:SetPaperSize(DMPAPER_A4)
// 	oPrint:SetMargin(60,60,60,60) // nEsquerda, nSuperior, nDireita, nInferior
// 	oPrint:cPathPDF := _cPathPDF // Caso seja utilizada impress�o em IMP_PDF

// 	nLinha   := 4000
// 	_aTotFil = {0,0,0,0,0,0,0,0,0,0,0,0}
// 	_aTotGer = {0,0,0,0,0,0,0,0,0,0,0,0}
// 	_wpag    := 0
	
// 	_sQuery := ""
// 	_ExeQuery()
// 	_sAliasQ = GetNextAlias ()
// 	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
	
// 	_FilAnt = ""	    	
// 	(_sAliasQ) -> (DBGoTop ())
//  	do while ! (_sAliasQ) -> (Eof ())
// 		// imprime cabe�alho
// 		IF _FilAnt != "" .and. _FilAnt != (_sAliasQ) -> FILIAL
//             // imprime totais da filial
//             If (nLinha/50) > 46
// 	   			_wpag += 1	
//        			xCabec()
//        			nlinha := 600
//     		Endif
//          	if _aTotFil[1] > 0
// 			    oPrint:Say(nLinha,0270, "TOTAL FILIAL   --> " + _FilAnt			        ,oFont12n)
// 			    oPrint:Say(nLinha,0995, TransForm( _aTotGer[1]   , '@E 999999') 		,oFont12n)
// 			    oPrint:Say(nLinha,1320, TransForm( _aTotGer[2]   , '@E 999,999,999.99')	,oFont12n)
// 			    oPrint:Say(nLinha,1660, TransForm( _aTotGer[3]   , '@E 999,999,999.99')	,oFont12n)
// 			    oPrint:Say(nLinha,2090, TransForm( _aTotGer[4]   , '@E 999,999,999.99')	,oFont12n)
// 			    oPrint:Say(nLinha,2325, TransForm( _aTotGer[5]   , '@E 999,999,999.99')	,oFont12n)
// 			    nLinha += 50 // linha em branco
// 			    nLinha += 50
			    
// 		    endif
            
//             _aTotGer[1] += _aTotFil[1] 
//    			_aTotGer[2] += _aTotFil[2] 
//    			_aTotGer[3] += _aTotFil[3]
//    			_aTotGer[4] += _aTotFil[4] 
//    			_aTotGer[5] = 100
    		
//             _aTotFil[1]  := 0
//             _aTotFil[2]  := 0
//             _aTotFil[3]  := 0
//             _aTotFil[4]  := 0
//             _aTotFil[5]  := 100
            
//         Endif
//         If (nLinha/50) > 46
//    			_wpag += 1	
//    			xCabec()
//    			nlinha := 600
// 		Endif
// 		// monta linha para impressao
//  		oPrint:Say(nLinha,0045, (_sAliasQ) -> FILIAL	  	 				            ,oFont12n)
// 		oPrint:Say(nLinha,0195, (_sAliasQ) -> PORTADOR 			  					    ,oFont12n)
//        	oPrint:Say(nLinha,0270, PORT_DESC 	 			  					    		,oFont12n)
//        	oPrint:Say(nLinha,0995, TransForm( (_sAliasQ) -> QUANT_TIT   , '@E 999999') 	,oFont12n)
//        	oPrint:Say(nLinha,1320, TransForm( (_sAliasQ) -> GARANTIA    , '@E 999,999,999.99') ,oFont12n)
//        	oPrint:Say(nLinha,1660, TransForm( (_sAliasQ) -> SALDO       , '@E 999,999,999.99') ,oFont12n)
//        	oPrint:Say(nLinha,2090, TransForm( (_sAliasQ) -> SOBRA_FALTA , '@E 999,999,999.99') ,oFont12n)
//        	oPrint:Say(nLinha,2325, TransForm( (_sAliasQ) -> PERCENTUAL  , '@E 999,999,999.99') ,oFont12n)	
//        	nLinha += 50
       	
       	
//        	// acumula totais
//        	_aTotFil[1] += (_sAliasQ) -> QUANT_TIT
//    		_aTotFil[2] += (_sAliasQ) -> GARANTIA
//    		_aTotFil[3] += (_sAliasQ) -> SALDO
//    		_aTotFil[4] += (_sAliasQ) -> SOBRA_FALTA
//    		_aTotFil[5] = 100 
   		
//    		_FilAnt = (_sAliasQ) -> FILIAL
   		
//        	// le o proximo
// 		(_sAliasQ) -> (dbskip())
// 	enddo
	
//     nLinha += 50 // linha em branco
//     // imprime total da filial
//     If (nLinha/50) > 46
// 	   _wpag += 1	
//        xCabec()
//        nlinha := 600
//     Endif
    
//     if _aTotFil[1] > 0
// 	    oPrint:Say(nLinha,0270, "TOTAL FILIAL   --> " + _FilAnt			        ,oFont12n)
// 	    oPrint:Say(nLinha,0995, TransForm( _aTotGer[1]   , '@E 999999') 		,oFont12n)
// 	    oPrint:Say(nLinha,1320, TransForm( _aTotGer[2]   , '@E 999,999,999.99')	,oFont12n)
// 	    oPrint:Say(nLinha,1660, TransForm( _aTotGer[3]   , '@E 999,999,999.99')	,oFont12n)
// 	    oPrint:Say(nLinha,2090, TransForm( _aTotGer[4]   , '@E 999,999,999.99')	,oFont12n)
// 	    oPrint:Say(nLinha,2325, TransForm( _aTotGer[5]   , '@E 999,999,999.99')	,oFont12n)
// 	    nLinha += 50 // linha em branco
//         nLinha += 50
        
// 	    _aTotGer[1] += _aTotFil[1] 
// 		_aTotGer[2] += _aTotFil[2] 
// 		_aTotGer[3] += _aTotFil[3]
// 		_aTotGer[4] += _aTotFil[4] 
// 		_aTotGer[5] = 100
// 	endif 
    
//     if _aTotGer[1] > 0
//     	If (nLinha/50) > 46
// 		   _wpag += 1	
// 	       xCabec()
// 	       nlinha := 600
// 	    Endif
    
// 	    oPrint:Say(nLinha,0270, "TOTAL GERAL   --> "					        ,oFont12n)
// 	    oPrint:Say(nLinha,0995, TransForm( _aTotGer[1]   , '@E 999999') 		,oFont12n)
// 	    oPrint:Say(nLinha,1320, TransForm( _aTotGer[2]   , '@E 999,999,999.99')	,oFont12n)
// 	    oPrint:Say(nLinha,1660, TransForm( _aTotGer[3]   , '@E 999,999,999.99')	,oFont12n)
// 	    oPrint:Say(nLinha,2090, TransForm( _aTotGer[4]   , '@E 999,999,999.99')	,oFont12n)
// 	    oPrint:Say(nLinha,2325, TransForm( _aTotGer[5]   , '@E 999,999,999.99')	,oFont12n)
// 	    nLinha += 50 // linha em branco
	    
//     endif
    
//     // finaliza impressao
//     oPrint:EndPage()
// 	oPrint:Preview() //abre o PDF na tela
	
// 	// gera o arquivo em PDF
// 	CpyT2S(_cPathPDF +_cFile+ ".PDF", cDestino)
// 	_sCtaMail  := "envio.comissoes"
    
//     _sMailDest := 'financeiro@novaalianca.coop.br'
//     U_SendMail (_sMailDest, "Resumo por Portador Cobran�a/Garantias", "", {cDestino + _cFile + ".PDF"}, _sCtaMail)
    
//     _sMailDest := 'rodrigo.colleoni@novaalianca.coop.br'
//     U_SendMail (_sMailDest, "Resumo por Portador Cobran�a/Garantias", "", {cDestino + _cFile + ".PDF"}, _sCtaMail)
    
//     _sMailDest := 'rita.correa@novaalianca.coop.br'
//     U_SendMail (_sMailDest, "Resumo por Portador Cobran�a/Garantias", "", {cDestino + _cFile + ".PDF"}, _sCtaMail)
    
// Return
// //
// // -------------------------------------------------------------------------------------
// Static Function xCabec()
// 	oPrint:StartPage()
// 	oPrint:Say(0300,1000,OemToAnsi('Resumo por Portador Cobran�a/Garantias'),oFont22)
// 	oPrint:Line(0350,00045,0350,2850)
// 	oPrint:Say(0400,0045,OemToAnsi('FILIAL    PORTADOR                                  QUANTIDADE              VLR.GARANTIA           VLR.SALDO              SOBRA/FALTA    PERCENTUAL'),oFont13)
//     oPrint:Say(0430,0045,OemToAnsi('                                                       TITULOS'                                                                                     ),oFont13)
// Return
// // --------------------------------------------------------------------------
// // Cria Perguntas no SX1
// Static Function _ValidPerg ()
//     local _aRegsPerg := {}
//     //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
//     aadd (_aRegsPerg, {01, "Op��o                        ?", "N", 1,  0,  "",   "   ", {"Relatorio","Email"},   ""})
//     U_ValPerg (cPerg, _aRegsPerg)
// Return
