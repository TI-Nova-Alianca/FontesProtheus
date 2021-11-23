
// Programa...: MT103FIM
// Autor......: Maurício C. Dani - TOTVS RS
// Data.......: 15/05/2018
// Descricao..: P.E. - Operação após gravação da NFE
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. - Operação após gravação da NFE
// #PalavasChave      #ponto_de_entrada #gravacao_NFE 
// #TabelasPrincipais #ZZX #SF1
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
// 24/02/2021 - Claudia - Ajustes conforme GLPI: 9481
// 25/08/2021 - Robert  - Nova versao de ciencia e manifesto da TRS (GLPI 10822)
// 30/08/2021 - Robert  - Passa a fazer manifesto somente se o usuario confirmou a tela.
// 23/11/2021 - Claudia - Gerar manifesto apenas para SPED. GLPI: 11183
//
// ------------------------------------------------------------------------------------
User Function MT103FIM()
	local _aAreaAnt := U_ML_SRArea ()
	Local _lConf    := PARAMIXB[2]==1

	if alltrim (cEspecie) == 'SPED' .and. _lConf  // Usuario confirmou a tela
		//Realiza ciência
		U_FBTRS101({SF1->F1_CHVNFE}, 4, '')
		//Abre tela do manifesto
		U_FBTRS102(.T.)
	endif

	U_ML_SRArea (_aAreaAnt)
Return
