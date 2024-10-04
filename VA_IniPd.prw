// Programa..: VA_IniPd
// Autor.....: Robert Koch
// Data......: 24/02/2009
// Cliente...: Alianca
// Descricao.: Inicializadores padrao genericos (para campos diversos do sistema,
//            onde nao cabe tudo no X3_RELACAO ou X3_INIBRW, por exemplo).
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #validacao_de_campo
// #Descricao         #Inicializadores padrao genericos
// #PalavasChave      #validacao #inicializador #padrao
// #TabelasPrincipais #
// #Modulos           #TODOS
//
// Historico de alteracoes:
// 27/03/2009 - Robert  - Criado inicializador para o campo ZZ7_SEQ
// 19/05/2009 - Robert  - Criado inicializador para o campo ZX5_CHAVE
// 14/10/2009 - Robert  - Criado inicializador para o campo C5_VAEST
//                      - Compatibilizacao com DBF para uso em Livramento.
//                      - Atualiza nome e estado do cliente quando efetivacao de pre-pedidos.
// 18/01/2010 - Robert  - Criado inicializador para o campo ZE_CARGA.
// 14/10/2010 - Robert  - Criados inicializadores para os campos 'Coop. origem' de diversas tabelas.
// 15/10/2010 - Robert  - Criado inicializador para o campo C5_VATOTST.
// 11/11/2010 - Robert  - Novos usuarios para campos de 'coop.origem'.
// 24/01/2011 - Robert  - Ajustes p/ campos *_VACORIG e ZE_SAFRA.
// 01/03/2011 - Robert  - Criado inicializador para o campo ZI_DESCMOV.
// 29/05/2011 - Robert  - Criado inicializador para o campo ZZX_NOME.
// 04/01/2012 - Robert  - Criado inicializador para o campo CR_VANUSER e CR_VANFORN.
// 21/02/2012 - Robert  - Nao usa mais a funcao PswSeek para buscar nomes no inicializador do campo CR_VANUSER.
// 28/05/2012 - Robert  - Tratamentos para campos do SCR quando A.E. e nao somente P.C.
// 01/10/2012 - Robert  - Inicializador do ZZ7_SEQ passa a considerar registros deletados.
// 02/08/2014 - Robert  - Inicializador para o campo C5_VASTAT.
// 13/08/2014 - Catia   - Tratamento para buscar descricao do SX5 de um campo virtual
// 21/11/2014 - Robert  - Criato tratamento para campo DB_VASLDLO.
// 14/08/2015 - Robert  - Melhorado retorno para coluna C5_VASTAT (lib coml, NF gerada)
// 12/09/2015 - Robert  - Removidos tratamentos (jah desabilitados) de ST customizada.
// 29/09/2015 - Robert  - Incluido Rafael na lista de nomes de compradores.
// 09/10/2015 - Robert  - Tratamento para o campo DAK_VASTFU
// 15/10/2015 - Robert  - Campo C5_VASTAT passa a ser gerado com base na funcao VA_FSTATUS_PED_VENDA do SQL.
// 26/10/2015 - Catia   - Campo ZZX_NOME - quando era CTE estava buscando o nome de um cliente e nao de um fornecedor
// 20/11/2015 - Robert  - Inicializador para o campo ZZ6_PREX.
// 23/07/2016 - Robert  - Campo ZAF_ENSAIO.
// 28/02/2017 - Robert  - Campo ZAG_SEQ.
// 09/03/2017 - Robert  - Inic.padrao campo C5_NUM (soh enquanto estiver tendo problema com a funcao GetSX8Num)
// 13/12/2017 - Robert  - Tratamento para o campo Z9_SEQ.
// 13/09/2018 - Andre   - Tratamento para o campo C7_CODPRF
// 15/01/2019 - Andre   - Tratamento para o campo CR_DATAMIN
// 20/05/2019 - Andre   - Tratamento para gatilho na tela de retorno no campo Nome do C5_NOMECLI
// 19/09/2019 - Robert  - Sugere CC cfe.grupo do usuario no campo D3_CC
// 25/09/2019 - Andre   - Adicionado codigos do Joel e Marcus no inicializador padrão.
// 10/12/2019 - Robert  - Desabilitado tratamento para o D3_CC
// 29/09/2020 - Cláudia - Incluido o novo usuário do alexandre na validação de liberação de doc. GLPI: 8369
// 22/08/2022 - Robert  - Criado inicializador de browse para o campo ZI_VENCTO (GLPI 12503)
// 27/06/2023 - Claudia - Incluido o usuario Franciele. GLPI 13786
// 26/02/2024 - Robert  - Chamadas de metodos de ClsSQL() nao recebiam parametros.
// 02/10/2024 - Sandra  - Incluso nome Franciele Borges
//

