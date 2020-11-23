// Programa:  MT410Cpy
// Autor:     Robert Koch
// Data:      16/10/2008
// Cliente:   Alianca
// Descricao: P.E. durante a copia de pedidos de venda.
//            Criado, inicialmente, para limpar campos que nao devem ser copiados.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. durante a copia de pedidos de venda.
// #PalavasChave      #pedido_de_venda #pedido #copia_de_pedido 
// #TabelasPrincipais #SC5 #SC6  
// #Modulos 		  #FAT 
//
// Historico de alteracoes:
// 09/03/2009 - Robert  - Incluido campo C5_VAUSER.
// 14/05/2009 - Robert  - Incluido campo C5_VADCO.
// 23/06/2009 - Robert  - Incluido campo C5_PEDCLI.
// 22/05/2014 - Robert  - Incluido campo C5_TPCARGA.
// 27/05/2014 - Robert  - Incluido campo C5_VAPEMB.
// 28/08/2019 - Andre   - Incluido campo C5_VAPDMER.
// 23/11/2020 - Claudia - Incluida a limpeza de campos C6_TES e C6_VAOPER. GLPI: 8801
//
// --------------------------------------------------------------------------------------
user function MT410Cpy ()
	local _aAreaAnt  := U_ML_SRArea ()
	local _i         := 0
	Local nPosTes    := GdFieldPos("C6_TES") 
	Local nPosOper   := GdFieldPos("C6_VAOPER") 

	m->c5_cliente = CriaVar ("C5_CLIENTE")
	m->c5_lojacli = CriaVar ("C5_LOJACLI")
	m->c5_tabela  = CriaVar ("C5_TABELA")
	m->c5_client  = CriaVar ("C5_CLIENT")
	m->c5_lojaent = CriaVar ("C5_LOJAENT")
	m->c5_vaUser  = CriaVar ("C5_VAUSER")
	m->c5_vaDCO   = CriaVar ("C5_VADCO")
	m->c5_PedCli  = CriaVar ("C5_PEDCLI")
	m->c5_VaPDMer = CriaVar ("C5_VAPDMER")
	m->c5_vaPEmb  = ''
	m->c5_TpCarga = ''  // Campo obrigatorio. Quero que o usuario revise-o.

	//Percorrendo linhas da grid
	For _i := 1 To Len(aCols)
		aCols[_i][nPosTes]  := '   '// campo C6_TES
		aCols[_i][nPosOper] := '  ' // campo C6_OPER
	Next _i

	U_ML_SRArea (_aAreaAnt)
return
