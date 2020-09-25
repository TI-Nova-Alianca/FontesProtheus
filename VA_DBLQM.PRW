// Programa...: VA_DBLQM
// Autor......: Robert Koch
// Data.......: 04/10/2016
// Descricao..: Edicao de parametro do configurador.
//
// Historico de alteracoes:
// 27/07/2020 - Robert  - Verificacao de acesso: passa a validar acesso 033 e nao mais 069.
//                      - Inseridas tags para catalogacao de fontes
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #atualizacao
// #Descricao         #Altera parametro de data minima para bloqueio de estoques.
// #PalavasChave      #parametro #MV_DBLQMOV #bloqueio_movimentacao_estoques
// #TabelasPrincipais #SX6
// #Modulos           #EST

// --------------------------------------------------------------------------
User Function VA_DBLQM ()
	local _sAntigo  := ""
	local _sNovo    := ""
	local _oEvento  := NIL
	local _sNomePar := "MV_DBLQMOV"

	if U_ZZUVL ('033')
		_sAntigo = GetMv (_sNomePar)
		_sNovo = U_Get ("Data limite para mov.estoques nesta filial", "D", 8, "@D", "", _sAntigo, .F., '.t.')
		if _sNovo != NIL .and. ! empty (_sNovo)
			PutMv (_sNomePar, _sNovo)
			u_help ("Alteracao efetuada com sucesso")

			_oEvento := ClsEvent():new ()
			_oEvento:CodEven   = "SX6001"
			_oEvento:Texto     = "Alteracao parametro " + _sNomePar + " de '" + cvaltochar (_sAntigo) + "' para '" + cvaltochar (_sNovo) + "'"
			_oEvento:Grava ()
		endif
	endif
return
