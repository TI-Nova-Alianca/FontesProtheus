// Programa...: AlmFull
// Autor......: Robert Koch
// Data.......: 15/08/2018
// Descricao..: Retorna almoxarifado a ser usado para integracao com FullWMS, conforme a situacao.
//
// Historico de alteracoes:
// 29/03/2019 - Robert - Criado tratamento para entrada de tipo PI no AX.01.
//

// --------------------------------------------------------------------------
user function AlmFull (_sProduto, _sSituaca)
	local _aArea := {}
	local _sRet := ""
	
	if _sSituaca == 'TODOS'  // O programa chamador quer saber quais sao todos os almox. de integracao
		_sRet = '11/22'
	else
		_aArea := sb1 -> (getarea ())
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
			u_help ("Cadastro do produto '" + _sProduto + "' nao localizado!")
			_sRet = ''
		else
			if cEmpAnt = '01' .and. cFilAnt == '01' .and. sb1 -> b1_vafullw == 'S'  // Produto DEVE entrar em algum almox. de integracao com FullWMS.
				do case
				case sb1 -> b1_tipo $ 'PA/PI' .and. _sSituaca == 'PR'  // Entrada de producao
					_sRet = '11'
				case sb1 -> b1_tipo == 'PA' .and. _sSituaca == 'DV'  // Devolucao de venda
					_sRet = '91/93'  // Um dos almox eh para quando vai refaturar, outro nao.
				case sb1 -> b1_tipo == 'PA' .and. _sSituaca == 'TF'  // Entrada de transferencia de outra filial
					_sRet = '11'
				case sb1 -> b1_tipo == 'ME' .and. _sSituaca == 'NE'  // Entrada por NF
					_sRet = '22'
				case sb1 -> b1_tipo == 'ME' .and. _sSituaca == 'TF'  // Entrada de transferencia de outra filial
					_sRet = '22'
				otherwise
					u_help ("Almox. de integracao com FullWMS: sem definicao para produto '" + alltrim (sb1 -> b1_cod) + "' (tipo " + sb1 -> b1_tipo + ") e situacao '" + _sSituaca + "'.")
					_sRet = ''
				endcase
			endif
		endif
		sb1 -> (restarea (_aArea))
	endif
	// u_log ('[' + procname () + ']: almox tipo', _sSituaca, 'para o produto', alltrim (_sProduto), ': ', _sRet)
return _sRet
