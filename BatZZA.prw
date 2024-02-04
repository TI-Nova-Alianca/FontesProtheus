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
// 03/02/2024 - Robert - Grava em log os dados do ZZA que pretende altetar (GLPI 14858)
//

// --------------------------------------------------------------------------
user function BatZZA ()
	local _oSQL      := NIL
	local _sWhere    := ''
	local _aDebugZZA := {}

	// Altera o status das cargas para 'jah lidas' no ZZA quando tiverem mas de 1 dia de vida, pois
	// ocorrem varios casos de nao finalizar a gravacao do grau, seja por queda de rede, por descuido
	// do operador, travamento de sistema, etc... e essas cargas ficam atrapalhando a selecao das proximas.
	_sWhere := ''
	_sWhere +=  " FROM " + RetSQLName ("ZZA") + " ZZA, "
	_sWhere +=             RetSQLName ("SZE") + " SZE "
	_sWhere += " WHERE ZZA_SAFRA = '" + U_IniSafra (date ()) + "'"
	_sWhere +=   " AND ZZA_FILIAL = '" + xfilial ("ZZA") + "'"
	_sWhere +=   " AND ZZA_STATUS in ('1', '2')"
	_sWhere +=   " AND ZZA.D_E_L_E_T_ = ''"
	_sWhere +=   " AND ZE_SAFRA = ZZA_SAFRA"
	_sWhere +=   " AND SZE.D_E_L_E_T_ = ''"
	_sWhere +=   " AND ZE_FILIAL = ZZA_FILIAL"
	_sWhere +=   " AND ZE_CARGA  = ZZA_CARGA"
	_sWhere +=   " AND (ZE_NFGER != '' OR ZE_AGLUTIN != '')"
	_sWhere +=   " AND (ZE_DATA   < '" + dtos (date () - 1) + "' OR ZE_NFGER != '')"

	// Estou com o campo ZZA_INIST1 ficando vazio e nao sei onde ocorre... desabilitar este trecho depois!
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := "SELECT * "
	_oSQL:_sQuery += _sWhere
	_aDebugZZA := aclone (_oSQL:Qry2Array (.f., .t.))
	U_Log2 ('debug', '[' + procname () + ']ZZA encontra-se assim:')
	U_Log2 ('debug', _aDebugZZA)

	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " UPDATE ZZA SET ZZA_STATUS = 'C'"
	_oSQL:_sQuery += _sWhere
	_oSQL:Log ()
	_oSQL:Exec ()

return .T.

