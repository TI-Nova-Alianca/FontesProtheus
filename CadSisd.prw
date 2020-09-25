// Programa...: SB1Sisd
// Autor......: Robert Koch
// Data.......: 31/08/2016
// Descricao..: Tela de consulta de relacionamentos produtos com Sisdeclara.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function CadSisd ()
	local _aAreaAnt   := U_ML_SRArea ()
	local _aAmbAnt    := U_SalvaAmb ()

	processa ({|| _Tela ()})

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return



// --------------------------------------------------------------------------
static function _Tela ()
	local _oSQL := NIL

	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT * FROM VA_VSB1_SISDECLARA"
	_oSQL:F3Array ('Cadastro de produtos Protheus X dados para Sisdeclara.')
return
