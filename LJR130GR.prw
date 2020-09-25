// Programa:  LJR130GR
// Autor:     Cláudia Lionço
// Data:      12/02/2020
// Descricao: Ponto de entrada que permite efetuar qualquer atualização na base após a gravação dos itens da nota fiscal (arquivo SD2), 
//            pois é chamado logo após a geração desse arquivo.
//
// Historico de alteracoes:
//
#include 'protheus.ch'
#include 'parmtype.ch'

user function LJR130GR()
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()

	U_HELP("Nota Fiscal gerada: " + ALLTRIM(SF2->F2_DOC) +" Série: "+ alltrim(SF2->F2_SERIE))
	
	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
return