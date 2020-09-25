// Programa...: VA_CMPFUN.PRX
// Autor......: Cláudia Lionço
// Data.......: 01/11/2019
// Descricao..: Programa para geração do relatório de compras de funcionários e 
//				 gera arquivo .TXT de desconto de compras de funcionarios - integracao folha
//
// Historico de alteracoes:
// 01/11/2019 - Cláudia - Migração dos programas ML_COMPFUNC e VA_COMPFUNC para este fonte, realizando a escolha de relatório/arquivo no mesmo fonte.
// 04/03/2020 - Claudia - Ajustada as devoluções de meses diferentes. GLPI:7578
//
// -----------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User Function VA_CMPFUN()
	cPerg1   := "VA_CMPFUN"
	
    _ValP1()
    If Pergunte(cPerg1,.T.)
    	If Mv_Par01 == 1
    		U_VA_RCMPFUN()
    	Else
    		U_VA_ACMPFUN()
    	EndIf
    Endif
Return
// -------------------------------------------------------------------------------------------------------------------------
// Relatório
User function VA_RCMPFUN()
	private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
    delete file (_sArqLog)

    cString := "SL1"
    cDesc1  := "Relatório Compras de Funcionários"
    cDesc2  := ""
    cDesc3  := ""
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    titulo  := "Relatório de Compras de Funcionarios"
    cPerg    := "VA_RCMPFUN"
    wnrel    := "VA_RCMPFUN"
    nTipo    := 0
    
    _ValidPerg()
    Pergunte(cPerg,.F.)
    If Pergunte(cPerg,.T.)
    
    	If mv_par03 > mv_par04
    		u_help ("Erro com o parametro de datas. Verifique!")
    		Return
    	Endif
    	
    	If dtos(mv_par03) = '20181026'
    		If dtos(mv_par04) = '20181125'
    			u_help ("Intervalo de datas, compreende data de reimplantacao das lojas. Necessário listar 2 relatorios. Reimplantacao em 01/11/2018")
    			Return
    		Endif
    	Endif
    	
    	titulo  := "Relatório de Compras de Funcionarios - Período : " + dtoc(mv_par03) + " até " + dtoc(mv_par04)
    	
    	wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
    	If nLastKey == 27
       		Return
    	Endif
    
    	SetDefault(aReturn,cString)
    	If nLastKey == 27
       		Return
    	Endif

    	RptStatus({|| RptDetail()})
    	
	Endif
