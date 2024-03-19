// Programa...: BatLimCr
// Autor......: Robert Koch (criado com base no DT_LIMCRED de Catia Cardoso, de 07/01/2015)
// Data.......: 13/08/2019
// Descricao..: Ajustas datas de limites de credito de clientes - Desativa Clientes e altera o Risco para 'E'
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #batch
// #Descricao         #Ajustas datas de limites de credito de clientes - Desativa Clientes e altera o Risco para 'E'
// #PalavasChave      #bloqueio #clientes #limite_de_credito 
// #TabelasPrincipais #SA1
// #Modulos           #FAT
//
// Historico de alteracoes:
// 19/08/2019 - Robert  - Nao bloqueia funcionarios ativos/afastados.
// 26/08/2019 - Robert  - Ignora campo A1_ULTCOM por que o mesmo desconsidera notas de bonificacao.
// 04/09/2019 - Robert  - Nao bloqueia associados ativos e nem clientes ativados recentemente.
// 11/10/2019 - Robert  - Nao chamava AtuMerc() apos as alteracoes do SA1.
// 15/10/2019 - Andre   - Adicionado validação para clientes com codigo base diferentes.
// 23/10/2019 - Robert  - Nao bloqueia operadoras de cartao (codigo com 3 posicoes).
// 26/10/2021 - Claudia - Aumentado de 180 para 365 dias o bloqueio de clientes. GLPI: 11133
// 19/03/2024 - Robert  - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//

