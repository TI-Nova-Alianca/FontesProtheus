// Programa..: VA_ProdXCli
// Descricao : Impressao lista precos especifica
// Autor.....: DWT
// Data......: por volta de 2014
//
// Historico de atualizacoes: 
// 29/01/2015 - alterado cabeçalho da tabela - tirado CIF e alterado data de vigencia.
// 02/02/2015 - Catia  - Incluido intervalo de CLIENTE/LOJA
// 18/06/2016 - Catia  - Alterada razao social
// 05/09/2016 - Robert - Tabela 81 trocada pela tabela 38 do ZX5.
// 10/04/2019 - Robert - Migrada tabela 98 do SX5 para 50 do ZX5.
// 26/07/2019 - Andre  - Campo B1_VAEANUN substituido pelo campo B5_2CODBAR.

// --------------------------------------------------------------------------
User Function VA_PRDXCLI()

cPerg   := "VA_PRDXCLI"
_ValidPerg()
Pergunte(cPerg,.F.)
oReport := ReportDef()
oReport:PrintDialog()

Return

// -------------------- FUNCAO INTERNA
Static Function ReportDef()

Local oReport
Local oSection
//Local oBreak
Local cTitulo:='TABELA DE PREÇO POR CANAL'

oReport := TReport():New("VA_PRDXCLI",cTitulo,cPerg,{|oReport| PrintReport(oReport)},"Este relatório trará informações da tabela PROCUTO X CLIENTES")
oReport:SetTotalInLine(.F.)
oReport:SetPortrait()
oSection := TRSection():New(oReport,"PRODUTOS",{""}, , , , , ,.F.,.F.,.F.,,10)
oSection:SetTotalInLine(.F.)

TRCell():New(oSection,"COD",		,"Cod.",							,15,, {|| aArray[d,1]},"LEFT" ,,"LEFT",,,,,,.F.)
TRCell():New(oSection,"DESC",		,"Descricao",  				   		,60,, {|| aArray[d,2]},"LEFT" ,,"LEFT",,,,,,.F.)
TRCell():New(oSection,"EMBALAGEM",  ,"Embalagem",				   		,15,, {|| aArray[d,3]},"LEFT" ,,"LEFT",,,,,,.F.)
TRCell():New(oSection,"PRCVEN",		,"Preço",		"@E 999,999,999.99"	,15,, {|| aArray[d,4]},"RIGHT",,"RIGHT",,,,,,.F.)
TRCell():New(oSection,"IPI",		,"IPI ",		"@E 999,999,999.99"	,15,, {|| aArray[d,5]},"RIGHT",,"RIGHT",,,,,,.F.)
TRCell():New(oSection,"VAST",		,"ST",	   		"@E 999,999,999.99"	,15,, {|| aArray[d,6]},"RIGHT",,"RIGHT",,,,,,.F.)
TRCell():New(oSection,"ESTADO",		,"Estado",     	" "	,6,, {|| aArray[d,8]},"RIGHT",,"RIGHT",,,,,,.F.)
TRCell():New(oSection,"EAN",		,"EAN13-unid",	"99999999999999999"	,20,, {|| aArray[d,7]},"RIGHT",,"RIGHT",,,,,,.F.)

Return oReport

