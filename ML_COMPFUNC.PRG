//  Programa...: ML_COMPFUN
//  Autor......: Catia Cardoso
//  Data.......: 27/11/2015
//  Descricao..: relatorio de compras de funcionarios
//  Historico de alteracoes:
//
//  24/10/2016 - Alterada Query de L1_EMISSAO para L1_EMISNF - por conta de cupom com data de orçamento diferente da data de emissao da NF
//  08/12/2016 - Alterada WHEN para setar o nome da filial do funcionario - incluida a filial 03
//  12/04/2017 - Verificada alteracao prevendo o camp novo da situacao ao inves da data de desligamento
//  27/03/2018 - Alteração para que se parte do cupom foi paga com vale que gere so a diferença em desconto em folha
//  25/10/2018 - Alterado Relatorio para que considere a reimplantação das lojas - cond 997 e forma de pagamento
//  26/11/2018 - Buscar o valor correto conforme a forma de pagamento
//  25/03/2019 - erro na query "ZAD.manta460" - ??? - onde devia estar buscando a situacao

#include "rwmake.ch"
#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function ML_COMPFUNC()

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
// Limite 10 caracteres -->    cPerg   := "ML_COMPFUNC"
    cPerg   := "ML_COMPFUN"
    wnrel   := "ML_COMPFUNC"
    nTipo   := 0
    
    _ValidPerg()
    Pergunte(cPerg,.F.)
    if Pergunte(cPerg,.T.)
    
    	if mv_par03 > mv_par04
    		u_help ("Erro com o parametro de datas. Verifique!")
    		return
    	endif
    	
    	if dtos(mv_par03) = '20181026'
    		if dtos(mv_par04) = '20181125'
    			u_help ("Intervalo de datas, compreende data de reimplantacao das lojas. Necessário listar 2 relatorios. Reimplantacao em 01/11/2018")
    			return
    		endif
    	endif
    	
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
    	
	endif
return

