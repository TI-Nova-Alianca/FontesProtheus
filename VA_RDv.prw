// Programa:   VA_RDV
// Autor:      Robert Koch
// Data:       04/05/2009
// Cliente:    Alianca
// Descricao:  Relatorio de devolucoes de vendas.
// 
// Historico de alteracoes:
// 27/04/2010 - Robert  - Criado tratamento para retornar dados para indicadores.
// 26/09/2011 - Robert  - Criados parametros de gerente comercial de... ate.
// 06/09/2013 - Leandro DWT - Inclusão de parâmetro para verificar se o usuário quer imprimir retornos simbólicos das filiais
// 29/02/2016 - Catia   - valiadações relatorio  - imprimir valores de fretes. 
// 03/03/2016 - Robert  - Declarada novamente a variavel aOrd (necessaria para execucao sme interface com o usuario).
// 30/03/2016 - Catia   - Opcao de Gerar em Planilha
// 12/04/2016 - Catia   - Opção de selecionar área de responsabilidade
// 23/10/2017 - Robert  - Removida geracao de arquivo de log.
// 05/12/2018 - Andre   - Ajustado para que a coluna FRETE CIF NA VENDA mostre o valor referente ao frete devolvido e não o frete total do produto.
// 25/01/2019 - Andre   - Pesquisa ZX5 alterada de FBUSCACPO para U_RETZX5.
// 05/09/2019 - Andre   - Adicionado opção de filtrar por Filiais.
// 15/10/2019 - Andre   - Em caso de planilha adicionado colunas D1_EMISSAO, D1_LOTECTL.
// 30/03/2020 - Claudia - Ajuste nos campos de ITEM, conforme GLPI: 7738
// 02/04/2020 - Claudia - Voltada alteração GLPI: 7738
// 28/03/2022 - Robert - Eliminada funcionalidade de conversao para TXT (em alguns casos 'perdia' o relatorio).
//

// --------------------------------------------------------------------------------------
user function VA_RDV (_lAutomat, _lIndicad)
	local _aRet     := {}
	private _lAuto  := iif (valtype (_lAutomat) == "L", _lAutomat, .F.)  // Uso sem interface com o usuario.
	private _lIndic := iif (valtype (_lIndicad) == "L", _lIndicad, .F.)  // Retorna dados para geracao de indicadores.
	
	// Variaveis obrigatorias dos programas de relatorio
	cString  := "SD1"
	cDesc1   := "Relatorio de devolucoes"
	cDesc2   := " "
	cDesc3   := " "
	tamanho  := "G"
	aReturn  := {"Zebrado", 1,"Administracao", 1, 2, 1, "",1}
	aLinha   := {}
    nLastKey := 0
    cPerg    := "VA_RDV"
    titulo   := "Devoluções"
    wnrel    := "VA_RDV"
    nTipo    := 0
	aOrd     := {}
         
	_ValidPerg ()
	pergunte (cPerg, .F.)

	if ! _lAuto

		// Execucao com interface com o usuario.
		//wnrel:=SetPrint(cString,wnrel,cPerg,Titulo,cDesc1,cDesc2,cDesc3,.F., aOrd, .T., NIL, tamanho, NIL, .F., NIL, NIL, .F., .T., NIL)
		wnrel:=SetPrint(cString,wnrel,cPerg,titulo,cDesc1,cDesc2,cDesc3,.F.)
		
	else
		// Execucao sem interface com o usuario.
		//
		// Deleta o arquivo do relatorio para evitar a pergunta se deseja sobrescrever.
		delete file (__reldir + wnrel + ".##r")
		//
		// Chama funcao setprint sem interface... essa deu trabalho!
		__AIMPRESS[1]:=1  // Obriga a impressao a ser "em disco" na funcao SetPrint
		wnrel := SetPrint (cString, ;  // Alias
		wnrel, ;  // Sugestao de nome de arquivo para gerar em disco
		cPerg, ;  // Parametros
		@titulo, ;  // Titulo do relatorio
		cDesc1, ;  // Descricao 1
		cDesc2, ;  // Descricao 2
		cDesc3, ;  // Descricao 3
		.F., ;  // .T. = usa dicionario
		aOrd, ;  // Array de ordenacoes para o usuario selecionar
		.T., ;  // .T. = comprimido
		tamanho, ;  // P/M/G
		NIL, ;  // Nao pude descobrir para que serve.
		.F., ;  // .T. = usa filtro
		NIL, ;  // lCrystal
		NIL, ;  // Nome driver. Ex.: "EPSON.DRV"
		.T., ;  // .T. = NAO mostra interface para usuario
		.T., ;  // lServer
		NIL)    // cPortToPrint
	endif

	If nLastKey == 27
		Return
	Endif
	delete file (__reldir + wnrel + ".##r")
	SetDefault (aReturn, cString)
	If nLastKey == 27
		Return
	Endif
	
	if _lIndic
		_aRet = aclone (_Imprime ())
	else
		processa ({|| _Imprime ()})
	endif
	MS_FLUSH ()
	DbCommitAll ()

	if ! _lIndic
		if ! _lAuto
			If aReturn [5] == 1
				ourspool(wnrel)
			Endif
		endif
	endif
