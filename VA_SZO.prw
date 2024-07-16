// Programa...: VA_SZO
// Autor......: Robert Koch
// Data.......: 25/06/2008
// Cliente....: Alianca
// Descricao..: Tela de manutencao de ordens de embarque.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Manutencao de ordens de embarque expedicao
// #PalavasChave      #ordens_embarque
// #TabelasPrincipais #ZZO
// #Modulos           #FAT
//
// Historico de alteracoes:
// 23/04/2010 - Robert  - Criada rotina de confirmacao de embarque.
// 21/07/2020 - Robert  - Desabilitado botao 'confirmar embarque' pois nao eh mais usado.
//                      - Inseridas tags para catalogacao de fontes
// 23/11/2020 - Claudia - Ajustada variavel de numero conforme GLPI: 8750
//
// -------------------------------------------------------------------------------------
User Function VA_SZO()
   local _aCores    := U_VA_SZOLG(.T.)
	private aRotina := {}

	aadd (aRotina, {"&Pesquisar"   , "AxPesqui"						, 0,1})
	aadd (aRotina, {"&Visualizar"  , "U_VA_SZOV(.F., .F.)"			, 0,2})
	aadd (aRotina, {"&Nova"        , "U_VA_SZON"					, 0,3})
	aadd (aRotina, {"&Excluir"     , "U_VA_SZOV(.T., .F.)"			, 0,5})
	aadd (aRotina, {"&Imprimir"    , "U_VA_SZOI(szo->zo_numero)"	, 0,5})
	aadd (aRotina, {"&Legenda"     , "U_VA_SZOLG(.F.)"				, 0,5})
	
	private cString   := "SZO"
	private cCadastro := "Manutencao de ordens de embarque"
	dbselectarea("SZO")
	dbSetOrder(1)
	
	MBrowse(,,,,"SZO",,,,,4, _aCores,,,,,,,,, 60000, {|| o := GetMBrowse(), o:GoBottom(), o:GoTop(), o:Refresh() }) 
return
//
// --------------------------------------------------------------------------
// Mostra legenda ou retorna array de cores, cfe. o caso.
user function VA_SZOLG(_lRetCores)
	local _aCores := {}

	aadd(_aCores, {"zo_impres != 'S'" ,'BR_VERDE'	})
	aadd(_aCores, {"zo_impres == 'S'" ,'BR_VERMELHO'	})

	if ! _lRetCores
		BrwLegenda(cCadastro, "Legenda" , {{"BR_VERMELHO", "Impressa"	 },;
										   {"BR_VERDE"	 , "Nao impressa"}})
	else
		return _aCores
	endif
return
