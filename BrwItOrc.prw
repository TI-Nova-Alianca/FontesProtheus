// Programa:   BrwItOrc
// Autor:      Robert Koch
// Data:       22/02/2008
// Cliente:    Alianca
// Descricao:  Browse para selecao de itens orcamentarios, baseado na conta contabil
//             informada. Criado para ser usado, inicialmente, em ped.compra.
// 
// Historico de alteracoes:
// 07/04/2008 - Robert - Nao considerava corretamente parametro _lRetACols no final da rotina.
// 05/06/2008 - Robert - Passa a buscar o saldo de cada item cfe. movimentacao do SD1.
// 10/09/2008 - Robert - Passa a buscar todos os dados em uma unica query
//                     - Passa a listar totais anuais no rodape da tela.
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
user function BrwItOrc (_sCtaIni, _sProduto, _sCtaFim, _lRetACols)
	local _xDado  := &(readvar ()) // Para retorno do gatilho.
	private _aRet := NIL
	_lRetACols = iif (_lRetACols == NIL, .F., _lRetACols)

	delete file (_sArqLog)

	processa ({|| _AndaLogo (_sCtaIni, _sProduto, _sCtaFim, _lRetACols)})
return iif (_lRetACols, _aRet, _xDado)



// --------------------------------------------------------------------------
static function _AndaLogo (_sCtaIni, _sProduto, _sCtaFim, _lRetACols)
    local _aAreaAnt    := U_ML_SRArea ()
    local _aAmbAnt     := U_SalvaAmb ()
    local _sNomeColP   := ""
    local _sNomeColS   := ""
    local _sQuery      := ""
	local _sAliasQ     := ""
	local _nSaldo      := 0
	local _n		   := 1
    private _C7VAORCAM := ""   // Deixar private para retorno.
    private _C7VAVEROR := ""   // Deixar private para retorno.
    private _C7VACO    := ""   // Deixar private para retorno.
    private _C7VAITORC := ""   // Deixar private para retorno.
    private _C7CC      := ""   // Deixar private para retorno.
    private _C7ITEMCTA := ""   // Deixar private para retorno.
	private _lConfirma := .F.  // Deixar private para retorno.
	private _nAnoPrev  := 0    // Deixar private para atualizacao de tela.
	private _nAnoReal  := 0    // Deixar private para atualizacao de tela.
	private _nAnoSald  := 0    // Deixar private para atualizacao de tela.
	private _oAnoPrev  := NIL  // Deixar private para atualizacao de tela.
	private _oAnoReal  := NIL  // Deixar private para atualizacao de tela.
	private _oAnoSald  := NIL  // Deixar private para atualizacao de tela.

   // Se estas variaveis nao existirem, tenho que cria-las, para poder utilizar a
   // rotina de montagem da GetDados.
   if type ("aHeader") != "A"
   	private aHeader   := {}
   endif
   if type ("aCols") != "A"
   	private aCols     := {}
   endif
   if type ("N") != "N"
   	private N         := 1
   endif
   if type ("aRotina") != "A"
		private aRotina   := {}  // Variavel exigida pela GetDados.
	endif
	aRotina = {}
	aadd (aRotina, {"BlaBlaBla", "allwaystrue ()", 0, 1})
	aadd (aRotina, {"BlaBlaBla", "allwaystrue ()", 0, 2})

   procregua (2)
   incproc ("Buscando dados...")

	// Se nao recebi a conta, devo ter recebido o produto (depende de qual campo o gatilho
	// foi disparado) e vou pegar a conta do produto.
	if _sCtaIni == NIL
		sb1 -> (dbsetorder (1))  // CT1_FILIAL+CT1_CONTA
		if sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
			_sCtaIni = sb1 -> b1_conta
		endif
	endif
		
	// Define conta final a ser lida, pois esta rotina pode ser chamada tanto por gatilhos
	// referentes a uma soh conta como por programas que querem receber como retorno o
	// aCols preenchido com um intervalo de contas.
	if _sCtaFim == NIL
		_sCtaFim = _sCtaIni
	endif

	// Busca previsoes no orcamento e seus saldos
	// O indice 'C7_VAORCAM' da tabela SC7 foi criado especificamente para agilizar esta consulta.
	_sQuery := ""
	_sQuery += " select AK2_ORCAME, AK2_VERSAO, AK2_CO, AK2_ID, AK2_VALOR, AK2_CC, AK2_ITCTB, AK2_DESCRI, AK3_DESCRI, AK2_PERIOD, AK2_DATAI, AK2_DATAF, "

	// Busca despesas jah efetuadas e que tenham sido lancadas atraves de lctos contabeis.
	_sQuery +=        " (select sum (CT2_VALOR)"
	_sQuery +=           " from " + RetSQLName ("CT2") + " CT2 "
	_sQuery +=          " where CT2.D_E_L_E_T_ = ''"
	_sQuery +=            " and CT2.CT2_FILIAL = '" + xfilial ("CT2") + "'"
	_sQuery +=            " and CT2.CT2_DATA   between AK2_PERIOD and AK2_PERIOD + 30"
	_sQuery +=            " and exists ("
	_sQuery +=                 "select CT1_FILIAL from " + RetSQLName ("CT1") + " CT1_CO "
	_sQuery +=                 " where CT1_CO.D_E_L_E_T_ = ''"
	_sQuery +=                   " and CT1_CO.CT1_FILIAL = '" + xfilial ("CT1") + "'"
	_sQuery +=                   " and CT1_CO.CT1_CONTA  = CT2.CT2_DEBITO"
	_sQuery +=                   " and CT1_CO.CT1_CTAORC = AK2.AK2_CO"
	_sQuery +=                 ")"
	_sQuery +=         ") as DebitoCT2, "
	_sQuery +=        " (select sum (CT2_VALOR)"
	_sQuery +=           " from " + RetSQLName ("CT2") + " CT2 "
	_sQuery +=          " where CT2.D_E_L_E_T_ = ''"
	_sQuery +=            " and CT2.CT2_FILIAL = '" + xfilial ("CT2") + "'"
	_sQuery +=            " and CT2.CT2_DATA   between AK2_PERIOD and AK2_PERIOD + 30"
	_sQuery +=            " and exists ("
	_sQuery +=                 "select CT1_FILIAL from " + RetSQLName ("CT1") + " CT1_CO "
	_sQuery +=                 " where CT1_CO.D_E_L_E_T_ = ''"
	_sQuery +=                   " and CT1_CO.CT1_FILIAL = '" + xfilial ("CT1") + "'"
	_sQuery +=                   " and CT1_CO.CT1_CONTA  = CT2.CT2_CREDIT"
	_sQuery +=                   " and CT1_CO.CT1_CTAORC = AK2.AK2_CO"
	_sQuery +=                 ")"
	_sQuery +=         ") as CreditoCT2, "

	// Busca despesas ainda nao efetuadas e que estejam previstas nos pedidos de compra.
	_sQuery += "        (select sum ((C7_QUANT - C7_QUJE) * C7_PRECO)"
	_sQuery +=           " from " + RetSQLName ("SC7") + " SC7 "
	_sQuery +=          " where SC7.D_E_L_E_T_ = ''"
	_sQuery +=            " and SC7.C7_FILIAL  = '" + xfilial ("SC7") + "'"
	_sQuery +=            " and SC7.C7_DATPRF  between AK2_PERIOD and AK2_PERIOD + 30"
	_sQuery +=            " and SC7.C7_ENCER   != 'E'"
	_sQuery +=            " and SC7.C7_RESIDUO != 'S'"
	_sQuery +=            " and SC7.C7_CONAPRO != 'B'"
	_sQuery +=            " and SC7.C7_VAORCAM  = AK2_ORCAME"
	_sQuery +=            " and SC7.C7_VAVEROR  = AK2_VERSAO"
	_sQuery +=            " and SC7.C7_VACO     = AK2_CO"
	_sQuery +=            " and SC7.C7_VAITORC  = AK2_ID"
	_sQuery +=         ") as UsadoSC7 "

	_sQuery += "   from " + RetSQLName ("CT1") + " CT1, "
	_sQuery +=              RetSQLName ("AK3") + " AK3, "
	_sQuery +=              RetSQLName ("AK5") + " AK5, "
	_sQuery +=              RetSQLName ("AK2") + " AK2  "
	_sQuery +=  " where CT1.D_E_L_E_T_ = ''"
	_sQuery +=    " and AK2.D_E_L_E_T_ = ''"
	_sQuery +=    " and AK3.D_E_L_E_T_ = ''"
	_sQuery +=    " and AK5.D_E_L_E_T_ = ''"
	_sQuery +=    " and CT1_FILIAL  = '" + xfilial ("CT1") + "'"
	_sQuery +=    " and AK2_FILIAL  = '" + xfilial ("AK2") + "'"
	_sQuery +=    " and AK3_FILIAL  = '" + xfilial ("AK3") + "'"
	_sQuery +=    " and AK5_FILIAL  = '" + xfilial ("AK5") + "'"
	_sQuery +=    " and CT1_CONTA   between '" + _sCtaIni + "' and '" + _sCtaFim + "'"
	_sQuery +=    " and CT1_CTAORC != ''"
	_sQuery +=    " and AK5_CODIGO  = CT1_CTAORC"
	_sQuery +=    " and AK2_CO      = CT1_CTAORC"
	_sQuery +=    " and AK2_DATAI   between '" + alltrim (str (year (dDataBase))) + "0101' and '" + alltrim (str (year (dDataBase))) + "1231'"
	_sQuery +=    " and AK3_ORCAME  = AK2_ORCAME"
	_sQuery +=    " and AK3_VERSAO  = AK2_VERSAO"
	_sQuery +=    " and AK3_CO      = AK2_CO"
	_sQuery +=  " Group by AK2_ORCAME, AK2_VERSAO, AK2_VALOR, AK2_ID, AK2_CO, AK2_CC, AK2_ITCTB, AK2_DESCRI, AK3_DESCRI, AK2_PERIOD, AK2_DATAI, AK2_DATAF "
	_sQuery +=  " Order by AK2_ORCAME, AK2_VERSAO, AK2_CO, AK2_ID, AK2_PERIOD, AK2_CC"
	u_log (_squery)
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
	TCSetField (_sAliasQ, "AK2_PERIOD", "D")
	TCSetField (_sAliasQ, "AK2_DATAI", "D")
	TCSetField (_sAliasQ, "AK2_DATAF", "D")

	// Monta aHeader para mostrar na GetDados posteriormente.
	aHeader = {}
	//              Titulo        Campo         Masc  Tam                       Dec ?   x3_usado Tipo Arq Contexto
	aadd (aHeader, {"Orcam",      "C7_VAORCAM", "@!", tamsx3 ("AK2_ORCAME")[1], 0,  "", "",      "C", "", "V"})
	aadd (aHeader, {"Versao",     "C7_VAVEROR", "@!", tamsx3 ("AK2_VERSAO")[1], 0,  "", "",      "C", "", "V"})
	aadd (aHeader, {"Cta.Orc.",   "C7_VACO",    "@!", tamsx3 ("AK2_CO")[1],     0,  "", "",      "C", "", "V"})
	aadd (aHeader, {"It.Orc.",    "C7_VAITORC", "@!", tamsx3 ("AK2_ID")[1],     0,  "", "",      "C", "", "V"})
	aadd (aHeader, {"C.Custo",    "C7_CC",      "@!", tamsx3 ("AK2_CC")[1],     0,  "", "",      "C", "", "V"})
	aadd (aHeader, {"It.Contab",  "C7_ITEMCTA", "@!", tamsx3 ("AK2_ITCTB")[1],  0,  "", "",      "C", "", "V"})
	aadd (aHeader, {"Descricao",  "Descri",     "@!", 40,                       0,  "", "",      "C", "", "V"})

	// Cria aCols cfe. os campos jah definidos no aHeader.
	aCols = {}
	Do While ! (_sAliasQ) -> (Eof ())

		// Monta uma array com os periodos "lado a lado", semelhante `a tela da planilha orcamentaria.
		// Se ainda nao tem uma coluna para este periodo no aHeader, cria-a.
		_sNomeColP = "P" + dtoc((_sAliasQ)->ak2_period)  // P = Previsto
		_sNomeColS = "S" + dtoc((_sAliasQ)->ak2_period)  // S = Saldo
		_sNomeColX = "X" + dtoc((_sAliasQ)->ak2_period)  // X = separador de colunas
		if GDFieldPos (_sNomeColP) == 0
			
			// Inclui colunas para o periodo: Previsao, saldo e 'separador'.
			//              Titulo                                                           Campo       Masc                 Tam Dec ?   x3_usado Tipo Arq Contexto
			aadd (aHeader, {dtoc((_sAliasQ)->ak2_datai) + "-" + dtoc((_sAliasQ)->ak2_dataf), _sNomeColP, "@E 999,999,999.99", 12, 2,  "", "",      "N", "", "V"})
			aadd (aHeader, {"Saldo"                                                        , _sNomeColS, "@E 999,999,999.99", 12, 2,  "", "",      "N", "", "V"})
			aadd (aHeader, {"I"                                                            , _sNomeColX, "@!",                1,  0,  "", "",      "C", "", "V"})

			// Se jah tenho alguma linha no aCols, tenho que criar essas novas colunas para todas as linhas.
			// Para isso, tenho que 'empurrar' a ultima coluna (flag de linha deletada).
			for _n = 1 to len (aCols)
				N := _n
				aadd (aCols [N], .F.)
				aadd (aCols [N], .F.)
				aadd (aCols [N], .F.)
				aCols [N, len (aCols [N]) - 3] = 0
				aCols [N, len (aCols [N]) - 2] = 0
				aCols [N, len (aCols [N]) - 1] = ""
			next
		endif
		
		// Se este item jah existe no aCols, gravo na mesma linha. Senao, gero linha nova.
		N = ascan (aCols, {|_aVal| _aVal [GDFieldPos ("C7_VAORCAM")] == (_sAliasQ) -> ak2_orcame ;
									.and. _aVal [GDFieldPos ("C7_VAVEROR")] == (_sAliasQ) -> ak2_versao ;
									.and. _aVal [GDFieldPos ("C7_VACO")]    == (_sAliasQ) -> ak2_co ;
									.and. _aVal [GDFieldPos ("C7_VAITORC")] == (_sAliasQ) -> ak2_id})
		if N == 0
			aadd (aCols, aclone (U_LinVazia (aHeader)))
			N = len (aCols)
			GDFieldPut ("C7_VAORCAM", (_sAliasQ) -> ak2_orcame)
			GDFieldPut ("C7_VAVEROR", (_sAliasQ) -> ak2_versao)
			GDFieldPut ("C7_VACO",    (_sAliasQ) -> ak2_co)
			GDFieldPut ("C7_VAITORC", (_sAliasQ) -> ak2_id)
			GDFieldPut ("C7_CC",      (_sAliasQ) -> ak2_cc)
			GDFieldPut ("C7_ITEMCTA", (_sAliasQ) -> ak2_itctb)
			GDFieldPut ("Descri", alltrim ((_sAliasQ) -> ak3_descri) + " - " + alltrim ((_sAliasQ) -> ak2_descri))
		endif
		
		GDFieldPut (_sNomeColP, (_sAliasQ) -> ak2_valor)

		// Desconta do saldo da linha os valores jah utilizados.
		_nSaldo := (_sAliasQ) -> ak2_valor
		_nSaldo -= (_sAliasQ) -> DebitoCT2
		_nSaldo += (_sAliasQ) -> CreditoCT2
		_nsaldo -= (_sAliasQ) -> UsadoSC7

		GDFieldPut (_sNomeColS, _nSaldo)

		(_sAliasQ) -> (dbskip ())
	enddo
				
	// Varre o aCols procurando a maior descricao e ajusta a largura da coluna no aHeader
	_nColDesc = GDFieldPos ("Descri")
	aHeader [_nColDesc, 4] = 1
	for _n = 1 to len (aCols)
		N := _n
		aHeader [_nColDesc, 4] = max (aHeader [_nColDesc, 4], len (aCols [N, _nColDesc]))
	next
	
	U_LOG ('aCols:', acols)
	
	// Monta tela para o usuario selecionar, como se fosse um F3 normal.
	if len (aCols) > 0 .and. ! _lRetACols
		N = 1
		define MSDialog _oDlg from 0, 0 to 450, oMainWnd:nClientWidth - 20 of oMainWnd pixel title "Selecao de itens orcamentarios"
			_oGetD := MSGETDADOS ():New (10, ;   // Limite superior
			10, ;                                // Limite esquerdo
			_oDlg:nClientHeight / 2 - 70, ;      // Limite inferior
			_oDlg:nClientWidth / 2 - 10, ;       // Limite direito
			2, ;                                 // opcao do mbrowse, caso tivesse
			"allwaystrue ()", ;                  // Linha ok
			"allwaystrue ()", ;                  // Tudo ok
			, ;                                  // Campos com incremento automatico
			.F., ;                               // Permite deletar linhas
			, ;                                  // Vetor de campos que podem ser alterados
			, ;                                  // Reservado
			.F., ;                               // Se .T., a primeira coluna nunca pode ficar vazia
			len (aCols), ;                       // Maximo de linhas permitido
			"allwaystrue ()", ;                  // Executada na validacao de campos, mesmo os que nao estao na MSGetDados
			"AllwaysTrue ()", ;                  // Funcao executada quando pressionadas as teclas <Ctrl>+<Delete>.
			, ;                                  // Reservado
			"allwaystrue ()", ;                  // Funcao executada para validar a exclusao ou reinclusao de uma linha do aCols.
			_oDlg)                               // Objeto no qual a MsGetDados serah criada.

			// Seccao de saldos anuais
			@ _oDlg:nClientHeight / 2 - 65, _oDlg:nClientWidth / 2 - 170 say "Totais anuais:"
			@ _oDlg:nClientHeight / 2 - 65, _oDlg:nClientWidth / 2 - 120 say "Previsto:"
			@ _oDlg:nClientHeight / 2 - 50, _oDlg:nClientWidth / 2 - 120 say "Realizado:"
			@ _oDlg:nClientHeight / 2 - 35, _oDlg:nClientWidth / 2 - 120 say "Saldo:"
			@ _oDlg:nClientHeight / 2 - 65, _oDlg:nClientWidth / 2 - 70  get _nAnoPrev picture "@E 999,999,999.99" when .F. size 50, 11 object _oAnoPrev
			@ _oDlg:nClientHeight / 2 - 50, _oDlg:nClientWidth / 2 - 70  get _nAnoReal picture "@E 999,999,999.99" when .F. size 50, 11 object _oAnoReal
			@ _oDlg:nClientHeight / 2 - 35, _oDlg:nClientWidth / 2 - 70  get _nAnoSald picture "@E 999,999,999.99" when .F. size 50, 11 object _oAnoSald

			// Chama rotina de atualizacao da tela a cada troca de linha no browse.
 			_oGetD:oBrowse:bChange := {|| _AtuTela ()}

			_oGetD:oBrowse:bLDblClick := {|| _lConfirma := .T., ;
														_C7VAORCAM := GDFieldGet ("C7_VAORCAM"), ;
														_C7VAVEROR := GDFieldGet ("C7_VAVEROR"), ;
														_C7VACO    := GDFieldGet ("C7_VACO"), ;
														_C7VAITORC := GDFieldGet ("C7_VAITORC"), ;
														_C7CC      := GDFieldGet ("C7_CC"), ;
														_C7ITEMCTA := GDFieldGet ("C7_ITEMCTA"), ;
														_oDlg:End ()}
			@ _oDlg:nClientHeight / 2 - 40, 10 button "Excel" action U_aColsXLS ()
		activate dialog _oDlg centered
	endif

	// Prepara dados para retorno, se for o caso.
	if _lRetACols
		_aRet := {aclone (aHeader), aclone (aCols)}
	endif

   // Restaura backups do aCols, etc. antes de gravar os dados no aCols.
   U_SalvaAmb (_aAmbAnt)
   
   // Atualiza dados na GetDados original. Faz isso depois da chamada sa funcao
   // SalvaAmb por que a mesma restaura backup do aCols.
   if _lConfirma .and. ! _lRetACols
	   if funname () == "MATA121"
			GDFieldPut ("C7_VAORCAM", _C7VAORCAM)
			GDFieldPut ("C7_VAVEROR", _C7VAVEROR)
			GDFieldPut ("C7_VACO",    _C7VACO)
			GDFieldPut ("C7_VAITORC", _C7VAITORC)
		   GDFieldPut ("C7_CC",      _C7CC)
			GDFieldPut ("C7_ITEMCTA", _C7ITEMCTA)
		endif
	endif

   U_ML_SRArea (_aAreaAnt)
return



// --------------------------------------------------------------------------
// Atualiza totais em tela
static function _AtuTela ()
	Local _nCampo := 0
	_nAnoPrev = 0
	_nAnoReal = 0
	_nAnoSald = 0
	for _nCampo = 8 to len (aHeader)
		if left (aHeader [_nCampo, 2], 1) == "P"
			_nAnoPrev += GDFieldGet (aHeader [_nCampo, 2])
		endif
		if left (aHeader [_nCampo, 2], 1) == "S"
			_nAnoSald += GDFieldGet (aHeader [_nCampo, 2])
		endif
	next
	_nAnoReal = _nAnoPrev - _nAnoSald
	_oAnoPrev:Refresh ()
	_oAnoReal:Refresh ()
	_oAnoSald:Refresh ()
return
