// Programa:  MA300ok
// Autor:     Robert Koch
// Data:      12/01/2023
// Descricao: P.E. que valida se pode executar recalculo de saldos de estoque (GLPI 13010)

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. que valida se pode executar recalculo de saldos de estoque
// #PalavasChave      #estoque #recalculo #MATA300
// #TabelasPrincipais #SB2
// #Modulos           #EST

// --------------------------------------------------------------------------
user function MA300OK ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _lRet300ok := .T.
	local _oVerif    := NIL

	// Verifica se tem inconsistencias entre MV_ULMES e ultima data do SB9/SBJ/SBK
	_oVerif := ClsVerif():New (45)
	_oVerif:Executa ()
	if len (_oVerif:Result) > 1
		u_help ("Erro tipo 45 (inconsistencia MV_ULMES). Recalculo de saldos nao deve ser feito nesta situacao.",, .t.)
		_lRet300ok = .F.
	endif

	U_ML_SRArea (_aAreaAnt)
return _lRet300ok
