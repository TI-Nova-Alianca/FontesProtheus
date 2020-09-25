// Programa...: FrtRel02_XLS
// Autor......: Catia Cardoso
// Data.......: 18/09/2014
// Descricao..: Relatorio e Exportacao XLS de ANALISE DE FRETES
//
// ------------------------------------------------------------------------------------------------
// Historico de alteracoes:
// ------------------------------------------------------------------------------------------------
// 08/01/2015 - Catia - incluido teste de usuarios que podem usar esta rotina/relatorio - usa a rotina 032
// 14/07/2015 - Catia - revalidado relatorio de fretes - jeferson/rodrigo
// 24/11/2015 - Catia - deixar tudo na mesma pagina - incluir linhas de conclusao no final
// 22/01/2016 - Catia - cString não estava SF2
// 03/06/2019 - Catia - alterado para que busque o valor do ICMS creditado no conhecimento de frete e calcule o custo do frete

User Function FRTXLS02 (_lAutomat)
    Local cCadastro  := "Análise de Fretes"
    Local aSays      := {}
    Local aButtons   := {}
    Local nOpca      := 0
    Local lPerg      := .F.
    private _lAuto   := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)

    Private cPerg   := "FRTXLS02"
    _ValidPerg()
    Pergunte(cPerg,.F.)
    
    if ! u_zzuvl ('032', __cUserId, .T.)
//		msgalert ("Usuário sem permissão para usar esta rotina/relatório.")
		return
	endif
	
	if _lAuto != NIL .and. _lAuto
        Processa( { |lEnd| _Gera() } )
    else
        AADD(aSays,"Este programa tem como objetivo apurar  ANÁLISE DE FRETES ")
        AADD(aSays,"sobre VENDAS e BONIFICAÇÕES.")
        AADD(aSays,"")
        AADD(aSays,"OBS.: Não considera fretes sobre DEVOLUÇÕES, COMPRAS e nem ")
        AADD(aSays,"TRANSFÊRENCIAS.")
        AADD(aSays,"")
        
        AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
        AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
        AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
        
        FormBatch( cCadastro, aSays, aButtons )
        
        If nOpca == 1
            Processa( { |lEnd| _ExecQuery(1) } )
            if mv_par11=1
                Processa( { |lEnd| _GeraArq() } )
            else
                Processa( { |lEnd| _Lista() } )
            endif
        Endif
    endif
return

// --------------------------------------------------------------------------
Static Function _TudoOk()
    Local _lRet     := .T.
Return _lRet

