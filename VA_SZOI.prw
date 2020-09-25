// Programa...: VA_SZOI
// Autor......: Robert Koch
// Data.......: 16/07/2008
// Descricao..: Rotina de impressao de ordens de ordens de embarque.
//
// Historico de alteracoes:
// 18/07/2008 - Robert  - Nao agrupava produto quando era de notas diferentes.
// 26/11/2008 - Robert  - Impressao da relacao dos municipios para entrega.
// 10/04/2019 - Robert  - Migrada tabela 98 do SX5 para 50 do ZX5.
// 30/08/2019 - Claudia - Alterado campo b1_p_brt para b1_pesbru.
//

// --------------------------------------------------------------------------
User Function VA_SZOI (_sOrdem)
	private cPerg := "VASZOI"
	private wnrel := "VA_SZOI"
	private nomeprog := "VA_SZOI"
	cString := "SZO"
	cDesc1  := "Este programa tem como objetivo imprimir relatorio de"
	cDesc2  := "Ordem de Embarque"
	cDesc3  := ""
	tamanho := "P"
	aReturn := { "Zebrado", 1,"Administracao", 2, 2, 1, "",1 }
	aLinha  := { }
	nLastKey:= 0
	titulo  := "ORDEM DE EMBARQUE"
	cabec1 := "DESCRICAO DO PRODUTO                                             QTDE       PESO"
	cabec2 := ""
	limite := 80
	titulo := "ORDEM DE EMBARQUE"
	
	// Cria as perguntas na tabela SX1
	_validPerg()
	
	// Se foi passado o numero da ordem de embarque, ajusta os parametros.
	if _sOrdem != NIL
		U_GravaSX1 (cPerg, "01", _sOrdem)           // Ordem de
		U_GravaSX1 (cPerg, "02", _sOrdem)           // Ordem ate
		U_GravaSX1 (cPerg, "03", "")                // Transp de
		U_GravaSX1 (cPerg, "04", "zzzzz")           // Transp ate
		U_GravaSX1 (cPerg, "05", ctod (""))         // Data de
		U_GravaSX1 (cPerg, "06", stod ("20491231")) // data ate
		U_GravaSX1 (cPerg, "07", "")                // Cliente
		U_GravaSX1 (cPerg, "08", "")                // Loja
		U_GravaSX1 (cPerg, "09", "zzzzzz")          // Cliente ate
		U_GravaSX1 (cPerg, "10", "zz")              // Loja ate
		U_GravaSX1 (cPerg, "11", "")                // Estado de
		U_GravaSX1 (cPerg, "12", "zz")              // Estado ate
	endif
	
	Pergunte(cPerg, .T.)

	wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
	If nLastKey == 27
		Return
	Endif
	fErase(__RelDir + wnrel + '.##r')
	SetDefault(aReturn,cString)
	If nLastKey == 27
		Return
	Endif
	processa ({|| RptDetail()})
	MS_FLUSH()  // Libera fila de relatorios em spool (Tipo Rede Netware)
	If aReturn [5] == 1
		DbCommitAll ()
		ourspool(wnrel)
	Endif
Return



// --------------------------------------------------------------------------
Static Function RptDetail()
	local _sQuery    := ""
	local _sAliasQ   := ""
	local _aMuni     := {}
	local _nMuni     := 0
	local _nNota	 := 0
	local _nMsg	     := 0
	local _nVia		 := 0
	private _nMaxLin := max (15, mv_par14)  // Para casos em que o usuario esquecer o parametro zerado.
	
	procRegua(LastRec())
	
	nTipo := 18
	li    := 80
	m_pag := 1
	
	// Monta arquivo de trabalho com dados das ordens a imprimir.
	incproc ("Buscando dados...")
	_sQuery := ""
