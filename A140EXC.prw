// Programa...: A140EXC
// Autor......: Catia Cardoso
// Data.......: 05/01/2017
// Descricao..: P.E. - Valida a exclus�o de uma pr�-nota
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. - Valida a exclus�o de uma pr�-nota
// #PalavasChave      #ponto_de_entrada #exclus�o_pre_nota #importacao_XML
// #TabelasPrincipais #ZZX #SF1
// #Modulos   		  #FAT 
//
// Historico de alteracoes:
// 15/05/2018 - Maur�cio C. Dani - TOTVS RS - Importa��o XML TOTVS
// 24/02/2021 - Claudia - Ajustes conforme GLPI: 9481
// 29/03/2021 - Robert  - Variavel _lRet estava com nome lRet cfe. importador XML da TRS.
// 25/08/2021 - Robert  - Nova versao de ciencia e manifesto da TRS (GLPI 10822)
//

//#Include 'protheus.ch'

// --------------------------------------------------------------------------
User Function A140EXC()
	Local _aAreaAnt := U_ML_SRArea ()
//	Local aZone		:= GetArea()
	Local _lRet 		:= .T.
//	Local lImpXml   := SuperGetMV('VA_XMLIMP', .F., .F.)
//	Private _aRet 	:= {}
//	Private _cTabMAN:= AllTrim(SuperGetMv("009_TABMAN"  ,.F.,"" ))

	zzx -> (dbsetorder (4))
	if zzx -> (dbseek (SF1->F1_CHVNFE, .F.))
		If reclock ("ZZX", .F.)
			ZZX->ZZX_STATUS := '3'
			msunlock ()
		endif			
	Endif

//	If lImpXml // Importador XML TOTVS
//	if SuperGetMV('VA_XMLIMP', .F., .F.)  // Se o importador de XML da TRS estiver ativo
/* Versao inicial quando fazia download pelo proprio importador
		_lRet 	:= .F.

		If !SuperGetMV('009_USAMAN', .F., .F.)
			Return .T.
		EndIf

		(_cTabMAN)->(dbSetOrder(1))

		// Posiciona na ZTB(Manifesto) para verificar se a nota foi baixada via manifesto eletrônico
		If !(_cTabMAN)->(MsSeek(xFilial(_cTabMAN) + SF1->F1_CHVNFE))
			// MsgInfo("Não foi possível localizar essa nota ou ela não teve download realizado via manifesto eletrônico!")
			Return .T.
		EndIf

		_lRet := U_fTelaManif()
		RestArea(aZone)
*/
//	else
		U_Log2 ('debug', 'Importador XML da TRS habilitado. Chamando rotinas de ciencia e manifesto.')
		Private _aRet 	:= {}

		//Realiza ci�ncia
		U_FBTRS101({SF1->F1_CHVNFE}, 4, '')
		//Abre tela do manifesto
		U_FBTRS102(.F.)
//	endif

	U_ML_SRArea (_aAreaAnt)
Return _lRet