// -------------------- FUNCAO INTERNA
Static Function PrintReport(oReport)
	local d := 0
	local c := 0
	Local aArray:={}
	Local oSection  := oReport:Section(1)
	nTitulo:=""
	nLinhaPont:="------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
	nLinhaCont:="_____________________________________________________________________________________________________________________________________________________"
	nBranco:= " "
	//declaração do cabeçalho
	lin1:="COOPERATIVA AGROINDUSTRIAL NOVA ALIANCA LTDA"
	lin2:="Estrada Gerardo Santin Guarese, s/n Travessão 7 de Setembro, Lagoa Bela Caixa Postal 21 - CEP 95270-000"
	lin3:="Flores da Cunha - RS  Fone/Fax 55+ (54) 3279 3400 - http://www.novaalianca.coop.br"
	logo:="logo2.jpg"
	fonte:="ARIAL"
	titulo:="TABELA DE PREÇO POR CANAL"
	 
	U_CabTReport(oReport,lin1,lin2,lin3,titulo,logo,fonte,1)
	
	cQuery2 := " SELECT DA0_DESCRI FROM " +RetSQLName("DA0")+ " where DA0_CODTAB='"+MV_PAR01+"'" 
	NLIST = U_Qry2Array(cQuery2)
																									   
	nTitulo	+="                                                                 "+MV_PAR01+" - "+ NLIST[1,1]
	nLinhaB   := ""
	//nCIF		:= "					Quando Frete CIF: até " + AllTrim(MV_PAR06) + "%"
	nCIF		:= ""
	nFOB		:= "					Quando Frete FOB: até " + AllTrim(MV_PAR07) + "%"
         
	oReport:PrintText("",,,,,,) 
	oReport:PrintText("",,,,,,)
	oReport:PrintText(nTitulo,,,,,,)
	oReport:PrintText("",,,,,,) 
    oReport:PrintText(nCIF,,,,,,)
    oReport:PrintText(nFOB,,,,,,) 
    oReport:PrintText("					Para pagamento à vista antecipado: desconto adicional de 3%",,,,,,) 
    oReport:PrintText("					* Os valores abaixo não consideram IPI e ST.",,,,,,)
    oReport:PrintText("					Vigência: à partir de 02/02/2015 com validade indeterminada.",,,,,,)
    oReport:PrintText("					Cliente : " + LEFT(fbuscacpo ("SA1", 1, xfilial ("SA1") + mv_par08 + '01',  "A1_NOME"),35),,,,,)
        
	// MARCA
	cQuery3 := " SELECT DISTINCT ZX5_38G1, ZX5_38G2, ZX5_38COD "
	cQuery3 += " FROM "+ RetSqlName("SB1")+" B1," + RetSqlName("DA1")+" DA1," + RetSqlName("ZX5")+" ZX5, " + RetSqlName("SA3")+" A3 "
	cQuery3 += " WHERE B1.D_E_L_E_T_='' "
	cQuery3 += " AND DA1.D_E_L_E_T_='' "
	cQuery3 += " AND ZX5.D_E_L_E_T_='' "
	cQuery3 += " AND A3.D_E_L_E_T_='' "
	cQuery3 += " AND B1_FILIAL='"+ xFilial("SB1") + "' "
	cQuery3 += " AND DA1_FILIAL='"+ xFilial("DA1") + "' "
	cQuery3 += " AND ZX5_FILIAL='"+ xFilial("ZX5") + "' "
	cQuery3 += " AND A3_FILIAL='"+ xFilial("SA3") + "' "
	cQuery3 += " AND B1_COD = DA1_CODPRO "
	cQuery3 += " AND DA1_CODTAB = '" + alltrim(MV_PAR01) + "' "
	cQuery3 += " AND DA1_ESTADO >= '" + alltrim(MV_PAR04) + "' "
	cQuery3 += " AND DA1_ESTADO <= '" + alltrim(MV_PAR05) + "' "
	CQuery3 += " AND DA1_CLIENT BETWEEN '" + mv_par08  + "' AND '" + mv_par09 + "'"
	cQuery3 += " AND DA1_LOJA   BETWEEN '" + mv_par10  + "' AND '" + mv_par11 + "'"
	cQuery3 += " AND ZX5_TABELA = '38' "                                                
	cQuery3 += " AND ZX5_38COD = B1_VAGRLP "
	cQuery3 += " ORDER BY ZX5_38G1 "
	
	MARCA = U_Qry2Array(cQuery3)
	
	FOR c:=1 TO LEN(MARCA)

		// PRODUTOS
		cQuery4 := " SELECT DISTINCT B1_COD, B1_DESC,"
