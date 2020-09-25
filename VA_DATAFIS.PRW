// Programa...: VA_DATAFIS
// Autor......: Robert Koch
// Data.......: 27/07/2020
// Descricao..: Edicao do parametro MV_DATAFIS do configurador
//              Criado com base no VA_PARAM de Catia Cardoso (25/02/2015)
//
// Historico de alteracoes:
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #atualizacao
// #Descricao         #Altera parametro de data minima para movimentacao fiscal.
// #PalavasChave      #parametro #MV_DATAFIS #bloqueio_movimentacao_fiscal
// #TabelasPrincipais #SX6
// #Modulos           #FIS

// --------------------------------------------------------------------------
User Function VA_DATAFIS ()
	local _sAntigo  := ""
	local _sNovo    := ""
	local _oEvento  := NIL
	local _sNomePar := ''
	
	if U_ZZUVL ('034')
		_sNomePar := "MV_DATAFIS"
		_sAntigo = GetMv (_sNomePar)
		_sNovo = U_Get ("Data limite operações fiscais - MV_DATAFIS", "D", 8, "@D", "", _sAntigo, .F., '.t.')
		if _sNovo!= NIL .and. ! empty(_sNovo) .and. _sNovo !=_sAntigo 
			PutMv (_sNomePar, _sNovo)
			u_help ("Alteracao efetuada com sucesso")

			_oEvento := ClsEvent():new ()
			_oEvento:CodEven   = "SX6001"
			_oEvento:Texto     = "Alteracao parametro " + _sNomePar + " de '" + cvaltochar (_sAntigo) + "' para '" + cvaltochar (_sNovo) + "'"
			_oEvento:Grava ()
		endif
	endif
return
