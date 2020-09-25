// Programa...: A280OK
// Autor......: Robert Koch
// Data.......: 19/05/2020
// Descricao..: Ponto de entrada 'Tudo ok' na rotina MATA280 (virada de saldos do estoque).
//              Criado inicialmente para gravar backup da tabela SC2 (OPs em processo).
//
// Historico de alteracoes:
// 16/06/2020 - Robert - Incluido backup da tabela CT5.
// 06/07/2020 - Robert - Grava evento.
//

// --------------------------------------------------------------------------
user function A280OK ()
	local _oEvento  := NIL
	private _lRetBkp := .T.

	// Monta evento com os parametros utilizados.
	_oEvento := ClsEvent():new ()
	_oEvento:Texto := "Iniciando virada de saldos de " + DTOS (paramixb [1]) + chr (13) + chr (10)
	_oEvento:Texto += "Ambiente: " + GetEnvServer () + chr (13) + chr (10)
	_oEvento:LeParam ('MTA280')
	_oEvento:CodEven = 'SB9002'
	_oEvento:Grava ()

	u_log2 ('info', 'Iniciando backup de algumas tabelas antes da virada de saldos do estoque')
	
	// Faz backup de alguns dados dos quais queremos guardar historico.
	processa ({|| _GodSaveMe ()})

	u_log2 ('info', 'P.E. ' + procname () + ' com retorno logico ' + cValtoChar (_lRetBkp))
return _lRetBkp



// --------------------------------------------------------------------------
static function _GodSaveMe ()
	local _sNomeBkp := ''
	local _sNome2   := '_EmpFil_' + cEmpAnt + cFilAnt + '_antes_virada_saldos_de_' + DTOS (paramixb [1]) + '_em_' + dtos (date ()) + '_' + strtran (time (), ':', '')
	local _oSQL     := ClsSQL ():New ()

	procregua (10)

	// Faz copia da tabela SC2 das ordens de producao que contiverem movimentos no mes que estah sendo fechado e posteriores,
	// pois em caso de reabertura de periodo, os campos de acumulados precisam ser ajustados.
	incproc ('Gerando backup Ordens de Producao')
	_sNomeBkp = 'SC2' + _sNome2
	_oSQL:_sQuery := "SELECT * INTO " + _sNomeBkp
	_oSQL:_sQuery +=  " FROM " + RetSQLName ('SC2')
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND C2_FILIAL = '" + xfilial ("SC2") + "'"
	_oSQL:_sQuery += " AND C2_NUM + C2_ITEM + C2_SEQUEN + C2_ITEMGRD IN "
	_oSQL:_sQuery += " ("
	_oSQL:_sQuery +=     " SELECT DISTINCT D3_OP"
	_oSQL:_sQuery +=       " FROM " + RetSQLName ("SD3") + " SD3 "
	_oSQL:_sQuery +=      " WHERE SD3.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=        " AND SD3.D3_FILIAL = '" + xfilial ("SD3") + "'"
	_oSQL:_sQuery +=        " AND SD3.D3_ESTORNO != 'S'"
	_oSQL:_sQuery +=        " AND SD3.D3_EMISSAO <= '" + DTOS (paramixb [1]) + "'"
	_oSQL:_sQuery +=        " AND SD3.D3_EMISSAO >= '" + DTOS (paramixb [1]- 180) + "'"  // Por questao de performance, vou assumir que nao temos OP com muito tempo em aberto
	_oSQL:_sQuery +=        " AND SD3.D3_OP      != ''"
	_oSQL:_sQuery +=        " AND EXISTS (SELECT *"
	_oSQL:_sQuery +=                      " FROM " + RetSQLName ("SD3") + " PROXIMO "
	_oSQL:_sQuery +=                     " WHERE PROXIMO.D_E_L_E_T_  = ''"
	_oSQL:_sQuery +=                       " AND PROXIMO.D3_FILIAL   = SD3.D3_FILIAL"
	_oSQL:_sQuery +=                       " AND PROXIMO.D3_OP       = SD3.D3_OP"
	_oSQL:_sQuery +=                       " AND PROXIMO.D3_ESTORNO != 'S'"
	_oSQL:_sQuery +=                       " AND PROXIMO.D3_EMISSAO  > '" + DTOS (paramixb [1]) + "'"
	_oSQL:_sQuery +=                   " )"
	_oSQL:_sQuery += " )"
	u_log2 ('info', _oSQL:_sQuery)
	if ! _oSQL:Exec ()
		u_help ('Erro ao criar backup: ' + _sNomeBkp,, .t.)
		_lRetBkp = .F.
	endif


	// Faz copia da tabela CT5 (lcto padrao) para ter um historico de como era contabilizado.
	incproc ('Gerando backup Lancamentos padronizados')
	_sNomeBkp = 'CT5' + _sNome2
	_oSQL:_sQuery := "SELECT * INTO " + _sNomeBkp
	_oSQL:_sQuery +=  " FROM " + RetSQLName ('CT5')
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND CT5_FILIAL = '" + xfilial ("CT5") + "'"
	u_log2 ('info', _oSQL:_sQuery)
	if ! _oSQL:Exec ()
		u_help ('Erro ao criar backup: ' + _sNomeBkp,, .t.)
		_lRetBkp = .F.
	endif
return