//		cQuery4 +=        " (SELECT X5_DESCRI"
//		cQuery4 +=           " FROM " + RetSQLName ("SX5")
//		cQuery4 +=          " WHERE X5_TABELA = '98'"
//		cQuery4 +=            " and X5_CHAVE=B1_GRPEMB) AS EMBALAGEM,"
		cQuery4 +=        " (SELECT ZX5_50DESC"
		cQuery4 +=           " FROM " + RetSQLName ("ZX5")
		cQuery4 +=          " WHERE D_E_L_E_T_ = ''"
		cQuery4 +=          "   AND ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		cQuery4 +=          "   AND ZX5_TABELA = '50'"
		cQuery4 +=            " and ZX5_50COD  = B1_GRPEMB) AS EMBALAGEM,"
		cQuery4 +=        " DA1_PRCVEN, "
		cQuery4 +=        " CASE WHEN B1_VLR_IPI > 0 THEN B1_VLR_IPI ELSE DA1_PRCVEN * B1_IPI / 100 END AS VALOR_IPI, "
		cQuery4 +=        " DA1_VAST,B5_2CODBAR,B1_GRPEMB, DA1_ESTADO "
		cQuery4 += " FROM "+ RetSqlName("SB1")+" B1," + RetSqlName("DA1")+" DA1," + RetSqlName("ZX5")+" ZX5, " + RetSqlName("SA3")+" A3, " + RetSqlName("SB5")+" B5  "
		cQuery4 += " WHERE B1.D_E_L_E_T_='' "
		cQuery4 += " AND DA1.D_E_L_E_T_='' "
		cQuery4 += " AND ZX5.D_E_L_E_T_='' "
		cQuery4 += " AND A3.D_E_L_E_T_='' "
		cQuery4 += " AND B5.D_E_L_E_T_='' "
		cQuery4 += " AND B1_FILIAL='"+ xFilial("SB1") + "' "
		cQuery4 += " AND DA1_FILIAL='"+ xFilial("DA1") + "' "
		cQuery4 += " AND ZX5_FILIAL='"+ xFilial("ZX5") + "' "
		cQuery4 += " AND A3_FILIAL='"+ xFilial("SA3") + "' "
		cQuery4 += " AND B5_FILIAL='"+ xFilial("SB5") + "' "
		cQuery4 += " AND B1_COD = DA1_CODPRO "
		cQuery4 += " AND B1_COD = B5_COD "
		cQuery4 += " AND DA1_CODTAB = '" + alltrim(MV_PAR01) + "' "
		cQuery4 += " AND DA1_CODPRO >= '" + alltrim(MV_PAR02) + "' "
		cQuery4 += " AND DA1_CODPRO <= '" + alltrim(MV_PAR03) + "' "
		cQuery4 += " AND DA1_ESTADO >= '" + alltrim(MV_PAR04) + "' "
		cQuery4 += " AND DA1_ESTADO <= '" + alltrim(MV_PAR05) + "' "
		CQuery4 += " AND DA1_CLIENT BETWEEN '" + mv_par08  + "' AND '" + mv_par09 + "'"
		cQuery4 += " AND DA1_LOJA   BETWEEN '" + mv_par10  + "' AND '" + mv_par11 + "'"
		cQuery4 += " AND ZX5_TABELA = '38' "
		cQuery4 += " AND ZX5_38COD = B1_VAGRLP "
		cQuery4 += " AND ZX5_38COD = '"+MARCA[c,3]+"' "
		cQuery4 += " ORDER BY B1_COD
		PRODUTO = U_Qry2Array(cQuery4)
		
		if LEN(PRODUTO) > 0
			oReport:PrintText(nBranco,,50)
			nMarca:=AllTrim(MARCA[c,1])+" - " +AllTrim(MARCA[c,2])
			oReport:PrintText("*** " + nMarca + " ***",,150) 
			oReport:PrintText(nLinhaPont,,50)
			oReport:PrintSHeader() 
		endif
            
		oSection:Init()
		oSection:SetHeaderSection(.T.)
		aArray:={}
		FOR d:=1 TO LEN(PRODUTO)
			AADD(aArray, {PRODUTO[d,1],PRODUTO[d,2],PRODUTO[d,3],PRODUTO[d,4],PRODUTO[d,5],PRODUTO[d,6],PRODUTO[d,7],PRODUTO[d,9]})
			
			oSection:Cell("COD")  		:SetBlock({|| aArray[d,1]})
			oSection:Cell("DESC") 		:SetBlock({|| aArray[d,2]})
			oSection:Cell("EMBALAGEM")  :SetBlock({|| aArray[d,3]})
			oSection:Cell("PRCVEN")		:SetBlock({|| aArray[d,4]})
			oSection:Cell("IPI")		:SetBlock({|| aArray[d,5]})
			oSection:Cell("VAST") 		:SetBlock({|| aArray[d,6]})
			oSection:Cell("ESTADO") 	:SetBlock({|| aArray[d,8]})
		   	oSection:Cell("EAN") 		:SetBlock({|| aArray[d,7]})
		  	
			oSection:PrintLine()
		NEXT
	NEXT

oSection:Finish()
oReport:IncMeter()
Return

//---------------------- PERGUNTAS
Static Function _ValidPerg ()
local _aRegsPerg := {}
//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                        Help
AADD(_aRegsPerg,{01,"Tabela			",	     			"C", 03, 0, "",   "DA0", {},                           ""})
AADD(_aRegsPerg,{02,"Produto ate	",	     			"C", 04, 0, "",   "SB1", {},                           ""})
AADD(_aRegsPerg,{03,"Produto ate	",	     			"C", 04, 0, "",   "SB1", {},                           ""})
AADD(_aRegsPerg,{04,"Estado de    	",	     			"C", 02, 0, "",   "  ", {},                           ""})
AADD(_aRegsPerg,{05,"Estado ate    	",	     			"C", 02, 0, "",   "  ", {},                           ""})
AADD(_aRegsPerg,{06,"Frete CIF   	", 					"C", 10, 0,  "",   "", {},                           ""})
AADD(_aRegsPerg,{07,"Frete FOB    	", 					"C", 10, 0,  "",   "", {},                           ""})
aadd(_aRegsPerg,{08,"Cliente de     ", "C", 6,  0,  "",   "SA1", {},                        "Cliente Inicial"})
aadd(_aRegsPerg,{09,"Cliente ate    ", "C", 6,  0,  "",   "SA1", {},                        "Cliente Final"})
aadd(_aRegsPerg,{10,"Loja de        ", "C", 2,  0,  "",   "   ", {},                        "Loja Inicial"})
aadd(_aRegsPerg,{11,"Loja ate       ", "C", 2,  0,  "",   "   ", {},                        "Loja Final"})

U_ValPerg (cPerg, _aRegsPerg)
Retur
