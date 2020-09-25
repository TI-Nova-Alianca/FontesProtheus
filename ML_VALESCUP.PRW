// Programa..: ML_VALESCUP
// Autor.....: Catia Cardoso
// Data......: 26/03/2018
// Nota......: Vales Presentes em CUPONS 
//
// Historico de alteracoes:
// 28/06/2018 - Catia   - Alterado para que considere apenas CUPONS (venda efetivada) e não liste orçamentos pendentes a faturar
// 18/12/2018 - Sandra  - Alterado para considerar data da emissão da nota fiscal e não do orçamento
// 30/06/2020 - Cláudia - Incluido campos de cliente/nome e numero do vale. GLPI: 8108
//                        Alterado modelo para TREPORT, com opção de geração em planilha excel e PDF
//
// ------------------------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#include "report.ch"
#include "rwmake.ch"
#include 'topconn.CH'

User function ML_VALESCUP()
	Private oReport
	Private cPerg   := "ML_VALESCUP"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// -------------------------------------------------------------------------
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	Local oFunction

	oReport := TReport():New("ML_VALESCUP","Vales Presentes em CUPONS ",cPerg,{|oReport| PrintReport(oReport)},"Vales Presentes em CUPONS ")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	//oReport:SetLandScape()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"		,	    				, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Emissão"		,       				,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Hora"			,       				,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Nº Orçamento"	,						,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Nº Cupom"		,						,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Cliente/Loja"	,						,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Nome"			,						,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Nº Vale"		,						,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Situação"		,						,12,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA10", 	"" ,"Vlr.Bruto"		, "@E 999,999,999.99"   ,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUNA11", 	"" ,"Vlr.Vale"		, "@E 999,999,999.99"   ,30,/*lPixel*/,{|| 	},"RIGHT",,"RIGHT",,,,,,.F.)
	
	TRFunction():New(oSection1:Cell("COLUNA10") ,"Vlr.Bruto", "SUM",,,"@E 999,999,999.99",,.F.,.T.)
	TRFunction():New(oSection1:Cell("COLUNA11") ,"Vlr.Vale" , "SUM",,,"@E 999,999,999.99",,.F.,.T.)

Return(oReport)
//
// -------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local _oSQL      := ClsSQL ():New ()

	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += " 	   SL1.L1_FILIAL AS FILIAL"
	_oSQL:_sQuery += "    ,SL1.L1_EMISNF AS EMISSAO"
	_oSQL:_sQuery += "    ,SL1.L1_HORA AS HORA"
	_oSQL:_sQuery += "    ,SL1.L1_NUM AS ORCAMENTO"
	_oSQL:_sQuery += "    ,SL1.L1_DOC AS CUPOM"
	_oSQL:_sQuery += "    ,SL1.L1_CLIENTE AS CLIENTE"
	_oSQL:_sQuery += "    ,SL1.L1_LOJA AS LOJA"
	_oSQL:_sQuery += "    ,SA1.A1_NOME AS NOME"
	_oSQL:_sQuery += "    ,SL4.L4_NUMCART AS NUMVALE"
	_oSQL:_sQuery += "    ,SL1.L1_SITUA AS SITUACAO"
	_oSQL:_sQuery += "    ,SL1.L1_VALES AS VLRVALE"
	_oSQL:_sQuery += "    ,SL1.L1_VALBRUT AS VALORBRT   "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SL1") + " SL1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON (SA1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND SA1.A1_COD = SL1.L1_CLIENTE"
	_oSQL:_sQuery += " 			AND SA1.A1_LOJA = SL1.L1_LOJA)"
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SL4") + " SL4 "
	_oSQL:_sQuery += " 	ON (SL4.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND SL4.L4_FILIAL = SL1.L1_FILIAL"
	_oSQL:_sQuery += " 			AND SL4.L4_NUM = SL1.L1_NUM"
	_oSQL:_sQuery += " 			AND SL4.L4_FORMA = 'VP')"
	_oSQL:_sQuery += " WHERE SL1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND SL1.L1_EMISNF BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_oSQL:_sQuery += " AND SL1.L1_FILIAL BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
	_oSQL:_sQuery += " AND SL1.L1_VALES > 0"
	_oSQL:_sQuery += " AND SL1.L1_DOC != ''"
	_oSQL:_sQuery += " ORDER BY SL1.L1_NUM"
	
	_sAliasQ := _oSQL:Qry2Trb (.f.)
	(_sAliasQ) -> (dbgotop ())
	
	oSection1:Init()
	oSection1:SetHeaderSection(.T.)
			
	While !(_sAliasQ) -> (eof ())
		_sCliente :=  alltrim((_sAliasQ) -> CLIENTE) +'/'+  (_sAliasQ) -> LOJA
		_dt :=  DTOC(STOD((_sAliasQ) -> EMISSAO))
		
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| (_sAliasQ) -> FILIAL   	})
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| _dt						})
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| (_sAliasQ) -> HORA 		})
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| (_sAliasQ) -> ORCAMENTO	})
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| (_sAliasQ) -> CUPOM		})
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| _sCliente					})
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| (_sAliasQ) -> NOME 		})
		oSection1:Cell("COLUNA8")	:SetBlock   ({|| (_sAliasQ) -> NUMVALE		})
		oSection1:Cell("COLUNA9")	:SetBlock   ({|| (_sAliasQ) -> SITUACAO		})
		oSection1:Cell("COLUNA10")	:SetBlock   ({|| (_sAliasQ) -> VLRVALE		})
		oSection1:Cell("COLUNA11")	:SetBlock   ({|| (_sAliasQ) -> VALORBRT		})

		oSection1:PrintLine()
		
		(_sAliasQ) -> (dbskip ())
	Enddo
	oSection1:Finish()
	(_sAliasQ) -> (dbclosearea ())