Return
//
//Static Function RptDetail()
//	local i	:= 0
//	
//    SetRegua(LastRec())
//    nTipo   := IIF(aReturn[4]==1,15,18)
//    li      := 80
//    m_pag   := 1
//    
//    _aTotFunc    = {0,0}
//	_aTotGer     = {0,0}
//	
//    cabec1  :="LOJA COMPRA       DT.COMPRA   NRO.CUPOM      FUNCIONARIO                                        CPF                 FILIAL FUNCIONARIO         VALOR CUPOM     CTB  SITUAÇÃO  NF DEV."
//    cabec2  :=""
//
//	_sSQL := " "
//	_sSQL += " SELECT SL1.L1_FILIAL" 
//    _sSQL += "      , SL1.L1_EMISNF"
//    _sSQL += "      , SL1.L1_DOC"
//    _sSQL += "      , ZAD.ZAD_NOME"
//    _sSQL += "      , SL1.L1_VACGC"
//    _sSQL += "      , ZAD.ZAD_FFILIA"
//	If mv_par11 = 2
//		_sSQL += "      , SL4.L4_VALOR"
//	Else
//		_sSQL += "      , SL1.L1_VLRTOT - SL1.L1_VALES"
//    Endif
//    _sSQL += "      , CASE WHEN SL1.L1_FILIAL = '13' THEN 'CAXIAS' WHEN SL1.L1_FILIAL = '10' THEN 'FLORES' WHEN SL1.L1_FILIAL = '03' THEN 'LIVRAMENTO' ELSE 'VICENTINA' END AS LOJA_NOME"
//    _sSQL += "      , FILIAIS.M0_FILIAL AS FIL_NOME "
//    _sSQL += "      , SL1.L1_INDCTB "
//    _sSQL += "      , ZAD.ZAD_SITUA "
//    _sSQL += "      , SL1.L1_CLIENTE "
//    _sSQL += "      , SL1.L1_LOJA "
//    _sSQL += "      , SL1.L1_SERIE "
//    _sSQL += "      , ISNULL((SELECT"
//	_sSQL += "      	DISTINCT"
//	_sSQL += "      		SD1.D1_DOC"
//	_sSQL += "      	FROM SD1010 SD1"
//	_sSQL += "      		,SF1010 SF1"
//	_sSQL += "      	WHERE SD1.D_E_L_E_T_ = ''"
//	_sSQL += "      	AND SF1.D_E_L_E_T_ = ''"
//	_sSQL += "      	AND SD1.D1_FORNECE = SF1.F1_FORNECE"
//	_sSQL += "      	AND SD1.D1_LOJA = SF1.F1_LOJA"
//	_sSQL += "      	AND SD1.D1_DOC = SF1.F1_DOC"
//	_sSQL += "      	AND SD1.D1_SERIE = SF1.F1_SERIE"
//	_sSQL += "      	AND SF1.F1_TIPO = 'D'"
//	_sSQL += "      	AND SD1.D1_DTDIGIT >= SL1.L1_EMISNF"
//	_sSQL += "      	AND SD1.D1_NFORI = SL1.L1_DOC"
//	_sSQL += "      	AND SD1.D1_SERIORI = SL1.L1_SERIE"
//	_sSQL += "      	AND SD1.D1_FORNECE = SL1.L1_CLIENTE"
//	_sSQL += "      	AND SD1.D1_LOJA = SL1.L1_LOJA)"
//	_sSQL += "      , 'V') AS DOCNF"
//	_sSQL += "      , ISNULL((SELECT"
//	_sSQL += "      	DISTINCT"
//	_sSQL += "      		SD1.D1_SERIE"
//	_sSQL += "      	FROM SD1010 SD1"
//	_sSQL += "      		,SF1010 SF1"
//	_sSQL += "      	WHERE SD1.D_E_L_E_T_ = ''"
//	_sSQL += "      	AND SF1.D_E_L_E_T_ = ''"
//	_sSQL += "      	AND SD1.D1_FORNECE = SF1.F1_FORNECE"
//	_sSQL += "      	AND SD1.D1_LOJA = SF1.F1_LOJA"
//	_sSQL += "      	AND SD1.D1_DOC = SF1.F1_DOC"
//	_sSQL += "      	AND SD1.D1_SERIE = SF1.F1_SERIE"
//	_sSQL += "      	AND SF1.F1_TIPO = 'D'"
//	_sSQL += "      	AND SD1.D1_DTDIGIT >= SL1.L1_EMISNF"
//	_sSQL += "      	AND SD1.D1_NFORI = SL1.L1_DOC"
//	_sSQL += "      	AND SD1.D1_SERIORI = SL1.L1_SERIE"
//	_sSQL += "      	AND SD1.D1_FORNECE = SL1.L1_CLIENTE"
//	_sSQL += "      	AND SD1.D1_LOJA = SL1.L1_LOJA)"
//	_sSQL += "      , 'V') AS SERIENF"
//    _sSQL += "   FROM SL1010 AS SL1"
//    If mv_par11 = 2
//       	_sSQL += " 		INNER JOIN SL4010 AS SL4"
//		_sSQL += " 			ON (SL4.D_E_L_E_T_ = ''"
//		_sSQL += " 				AND SL4.L4_FILIAL  = SL1.L1_FILIAL"
//		_sSQL += " 				AND SL4.L4_NUM     = SL1.L1_NUM"
//		_sSQL += " 				AND SL4.L4_FORMA   = 'CO'"
//		_sSQL += " 				AND SL4.L4_ADMINIS LIKE '%900%' )"
//	Endif	
//	_sSQL += "  	INNER JOIN SF2010 AS SF2"
// 	_sSQL += "			ON (SF2.D_E_L_E_T_ = ''"
// 	_sSQL += "				AND SF2.F2_FILIAL  = L1_FILIAL"
// 	_sSQL += "				AND SF2.F2_DOC     = L1_DOC"
// 	_sSQL += "				AND SF2.F2_SERIE   = L1_SERIE"
// 	_sSQL += "				AND SF2.F2_EMISSAO = L1_EMISNF)"
// 	_sSQL += "  	INNER JOIN ZAD010 AS ZAD"
// 	_sSQL += "			ON (ZAD.D_E_L_E_T_     = ''"
// 	_sSQL += "				AND ZAD.ZAD_CPF    =  L1_CGCCLI"
// 	If mv_par10 = 1
//		_sSQL += "			AND ZAD.ZAD_SITUA IN ('1','2')"  // -- busca so os ativos e afastados	 		
// 	Endif
// 	_sSQL += "				AND ZAD.ZAD_FFILIA BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
// 	_sSQL += "				AND ZAD.ZAD_CPF    BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "')"
//	_sSQL += "  	INNER JOIN VA_SM0 AS FILIAIS"
//	_sSQL += "			ON (FILIAIS.D_E_L_E_T_     = ''"
//	_sSQL += "				AND FILIAIS.M0_CODFIL  = ZAD.ZAD_FFILIA"
//	_sSQL += "				AND FILIAIS.M0_CODIGO  = '01' )"
// 	_sSQL += " WHERE SL1.D_E_L_E_T_  =''"
// 	_sSQL += "   AND SL1.L1_FILIAL   BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
//    _sSQL += "   AND SL1.L1_EMISNF  BETWEEN '" + dtos (mv_par03) + "' and '" + dtos (mv_par04) + "'"
//    _sSQL += "   AND SL1.L1_DOC     !=''"
//    If mv_par11 = 1
//    	_sSQL += "   AND SL1.L1_CONDPG   = '997'"
//    Endif
//    If mv_par09 = 2
//    	_sSQL += " ORDER BY ZAD.ZAD_NOME, SL1.L1_EMISNF"
//	Else
//		_sSQL += " ORDER BY SL1.L1_EMISNF"	    	
//    Endif    	   
//	nHandle := FCreate("c:\temp\logDevolucao.txt")
//	FWrite(nHandle,_sSQL )
//	FClose(nHandle)
//	
//	_aDados := U_Qry2Array(_sSQL)
//	
//	If len(_aDados) > 0
//		_wfunc := ''
//		For i=1 to Len(_aDados)
//			_wfilcompra = _aDados[i,1]
//			_wemissao   = _aDados[i,2]
//			_wdoc       = _aDados[i,3]
//			_wnome      = _aDados[i,4]
//			_wcpf       = _aDados[i,5]
//			_wfilfunc   = _aDados[i,6]
//			_wvalor     = _aDados[i,7]
//			_wnomeloja  = _aDados[i,8]
//			_wnomefil   = _aDados[i,9]
//			_windctb    = _aDados[i,10]
//			_wsitua     = _aDados[i,11] 
//			_wcliente   = _aDados[i,12]
//			_wloja      = _aDados[i,13]
//			_wdocserie  = _aDados[i,14]
//			_wnfdev     = _aDados[i,15]
//			_wserdev    = _aDados[i,16]
//				
//			If alltrim(_wnfdev) != 'V' // devoluções
//				_wdev     := "DEVOLUÇÃO"
//				_wnotadev := alltrim(_wnfdev) + "/" + alltrim(_wserdev)  
//			Else
//				_wdev     := "-"
//				_wnotadev := "-"
//			EndIf
//			
//			If mv_par09 = 2
//				If li>67
//         			cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
//           		Endif	
//				If _wfunc <> _wnome .and. _aTotFunc[1] > 0
//					@ li, 116 PSAY "Total do Funcionario:"
//   					@ li, 142 PSAY _aTotFunc [1] Picture "@E 9,999,999.99"
//   					li:=li + 2
//    				_aTotFunc[1] := 0
//				Endif
//			Endif
//			
//			If li>67
//           		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
//           	Endif        
//        	
//		    @li,  00 PSAY _wfilcompra + '-' + _wnomeloja 
//	        @li,  18 PSAY _wemissao
//	        @li,  31 PSAY _wdoc
//	        @li,  45 PSAY _wnome
//	        @li,  96 PSAY _wcpf   Picture "@R 999.999.999-99"
//	        @li, 116 PSAY _wfilfunc + '-' + _wnomefil 
//	        @li, 143 PSAY _wvalor Picture "@E 9,999,999.99"
//	        @li, 160 PSAY _windctb
//	        @li, 165 PSAY _wdev
//	        @li, 175 PSAY _wnotadev
//	        If val(_wsitua) > 2
//				@li, 190 PSAY "FUNCIONARIO DESLIGADO" 
//	        Endif  
//		    li:=li + 1
//
//			// acumula total em compras
//	        If mv_par09 = 2
//	        	If alltrim(_wnfdev) == 'V' // vendas
//	        		_aTotFunc[1] += _aDados[i,7]
//	        	EndIf
//			Endif	    
//			If alltrim(_wnfdev) == 'V' // vendas
//	        	_aTotGer [1] += _aDados[i,7]
//	        EndIf
//	        _wfunc = _wnome
//					
//		Next
//	Endif		
//		
//	If mv_par09 = 2
//		If _aTotFunc[1] > 0
//			If li>67
//         		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
//           	Endif        
//			@ li, 116 PSAY "Total do Funcionario:"
//			@ li, 142 PSAY _aTotFunc [1] Picture "@E 9,999,999.99"
//			li:=li + 1
//			_aTotFunc[1] := 0
//		Endif				
//	Endif 								
//	
//	If li>67
//    	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
//    EndIf     
//
//    li:=li + 2   
//	@ li, 116 PSAY "TOTAL GERAL:"
//	@ li, 142 PSAY _aTotGer [1] Picture "@E 9,999,999.99"
//	li:=li + 2
//	
//	U_ImpParam (60)
//	      
//    Set Device To Screen
//
//    If aReturn[5]==1
//       Set Printer TO
//       dbcommitAll()
//       ourspool(wnrel)
//    Endif
//
//    MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)
//Return	

