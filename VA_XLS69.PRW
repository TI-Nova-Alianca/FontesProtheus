// Programa..: VA_XLS69.PRW
// Autor.....: Sandra Sugari
// Data......: 22/05/2024
// Nota......: Relatorio de Linha Comercial
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #relatorio
// #Descricao         #Relatorio de Linha Comercial
// #PalavasChave      #Relatorio de Linha Comercial
// #TabelasPrincipais #SB1 #SB2 #SB9 
// #Modulos           #EST
//
// Historico de alteracoes:
// 
// ----------------------------------------------------------------------------------------------------------

User Function VA_XLS69 (_lAutomat)
	Local cCadastro := "Relatorio de Linha Comercial"
	Local aSays     := {}
	Local aButtons  := {}
	Local nOpca     := 0
	Local lPerg     := .F.
	private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)
	Private cPerg   := "VAXLS69"
	_ValidPerg()
	Pergunte(cPerg,.F.)

	if _lAuto != NIL .and. _lAuto
		Processa( { |lEnd| _Gera() } )
	else
		AADD(aSays,cCadastro)
		AADD(aSays,"")
		AADD(aSays,"")
		AADD(aButtons, { 5, .T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 1, .T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2, .T.,{|| FechaBatch() }} )
		FormBatch( cCadastro, aSays, aButtons )
		If nOpca == 1
			Processa( { |lEnd| _Gera() } )
		Endif
	endif
return


// --------------------------------------------------------------------------
// 'Tudo OK' do FormBatch.
Static Function _TudoOk()
	Local _lRet     := .T.
Return _lRet


// --------------------------------------------------------------------------
Static Function _Gera()
	local _oSQL      := NIL

	procregua (10)
	incproc ("Gerando arquivo de exportacao")

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	
    _oSQL:_sQuery := " "
_oSQL:_sQuery += " WITH SALDOS "                
_oSQL:_sQuery += " AS "               
_oSQL:_sQuery += " (SELECT "               
_oSQL:_sQuery += "       'ATUAL' AS ANO_MES "       
_oSQL:_sQuery += "       ,B2_FILIAL AS FILIAL "           
_oSQL:_sQuery += "       ,B2_COD AS PRODUTO "           
_oSQL:_sQuery += "       ,SUM(B2_QATU) AS SALDO "            
_oSQL:_sQuery += "       ,0 AS CUSTO "           
_oSQL:_sQuery += "   FROM SB2010 SB2 "           
_oSQL:_sQuery += "   WHERE SB2.D_E_L_E_T_ = '' "            
_oSQL:_sQuery += "   AND SB2.B2_QATU > 0 "           
_oSQL:_sQuery += "   GROUP BY SB2.B2_FILIAL "           
_oSQL:_sQuery += "          ,SB2.B2_COD "    
_oSQL:_sQuery += "   UNION ALL "            
_oSQL:_sQuery += "   SELECT "            
//_sQuery += "       SUBSTRING(SB9.B9_DATA, 1, 6) AS ANO_MES "       
_oSQL:_sQuery += "      B9_DATA "
_oSQL:_sQuery += "     ,B9_FILIAL AS FILIAL "
_oSQL:_sQuery += "     ,B9_COD AS PRODUTO "            
_oSQL:_sQuery += "     ,SUM(B9_QINI) AS SALDO "            
_oSQL:_sQuery += "     ,SUM(SB9.B9_VINI1) AS CUSTO "           
_oSQL:_sQuery += "   FROM SB9010 SB9 "           
_oSQL:_sQuery += "   WHERE SB9.D_E_L_E_T_ = '' "            
_oSQL:_sQuery += "   AND SB9.B9_QINI > 0 "           
_oSQL:_sQuery += "   AND SB9.B9_VINI1 > 0 "           
_oSQL:_sQuery += "   AND B9_DATA >= '"+DTOS(MV_PAR01)+"' "        
_oSQL:_sQuery += "  GROUP BY 
                        //SUBSTRING(SB9.B9_DATA, 1, 6) "   
