// Programa:   BatZZA
// Autor:      Robert Koch
// Data:       21/01/2013
// Descricao:  Manutencao tabela ZZA durante a safra
//             Criado para ser executado via batch.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Atualiza status de possiveis registros que ficaram 'perdidos' no ZZA
// #PalavasChave      #safra #grau #brix #babo
// #TabelasPrincipais #SZE #ZZA
// #Modulos           #COOP

// Historico de alteracoes:
// 22/02/2017 - Robert - Autentado prazo de date() para date()-1.
// 26/02/2019 - Robert - Altera o status para 'C' (Cancelada) e nao mais para '1'.
//                     - Considera tanto date()-1 como ZE_NFGER!=''
//                     - Considera tanto status 1 como 2 (antes era apenas 1)
//                     - Busca ano safra pela funcao U_IniSafra().
// 17/01/2021 - Robert - Eliminados logs desnecessarios.
//                     - Inseridas tags para catalogo de programas.
//

// --------------------------------------------------------------------------
user function BatZZA ()
	local _oSQL   := NIL
//	local _sArqLog2 := iif (type ("_sArqLog") == "C", _sArqLog, "")
//	_sArqLog := U_NomeLog (.t., .f.)
//	u_logIni ()
//	u_logDH ()
	U_Log2 ('info', 'Iniciando ' + procname ())

	// Altera o status das cargas para 'jah lidas' no ZZA quando tiverem mas de 1 dia de vida, pois
	// ocorrem varios casos de nao finalizar a gravacao do grau, seja por queda de rede, por descuido
	// do operador, travamento de sistema, etc... e essas cargas ficam atrapalhando a selecao das proximas.
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " UPDATE ZZA SET ZZA_STATUS = 'C'"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZZA") + " ZZA, "
	_oSQL:_sQuery +=              RetSQLName ("SZE") + " SZE "
//	_oSQL:_sQuery +=  " WHERE ZZA_SAFRA = '" + cvaltochar (year (date ())) + "'"
	_oSQL:_sQuery +=  " WHERE ZZA_SAFRA = '" + U_IniSafra (date ()) + "'"
	_oSQL:_sQuery +=    " AND ZZA_FILIAL = '" + xfilial ("ZZA") + "'"
//	_oSQL:_sQuery +=    " AND ZZA_STATUS = '1'"
	_oSQL:_sQuery +=    " AND ZZA_STATUS in ('1', '2')"
	_oSQL:_sQuery +=    " AND ZZA.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND ZE_SAFRA = ZZA_SAFRA"
	_oSQL:_sQuery +=    " AND SZE.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND ZE_FILIAL = ZZA_FILIAL"
	_oSQL:_sQuery +=    " AND ZE_CARGA  = ZZA_CARGA"
	_oSQL:_sQuery +=    " AND (ZE_NFGER != '' OR ZE_AGLUTIN != '')"
//	_oSQL:_sQuery +=    " AND ZE_DATA   < '" + dtos (date () - 1) + "'"
	_oSQL:_sQuery +=    " AND (ZE_DATA   < '" + dtos (date () - 1) + "' OR ZE_NFGER != '')"
	_oSQL:Log ()
	_oSQL:Exec ()

//	u_logFim ()
//	_sArqLog = _sArqLog2
return .T.