//	_sQuery += " Select F2_ORDEMB, F2_TRANSP, A4_NOME, D2_COD, B1_DESC, B1_GRPEMB, substring (B1_VAGRLP, 1, 1) as ListaPrc1, substring (B1_VAGRLP, 2, 1) as ListaPrc2, X5_DESCRI, C6_DESCRI, Sum (D2_QUANT) Quant, sum (B1_PESBRU * D2_QUANT) as Peso, A4_TEL"
	_sQuery += " Select F2_ORDEMB, F2_TRANSP, A4_NOME, D2_COD, B1_DESC, B1_GRPEMB, substring (B1_VAGRLP, 1, 1) as ListaPrc1, substring (B1_VAGRLP, 2, 1) as ListaPrc2, ZX5_50.ZX5_50DESC, C6_DESCRI, Sum (D2_QUANT) Quant, sum (B1_PESBRU * D2_QUANT) as Peso, A4_TEL"
	_sQuery += "   From " + RetSQLName ("SF2") + " SF2, "
	_sQuery +=              RetSQLName ("SA4") + " SA4, "
	_sQuery +=              RetSQLName ("SB1") + " SB1, "
//	_sQuery +=              RetSQLName ("SX5") + " SX5,  "
	_sQuery +=              RetSQLName ("ZX5") + " ZX5_50,  "
	_sQuery +=              RetSQLName ("SA1") + " SA1,  "
	_sQuery +=              RetSQLName ("SD2") + " SD2  "
	_sQuery += "    Left join " + RETSQLNAME ("SC6") + " SC6 "
	_sQuery += "    on (SC6.D_E_L_E_T_ != '*'"
	_sQuery += "        AND C6_FILIAL   = '" + xfilial ("SC6") + "'"
	_sQuery += "        AND C6_NUM      = D2_PEDIDO"
	_sQuery += "        AND C6_ITEM     = D2_ITEMPV"
	_sQuery += "        AND C6_PRODUTO  = D2_COD)"
	_sQuery += "  Where SF2.D_E_L_E_T_ = ''"
	_sQuery += "    And SA4.D_E_L_E_T_ = ''"
	_sQuery += "    And SB1.D_E_L_E_T_ = ''"
	_sQuery += "    And SA1.D_E_L_E_T_ = ''"
	_sQuery += "    And SD2.D_E_L_E_T_ = ''"
	_sQuery += "    And F2_FILIAL  = '" + xfilial ("SF2") + "'"
	_sQuery += "    And A4_FILIAL  = '" + xfilial ("SA4") + "'"
	_sQuery += "    And B1_FILIAL  = '" + xfilial ("SB1") + "'"
	_sQuery += "    And A1_FILIAL  = '" + xfilial ("SA1") + "'"
	_sQuery += "    And D2_FILIAL  = '" + xfilial ("SD2") + "'"
	_sQuery += "    And A4_COD     = F2_TRANSP"
//	_sQuery += "    And X5_CHAVE   = B1_GRPEMB"
//	_sQuery += "    And X5_TABELA  = '98'"
	_sQuery += "    And ZX5_50.D_E_L_E_T_ = ''"
	_sQuery += "    And ZX5_50.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
	_sQuery += "    And ZX5_50.ZX5_50COD  = B1_GRPEMB"
	_sQuery += "    And ZX5_50.ZX5_TABELA = '50'"
	_sQuery += "    And B1_COD     = D2_COD"
	_sQuery += "    And A1_LOJA    = F2_LOJA"
	_sQuery += "    And A1_COD     = F2_CLIENTE"
	_sQuery += "    And D2_SERIE   = F2_SERIE"
	_sQuery += "    And D2_DOC     = F2_DOC"
	_sQuery += "    And F2_ORDEMB  between '" + mv_par01 + "' and '" + mv_par02 + "'"
	_sQuery += "    And F2_TRANSP  between '" + mv_par03 + "' and '" + mv_par04 + "'"
	_sQuery += "    And F2_EMISSAO between '" + dtos (mv_par05) + "' and '" + dtos (mv_par06) + "'"
	_sQuery += "    And F2_CLIENTE between '" + mv_par07 + "' and '" + mv_par09 + "'"
	_sQuery += "    And F2_LOJA    between '" + mv_par08 + "' and '" + mv_par10 + "'"
	_sQuery += "    And F2_EST     between '" + mv_par11 + "' and '" + mv_par12 + "'"