Static Function RptDetail()
	local i	:= 0
	
    SetRegua(LastRec())
    nTipo   := IIF(aReturn[4]==1,15,18)
    li      := 80
    m_pag   := 1
    
    _aTotFunc    = {0,0}
	_aTotGer     = {0,0}
	
    cabec1  :="LOJA COMPRA       DT.COMPRA   DOCUMENTO      FUNCIONARIO                                        CPF                 FILIAL FUNCIONARIO         VALOR CUPOM     CTB  SITUAÇÃO  DOC.ORIGEM"
    cabec2  :=""

	_sSQL := " "
	_sSQL += " WITH C"
	_sSQL += " AS"
	_sSQL += " (SELECT"
	_sSQL += " 		SL1.L1_FILIAL AS FILIAL"
	_sSQL += " 	   ,SL1.L1_EMISNF AS EMISSAO"
	_sSQL += " 	   ,SL1.L1_DOC AS DOCUMENTO"
	_sSQL += " 	   ,ZAD.ZAD_NOME AS NOME"
	_sSQL += " 	   ,SL1.L1_VACGC AS CPF"
	_sSQL += " 	   ,ZAD.ZAD_FFILIA AS FILIAL_CLIENTE"
	If mv_par11 = 2
		_sSQL += " 	   ,SL4.L4_VALOR AS VALOR"
	Else
		_sSQL += "      , SL1.L1_VLRTOT - SL1.L1_VALES AS VALOR"
	 Endif
	_sSQL += " 	   ,CASE"
	_sSQL += " 			WHEN SL1.L1_FILIAL = '13' THEN 'CAXIAS'"
	_sSQL += " 			WHEN SL1.L1_FILIAL = '10' THEN 'FLORES'"
	_sSQL += " 			WHEN SL1.L1_FILIAL = '03' THEN 'LIVRAMENTO'"
	_sSQL += " 			ELSE 'VICENTINA'"
	_sSQL += " 		END AS LOJA_NOME"
	_sSQL += " 	   ,FILIAIS.M0_FILIAL AS FIL_NOME"
	_sSQL += " 	   ,SL1.L1_INDCTB AS CTB"
	_sSQL += " 	   ,ZAD.ZAD_SITUA AS SITUACAO"
	_sSQL += "     ,SL1.L1_CLIENTE AS CLIENTE "
	_sSQL += "     ,SL1.L1_LOJA AS LOJA"
	_sSQL += "     ,SL1.L1_SERIE AS SERIE"
	_sSQL += " 	   ,'' AS NF_ORIGEM"
	_sSQL += " 	   ,'' AS SERIE_ORIGEM"
	_sSQL += " 	   ,'VENDA' AS TIPO"
	_sSQL += " 	FROM SL1010 AS SL1"
	If mv_par11 = 2
		_sSQL += " 	INNER JOIN SL4010 AS SL4"
		_sSQL += " 		ON (SL4.D_E_L_E_T_ = ''"
		_sSQL += " 		AND SL4.L4_FILIAL = SL1.L1_FILIAL"
		_sSQL += " 		AND SL4.L4_NUM = SL1.L1_NUM"
		_sSQL += " 		AND SL4.L4_FORMA = 'CO'"
		_sSQL += " 		AND SL4.L4_ADMINIS LIKE '%900%')"
	EndIf
	_sSQL += " 	INNER JOIN SF2010 AS SF2"
	_sSQL += " 		ON (SF2.D_E_L_E_T_ = ''"
	_sSQL += " 		AND SF2.F2_FILIAL = L1_FILIAL"
	_sSQL += " 		AND SF2.F2_DOC = L1_DOC"
	_sSQL += " 		AND SF2.F2_SERIE = L1_SERIE"
	_sSQL += " 		AND SF2.F2_EMISSAO = L1_EMISNF)"
	_sSQL += " 	INNER JOIN ZAD010 AS ZAD"
	_sSQL += " 		ON (ZAD.D_E_L_E_T_ = ''"
	_sSQL += " 		AND ZAD.ZAD_CPF = L1_CGCCLI"
	If mv_par10 = 1
		_sSQL += " 		AND ZAD.ZAD_SITUA IN ('1', '2')" // -- busca so os ativos e afastados
	EndIf
	_sSQL += " 		AND ZAD.ZAD_FFILIA BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
	_sSQL += " 		AND ZAD.ZAD_CPF BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "')"
	_sSQL += " 	INNER JOIN VA_SM0 AS FILIAIS"
	_sSQL += " 		ON (FILIAIS.D_E_L_E_T_ = ''"
	_sSQL += " 		AND FILIAIS.M0_CODFIL = ZAD.ZAD_FFILIA"
	_sSQL += " 		AND FILIAIS.M0_CODIGO = '01')"
	_sSQL += " 	WHERE SL1.D_E_L_E_T_ = ''"
	_sSQL += " 	AND SL1.L1_FILIAL BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_sSQL += " 	AND SL1.L1_EMISNF BETWEEN '" + dtos (mv_par03) + "' and '" + dtos (mv_par04) + "'"
	_sSQL += " 	AND SL1.L1_DOC != ''"
	If mv_par11 = 1
		_sSQL += "   AND SL1.L1_CONDPG   = '997'"
	EndIf
	_sSQL += " 	UNION ALL"
	_sSQL += " 	SELECT DISTINCT"
	_sSQL += " 		SD1.D1_FILIAL AS FILIAL"
	_sSQL += " 	   ,SD1.D1_EMISSAO AS EMISSAO"
	_sSQL += " 	   ,SD1.D1_DOC AS DOCUMENTO"
	_sSQL += " 	   ,ZAD.ZAD_NOME AS NOME"
	_sSQL += " 	   ,SL1.L1_VACGC AS CPF"
	_sSQL += " 	   ,ZAD.ZAD_FFILIA AS FILIAL_CLIENTE"
	If mv_par11 = 2
		_sSQL += "      , (SL4.L4_VALOR * -1) AS VALOR"
	Else
		_sSQL += "      , ((SL1.L1_VLRTOT - SL1.L1_VALES) * -1) AS VALOR"
	Endif
	_sSQL += " 	   ,CASE"
	_sSQL += " 			WHEN SL1.L1_FILIAL = '13' THEN 'CAXIAS'"
	_sSQL += " 			WHEN SL1.L1_FILIAL = '10' THEN 'FLORES'"
	_sSQL += " 			WHEN SL1.L1_FILIAL = '03' THEN 'LIVRAMENTO'"
	_sSQL += " 			ELSE 'VICENTINA'"
	_sSQL += " 		END AS LOJA_NOME"
	_sSQL += " 	   ,FILIAIS.M0_FILIAL AS FIL_NOME"
	_sSQL += " 	   ,SL1.L1_INDCTB AS CTB"
	_sSQL += " 	   ,ZAD.ZAD_SITUA AS SITUACAO"
	_sSQL += "     ,SL1.L1_CLIENTE "
	_sSQL += "     ,SL1.L1_LOJA "
	_sSQL += "     ,SL1.L1_SERIE "
	_sSQL += " 	   ,SD1.D1_NFORI AS NF_ORIGEM"
	_sSQL += " 	   ,SD1.D1_SERIORI AS SERIE_ORIGEM"
	_sSQL += " 	   ,'DEVOLUÇÃO' AS TIPO"
	_sSQL += " 	FROM SD1010 SD1"
	_sSQL += " 	INNER JOIN SF1010 SF1"
	_sSQL += " 		ON (SF1.D_E_L_E_T_ = ''"
	_sSQL += " 		AND SD1.D1_FORNECE = SF1.F1_FORNECE"
	_sSQL += " 		AND SD1.D1_LOJA = SF1.F1_LOJA"
	_sSQL += " 		AND SD1.D1_DOC = SF1.F1_DOC"
	_sSQL += " 		AND SD1.D1_SERIE = SF1.F1_SERIE"
	_sSQL += " 		AND SF1.F1_TIPO = 'D')"
	_sSQL += " 	RIGHT JOIN SL1010 SL1"
	_sSQL += " 		ON (SL1.D_E_L_E_T_ = ''"
	_sSQL += " 		AND SD1.D1_NFORI = SL1.L1_DOC"
	_sSQL += " 		AND SD1.D1_SERIORI = SL1.L1_SERIE"
	_sSQL += " 		AND SD1.D1_FORNECE = SL1.L1_CLIENTE"
	_sSQL += " 		AND SD1.D1_LOJA = SL1.L1_LOJA "
	If mv_par11 = 1
		_sSQL += "   	AND SL1.L1_CONDPG   = '997'"
	EndIf
	_sSQL += "		)"
	_sSQL += " 	INNER JOIN SL4010 AS SL4"
	_sSQL += " 		ON (SL4.D_E_L_E_T_ = ''"
	_sSQL += " 		AND SL4.L4_FILIAL = SL1.L1_FILIAL"
	_sSQL += " 		AND SL4.L4_NUM = SL1.L1_NUM"
	_sSQL += " 		AND SL4.L4_FORMA = 'CO'"
	_sSQL += " 		AND SL4.L4_ADMINIS LIKE '%900%')"
	_sSQL += " 	INNER JOIN ZAD010 AS ZAD"
	_sSQL += " 		ON (ZAD.D_E_L_E_T_ = ''"
	_sSQL += " 		AND ZAD.ZAD_CPF = L1_CGCCLI"
	If mv_par10 = 1
	_sSQL += " 		AND ZAD.ZAD_SITUA IN ('1', '2')"
	EndIf
	_sSQL += " 		AND ZAD.ZAD_FFILIA BETWEEN  '" + mv_par07 + "' AND '" + mv_par08 + "'"
	_sSQL += " 		AND ZAD.ZAD_CPF BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "')"
	_sSQL += " 	INNER JOIN VA_SM0 AS FILIAIS"
	_sSQL += " 		ON (FILIAIS.D_E_L_E_T_ = ''"
	_sSQL += " 		AND FILIAIS.M0_CODFIL = ZAD.ZAD_FFILIA"
	_sSQL += " 		AND FILIAIS.M0_CODIGO = '01')"
	_sSQL += " 	WHERE SD1.D_E_L_E_T_ = ''"
	_sSQL += "  AND SD1.D1_FILIAL BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_sSQL += " 	AND SD1.D1_EMISSAO BETWEEN '" + dtos (mv_par03) + "' and '" + dtos (mv_par04) + "'"
	_sSQL += " 	)"
	_sSQL += " SELECT"
	_sSQL += " 	*"
	_sSQL += " FROM C"
	If mv_par09 = 2
		_sSQL += " ORDER BY NOME, EMISSAO, TIPO"
	Else
		_sSQL += " ORDER BY EMISSAO"
	EndIf

