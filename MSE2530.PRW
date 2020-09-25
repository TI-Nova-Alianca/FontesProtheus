// Programa...: MSE2530.PRX
// Autor......: Ricardo
// Data.......: 22/05/1999
// Descricao..: Ponto de Entrada tela de atualizacao de pagamento de comissoes (apos a gravacao do registro do SE2).
//
// Historico de alteracoes:
// 01/11/2013 - Leandro - incluir título a pagar com prefixo PR e 1/12 avos do valor da comissão
// 03/02/2014 - Robert  - Ajusta parametros da rotina FINA050
// 28/08/2015 - Catia   - Este ponto de entrada estava recalculando o valor do IR dos titulos de comissoes e deduzindo SEMPRE - teste conforme SIMPLES NACIONAL
// 02/09/2015 - Catia   - Alterado para que gere os titulos de 1/12 tanto provisionada quanto paga
// 13/03/2017 - Catia   - Alterado para que passe a gerar os titulos com o tipo PRI ao inves de PR
// 08/08/2017 - Catia   - Ajuste na geração do titulo da indenização - referente a representantes no simples
// 08/04/2019 - Catia   - include TbiConn.ch
//

#include "totvs.ch"
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

// ------------------------------------------------------------------------------------
User Function MSE2530()
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()
	private _sarqlog := procname ()+".log"
	u_logini()
	
	_wvalor    = SE2->E2_VALOR
	_wvalorbru = SE2->E2_VALOR
	_wsimples  = fBuscaCpo ('SA2', 1, xfilial('SA2') + SE2->E2_FORNECE + SE2->E2_LOJA, "A2_SIMPNAC")
	_wvlrir    = 0
	
	if _wsimples != '1'
		_wvlrir   = ROUND(_wvalor * 0.015 , 2)
		if _wvlrir < 10
			_wvlrir = 0 	
		endif
	endif
	
	_wvalor = _wvalor - _wvlrir
	// altera valores do titulo normal da comissao deduzindo ou não o IR conforme o caso
	SE2->E2_VLCIR := ROUND(SE2->E2_VALOR , 2)
	SE2->E2_VLIR  := _wvlrir
	SE2->E2_VALOR := _wvalor 
	SE2->E2_SALDO := ROUND(SE2->E2_VALOR , 2)
	
	// Gera titulo de provisao de rescisao
	_Gera12 (_wvalorbru)
	
	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return

// --------------------------------------------------------------------------
// inclui um novo título a pagar, com as mesmas informações, porém com prefixo PR e 1/12 avos do valor
static function _Gera12 (_wbase)
	local _aAutoSE2   := {}
	local lMsErroAuto := .f.
	local lMsHelpAuto := .f.
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()
	local cPerg       := "          "
	local _aBkpSX1    := {}
	local _lCtOnLine  := (mv_par08 == 1)
	local _lMostraCt  := (mv_par09 == 1)
	
	// buscar campo que identifica se o vendedor esta no simples
	_wsimples  = fBuscaCpo ('SA2', 1, xfilial('SA2') + SE2->E2_FORNECE + SE2->E2_LOJA, "A2_SIMPNAC")
	// busca nos dados do vendedor se a indenizacao é paga ou provisionada
	_sSQL := ""
    _sSQL += " SELECT A3_INDENIZ" 
    _sSQL += "   FROM SA3010"
 	_sSQL += "  WHERE A3_FORNECE = '" + SE2->E2_FORNECE + "' "
   	_sSQL += "    AND A3_LOJA    = '" + SE2->E2_LOJA + "' "
   	_sSQL += "    AND A3_ATIVO   = 'S'"

    aDados := U_Qry2Array(_sSQL)
	if len (aDados) = 1
		_windeniz = aDados[1,1]
	else
		_windeniz = 'X'
	endif
	
	// monta valor da indenizacao a partir do titulo de comissao
	_wvalor   = _wbase/12
	_wvlrir = 0
	// valida valor do IR do titulo de indenizacao
	if _windeniz = "S" .and. _wsimples != '1'
		_wvlrir   = ROUND(_wvalor * 0.15 , 2)
		if _wvlrir < 10
			_wvlrir = 0 	
		endif
	endif		
	_wvalor = _wvalor - _wvlrir
	
	
	// grava titulo da indenizacao
	_aAutoSE2 := {}
	aadd (_aAutoSE2, {"E2_PREFIXO", 'IND'				, NIL})
	aadd (_aAutoSE2, {"E2_NUM"    , SE2->E2_NUM     	, Nil})
	if _windeniz = "N"
		aadd (_aAutoSE2, {"E2_TIPO"   , "PRI"			, Nil})
	else
		// a indenização eh paga mensalmente gera titulo normal tipo RC (recibo)
		aadd (_aAutoSE2, {"E2_TIPO"   , "RC"				, Nil})	
	endif		
	aadd (_aAutoSE2, {"E2_FORNECE", SE2->E2_FORNECE 	, Nil})
	aadd (_aAutoSE2, {"E2_LOJA"   , SE2->E2_LOJA    	, Nil})
	aadd (_aAutoSE2, {"E2_EMISSAO", SE2->E2_EMISSAO 	, Nil})
	aadd (_aAutoSE2, {"E2_VENCTO" , SE2->E2_VENCTO      , Nil})
	aadd (_aAutoSE2, {"E2_VALOR"  , _wvalor         	, Nil})
	aadd (_aAutoSE2, {"E2_VLIR"   , _wvlrir         	, Nil})
	
	if _windeniz = "N"
		aadd (_aAutoSE2, {"E2_HIST"   , 'PROV.1/12 ' + SE2->E2_HIST , Nil})
	else
		// se a indenizacao eh paga mensalmente altera o historio do titulo
		aadd (_aAutoSE2, {"E2_HIST"   , 'INDENIZACAO 1/12 PAGA MENSALMENTE' + SE2->E2_HIST , Nil})
	endif
			
	aadd (_aAutoSE2, {"E2_PARCELA", SE2->E2_PARCELA 	, Nil})
	aadd (_aAutoSE2, {"E2_VACHVEX", SE2->E2_VACHVEX   	, Nil})
	aadd (_aAutoSE2, {"E2_ORIGEM" , 'FINA530'			, Nil})
	_aAutoSE2 := aclone (U_OrdAuto (_aAutoSE2))
		
	// Ajusta parametros da rotina.
	cPerg = 'FIN050    '
	_aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
	U_GravaSX1 (cPerg, "01", iif (_lMostraCt, 1, 2))  // Mostra lcto. 
	U_GravaSX1 (cPerg, "02", 1)
	U_GravaSX1 (cPerg, "04", iif (_lCtOnLine, 1, 2))
	dbselectarea ("SE2")
	dbsetorder (1)
	MsExecAuto({ | x,y,z | Fina050(x,y,z) }, _aAutoSE2,, 3)
	if lMsErroAuto
		u_help ("Erro na rotina automatica de inclusao de contas a pagar com prefixo PRI:" + U_LeErro (memoread (NomeAutoLog ())))
		MostraErro()
	endif
	U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina.

	u_log (se2 -> e2_num)
	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
Return
