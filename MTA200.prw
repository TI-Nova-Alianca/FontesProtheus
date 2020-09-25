// Programa...: MTA200
// Autor......: Cl�udia Lion�o
// Data.......: 27/08/2019
// Descricao..: P.E. executado ap�s altera��o na estrutura de um produto.
//
// Historico de alteracoes:
// 27/08/2019 - Cl�udia - Cria��o do ponto de entrada, enviando e-mail na altera��o de estrutura de produto.
// ----------------------------------------------------------------
user function MTA200 ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()

	if _lRet
		_lRet = _EnvEmail()
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return _lRet
// ----------------------------------------------------------------
// Envia e-mail
static function _EnvEmail ()
	local _lRet      := .T.
	
	// Cria evento dedo-duro para posterior gravacao em outro P.E. apos a efetivacao do movimento.
	_oEvento := ClsEvent():New ()
	_oEvento:Alias     = 'SG1'
	_oEvento:Texto     = "Altera��o de estrutura de produto: " + alltrim(cproduto) + chr (13) + chr (10) + ;
	 					 "Estrutura N�: " + alltrim(cproduto) + chr (13) + chr (10) + ;
	                     "Item N�: "+ alltrim(ccodpai) + "-" + alltrim(g1_desc) + " foi alterado na estrutura."
	_oEvento:CodEven   = "SG1001"
	_oEvento:Produto   = alltrim(cproduto)
	_oEvento:MailToZZU = {"069"}
	
	_oEvento:Grava()

return _lRet