// --------------------------------------------------------------------------
Static Function _ExecQuery(_periodo)
    local  _sQuery    := ""
    public _sAlias_FRETES   := ""
    
    procregua (10)
    incproc ("Buscando dados")
    _sQuery := ""
    _sQuery += " WITH C AS (SELECT SD2.D2_EST                    AS UF"
    _sQuery += "                 , SD2.D2_DOC                    AS NOTA"
  	_sQuery += "                 , SF2.F2_PBRUTO                 AS PESO_BRUTO"
  	_sQuery += "	             , SUM(SD2.D2_VALBRUT)           AS TOT_FAT_UF"
  	_sQuery += "                 , ISNULL(SUM(SZH1.RATEIO),0)    AS TOT_FRE"
  	_sQuery += "                 , 0                             AS FAT_FRETE"
  	_sQuery += "	             , ISNULL(SUM(SZH1.CREDICMS), 0) AS CRED_ICMS"
  	_sQuery += "  FROM " + RetSQLName ("SD2") + " AS SD2 "
  	_sQuery += "	INNER JOIN " + RetSQLName ("SF2") + " AS SF2 "
  	_sQuery += "			ON (SF2.D_E_L_E_T_ = ''"
  	_sQuery += "				AND SF2.F2_FILIAL  = SD2.D2_FILIAL"
  	_sQuery += "				AND SF2.F2_DOC     = SD2.D2_DOC"
  	_sQuery += "				AND SF2.F2_SERIE   = SD2.D2_SERIE"
  	_sQuery += "				AND SF2.F2_CLIENTE = SD2.D2_CLIENTE"
  	_sQuery += "				AND SF2.F2_LOJA    = SD2.D2_LOJA"
  	_sQuery += "				AND SF2.F2_EMISSAO = SD2.D2_EMISSAO)"
	_sQuery += "	INNER JOIN SF4010 AS SF4"
	_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"
	_sQuery += "				AND SF4.F4_CODIGO  = SD2.D2_TES"
  	_sQuery += "			    AND SF4.F4_MARGEM IN ('1','3') )"
  	_sQuery += "	INNER JOIN SA1010 AS SA1"
	_sQuery += "			ON (SA1.D_E_L_E_T_ = ''"
	_sQuery += "				AND SA1.A1_COD  = SD2.D2_CLIENTE"
	_sQuery += "                AND SA1.A1_SATIV1     BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
    _sQuery += "                AND SA1.A1_VACANAL    BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
    _sQuery += "				AND SA1.A1_LOJA  = SD2.D2_LOJA)"
	_sQuery += "     LEFT JOIN (SELECT SUM(SZH.ZH_RATEIO) AS RATEIO"
	_sQuery += "     			     , SZH.ZH_FILIAL"
	_sQuery += "     				 , SZH.ZH_NFSAIDA"
	_sQuery += "     				 , SZH.ZH_SERNFS"
	_sQuery += "     				 , SZH.ZH_ITNFS"
	_sQuery += "                     , SUM(SZH.ZH_CREDICM) AS CREDICMS"
	_sQuery += "                  FROM " + RetSQLName ("SZH") + " SZH"
	_sQuery += "			     WHERE SZH.D_E_L_E_T_ = ''"
	_sQuery += "		  		 GROUP BY SZH.ZH_FILIAL, SZH.ZH_NFSAIDA, SZH.ZH_SERNFS, SZH.ZH_ITNFS) AS SZH1"
	_sQuery += "             ON (SZH1.ZH_FILIAL        = SD2.D2_FILIAL"		  		 
	_sQuery += "    			 AND SZH1.ZH_NFSAIDA   = SD2.D2_DOC"
	_sQuery += "    			 AND SZH1.ZH_SERNFS    = SD2.D2_SERIE"
	_sQuery += "    			 AND SZH1.ZH_ITNFS     = SD2.D2_ITEM)"
	_sQuery += " WHERE SD2.D_E_L_E_T_ = ''"
    _sQuery += "   AND SD2.D2_FILIAL    = '" + xfilial ("SD2") + "'"
    if _periodo == 1
        _sQuery += "              AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par12) + "' and '" + dtos (mv_par13) + "'"
    else
        _sQuery += "              AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par14) + "' and '" + dtos (mv_par15) + "'"
    endif
    _sQuery += "   AND SD2.D2_EST       BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_sQuery += "   AND SD2.D2_CLIENTE   BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
    _sQuery += "   AND SD2.D2_LOJA      BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
    _sQuery += " GROUP BY SD2.D2_EST, SD2.D2_DOC, SF2.F2_PBRUTO"
    _sQuery += " UNION ALL"
    // busca total de notas com frete
    _sQuery += " SELECT SD2.D2_EST                    AS UF"
    _sQuery += "      , SD2.D2_DOC                    AS NOTA"
  	_sQuery += "      , 0                             AS PESO_BRUTO"
  	_sQuery += "      , 0                             AS TOT_FAT_UF"
  	_sQuery += "      , 0                             AS TOT_FRE"
  	_sQuery += "      , SUM(SD2.D2_VALBRUT)           AS FAT_FRETE"
  	_sQuery += "      , ISNULL(SUM(SZH1.CREDICMS), 0)  AS CRED_ICMS"      
  	_sQuery += "  FROM " + RetSQLName ("SD2") + " AS SD2 "
  	_sQuery += "	INNER JOIN SF4010 AS SF4"
	_sQuery += "			ON (SF4.D_E_L_E_T_ = ''"
	_sQuery += "				AND SF4.F4_CODIGO  = SD2.D2_TES"
  	_sQuery += "			    AND SF4.F4_MARGEM IN ('1','3') )"
  	_sQuery += "	INNER JOIN SA1010 AS SA1"
	_sQuery += "			ON (SA1.D_E_L_E_T_ = ''"
	_sQuery += "				AND SA1.A1_COD  = SD2.D2_CLIENTE"
	_sQuery += "                AND SA1.A1_SATIV1     BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
    _sQuery += "                AND SA1.A1_VACANAL    BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "'"
    _sQuery += "				AND SA1.A1_LOJA  = SD2.D2_LOJA)"
	_sQuery += "    INNER JOIN (SELECT SUM(SZH.ZH_RATEIO) AS RATEIO"
	_sQuery += "     			     , SZH.ZH_FILIAL"
	_sQuery += "     				 , SZH.ZH_NFSAIDA"
	_sQuery += "     				 , SZH.ZH_SERNFS"
	_sQuery += "     				 , SZH.ZH_ITNFS"
	_sQuery += "                     , SUM(SZH.ZH_CREDICM) AS CREDICMS"
	_sQuery += "                  FROM " + RetSQLName ("SZH") + " SZH"
	_sQuery += "			     WHERE SZH.D_E_L_E_T_ = ''"
	_sQuery += "		  		 GROUP BY SZH.ZH_FILIAL, SZH.ZH_NFSAIDA, SZH.ZH_SERNFS, SZH.ZH_ITNFS) AS SZH1"
	_sQuery += "             ON (SZH1.ZH_FILIAL        = SD2.D2_FILIAL"		  		 
	_sQuery += "    			 AND SZH1.ZH_NFSAIDA   = SD2.D2_DOC"
	_sQuery += "    			 AND SZH1.ZH_SERNFS    = SD2.D2_SERIE"
	_sQuery += "    			 AND SZH1.ZH_ITNFS     = SD2.D2_ITEM)"
	_sQuery += " WHERE SD2.D_E_L_E_T_ = ''"
    _sQuery += "   AND SD2.D2_FILIAL    = '" + xfilial ("SD2") + "'"
    if _periodo == 1
        _sQuery += "              AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par12) + "' and '" + dtos (mv_par13) + "'"
    else
        _sQuery += "              AND SD2.D2_EMISSAO BETWEEN '" + dtos (mv_par14) + "' and '" + dtos (mv_par15) + "'"
    endif
    _sQuery += "   AND SD2.D2_EST       BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_sQuery += "   AND SD2.D2_CLIENTE   BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
    _sQuery += "   AND SD2.D2_LOJA      BETWEEN '" + mv_par09 + "' AND '" + mv_par10 + "'"
    _sQuery += " GROUP BY SD2.D2_EST, SD2.D2_DOC)"
    _sQuery += " SELECT C.UF              AS UF"
    _sQuery += "      , SUM(C.PESO_BRUTO) AS PESO_BRUTO"
  	_sQuery += "	  , SUM(C.TOT_FAT_UF) AS TOT_FAT_UF"
  	_sQuery += "      , SUM(C.TOT_FRE)    AS TOT_FRE"
  	_sQuery += "      , SUM(C.FAT_FRETE)  AS TOT_NF_FRE"
  	_sQuery += "      , SUM(C.CRED_ICMS)  AS ICMS_CRED"
  	_sQuery += " FROM C"
    _sQuery += " GROUP BY UF"
    _sQuery += " ORDER BY UF"
    
    //nHandle := FCreate("c:\temp\FRTXLS02.txt")
    //FWrite(nHandle,_sQuery )
    //FClose(nHandle)

    //u_showmemo(_sQuery)
    
    _sAlias_FRETES = GetNextAlias ()
    DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAlias_FRETES, .f., .t.)
    count to _nRecCount
    procregua (_nRecCount)
