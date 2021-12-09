// Programa:  SimulCTB
// Autor:     Robert Koch
// Data:      22/09/2016
// Descricao: Simula a execucao de lancamentos padronizados para ver como vai ficar a contabilizacao.
//
// Historico de alteracoes:
// 01/12/2016 - Robert -
// 08/12/2021 - Robert - Ajustes contabilizacoes SD1
//

// --------------------------------------------------------------------------
user function SimulCtb (_lAuto)
	private cPerg := "SIMULCTB"

	_ValidPerg ()
	if _lAuto
		Pergunte (cPerg, .F.)
		processa ({|| _FujaLouco ()})
	else
		if Pergunte (cPerg, .T.)
			processa ({|| _FujaLouco ()})
		endif
	endif
return



// --------------------------------------------------------------------------
static function _FujaLouco ()
	local _oSQL      := NIL
	local _aRegMovto := {}
	local _nRegMovto := 0
	local _nTabMovto := 0
	local _sTabMovto := ""
	local _aRegCT5   := {}
	local _nRegCT5   := 0
	local _lContinua := .T.
	local _nLcto     := 0
	local _nPar12    := 0
	private mv_par12 := 1
	private _aLctos    := {}

	U_LOGSX1 ()
	procregua (10)
	
	// Cria tabela para resultados. HABILITAR SOMENTE SE ALTERAR A DEFINICAO DA TABELA.
