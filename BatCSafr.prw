// Programa:   BatCSafr
// Autor:      Robert Koch
// Data:       19/01/2018
// Descricao:  Envia e-mail de acompanhamento de cargas de safra.
//             Criado para ser executado via batch em lugar do 'consultas web'
//
// Historico de alteracoes:
// 09/01/2018 - Robert - Atualizada lista de destinatarios.
// 24/01/2019 - Sandra - Incluso Deise.demori@novaalianca.coop.br.
// 27/02/2019 - Robert - Ignora cargas devolvidas.
//                     - Passa a trazer grau medio geral (antes vinha propositalmente zerado).
// 22/11/2019 - Robert - Ajustados nomes conselheiros 2020
//

// --------------------------------------------------------------------------
user function BatCSafr ()
	local _sMsg   := ""
	local _sDest  := ""
	local _oSQL   := NIL
	local _sSafra := U_IniSafra ()
	local _aCols  := {}
	u_logIni ()

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " WITH C AS ("
	_oSQL:_sQuery += " SELECT FILIAL, PRODUTO, DESCRICAO, GRAU, PESO_LIQ"
	_oSQL:_sQuery += " FROM VA_VCARGAS_SAFRA"
	_oSQL:_sQuery += " WHERE SAFRA = '" + _sSafra + "'"
	_oSQL:_sQuery += " AND STATUS != 'C'"  // Cancelada
	_oSQL:_sQuery += " AND AGLUTINACAO != 'O'"  // Aglutinada em outra carga
	_oSQL:_sQuery += " AND PESO_LIQ > 0"  // Para evitar cargas 'em recebimento'
	_oSQL:_sQuery += " AND NF_DEVOLUCAO = ''"  // Para evitar cargas devolvidas'
	_oSQL:_sQuery += " )"
	
	// Agrupado por variedade
	_oSQL:_sQuery += " SELECT PRODUTO, DESCRICAO"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '01' THEN PESO_LIQ ELSE 0 END) AS KG_F01"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '01' AND C2.PRODUTO = C.PRODUTO), 0), 1) AS GRAU_F01"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '03' THEN PESO_LIQ ELSE 0 END) AS KG_F03"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '03' AND C2.PRODUTO = C.PRODUTO), 0), 1) AS GRAU_F03"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '07' THEN PESO_LIQ ELSE 0 END) AS KG_F07"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '07' AND C2.PRODUTO = C.PRODUTO), 0), 1) AS GRAU_F07"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '09' THEN PESO_LIQ ELSE 0 END) AS KG_F09"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '09' AND C2.PRODUTO = C.PRODUTO), 0), 1) AS GRAU_F09"
	_oSQL:_sQuery += " , SUM (PESO_LIQ) AS KG_GERAL"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.PRODUTO = C.PRODUTO), 0), 1) AS GRAU_GERAL"
	_oSQL:_sQuery += " FROM C"
	_oSQL:_sQuery += " GROUP BY PRODUTO, DESCRICAO"
	
	// Linha com totais no final
	_oSQL:_sQuery += " UNION ALL"
	_oSQL:_sQuery += " SELECT 'TOTAIS', 'ZZZZZZZZZZZZZZ'"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '01' THEN PESO_LIQ ELSE 0 END) AS KG_F01"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '01'), 0), 1) AS GRAU_F01"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '03' THEN PESO_LIQ ELSE 0 END) AS KG_F03"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '03'), 0), 1) AS GRAU_F03"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '07' THEN PESO_LIQ ELSE 0 END) AS KG_F07"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '07'), 0), 1) AS GRAU_F07"
	_oSQL:_sQuery += " , SUM (CASE WHEN FILIAL = '09' THEN PESO_LIQ ELSE 0 END) AS KG_F09"
	_oSQL:_sQuery += " , ROUND (ISNULL ((SELECT SUM (PESO_LIQ * GRAU) / SUM (PESO_LIQ) FROM C AS C2 WHERE C2.FILIAL = '09'), 0), 1) AS GRAU_F09"
	_oSQL:_sQuery += " , SUM (PESO_LIQ) AS KG_GERAL"