//	nHandle := FCreate("c:\temp\logDevolucao.txt")
//	FWrite(nHandle,_sSQL )
//	FClose(nHandle)
	
	_aDados := U_Qry2Array(_sSQL)
	
	If len(_aDados) > 0
		_wfunc := ''
		For i=1 to Len(_aDados)
			_wfilcompra = _aDados[i,1]
			_wemissao   = _aDados[i,2]
			_wdoc       = _aDados[i,3]
			_wnome      = _aDados[i,4]
			_wcpf       = _aDados[i,5]
			_wfilfunc   = _aDados[i,6]
			_wvalor     = _aDados[i,7]
			_wnomeloja  = _aDados[i,8]
			_wnomefil   = _aDados[i,9]
			_windctb    = _aDados[i,10]
			_wsitua     = _aDados[i,11] 
			_wcliente   = _aDados[i,12]
			_wloja      = _aDados[i,13]
			_wdocserie  = _aDados[i,14]
			_wnfOrigem  = _aDados[i,15]
			_wserieori  = _aDados[i,16] 
			_wtipo      = _aDados[i,17] 
			//_wnfdev     = _aDados[i,15]
			//_wserdev    = _aDados[i,16]

				
			If alltrim(_wtipo) != 'VENDA' // devoluções
				_wdev     := _wtipo
				_wnotadev := alltrim(_wnfOrigem) + "/" + alltrim(_wserieori)  
			Else
				_wdev     := _wtipo
				_wnotadev := "-"
			EndIf
			
			If mv_par09 = 2
				If li>67
         			cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           		Endif	
				If _wfunc <> _wnome .and. _aTotFunc[1] > 0
					@ li, 116 PSAY "Total do Funcionario:"
   					@ li, 142 PSAY _aTotFunc [1] Picture "@E 9,999,999.99"
   					li:=li + 2
    				_aTotFunc[1] := 0
				Endif
			Endif
			
			If li>67
           		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           	Endif        
        	
		    @li,  00 PSAY _wfilcompra + '-' + _wnomeloja 
	        @li,  18 PSAY _wemissao
	        @li,  31 PSAY _wdoc
	        @li,  45 PSAY _wnome
	        @li,  96 PSAY _wcpf   Picture "@R 999.999.999-99"
	        @li, 116 PSAY _wfilfunc + '-' + _wnomefil 
	        @li, 143 PSAY _wvalor Picture "@E 9,999,999.99"
	        @li, 160 PSAY _windctb
	        @li, 165 PSAY _wdev
	        @li, 175 PSAY _wnotadev
	        If val(_wsitua) > 2
				@li, 190 PSAY "FUNCIONARIO DESLIGADO" 
	        Endif  
		    li:=li + 1

			// acumula total em compras
	        If mv_par09 = 2
	        	//If alltrim(_wtipo) == 'VENDA' // vendas
	        		_aTotFunc[1] += _aDados[i,7]
	        	//EndIf
			Endif	    
			//If alltrim(_wtipo) == 'VENDA' // vendas
	        	_aTotGer [1] += _aDados[i,7]
	        //EndIf
	        _wfunc = _wnome
					
		Next
	Endif		
		
	If mv_par09 = 2
		If _aTotFunc[1] > 0
			If li>67
         		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           	Endif        
			@ li, 116 PSAY "Total do Funcionario:"
			@ li, 142 PSAY _aTotFunc [1] Picture "@E 9,999,999.99"
			li:=li + 1
			_aTotFunc[1] := 0
		Endif				
	Endif 								
	
	If li>67
    	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
    EndIf     

    li:=li + 2   
	@ li, 116 PSAY "TOTAL GERAL:"
	@ li, 142 PSAY _aTotGer [1] Picture "@E 9,999,999.99"
	li:=li + 2
	
	U_ImpParam (60)
	      
    Set Device To Screen

    If aReturn[5]==1
       Set Printer TO
       dbcommitAll()
       ourspool(wnrel)
    Endif

    MS_FLUSH() // Libera fila de relatorios em spool (Tipo Rede Netware)
