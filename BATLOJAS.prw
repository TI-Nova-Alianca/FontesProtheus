//  Programa...: BATLOJAS
//  Autor......: Catia Cardoso
//  Data.......: 12/12/2018
//  Descricao..: estorna pagamento de cupons de VP
//               RODAR POR FILIAL
// 
//  Historico de alteracoes:
//
//  09/01/2019 - ajuste na baixa dos cheques pq NAO DEVE CONTABILIZAR - a contabilizacao é feita pelo faturamento off-line
//  06/02/2019 - refeito o estorno dos vales para que use tambem por rotina automatica para que ja fique ok a tabela de saldos bancarios
//  14/02/2019 - tinha ficado um showmemo aberto
//  08/04/2019 - Catia  - include TbiConn.ch 
//  17/04/2019 - SEPARADO O BAT DE CHEQUES E DE VALOES PRESENTES
//  17/06/2019 - Robert - Removidos testes e logs diversos ref. travamento quando rodava em batch
//

// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

user function BATLOJAS()
	// estona VP
	VA_ESTVP()
	
return

static function VA_ESTVP()
	local i := 0

	_sSQL  = "" 
	_sSQL += " SELECT SE1.E1_FILIAL, SE1.E1_PREFIXO, SE1.E1_NUM"
	_sSQL += "      , SE1.E1_PARCELA, SE1.E1_CLIENTE, SE1.E1_LOJA, SE1.E1_EMISSAO, SE1.E1_VALOR, SE1.E1_BAIXA"
	_sSQL += "      , SE1.E1_TIPO"
	_sSQL += "   FROM SE1010 AS SE1"
	_sSQL += "  WHERE SE1.D_E_L_E_T_ = ''"
	_sSQL += "    AND SE1.E1_FILIAL  = '" + xfilial('SE1') + "'"
	_sSQL += "    AND SE1.E1_EMISSAO >= '" + dtos(date() -5) + "'"
	_sSQL += "    AND SE1.E1_SALDO   = 0 " 
	_sSQL += "    AND SE1.E1_TIPO    = 'VP'"
	_aVendVP := U_Qry2Array(_sSQL)
	
	if len(_aVendVP) > 0
		for i=1 to len(_aVendVP)
		 	
			// FAZ A EXCLUSAO DA BAIXA PELA ROTINA AUTOMATICA PARA DEIXAR O SALDO BANCARIO CORRETO
			lMsErroAuto := .F.
			_aAutoSE1   := {}
			aAdd(_aAutoSE1, {"E1_FILIAL" 	, _aVendVP[i,1]	    , Nil})
			aAdd(_aAutoSE1, {"E1_PREFIXO" 	, _aVendVP[i,2]	    , Nil})
			aAdd(_aAutoSE1, {"E1_NUM"     	, _aVendVP[i,3]	    , Nil})
			aAdd(_aAutoSE1, {"E1_PARCELA" 	, _aVendVP[i,4]	    , Nil})
			aAdd(_aAutoSE1, {"E1_TIPO" 	    , _aVendVP[i,10]    , Nil})
			aAdd(_aAutoSE1, {"E1_CLIENTE" 	, _aVendVP[i,5] 	, Nil})
			aAdd(_aAutoSE1, {"E1_LOJA"    	, _aVendVP[i,6] 	, Nil})
			aAdd(_aAutoSE1, {"E1_EMISSAO"   , _aVendVP[i,7] 	, Nil})
			aAdd(_aAutoSE1, {"AUTDTBAIXA"   , _aVendVP[i,9]     , Nil})
			aAdd(_aAutoSE1, {"AUTDTCREDITO" , _aVendVP[i,9]     , Nil})
			AAdd(_aAutoSE1, {"AUTAGENCIA"  	, '.    ' 		    , Nil})
			AAdd(_aAutoSE1, {"AUTCONTA"  	, '.         '      , Nil})
			AAdd(_aAutoSE1, {"AUTDESCONT"	, 0         		, Nil})
			AAdd(_aAutoSE1, {"AUTMULTA"  	, 0         		, Nil})
			AAdd(_aAutoSE1, {"AUTJUROS"  	, 0         		, Nil})
			AAdd(_aAutoSE1, {"AUTVALREC"  	, _aVendVP[i,8] 	, Nil})
			_aAutoSE1 := aclone (U_OrdAuto (_aAutoSE1))  // orderna conforme dicionário de dados
			   
			cPerg = 'FIN070'
			_aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
			U_GravaSX1 (cPerg, "01", 2)
			U_GravaSX1 (cPerg, "04", 2)
			
			lMsErroAuto := .F.
			lMsHelpAuto := .F.
			MSExecAuto({|x,y| Fina070(x,y)},_aAutoSE1,6,.F.,5) // rotina automática para exclusao da baixa de títulos
			If lMsErroAuto
				MostraErro()
				//Return()
				exit
			Endif  
			U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina	
		next
	endif
return
