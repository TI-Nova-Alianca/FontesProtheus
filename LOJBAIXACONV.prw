// Programa...: LOJBAICACONV
// Autor......: Catia Cardoso
// Data.......: 07/02/2019
// Descricao..: Baixa titulos de VP ou Convenios
//
// Historico de alteracoes:
// 08/04/2019 - Catia  - include TbiConn.ch
// 17/04/2019 - Catia  - estava dando erro na data de baixa 
// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

user function LOJBAIXACONV()
	local i := 0
	cPerg   := "LOJBAIXACONV"
	
	if ! u_zzuvl ('043', __cUserId, .T.)
		return
	endif
    
	_ValidPerg()
	if mv_par01 > mv_par02
		msgalert ("Data inicial maior que a data final.")
		_ValidPerg()
	endif
	
    if Pergunte(cPerg,.T.) 
    	
    	_whistorico := ""
    	_wcompldescr := ""
		_sSQL := ""
	    _sSQL += " SELECT '' AS MARCA, SE1.E1_FILIAL, SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA"
	    _sSQL += "       , SE1.E1_TIPO, SE1.E1_EMISSAO, SE1.E1_VENCREA, SE1.E1_VALOR, SE1.E1_CLIENTE, SE1.E1_LOJA""
	    _sSQL += "   FROM SE1010 AS SE1"
	    _sSQL += "   	INNER JOIN SL1010 AS SL1"
		_sSQL += "   		ON (SL1.D_E_L_E_T_ = ''"
		_sSQL += "   			AND SL1.L1_FILIAL = SE1.E1_FILIAL"
		_sSQL += "   			AND SL1.L1_DOC    = SE1.E1_NUM"
		_sSQL += "   			AND SL1.L1_SERIE  = SE1.E1_PREFIXO)"
		_sSQL += "   	INNER JOIN SL4010 AS SL4"
		_sSQL += "   		ON (SL4.D_E_L_E_T_ = ''"
		_sSQL += "   			AND SL4.L4_FILIAL = SE1.E1_FILIAL"
		_sSQL += "   			AND SL4.L4_NUM    = SL1.L1_NUM"
		_sSQL += "   			AND SL4.L4_FORMA  = SE1.E1_TIPO"
		do case
			case mv_par03 = 2
				_sSQL += "   			AND SL4.L4_ADMINIS LIKE '%900 %'"
				_whistorico := "CO - VLR.BAIXA TIT.COMPRA FUNCIONARIO"
				_wcompldescr  := " - Compras Funcionarios" 
			case mv_par03 = 3	
				_sSQL += "   			AND SL4.L4_ADMINIS LIKE '%800 %'"
				_whistorico := "CO - VLR.BAIXA TIT.COMPRA ASSOCIADO"
				_wcompldescr  := " - Compras Associados"
		endcase
		_sSQL += "   			AND SL4.L4_VALOR  = SE1.E1_VALOR)"
	    _sSQL += "  WHERE SE1.D_E_L_E_T_ = ''"
	    _sSQL += "    AND SE1.E1_FILIAL  =  '" + xfilial('SE1') + "'"
	    _sSQL += "    AND SE1.E1_EMISSAO BETWEEN  '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
	    if mv_par03 = 1
	    	_sSQL += "    AND SE1.E1_TIPO    = 'VP' "
	    	_whistorico := 'VP - VLR.BAIXA TIT.VALE PRESENTE'
	    	_wcompldescr  := " - Vales Presente"
		else 
	    	_sSQL += "    AND SE1.E1_TIPO    = 'CO' "
	    endif	
	    _sSQL += "    AND SE1.E1_SALDO   > 0"
	    
	    _aDados  := U_Qry2Array(_sSQL)
	    _aColsMB = {}
		
		aadd (_aColsMB, { 2,  "Loja"      , 40,  "@!"})
	    aadd (_aColsMB, { 3,  "Prefixo"   , 40,  "@!"})
	    aadd (_aColsMB, { 4,  "Numero"    , 40,  "@!"})
	    aadd (_aColsMB, { 5,  "Parcela"   , 10,  "@!"})
	    aadd (_aColsMB, { 6,  "Tipo"      , 10,  "@!"})
	    aadd (_aColsMB, { 7,  "Emissao"   , 50,  "@D"})
	    aadd (_aColsMB, { 8,  "Vencimento", 50,  "@D"})
	    aadd (_aColsMB, { 9,  "Valor"     , 50,  "@E 999,999.99"})
	    
	    for i=1 to len(_aDados)
	    	_aDados[i,1] = .F.
    	next
	    
	    U_MBArray (@_aDados,"Baixa Titulos de Convenio " + _wcompldescr, _aColsMB, 1,  oMainWnd:nClientWidth - 50 ,550, ".T.")
	    
		cPerg = 'FIN070'
		_aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
		U_GravaSX1 (cPerg, "01", 2)
		U_GravaSX1 (cPerg, "04", 2)
		
		_wdtbaixa = mv_par04
		for i=1 to len(_aDados)
			if _aDados[i,1] = .T.
				lMsErroAuto := .F.
				// executar a rotina de baixa automatica do SE1 gerando o SE5 - sem contabilizacao
				_aAutoSE1 := {}
	
				aAdd(_aAutoSE1, {"E1_FILIAL" 	, _aDados[i,2]	    , Nil})
				aAdd(_aAutoSE1, {"E1_PREFIXO" 	, _aDados[i,3]	    , Nil})
				aAdd(_aAutoSE1, {"E1_NUM"     	, _aDados[i,4]	    , Nil})
				aAdd(_aAutoSE1, {"E1_PARCELA" 	, _aDados[i,5]	    , Nil})
				aAdd(_aAutoSE1, {"E1_CLIENTE" 	, _aDados[i,10] 	, Nil})
				aAdd(_aAutoSE1, {"E1_LOJA"    	, _aDados[i,11] 	, Nil})
				aAdd(_aAutoSE1, {"E1_TIPO"    	, _aDados[i,6] 		, Nil})
				AAdd(_aAutoSE1, {"AUTMOTBX"		, 'DACAO'  	  	    , Nil})
				AAdd(_aAutoSE1, {"AUTAGENCIA"  	, '' 		    	, Nil})
				AAdd(_aAutoSE1, {"AUTCONTA"  	, ''      			, Nil})
				AAdd(_aAutoSE1, {"AUTDTBAIXA"	, _wdtbaixa			, Nil})
				AAdd(_aAutoSE1, {"AUTDTCREDITO"	, _wdtbaixa			, Nil})
				AAdd(_aAutoSE1, {"AUTHIST"   	, _whistorico		, Nil})
				AAdd(_aAutoSE1, {"AUTDESCONT"	, 0         		, Nil})
				AAdd(_aAutoSE1, {"AUTMULTA"  	, 0         		, Nil})
				AAdd(_aAutoSE1, {"AUTJUROS"  	, 0         		, Nil})
				AAdd(_aAutoSE1, {"AUTVALREC"  	, _aDados[i,9] 		, Nil})
				
			   _aAutoSE1 := aclone (U_OrdAuto (_aAutoSE1))  // orderna conforme dicionário de dados
			
			   MSExecAuto({|x,y| Fina070(x,y)},_aAutoSE1,3,.F.,5) // rotina automática para baixa de títulos
			   
	           If lMsErroAuto
	           		MostraErro()
				    Return()
			   Endif  
		   endif
		next
	endif
	U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina	
return		
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                      Help
    aadd (_aRegsPerg, {01, "Data Inicial  ?", "D", 8,  0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {02, "Data final    ?", "D", 8,  0,  "",   "   ", {},  ""})
    aadd (_aRegsPerg, {03, "Tipo          ?", "N", 1,  0,  "",   "   ", {"Vale Presente","Funcionários","Associados"}, ""})
    aadd (_aRegsPerg, {04, "Data p/Baixa  ?", "D", 8,  0,  "",   "   ", {},  ""})
    
    U_ValPerg (cPerg, _aRegsPerg)
Return