// -------------------------------------------------------------------------------------------------------
user function VA_IniPd (_sCampo, _lBrowse)
	local _xRet     := NIL
	local _sQuery   := ""
	local _aAreaSX3 := {}
	local _nLinha   := 0
	//local _n        := 0
	local _sUser    := ""
	local _oSQL     := NIL
	//local _aRetSQL  := {}
	//local _nPercSep := 0
	//local _aGrupos  := {}

	do case
		case _sCampo == "C5_NOMECLI"
			if _lBrowse
				if sc5->c5_tipo $ "BD"
					_xRet = fbuscacpo("SA2",1,xFilial("SA2")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A2_NOME")
				else
					_xRet = fbuscacpo("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NOME")
				endif
			else
				if IsInCallStack ("MATA416")  // Efetivacao de pre-pedido
					_xRet = fbuscacpo("SA1",1,xFilial("SA1")+SCJ->CJ_CLIENTE+SCJ->CJ_LOJA,"A1_NOME")
				else
					if inclui
						if IsInCallStack ("A410ProcDv") 
							if m->c5_tipo $ "BD"
								_xRet = fbuscacpo("SA2",1,xFilial("SA2")+M->C5_CLIENTE+M->C5_LOJACLI,"A2_NOME")
							else
								_xRet = fbuscacpo("SA1",1,xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"A1_NOME")
							endif
						else
							_xRet = ""
						endif
					else
						if m->c5_tipo $ "BD"
							_xRet = fbuscacpo("SA2",1,xFilial("SA2")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A2_NOME")
						else
							_xRet = fbuscacpo("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NOME")
						endif
					endif
				endif
			endif
		
		
		case _sCampo == "C5_VEND1"
			if _lBrowse
				if ! sc5->c5_tipo $ "BD"
					_xRet = fbuscacpo("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_VEND")
				else
					_xRet = '001'
				endif
			else
				if IsInCallStack ("MATA416")  // Efetivacao de pre-pedido
					_xRet = fbuscacpo("SA1",1,xFilial("SA1")+SCJ->CJ_CLIENTE+SCJ->CJ_LOJA,"A1_VEND")
				else
					if inclui
						if IsInCallStack ("A410ProcDv")
							if ! m->c5_tipo $ "BD"
								_xRet = fbuscacpo("SA1",1,xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"A1_VEND")
							else
								_xRet = '001'
							endif
						else
							_xRet = IIF(TYPE("_SCODREP")=="C", _SCODREP, "")
						endif
//					else
//						u_log ('nao estou no incluir')
					//	if ! m->c5_tipo $ "BD"
					//		_xRet = fbuscacpo("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_VEND")
					//	else
					//		_xRet = '001'
					//	endif
					endif
				endif
			endif

		case _sCampo == "C5_NUM"
			_xRet = ""
			if ! _lBrowse
				_xRet = GetMv ("VA_INIC5NU")
				PutMv ("VA_INIC5NU", soma1 (_xRet))
			endif



		case _sCampo == "C5_VAEST"
			_xRet = ""  // Deixa pronto para retorno caso nao encontre nada.
			if _lBrowse
				if sc5->c5_tipo $ "BD"
					_xRet = fbuscacpo("SA2",1,xFilial("SA2")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A2_EST")
				else
					_xRet = fbuscacpo("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_EST")
				endif
			else
				if IsInCallStack ("MATA416")  // Efetivacao de pre-pedido
					_xRet = fbuscacpo("SA1",1,xFilial("SA1")+SCJ->CJ_CLIENTE+SCJ->CJ_LOJA,"A1_EST")
				else
					if inclui
						_xRet = ""
					else
						if m->c5_tipo $ "BD"
							_xRet = fbuscacpo("SA2",1,xFilial("SA2")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A2_EST")
						else
							_xRet = fbuscacpo("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_EST")
						endif
					endif
				endif
			endif


		case _sCampo == "C5_VASTAT"
			_xRet = ""  // Deixa pronto para retorno caso nao encontre nada.
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := "SELECT dbo.VA_FSTATUS_PED_VENDA ('" + sc5 -> c5_filial + "','" + sc5 -> c5_num + "')"
			_xRet = _oSQL:RetQry (1, .f.)


		case _sCampo == "CR_VANFORN"
			_xRet = ""
			if _lBrowse
				if scr -> cr_tipo $ "PC/AE"
					_sQuery := ""
					_sQuery += " SELECT A2_NOME "
					_sQuery +=   " FROM " + RetSQLName ("SA2") + " SA2, "
					_sQuery +=              RetSQLName ("SC7") + " SC7 "
					_sQuery +=  " where SA2.D_E_L_E_T_ = ''"
					_sQuery +=    " and SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
					_sQuery +=    " and SA2.A2_COD     = SC7.C7_FORNECE"
					_sQuery +=    " and SA2.A2_LOJA    = SC7.C7_LOJA"
					_sQuery +=    " and SC7.D_E_L_E_T_ = ''"
					_sQuery +=    " and SC7.C7_FILIAL  = '" + scr -> cr_filial + "'"
					_sQuery +=    " and SC7.C7_NUM     = '" + left (scr -> cr_num, 7) + "'"
					_xRet = U_RetSQL (_sQuery)
				endif
			endif
			
		case _sCampo == "CR_DATAMIN"
			_xRet = ""
			_sQuery := "" 
			_sQuery += " SELECT MIN(C7_DATPRF)"
			_sQuery += "	FROM " + RetSQLName ("SC7") + " SC7, "     
			_sQuery += 		 		 RetSQLName ("SCR") + " SCR "
			_sQuery += " WHERE SCR.D_E_L_E_T_ = ''"
			_sQuery += " AND SCR.CR_FILIAL = '" + sc7 -> c7_filial + "'"
			_sQuery += " AND SCR.CR_NUM = '" + sc7 -> c7_num + "'"
			_sQuery += " AND SC7.C7_FILIAL = SCR.CR_FILIAL "
			_sQuery += " AND SC7.C7_NUM = SCR.CR_NUM "
			_xRet = U_RetSQL (_sQuery)


		case _sCampo == "CR_VANUSER"
			_xRet = ""
			if _lBrowse		
				if scr -> cr_tipo $ "PC/AE"
					// Desisti de usar a funcao PswSeek por que estava muito demorada.
					_sUser = fBuscaCpo ("SC7", 1, scr -> cr_filial + left (scr -> cr_num, 6), "C7_USER")
					do case
						case _sUser == '000671'
							_xRet = 'Alexandre'
						case _sUser == '000118'
							_xRet = 'Gilmar'
						case _sUser == '000111'
							_xRet = 'Anderson'
						case _sUser == '000093'
							_xRet = 'Fernando Matana'
						case _sUser == '000090'
							_xRet = 'Mateus'
						case _sUser == '000069'
							_xRet = 'Thais'
						case _sUser $ '000067/000210'
							_xRet = 'Robert'
						case _sUser == '000215'
							_xRet = 'Carine'
						case _sUser == '000360'
							_xRet = 'Leandro Siqueira'
						case _sUser == '000371'
							_xRet = 'Debora'
						case _sUser == '000376'
							_xRet = 'Rafael'
						case _sUser == '000543'
							_xRet = 'Joel'
						case _sUser == '000456'
							_xRet = 'Marcos'
						case _sUser == '000822'
							_xRet = 'Franciele'
						case _sUser == '000896'
							_xRet = 'Franciele Borges'	
						otherwise
							_xRet = '' //_sUser + "(ajustar prog." + procname () + ")"
					endcase
				endif
			endif

/*
	case _sCampo == "D3_CC"
		_xRet = ''
		if ! _lBrowse .and. IsInCallStack ("MATA241")  // Inicialmente a intencao eh usar apenas esta tela para baixas de estoque
			// Sugere CC conforme o setor em que o usuario encontra-se alocado.
			_aGrupos = aclone (UsrRetGrp (__cUserId))
			do case
				case ascan (_aGrupos, '000054') > 0  // Qualidade
					_xRet = cFilAnt + '2004'
				case ascan (_aGrupos, '000052') > 0  // Logistica
					_xRet = cFilAnt + '4004'
				case ascan (_aGrupos, '000068') > 0 .or. ascan (_aGrupos, '000013') > 0  // Retaguarda/lojas
					_xRet = cFilAnt + '4003'
				case ascan (_aGrupos, '000001') > 0  // Comercial
					_xRet = cFilAnt + '4001'
				otherwise
					_xRet = cFilAnt + '3002'  // Administrativo
			endcase
		endif
*/


		case _sCampo == "DAK_VASTFU"
			_xRet = ""
			if _lBrowse
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " select isnull (case min (status) "
				_oSQL:_sQuery +=                " when '1' then '1-IMPORTADA'"
				_oSQL:_sQuery +=                " when '2' then '2-ONDA GERADA'"
				_oSQL:_sQuery +=                " when '3' then '3-EM SEPARACAO'"
				_oSQL:_sQuery +=                " when '4' then '4-SEPAR.ENCERRADA'"
				_oSQL:_sQuery +=                " when '5' then '5-CONFERENCIA'"
				_oSQL:_sQuery +=                " when '6' then '6-ENCERRADA'"
				_oSQL:_sQuery +=                " when '9' then '9-EXCLUIDA'"
				_oSQL:_sQuery +=                " else '' end"
				_oSQL:_sQuery +=         ", '')"
				_oSQL:_sQuery +=   " from tb_wms_pedidos"
				_oSQL:_sQuery +=  " where saida_id like 'DAK" + dak -> dak_filial + dak -> dak_cod + "%'"
				//_oSQL:Log ()
				_xRet = U_RetSQL (_oSQL:_sQuery)
			endif



		case _sCampo == "DB_VASLDLO"
			_xRet = 0
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT SUM (BF_QUANT - BF_EMPENHO)"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SBF") + " SBF "
			_oSQL:_sQuery += " WHERE SBF.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND BF_FILIAL  = '" + xfilial ("SBF") + "'"
			_oSQL:_sQuery +=   " AND BF_LOCAL   = '" + sdb -> db_local + "'"
			_oSQL:_sQuery +=   " AND BF_LOCALIZ = '" + sdb -> db_localiz + "'"
			_oSQL:_sQuery +=   " AND BF_PRODUTO = '" + sdb -> db_produto + "'"
			_oSQL:_sQuery +=   " AND BF_LOTECTL = '" + sdb -> db_lotectl + "'"
			//U_LOG (_oSQL:_sQuery)
			_xRet = _oSQL:RetQry (1, .F.)



		case _sCampo == "Z9_SEQ"
			_xRet = "000"
			for _nLinha = 1 to len (aCols) - 1
				if GDFieldGet ("Z9_SEQ", _nLinha) > _xRet
					_xRet = GDFieldGet ("Z9_SEQ", _nLinha)
				endif
			next
			_xRet = soma1 (_xRet)



		case _sCampo == "ZAF_ENSAIO"
			_xRet = ''
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT ISNULL (MAX (ZAF_ENSAIO), '" + replicate ('0', tamsx3 ("ZAF_ENSAIO")[2]) + "')"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("ZAF") + " ZAF "
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"  // Nao inclui a FILIAL por que quero numeracao distinta para toda a empresa.
			//_oSQL:Log ()
			_xRet = Soma1 (_oSQL:RetQry (1, .F.))



		case _sCampo == "ZF_ITEM"
			_xRet = ""
			if type ("N") == "N" .and. N > 1
				_xRet = GDFieldGet ("ZF_ITEM", N - 1)
			else
				_xRet = "00"
			endif
			_xRet = soma1 (_xRet)



		case _sCampo == "ZI_DESCMOV"
			_xRet = ""
			_sQuery := ""
			_sQuery += " select ZX5_10DESC"
			_sQuery += "   from " + RetSQLName ("ZX5")
			_sQuery += "  where D_E_L_E_T_ = ''"
			_sQuery += "    and ZX5_FILIAL = (SELECT CASE ZX5_MODO WHEN 'C' THEN '  ' ELSE '" + cFilAnt + "' END"
			_sQuery +=                        " FROM " + RetSQLName ("ZX5")
			_sQuery +=                       " WHERE D_E_L_E_T_ = ''"
			_sQuery +=                         " AND ZX5_FILIAL = '  '"
			_sQuery +=                         " AND ZX5_TABELA = '00'"
			_sQuery +=                         " AND ZX5_CHAVE  = '10')"
			_sQuery += "    and ZX5_TABELA = '10'"
			_sQuery += "    and ZX5_10COD  = '" + szi -> zi_tm + "'"
			_xRet = U_RetSQL (_sQuery)


		case _sCampo == "ZI_VENCTO"
			if _lBrowse
				_xRet = POSICIONE("SE2",6,ZI_FILIAL+zi_assoc+zi_lojasso+ZI_SERIE+ZI_DOC+ZI_PARCELA,"E2_VENCTO")
			else
				_xRet = ctod ('')
			endif


		case _sCampo == "ZX5_CHAVE"
			_xRet = "00"
			for _nLinha = 1 to len (aCols) - 1
				if GDFieldGet ("ZX5_CHAVE", _nLinha) > _xRet
					_xRet = GDFieldGet ("ZX5_CHAVE", _nLinha)
				endif
			next
			_xRet = soma1 (_xRet)



		case _sCampo == "ZZ6_PREX"
			if len (alltrim (zz6 -> zz6_fildes)) == 2
				_xRet = U_RetSQL ("SELECT CONVERT(varchar(23), dbo.VA_FPROX_EXEC_BATCH (" + cvaltochar (zz6 -> (recno ())) + ",'" + zz6 -> zz6_empdes + "','" + zz6 -> zz6_fildes + "'), 121)")
			else
				_xRet = U_RetSQL ("SELECT CONVERT(varchar(23), dbo.VA_FPROX_EXEC_BATCH (" + cvaltochar (zz6 -> (recno ())) + ",'" + zz6 -> zz6_empdes + "','" + cFilAnt + "'), 121)")
			endif



		case _sCampo == "ZZ7_SEQ"
			if type ("_sContato") == "C"
				_sQuery := ""
				_sQuery += " select max (ZZ7_SEQ)"
				_sQuery +=   " from " + RetSQLName ("ZZ7") + " ZZ7 "
				_sQuery +=  " where ZZ7.ZZ7_FILIAL = '" + xfilial ("ZZ7") + "'"
				//Preciso considerar os deletados. --> _sQuery +=    " and ZZ7.D_E_L_E_T_ = ''"
				_sQuery +=    " and ZZ7.ZZ7_CONTAT = '" + _sContato + "'"
				_sQuery +=    " and ZZ7.ZZ7_DATA   = '" + dtos (CriaVar ("ZZ7_DATA")) + "'"
				_xRet = U_RetSQL (_sQuery)
				if empty (_xRet)
					_xRet = strzero (0, tamsx3 ("ZZ7_SEQ")[1])
				endif
				_xRet = Soma1 (_xRet)
			endif



		case _sCampo == "ZZP_SEQ"
			_xRet = ""
			if type ("N") == "N" .and. N > 1
				_xRet = GDFieldGet ("ZF_ITEM", N - 1)
			else
				_xRet = replicate ("0", tamsx3 ("ZZP_SEQ") [1])
			endif
			_xRet = soma1 (_xRet)

		case _sCampo == "ZA9_CODSEG"
			_xRet = fbuscacpo ("SA1", 1, xFilial ("SA1")+ m->za9_cli   , "A1_SATIV1")
			_xRet = fbuscacpo ("SX5", 1 , xFilial("SX5")+ "T3" + _xRet , "X5_DESCRI")                                                                 

		case _sCampo == "ZZX_NOME"
			if _lBrowse
				if (zzx -> zzx_tiponf= "N" .or. zzx-> zzx_layout = "procCTe")
					_xRet = fbuscacpo ("SA2", 1, xFilial ("SA2")+ zzx -> zzx_clifor + zzx -> zzx_loja, "A2_NOME")
				else
					_xRet = fbuscacpo ("SA1", 1, xFilial ("SA1")+ zzx -> zzx_clifor + zzx -> zzx_loja, "A1_NOME")
				endif
			else
				if (zzx -> zzx_tiponf= "N" .or. zzx-> zzx_layout = "procCTe")
					_xRet = fbuscacpo ("SA2", 1, xFilial ("SA2")+ m->zzx_clifor + m->zzx_loja, "A2_NOME")
				else
					_xRet = fbuscacpo ("SA1", 1, xFilial ("SA1")+ m->zzx_clifor + m->zzx_loja, "A1_NOME")
				endif
			endif

		case _sCampo = "C7_CODPRF"
			_xRet = ''
			if funname() == 'MATA121'
				if _lBrowse
					_xRet = fbuscacpo ("SA5",1,XFILIAL("SA5")+SC7->C7_FORNECE+SC7->C7_LOJA+SC7->C7_PRODUTO,"A5_CODPRF")
				else
					IF(INCLUI,"",POSICIONE("SA5",1,XFILIAL("SA5")+SC7->C7_FORNECE+SC7->C7_LOJA+SC7->C7_PRODUTO,"A5_CODPRF"))
				endif
			endif
			
		case _sCampo = "C1_CODPRF"
			_xRet = fbuscacpo ("SA5",1,XFILIAL("SA5")+SC1->C1_FORNECE+SC1->C1_LOJA+SC1->C1_PRODUTO,"A5_CODPRF")

		case _sCampo = "ZAX_VABARA"
		    _sVABARA = POSICIONE("SA1",1,XFILIAL("ZAX")+ZAX->ZAX_CLIENT+ZAX->ZAX_LOJA,"A1_VABARAP")                                     
		    Do Case 
				Case Alltrim(_sVABARA) == '0'
					_xRet = 'Não' 
				Case Alltrim(_sVABARA) == '1'
					_xRet = 'Base Nota'
				Case Alltrim(_sVABARA) == '2'
					_xRet = 'Base Mercadoria' 
				Case Alltrim(_sVABARA) == '3'
					_xRet = 'Total NF - ST' 		 	
			endcase   


		otherwise

			// Se a chamada foi feita para um campo nao previsto, verifica o seu tipo e retorna
			// dados vazios de acordo com o tipo do campo.
			//nao vale a pena... U_AvisaTI ("Campo '" + _sCampo + "' nao previsto na rotina " + procname ())
			_aAreaSX3 = sx3 -> (getarea ())
			sx3 -> (dbsetorder (2))
			if sx3 -> (dbseek (_sCampo, .F.))
				do case
					case sx3 -> x3_tipo $ "CM"
						_xRet = ""
					case sx3 -> x3_tipo == "N"
						_xRet = 0
					case sx3 -> x3_tipo == "D"
						_xRet = ctod ("")
					case sx3 -> x3_tipo == "L"
						_xRet = .F.
				endcase
			endif
			sx3 -> (restarea (_aAreaSX3))

	endcase
return _xRet