// --------------------------------------------------------------------------------------------------
user function BatLimCr ()
	local _oSQL      := NIL
	local _aRegSA1   := {}
	local _nRegSA1   := 0
	local _dNovaLC   := ctod ('')
	local _nQtDatLC  := 0
	local _nQtBloq   := 0
	local _oAssoc    := NIL
	local _lPodeBloq := .T.

	// Aumenta prazo do limite de credito dos clientes ativos.
	_dNovaLC = lastday (date () + 180)
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " "
	_oSQL:_sQuery += "SELECT R_E_C_N_O_"
	_oSQL:_sQuery += "  FROM " + RetSQLName ("SA1") + " SA1"
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += "   AND SA1.A1_MSBLQL != '1'"
	_oSQL:_sQuery += "   AND SA1.A1_VENCLC != ''"
	_oSQL:_sQuery += "   AND SA1.A1_VENCLC <= '" + dtos (_dNovaLC - 120) + "'"
	_oSQL:Log ()
	_aRegSA1 = _oSQL:Qry2Array (.f., .f.)
	for _nRegSA1 = 1 to len (_aRegSA1)
		sa1 -> (dbgoto (_aRegSA1 [_nRegSA1, 1]))

		u_log ('Aumentando data limite credito cliente', sa1 -> a1_cod, sa1 -> a1_loja, 'de', sa1 -> a1_venclc,'para',_dNovaLC)

		// Cria variaveis para uso na gravacao do evento de alteracao
		regtomemory ("SA1", .F., .F.)
		m->a1_venclc = _dNovaLC
			
		// Grava evento de alteracao
		_oEvento := ClsEvent():new ()
		_oEvento:AltCadast ("SA1", m->a1_cod, sa1 -> (recno ()), '', .F.)

		reclock ("SA1", .f.)
		sa1 -> a1_venclc = m->a1_venclc
		msunlock ()

		// Notifica o Mercanet de que este registro foi alterado.
		U_AtuMerc ('SA1', sa1 -> (recno ()))

		_nQtDatLC ++
	//	exit
	next


	// Bloqueia clientes sem compra nos ultimos 365 dias.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " "
	_oSQL:_sQuery += "SELECT R_E_C_N_O_"
	_oSQL:_sQuery += " FROM (SELECT R_E_C_N_O_, A1_CGC, A1_VADTINC, A1_MSBLQL, A1_RISCO, A1_VENCLC, A1_ULTCOM, A1_COD, A1_LOJA,"
	
	// Busca ultima NF por que nem sempre o campo A1_ULTCOM estah preenchido.
	_oSQL:_sQuery +=        " ISNULL ((SELECT MAX (F2_EMISSAO) FROM SF2010 WHERE D_E_L_E_T_ = '' AND F2_TIPO = 'N' AND F2_CLIENTE = A1_COD AND F2_LOJA = A1_LOJA), '') AS ULTCOM"

	_oSQL:_sQuery +=        "  FROM " + RetSQLName ("SA1")
	_oSQL:_sQuery +=       ") AS SA1"
	_oSQL:_sQuery += " WHERE SA1.A1_CGC NOT LIKE '%88612486%'" // desprezar os codigos de clientes que sao as nossas filiais
	_oSQL:_sQuery +=   " AND LEN (A1_CGC) > 3"  // Desprezar operadoras de cartao
	_oSQL:_sQuery +=   " AND ((ULTCOM != '' AND ULTCOM <= '" + dtos (date () - 365) + "')"
	_oSQL:_sQuery +=     " OR (ULTCOM  = '' AND SA1.A1_VADTINC <= '" + dtos (date () - 365) + "'))"

	// Se for um "codigo base", somente poderah ser bloqueado se tiver todos os codigos filhos ja bloqueados.
	_oSQL:_sQuery += " AND NOT EXISTS (SELECT *"
	_oSQL:_sQuery +=                   " FROM " + RetSQLName ("SA1") + " FILHA"
	_oSQL:_sQuery +=                  " WHERE FILHA.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                    " AND FILHA.A1_FILIAL  = '" + xfilial ("SA1") + "'"
	_oSQL:_sQuery +=                    " AND FILHA.A1_VACBASE = SA1.A1_COD"
	_oSQL:_sQuery +=                    " AND FILHA.A1_VALBASE = SA1.A1_LOJA"
	_oSQL:_sQuery +=     				" AND FILHA.A1_COD    != SA1.A1_COD"
	_oSQL:_sQuery +=                    " AND FILHA.A1_MSBLQL  = '2')

	// Nao bloqueia funcionarios ativos/afastados.
	_oSQL:_sQuery += " AND NOT EXISTS (SELECT *"
	_oSQL:_sQuery +=                   " FROM " + RetSQLName ("ZAD") + " ZAD"
	_oSQL:_sQuery +=                  " WHERE ZAD.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                    " AND ZAD.ZAD_FILIAL = '" + xfilial ("ZAD") + "'"
	_oSQL:_sQuery +=                    " AND ZAD.ZAD_CPF    = SA1.A1_CGC"
	_oSQL:_sQuery +=                    " AND ZAD.ZAD_SITUA != '4')"

	// Tem pelo menos um dos campos precisando ser alterado.
	_oSQL:_sQuery += "   AND (A1_MSBLQL != '1' OR A1_RISCO != 'E' OR A1_VENCLC != '')"
	_oSQL:Log ()
	_aRegSA1 = _oSQL:Qry2Array (.f., .f.)

	for _nRegSA1 = 1 to len (_aRegSA1)
		sa1 -> (dbgoto (_aRegSA1 [_nRegSA1, 1]))
		u_log ('Verificando cliente', sa1 -> a1_cod, sa1 -> a1_loja)
		_lPodeBloq = .T.

		// Verifica se eh associado e, nesse caso, se encontra-se inativo.
		if _lPodeBloq
			sa2 -> (dbsetorder (3))  // A2_FILIAL, A2_CGC
			if sa2 -> (dbseek (xfilial ("SA2") + sa1 -> a1_cgc, .F.))
				_oAssoc := ClsAssoc ():New (sa2 -> a2_cod, sa2 -> a2_loja, .T.)
				if valtype (_oAssoc) == "O"
					if _oAssoc:Ativo ()
						u_log ('Trata-se de associado ativo:', _oAssoc:Nome)
						_lPodeBloq = .F.
					else
						u_log ('Associado inativo por motivo:', _oAssoc:MotInativ)
					endif
				endif
			endif
		endif

		// Clientes ativados recentemente nao devem ser bloqueados.
		if _lPodeBloq
			_oSQL:_sQuery := " SELECT COUNT (*)"
			_oSQL:_sQuery +=   " FROM VA_VEVENTOS"
			_oSQL:_sQuery +=  " WHERE DATA        >= '" + dtos (date () - 180) + "'"
			_oSQL:_sQuery +=    " AND CLIENTE      = '" + sa1 -> a1_cod + "'"
			_oSQL:_sQuery +=    " AND LOJA_CLIENTE = '" + sa1 -> a1_loja + "'"
			_oSQL:_sQuery +=    " AND ALIAS_TABELA = 'SA1'"
			_oSQL:_sQuery +=    " AND CODEVENTO    = 'ALT001'"
			_oSQL:_sQuery +=    " AND DESCRITIVO LIKE '%<cpo>A1_MSBLQL</cpo>%'"
			_oSQL:_sQuery +=    " AND DESCRITIVO LIKE '%<de>1</de>%'"
			_oSQL:_sQuery +=    " AND DESCRITIVO LIKE '%<para>2</para>%'"
			_oSQL:Log ()
			if _oSQL:RetQry () > 0
				u_log ('Cliente foi desbloqueado recentemente')
				_lPodeBloq = .F.
			endif
		endif

		// Cria variaveis para uso na gravacao do evento de alteracao
		if _lPodeBloq
			u_log ('Bloqueando')
			regtomemory ("SA1", .F., .F.)
			m->a1_msblql = '1'
			m->a1_risco  = 'E'
			m->a1_venclc = ctod ('')
				
			// Grava evento de alteracao
			_oEvento := ClsEvent():new ()
			_oEvento:AltCadast ("SA1", m->a1_cod, sa1 -> (recno ()), '', .F.)

			reclock ("SA1", .f.)
			sa1 -> a1_risco  = m->a1_risco
			sa1 -> a1_venclc = m->a1_venclc
			sa1 -> a1_msblql = m->a1_msblql
			msunlock ()
			
			// Notifica o Mercanet de que este registro foi alterado.
			U_AtuMerc ('SA1', sa1 -> (recno ()))
			
			_nQtBloq ++
			//exit
		endif
	next

	// Dados de retorno para o controle de batches.
	_oBatch:Retorno = 'S'
	_oBatch:Mensagens += cvaltochar (_nQtDatLC) + " datas de limite credito alteradas; " + cvaltochar (_nQtBloq) + " clientes bloqueados."
return
