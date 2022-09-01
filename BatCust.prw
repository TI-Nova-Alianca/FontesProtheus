// Programa...: BatCust
// Autor......: Robert Koch
// Data.......: 17/06/2020
// Descricao..: Verifica custos negativos.
//
// Historico de alteracoes:
// 01/09/2022 - Robert - Melhorias ClsAviso.
//

// -----------------------------------------------------------------------------------------------------------------
user function BatCust ()
	local _oSQL    := NIL
	local _oAviso  := NIL
	local _aRegSB2 := {}
	local _nRegSB2 := 0

	u_log2 ('debug', 'Iniciando ' + procname ())
	_oBatch:Retorno = 'S'  // "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente

	// Nao executa se tiver algum processo de custo medio rodando. Para isso, verifica semaforo criado
	// pelo ponto de entrada MA330OK.
	if U_Semaforo ('CustoMedio', .F.) == 0
		u_log2 ('info', 'Encontrei processo de recalculo do custo medio ativo. Nao vou executar nada neste momento.')
	else
		// Itens com custo muito negativo causam erro de gravacao na movimentacao de estoque.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT R_E_C_N_O_"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SB2")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND B2_VATU1 < -1000000"
		_oSQL:Log ()
		_aRegSB2 = _oSQL:Qry2Array ()
		for _nRegSB2 = 1 to len (_aRegSB2)
			sb2 -> (dbgoto (_aRegSB2 [_nRegSB2, 1]))
			_oAviso := ClsAviso ():New ()
			_oAviso:Tipo       = 'A' // Aviso
			_oAviso:DestinAvis = 'grpTI'
			_oAviso:Texto      = 'Filial ' + cFilAnt + ' Item ' + alltrim (sb2 -> b2_cod) + ' Alm. ' + sb2 -> b2_local + ' com valor distorcido no B2_VATU (' + cvaltochar (sb2 -> b2_vatu1) + '). Ajustando para 1'
			_oAviso:Origem     = procname ()
			_oAviso:DiasDeVida = 60
			_oAviso:Grava ()
			reclock ("SB2", .F.)
			sb2 -> b2_vatu1 = 1
			msunlock ()
		next
	endif

	u_log2 ('debug', 'Finalizando ' + procname ())
return .T.