return _aRet
// --------------------------------------------------------------------------
// Geracao do arquivo de trabalho p/ impressao
static function _Imprime ()
	local _nMaxLin   := 68
	local _sQuery    := ""
	//local _aAliasQ   := ""
	local _aMotivos  := {}
	local _aRespon   := {}
	local _nMotivo   := 0
	local _nRespon   := 0
	//local _nValor    := 0
	//local _aTotVend  := {}
	local _aTotGer   := {}
	//local _aTotGer   := {}
	//local _aTotRep   := {}

	// Nao aceita filtro por que precisaria inserir na query.
	If !Empty(aReturn[7])
		u_help ("Este relatorio nao aceita filtro do usuario.")
		return
	EndIf	
	
	cCabec1  := "NF DEVOLUCAO  DATA        CLIENTE                         UF  PRODUTO                      QUANT UM         "
	cCabec2  := "                                                                                                         "
	if ! u_zzuvl ('057', __cUserId, .F.)
		cCabec1 += "VALOR     VALOR     VALOR      FRETE CIF  NF VENDA    FRETE CIF   NRO.CONH   "
		cCabec2 += "PRODUTOS        ST       IPI       NA VENDA              DEVOLUCAO    RETORNO"
	endif		
	cCabec1 += "MOTIVO DA DEVOLUCAO"
 	aOrd     := {}
	
    nTipo := IIF(aReturn[4]==1,15,18)
    li    := 80
    m_pag := 1
    
	li = _nMaxLin + 1
	procregua (3)
	Titulo += " de " + dtoc (mv_par05) + " até " + dtoc (mv_par06)

	_sQuery := ""
	_sQuery += " with C as ("
	_sQuery += " select SD1.D1_DOC, SD1.D1_SERIE, SD1.D1_DTDIGIT, SD1.D1_FORNECE, SD1.D1_LOJA, SA1.A1_NOME, SA1.A1_EST, SA1.A1_CGC, SD1.D1_DESCRI, SD1.D1_NFORI, "
	if mv_par21 == 1
		_sQuery += " SD1.D1_EMISSAO, SD1.D1_LOTECTL, "
	endif 
	_sQuery += "        SD1.D1_COD, D1_UM, SD1.D1_QUANT, SD1.D1_VUNIT * SD1.D1_QUANT AS D1_TOTAL, SD1.D1_MOTDEV, SF2.F2_VEND1, D1_VALIPI, D1_ICMSRET,"
	_sQuery += "        ISNULL(ZX5_02DESC,'') AS ZX5_02DESC, ISNULL(ZX5_02DUPL,'') AS ZX5_02DUPL, ISNULL(ZX5_02RESP,'') AS ZX5_02RESP,"
	_sQuery += "        (SELECT ROUND (SUM (SZH.ZH_RATEIO)*SD1.D1_QUANT/SD2.D2_QUANT,2) "
	_sQuery += "           FROM " + RetSQLName ("SZH") + " AS SZH "
	_sQuery += "          WHERE SZH.D_E_L_E_T_ = ''"
	_sQuery += "            And SZH.ZH_FILIAL  = SD2.D2_FILIAL
	_sQuery += "            And SZH.ZH_NFSAIDA = SD2.D2_DOC"
	_sQuery += "            And SZH.ZH_SERNFS  = SD2.D2_SERIE"
	_sQuery += "            And SZH.ZH_ITNFS   = SD2.D2_ITEM) AS FRETECIF"
	_sQuery += "        ,(SELECT SUM (SZH.ZH_RATEIO) "
	_sQuery += "           FROM " + RetSQLName ("SZH") + " AS SZH "
	_sQuery += "          WHERE SZH.D_E_L_E_T_ = ''"
	_sQuery += "            And SZH.ZH_FILIAL  = SD1.D1_FILIAL
	_sQuery += "            and SZH.ZH_CLIFOR  = SD1.D1_FORNECE"
	_sQuery += "			and SZH.ZH_LJCLIFO = SD1.D1_LOJA"        
	_sQuery += "            And SZH.ZH_NFENTR  = SD1.D1_DOC"
	_sQuery += "            And SZH.ZH_SRNFENT = SD1.D1_SERIE"
	_sQuery += "            And SZH.ZH_ITNFE   = SUBSTRING(SD1.D1_ITEM,3,2)) AS TOTAL_FRETE"
	//_sQuery += "            And SZH.ZH_ITNFE   = SD1.D1_ITEM) AS TOTAL_FRETE"
	_sQuery += "        ,(SELECT TOP 1 SZH.ZH_NFFRETE "
	_sQuery += "           FROM " + RetSQLName ("SZH") + " AS SZH "
	_sQuery += "          WHERE SZH.D_E_L_E_T_ = ''"
	_sQuery += "            And SZH.ZH_FILIAL  = SD1.D1_FILIAL
	_sQuery += "            and SZH.ZH_CLIFOR  = SD1.D1_FORNECE"
	_sQuery += "			and SZH.ZH_LJCLIFO = SD1.D1_LOJA"            
	_sQuery += "            And SZH.ZH_NFENTR  = SD1.D1_DOC"
	_sQuery += "            And SZH.ZH_SRNFENT = SD1.D1_SERIE"
	_sQuery += "            And SZH.ZH_ITNFE   = SUBSTRING(SD1.D1_ITEM,3,2)) AS NR_CONH"
	//_sQuery += "            And SZH.ZH_ITNFE   = SD1.D1_ITEM) AS NR_CONH"
	_sQuery +=  " from " + RETSQLNAME ("SA1") + " SA1, "
	_sQuery +=             RETSQLNAME ("SD1") + " SD1 "
	_sQuery +=     " inner join " + RETSQLNAME ("SF4") + " SF4 "
	_sQuery +=                " on (SF4.D_E_L_E_T_    = ''"
	_sQuery +=                "     and SF4.F4_FILIAL = '" + xfilial ("SF4")  + "'"
	_sQuery +=                "     and SF4.F4_CODIGO = SD1.D1_TES"
	_sQuery +=                "     and SF4.F4_MARGEM = '2')"
	_sQuery +=     " left join " + RETSQLNAME ("ZX5") + " ZX5 "
	_sQuery +=   		" ON( ZX5.D_E_L_E_T_   = ''"
	_sQuery +=   		" and ZX5.ZX5_FILIAL   = '" + xfilial ("ZX5")  + "'"
	_sQuery +=   		" and ZX5.ZX5_TABELA   = '02'"
	_sQuery +=   		" and ZX5.ZX5_02MOT    = SD1.D1_MOTDEV)"
	_sQuery +=     " left join " + RETSQLNAME ("SD2") + " SD2 "
	_sQuery +=          " left join " + RETSQLNAME ("SF2") + " SF2 "
	_sQuery +=                " on (SF2.D_E_L_E_T_   = ''"
	_sQuery +=                " and SF2.F2_FILIAL    = SD2.D2_FILIAL"
	_sQuery +=                " and SF2.F2_DOC       = SD2.D2_DOC"
	_sQuery +=                " and SF2.F2_SERIE     = SD2.D2_SERIE"
	_sQuery +=                " and SF2.F2_CLIENTE   = SD2.D2_CLIENTE"
	_sQuery +=                " and SF2.F2_LOJA      = SD2.D2_LOJA)"
	_sQuery +=           " on (SD2.D_E_L_E_T_   = ''"
	_sQuery +=           " and SD2.D2_FILIAL    = SD1.D1_FILIAL"
	_sQuery +=           " and SD2.D2_DOC       = SD1.D1_NFORI"
	_sQuery +=           " and SD2.D2_SERIE     = SD1.D1_SERIORI"
	_sQuery +=           " and SD2.D2_ITEM      = SD1.D1_ITEMORI"
	_sQuery +=           " and SD2.D2_CLIENTE   = SD1.D1_FORNECE"
	_sQuery +=           " and SD2.D2_LOJA      = SD1.D1_LOJA)"
	_sQuery += " where SA1.D_E_L_E_T_   = ''"
	_sQuery +=   " and SA1.A1_FILIAL    = '" + xfilial ("SA1")  + "'"
	_sQuery +=   " and SA1.A1_COD       = SD1.D1_FORNECE"
	_sQuery +=   " and SA1.A1_LOJA      = SD1.D1_LOJA"
	if mv_par20 == 2
		_sQuery +=   " AND A1_CGC NOT LIKE '" + left(SM0->M0_CGC,8) + "%'"
	endif
	_sQuery +=   " and SD1.D_E_L_E_T_   = ''"
	_sQuery +=   " and SD1.D1_FILIAL    BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "'"
	_sQuery +=   " and SD1.D1_TIPO      = 'D'"
	_sQuery +=   " and SD1.D1_NFORI    != ''"
	_sQuery +=   " and SD1.D1_DTDIGIT   between '" + dtos (mv_par05)   + "' and '" + dtos (mv_par06)   + "'"
	_sQuery +=   " and SD1.D1_MOTDEV    between '" + mv_par07          + "' and '" + mv_par08          + "'"
	_sQuery +=   " and SD1.D1_FORNECE + SD1.D1_LOJA between '" + mv_par10+mv_par11 + "' and '" + mv_par12+mv_par13 + "'"
	_sQuery +=   " and SD1.D1_COD       between '" + mv_par14          + "' and '" + mv_par15          + "'"
	if (val(mv_par03) + val(mv_par04)) > 0
		_sQuery +=   " and SF2.F2_VEND1     between '" + mv_par03          + "' and '" + mv_par04          + "'"
	endif
	
	if (val(mv_par18) + val(mv_par19)) > 0		
		_sQuery +=   " and EXISTS (SELECT *
		_sQuery +=                 " FROM " + RETSQLNAME ("SA3") + " SA3 "
		_sQuery +=                " WHERE SA3.D_E_L_E_T_  != '*'"
		_sQuery +=                  " and SA3.A3_FILIAL    = '" + xfilial ("SA3") + "'"
		_sQuery +=                  " and SA3.A3_COD       = SF2.F2_VEND1"
		_sQuery +=                  " and SA3.A3_VAGEREN   BETWEEN '" + mv_par18 + "' AND '" + mv_par19 + "')"
	endif
	_sQuery += "  )"
	_sQuery += " select * from C  "
	_sQuery += "  where 1=1"