Static Function RptDetail()
	local i := 0
	
    SetRegua(LastRec())
    nTipo   := IIF(aReturn[4]==1,15,18)
    li      := 80
    m_pag   := 1
    
    _aTotFunc = {0,0}
	_aTotGer  = {0,0}
			        
    cabec1  :="LOJA COMPRA       DT.COMPRA   NRO.CUPOM      FUNCIONARIO                                        CPF                 FILIAL FUNCIONARIO         VALOR CUPOM     CTB  SITUAÇÃO"
    cabec2  :=""

	_sSQL := " "
	_sSQL += " SELECT SL1.L1_FILIAL" 
    _sSQL += "      , SL1.L1_EMISNF"
    _sSQL += "      , SL1.L1_DOC"
    _sSQL += "      , ZAD.ZAD_NOME"
    _sSQL += "      , SL1.L1_VACGC"
    _sSQL += "      , ZAD.ZAD_FFILIA"
	if mv_par11 = 2
		_sSQL += "      , SL4.L4_VALOR"
	else
		_sSQL += "      , SL1.L1_VLRTOT - SL1.L1_VALES"
    endif
    _sSQL += "      , CASE WHEN SL1.L1_FILIAL = '13' THEN 'CAXIAS' WHEN SL1.L1_FILIAL = '10' THEN 'FLORES' WHEN SL1.L1_FILIAL = '03' THEN 'LIVRAMENTO' ELSE 'VICENTINA' END AS LOJA_NOME"
    _sSQL += "      , FILIAIS.M0_FILIAL AS FIL_NOME "
    _sSQL += "      , SL1.L1_INDCTB "
    _sSQL += "      , ZAD.ZAD_SITUA "
    _sSQL += "      , SL1.L1_CLIENTE "
    _sSQL += "      , SL1.L1_LOJA "
    _sSQL += "      , SL1.L1_SERIE "
    _sSQL += "   FROM SL1010 AS SL1"
    if mv_par11 = 2
       	_sSQL += " 		INNER JOIN SL4010 AS SL4"
		_sSQL += " 			ON (SL4.D_E_L_E_T_ = ''"
		_sSQL += " 				AND SL4.L4_FILIAL  = SL1.L1_FILIAL"
		_sSQL += " 				AND SL4.L4_NUM     = SL1.L1_NUM"
		_sSQL += " 				AND SL4.L4_FORMA   = 'CO'"
		_sSQL += " 				AND SL4.L4_ADMINIS LIKE '%900%' )"
	endif	
	_sSQL += "  	INNER JOIN SF2010 AS SF2"
 	_sSQL += "			ON (SF2.D_E_L_E_T_ = ''"
 	_sSQL += "				AND SF2.F2_FILIAL  = L1_FILIAL"
 	_sSQL += "				AND SF2.F2_DOC     = L1_DOC"
 	_sSQL += "				AND SF2.F2_SERIE   = L1_SERIE"
 	_sSQL += "				AND SF2.F2_EMISSAO = L1_EMISNF)"
 	_sSQL += "  	INNER JOIN ZAD010 AS ZAD"
 	_sSQL += "			ON (ZAD.D_E_L_E_T_     = ''"
 	_sSQL += "				AND ZAD.ZAD_CPF    =  L1_CGCCLI"
 	if mv_par10 = 1
		_sSQL += "			AND ZAD.ZAD_SITUA IN ('1','2')"  // -- busca so os ativos e afastados	 		
 	endif
 	_sSQL += "				AND ZAD.ZAD_FFILIA BETWEEN '" + mv_par07 + "' AND '" + mv_par08 + "'"
 	_sSQL += "				AND ZAD.ZAD_CPF    BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "')"
	_sSQL += "  	INNER JOIN VA_SM0 AS FILIAIS"
	_sSQL += "			ON (FILIAIS.D_E_L_E_T_     = ''"
	_sSQL += "				AND FILIAIS.M0_CODFIL  = ZAD.ZAD_FFILIA"
	_sSQL += "				AND FILIAIS.M0_CODIGO  = '01' )"
 	_sSQL += " WHERE SL1.D_E_L_E_T_  =''"
 	_sSQL += "   AND SL1.L1_FILIAL   BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
    _sSQL += "   AND SL1.L1_EMISNF  BETWEEN '" + dtos (mv_par03) + "' and '" + dtos (mv_par04) + "'"
    _sSQL += "   AND SL1.L1_DOC     !=''"
    if mv_par11 = 1
    	_sSQL += "   AND SL1.L1_CONDPG   = '997'"
    endif
    if mv_par09 = 2
    	_sSQL += " ORDER BY ZAD.ZAD_NOME, SL1.L1_EMISNF"
	else
		_sSQL += " ORDER BY SL1.L1_EMISNF"	    	
    endif    	   
			
	_aDados := U_Qry2Array(_sSQL)
	if len(_aDados) > 0
		_wfunc := ''
		for i=1 to len(_aDados)
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

			_dDt := DTOS(_wemissao)
			
			_sSQL1 := " "
			_sSQL1 += " SELECT "
			_sSQL1 += " 	SD1.D1_NFORI "
			_sSQL1 += " FROM SD1010 SD1 "
			_sSQL1 += " 	,SF1010 SF1 "
			_sSQL1 += " WHERE SD1.D_E_L_E_T_ = '' "
			_sSQL1 += " AND SF1.D_E_L_E_T_   = '' "
			_sSQL1 += " AND SD1.D1_FORNECE   = SF1.F1_FORNECE "
			_sSQL1 += " AND SD1.D1_LOJA      = SF1.F1_LOJA "
			_sSQL1 += " AND SD1.D1_DOC 		 = SF1.F1_DOC "
			_sSQL1 += " AND SD1.D1_SERIE 	 = SF1.F1_SERIE "
			_sSQL1 += " AND SF1.F1_TIPO 	 = 'D' "
			_sSQL1 += " AND SD1.D1_DTDIGIT 	>= '" + _dDt        + "'"
			_sSQL1 += " AND SD1.D1_FILIAL 	 = '" + _wfilcompra + "'"
			_sSQL1 += " AND SD1.D1_NFORI 	 = '" + _wdoc       + "'"
			_sSQL1 += " AND SD1.D1_SERIORI   = '" + _wdocserie  + "'"
			_sSQL1 += " AND SD1.D1_FORNECE 	 = '" + _wcliente   + "'"
			_sSQL1 += " AND SD1.D1_LOJA 	 = '" + _wloja      + "'"
			
			_aDev := U_Qry2Array(_sSQL1)
			
			If len(_aDev) > 0
				_wdev := "DEVOLUÇÃO"
			Else
				_wdev := "-"
			EndIf
			
			if mv_par09 = 2
				If li>67
         			cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           		Endif	
				if _wfunc <> _wnome .and. _aTotFunc[1] > 0
					@ li, 116 PSAY "Total do Funcionario:"
   					@ li, 142 PSAY _aTotFunc [1] Picture "@E 9,999,999.99"
   					li:=li + 2
    				_aTotFunc[1] := 0
				endif
			endif
			
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
	        if val(_wsitua) > 2
				@li, 175 PSAY "FUNCIONARIO DESLIGADO" 
	        endif  
		    li:=li + 1

			// acumula total em compras
	        if mv_par09 = 2
	        	_aTotFunc[1] += _aDados[i,7]
			endif	        	
	        _aTotGer [1] += _aDados[i,7]
	        _wfunc = _wnome
					
		next
	endif		
		
	if mv_par09 = 2
		if _aTotFunc[1] > 0
			If li>67
         		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           	Endif        
			@ li, 116 PSAY "Total do Funcionario:"
			@ li, 142 PSAY _aTotFunc [1] Picture "@E 9,999,999.99"
			li:=li + 1
			_aTotFunc[1] := 0
		endif				
	endif 								
	
	if li>67
    	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
    Endif     

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
	
	
return	

// --------------------------------------------------------------------------
// Cria Perguntas no SX1
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