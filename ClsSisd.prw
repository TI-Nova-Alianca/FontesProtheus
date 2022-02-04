// Programa:  ClsSisd
// Autor:     Robert Koch
// Data:      20/10/2011
// Descricao: Declaracao de classe de dados de produtos relacionados ao Sisdeclara.
//            Poderia trabalhar como uma include, mas prefiro declarar uma funcao de usuario
//            apenas para poder incluir no projeto e manter na pasta dos fontes.
//
// Historico de alteracoes:
// 17/02/2016 - Robert - Crado metodo ValProd().
// 09/03/2016 - Robert - Criado tratamento para o campo B1_VACSD13.
// 01/04/2016 - Robert - Passa a representar um produto. Criados atributos diversos.
// 07/04/2016 - Robert - Validacao para nao permitir cor na bagaceira.
// 17/05/2016 - Robert - Campos do Sisdeclara migrados da tabela SB1 para SB5.
// 07/07/2016 - Robert - Verifica necessidade de informar especie conforme tipo de produto.
// 11/07/2016 - Robert - Exige classe para tipo=08 (suco).
// 05/08/2016 - Robert - Exige 'tipo de produto' quando o item for considerado no SIsdeclara.
// 08/08/2016 - Robert - Novas validacoes para cor e embalagem.
// 05/09/2016 - Robert - Tratamento para filial 08.
// 04/02/2022 - Robert - Campo TIPO aumentou de tamanho. Passa a usar alltrim().
//

#include "protheus.ch"

// --------------------------------------------------------------------------
// Funcao declarada apenas para poder compilar este arquivo fonte.
user function ClsSisd ()
return


// ==========================================================================
CLASS ClsSisd

	// Declaracao das propriedades da Classe
	data Erros
	data Avisos
	data CodSB1
	data CodSisd
	data CodProt
	data Cor
	data Descri
	data Embalagem
	data Tipo
	data Classe
	data Especie
	data Percent
	data Considera
	data Variedade

	// Declaracao dos Metodos da classe
	METHOD New ()
	METHOD ValProd ()

ENDCLASS


// --------------------------------------------------------------------------
// Construtor.
METHOD New (_sProduto, _sAlias, _sFilial) Class ClsSisd
	local _aAreaAnt := U_ML_SRArea ()
	local _sFilial  := iif (_sFilial == NIL, cFilAnt, _sFilial)
	local _sTabCod  := ''

	::Erros = {}
	::Avisos = {}

	do case
		case cEmpAnt + cFilAnt == '0101' ; _sTabCod = '12'
		case cEmpAnt + cFilAnt == '0103' ; _sTabCod = '24'
		case cEmpAnt + cFilAnt == '0105' ; _sTabCod = '25'
		case cEmpAnt + cFilAnt == '0106' ; _sTabCod = '26'
		case cEmpAnt + cFilAnt == '0107' ; _sTabCod = '27'
		case cEmpAnt + cFilAnt == '0108' ; _sTabCod = '38'
		case cEmpAnt + cFilAnt == '0109' ; _sTabCod = '28'
		case cEmpAnt + cFilAnt == '0110' ; _sTabCod = '29'
		case cEmpAnt + cFilAnt == '0111' ; _sTabCod = '30'
		case cEmpAnt + cFilAnt == '0112' ; _sTabCod = '31'
		case cEmpAnt + cFilAnt == '0113' ; _sTabCod = '23'
		otherwise
			aadd (::Erros, "Empresa / filial '" + cEmpAnt + cFilAnt + "' nao prevista no metodo " + procname () + " da classe " + GetClassName (::Self))
	endcase

	// Conforme o ALIAS recebido posso saber se trata-se de manutencao no cadastro (alias M->)
	if _sAlias == 'SB5'
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
			aadd (::Erros, "Produto '" + _sProduto + "' nao encontrado na tabela SB1 (dados genericos produtos).")
		else
			sb5 -> (dbsetorder (1))
			if ! sb5 -> (dbseek (xfilial ("SB5") + _sProduto, .F.))
				aadd (::Erros, "Produto '" + _sProduto + "' nao encontrado na tabela SB5 (dados adicionais produtos).")
			else
				::CodProt   = _sProduto
				::CodSisd   = sb5 -> &('B5_VACSD' + _sFilial)
				::Cor       = sb1 -> b1_vaCor
				::Tipo      = sb5 -> b5_vaTPSis
				::Classe    = sb5 -> b5_vaCPSis
				::Especie   = sb5 -> b5_vaEPSis
				::Embalagem = sb5 -> b5_vaEmSis
				::Percent   = sb5 -> b5_vaPPSis
				::Considera = (sb5 -> b5_vaSisde == 'S')
				::Variedade = sb5 -> b5_vaVPSis
			endif
		endif
	else
		::CodProt   = _sProduto  // m->b5_cod
		::CodSisd   = m->&('B5_VACSD' + _sFilial)
		::Cor       = iif (type ('M->B1_VACOR') == 'C', m->b1_vacor, fBuscaCpo ("SB1", 1, xfilial ("SB1") + _sProduto, "B1_VACOR"))
		::Tipo      = m->b5_vaTPSis
		::Classe    = m->b5_vaCPSis
		::Especie   = m->b5_vaEPSis
		::Embalagem = m->b5_vaEmSis
		::Percent   = m->b5_vaPPSis
		::Considera = (m->b5_vaSisde == 'S')
		::Variedade = m->b5_vaVPSis
	endif
	::Descri = U_RetZX5 (_sTabCod, ::CodSisd, 'ZX5_' + _sTabCod + 'DESC')

	U_ML_SRArea (_aAreaAnt)