/*
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "IF OBJECT_ID ('dbo.VA_SIMUL_LCTOS') IS NOT NULL DROP TABLE dbo.VA_SIMUL_LCTOS"
	_oSQL:Log ()
	if _oSQL:Exec()
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " CREATE TABLE VA_SIMUL_LCTOS ("
		_oSQL:_sQuery += " DHGERACAO datetime     not null default GetDate(),"
		_oSQL:_sQuery += " TABELA    varchar (3)  not null default '',"
		_oSQL:_sQuery += " RECNO     INT          not null default 0,"
		_oSQL:_sQuery += " LPAD      varchar (3)  not null default '',"
		_oSQL:_sQuery += " SEQ       varchar (3)  not null default '',"
		_oSQL:_sQuery += " VALOR     FLOAT        not null default 0,"
		_oSQL:_sQuery += " CTADEB    varchar (20) not null default '',"
		_oSQL:_sQuery += " CTACRED   varchar (20) not null default '',"
		_oSQL:_sQuery += " CCD       varchar (9)  not null default '',"
		_oSQL:_sQuery += " CCC       varchar (9)  not null default '',"
		_oSQL:_sQuery += " HIST      varchar (" + cvaltochar (_nTamHist) + ") not null default '',"
		_oSQL:_sQuery += " M330PAR12 varchar (1)  not null default '',"
		_oSQL:_sQuery += " CLVLDB    varchar (9)  not null default '',"
		_oSQL:_sQuery += " CLVLCR    varchar (9)  not null default ''"
		_oSQL:_sQuery += ")"
		_oSQL:Log ()
		_lContinua = _oSQL:Exec ()
	endif
*/

	for _nTabMovto = 1 to 3
		u_log2 ('info', '_nTabMovto: ' + cvaltochar (_nTabMovto) + ' _lContinua: ' + cvaltochar (_lContinua))
		if ! _lContinua
			u_help ('Abortando no inicio da tabela de movtos',, .t.)
			exit
		endif
		_sTabMovto = {'SD1','SD2','SD3'}[_nTabMovto]
		if ! _sTabMovto $ mv_par04
			U_Log2 ('aviso', 'Tabela ' + _sTabMovto + ' nao vai ser lida, pois nao consta nos parametros.')
			loop
		endif
		u_log2 ('info', 'Iniciando tabela ' + _sTabMovto)

		// Monta lista dos registros da tabela de movimentos a serem verificados
		incproc ('Buscando movimentos...')
		_oSQL := ClsSQL ():New ()
		do case
		case _sTabMovto == 'SD1'
			_oSQL:_sQuery := "SELECT R_E_C_N_O_"
			_oSQL:_sQuery +=  " FROM " + RetSQLName (_sTabMovto)
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND D1_FILIAL  = '" + xfilial ("SD1") + "'"
			_oSQL:_sQuery +=   " AND D1_DTDIGIT BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_oSQL:_sQuery += " ORDER BY D1_FILIAL, D1_DTDIGIT, D1_NUMSEQ"
		case _sTabMovto == 'SD2'
			_oSQL:_sQuery := "SELECT R_E_C_N_O_"
			_oSQL:_sQuery +=  " FROM " + RetSQLName (_sTabMovto)
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND D2_FILIAL  = '" + xfilial ("SD2") + "'"
			_oSQL:_sQuery +=   " AND D2_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_oSQL:_sQuery += " ORDER BY D2_FILIAL, D2_EMISSAO, D2_NUMSEQ"
		case _sTabMovto == 'SD3'
			_oSQL:_sQuery := "SELECT R_E_C_N_O_"
			_oSQL:_sQuery +=  " FROM " + RetSQLName (_sTabMovto)
			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND D3_FILIAL  = '" + xfilial ("SD3") + "'"
			_oSQL:_sQuery +=   " AND D3_EMISSAO BETWEEN '" + dtos (mv_par01) + "' AND '" + dtos (mv_par02) + "'"
			_oSQL:_sQuery +=   " AND D3_ESTORNO != 'S'"
			_oSQL:_sQuery += " ORDER BY D3_FILIAL, D3_EMISSAO, D3_NUMSEQ"
		endcase
		_oSQL:Log ()
		_aRegMovto = aclone (_oSQL:Qry2Array ())
		u_log2 ('info', 'qt.reg.movto: ' + cvaltochar (len (_aRegMovto)))
	
		// Remove registros anteriores
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "DELETE VA_SIMUL_LCTOS"
		_oSQL:_sQuery += " WHERE TABELA = '" + _sTabMovto + "'"
		_oSQL:Log ()
		if ! _oSQL:Exec ()
			u_help ('Erro na limpeza de movtos anteriores.',, .t.)
			_lContinua = .F.
		endif
	
	
		// Monta lista dos lancamentos padrao que podem interessar.
		incproc ('Buscando lctos padrao...')
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT R_E_C_N_O_"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ('CT5')
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND CT5_FILIAL = '" + xfilial ("CT5") + "'"
		_oSQL:_sQuery +=   " AND CT5_STATUS = '1'"  // Ativo
		if ! empty (mv_par03)
			_oSQL:_sQuery +=   " AND CT5_LANPAD in " + FormatIn (alltrim (mv_par03), '/')
		endif
		do case
		case _sTabMovto == 'SD1'
			_oSQL:_sQuery +=   " AND CT5_VLR01 LIKE '%D1$_%' ESCAPE '$'"
		case _sTabMovto == 'SD2'
			_oSQL:_sQuery +=   " AND CT5_VLR01 LIKE '%D2$_%' ESCAPE '$'"
		case _sTabMovto == 'SD3'
			_oSQL:_sQuery +=   " AND CT5_VLR01 LIKE '%D3$_%' ESCAPE '$'"
		otherwise
			u_help ("Tabela '" + _sTabMovto + "' sem tratamento na leitura do CT5",, .t.)
			_lContinua = .F.
		endcase
		_oSQL:_sQuery += " ORDER BY CT5_LANPAD, CT5_SEQUEN"
		_oSQL:Log ()
		_aRegCT5 = aclone (_oSQL:Qry2Array ())
		//u_log2 ('debug', 'Registros CT5:')
		//u_log2 ('debug', _aRegCT5)

		// Varre o arquivo de movimentos e tenta executar as contabilizacoes.
		sf4 -> (dbsetorder (1))
		sde -> (dbsetorder (1))  // DE_FILIAL, DE_DOC, DE_SERIE, DE_FORNECE, DE_LOJA, DE_ITEMNF, DE_ITEM, R_E_C_N_O_, D_E_L_E_T_
		procregua (len (_aRegMovto))
		for _nRegMovto = 1 to len (_aRegMovto)
			if ! _lContinua
				u_help ("Abortando no inicio da leitura dos movtos.",, .t.)
				exit
			endif
			incproc ()
			
			// Posiciona no registro de movimento a ser contabilizado.
			U_Log2 ('info', 'Posicionando ' + _sTabMovto + ' no recno ' + cvaltochar (_aRegMovto [_nRegMovto, 1]))
			(_sTabMovto) -> (dbgoto (_aRegMovto [_nRegMovto, 1]))
			
			// Deixa arquivos adicionais posicionados para o caso do LPAD precisar.
			if _sTabMovto == 'SD1'
				sf4 -> (dbseek (xfilial ("SF4") + sd1 -> d1_tes, .F.))
			elseif _sTabMovto == 'SD2'
				sf4 -> (dbseek (xfilial ("SF4") + sd2 -> d2_tes, .F.))
			endif

			// Tenta gerar lctos para este movimento.
			_aLctos = {}
			//
			// Varre todos os lpad que fazem referencia a esta tabela de movtos.
			for _nRegCT5 = 1 to len (_aRegCT5)
				ct5 -> (dbgoto (_aRegCT5 [_nRegCT5, 1]))

				if _sTabMovto == 'SD1' .and. ct5 -> ct5_lanpad == '640' .and. ! sd1 -> d1_tipo $ 'D/B'  // Este LPAD roda apenas para devolucoes
					//U_Log2 ('info', "LPAD '" + ct5 -> ct5_lanpad + "' aplica-se para NF de entrada somente quando utiliza cliente.")
					loop
				endif
				if left (ct5 -> ct5_moedas, 1) != '1'
					U_Log2 ('aviso', "LPAD '" + ct5 -> ct5_lanpad + "' nao configurado para gerar valor na moeda 1.")
					loop
				endif

				for _nPar12 = 1 to iif ('MV_PAR12' $ upper (ct5 -> ct5_vlr01), 3, 1)
					
					// Deixa a variavel pronta para ser interpretada pela regra do lcto padrao.
					mv_par12 = _nPar12

					// Quando lcto de rateio, processa todos os registros da tabela SDE (rateios)
					if 'DE_' $ upper (ct5 -> ct5_vlr01)
					//	u_log2 ('info', 'LPAD ' + ct5 -> ct5_lanpad + '/' + ct5 -> ct5_sequen + ' tem rateio. Testando chave ' + xfilial ("SDE") + sd1 -> d1_doc + sd1 -> d1_serie + sd1 -> d1_fornece + sd1 -> d1_loja + sd1 -> d1_item)
						sde -> (dbseek (xfilial ("SDE") + sd1 -> d1_doc + sd1 -> d1_serie + sd1 -> d1_fornece + sd1 -> d1_loja + sd1 -> d1_item, .T.))
						do while ! sde -> (eof ());
						.and. sde -> de_filial  == xfilial ("SDE");
						.and. sde -> de_doc     == sd1 -> d1_doc;
						.and. sde -> de_serie   == sd1 -> d1_serie;
						.and. sde -> de_fornece == sd1 -> d1_fornece;
						.and. sde -> de_loja    == sd1 -> d1_loja;
						.and. sde -> de_itemnf  == sd1 -> d1_item
					//		u_log2 ('info', 'Verificando de_item: ' + sde -> de_item)
							_ExecLPad ()
							sde -> (dbskip ())
						enddo
					else
						_ExecLPad ()
					endif
				next
			next

			// Grava pelo menos um registro mencionando o RECNO da tabela. Se tiver lctos gerados, acrescenta.
			for _nLcto = 1 to max (1, len (_aLctos))
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " INSERT INTO VA_SIMUL_LCTOS (TABELA, RECNO, LPAD, SEQ, VALOR, CTADEB, CTACRED, CCD, CCC, HIST, M330PAR12, CLVLDB, CLVLCR)"
				_oSQL:_sQuery += " VALUES ('" + _sTabMovto + "',"
				_oSQL:_sQuery +=           cvaltochar ((_sTabMovto) -> (recno ())) + ","
				_oSQL:_sQuery +=           iif (_nLcto > len (_aLctos), "'',", "'" + _aLctos [_nLcto, 1]  + "', ")
				_oSQL:_sQuery +=           iif (_nLcto > len (_aLctos), "'',", "'" + _aLctos [_nLcto, 2]  + "', ")
				_oSQL:_sQuery +=           iif (_nLcto > len (_aLctos), "0 ,", cvaltochar (_aLctos [_nLcto, 3]) + ", ")
				_oSQL:_sQuery +=           iif (_nLcto > len (_aLctos), "'',", "'" + _aLctos [_nLcto, 4]  + "', ")
				_oSQL:_sQuery +=           iif (_nLcto > len (_aLctos), "'',", "'" + _aLctos [_nLcto, 5]  + "', ")
				_oSQL:_sQuery +=           iif (_nLcto > len (_aLctos), "'',", "'" + _aLctos [_nLcto, 6]  + "', ")
				_oSQL:_sQuery +=           iif (_nLcto > len (_aLctos), "'',", "'" + _aLctos [_nLcto, 7]  + "', ")
				_oSQL:_sQuery +=           iif (_nLcto > len (_aLctos), "'',", "'" + _aLctos [_nLcto, 8]  + "',")
				_oSQL:_sQuery +=           iif (_nLcto > len (_aLctos), "'',", "'" + _aLctos [_nLcto, 9]  + "',")
				_oSQL:_sQuery +=           iif (_nLcto > len (_aLctos), "'',", "'" + _aLctos [_nLcto, 10] + "',")
				_oSQL:_sQuery +=           iif (_nLcto > len (_aLctos), "''" , "'" + _aLctos [_nLcto, 11] + "'")
				_oSQL:_sQuery +=         ")"
				//_oSQL:Log ()
				if ! _oSQL:Exec ()
					u_help ('Erro ao inserir lctos no arquivo de simulacoes.',, .t.)
					_lContinua = .F.
				endif
			next
			if ! _lContinua
				u_help ('Abortando o processo no final da leitura de movtos.',, .t.)
				exit
			endif
		next
	next
	U_LOG2 ('info', 'Simulacao de contabilizacao finalizada.')
