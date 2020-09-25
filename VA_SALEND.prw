// Programa:  VA_SALEND
// Autor:     Cláudia Lionço
// Data:      20/03/2020
// Descricao: Relatorio de saldos a endereçar. GLPI: 7678
//
// Historico de alteracoes:
//
// ---------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_SALEND()
	Private oReport

	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// ------------------------------------------------------------------------------
Static Function ReportDef()
	Local oReport   := Nil
	Local oSection1 := Nil
	Local oFunction

	oReport := TReport():New("VA_SALEND","Relatorio de saldos a endereçar",,{|oReport| PrintReport(oReport)},"Relatorio de saldos a endereçar")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetPortrait()
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Filial"	,	    				, 8,/*lPixel*/,{||  },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Produto"	,       				,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Descrição"	,       				,40,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Saldo"		,						,15,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Local"		,						,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Documento"	,						,20,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Data"		,						,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Situação"	,						, 8,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	
Return(oReport)
//
// ------------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local _oSQL     := NIL

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += " 	DA_FILIAL AS FILIAL"
	_oSQL:_sQuery += "    ,DA_PRODUTO AS PRODUTO"
	_oSQL:_sQuery += "    ,B1.B1_DESC AS DESCRICAO"
	_oSQL:_sQuery += "    ,DA_SALDO AS SALDO"
	_oSQL:_sQuery += "    ,DA_LOCAL AS LOC"
	_oSQL:_sQuery += "    ,DA_DOC AS DOCUMENTO"
	_oSQL:_sQuery += "    ,CONVERT(SMALLDATETIME, DA_DATA) AS DTA"
	_oSQL:_sQuery += "    ,CASE"
	_oSQL:_sQuery += " 		WHEN MONTH(GETDATE()) = MONTH(CONVERT(SMALLDATETIME, DA_DATA)) THEN 'OK'"
	_oSQL:_sQuery += " 		ELSE 'ERRO'"
	_oSQL:_sQuery += " 	END AS MES_ATUAL"
	_oSQL:_sQuery += " FROM SDA010 DA"
	_oSQL:_sQuery += " 	,SB1010 B1"
	_oSQL:_sQuery += " WHERE DA_SALDO > 0"
	_oSQL:_sQuery += " AND B1.B1_COD = DA.DA_PRODUTO"
	_oSQL:_sQuery += " AND B1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND DA.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " ORDER BY DTA"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb (.F.)
	procregua ((_sAliasQ) -> (reccount ()))
		
	oSection1:Init()
	oSection1:SetHeaderSection(.T.)
			
	Do While ! (_sAliasQ) -> (eof ())
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| (_sAliasQ) -> FILIAL  	})
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| (_sAliasQ) -> PRODUTO 	})
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| (_sAliasQ) -> DESCRICAO})
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| (_sAliasQ) -> SALDO   	})
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| (_sAliasQ) -> LOC		})
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| (_sAliasQ) -> DOCUMENTO})
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| (_sAliasQ) -> DTA	 	})
		oSection1:Cell("COLUNA8")	:SetBlock   ({|| (_sAliasQ) -> MES_ATUAL})

		oSection1:PrintLine()
		
		(_sAliasQ) -> (dbskip ())
	Enddo
	oSection1:Finish()
	(_sAliasQ) -> (dbclosearea ())
Return
	
