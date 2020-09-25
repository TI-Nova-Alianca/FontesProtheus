// Programa...: TMKA503A
// Autor......: Robert Koch
// Data.......: 30/08/2010
// Descricao..: Para ser chamado no menu em lugar do TMKA503A padrao.
//              Criado inicialmente para rodar processo na saida da tela.
//
// Historico de alteracoes:
//

// --------------------------------------------------------------------------
user function _TMK503A ()
	local _sAliasQ := ""
//	u_logId ()

	// Executa rotina padrao.
	TMKA503A ()

	ade -> (dbsetorder (1))  // ADE_FILIAL+ADE_CODIGO
	sa1 -> (dbsetorder (1))  // 

	// Verifica acoes informadas pelo usuario.
	_sQuery := ""
	_sQuery += " select ADF.ADF_CODIGO, ZX5.ZX5_07TIPO "
	_sQuery += "   from " + RetSQLName ("ADF") + " ADF, "
	_sQuery +=              RetSQLName ("ADE") + " ADE, "
	_sQuery +=              RetSQLName ("ZX5") + " ZX5 "
	_sQuery += "  where ADF.D_E_L_E_T_ != '*'"
	_sQuery += "    and ADE.D_E_L_E_T_ != '*'"
	_sQuery += "    and ZX5.D_E_L_E_T_ != '*'"
	_sQuery += "    and ADF_FILIAL      = '" + xfilial ("ADF") + "'"
	_sQuery += "    and ADE_FILIAL      = '" + xfilial ("ADE") + "'"
	_sQuery += "    and ZX5_FILIAL      = '" + xfilial ("ZX5") + "'"
	_sQuery += "    and ZX5_TABELA      = '07'"
	_sQuery += "    and ZX5_07ACAO      = ADF.ADF_VAACAO"
	_sQuery += "    and ADF_CODIGO      = ADE.ADE_CODIGO"
	_sQuery += "    and ADF_DATA        = '" + dtos (dDataBase) + "'"
	_sQuery += "    and ADE_ENTIDA      = 'SA1'"
	_sQuery += "    and ADE_ASSUNT      = '000008'"  // Inativacao de clientes
	_sQuery += "    and ADE_STATUS     != '3'"  // Encerrado
	u_log (_sQuery)
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
	u_logtrb (_sAliasQ, .t.)
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())
		if (_sAliasQ) -> zx5_07Tipo $ "D/R"
			u_log (xfilial ("ADE") + (_sAliasQ) -> adf_codigo)
			if ade -> (dbseek (xfilial ("ADE") + (_sAliasQ) -> adf_codigo, .F.))

				// Encerra a pendencia
				u_log ("Encerrando")
				reclock ("ADE", .F.)
				ade -> ade_status = "3"
				msunlock ()

				// Atualiza status do cliente
				if sa1 -> (dbseek (xfilial ("SA1") + ade -> ade_chave, .F.))
					u_log ("Atualizando cli")
					if (_sAliasQ) -> zx5_07Tipo == "D"
						reclock ("SA1", .F.)
						sa1 -> a1_vaStatC = "D"
						msunlock ()

						// Grava evento para posterior consulta.
						_oEvento := ClsEvent():new ()
						_oEvento:CodEven = "SA1001"
						_oEvento:Texto   = "Cliente inativado definitivamente cfe. pendencia '" + ade -> ade_codigo + "' do Call Center"
						_oEvento:Cliente = sa1 -> a1_Cod
						_oEvento:LojaCli = sa1 -> a1_Loja
						_oEvento:Grava ()
						u_log ("Desativei defin. ", sa1 -> a1_cod)

					elseif (_sAliasQ) -> zx5_07Tipo == "R"
						reclock ("SA1", .F.)
						sa1 -> a1_vaStatC = "A"
						msunlock ()
						u_log ("Reativei ", sa1 -> a1_cod)
					endif
				endif
			endif
		endif
		(_sAliasQ) -> (dbskip ())
	enddo
return
