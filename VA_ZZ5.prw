// Programa...: VA_ZZ5
// Autor......: Robert Koch
// Data.......: 19/02/2009
// Descricao..: Tela de manutencao transferencias de mercadorias da expedicao para a loja.
//              - A loja trabalha com codigos de produtos diferentes (garrafas) da expedicao (caixas)
//                e cada transferencia significa a desmontagem de uma caixa.
//              - Os usuarios da loja incluem (nesta tela) solicitacoes de transferencia.
//              - Os usuarios da expedicao efetivam a transferencia quando entregarem as mercadorias.
//
// Historico de alteracoes:
// 21/05/2015 - Robert - Verifica se encontra-se numa filial que tenha loja.
//

// --------------------------------------------------------------------------
User Function VA_ZZ5 ()
	local _aCores := U_VA_ZZ5LG (.T.)
	private aRotina := {}

	if ! cEmpAnt + cFilAnt $ '0113/0110'
		if ! msgnoyes ("Rotina desenvolvida para atender as filiais com loja (10 e 13). Confirma assim mesmo?","Confirmar")
			return
		endif
	endif

	aadd (aRotina, {"&Pesquisar"        , "AxPesqui", 0, 1})
	aadd (aRotina, {"&Visualizar"       , "AxVisual", 0, 2})
	aadd (aRotina, {"Sol&icitar"        , "AxInclui", 0, 3})
	aadd (aRotina, {"&Alterar"          , "AxAltera", 0, 4})
	aadd (aRotina, {"Canc&elar sol."    , "U_VA_ZZ5C ()", 0, 5})
	aadd (aRotina, {"&Transferir"       , "U_VA_ZZ5T ()", 0, 5})
	aadd (aRotina, {"&Legenda"          , "U_VA_ZZ5LG (.F.)", 0,5})
	private cString   := "ZZ5"
	private cCadastro := "Transferencias de mercadorias para a loja"
	dbselectarea ("ZZ5")
	dbSetOrder (1)
   mBrowse(,,,,"ZZ5",,,,,2, _aCores)
return



// --------------------------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function VA_ZZ5LG (_lRetCores)
   local _aCores := {}
   aadd (_aCores, {"zz5_estorn != 'S' .and.  empty (zz5_dtaten)" ,'BR_VERDE'})
   aadd (_aCores, {"zz5_estorn != 'S' .and. !empty (zz5_dtaten)" ,'BR_VERMELHO'})
   aadd (_aCores, {"zz5_estorn == 'S'"                           ,'BR_PRETO'})

   if ! _lRetCores
      BrwLegenda (cCadastro, "Legenda", {{"BR_VERMELHO", "Atendida"}, ;
                                         {"BR_VERDE",    "Nao atendida"}, ;
                                         {"BR_PRETO",    "Estornada"}})
   else
      return _aCores
   endif
return



// --------------------------------------------------------------------------
// Exclusao (cancelamento de solicitacao)
user function VA_ZZ5C ()
	if ! empty (zz5 -> zz5_dtaten)
		u_help ("Solicitacao ja' atendida nao pode ser cancelada.")
	else
		AxDeleta ("ZZ5", zz5 -> (recno ()), 5)
	endif
return