Return
// -------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      				Help
	aadd (_aRegsPerg, {01, "Emissao Cupom de   ?", "D",  8, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {02, "Emissao Cupom até  ?", "D",  8, 0,  "",   "   ", {},                         ""})
	aadd (_aRegsPerg, {03, "Filial de          ?", "C", 2,  0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {04, "Filial até         ?", "C", 2,  0,  "",   "SM0", {},                         ""})
    
     U_ValPerg (cPerg, _aRegsPerg)
Return





//#include "rwmake.ch"
//#IFNDEF WINDOWS
//	#DEFINE PSAY SAY
//#ENDIF
//
//User Function ML_VALESCUP()
//
//	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
//	delete file (_sArqLog)
//
//    cString := "SL1"
//    cDesc1  := "Vales Presentes em CUPONS"
//    cDesc2  := " "
//    cDesc3  := " "
//    tamanho := "G"
//    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
//    aLinha  := {}
//    nLastKey:= 0
//    cPerg   := "ML_VALESCUP"
//    titulo  := "Vales Presentes em CUPONS"
//    wnrel   := "ML_VALESCUP"
//    nTipo   := 0
//
//    _ValidPerg()
//    Pergunte(cPerg,.T.)
//
//    wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
//
//    If nLastKey == 27
//	   Return
//    Endif
//    SetDefault(aReturn,cString)
//    If nLastKey == 27
//	   Return
//    Endif
//
//    RptStatus({|| RptDetail()})
//Return
//
//Static Function RptDetail()
//
//    SetRegua(LastRec())
//
//    nTipo := IIF(aReturn[4]==1,15,18)
//    li    := 80
//    m_pag := 1
//    cabec1 := " FILIAL    EMISSAO        HORA     ORÇAMENTO    CUPOM     SITUAÇAO                           VALOR BRUTO           VALOR VALE"
//    cabec2 := ""
//    
//    _sQuery := " "
//    _sQuery += " SELECT SL1.L1_FILIAL AS FILIAL, SL1.L1_EMISNF AS EMISSAO, SL1.L1_HORA AS HORA, SL1.L1_NUM AS NUMERO"
//    _sQuery += "      , SL1.L1_DOC AS CUPOM, SL1.L1_VALBRUT AS VALOR, SL1.L1_SITUA AS SITUACAO, SL1.L1_VALES AS VALE"
//    _sQuery += "   FROM SL1010 AS SL1"
// 	_sQuery += "  WHERE SL1.D_E_L_E_T_ = ''"
//   	_sQuery += "    AND SL1.L1_EMISNF BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
//   	_sQuery += "    AND SL1.L1_FILIAL  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
//   	_sQuery += "    AND SL1.L1_VALES >0"
//   	_sQuery += "    AND SL1.L1_DOC !=''"
//    _sQuery += " ORDER BY SL1.L1_NUM"
//
//    u_log (_sQuery)
//    _sAliasQ = GetNextAlias ()
//    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
//    count to _nRecCount
//    procregua (_nRecCount)
//    
//    _aTotVenda  = {0,0,0,0,0,0}
//    (_sAliasQ) -> (DBGoTop ())
//    Do While ! (_sAliasQ) -> (Eof ())
//    	If li>58
//	       cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
//	    Endif
//	    
//	    @ li, 002 PSAY (_sAliasQ) -> FILIAL
//	    @ li, 011 PSAY stod((_sAliasQ) -> EMISSAO)
//	    @ li, 026 PSAY (_sAliasQ) -> HORA
//	    @ li, 038 PSAY (_sAliasQ) -> NUMERO
//	    @ li, 048 PSAY (_sAliasQ) -> CUPOM
//	    @ li, 058 PSAY (_sAliasQ) -> SITUACAO
//	    @ li, 088 PSAY (_sAliasQ) -> VALOR  Picture "@E 9,999,999,999.99"
//    	@ li, 108 PSAY (_sAliasQ) -> VALE   Picture "@E 9,999,999,999.99"
//	    li ++
//       	_aTotVenda [1] += (_sAliasQ) -> VALOR
//       	_aTotVenda [2] += (_sAliasQ) -> VALE
//       	
//	 	(_sAliasQ) -> (dbskip())
//     enddo
//	 
//	 li ++      
//     If li>58
//     	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
//     Endif  
//     li ++
//	 @ li, 005 PSAY "TOTAIS:"
//	 @ li, 088 PSAY _aTotVenda[1] Picture "@E 9,999,999,999.99"
//	 @ li, 108 PSAY _aTotVenda[2] Picture "@E 9,999,999,999.99"
//	 li ++
// 	 U_ImpParam (58)
//	      
//     Set Device To Screen
//
//     If aReturn[5]==1
//	       Set Printer TO
//	       dbcommitAll()
//	       ourspool(wnrel)
//     Endif
//
//     MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)
//
//return
//// --------------------------------------------------------------------------
//// Cria Perguntas no SX1
//Static Function _ValidPerg ()
//	local _aRegsPerg := {}
//	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
//	aadd (_aRegsPerg, {01, "Emis de Cupom         ?", "D",  8, 0,  "",   "   ", {},                         ""})
//	aadd (_aRegsPerg, {02, "Emis ate Cupom        ?", "D",  8, 0,  "",   "   ", {},                         ""})
//	aadd (_aRegsPerg, {03, "Filial de          ?", "C", 2,  0,  "",   "SM0", {},                         ""})
//    aadd (_aRegsPerg, {04, "Filial até         ?", "C", 2,  0,  "",   "SM0", {},                         ""})
//    
//   	U_ValPerg (cPerg, _aRegsPerg)
//Return