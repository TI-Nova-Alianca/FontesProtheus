// Programa:   LJ7001
// Autor:      Robert Koch
// Data:       21/02/2011
// Cliente:    Alianca
// Descricao:  P.E. 'Tudo OK' na tela de venda assistida.
//
// Historico de alteracoes:
// 29/06/2012 - Robert - Separacao de validacoes em functions.
//                     - Implementada validacao de preenchimento de CPF/CNPJ do cliente.
// 21/06/2013 - Robert - Nao exige mais CPF abaixo de R$ 200
// 05/05/2015 - Catia  - Desabilitado o teste que obriga CPF se compra >= R$ 200 - solicitação Rodrigo Colleoni
// 01/11/2016 - Catia  - Desabilitada validação do TES que considerava so o 526 e o 531 - ira faturar com o TES que vem do produto
// 14/11/2016 - Catia  - Desabilitada a validacao do _VerCGC
// --------------------------------------------------------------------------
user function LJ7001 ()
	local _lRet     := .T.
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()

	/*
	if _lRet
		_lRet = _VerTES ()
	endif
	*/
	
	/*
	if _lRet
		_lRet = _VerAlmox ()
	endif
	*/
	
	/*
	if _lRet
		_lRet = _VerCGC ()
	endif
	*/
	
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
return _lRet

// --------------------------------------------------------------------------
static function _VerTES ()
	local _lRet     := .T.
	local _nColTES  := ascan (aPosCpoDet, {|_aVal| alltrim (_aVal [1]) == "LR_TES"})
	local _sTES     := ""
	local _N		:= 0
	
	if _nColTES > 0 .and. paramixb [1] == 2  // 1-orcamento  2-venda  3-pedido
		for _N = 1 to len (aCols)
			N := _N
			if ! GDDeleted ()
				_sTES = iif (alltrim (GDFieldGet ("LR_PRODUTO")) == '8000', '531', '526')
				if aColsDet [N, _nColTES] != _sTES
					u_help ("Linha " + cValToChar (N) + ": TES para cupom fiscal deve ser '526'")
					_lRet = .F.
					exit
				endif
			endif
		next
	endif
return _lRet

// --------------------------------------------------------------------------
static function _VerAlmox ()
	local _lRet     := .T.
	local _nColLoc  := ascan (aPosCpoDet, {|_aVal| alltrim (_aVal [1]) == "LR_LOCAL"})
	local _N		:= 0
	
	if _nColLoc > 0 .and. paramixb [1] == 2  // 1-orcamento  2-venda  3-pedido
		for _N = 1 to len (aCols)
			N := _N
			if ! GDDeleted ()
				if aColsDet [N, _nColLoc] != '10'
					u_help ("Linha " + cValToChar (N) + ": Vendas via cupom devem ser feitas a partir do almoxarifado '10'")
					_lRet = .F.
					exit
				endif
			endif
		next
	endif
return _lRet

// --------------------------------------------------------------------------
static function _VerCGC ()
	local _lRet      := .T.
	local _nColVlr   := ascan (aPosCpoDet, {|_aVal| alltrim (_aVal [1]) == "LR_BASEICM"})  // Unico campo disponivel, por enquanto.
	local _nValor    := 0
	local _N		 := 0

	if paramixb [1] == 2  // 1-orcamento  2-venda  3-pedido
		if _nColVlr == 0
			u_help ("Nao foi possivel buscar o valor do cupom. Campo LR_BASEICM deve estar em uso para validacoes.")
			_lRet = .F.
		else 
			for _N = 1 to len (aCols)
				N := _N
				if ! GDDeleted ()
					_nValor += aColsDet [N, _nColVlr]
				endif
			next
		endif
	endif
return _lRet