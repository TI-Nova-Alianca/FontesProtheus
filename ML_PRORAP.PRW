//  Programa...: ML_PRORAP
//  Autor......: Catia Cardoso
//  Data.......: 24/02/2015
//  Descricao..: Relatório de Provisao de Rapel
//
//  Historico de alteracoes:
//
//  30/03/2015 - Catia -incluido parametro de cliente/loja
//  26/06/2015 - Catia -alterado para que faça a provisao usando o percentual de RAPEL da nota e nao do cadastro de clientes
//  20/08/2015 - Catia -impressao de parametros no final do relatorio
//  21/08/2015 - Catia - estava provisionando sobre bonificacoes tb
//  26/08/2015 - Catia - alterada forma de arredondamento para fechar com o que faz no lcto padrao
//  19/10/2015 - Catia - criada opcao por REDE para facilitar na conciliação
//  12/06/2017 - Catia - alterado para buscar o valor do rapel do D2 ao inves de calcular em percentual
//  26/02/2020 - Claudia - Incluida a filial nas tabelas SA1 e SF4
//
#include "rwmake.ch"
#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function ML_PRORAP()

private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
    delete file (_sArqLog)

    cString := "SE1"
    cDesc1  := "Relatório de Provisão de Rapel"
    cDesc2  := ""
    cDesc3  := ""
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    titulo  := "Relatório de Provisão de Rapel"
    cPerg   := "ML_PRORAP"
    wnrel   := "ML_PRORAP"
    nTipo   := 0

    _ValidPerg()
    if Pergunte(cPerg,.T.)
    
    	wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
    	If nLastKey == 27
       		Return
    	Endif
    
    	SetDefault(aReturn,cString)
    	If nLastKey == 27
       		Return
    	Endif

    	RptStatus({|| RptDetail()})
	endif
return