//	_sQuery += "  Group by F2_ORDEMB, F2_TRANSP, substring (B1_VAGRLP, 1, 1), substring (B1_VAGRLP, 2, 1), A4_NOME, D2_COD, B1_DESC, B1_GRPEMB, X5_DESCRI, C6_DESCRI, A4_TEL "
	_sQuery += "  Group by F2_ORDEMB, F2_TRANSP, substring (B1_VAGRLP, 1, 1), substring (B1_VAGRLP, 2, 1), A4_NOME, D2_COD, B1_DESC, B1_GRPEMB, ZX5_50.ZX5_50DESC, C6_DESCRI, A4_TEL "
//	_sQuery += "  Order by F2_ORDEMB, B1_GRPEMB, B1_DESC"
	_sQuery += "  Order by F2_ORDEMB, B1_GRPEMB,  substring (B1_VAGRLP, 1, 1), substring (B1_VAGRLP, 2, 1), B1_DESC"
	u_log (_sQuery)

 	_sAliasQ = GetNextAlias ()
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
	
	for _nVia = 1 to mv_par13
		(_sAliasQ) -> (DBGoTop ())
		Do While ! (_sAliasQ) -> (Eof ())
			
			// Zera a numeracao de paginas a cada ordem.
			m_pag = 1
	
			// Controla quebra por ordem de embarque.
			_sOrdem = (_sAliasQ) -> f2_ordemb
			_nTQtdGer = 0
			_nTPesGer = 0
			_aNotas   = {}
			_aMuni    = {}
			cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			@ li, 0 psay "ORDEM EMBARQUE: " + _sOrdem
			if _nVia == 1
				@ li, 42 psay "Via 1 - Transportadora (conferencia)"
			elseif _nVia == 2
				@ li, 42 psay "Via 2 - Expedicao (conferencia)"
			endif
			li ++
			@ li, 0 psay "TRANSPORTADORA: " + alltrim ((_sAliasQ) -> f2_transp) + " - " + (_sAliasQ) -> a4_nome + "- " + (_sAliasQ) -> a4_tel
			li += 2
			@ li, 0 psay __PrtFatLine ()
			li ++
			Do While ! (_sAliasQ) -> (Eof()) .and. (_sAliasQ) -> f2_ordemb == _sOrdem
				
				// Controla quebra por grupo de embalagem e grupo de lista de precos.
				_sGrpEmb  = (_sAliasQ) -> b1_GrpEmb
				_sGrLPrc1 = (_sAliasQ) -> ListaPrc1
				_sGrLPrc2 = (_sAliasQ) -> ListaPrc2
				_nTQtdGrp = 0
				_nTPesGrp = 0

				// Busca descricao dos grupos semelhante `a da lista de precos.
				sx5 -> (dbsetorder (1))
				if sx5 -> (dbseek (xfilial ("SX5") + "81" + _sGrLPrc1 + _sGrLPrc2, .F.))
					_sDescLis = alltrim (sx5 -> x5_descri) + " - " + alltrim (sx5 -> x5_descSpa)
				else
					_sDescLis = ""
				endif

				if li > _nMaxLin - 4
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				endif
//				@ li, 0 psay "GRUPO: " + _sGrpEmb + (_sAliasQ) -> b1_grpemb + " - " + alltrim ((_sAliasQ) -> x5_descri) + " - " + _sDescLis
				@ li, 0 psay "GRUPO: " + _sGrpEmb + (_sAliasQ) -> b1_grpemb + " - " + alltrim ((_sAliasQ) -> ZX5_50DESC) + " - " + _sDescLis
				li ++
				Do While ! (_sAliasQ) -> (Eof()) ;
					.and.  (_sAliasQ) -> f2_ordemb == _sOrdem ;
					.and.  (_sAliasQ) -> b1_grpemb == _sGrpEmb ;
					.and.  (_sAliasQ) -> ListaPrc1 == _sGrLPrc1 ;
					.and.  (_sAliasQ) -> ListaPrc2 == _sGrLPrc2
					
					_sDescri = iif (! empty ((_sAliasQ) -> c6_descri), (_sAliasQ) -> c6_descri, (_sAliasQ) -> b1_desc)
					
					if li > _nMaxLin
						cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
					endif
					@ li, 0 psay padr (left (alltrim ((_sAliasQ) -> d2_cod) + " - " + _sDescri, 61), 61, " ") + " " + ;
					             transform ((_sAliasQ) -> Quant, "@E 999,999") + " " + ;
					             transform ((_sAliasQ) -> Peso, "@E 999,999.99")
					li ++
					_nTQtdGrp += (_sAliasQ) -> Quant
					_nTQtdGer += (_sAliasQ) -> Quant
					_nTPesGrp += (_sAliasQ) -> Peso
					_nTPesGer += (_sAliasQ) -> Peso

					(_sAliasQ) -> (dbskip())
				enddo
				li ++
				if li > _nMaxLin - 2
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				endif
				@ li, 36 psay "Total do grupo    ==> " + transform (_nTQtdGrp, "@E 999,999,999") + " " + transform (_nTPesGrp, "@E 999,999.99")
				li ++
				@ li, 0 psay __PrtThinLine ()
				li ++
			enddo
			if li > _nMaxLin - 2
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			endif
			@ li, 36 psay "Total da ordem    ==> " + transform (_nTQtdGer, "@E 999,999,999") + " " + transform (_nTPesGer, "@E 999,999.99")
			li ++
			@ li, 0 psay __PrtFatLine ()
			li ++


			// Monta relacao das notas fiscais contempladas pela ordem de embarque
			_sQuery := ""
			_sQuery += " Select F2_DOC, "
			_sQuery +=        " CASE SF2.F2_TIPO"
			_sQuery +=             " WHEN 'B' THEN SA2.A2_MUN"
			_sQuery +=             " WHEN 'D' THEN SA2.A2_MUN"
			_sQuery +=             " ELSE SA1.A1_MUN"
			_sQuery +=        " END ,"
			_sQuery +=        " CASE SF2.F2_TIPO"
			_sQuery +=             " WHEN 'B' THEN SA2.A2_EST"
			_sQuery +=             " WHEN 'D' THEN SA2.A2_EST"
			_sQuery +=             " ELSE SA1.A1_EST"
			_sQuery +=        " END "
			_sQuery += "   From " + RetSQLName ("SF2") + " SF2 "

			// Busca clientes e fornecedores com left join por que vai depender do tipo de nota
			_sQuery +=        " LEFT JOIN " + RetSQLName ("SA2") + " SA2 "
			_sQuery +=              " ON (SA2.D_E_L_E_T_ = ''"
			_sQuery +=              " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
			_sQuery +=              " AND SA2.A2_COD     = SF2.F2_CLIENTE "
			_sQuery +=              " AND SA2.A2_LOJA    = SF2.F2_LOJA) "
			_sQuery +=        " LEFT JOIN " + RetSQLName ("SA1") + " SA1 "
			_sQuery +=              " ON (SA1.D_E_L_E_T_ = ''"
			_sQuery +=              " AND SA1.A1_FILIAL   = '" + xfilial ("SA1") + "'"
			_sQuery +=              " AND SA1.A1_COD     = SF2.F2_CLIENTE "
			_sQuery +=              " AND SA1.A1_LOJA    = SF2.F2_LOJA)"

			_sQuery += "  Where SF2.D_E_L_E_T_ = ''"
			_sQuery += "    And F2_FILIAL  = '" + xfilial ("SF2") + "'"
			_sQuery += "    And F2_ORDEMB  = '" + _sOrdem + "'"
			_sQuery += "  Order by F2_DOC"
			_aNotas = aclone (U_Qry2Array (_sQuery))

			// Gera string com os numeros das notas
			_sNotas = "NF: "
			for _nNota = 1 to len (_aNotas)
				_sNotas += _aNotas [_nNota, 1] + iif (_nNota == len (_aNotas), "", ", ")
				
				// Monta lista de municipios
				if ascan (_aMuni, {|_aVal| _aVal [1] == _aNotas [_nNota, 2] .and. _aVal [2] == _aNotas [_nNota, 3]}) == 0
					aadd (_aMuni, {_aNotas [_nNota, 2], _aNotas [_nNota, 3]})
				endif
			next
			_aNotas = aclone (U_QuebraTXT (_sNotas, limite))
			for _nNota = 1 to len (_aNotas)
				if li > _nMaxLin
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				endif
				@ li, 0 psay _aNotas [_nNota]
				li ++
			next
			
			// Lista municipios de entrega
			if li > _nMaxLin - 3
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			endif
			@ li, 0 psay "Municipios:"
			for _nMuni = 1 to len (_aMuni)
				if li > _nMaxLin
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				endif
				@ li, 12 psay _aMuni [_nMuni, 1] + " " + _aMuni [_nMuni, 2]
				li ++
			next
			li ++