Return	
//
//
//
//
//
// -------------------------------------------------------------------------------------------------------------------------
// Geração do Arquivo .TXT
User function VA_ACMPFUN()
	local i	:= 0
	
	cPerg2  := "VA_ACMPFUN"

    _ValP2()
    If Pergunte(cPerg2,.T.)
        	
    	If mv_par01 > mv_par02
    		u_help ("Erro com o parametro de datas. Verifique!")
    		Return
    	Endif
    	
    	If dtos(mv_par01) = '20181026'
    		If dtos(mv_par02) = '20181125'
    			u_help ("Intervalo de datas, compreende data de reimplantacao das lojas. Necessário listar 2 relatorios. Reimplantacao em 01/11/2018")
    			Return
    		Endif
    	Endif
    	
    	// Antes da Reimplantação Lojas
    	If mv_par06 == 1 // antes da implantação
			_sSQL := " "
			_sSQL += " SELECT SL1.L1_VACGC"
			_sSQL += "      , SUM(SL1.L1_VLRTOT - SL1.L1_VALES)*100"
		    _sSQL += "   FROM SL1010 AS SL1" 	
			_sSQL += "  	INNER JOIN SF2010 AS SF2"
		 	_sSQL += "			ON (SF2.D_E_L_E_T_ = ''"
		 	_sSQL += "				AND SF2.F2_FILIAL  = L1_FILIAL"
		 	_sSQL += "				AND SF2.F2_DOC     = L1_DOC"
		 	_sSQL += "				AND SF2.F2_SERIE   = L1_SERIE"
		 	_sSQL += "				AND SF2.F2_EMISSAO = L1_EMISNF)"
		 	_sSQL += "  	INNER JOIN ZAD010 AS ZAD"
		 	_sSQL += "			ON (ZAD.D_E_L_E_T_     = ''"
		 	_sSQL += "				AND ZAD.ZAD_CPF    BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
		 	If mv_par05 = 1
				_sSQL += "				AND ZAD.ZAD_SITUA IN ('1','2')"  // -- busca so os ativos e afastados	 		
		 	Endif
		 	_sSQL += "				AND ZAD.ZAD_CPF    =  L1_CGCCLI)"
			_sSQL += " WHERE SL1.D_E_L_E_T_  =''"
		 	_sSQL += "   AND SL1.L1_EMISNF  BETWEEN '" + dtos (mv_par01) + "' and '" + dtos (mv_par02) + "'"
		   	_sSQL += "   AND SL1.L1_DOC     !=''"
		   	_sSQL += "   AND SL1.L1_CONDPG   = '997'"
		    _sSQL += " GROUP BY SL1.L1_VACGC "
		    _sSQL += " ORDER BY SL1.L1_VACGC"  
	    Endif
	    //
	    //
	    // Depois da Reimplantação Lojas
	    If mv_par06 == 2
	    	_sSQL := " "
			_sSQL += " WITH C"
			_sSQL += " AS"
			_sSQL += " (SELECT"
			_sSQL += " 	   SL1.L1_VACGC AS CPF"
			_sSQL += " 	   ,SL4.L4_VALOR AS VALOR"
			_sSQL += " 	FROM SL1010 AS SL1"
			_sSQL += " 	INNER JOIN SL4010 AS SL4"
			_sSQL += " 		ON (SL4.D_E_L_E_T_ = ''"
			_sSQL += " 		AND SL4.L4_FILIAL = SL1.L1_FILIAL"
			_sSQL += " 		AND SL4.L4_NUM = SL1.L1_NUM"
			_sSQL += " 		AND SL4.L4_FORMA = 'CO'"
			_sSQL += " 		AND SL4.L4_ADMINIS LIKE '%900%')"
			_sSQL += " 	INNER JOIN SF2010 AS SF2"
			_sSQL += " 		ON (SF2.D_E_L_E_T_ = ''"
			_sSQL += " 		AND SF2.F2_FILIAL = L1_FILIAL"
			_sSQL += " 		AND SF2.F2_DOC = L1_DOC"
			_sSQL += " 		AND SF2.F2_SERIE = L1_SERIE"
			_sSQL += " 		AND SF2.F2_EMISSAO = L1_EMISNF)"
			_sSQL += " 	INNER JOIN ZAD010 AS ZAD"
			_sSQL += " 		ON (ZAD.D_E_L_E_T_ = ''"
			_sSQL += " 		AND ZAD.ZAD_CPF = L1_CGCCLI"
			If mv_par05 = 1
				_sSQL += " 		AND ZAD.ZAD_SITUA IN ('1', '2')" // -- busca so os ativos e afastados
			EndIf
			_sSQL += " 		AND ZAD.ZAD_CPF BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "')"   
			_sSQL += " 	INNER JOIN VA_SM0 AS FILIAIS"
			_sSQL += " 		ON (FILIAIS.D_E_L_E_T_ = ''"
			_sSQL += " 		AND FILIAIS.M0_CODFIL = ZAD.ZAD_FFILIA"
			_sSQL += " 		AND FILIAIS.M0_CODIGO = '01')"
			_sSQL += " 	WHERE SL1.D_E_L_E_T_ = ''"
			_sSQL += " 	AND SL1.L1_EMISNF BETWEEN '" + dtos (mv_par01) + "' and '" + dtos (mv_par02) + "'"
			_sSQL += " 	AND SL1.L1_DOC != ''"
			_sSQL += " 	UNION ALL"
			_sSQL += " 	SELECT DISTINCT"
			_sSQL += " 	    SL1.L1_VACGC AS CPF"
			_sSQL += "      , (SL4.L4_VALOR * -1) AS VALOR"
			_sSQL += " 	FROM SD1010 SD1"
			_sSQL += " 	INNER JOIN SF1010 SF1"
			_sSQL += " 		ON (SF1.D_E_L_E_T_ = ''"
			_sSQL += " 		AND SD1.D1_FORNECE = SF1.F1_FORNECE"
			_sSQL += " 		AND SD1.D1_LOJA = SF1.F1_LOJA"
			_sSQL += " 		AND SD1.D1_DOC = SF1.F1_DOC"
			_sSQL += " 		AND SD1.D1_SERIE = SF1.F1_SERIE"
			_sSQL += " 		AND SF1.F1_TIPO = 'D')"
			_sSQL += " 	RIGHT JOIN SL1010 SL1"
			_sSQL += " 		ON (SL1.D_E_L_E_T_ = ''"
			_sSQL += " 		AND SD1.D1_NFORI = SL1.L1_DOC"
			_sSQL += " 		AND SD1.D1_SERIORI = SL1.L1_SERIE"
			_sSQL += " 		AND SD1.D1_FORNECE = SL1.L1_CLIENTE"
			_sSQL += " 		AND SD1.D1_LOJA = SL1.L1_LOJA "
			_sSQL += "		)"
			_sSQL += " 	INNER JOIN SL4010 AS SL4"
			_sSQL += " 		ON (SL4.D_E_L_E_T_ = ''"
			_sSQL += " 		AND SL4.L4_FILIAL = SL1.L1_FILIAL"
			_sSQL += " 		AND SL4.L4_NUM = SL1.L1_NUM"
			_sSQL += " 		AND SL4.L4_FORMA = 'CO'"
			_sSQL += " 		AND SL4.L4_ADMINIS LIKE '%900%')"
			_sSQL += " 	INNER JOIN ZAD010 AS ZAD"
			_sSQL += " 		ON (ZAD.D_E_L_E_T_ = ''"
			_sSQL += " 		AND ZAD.ZAD_CPF = L1_CGCCLI"
			If mv_par05 = 1
			_sSQL += " 		AND ZAD.ZAD_SITUA IN ('1', '2')"
			EndIf
			_sSQL += " 		AND ZAD.ZAD_CPF BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "')"
			_sSQL += " 	INNER JOIN VA_SM0 AS FILIAIS"
			_sSQL += " 		ON (FILIAIS.D_E_L_E_T_ = ''"
			_sSQL += " 		AND FILIAIS.M0_CODFIL = ZAD.ZAD_FFILIA"
			_sSQL += " 		AND FILIAIS.M0_CODIGO = '01')"
			_sSQL += " 	WHERE SD1.D_E_L_E_T_ = ''"
			_sSQL += " 	AND SD1.D1_EMISSAO BETWEEN '" + dtos (mv_par01) + "' and '" + dtos (mv_par02) + "'"
			_sSQL += " 	)"
			_sSQL += " SELECT"
			_sSQL += " 		CPF "
		    _sSQL += "      ,SUM(VALOR) * 100 "
			_sSQL += " FROM C "
			_sSQL += " GROUP BY CPF "
			_sSQL += " ORDER BY CPF "
	    EndIf
