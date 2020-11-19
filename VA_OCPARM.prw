///////////////////////////////////////////////////////////////////////////////////////////////////
// Relatório para Logístia para acompanhameno de taxa de ocuoação de armazem por rua e andar     //
// 12/08/2014 - Bruno Silva														           	     //
///////////////////////////////////////////////////////////////////////////////////////////////////

#include "protheus.ch"
#include "report.ch"    
#include "topconn.ch"    
#INCLUDE "COLORS.CH"
#INCLUDE "TBICONN.CH"
#include "rwmake.ch"

User Function VA_OCPARM() 

Local oReport
//Local oSection1
//Local oBreak

Private cPerg := "VA_OCPARM" 

//_ValidPerg()
If TRepInUse()                
	Pergunte(cPerg,.F.)	
	oReport := ReportDef()
	oReport:PrintDialog()	
EndIf
Return

Static Function ReportDef()
	Local oReport
	Local oSection1
	//Local oBreak
	Local cTitulo := "Ocupação Armazem"
	
	oReport := TReport():New(cPerg,cTitulo,'',{|oReport| PrintReport(oReport)},cTitulo)
	oReport:SetPortrait() 
	oReport:SetTotalInLine(.F.)
	//	oReport:cFontBody := "Arial" 
	//oreport:nfontbody := 8
	
	oSection1 := TRSection():New(oReport,"Armazem",{"SBF"})
	//oSection1:SetTotalInLine(.T.)
	
	TRCell():New(oSection1,"_RUA","         ","Rua",                /*Picture*/      	,05,/*lPixel*/,{||   	},"LEFT",,,,,,,,.T.)
	TRCell():New(oSection1,"END_OCUP","     ","End.Ocupados", 	    /*Picture*/    		,15,/*lPixel*/,{||		},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"END_RUA"," 	    ","End.Por Rua",     	"@E 999.99"    		,15,/*lPixel*/,{|| 		},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"OCUP_RUA"," 	","%Ocup.Por Rua",     	/*Picture*/    		,15,/*lPixel*/,{|| 		},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"END_ANDAR"," 	","End.Por Andar",     /*Picture*/    		,16,/*lPixel*/,{|| 		},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"1_ANDAR"," 	    ","%1ºAndar",			"@E 999.99"    		,12,/*lPixel*/,{||  	},"RIGHT",,"RIGHT",,,,,,.T.)	                                   	
	TRCell():New(oSection1,"2_ANDAR"," 	    ","%2ºAndar",			"@E 999.99"    		,12,/*lPixel*/,{||  	},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"3_ANDAR"," 	    ","%3ºAndar",			"@E 999.99"    		,12,/*lPixel*/,{||  	},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"4_ANDAR"," 	    ","%4ºAndar",			"@E 999.99"    		,12,/*lPixel*/,{||  	},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"5_ANDAR"," 	    ","%5ºAndar",			"@E 999.99"    		,12,/*lPixel*/,{||  	},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"6_ANDAR"," 	    ","%6ºAndar",			"@E 999.99"    		,12,/*lPixel*/,{||  	},"RIGHT",,"RIGHT",,,,,,.T.)
	TRCell():New(oSection1,"7_ANDAR"," 	    ","%7ºAndar",			"@E 999.99"    		,12,/*lPixel*/,{||  	},"RIGHT",,"RIGHT",,,,,,.T.)
	 
 	//oBreak := TRBreak():New(oSection1,oSection1:Cell("BF_PRODUTO"),"Produto")     
 	
 	TRFunction():New(oSection1:Cell("END_OCUP")	 ,,"SUM"	   ,/*oBreak*/ ,"Total End. Ocupados" ,"@E 999,999",NIL, .F., .T.)	                                 
 	TRFunction():New(oSection1:Cell("END_RUA")   ,,"SUM"	   ,/*oBreak*/ ,"Total End. Por Rua"  ,"@E 999,999",NIL, .F., .T.)
 	//TRFunction():New(oSection1:Cell("OCUP_RUA")	 ,,"AVERAGE"   ,/*oBreak*/ ,"Ocup. Por Rua."     ,"@E 999.99",NIL, .F., .T.)
 	//TRFunction():New(oSection1:Cell("END_ANDAR")   ,,"SUM"	   ,/*oBreak*/ ,"Total End. Por Rua"  ,"@E 999,999",NIL, .F., .T.)
 	//           New(oCell,cName,cFunction,oBreak,cTitle,cPicture,uFormula,lEndSection,lEndReport,lEndPage,oParent,bCondition,lDisable,bCanPrint)
      
Return oReport

Static Function PrintReport(oReport)
local _nI		:= 0
private _sQuery := ""

_sQuery := " SELECT SUBSTRING(BF_LOCALIZ, 1, 1) AS RUA, COUNT(BF_PRODUTO) AS END_OCUP "  
_sQuery += " FROM "+ RetSQLName("SBF") + " SBF "
_sQuery += " WHERE SBF.D_E_L_E_T_ = '' " 
_sQuery += " AND BF_FILIAL = '"+ xFilial("SBF") +"' " 
_sQuery += " AND BF_ESTFIS <> '' "
_sQuery += " AND SUBSTRING(BF_LOCALIZ, 1, 1) BETWEEN 'A' AND 'K' "
_sQuery += " AND SUBSTRING(BF_LOCALIZ, 2, 1) <= '9' "
_sQuery += " GROUP BY SUBSTRING(BF_LOCALIZ, 1, 1) ORDER BY SUBSTRING(BF_LOCALIZ, 1, 1) "

DbUseArea(.T., "TOPCONN", TCGenQry(,,_sQuery) , "TRB", .F., .T.)
DbSelectArea("TRB")
oSection1 := oReport:Section(1)
oSection1:Init()
oReport:SetMeter(LastRec("TRB"))

