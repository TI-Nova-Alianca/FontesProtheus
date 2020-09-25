//  Programa...: ML_COMPPTPPAG
//  Autor......: Catia Cardoso
//  Data.......: 26/02/2019
//  Descricao..: relatorio de VENDAS DAS LOJAS POR TIPO DE PAGAMENTO
//  Historico de alteracoes:
//
//  26/03/2019 - Catia - Alterado para que nao considere os vales presentes - serie 999 - do RH
//  07/06/2019 - Catia - incluido contador de quantidade de cupons no dia/periodo
//  10/06/2019 - Catia - incluido numero no nsu a credito e a debito
#include "rwmake.ch"
#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function ML_COMPPTPPAG()

private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
    delete file (_sArqLog)

    cString := "SL4"
    cDesc1  := "Relatório Vendas Lojas p/Tipo de Pagamento"
    cDesc2  := ""
    cDesc3  := ""
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    titulo  := "Relatório Vendas Lojas p/Tipo de Pagamento"
    cPerg   := "ML_COMPPTPAG"
    wnrel   := "ML_COMPPTPAG"
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
    
Static Function RptDetail()
	local i := 0

    SetRegua(LastRec())
    nTipo    := IIF(aReturn[4]==1,15,18)
    li       := 80
    m_pag    := 1
    _aTotGer  = {0,0,0,0,0,0,0,0,0,0,0}
    		        
    cabec1  :=" CUPOM   SERIE  EMISSAO       VLR.CUPOM  VLR.DINHEIRO  VLR.CHEQUES  VLR.CONVENIO    VLR.VALES  VLR.CARTAO CC  VLR.CARTAO CD     T O T A L      NSU_CC      NSU_CD"
    cabec2  :=""

	_sSQL := " "
	_sSQL += " SELECT SL1.L1_DOC, SL1.L1_SERIE, dbo.VA_DTOC(SL1.L1_EMISNF), SL1.L1_VLRTOT"
    _sSQL += "  	, SL1.L1_DINHEIR, SL1.L1_CHEQUES"
	_sSQL += "  	, SL1.L1_CONVENI, SL1.L1_VALES"
	_sSQL += "  	, SL1.L1_CARTAO"
	_sSQL += "  	, SL1.L1_VLRDEBI"
	_sSQL += "  	, SL1.L1_VLRDEBI + SL1.L1_DINHEIR + SL1.L1_CHEQUES + SL1.L1_CONVENI + SL1.L1_VALES + SL1.L1_CARTAO AS SOMA_FORMAS_PAG"
	_sSQL += "  	, IIF (ROUND(SL1.L1_VLRTOT - ( SL1.L1_VLRDEBI + SL1.L1_DINHEIR + SL1.L1_CHEQUES + SL1.L1_CONVENI + SL1.L1_VALES + SL1.L1_CARTAO),2)=0, 'OK','ERRO') AS VERIFICACAO_SL1"
	_sSQL += "		, ISNULL((SELECT TOP 1 L4_NSUTEF"
	_sSQL += "     				FROM SL4010"
	_sSQL += "    			   WHERE L4_FILIAL =  SL1.L1_FILIAL"
	_sSQL += "	  				 AND L4_NUM    =  SL1.L1_NUM"
	_sSQL += "	  				 AND L4_FORMA  = 'CC'),'') AS NSU_CC"
	_sSQL += "		, ISNULL((SELECT TOP 1 L4_NSUTEF"
	_sSQL += "	 				FROM SL4010"
	_sSQL += "    			   WHERE L4_FILIAL = SL1.L1_FILIAL"
	_sSQL += "	  				 AND L4_NUM    = SL1.L1_NUM"
	_sSQL += "	  				 AND L4_FORMA  = 'CD'),'') AS NSU_CD"
	_sSQL += "   FROM SL1010 AS SL1"
	_sSQL += "  WHERE SL1.D_E_L_E_T_ = ''"
	_sSQL += "    AND SL1.L1_FILIAL  = '" + xfilial ("SL1") + "'"
	_sSQL += "    AND SL1.L1_SERIE  != '999'"
    _sSQL += "    AND SL1.L1_EMISNF  BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
    _sSQL += "    AND SL1.L1_SITUA  = 'OK'"
    
    _sSQL1 := " "
	_sSQL1 += " SELECT SL4.L4_FORMA"
    _sSQL1 += "  	 , SL4.L4_ADMINIS"
    _sSQL1 += "  	 , SUM(SL4.L4_VALOR)"
    _sSQL1 += "   FROM SL4010 AS SL4"
	_sSQL1 += " 	INNER JOIN SL1010 AS SL1"
	_sSQL1 += " 		ON (SL1.L1_FILIAL  = SL4.L4_FILIAL"
	_sSQL1 += " 			AND SL1.L1_NUM = SL4.L4_NUM"
	_sSQL1 += " 			AND SL1.L1_EMISNF BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	_sSQL1 += " 			AND SL1.L1_SITUA  = 'OK')"
	_sSQL1 += "  WHERE SL4.L4_FILIAL = '" + xfilial ("SL4") + "'"
	_sSQL1 += "    AND SL4.L4_FORMA IN ('CC','CD', 'CO')"
	_sSQL1 += "    AND SL4.D_E_L_E_T_ = ''"
	_sSQL1 += "    AND SL4.L4_ADMINIS NOT LIKE '004 %'"
	_sSQL1 += "  GROUP BY SL4.L4_FORMA, SL4.L4_ADMINIS"
	_sSQL1 += "  ORDER BY SL4.L4_FORMA, SL4.L4_ADMINIS"
   
	//u_showmemo(_sSQL1)
	_aDados1 := U_Qry2Array(_sSQL1)
	_aDados  := U_Qry2Array(_sSQL)
	if len(_aDados) > 0
		
		for i=1 to len(_aDados)
			_wdoc       = _aDados[i,1]
			_wserie     = _aDados[i,2]
			_wemissao   = _aDados[i,3]
			_wvlrTOT    = _aDados[i,4]
			_wvlrDIN    = _aDados[i,5]
			_wvlrCH     = _aDados[i,6]
			_wvlrCONV   = _aDados[i,7]
			_wvlrVP     = _aDados[i,8]
			_wvlrCC     = _aDados[i,9]
			_wvlrCD     = _aDados[i,10]
			_wvlrsoma   = _aDados[i,11]
			_wsnuCC     = _aDados[i,13]
			_wsnuCD     = _aDados[i,14]
			
			if mv_par03 = 1 // opcao analitica 
			
				If li>67
	           		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
	           	Endif        
	        	
			    @li, 01 PSAY _wdoc 
		        @li, 11 PSAY _wserie
		        @li, 16 PSAY _wemissao
		        @li, 30 PSAY _wvlrTOT  Picture "@E 999,999.99"
		        @li, 43 PSAY _wvlrDIN  Picture "@E 999,999.99"
		        @li, 56 PSAY _wvlrCH   Picture "@E 999,999.99" 
		        @li, 70 PSAY _wvlrCONV Picture "@E 999,999.99"
		        @li, 83 PSAY _wvlrVP   Picture "@E 999,999.99"
		        @li, 98 PSAY _wvlrCC   Picture "@E 999,999.99"
		        @li,113 PSAY _wvlrCD   Picture "@E 999,999.99"
		        @li,127 PSAY _wvlrsoma Picture "@E 999,999.99"
		        @li,143 PSAY _wsnuCC 
		        @li,155 PSAY _wsnuCD 
		        
			    li:=li + 1
			    
			endif

	        _aTotGer [1] += _wvlrTOT
	        _aTotGer [2] += _wvlrDIN
	        _aTotGer [3] += _wvlrCH
	        _aTotGer [4] += _wvlrCONV
	        _aTotGer [5] += _wvlrVP
	        _aTotGer [6] += _wvlrCC
	        _aTotGer [7] += _wvlrCD
	        _aTotGer [8] += _wvlrsoma
	        _aTotGer [9] += 1
					
		next
	endif		
	
	if li>67
    	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
    Endif     

    li:=li + 2   
	@ li, 001 PSAY "TOTAIS:"
	@ li, 020 PSAY _aTotGer [9] Picture "@E 9999"
	@ li, 030 PSAY _aTotGer [1] Picture "@E 999,999.99"
	@ li, 043 PSAY _aTotGer [2] Picture "@E 999,999.99"
	@ li, 056 PSAY _aTotGer [3] Picture "@E 999,999.99"
	@ li, 070 PSAY _aTotGer [4] Picture "@E 999,999.99"
	@ li, 083 PSAY _aTotGer [5] Picture "@E 999,999.99"
	@ li, 098 PSAY _aTotGer [6] Picture "@E 999,999.99"
	@ li, 113 PSAY _aTotGer [7] Picture "@E 999,999.99"
	@ li, 127 PSAY _aTotGer [8] Picture "@E 999,999.99"
	
	li:=li + 2
	
	if len(_aDados1) > 0
		@ li, 001 PSAY "RESUMO:"
		for i=1 to len(_aDados1)
			@li, 11 PSAY alltrim(_aDados1[i,1])
	        @li, 16 PSAY alltrim(_aDados1[i,2])
	        @li, 43 PSAY _aDados1[i,3]  Picture "@E 999,999.99"
	        
			If li>67
           		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           	Endif     
           	   
           	li:=li + 1
		next
	endif
	
	U_ImpParam (67)
	      
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
    
    aadd (_aRegsPerg, {01, "Emissao de      ?", "D", 8, 0,  "",  "   ", {},                         ""})
    aadd (_aRegsPerg, {02, "Emissao até     ?", "D", 8, 0,  "",  "   ", {},                         ""})
    aadd (_aRegsPerg, {03, "Opção Desejada   ", "N", 1, 0,  "",  "   ", {"Analitico","Sintetico"},  ""})
     U_ValPerg (cPerg, _aRegsPerg)
Return