return
        
Static Function _GeraArq()
     incproc ("Gerando arquivo de exportacao")
     DbGoTop()
     processa ({ || U_Trb2XLS (_sAlias_FRETES, .F.)})
     (_sAlias_FRETE) -> (dbclosearea ())     
return

Static Function _Lista()
        // seta variaveis usadas no relatorio
        cString :="SF2"
        cDesc1  :="Este programa tem como objetivo, imprimir relatorio de"
        cDesc2  :="Analise de Fretes"
        cDesc3  :=""
        aLinha  :={ }
        nLastKey:=0
        titulo   :=""
        wnrel    :="FRT02XLS"            
        tamanho  :="G"
        aReturn :={ "Zebrado", 1,"Administracao", 1, 2, 1, "",1 }
        
        wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
        If nLastKey == 27
            Return
        Endif

        SetDefault(aReturn,cString)
        If nLastKey == 27
            Return
        Endif
        
        titulo   :="Analise de Fretes - Resumo por Estado"
        RptStatus({|| RptDetResumo()})
return

Static Function RptDetResumo()
    SetRegua(LastRec())
    nTipo     := IIF(aReturn[4]==1,15,18)
    li        := 80
    m_pag     := 1
    cabec1    := "      UF   TOTAL FATURAMENTO  NOTAS COM FRETE    PESO BRUTO   VLR DO FRETE    %FAT     VLR_KG      ICMS CREDITADO    CUSTO FRETE        %FAT     VLR_KG
    cabec2    := " "
    _wcont    := 0
    _aFretePer = {0,0}
    _aTotGer   = {0,0,0,0,0,0,0,0,0,0}
    _periodo   = 1
    
    Processa( { |lEnd| _Imprime(1) } )
    
    if dtos(mv_par14) != ' '
        Processa( { |lEnd| _ExecQuery(2) } )
        Processa( { |lEnd| _Imprime(2) } )
    endif
    SetPrc(0,0)
    
    Set Device To Screen

    If aReturn[5]==1
       Set Printer TO
       dbcommitAll()
       ourspool(wnrel)
    Endif
    MS_FLUSH()