//	    // Depois da Reimplantação Lojas
//    	If mv_par06 = 2 // depois da implantação
//	    	_sSQL := " "
//			_sSQL += " WITH C "
//			_sSQL += " AS "
//			_sSQL += " ( SELECT SL1.L1_VACGC AS CGC "
//			_sSQL += "      ,SL4.L4_VALOR AS VALOR "
//			_sSQL += "      ,ISNULL((SELECT "
//			_sSQL += "      DISTINCT "
//			_sSQL += "      	SD1.D1_NFORI "
//			_sSQL += "      FROM SD1010 SD1 "
//			_sSQL += "      	,SF1010 SF1 "
//			_sSQL += "      WHERE SD1.D_E_L_E_T_ = '' "
//			_sSQL += "      AND SF1.D_E_L_E_T_ = '' "
//			_sSQL += "      AND SD1.D1_FORNECE = SF1.F1_FORNECE "
//			_sSQL += "      AND SD1.D1_LOJA = SF1.F1_LOJA "
//			_sSQL += "      AND SD1.D1_DOC = SF1.F1_DOC "
//			_sSQL += "      AND SD1.D1_SERIE = SF1.F1_SERIE "
//			_sSQL += "      AND SF1.F1_TIPO = 'D' "
//			_sSQL += "      AND SD1.D1_DTDIGIT >= SL1.L1_EMISNF "
//			_sSQL += "      AND SD1.D1_NFORI = SL1.L1_DOC "
//			_sSQL += "      AND SD1.D1_SERIORI = SL1.L1_SERIE "
//			_sSQL += "      AND SD1.D1_FORNECE = SL1.L1_CLIENTE "
//			_sSQL += "      AND SD1.D1_LOJA = SL1.L1_LOJA) "
//			_sSQL += "      , 'V') AS TIPVEN "
//		    _sSQL += "   FROM SL1010 AS SL1 " 
//	       	_sSQL += " 		INNER JOIN SL4010 AS SL4 "
//			_sSQL += " 			ON (SL4.D_E_L_E_T_ = '' "
//			_sSQL += " 				AND SL4.L4_FILIAL  = SL1.L1_FILIAL "
//			_sSQL += " 				AND SL4.L4_NUM     = SL1.L1_NUM "
//			_sSQL += " 				AND SL4.L4_FORMA   = 'CO' "
//			_sSQL += " 				AND SL4.L4_ADMINIS LIKE '%900%' ) "
//			_sSQL += "  	INNER JOIN SF2010 AS SF2 "
//		 	_sSQL += "			ON (SF2.D_E_L_E_T_ = '' "
//		 	_sSQL += "				AND SF2.F2_FILIAL  = L1_FILIAL "
//		 	_sSQL += "				AND SF2.F2_DOC     = L1_DOC "
//		 	_sSQL += "				AND SF2.F2_SERIE   = L1_SERIE "
//		 	_sSQL += "				AND SF2.F2_EMISSAO = L1_EMISNF) "
//		 	_sSQL += "  	INNER JOIN ZAD010 AS ZAD "
//		 	_sSQL += "			ON (ZAD.D_E_L_E_T_     = '' "
//		 	_sSQL += "				AND ZAD.ZAD_CPF    BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "'"
//		 	If mv_par05 = 1
//				_sSQL += "				AND ZAD.ZAD_SITUA IN ('1','2')"  // -- busca so os ativos e afastados	 		
//		 	Endif
//		 	_sSQL += "				AND ZAD.ZAD_CPF    =  L1_CGCCLI)"
//			_sSQL += " WHERE SL1.D_E_L_E_T_  =''"
//		 	_sSQL += "   AND SL1.L1_EMISNF  BETWEEN '" + dtos (mv_par01) + "' and '" + dtos (mv_par02) + "'"
//		   	_sSQL += "   AND SL1.L1_DOC     !='' )"
//			_sSQL += " SELECT "
//			_sSQL += " 	CGC "
//			_sSQL += "    ,SUM(VALOR) * 100 "
//			_sSQL += " FROM C "
//			_sSQL += " WHERE TIPVEN = 'V' "
//			_sSQL += " GROUP BY CGC "
//			_sSQL += " ORDER BY CGC "
//    	EndIf
    	
	    nHandle := FCreate("c:\temp\arquivo_rh_fun.txt")
	    FWrite(nHandle,_sSQL )
	    FClose(nHandle)

	    _aDados := U_Qry2Array(_sSQL)
		if len(_aDados) > 0
			_wlinha = ''
			_sArq = "C:\TEMP\COMPRAS_LOJAS.TXT"
			_nHdl = fcreate(_sArq, 0)
			for i=1 to len(_aDados)
				_wlinha := alltrim(_aDados [i,1]) + strzero(_aDados [i,2],12)
				fwrite (_nHdl, _wlinha + chr (13) + chr (10))
			next
			fclose (_nHdl)
			u_help ("Arquivo gerado em: C:\TEMP\ Arquivo: COMPRAS_LOJAS.TXT")
		endif
	endif						
