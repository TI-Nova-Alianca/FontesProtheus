// Programa...: A140EXC
// Autor......: Catia Cardoso
// Data.......: 05/01/2017
// Descricao..: P.E. - Valida a exclusão de uma pré-nota
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. - Valida a exclusão de uma pré-nota
// #PalavasChave      #ponto_de_entrada #exclusão_pre_nota #importacao_XML
// #TabelasPrincipais #ZZX #SF1
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
// 15/05/2018 - Maurício C. Dani - TOTVS RS - Importação XML TOTVS
// 24/02/2021 - Claudia - Ajustes conforme GLPI: 9481
// 29/03/2021 - Robert  - Variavel _lRet estava com nome lRet cfe. importador XML da TRS.
// 25/08/2021 - Robert  - Nova versao de ciencia e manifesto da TRS (GLPI 10822)
// 23/11/2021 - Claudia - Gerar manifesto apenas para SPED. GLPI: 11183
//
//
// ------------------------------------------------------------------------------------------
User Function A140EXC()
	Local _aAreaAnt := U_ML_SRArea ()
	Local _lRet     := .T.

	zzx -> (dbsetorder (4))
	if zzx -> (dbseek (SF1->F1_CHVNFE, .F.))
		If reclock ("ZZX", .F.)
			ZZX->ZZX_STATUS := '3'
			msunlock ()
		endif			
	Endif

	U_Log2 ('debug', 'Importador XML da TRS habilitado. Chamando rotinas de ciencia e manifesto.')
	Private _aRet 	:= {}

	If alltrim(SF1->F1_ESPECIE) == 'SPED'
		//Realiza ciência
		U_FBTRS101({SF1->F1_CHVNFE}, 4, '')
		//Abre tela do manifesto
		U_FBTRS102(.F.)
	EndIf

	U_ML_SRArea (_aAreaAnt)
Return _lRet