/*
			li += 2
			if li > _nMaxLin - 3
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			endif
			@ li, 0 psay "   ________________________________          _________________________________"
			li ++
			@ li, 0 psay "              Expedicao                                Transportadora"
			li ++
*/
			@ li, 0 psay "   ________________________________          _________________________________"
			li ++
			@ li, 0 psay "       Separador (Nova Alianca)                  Conferente (Nova Alianca)"
			li += 2

			// Monta mensagem de rodape com quebra de texto.
			_sMsg := "Recebemos da " + alltrim (sm0 -> m0_nomecom) + " os produtos acima discriminados pela ordem de embarque No."
			_sMsg += _sOrdem + ". Deste momento em diante me responsabilizo pela integridade da mercadoria."
			_aMsg := U_QuebraTXT (_sMsg, limite)
			for _nMsg = 1 to len (_aMsg)
				if li > _nMaxLin - 1
					cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
				endif
				@ li, 0 psay _aMsg [_nMsg]
				li ++
			next
			li ++
			if li > _nMaxLin - 1
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			endif
			@ li, 0 psay "   ________________________________          _________________________________"
			li ++
			@ li, 0 psay "   Conferente transp.(nome legivel)                     Assinatura"
			li += 2
			if li > _nMaxLin - 1
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			endif
			@ li, 0 psay "   ________________________________          _________________________________"
			li ++
			@ li, 0 psay "                Placa                                      Data"
			li ++