return    
    
Static Function _Imprime(_periodo)    
    (_sAlias_FRETE) -> (DBGoTop ())
    
     Do While ! (_sAlias_FRETE) -> (Eof ())
            
         If li>58
            cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
         Endif
         
         if _wcont=0
            if _periodo == 1
                @ li, 001 PSAY "PERIODO: " + dtoc(mv_par12) + ' até '+ dtoc(mv_par13)
            else
                @ li, 001 PSAY "PERIODO: " + dtoc(mv_par14) + ' até '+ dtoc(mv_par15)
            endif    
            li ++
            li ++
            _wcont := 1
         endif
         
         @ li, 006 PSAY (_sAlias_FRETE) -> UF
         @ li, 010 PSAY (_sAlias_FRETE) -> TOT_FAT_UF        Picture "@E 999,999,999,999.99"
         @ li, 031 PSAY (_sAlias_FRETE) -> TOT_NF_FRE        Picture "@E 999,999,999.99"
         @ li, 046 PSAY (_sAlias_FRETE) -> PESO_BRUTO        Picture "@E 99,999,999.99"
         @ li, 061 PSAY (_sAlias_FRETE) -> TOT_FRE           Picture "@E 99,999,999.99"
         @ li, 077 PSAY ROUND((_sAlias_FRETE) -> TOT_FRE /(_sAlias_FRETE) -> TOT_NF_FRE*100,2) Picture "@E 9999.99%"
         @ li, 084 PSAY ROUND((_sAlias_FRETE) -> TOT_FRE /(_sAlias_FRETE) -> PESO_BRUTO,2) Picture "@E 9,999.99"
         @ li, 099 PSAY (_sAlias_FRETE) -> ICMS_CRED         Picture "@E 99,999,999.99"
         _wcustofre = (_sAlias_FRETE) -> TOT_FRE -(_sAlias_FRETE) -> ICMS_CRED
         @ li, 114 PSAY ROUND(_wcustofre,2)  Picture "@E 99,999,999.99"
         @ li, 134 PSAY ROUND(_wcustofre /(_sAlias_FRETE) -> TOT_NF_FRE*100,2) Picture "@E 9999.99%"
         @ li, 144 PSAY ROUND(_wcustofre /(_sAlias_FRETE) -> PESO_BRUTO,2) Picture "@E 9,999.99"
                  
         _aTotGer [1]  += (_sAlias_FRETE) -> TOT_FAT_UF
         _aTotGer [2]  += (_sAlias_FRETE) -> TOT_NF_FRE
         _aTotGer [3]  += (_sAlias_FRETE) -> PESO_BRUTO
         _aTotGer [4]  += (_sAlias_FRETE) -> TOT_FRE
         _aTotGer [5]  += (_sAlias_FRETE) -> ICMS_CRED
         _aTotGer [6]  += _wcustofre 
            
         (_sAlias_FRETE) -> (dbskip())
         li ++
            
     enddo
     // imprime totais
     If li>58
         cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
     Endif
     li ++
     
     @ li, 001 PSAY "TOTAIS:"
     @ li, 009 PSAY _aTotGer [1]                            Picture "@E 9999,999,999,999.99"
     @ li, 031 PSAY _aTotGer [2]                            Picture "@E 999,999,999.99"
     @ li, 046 PSAY _aTotGer [3]                            Picture "@E 99,999,999.99"
     @ li, 061 PSAY _aTotGer [4]                            Picture "@E 99,999,999.99"
     @ li, 078 PSAY ROUND(_aTotGer [4]/_aTotGer [2]*100,2)  Picture "@E 999.99%"
     @ li, 085 PSAY ROUND(_aTotGer [4]/_aTotGer [3],2)      Picture "@E 9,999.99"
     @ li, 099 PSAY _aTotGer [5]                            Picture "@E 999,999,999.99"
     @ li, 114 PSAY _aTotGer [6]                            Picture "@E 999,999,999.99"
     @ li, 135 PSAY ROUND(_aTotGer [6]/_aTotGer [2]*100,2)  Picture "@E 999.99%"
     @ li, 144 PSAY ROUND(_aTotGer [6]/_aTotGer [3],2)      Picture "@E 99,999.99"
     
     li ++
     li ++
     li ++
     
     (_sAlias_FRETE) -> (dbclosearea ())
     
     _aFretePer[_periodo] = ROUND((_aTotGer [4] / _aTotGer [1]) *100 ,2)
	 _wcont  := 0
     _aTotGer = {0,0,0,0,0,0,0,0,0,0}
     
	 if _periodo == 2
   		@ li, 001 PSAY "FRETE SOBRE TOTAL FATURAMENTO :"
   		li ++
   		@ li, 001 PSAY "PERIODO: " + dtoc(mv_par12) + ' até '+ dtoc(mv_par13)
   		@ li, 040 PSAY _aFretePer[1]    Picture "@E 9,999.99%"
   		li ++
   		@ li, 001 PSAY "PERIODO: " + dtoc(mv_par14) + ' até '+ dtoc(mv_par15)
        @ li, 040 PSAY _aFretePer[2]    Picture "@E 9,999.99%"
        li ++
     endif    
     li ++

