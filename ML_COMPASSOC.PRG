//  Programa...: ML_COMPASSOC
//  Autor......: Catia Cardoso
//  Data.......: 08/02/2019
//  Descricao..: relatorio de compras de associacao
//  Historico de alteracoes:
//

#include "rwmake.ch"
#IFNDEF WINDOWS
    #DEFINE PSAY SAY
#ENDIF

User function ML_COMPASSOC()

private _sArqLog := procname () + "_" + alltrim (cUserName) + ".log"
    delete file (_sArqLog)

    cString := "SL1"
    cDesc1  := "Relatório Compras de Associados"
    cDesc2  := ""
    cDesc3  := ""
    tamanho := "G"
    aReturn := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
    aLinha  := {}
    nLastKey:= 0
    titulo  := "Relatório de Compras de Associados"
    cPerg   := "ML_COMPASSOC"
    wnrel   := "ML_COMPASSOC"
    nTipo   := 0
    
    _ValidPerg()
    Pergunte(cPerg,.F.)
    if Pergunte(cPerg,.T.)
    
    	if mv_par03 > mv_par04
    		u_help ("Erro com o parametro de datas. Verifique!")
    		return
    	endif
    	
    	titulo  := "Relatório de Compras de Associados - Período : " + dtoc(mv_par03) + " até " + dtoc(mv_par04)
    	
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
    
    _aTotAssoc = {0,0}
	_aTotGer  = {0,0}
			        
    cabec1  :="LOJA COMPRA       DT.COMPRA   NRO.CUPOM      ASSOCIADO                                          CODIGO                                          VALOR CUPOM    INT.C/C"
    cabec2  :=""

	_sSQL := " "
	_sSQL += " SELECT SL1.L1_FILIAL" 
    _sSQL += "      , SL1.L1_EMISNF"
    _sSQL += "      , SL1.L1_DOC"
    _sSQL += "      , SA2.A2_NOME"
    _sSQL += "      , SA2.A2_COD"
	_sSQL += "      , SL4.L4_VALOR" 
    _sSQL += "      , CASE WHEN SL1.L1_FILIAL = '13' THEN 'CAXIAS' WHEN SL1.L1_FILIAL = '10' THEN 'FLORES' WHEN SL1.L1_FILIAL = '03' THEN 'LIVRAMENTO' ELSE 'VICENTINA' END AS LOJA_NOME"
    _sSQL += "      , SL1.L1_INDCTB"
    _sSQL += "      , SA2.A2_LOJA"
    _sSQL += "   FROM SL1010 AS SL1"
   	_sSQL += " 		INNER JOIN SL4010 AS SL4"
	_sSQL += " 			ON (SL4.D_E_L_E_T_ = ''"
	_sSQL += " 				AND SL4.L4_FILIAL  = SL1.L1_FILIAL"
	_sSQL += " 				AND SL4.L4_NUM     = SL1.L1_NUM"
	_sSQL += " 				AND SL4.L4_FORMA   = 'CO'"
	_sSQL += " 				AND SL4.L4_ADMINIS LIKE '%800 %' )"
 	_sSQL += "		INNER JOIN SA2010 AS SA2"
	_sSQL += "			ON (SA2.D_E_L_E_T_  = ''"
	_sSQL += "				AND SA2.A2_CGC  = SL1.L1_CGCCLI"
	_sSQL += "				AND SA2.A2_LOJA = SL1.L1_LOJA"
 	_sSQL += "				AND SA2.A2_COD  BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "')"
	_sSQL += " WHERE SL1.D_E_L_E_T_  =''"
 	_sSQL += "   AND SL1.L1_FILIAL   BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
    _sSQL += "   AND SL1.L1_EMISNF  BETWEEN '" + dtos (mv_par03) + "' and '" + dtos (mv_par04) + "'"
    _sSQL += "   AND SL1.L1_DOC     !=''"
    if mv_par07 = 2
    	_sSQL += " ORDER BY SA2.A2_NOME, SL1.L1_EMISNF"
	else
		_sSQL += " ORDER BY SL1.L1_EMISNF"	    	
    endif    	   
	
	//u_showmemo(_sSQL)

	_aDados := U_Qry2Array(_sSQL)
	if len(_aDados) > 0
		_wassoc:= ''
		for i=1 to len(_aDados)
			_wfilcompra = _aDados[i,1]
			_wemissao   = _aDados[i,2]
			_wdoc       = _aDados[i,3]
			_wnome      = _aDados[i,4]
			_wcod       = _aDados[i,5] + '-' +_aDados[i,9]
			_wvalor     = _aDados[i,6]
			_wnomeloja  = _aDados[i,7]
			_windctb    = _aDados[i,8]
			
			if mv_par07 = 2
				If li>60
         			cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           		Endif	
				if _wassoc<> _wnome .and. _aTotAssoc[1] > 0
					@ li, 116 PSAY "Total do Associado :"
   					@ li, 143 PSAY _aTotAssoc [1] Picture "@E 9,999,999.99"
   					li:=li + 2
    				_aTotAssoc[1] := 0
				endif
			endif
			
			If li>60
           		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           	Endif        
        	
		    @li,  00 PSAY _wfilcompra + '-' + _wnomeloja 
	        @li,  18 PSAY _wemissao
	        @li,  31 PSAY _wdoc
	        @li,  45 PSAY _wnome
	        @li,  96 PSAY _wcod
	        @li, 143 PSAY _wvalor Picture "@E 9,999,999.99"
	        @li, 160 PSAY _windctb
	         
		    li:=li + 1

			// acumula total em compras
	        if mv_par07 = 2
	        	_aTotAssoc[1] += _wvalor
			endif	        	
	        _aTotGer [1] += _wvalor
	        _wassoc = _wnome
					
		next
	endif		
		
	if mv_par07 = 2
		if _aTotAssoc[1] > 0
			If li>60
         		cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
           	Endif        
			@ li, 116 PSAY "Total do Associado:"
			@ li, 143 PSAY _aTotAssoc [1] Picture "@E 9,999,999.99"
			li:=li + 1
			_aTotAssoc[1] := 0
		endif				
	endif 								
	
	if li>60
    	cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
    Endif     

    li:=li + 2   
	@ li, 116 PSAY "TOTAL GERAL:"
	@ li, 143 PSAY _aTotGer [1] Picture "@E 9,999,999.99"
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
    aadd (_aRegsPerg, {05, "Associado de            ?", "C", 6, 0,  "",  "SA2", {},                         "Associado Inicial"})
	aadd (_aRegsPerg, {06, "Associado até           ?", "C", 6, 0,  "",  "SA2", {},                         "Associado Final"})
	aadd (_aRegsPerg, {07, "Total por Associado     ?", "N", 1, 0,  "",  "   ", {"Nao", "Sim"}, ""})
    U_ValPerg (cPerg, _aRegsPerg)
Return