//  _sQuery +=   " and ZX5.D_E_L_E_T_   = ''"
//	_sQuery +=   " and ZX5.ZX5_FILIAL   = '" + xfilial ("ZX5")  + "'"
//	_sQuery +=   " and ZX5.ZX5_TABELA   = '02'"
//	_sQuery +=   " and ZX5.ZX5_02MOT    = SD1.D1_MOTDEV"
	
	if mv_par09 == 1
		_sQuery +=   " and ZX5_02DUPL = 'S'"
	elseif mv_par09 == 2
		_sQuery +=   " and ZX5_02DUPL = 'N'"
	endif
	
	do case
		case mv_par22 == 2
			_sQuery +=   " and ZX5_02RESP = 'A'"
		case mv_par22 == 3
			_sQuery +=   " and ZX5_02RESP = 'C'"
		case mv_par22 == 4
			_sQuery +=   " and ZX5_02RESP = 'I'"
	endcase

	do case
		case mv_par16 == 1
			_sQuery += " order by F2_VEND1, D1_FORNECE, D1_LOJA, D1_DTDIGIT, D1_COD"
		case mv_par16 == 2
			_sQuery += " order by D1_MOTDEV, D1_DTDIGIT, D1_DOC"
		case mv_par16 == 3
			_sQuery += " order by D1_DTDIGIT, D1_DOC"						
	endcase

	//u_showmemo ( _sQuery)
	
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t.,'TOPCONN',TcGenQry(,,_sQuery), _sAliasQ,.F.,.F.)
	TCSetField (alias (), "D1_DTDIGIT", "D")
	
	if mv_par21 == 1  // gera em planilha
		processa ({ || U_Trb2XLS (_sAliasQ, .F.)})
		return
	endif
	
	_aTotGer      = {0, 0, 0, 0, 0}
	_aTotQuebra   = {0, 0, 0, 0, 0}
	_wquebra = ''
	_Squebra = ''
	
	do while ! (_sAliasQ) -> (eof ())
		do case 
			case mv_par16 == 1
				_wquebra = (_sAliasQ) -> f2_vend1
			case mv_par16 == 2
				_wquebra = (_sAliasQ) -> D1_MOTDEV
			case mv_par16 == 3
				_wquebra = dtos((_sAliasQ) -> D1_DTDIGIT)								
		endcase
						
		if _sQuebra !='' .and. _sQuebra <> _wquebra
			if li > _nMaxLin - 2
				cabec(titulo,cCabec1,cCabec2,wnrel,tamanho,nTipo)
			endif
			if ! u_zzuvl ('057', __cUserId, .F.)
				// imprime total da quebra
				do case
					case mv_par16 == 1
						_sLinImp := "TOTAL VENDEDOR :" + "                         "
					case mv_par16 == 2
						_sLinImp := "TOTAL MOVIMENTO:" + "                         "
					case mv_par16 == 3
						_sLinImp := "  TOTAL NA DATA:" + "                         "				 					
				endcase			
				_sLinImp += transform (_aTotQuebra [1], "@E 9,999,999.99") + " "
				_sLinImp += transform (_aTotQuebra [2], "@E 99,999.99") + " "
				_sLinImp += transform (_aTotQuebra [3], "@E 99,999.99") + "    "
				_sLinImp += transform (_aTotQuebra [4], "@E 99,999.99") + "   "
				_sLinImp += "            "
				_sLinImp += transform (_aTotQuebra [5], "@E 99,999.99") + "   "
				li += 1
				@ li, 60 psay _sLinImp
				_aTotQuebra [1] = 0
				_aTotQuebra [2] = 0 
				_aTotQuebra [3] = 0
				_aTotQuebra [4] = 0
				_aTotQuebra [5] = 0
			endif
			li ++
			if mv_par17 == 2  // Detalhado
				@ li, 0 psay __PrtThinLine ()
				li += 2
			endif
		endif
		
		if li > _nMaxLin - 2
			cabec(titulo,cCabec1,cCabec2,wnrel,tamanho,nTipo)
		endif  
		
		if mv_par17 == 2  // Detalhado
				if _sQuebra <> _wquebra
					do case
						case mv_par16 == 1
							@ li, 0 psay "Vendedor: " + (_sAliasQ) -> f2_vend1 + " - " + fBuscaCpo ("SA3", 1, xfilial ("SA3") + (_sAliasQ) -> f2_vend1, "A3_NOME")
							_sQuebra = (_sAliasQ) -> f2_vend1
						case mv_par16 == 2
							//@ li, 0 psay "Motivo: " + (_sAliasQ) -> D1_MOTDEV + " - " + fBuscaCpo ("ZX5", 1, xfilial ("ZX5") + '02' + (_sAliasQ) -> D1_MOTDEV, "ZX5_02DESC")
							U_LOG ("Motivo: ", (_sAliasQ) -> D1_MOTDEV)
							@ li, 0 psay "Motivo: " + (_sAliasQ) -> D1_MOTDEV + " - " + u_RetZX5 ('02', (_sAliasQ) -> D1_MOTDEV, "ZX5_02DESC")
							_sQuebra = (_sAliasQ) -> D1_MOTDEV
						case mv_par16 == 3
							@ li, 0 psay "Data: " + dtoc ((_sAliasQ) -> d1_dtdigit)
							_sQuebra = dtos((_sAliasQ) -> D1_DTDIGIT)											
					endcase
					li += 2
				endif				
		endif
		// se cliente for Aliança, pula registro para não considerar retornos simbólicos
		//if mv_par20 == 2
		//	if substr((_sAliasQ)->A1_CGC,1,10) == '8861248600'
		//       	(_sAliasQ)->(dbskip ())
		//       	loop
		//    endif           
	    //endif
        
        if li > _nMaxLin - 2
			cabec(titulo,cCabec1,cCabec2,wnrel,tamanho,nTipo)
		endif  
		
		if mv_par17 == 2  // Detalhado
			_sLinImp := ""
			_sLinImp += (_sAliasQ) -> d1_doc + "/" + (_sAliasQ) -> d1_serie + " "
			_sLinImp += dtoc ((_sAliasQ) -> d1_dtdigit) + "  "
			_sLinImp += u_TamFixo ((_sAliasQ) -> d1_fornece + "/" + (_sAliasQ) -> d1_loja + " - " + (_sAliasQ) -> a1_nome, 30) + "  "
			_sLinImp += (_sAliasQ) -> a1_est + "  "
			_sLinImp += u_TamFixo (alltrim ((_sAliasQ) -> d1_COD) + " - " + (_sAliasQ) -> D1_DESCRI, 25) + "  "
			_sLinImp += transform ((_sAliasQ) -> d1_quant, "@E 9999.99") + " "
			_sLinImp += (_sAliasQ) -> d1_um + "  "
			
			if ! u_zzuvl ('057', __cUserId, .F.)
				_sLinImp += transform ((_sAliasQ) -> d1_total, "@E 9,999,999.99") + " "
				_sLinImp += transform ((_sAliasQ) -> d1_ICMSRET, "@E 99,999.99") + " "
				_sLinImp += transform ((_sAliasQ) -> d1_ValIPI, "@E 99,999.99") + "    "
				_sLinImp += transform ((_sAliasQ) -> FreteCIF, "@E 99,999.99") + "   "
				_sLinImp += (_sAliasQ) -> D1_NFORI + "   "
				_sLinImp += transform ((_sAliasQ) -> TOTAL_FRETE, "@E 99,999.99") + "   "
				_sLinImp += (_sAliasQ) -> NR_CONH + "   "
			else
				_sLinImp += "       "	
			endif
							
			_sLinImp += (_sAliasQ) -> D1_MOTDEV + ' - ' + left ( (_sAliasQ) -> zx5_02desc, 30)
			@ li, 0 psay _sLinImp
			li ++
		endif

		// Acumula totais e subtotais
		_aTotQuebra [1] += (_sAliasQ) -> d1_total
		_aTotQuebra [2] += (_sAliasQ) -> d1_ICMSRET
		_aTotQuebra [3] += (_sAliasQ) -> d1_ValIPI
		_aTotQuebra [4] += (_sAliasQ) -> FreteCIF
		_aTotQuebra [5] += (_sAliasQ) -> TOTAL_FRETE
		
		_aTotGer [1] += (_sAliasQ) -> d1_total
		_aTotGer [2] += (_sAliasQ) -> d1_ICMSRET
		_aTotGer [3] += (_sAliasQ) -> d1_ValIPI
		_aTotGer [4] += (_sAliasQ) -> FreteCIF
		_aTotGer [5] += (_sAliasQ) -> TOTAL_FRETE

		// Acrescenta esta devolucao `a array para posterior por motivo
		_nMotivo = ascan (_aMotivos, {|_aVal| _aVal [1] == (_sAliasQ) -> d1_motdev})
		if _nMotivo == 0
			aadd (_aMotivos, {(_sAliasQ) -> d1_motdev, substr( (_sAliasQ) -> zx5_02desc, 1,40) + ' - ' + (_sAliasQ) -> zx5_02resp, 0,0,0,0,0})
			_nMotivo = len (_aMotivos)
		endif
		_aMotivos [_nMotivo, 3] += (_sAliasQ) -> d1_total
		_aMotivos [_nMotivo, 4] += (_sAliasQ) -> d1_ICMSRET
		_aMotivos [_nMotivo, 5] += (_sAliasQ) -> d1_ValIPI
		_aMotivos [_nMotivo, 6] += (_sAliasQ) -> FreteCIF
		_aMotivos [_nMotivo, 7] += (_sAliasQ) -> TOTAL_FRETE
		
		// Acrescenta esta devolucao ao array para totalizacao por responsabilidade
		_nRespon = ascan (_aRespon, {|_aVal| _aVal [1] == (_sAliasQ) -> zx5_02resp })
		if _nRespon == 0
			do case
				case (_sAliasQ) -> zx5_02resp == "A"
					_wdescri = "Administrativo"
				case (_sAliasQ) -> zx5_02resp == "C"
					_wdescri = "Comercial"
				case (_sAliasQ) -> zx5_02resp == "I"
					_wdescri = "Industrial"
				otherwise	
					_wdescri = "Não identificado"					
			endcase
	        aadd (_aRespon, { (_sAliasQ) -> zx5_02resp, _wdescri, 0,0,0,0,0})
			_nRespon = len (_aRespon)
		endif
		_aRespon [_nRespon, 3] += (_sAliasQ) -> d1_total
		_aRespon [_nRespon, 4] += (_sAliasQ) -> d1_ICMSRET
		_aRespon [_nRespon, 5] += (_sAliasQ) -> d1_ValIPI
		_aRespon [_nRespon, 6] += (_sAliasQ) -> FreteCIF
		_aRespon [_nRespon, 7] += (_sAliasQ) -> TOTAL_FRETE
		(_sAliasQ) -> (dbskip ())
	enddo
	
	if mv_par17 == 2  // Detalhado
		if _aTotQuebra [1] > 0
			if li > _nMaxLin - 2
				cabec(titulo,cCabec1,cCabec2,wnrel,tamanho,nTipo)
			endif
			if ! u_zzuvl ('057', __cUserId, .F.)
				do case
					case mv_par16 == 1
						_sLinImp := "TOTAL VENDEDOR :" + "                         "
					case mv_par16 == 2 					
						_sLinImp := "TOTAL MOVIMENTO:" + "                         "
					case mv_par16 == 3									
						_sLinImp := "     TOTAL DATA:" + "                         "
				endcase
				_sLinImp += transform (_aTotQuebra [1], "@E 9,999,999.99") + " "
				_sLinImp += transform (_aTotQuebra [2], "@E 99,999.99") + " "
				_sLinImp += transform (_aTotQuebra [3], "@E 99,999.99") + "    "
				_sLinImp += transform (_aTotQuebra [4], "@E 99,999.99") + "   "
				_sLinImp += "            "
				_sLinImp += transform (_aTotQuebra [5], "@E 99,999.99") + "   "
				li += 1
				@ li, 60 psay _sLinImp
			endif
			li ++
			if mv_par17 == 2  // Detalhado
				@ li, 0 psay __PrtThinLine ()
				li += 2
			endif
		endif		
	
		// Imprime totais gerais
		if ! u_zzuvl ('057', __cUserId, .F.)
			if li > _nMaxLin - 2
				cabec(titulo,cCabec1,cCabec2,wnrel,tamanho,nTipo)
			endif
			_sLinImp := "T O T A L   G E R A L :                  "
			_sLinImp += transform (_aTotGer [1], "@E 9,999,999.99") + " "
			_sLinImp += transform (_aTotGer [2], "@E 99,999.99") + " "
			_sLinImp += transform (_aTotGer [3], "@E 99,999.99") + "    "
			_sLinImp += transform (_aTotGer [4], "@E 99,999.99") + "   "
			_sLinImp += "            "
			_sLinImp += transform (_aTotGer [5], "@E 99,999.99") + "   "
			li += 1	
			@ li, 60 psay _sLinImp
			li += 2
		endif			
	endif
	
	// Gera nova pagina com totais por motivo.
	if len (_aMotivos) > 0
		if ! u_zzuvl ('057', __cUserId, .F.)
			_aMotivos = asort (_aMotivos,,, {|_x, _y| _x [1] < _y [1]})
			if mv_par17 == 2  // Detalhado
				cabec(titulo,cCabec1,cCabec2,wnrel,tamanho,nTipo)
			endif			
			@ li, 0 psay "Totais por motivo de devolucao:"
			li += 2
			@ li, 0 psay "Motivo                                               Valor Produtos       Valor ST      Valor IPI    Frete CIF ref.Venda    Frete CIF ref. Devolucao"
			li ++
			@ li, 0 psay "---------------------------------------------------  --------------   ------------  -------------    -------------------    ------------------------"
			li ++
			_wtot3 :=0
			_wtot4 :=0
			_wtot5 :=0
			_wtot6 :=0
			_wtot7 :=0
			for _nMotivo = 1 to len (_aMotivos)
				if li > _nMaxLin - 2
					cabec(titulo,cCabec1,cCabec2,wnrel,tamanho,nTipo)
				endif
				@ li, 0 psay U_TamFixo (_aMotivos [_nMotivo, 1] + " - " + _aMotivos [_nMotivo, 2], 50) + "   " + ;
				             transform (_aMotivos [_nMotivo, 3], "@E 999,999,999.99") + " " + ;                     // valor dos produtos
				             transform (_aMotivos [_nMotivo, 4], "@E 999,999,999.99") + " " + ;                     // valor ST
				             transform (_aMotivos [_nMotivo, 5], "@E 999,999,999.99") + "         " + ;             // valor IPI
				             transform (_aMotivos [_nMotivo, 6], "@E 999,999,999.99") + "              " + ;        // frete referente a venda
				             transform (_aMotivos [_nMotivo, 7], "@E 999,999,999.99")                               // frete referente a devolucao
				li ++
				// totaliza motivos
				_wtot3 = _wtot3 + (_aMotivos [_nMotivo, 3])
				_wtot4 = _wtot4 + (_aMotivos [_nMotivo, 4])
				_wtot5 = _wtot5 + (_aMotivos [_nMotivo, 5])
				_wtot6 = _wtot6 + (_aMotivos [_nMotivo, 6])
				_wtot7 = _wtot7 + (_aMotivos [_nMotivo, 7])
			next
			@ li, 0 psay "---------------------------------------------------  --------------   ------------  -------------    -------------------    ------------------------"
			li ++
			@ li, 0 psay U_TamFixo ( "", 50) + "   " + ;
				         transform ( _wtot3, "@E 999,999,999.99") + " " + ;                     // total dos produtos
				         transform ( _wtot4, "@E 999,999,999.99") + " " + ;                     // total ST
				         transform ( _wtot5, "@E 999,999,999.99") + "         " + ;             // total IPI
				         transform ( _wtot6, "@E 999,999,999.99") + "              " + ;        // total frete referente a venda
				         transform ( _wtot7, "@E 999,999,999.99")                               // total frete referente a devolucao
			li ++
			li += 2
		endif			
	endif
		
	// Imprime resumo por responsabilidade
	if len (_aRespon) > 0
		if ! u_zzuvl ('057', __cUserId, .F.)
			_aRespon = asort (_aRespon,,, {|_x, _y| _x [1] < _y [1]})
			if li > _nMaxLin - 2
				cabec(titulo,cCabec1,cCabec2,wnrel,tamanho,nTipo)
			endif			
			@ li, 0 psay "Totais por área de responsabilidade"
			li += 2
			@ li, 0 psay "Area Responsavel                                     Valor Produtos       Valor ST      Valor IPI    Frete CIF ref.Venda    Frete CIF ref. Devolucao"
			li ++
			@ li, 0 psay "---------------------------------------------------  --------------   ------------  -------------    -------------------    ------------------------"
			li ++
			_wtot3 :=0
			_wtot4 :=0
			_wtot5 :=0
			_wtot6 :=0
			_wtot7 :=0
			for _nRespon = 1 to len (_aRespon)
				if li > _nMaxLin - 2
					cabec(titulo,cCabec1,cCabec2,wnrel,tamanho,nTipo)
				endif
				@ li, 0 psay U_TamFixo (_aRespon [_nRespon, 1] + " - " + _aRespon [_nRespon, 2], 50) + "   " + ;
				             transform (_aRespon [_nRespon, 3], "@E 999,999,999.99") + " " + ;                     // valor dos produtos
				             transform (_aRespon [_nRespon, 4], "@E 999,999,999.99") + " " + ;                     // valor ST
				             transform (_aRespon [_nRespon, 5], "@E 999,999,999.99") + "         " + ;             // valor IPI
				             transform (_aRespon [_nRespon, 6], "@E 999,999,999.99") + "              " + ;  // frete referente a venda
				             transform (_aRespon [_nRespon, 7], "@E 999,999,999.99")                               // frete referente a devolucao
				li ++
				// totaliza areas responsabilizade
				_wtot3 = _wtot3 + (_aRespon [_nRespon, 3])
				_wtot4 = _wtot4 + (_aRespon [_nRespon, 4])
				_wtot5 = _wtot5 + (_aRespon [_nRespon, 5])
				_wtot6 = _wtot6 + (_aRespon [_nRespon, 6])
				_wtot7 = _wtot7 + (_aRespon [_nRespon, 7])
			next
			@ li, 0 psay "---------------------------------------------------  --------------   ------------  -------------    -------------------    ------------------------"
			li ++
			@ li, 0 psay U_TamFixo ( "", 50) + "   " + ;
				         transform ( _wtot3, "@E 999,999,999.99") + " " + ;                     // total dos produtos
				         transform ( _wtot4, "@E 999,999,999.99") + " " + ;                     // total ST
				         transform ( _wtot5, "@E 999,999,999.99") + "         " + ;             // total IPI
				         transform ( _wtot6, "@E 999,999,999.99") + "              " + ;        // total frete referente a venda
				         transform ( _wtot7, "@E 999,999,999.99")                               // total frete referente a devolucao
			li ++
			li += 2
		endif
	endif

	// Imprime parametros usados na geracao do relatorio
	U_ImpParam (_nMaxLin)