return	
// -------------------------------------------------------------------------------------------------------------------------
// Perguntas arquivo .txt
Static Function _ValP2()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data Inicial         ?", "D", 8, 0,  "",  "   ", {}							, ""})
    aadd (_aRegsPerg, {02, "Data Final           ?", "D", 8, 0,  "",  "   ", {}							, ""})
    aadd (_aRegsPerg, {03, "Funcionario          ?", "C",11, 0,  "",  "ZAD", {}							, "Funcioanrio Inicial"})
	aadd (_aRegsPerg, {04, "Funcionario          ?", "C",11, 0,  "",  "ZAD", {}							, "Funcionario Final"})
	aadd (_aRegsPerg, {05, "Considera demitidos  ?", "N", 1, 0,  "",  "   ", {"Nao"						, "Sim"}, ""})
	aadd (_aRegsPerg, {06, "Reimplantação lojas  ?", "N", 1, 0,  "",  "   ", {"Antes", "Depois"}		, ""})
	
    U_ValPerg (cPerg2, _aRegsPerg)
Return

// -------------------------------------------------------------------------------------------------------------------------
// Perguntas relatório
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Loja de                 ?", "C", 2, 0,  "",  "SM0", {},                         ""})
    aadd (_aRegsPerg, {02, "Loja até                ?", "C", 2, 0,  "",  "SM0", {},                         ""})
    aadd (_aRegsPerg, {03, "Data de Compra          ?", "D", 8, 0,  "",  "   ", {},                         ""})
    aadd (_aRegsPerg, {04, "Data de Compra          ?", "D", 8, 0,  "",  "   ", {},                         ""})
    aadd (_aRegsPerg, {05, "Funcionario             ?", "C",11, 0,  "",  "ZAD", {},                         "Funcionario Inicial"})
	aadd (_aRegsPerg, {06, "Funcionario             ?", "C",11, 0,  "",  "ZAD", {},                         "Funcionario Final"})
	aadd (_aRegsPerg, {07, "Filial Funcionário de   ?", "C", 2, 0,  "",  "SM0", {},                         ""})
    aadd (_aRegsPerg, {08, "Filial Funcionário até  ?", "C", 2, 0,  "",  "SM0", {},                         ""})
    aadd (_aRegsPerg, {09, "Total por Funcionário   ?", "N", 1, 0,  "",  "   ", {"Nao", "Sim"}, ""})
	aadd (_aRegsPerg, {10, "Considera demitidos     ?", "N", 1, 0,  "",  "   ", {"Nao", "Sim"}, ""})
	aadd (_aRegsPerg, {11, "Reimplantação Lojas     ?", "N", 1, 0,  "",  "   ", {"Antes", "Depois"}, ""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
// -------------------------------------------------------------------------------------------------------------------------
// Perguntas iniciais
Static Function _ValP1 ()
    local _aRegsPerg := {}
    //                     PERGUNT   TIPO TAM DEC VALID F3     Opcoes                      Help
	aadd (_aRegsPerg, {01, "Geração ", "N", 1, 0,  "",  "   ", {"Relatório", "Arquivo"}, ""})
	
    U_ValPerg (cPerg1, _aRegsPerg)
Return