return

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	 //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                     Help
    aadd (_aRegsPerg, {01, "UF de                         ", "C", 2,  0,  "",   "12 ", {},                        "UF inicial do cliente"})
    aadd (_aRegsPerg, {02, "UF ate                        ", "C", 2,  0,  "",   "12 ", {},                        "UF final do cliente"})
    aadd (_aRegsPerg, {03, "Segmento Cliente de           ", "C", 6,  0,  "",   "T3", {},                         "Segmento inicial do cliente"})
    aadd (_aRegsPerg, {04, "Segmento Cliente até          ", "C", 6,  0,  "",   "T3", {},                         "Segmento final do cliente"})
    aadd (_aRegsPerg, {05, "Canal Cliente de              ", "C", 2,  0,  "",   "ZX518", {},                      "Canal inicial do cliente"})
    aadd (_aRegsPerg, {06, "Canal Cliente até             ", "C", 2,  0,  "",   "ZX518", {},                      "Canal final do cliente"})
    aadd (_aRegsPerg, {07, "Cliente de                    ", "C", 6,  0,  "",   "ZX518", {},                      "Canal inicial do cliente"})
    aadd (_aRegsPerg, {08, "Cliente ate                   ", "C", 6,  0,  "",   "ZX518", {},                      "Canal final do cliente"})
    aadd (_aRegsPerg, {09, "Loja de                       ", "C", 2,  0,  "",   "ZX518", {},                      "Canal inicial do cliente"})
    aadd (_aRegsPerg, {10, "Loja ate                      ", "C", 2,  0,  "",   "ZX518", {},                      "Canal final do cliente"})
    aadd (_aRegsPerg, {11, "Planilia/Relatorio            ", "N", 1,  0,  "",   "   ", {"Planilia ","Relatorio"},   ""})
    aadd (_aRegsPerg, {12, "Data Inicial Periodo 1        ", "D", 8,  0,  "",   "   ", {},                        "Data inicial do primeiro periodo"})
    aadd (_aRegsPerg, {13, "Data Final   Periodo 1        ", "D", 8,  0,  "",   "   ", {},                        "Data final   do primeiro periodo"})
    aadd (_aRegsPerg, {14, "Data Inicial Periodo 2        ", "D", 8,  0,  "",   "   ", {},                        "Data inicial do segundo periodo"})
    aadd (_aRegsPerg, {15, "Data Final   Periodo 2        ", "D", 8,  0,  "",   "   ", {},                        "Data final   do segundo periodo"})
	
	 U_ValPerg (cPerg, _aRegsPerg)
Return