Static Function RptDetail()

    SetRegua(LastRec())
    nTipo   := IIF(aReturn[4]==1,15,18)
    li      := 80
    m_pag   := 1
    cabec1  :="DT.EMISSAO  NOTA/SERIE     CLIENTE  RAZAO SOCIAL                                         TOTAL PRODUTOS     VALOR IPI      VALOR ST  VLR DESCONTOS    TOTAL DA NOTA               VLR DO RAPEL"
    cabec2  :=""
    
    _sQuery := " "
    _sQuery += " SELECT SD2.D2_EMISSAO      AS DT_EMISSAO"
	_sQuery += "      , SD2.D2_DOC          AS NOTA"
	_sQuery += "      , SD2.D2_SERIE        AS SERIE"
	_sQuery += "      , SA1.A1_COD          AS COD_CLI"
	_sQuery += "      , SA1.A1_NOME         AS NOM_CLI"
	_sQuery += "      , SUM(SD2.D2_TOTAL)   AS VLR_PROD"
	_sQuery += "      , SUM(SD2.D2_VALIPI)  AS VLR_IPI"
	_sQuery += "      , SUM(SD2.D2_ICMSRET) AS VLR_ST"
	_sQuery += "      , SUM(SD2.D2_DESCON)  AS VLR_DESC"
  	_sQuery += "      , SUM(SD2.D2_VALBRUT) AS VLR_BRT"
	_sQuery += "      , SUM(SD2.D2_VRAPEL)  AS VLR_RAPEL"
	_sQuery += "  FROM " + RetSQLName ("SD2") + " AS SD2 "
	_sQuery += "		INNER JOIN SF4010 AS SF4"
	_sQuery += "				ON (SF4.D_E_L_E_T_    = '' "
	_sQuery += "					AND SF4.F4_FILIAL = '' "
  	_sQuery += "					AND SF4.F4_CODIGO = SD2.D2_TES"
  	_sQuery += "                    AND SF4.F4_MARGEM = '1')"
  	_sQuery += "  INNER JOIN " + RetSQLName ("SA1") + " AS SA1 "
	_sQuery += "		  ON (SA1.D_E_L_E_T_ = ''"
	_sQuery += "				AND SA1.A1_FILIAL = ''"
 	_sQuery += "			  	AND SA1.A1_COD    = SD2.D2_CLIENTE"
 	IF mv_par09 = 2  // opcao por rede 
		_sQuery += "		  AND SA1.A1_VACBASE  BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
	ENDIF			
	_sQuery += "			  AND SA1.A1_LOJA    = SD2.D2_LOJA)"
	_sQuery += " WHERE SD2.D_E_L_E_T_ = ''"
    _sQuery += "   AND SD2.D2_FILIAL  BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
    _sQuery += "   AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par03) + "' AND '" + dtos (mv_par04) + "'"
    IF mv_par09 = 1  // opcao por cliente
 		_sQuery += "   AND SD2.D2_CLIENTE BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
 		_sQuery += "   AND SD2.D2_LOJA    BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
	endif
	_sQuery += " GROUP BY SD2.D2_EMISSAO, SD2.D2_DOC, SD2.D2_SERIE, SA1.A1_COD, SA1.A1_NOME"
    _sQuery += " ORDER BY SD2.D2_EMISSAO, SD2.D2_DOC, SD2.D2_SERIE"
  
	//u_showmemo(_sQuery)
        
    _sAliasQ = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
    
    _aTotGer  = {0,0,0,0,0,0,0,0}
    
    (_sAliasQ) -> (DBGoTop ())
     Do While ! (_sAliasQ) -> (Eof ())
     	
		   If li>58
           		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           Endif        
        		     
           @li,  00 PSAY  stod((_sAliasQ) -> DT_EMISSAO)
           @li,  13 PSAY (_sAliasQ) -> NOTA
           @li,  23 PSAY (_sAliasQ) -> SERIE
           @li,  28 PSAY (_sAliasQ) -> COD_CLI
           @li,  37 PSAY (_sAliasQ) -> NOM_CLI
		   @li,  90 PSAY (_sAliasQ) -> VLR_PROD  Picture "@E 999,999,999.99"
           @li, 108 PSAY (_sAliasQ) -> VLR_IPI   Picture "@E 999,999.99"
           @li, 122 PSAY (_sAliasQ) -> VLR_ST    Picture "@E 999,999.99"
           @li, 137 PSAY (_sAliasQ) -> VLR_DESC  Picture "@E 999,999.99"
           @li, 150 PSAY (_sAliasQ) -> VLR_BRT   Picture "@E 999,999,999.99"
           @li, 177 PSAY (_sAliasQ) -> VLR_RAPEL Picture "@E 99,999,999.99"
	       li ++
		   
           // acumula total das emissoes
           _aTotGer[1] += (_sAliasQ) -> VLR_PROD
           _aTotGer[2] += (_sAliasQ) -> VLR_IPI
           _aTotGer[3] += (_sAliasQ) -> VLR_ST
           _aTotGer[4] += (_sAliasQ) -> VLR_DESC
           _aTotGer[5] += (_sAliasQ) -> VLR_BRT
           _aTotGer[7] += (_sAliasQ) -> VLR_RAPEL
           
           (_sAliasQ) -> (dbskip())
     enddo
     
     if _aTotGer [1] > 0
        // imprime total geral
        If li>58
            cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
        Endif        
        li++
        @ li, 00 PSAY "TOTAL DO GERAL --> "
        @li,  90 PSAY _aTotGer[1] Picture "@E 999,999,999.99"
        @li, 108 PSAY _aTotGer[2] Picture "@E 999,999.99"
        @li, 122 PSAY _aTotGer[3] Picture "@E 999,999.99"
        @li, 137 PSAY _aTotGer[4] Picture "@E 999,999.99"
        @li, 150 PSAY _aTotGer[5] Picture "@E 999,999,999.99"
        @li, 177 PSAY _aTotGer[7] Picture "@E 99,999,999.99"
	    
        li++
     Endif
     
     U_ImpParam (58)
    
     Set Device To Screen

     If aReturn[5]==1
           Set Printer TO
           dbcommitAll()
           ourspool(wnrel)
     Endif

     MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)

return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Filial de                    ?", "C", 2, 0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {02, "Filial até                   ?", "C", 2, 0,  "",   "SM0", {},                         ""})
    aadd (_aRegsPerg, {03, "Data de Emissao de           ?", "D", 8, 0,  "",   "   ", {},                         ""})
    aadd (_aRegsPerg, {04, "Data de Emissao até          ?", "D", 8, 0,  "",   "   ", {},                         ""})
    aadd (_aRegsPerg, {05, "Cliente de                    ", "C", 6,  0,  "",   "SA1", {},                        "Cliente Inicial"})
	aadd (_aRegsPerg, {06, "Cliente ate                   ", "C", 6,  0,  "",   "SA1", {},                        "Cliente Final"})
	aadd (_aRegsPerg, {07, "Loja de                       ", "C", 2,  0,  "",   "   ", {},                        "Loja Inicial"})
	aadd (_aRegsPerg, {08, "Loja ate                      ", "C", 2,  0,  "",   "   ", {},                        "Loja Final"})
	aadd (_aRegsPerg, {09, "Opção para cliente           ?", "N", 1,  0,  "",   "   ", {"Cliente","Rede"},   ""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return