_nTotOcup := 0
_nTotRua  := 0

While !EOF()  
	
	oSection1:Cell("_RUA")	        :SetBlock({|| TRB->RUA})		
	oSection1:Cell("END_OCUP")		:SetBlock({|| TRB->END_OCUP})
	_END_RUA := IIF(TRB->RUA = 'A',280,560)
	oSection1:Cell("END_RUA") 		:SetBlock({|| _END_RUA	 })
	_nTotRua  += _END_RUA
	_nTotOcup += END_OCUP	
	OCUP_RUA := Round(TRB->END_OCUP / _END_RUA * 100,2)	
		
	oSection1:Cell("OCUP_RUA") 	:SetBlock({|| OCUP_RUA })
	
	_END_ANDAR := IIF(TRB->RUA = 'A',40,80)
	
	oSection1:Cell("END_ANDAR")      :SetBlock({|| _END_ANDAR  })
	
	// SELECT ANDARES	
	_1ANDAR := 0 
	_2ANDAR := 0 
	_3ANDAR := 0 
	_4ANDAR := 0 
	_5ANDAR := 0
	_6ANDAR := 0 
	_7ANDAR := 0   
	
	_sQuery := " SELECT SUBSTRING(BF_LOCALIZ, 1, 1) AS RUA, COUNT(BF_PRODUTO) AS END_OCUP, SUBSTRING(BF_LOCALIZ, 4, 2) AS ANDAR "  
	_sQuery += " FROM "+ RetSQLName("SBF") + " SBF "
	_sQuery += " WHERE SBF.D_E_L_E_T_ = '' " 
	_sQuery += " AND BF_FILIAL = '"+ xFilial("SBF") +"' " 
	_sQuery += " AND BF_ESTFIS <> '' "
	_sQuery += " AND SUBSTRING(BF_LOCALIZ, 1, 1) = '"+ TRB->RUA +"' "
	_sQuery += " AND SUBSTRING(BF_LOCALIZ, 2, 1) <= '9' "
	_sQuery += " GROUP BY SUBSTRING(BF_LOCALIZ, 1, 1),SUBSTRING(BF_LOCALIZ, 4, 2) ORDER BY SUBSTRING(BF_LOCALIZ, 1, 1) "	
	_aAndar := U_Qry2Array(_sQuery)  
	For _nI := 1 to Len(_aAndar)
		DO CASE
			Case _aAndar[_nI, 3 ] = '01'
				_1ANDAR := _aAndar[_nI, 2 ]
			Case _aAndar[_nI, 3 ] = '02'
				_2ANDAR := _aAndar[_nI, 2 ]
			Case _aAndar[_nI, 3 ] = '03'
				_3ANDAR := _aAndar[_nI, 2 ]
			Case _aAndar[_nI, 3 ] = '04'
				_4ANDAR := _aAndar[_nI, 2 ]
			Case _aAndar[_nI, 3 ] = '05'
				_5ANDAR := _aAndar[_nI, 2 ]
			Case _aAndar[_nI, 3 ] = '06'
				_6ANDAR := _aAndar[_nI, 2 ]
			Case _aAndar[_nI, 3 ] = '07'
				_7ANDAR := _aAndar[_nI, 2 ]									
		ENDCASE
	Next 
	
	oSection1:Cell("1_ANDAR")      	:SetBlock({|| Round(_1ANDAR / _END_ANDAR * 100,2) })
	oSection1:Cell("2_ANDAR")      	:SetBlock({|| Round(_2ANDAR / _END_ANDAR * 100,2) })
	oSection1:Cell("3_ANDAR")      	:SetBlock({|| Round(_3ANDAR / _END_ANDAR * 100,2) })
	oSection1:Cell("4_ANDAR")      	:SetBlock({|| Round(_4ANDAR / _END_ANDAR * 100,2) })
	oSection1:Cell("5_ANDAR")      	:SetBlock({|| Round(_5ANDAR / _END_ANDAR * 100,2) })
	oSection1:Cell("6_ANDAR")      	:SetBlock({|| Round(_6ANDAR / _END_ANDAR * 100,2) })
	oSection1:Cell("7_ANDAR")      	:SetBlock({|| Round(_7ANDAR / _END_ANDAR * 100,2) })                        
				
	oSection1:PrintLine()
	oReport:IncMeter()  
				
	DbSelectArea("TRB")
	dbSkip()	
EndDo		
		
	//Imprime total Gerat	
	_nTOT := NoRound(_nTotOcup / _nTotRua * 100)
	_nTOT := TRANSFORM(_nTOT, "@E 999,99")  
	oReport:SkipLine()	
	oReport:Say(oReport:Row(),10, "% de Ocupação Total: "+ _nTOT)
	oReport:SkipLine()		   
  	oSection1:Finish() 
  	
  	DbSelectArea("TRB")
    dbCloseArea()
Return		     

// Static Function _ValidPerg ()
// 	local _aRegsPerg := {}
	
// 	//                     PERGUNT                TIPO TAM DEC VALID  F3    Opcoes                        Help   
// 	aadd (_aRegsPerg, {01, "Endereço de ?",		  "C", 04, 0,  "",   "SBE", {},                           ""})  
// 	aadd (_aRegsPerg, {02, "Endereço até ?", 	  "C", 04, 0,  "",   "SBE", {},                           ""})
//    	//aadd (_aRegsPerg, {03, "Recurso	?",           "C", 08, 0,   "",   "SH1", {},                           ""})   	
//   	//aadd (_aRegsPerg, {04, "Tipo Produto de ?",   "C", 02, 0,   "",   "02", {},                           ""})
	
// 	U_ValPerg (cPerg, _aRegsPerg)
// Return
