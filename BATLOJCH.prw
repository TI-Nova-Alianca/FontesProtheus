//  Programa...: BATLOJAS
//  Autor......: Catia Cardoso
//  Data.......: 12/12/2018
//  Descricao..: baixa cupons com forma de pagamento cheque
//               RODAR POR FILIAL
// 
//  Historico de alteracoes:
//
//  17/04/2019 - SEPARADO O BAT DE CHEQUES E DE VALOES PRESENTES
//  07/05/2019 - Ajustado para trate so os tipos de tipo CH no SE1
//  
// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

user function BATLOJCH()

	VA_BAICH()
	
return

static function VA_BAICH()
local i:= 0 
	
	// LE VENDAS DE CUPONS DAS LOJAS - PARA ASSOCIADOS
	_sSQL := ""
	_sSQL += " SELECT SL1.L1_FILIAL, SL1.L1_DOC, SL1.L1_NUM, SL4.L4_VALOR"
	_sSQL += "      , SE1.E1_PREFIXO, SL4.L4_FORMA, SL1.L1_OPERADO"
	_sSQL += "      , SE1.E1_PARCELA, SE1.E1_CLIENTE, SE1.E1_LOJA, SE1.E1_EMISSAO"
	_sSQL += "   FROM SL1010 AS SL1"
	_sSQL += " 		INNER JOIN SL4010 AS SL4"
	_sSQL += " 			ON (SL4.D_E_L_E_T_ = ''"
	_sSQL += " 				AND SL4.L4_FILIAL = SL1.L1_FILIAL"
	_sSQL += " 				AND SL4.L4_FORMA  = 'CH'"
	_sSQL += " 				AND SL4.L4_NUM    = SL1.L1_NUM)"
	_sSQL += "   	INNER JOIN SE1010 AS SE1"
	_sSQL += "   		ON (SE1.D_E_L_E_T_ = ''"
	_sSQL += "   			AND SE1.E1_FILIAL  = SL1.L1_FILIAL"
	_sSQL += "   			AND SE1.E1_PREFIXO = SL1.L1_SERIE"
	_sSQL += "           	AND SE1.E1_TIPO    = 'CH'
	_sSQL += "              AND SE1.E1_SALDO > 0"
	_sSQL += "   			AND SE1.E1_NUM = SL1.L1_DOC)"
	_sSQL += "  WHERE SL1.D_E_L_E_T_ = ''"
	_sSQL += "    AND SL1.L1_FILIAL  = '" + xfilial('SL1') + "'"
    _sSQL += "    AND SL1.L1_EMISNF >= '" + dtos(date() -3 ) + "'"
     
	_aVendCH := U_Qry2Array(_sSQL)
	if len(_aVendCH) > 0
	    
		for i=1 to len(_aVendCH)	
			lMsErroAuto := .F.
			// executar a rotina de baixa automatica do SE1 gerando o SE5
			_aAutoSE1 := {}
			aAdd(_aAutoSE1, {"E1_FILIAL" 	, _aVendCH[i,1]	    , Nil})
			aAdd(_aAutoSE1, {"E1_PREFIXO" 	, _aVendCH[i,5]	    , Nil})
			aAdd(_aAutoSE1, {"E1_NUM"     	, _aVendCH[i,2]	    , Nil})
			aAdd(_aAutoSE1, {"E1_PARCELA" 	, _aVendCH[i,8]	    , Nil})
			aAdd(_aAutoSE1, {"E1_CLIENTE" 	, _aVendCH[i,9] 	, Nil})
			aAdd(_aAutoSE1, {"E1_LOJA"    	, _aVendCH[i,10] 	, Nil})
			AAdd(_aAutoSE1, {"AUTMOTBX"		, 'NORMAL'  		, Nil})
			AAdd(_aAutoSE1, {"AUTAGENCIA"  	, '.    ' 		    , Nil})
			AAdd(_aAutoSE1, {"AUTCONTA"  	, '.         '      , Nil})
			AAdd(_aAutoSE1, {"AUTDTBAIXA"	, _aVendCH[i,11]	, Nil})
			AAdd(_aAutoSE1, {"AUTDTCREDITO"	, _aVendCH[i,11]	, Nil})
			AAdd(_aAutoSE1, {"AUTHIST"   	, 'Valor recebido s/Titulo - CH', Nil})
			AAdd(_aAutoSE1, {"AUTDESCONT"	, 0         		, Nil})
			AAdd(_aAutoSE1, {"AUTMULTA"  	, 0         		, Nil})
			AAdd(_aAutoSE1, {"AUTJUROS"  	, 0         		, Nil})
			AAdd(_aAutoSE1, {"AUTVALREC"  	, _aVendCH[i,4] 	, Nil})
			
		   _aAutoSE1 := aclone (U_OrdAuto (_aAutoSE1))  // orderna conforme dicionário de dados
		   
		   cPerg = 'FIN070'
		   _aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
		   U_GravaSX1 (cPerg, "01", 2)
		   U_GravaSX1 (cPerg, "04", 2)
			
           MSExecAuto({|x,y| Fina070(x,y)},_aAutoSE1,3,.F.,5) // rotina automática para baixa de títulos
			
           If lMsErroAuto
           		MostraErro()
			    Return()
		   Endif  
			
		   U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina
		   
		next
	endif			
return