return _aMotivos
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3       Opcoes                         Help
	aadd (_aRegsPerg, {01, "Filial inicial                 ?", "C", 2,  0,  "",   "SM0",   {},							  ""})
	aadd (_aRegsPerg, {02, "Filial final                   ?", "C", 2,  0,  "",   "SM0",   {},    						  ""})
	aadd (_aRegsPerg, {03, "Vendedor de                    ?", "C", 4,  0,  "",   "SA3",   {},                            ""})
	aadd (_aRegsPerg, {04, "Vendedor até                   ?", "C", 4,  0,  "",   "SA3",   {},                            ""})
	aadd (_aRegsPerg, {05, "Data devolução de              ?", "D", 8,  0,  "",   "   ",   {},                            ""})
	aadd (_aRegsPerg, {06, "Data devolução até             ?", "D", 8,  0,  "",   "   ",   {},                            ""})
	aadd (_aRegsPerg, {07, "Motivo devolução de            ?", "C", 6,  0,  "",   "ZX502", {},                            ""})
	aadd (_aRegsPerg, {08, "Motivo devolução até           ?", "C", 6,  0,  "",   "ZX502", {},                            ""})
	aadd (_aRegsPerg, {09, "Motivos c/movimento financeiro ?", "N", 1,  0,  "",   "   ",   {"Sim", "Nao", "Todos"},       "Indique se deseja listar motivos de devolucao que implicam valores financeiros."})
	aadd (_aRegsPerg, {10, "Cliente de                     ?", "C", 6,  0,  "",   "SA1",   {},                            ""})
	aadd (_aRegsPerg, {11, "Loja cliente de                ?", "C", 2,  0,  "",   "   ",   {},                            ""})
	aadd (_aRegsPerg, {12, "Cliente até                    ?", "C", 6,  0,  "",   "SA1",   {},                            ""})
	aadd (_aRegsPerg, {13, "Loja cliente até               ?", "C", 2,  0,  "",   "   ",   {},                            ""})
	aadd (_aRegsPerg, {14, "Produto de                     ?", "C", 15, 0,  "",   "SB1",   {},                            "Produto inicial a ser considerado."})
	aadd (_aRegsPerg, {15, "Produto até                    ?", "C", 15, 0,  "",   "SB1",   {},                            "Produto final a ser considerado."})
	aadd (_aRegsPerg, {16, "Ordenação Relatorio            ?", "N", 1,  0,  "",   "   ",   {"Vendedor", "Motivo","Data"}, "Indique a ordenação desejada no relatório."})
	aadd (_aRegsPerg, {17, "Lista apenas Resumo            ?", "N", 1,  0,  "",   "   ",   {"Sim", "Nao"},                "Indique se deseja listar apenas o resumo por motivos de devolução"})
	aadd (_aRegsPerg, {18, "Gerente comercial de           ?", "C", 6,  0,  "",   "80 ",   {},                            "Gerente de vendas inicial a ser considerado"})
	aadd (_aRegsPerg, {19, "Gerente comercial até          ?", "C", 6,  0,  "",   "80 ",   {},                            "Gerente de vendas final a ser considerado"})
	aadd (_aRegsPerg, {20, "Cons ret simból(entre filiais) ?", "N", 1,  0,  "",   "   ",   {"Sim", "Nao"},                "Indique se deseja que os retornos simbólicos das filiais sejam impressos."})
    aadd (_aRegsPerg, {21, "Gera em Planilha               ?", "N", 1,  0,  "",   "   ",   {"Sim", "Nao"},                "Indique se deseja gerar em planilha."})
    aadd (_aRegsPerg, {22, "Area de Responsabilidade       ?", "N", 1,  0,  "",   "   ",   {"Todas", "Administrativo","Comercial","Industrial"}, "Indique a área de responsabilidade desejada."})
	aadd (_aDefaults, {"14", 1})
	aadd (_aDefaults, {"14", 2})
	aadd (_aDefaults, {"16", ''})
	aadd (_aDefaults, {"17", 'z'})
	aadd (_aDefaults, {"18", 2})
	aadd (_aDefaults, {"19", 2})
	aadd (_aDefaults, {"19", 1})
	
	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
Return