//	_oSQL:_sQuery += " , 0 AS GRAU_GERAL"
	_oSQL:_sQuery += " , ROUND(ISNULL((SELECT SUM(PESO_LIQ * GRAU) / SUM(PESO_LIQ) FROM C AS C2), 0), 1) AS GRAU_GERAL"
	_oSQL:_sQuery += " FROM C"

	_oSQL:_sQuery += " ORDER BY DESCRICAO"
	_oSQL:Log ()

	_aCols = {}
	aadd (_aCols, {'Variedade',  'left' ,  ''})
	aadd (_aCols, {'Descricao',  'left' ,  ''})
	aadd (_aCols, {'Kg F01',     'right',  '@E 999,999,999'})
	aadd (_aCols, {'Grau F01',   'right',  '@E 99.9'})
	aadd (_aCols, {'Kg F03',     'right',  '@E 999,999,999'})
	aadd (_aCols, {'Grau F03',   'right',  '@E 99.9'})
	aadd (_aCols, {'Kg F07',     'right',  '@E 999,999,999'})
	aadd (_aCols, {'Grau F07',   'right',  '@E 99.9'})
	aadd (_aCols, {'Kg F09',     'right',  '@E 999,999,999'})
	aadd (_aCols, {'Grau F09',   'right',  '@E 99.9'})
	aadd (_aCols, {'Kg geral',   'right',  '@E 999,999,999'})
	aadd (_aCols, {'Grau geral', 'right',  '@E 99.9'})

	_sMsg = _oSQL:Qry2HTM ("Acompanhamento cargas safra " + _sSafra, _aCols, "", .T., .F.)
	if len (_oSQL:_xRetQry) > 1
		u_log (_sMsg)
		_sDest := ""

		// Internos - direcao
		_sDest += "alceu.dallemolle@novaalianca.coop.br;"
		_sDest += "joel.panizzon@novaalianca.coop.br;"
		_sDest += "jocemar.dalcorno@novaalianca.coop.br;"
		_sDest += "rodrigo.colleoni@novaalianca.coop.br;"

		// Conselho administracao titulares
		_sDest += "diegowaiss@hotmail.com;"
		_sDest += "gilbertoverdi@gmail.com;"
		_sDest += "joel.caldart@hotmail.com;"
		_sDest += "linojoaopan@hotmail.com;"
		_sDest += "marciogirelli.st@gmail.com;"
		_sDest += "marcioferrar@gmail.com;"
		_sDest += "rodrigovdebona@gmail.com;"
		_sDest += "romildowferrari@hotmail.com;"

		// Conselho administracao suplentes
		_sDest += "darci.boldrin@novaalianca.coop.br;"
		_sDest += "drcioato@hotmail.com;"
		_sDest += "ledacioato@hotmail.com;"
		_sDest += "juninhosalton@outlook.com;"
		_sDest += "marcosparisotto6@gmail.com;"
		_sDest += "roberto.pagliarin@novaalianca.coop.br;"

		// Conselho fiscal titulares
		_sDest += "sidimarfleck@gmail.com;"
		_sDest += "ivanortoscan276@gmail.com;"
		_sDest += "daniederbof@hotmail.com;"

		// Conselho fiscal suplentes
		_sDest += "carloscbusetti@hotmail.com;"
		_sDest += "fernandoantoniogiordani@gmail.com;"


/* Conselho em 2019:
		_sDest += "dionisiolorandi@gmail.com;"
		_sDest += "parisottoadelar@gmail.com;"
		_sDest += "elianecanutocanalli@gmail.com;"
		_sDest += "leandrotonello26@gmail.com;"
		_sDest += "ruibertuol@yahoo.com.br;"
		_sDest += "zancojucemar@gmail.com;"
		_sDest += "linojoaopan@hotmail.com;"
		_sDest += "borrachadirceu@hotmail.com;"
*/
		// Internos - gestores
		_sDest += "rubiane.busetti@novaalianca.coop.br;"
		_sDest += "evandro.marcon@novaalianca.coop.br;"
		_sDest += "rodimar.vizentin@novaalianca.coop.br;"

		// Internos - tecnico / enologia / operacao
		_sDest += "talison.brisotto@novaalianca.coop.br;"
		_sDest += "eliane.lopes@novaalianca.coop.br;"
		_sDest += "pedro.toniolo@novaalianca.coop.br;"
		_sDest += "anderson.felten@novaalianca.coop.br;"
		_sDest += "eduardo.guarche@novaalianca.coop.br;"
		_sDest += "renan.mascarello@novaalianca.coop.br;"
		_sDest += "sergio.pereira@novaalianca.coop.br;"
		_sDest += "deise.demori@novaalianca.coop.br;"

		// Internos - agronomia
		_sDest += "leonardo.reffatti@novaalianca.coop.br;"
		_sDest += "paulo.dullius@novaalianca.coop.br;"
		_sDest += "waldir.schu@novaalianca.coop.br;"
		_sDest += "odinei.cardoso@novaalianca.coop.br;"
		_sDest += "alex.cervinski@novaalianca.coop.br;"

		// Internos - TI (monitoramento)
		_sDest += "sandra.sugari@novaalianca.coop.br;"
		_sDest += "robert.koch@novaalianca.coop.br;"

		U_SendMail (_sDest, "Acompanhamento cargas safra", _sMsg)
	endif

	u_logFim ()
return