_oSQL:_sQuery += "            B9_DATA "       
_oSQL:_sQuery += "           ,B9_FILIAL "   
_oSQL:_sQuery += "           ,B9_COD) "    
_oSQL:_sQuery += " SELECT "               
_oSQL:_sQuery += "   ANO_MES "            
_oSQL:_sQuery += "  ,FILIAL "                
_oSQL:_sQuery += "  ,SB1.B1_CODLIN AS COD_LIN_COML "                
_oSQL:_sQuery += "  ,ZX5_39.ZX5_39DESC AS DESC_LIN_COML "                
_oSQL:_sQuery += "  ,B1_TIPO AS TIPO " 
_oSQL:_sQuery += "  ,ZX5_34.ZX5_34COD "
_oSQL:_sQuery += "  ,ZX5_34.ZX5_34DESC AS CLASSIFICACAO "             
_oSQL:_sQuery += "  ,SALDOS.PRODUTO "              
_oSQL:_sQuery += "  ,B1_DESC AS DESCRICAO "               
_oSQL:_sQuery += "  ,SALDO "                
_oSQL:_sQuery += "  ,B1_UM AS UN_MED "                
_oSQL:_sQuery += "  ,SALDO * B1_LITROS AS SALDO_LITROS "                
_oSQL:_sQuery += "  ,CUSTO "               
_oSQL:_sQuery += " FROM SALDOS "               
_oSQL:_sQuery += "   ,SB1010 SB1 "           
_oSQL:_sQuery += "    LEFT JOIN ZX5010 ZX5_39 "           
_oSQL:_sQuery += "       ON (ZX5_39.ZX5_FILIAL = '  ' "        
_oSQL:_sQuery += "                AND ZX5_39.D_E_L_E_T_ = '' "
_oSQL:_sQuery += "                AND ZX5_39.ZX5_TABELA = '39' "
_oSQL:_sQuery += "                AND ZX5_39.ZX5_39COD = SB1.B1_CODLIN) "
_oSQL:_sQuery += "    LEFT JOIN SB5010 AS B5 "           
_oSQL:_sQuery += "       ON (B5.B5_FILIAL = '  '  "      
_oSQL:_sQuery += "                AND B5.D_E_L_E_T_ = '' "
_oSQL:_sQuery += "                AND B5.B5_COD = SB1.B1_COD) "
_oSQL:_sQuery += "    LEFT JOIN ZX5010 ZX5_34 "
_oSQL:_sQuery += "       ON (ZX5_34.ZX5_FILIAL = '  ' "
_oSQL:_sQuery += "				  AND ZX5_34.D_E_L_E_T_ = '' "
_oSQL:_sQuery += "				  AND ZX5_34.ZX5_TABELA = '34' "
_oSQL:_sQuery += "				  AND ZX5_34.ZX5_34COD = B5_VATPSIS) "
_oSQL:_sQuery += " WHERE SB1.D_E_L_E_T_ = '' "               
_oSQL:_sQuery += " AND SB1.B1_FILIAL = '  ' "               
_oSQL:_sQuery += " AND SB1.B1_COD = SALDOS.PRODUTO "   
_oSQL:_sQuery += " and B1_CODLIN         between '" + mv_par02 + "' and '" + mv_par03 + "'"
_oSQL:_sQuery += " and B1_TIPO           between '" + mv_par04 + "' and '" + mv_par05 + "'"
_oSQL:_sQuery += " and FILIAL            between '" + mv_par06 + "' and '" + mv_par07 + "'"
_oSQL:_sQuery += " ORDER BY ANO_MES, FILIAL, PRODUTO " 

_oSQL:Log ('[' + procname () + ']')
_oSQL:ArqDestXLS = 'VA_XLS69'
_oSQL:Qry2Xls (.F., .F., .F.)
return


// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}

	
     //                PERGUNT                           TIPO   TAM DEC VALID F3      Opcoes                         Help
	aadd (_aRegsPerg, {01, "Data Inicial                    ", "D", 8,  0,  "",   "",       {},                          ""})
	aadd (_aRegsPerg, {02, "Linha Com de                    ", "C", 2,  0,  "",   "ZX539",  {},                         "Linha Com Inicial"})
	aadd (_aRegsPerg, {03, "Linha Com ate                   ", "C", 2,  0,  "",   "ZX539",  {},                         "Linha Com FInal"})
	aadd (_aRegsPerg, {04, "Tipo produto inicial            ", "C", 2,  0,  "",   "02",     {},                         ""})
	aadd (_aRegsPerg, {05, "Tipo produto final              ", "C", 2,  0,  "",   "02 ",    {},                         ""})
	aadd (_aRegsPerg, {06, "Filial de                       ", "C", 2,  0,  "",   "SM0",    {},                          ""})
    aadd (_aRegsPerg, {07, "Filial até                      ", "C", 2,  0,  "",   "SM0",    {},                          ""})
    U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
    
    
    
    
    
    /*
    
    //                 Ordem Descri                          tipo tam                      dec valid  F3    opcoes (combo)  help
	aadd (_aRegsPerg, {01, "Filial inicial                ", "C", 2,                       0,  "",   "SM0", {},             ""})
	aadd (_aRegsPerg, {02, "Filial final                  ", "C", 2,                       0,  "",   "SM0", {},             ""})
	aadd (_aRegsPerg, {03, "OS inicial                    ", "C", tamsx3 ("TJ_ORDEM")[1],  0,  "",   "STJ", {},             ""})
	aadd (_aRegsPerg, {04, "OS final                      ", "C", tamsx3 ("TJ_ORDEM")[1],  0,  "",   "STJ", {},             ""})
	aadd (_aRegsPerg, {05, "Bem inicial                   ", "C", tamsx3 ("TJ_CODBEM")[1], 0,  "",   "ST9", {},             ""})
	aadd (_aRegsPerg, {06, "Bem final                     ", "C", tamsx3 ("TJ_CODBEM")[1], 0,  "",   "ST9", {},             ""})
	aadd (_aRegsPerg, {07, "Inicio previsto de            ", "D", 8,                       0,  "",   "   ", {},             ""})
	aadd (_aRegsPerg, {08, "Inicio previsto ate           ", "D", 8,                       0,  "",   "   ", {},             ""})
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return

*/