Return ::Self



// --------------------------------------------------------------------------
// Valida consistencia entre campos do cadastro de produtos.
// Para obter as regras sugiro simular o cadastramento de um produto no programa SISDECLARA.
// Retorna array contendo strings no formato {{erros}, {avisos}}
METHOD ValProd () Class ClsSisd
	local _aErros   := {}
	local _aAvisos  := {}
	local _aAreaAnt := U_ML_SRArea ()

	if ::Considera
		if val (::Tipo) == 0
			aadd (::Erros, "Tipo de produto no Sisdeclara (campo '" + alltrim (RetTitle ("B5_VATPSIS")) + "') deve ser informado quando o produto for considerado no Sisdeclara.")
		endif
		if empty (::Especie)
			aadd (::Erros, "Especie no Sisdeclara (campo '" + alltrim (RetTitle ("B5_VAEPSIS")) + "') deve ser informado quando o produto for considerado no Sisdeclara.")
		endif
//		if ! ::Tipo $ '01/02/03/05/12/13/31/32/33/35/51/52' .and. ::Especie != '000-0'
		if ! alltrim (::Tipo) $ '01/02/03/05/12/13/31/32/33/35/51/52' .and. ::Especie != '000-0'
			aadd (::Erros, "Especie (campo '" + alltrim (RetTitle ("B5_VAEPSIS")) + "') nao deve ser informada para produtos do tipo '" + ::Tipo + "' (campo '" + alltrim (RetTitle ("B5_VACPSIS")) + "').")
		endif
//		if ::Tipo $ '01/02/03/05/12/13/31/32/33/35/51/52' .and. ::Especie == '000-0'
		if alltrim (::Tipo) $ '01/02/03/05/12/13/31/32/33/35/51/52' .and. ::Especie == '000-0'
			aadd (::Erros, "Especie (campo '" + alltrim (RetTitle ("B5_VAEPSIS")) + "') deve ser informada para produtos do tipo '" + ::Tipo + "' (campo '" + alltrim (RetTitle ("B5_VACPSIS")) + "').")
		endif

//		if ::Tipo $ '01/' .and. ::Percent == 0
		if alltrim (::Tipo) $ '01/' .and. ::Percent == 0
			aadd (::Erros, "Percentual (campo '" + alltrim (RetTitle ("B5_VAPPSIS")) + "') deve ser informado para produtos do tipo '" + ::Tipo + "' (campo '" + alltrim (RetTitle ("B5_VACPSIS")) + "').")
		endif
//		if ::Tipo $ '08' .and. ::Classe == '11' .and. ::Percent == 0
		if alltrim (::Tipo) $ '08' .and. ::Classe == '11' .and. ::Percent == 0
	 		aadd (::Erros, "Suco concentrado: o brix deve ser informado no campo '" + alltrim (RetTitle ("B5_VAPPSIS")) + "').")
		endif
//		if ::Tipo $ '01/02/03/12/13/31/32/33/35/51/52' .and. ::Percent == 0
		if alltrim (::Tipo) $ '01/02/03/12/13/31/32/33/35/51/52' .and. ::Percent == 0
	 		aadd (::Erros, "Percentual (campo '" + alltrim (RetTitle ("B5_VAPPSIS")) + "') deve ser informado para produtos do tipo '" + ::Tipo + "' (campo '" + alltrim (RetTitle ("B5_VACPSIS")) + "').")
		endif
//		if ! ::Tipo $ '01/02/03/08/12/13/31/32/33/35/51/52' .and. ::Percent > 0
		if ! alltrim (::Tipo) $ '01/02/03/08/12/13/31/32/33/35/51/52' .and. ::Percent > 0
	 		aadd (::Erros, "Percentual (campo '" + alltrim (RetTitle ("B5_VAPPSIS")) + "') nao deve ser informado para produtos do tipo '" + ::Tipo + "' (campo '" + alltrim (RetTitle ("B5_VACPSIS")) + "').")
		endif
		if left (::Especie, 3) == '150' .and. ::Percent != 100
	 		aadd (::Erros, "Especie 'mistura': percentual (campo '" + alltrim (RetTitle ("B5_VAPPSIS")) + "') deve ser 100.")
		endif
		
		// Validacoes de cor.