/*
			li ++
			if li > _nMaxLin - 1
				cabec(titulo,cabec1,cabec2,wnrel,tamanho,nTipo)
			endif
			@ li, 0 psay "   ________________________________          _________________________________"
			li ++
			@ li, 0 psay "             Hora coleta                                Data coleta"
			li += 1
*/

			// Marca a ordem como 'jah impressa'.
			szo -> (dbsetorder (1))  // ZO_FILIAL+ZO_NUMERO
			if szo -> (dbseek (xfilial ("SZO") + _sOrdem, .F.))
				reclock ("SZO", .F.)
				szo -> zo_impres = "S"
				msunlock ()
			endif
	
		enddo
	next
	(_sAliasQ) -> (dbclosearea ())
	dbselectarea ("SZO")
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Ordem embarque de             ", "C", 5,  0,  "",   "SZO", {},    ""})
	aadd (_aRegsPerg, {02, "Ordem embarque ate            ", "C", 5,  0,  "",   "SZO", {},    ""})
	aadd (_aRegsPerg, {03, "Transportadora de             ", "C", 6,  0,  "",   "SA4", {},    ""})
	aadd (_aRegsPerg, {04, "Transportadora ate            ", "C", 6,  0,  "",   "SA4", {},    ""})
	aadd (_aRegsPerg, {05, "Data emissao da ordem de      ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {06, "Data emissao da ordem ate     ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {07, "Cliente de                    ", "C", 6,  0,  "",   "SA1", {},    ""})
	aadd (_aRegsPerg, {08, "Loja de                       ", "C", 2,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {09, "Cliente ate                   ", "C", 6,  0,  "",   "SA1", {},    ""})
	aadd (_aRegsPerg, {10, "Loja ate                      ", "C", 2,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {11, "Estado de                     ", "C", 2,  0,  "",   "12 ", {},    ""})
	aadd (_aRegsPerg, {12, "Estado ate                    ", "C", 2,  0,  "",   "12 ", {},    ""})
	aadd (_aRegsPerg, {13, "Quantidade de vias            ", "N", 2,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {14, "Maximo de linhas por pagina   ", "N", 2,  0,  "",   "   ", {},    ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