/*
#include "rwmake.ch"
#IFNDEF WINDOWS
	#DEFINE PSAY SAY
#ENDIF

User Function ML_LINCOM()

	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
	delete file (_sArqLog)

    cString := "SB1"
    cDesc1  := "Relatorio de Linha Comercial"
    cDesc2  := " "
    cDesc3  := " "
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    cPerg   := "ML_LINCOM"
    titulo  := "Relatorio de Linha Comercial"
    wnrel   := "ML_LINCOM"
    nTipo   := 0

    _ValidPerg()
    Pergunte(cPerg,.F.)

    wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)

    If nLastKey == 27
	   Return
    Endif
    SetDefault(aReturn,cString)
    If nLastKey == 27
	   Return
    Endif

    RptStatus({|| RptDetail()})
Return
//
// ----------------------------------------------------------------------------------------------
Static Function RptDetail()


    SetRegua(LastRec())

    nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
   cabec1 := "ANO_MES    FILIAL   COD_LIN_COML    DESCR_LIN_COML       TIPO      PRODUTO      DESCRIÇÃO                      SALDO       UN_MED     SALDOS_LITROS      CUSTOS"
	//cabec2 := ""
    
_sQuery := " "
_sQuery += " WITH SALDOS "                
_sQuery += " AS "               
_sQuery += " (SELECT "               
_sQuery += "       'ATUAL' AS ANO_MES "       
_sQuery += "       ,B2_FILIAL AS FILIAL "           
_sQuery += "       ,B2_COD AS PRODUTO "           
_sQuery += "       ,SUM(B2_QATU) AS SALDO "            
_sQuery += "       ,0 AS CUSTO "           
_sQuery += "   FROM SB2010 SB2 "           
_sQuery += "   WHERE SB2.D_E_L_E_T_ = '' "            
_sQuery += "   AND SB2.B2_QATU > 0 "           
_sQuery += "   GROUP BY SB2.B2_FILIAL "           
_sQuery += "          ,SB2.B2_COD "    
_sQuery += "   UNION ALL "            
_sQuery += "   SELECT "            
//_sQuery += "       SUBSTRING(SB9.B9_DATA, 1, 6) AS ANO_MES "       
_sQuery += "      B9_DATA "
_sQuery += "     ,B9_FILIAL AS FILIAL "
_sQuery += "     ,B9_COD AS PRODUTO "            
_sQuery += "     ,SUM(B9_QINI) AS SALDO "            
_sQuery += "     ,SUM(SB9.B9_VINI1) AS CUSTO "           
_sQuery += "   FROM SB9010 SB9 "           
_sQuery += "   WHERE SB9.D_E_L_E_T_ = '' "            
_sQuery += "   AND SB9.B9_QINI > 0 "           
_sQuery += "   AND SB9.B9_VINI1 > 0 "           
_sQuery += "   AND B9_DATA >= 'STOD(Data)' "        
_sQuery += "  GROUP BY 
                        //SUBSTRING(SB9.B9_DATA, 1, 6) "   
_sQuery += "            B9_DATA "       
_sQuery += "           ,B9_FILIAL "   
_sQuery += "           ,B9_COD) "    
_sQuery += " SELECT "               
_sQuery += "   ANO_MES "            
_sQuery += "  ,FILIAL "                
_sQuery += "  ,SB1.B1_CODLIN AS COD_LIN_COML "                
_sQuery += "  ,ZX5_39.ZX5_39DESC AS DESC_LIN_COML "                
_sQuery += "  ,B1_TIPO AS TIPO "                
_sQuery += "  ,SALDOS.PRODUTO "              
_sQuery += "  ,B1_DESC AS DESCRICAO "               
_sQuery += "  ,SALDO "                
_sQuery += "  ,B1_UM AS UN_MED "                
_sQuery += "  ,SALDO * B1_LITROS AS SALDO_LITROS "                
_sQuery += "  ,CUSTO "               
_sQuery += " FROM SALDOS "               
_sQuery += "   ,SB1010 SB1 "           
_sQuery += "    LEFT JOIN ZX5010 ZX5_39 "           
_sQuery += "       ON (ZX5_39.ZX5_FILIAL = '  ' "        
_sQuery += "                AND ZX5_39.D_E_L_E_T_ = '' "
_sQuery += "                AND ZX5_39.ZX5_TABELA = '39' "
_sQuery += "                AND ZX5_39.ZX5_39COD = SB1.B1_CODLIN) "
_sQuery += " WHERE SB1.D_E_L_E_T_ = '' "               
_sQuery += " AND SB1.B1_FILIAL = '  ' "               
_sQuery += " AND SB1.B1_COD = SALDOS.PRODUTO "               
_sQuery += " ORDER BY ANO_MES, FILIAL, PRODUTO " 


    //u_showmemo(_sQuery)
    
    u_log (_sQuery)
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
        
    (_sAliasQ) -> (DBGoTop ())
    (_sAliasQ) -> (dbskip())
		
 
     
    Set Device To Screen

	If aReturn[5]==1
		Set Printer TO
		dbcommitAll()
		ourspool(wnrel)
	Endif

    MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT                           TIPO   TAM DEC VALID F3      Opcoes                         Help
	aadd (_aRegsPerg, {01, "Data Inicial                    ", "D", 8,  0,  "",   "SB9",    {},                          ""})
	aadd (_aRegsPerg, {02, "Linha Com de                    ", "C", 3,  0,  "",   "ZX539",  {},                         "Linha Com Inicial"})
	aadd (_aRegsPerg, {03, "Linha Com ate                   ", "C", 3,  0,  "",   "ZX539",  {},                         "Linha Com FInal"})
	aadd (_aRegsPerg, {04, "Tipo produto inicial            ", "C", 2,  0,  "",   "02",     {},                         ""})
	aadd (_aRegsPerg, {05, "Tipo produto final              ", "C", 2,  0,  "",   "02 ",    {},                         ""})
	aadd (_aRegsPerg, {06, "Filial de                       ", "C", 2,  0,  "",   "SM0",    {},                          ""})
    aadd (_aRegsPerg, {07, "Filial até                      ", "C", 2,  0,  "",   "SM0",    {},                          ""})
   
    
   	U_ValPerg (cPerg, _aRegsPerg)
Return

*/