//		if ! empty (::Cor) .and. ::Tipo $ '19/22/23/24/25/30/34/36/37/40/49/50/53/99'
		if ! empty (::Cor) .and. alltrim (::Tipo) $ '19/22/23/24/25/30/34/36/37/40/49/50/53/99'
			aadd (::Erros, "Cor NAO deve ser informada no campo '" + alltrim (RetTitle ("B1_VACOR")) + "' do cadastro de produtos, quando tipo de produto no Sisdeclara = '" + ::Tipo + "'.")
		endif
//		if ::Tipo $ '31/33' .and. ! ::Cor $ 'B/R'
		if alltrim (::Tipo) $ '31/33' .and. ! ::Cor $ 'B/R'
			aadd (::Erros, "Cor deve ser 'branco' ou 'rosado' no campo '" + alltrim (RetTitle ("B1_VACOR")) + "' do cadastro de produtos, quando tipo de produto no Sisdeclara = '" + ::Tipo + "'.")
		endif
//		if empty (::Cor) .and. ::Tipo $ '01/02/03/04/05/06/07/08/09/12/13/14/15/16/17/18/28/29/32/35/41/42/43/44/45/46/47/48/51/52'
		if empty (::Cor) .and. alltrim (::Tipo) $ '01/02/03/04/05/06/07/08/09/12/13/14/15/16/17/18/28/29/32/35/41/42/43/44/45/46/47/48/51/52'
			aadd (::Erros, "Cor (campo '" + alltrim (RetTitle ("B1_VACOR")) + "' do cadastro de produtos) deve ser informada para produtos do tipo '" + ::Tipo + "'.")
		endif
		//if ::Tipo $ '25/30/36/37/40/41'
		//	aadd (::Avisos, "Provavel inconsistencia entre tipo de produto (campo '" + alltrim (RetTitle ("B5_VATPSIS")) + "') e cor (campo '" + alltrim (RetTitle ("B1_VACOR")) + "'). Verifique possiveis erros no validador do SIsdeclara.")
		//endif
		
//		if ::Tipo == '12' .and. ::Classe != '12'  // Mosto
		if alltrim (::Tipo) == '12' .and. ::Classe != '12'  // Mosto
			aadd (::Erros, "Classe no Sisdeclara deve ser '12' no campo '" + alltrim (RetTitle ("B5_VACPSIS")) + "' quando tipo = '" + ::Tipo + "'.")
		endif
//		if ::Tipo == '31' .and. ::Classe != '07'  // Moscatel
		if alltrim (::Tipo) == '31' .and. ::Classe != '07'  // Moscatel
			aadd (::Erros, "Classe no Sisdeclara deve ser '07' no campo '" + alltrim (RetTitle ("B5_VACPSIS")) + "' quando tipo = '" + ::Tipo + "'.")
		endif
//		if ::Tipo $ '01/08' .and. val (::Classe) == 0
		if (::Tipo) $ '01/08' .and. val (::Classe) == 0
			aadd (::Erros, "Classe no Sisdeclara deve ser informada no campo '" + alltrim (RetTitle ("B5_VACPSIS")) + "' quando tipo = '" + ::Tipo + "'.")
		endif
//		if ::Classe == '12' .and. ! ::Tipo $ '12/13'  // Mosto
		if ::Classe == '12' .and. ! alltrim (::Tipo) $ '12/13'  // Mosto
			aadd (::Erros, "Tipo de produto para Sisdeclara (campo '" + alltrim (RetTitle ("B5_VATPSIS")) + "') incoerente com a classe '12' (mosto).")
		endif
//		if ::Tipo $ '07/14/16/17/18/19/20/22/23/24/25/28/30/34/36/37/40/41/42/43/44/45/46/47/48/49/50/53/99' .and. ::Classe != '00'
		if alltrim (::Tipo) $ '07/14/16/17/18/19/20/22/23/24/25/28/30/34/36/37/40/41/42/43/44/45/46/47/48/49/50/53/99' .and. ::Classe != '00'
			aadd (::Erros, "Classe (campo '" + alltrim (RetTitle ("B5_VACPSIS")) + "') nao deve ser informada para produtos do tipo '" + ::Tipo + "' (campo '" + alltrim (RetTitle ("B5_VACPSIS")) + "').")
		endif
		if empty (::Embalagem) .or. ::Embalagem == '99'
			aadd (::Erros, "Embalagem para Sisdeclara (campo '" + alltrim (RetTitle ("B5_VAEMSIS")) + "') deve ser informada quando o produto for considerado no Sisdeclara.")
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
return {_aErros, _aAvisos}