return



// --------------------------------------------------------------------------
// Executa o lancamento padrao.
Static Function _ExecLPad ()
	local _nValor    := 0
	local _sCtaDeb   := ""
	local _sCtaCred  := ""
	local _sCCD      := ""
	local _sCCC      := ""
	local _sHist     := ""
	local _nTamHist  := 40

	// Executa a regra do lcto padrao para ver se retorna valor.
	_nValor = eval (&("{||" + alltrim (ct5 -> ct5_vlr01) + "}"))
	if _nValor != 0
		_sCtaDeb  = cvaltochar (eval (&("{||" + alltrim (ct5 -> ct5_debito) + "}")))
		_sCtaCred = cvaltochar (eval (&("{||" + alltrim (ct5 -> ct5_credit) + "}")))
		_sCCD     = cvaltochar (eval (&("{||" + alltrim (ct5 -> ct5_ccd) + "}")))
		_sCCC     = cvaltochar (eval (&("{||" + alltrim (ct5 -> ct5_ccc) + "}")))
		_sHist    = left (strtran (strtran (strtran (cvaltochar (eval (&("{||" + alltrim (ct5 -> ct5_hist) + "}"))), '&', ''), '$', ''), '%', ''), _nTamHist)
		_sClVlDb  = cvaltochar (eval (&("{||" + alltrim (ct5 -> ct5_clvldb) + "}")))
		_sClVlCr  = cvaltochar (eval (&("{||" + alltrim (ct5 -> ct5_clvlcr) + "}")))
		aadd (_aLctos, {ct5 -> ct5_lanpad, ct5 -> ct5_sequen, _nValor, ;
						iif (empty (_sCtaDeb),  '', _sCtaDeb), ;
						iif (empty (_sCtaCred), '', _sCtaCred), ;
						iif (empty (_sCCD),     '', _sCCD), ;
						iif (empty (_sCCC),     '', _sCCC), ;
						iif (empty (_sHist),    '', _sHist), ;
						cvaltochar (mv_par12), ;
						iif (empty (_sClVlDb),    '', _sClVlDb), ;
						iif (empty (_sClVlCr),    '', _sClVlCr)})
	endif
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3  Opcoes                 Help
//	aadd (_aRegsPerg, {01, "Arquivo de movimentos         ", "N", 1,  0,  "",   "", {"SD1", 'SD2', 'SD3'}, ""})
	aadd (_aRegsPerg, {01, "Data inicial                  ", "D", 8,  0,  "",   "", {},                    ""})
	aadd (_aRegsPerg, {02, "Data final                    ", "D", 8,  0,  "",   "", {},                    ""})
	aadd (_aRegsPerg, {03, "LPADs a considerar(bco=todos) ", "C", 60, 0,  "",   "", {},                    ""})
	aadd (_aRegsPerg, {04, "Tabelas (SD1/SD2/...)         ", "C", 60, 0,  "",   "", {},                    ""})
//	aadd (_aRegsPerg, {06, "D3_CF a considerar(sep.barras)", "C", 60, 0,  "",   "", {},                    ""})
//	aadd (_aRegsPerg, {07, "TES a considerar(sep.barras)  ", "C", 60, 0,  "",   "", {},                    ""})

	U_ValPerg (cPerg, _aRegsPerg)
return
