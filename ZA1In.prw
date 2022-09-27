// Programa...: ZA1In
// Autor......: Robert Koch (com base no EtqPllIn de Julio Pedroni)
// Data.......: 14/12/2020
// Descricao..: Initilizar etiqueta (desmembrado do VA_EtqPll.prw)

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #PalavasChave      #etiquetas #pallets
// #TabelasPrincipais #ZA1
// #Modulos           #PCP

// Historico de alteracoes:
// 14/12/2020 - Robert - Testava campos do ZA1 antes de posicionar no registro.
// 24/01/2022 - Robert - Gravacao evento de inutilizacao.
// 26/09/2022 - Robert - Passa a chmar metodo :Inutiliza() da ClsEtiq.
//

// ----------------------------------------------------------------
User Function ZA1In (_sCodigo, _lMsg)
	Local _aAreaAnt := U_ML_SRArea ()
	local _oEtiq    := NIL
	U_Log2 ('debug', '[' + procname () + ']Instanciando etiqueta')
	_oEtiq := ClsEtiq ():New (_sCodigo)
	_oEtiq:Inutiliza (_lMsg)
	U_ML_SRArea (_aAreaAnt)
return
