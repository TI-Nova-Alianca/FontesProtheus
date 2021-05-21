// Programa...: ClsTabGen
// Autor......: Robert Koch
// Data.......: 04/01/2017
// Descricao..: Declaracao de classe de representacao de tabelas genericas (ZX5).
//            	Poderia trabalhar como uma include, mas prefiro declarar uma funcao de usuario
//            	apenas para poder incluir no projeto e manter na pasta dos fontes.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #classe
// #Descricao         #Declaracao de classe de representacao de tabelas genericas (ZX5)
// #PalavasChave      #clase #uso_generico
// #TabelasPrincipais #ZX5
// #Modulos           #todos_modulos
//
// Historico de alteracoes:
// 06/02/2017 - Robert  - Tratamento lista de campos chave tabelas Sisdeclara.
// 21/03/2017 - Robert  - Tratamento chaves duplicadas tabela 14.
// 29/05/2017 - Catia   - tabela 02 estava sem chave
// 19/06/2017 - Robert  - Criado medodo ExistChav().
//                      - Criado atributo ExistTab e inserida respectiva validacao no momento de instanciar a classe.
// 07/12/2017 - Robert  - Criado metodo PodeExcl().
// 14/02/2018 - Catia   - tabela 48 estava sem chave
// 25/01/2019 - Robert  - Ajustada chave unica tabela 14.
// 03/01/2020 - Robert  - Campo ZX5_17COND vai ser excluido (a tabela 17 serve somente para espaldeira, 
//                        entao nao ha motivo para manter o campo).
//                      - Criado tratamento para as tabelas 52 e 53.
// 11/05/2021 - Claudia - Ajustada a chamada para tabela SX3 devido a R27. GLPI: 8825
//
// --------------------------------------------------------------------------------------------------------------------
#include "protheus.ch"

CLASS ClsTabGen

	// Declaracao das propriedades da Classe
	DATA Campos
	DATA CodTabela
	DATA CposChave
	DATA ExistTab
	DATA ModoAcesso
	DATA UltMsg

	// Declaracao dos Metodos da classe
	METHOD New ()
	METHOD Insere ()
	METHOD ExistChav ()
	METHOD PodeExcl ()
ENDCLASS
//
// --------------------------------------------------------------------------
// Construtor.
METHOD New (_sCodTab) Class ClsTabGen
	local _aAreaAnt := U_ML_SRArea ()
	local _x        := 0

	::Campos     = {}
	::CodTabela  = ''
	::CposChave  = {}
	::ModoAcesso = ''
	::UltMsg     = ''
	::ExistTab   = .F.
	
	zx5 -> (dbsetorder (1))  // ZX5_FILIAL+ZX5_TABELA+ZX5_CHAVE
	if valtype (_sCodTab) != 'C' .or. empty (_sCodTab) .or. ! zx5 -> (dbseek (xfilial ("ZX5") + '00' + _sCodTab, .F.))
		::ExistTab = .F.
		::UltMsg   = "Codigo de tabela '" + cvaltochar (_sCodTab) + "' invalido / tabela nao cadastrada no ZX5."
		u_log (::UltMsg)
	else
		::ExistTab = .T.
		::CodTabela  = _sCodTab
		::ModoAcesso = fBuscaCpo ("ZX5", 1, xfilial ("ZX5") + "00" + ::CodTabela, "ZX5_MODO")

		// Monta lista de campos chave
		do case
			case ::CodTabela == "01" ; ::CposChave = {"ZX5_01CPRO", "ZX5_01LPRO", "ZX5_01CCLI", "ZX5_01LCLI"}
			case ::CodTabela == "02" ; ::CposChave = {"ZX5_02MOT"}
			case ::CodTabela == "06" ; ::CposChave = {"ZX5_06USER"}
			case ::CodTabela == "08" ; ::CposChave = {"ZX5_08MARC"}
			case ::CodTabela == "09" ; ::CposChave = {"ZX5_09SAFR", "ZX5_09LOCA"}
			case ::CodTabela == "11" ; ::CposChave = {"ZX5_11SAFR", "ZX5_11COD"}
			case ::CodTabela == "13" ; ::CposChave = {"ZX5_13SAFR", "ZX5_13GRUP"}
			case ::CodTabela == "14" ; ::CposChave = {"ZX5_14SAFR", "ZX5_14PROD", "ZX5_14GRUP"}
			case ::CodTabela == "15" ; ::CposChave = {"ZX5_15PLAN", "ZX5_15COD"}
			case ::CodTabela == "16" ; ::CposChave = {"ZX5_16PLAN", "ZX5_16ITEM"}
			case ::CodTabela == "17" ; ::CposChave = {"ZX5_17SAFR", "ZX5_17PROD"}
			case ::CodTabela == "20" ; ::CposChave = {"ZX5_20CRQ"}
			case ::CodTabela == "48" ; ::CposChave = {"ZX5_48MOT"}
			case ::CodTabela == "52" ; ::CposChave = {"ZX5_52SAFR", "ZX5_52GRUP"}
			case ::CodTabela == "53" ; ::CposChave = {"ZX5_53SAFR", "ZX5_53GRUP", "ZX5_53PROD"}
			case ::CodTabela == "54" ; ::CposChave = {"ZX5_54COD"}
			otherwise
				// Procura campo 'COD' na tabela, pois atende a maioria dos casos.
				if zx5 -> (fieldpos ('ZX5_' + ::CodTabela + 'COD')) > 0
					::CposChave = {'ZX5_' + ::CodTabela + 'COD'}
				endif
		endcase

		// // Monta lista de campos pertencentes `a tabela informada.
		// ::Campos = {}
		// sx3 -> (dbsetorder (1))
		// sx3 -> (dbseek ("ZX5", .T.))
		// do while ! sx3 -> (eof ()) .and. sx3 -> x3_arquivo == "ZX5"
		// 	if left (sx3 -> x3_campo, 6) == "ZX5_" + ::CodTabela
		// 		aadd (::Campos, sx3 -> x3_campo)
		// 	endif
		// 	sx3 -> (dbskip ())
		// enddo

		// Monta lista de campos pertencentes a tabela informada.
		::Campos = {}
		_oSQL  := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += " 	   X3_ARQUIVO "
		_oSQL:_sQuery += "    ,X3_CAMPO  "
		_oSQL:_sQuery += " FROM SX3010 "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_='' "
		_oSQL:_sQuery += " AND X3_ARQUIVO='ZX5' "
		_aZX5  = aclone (_oSQL:Qry2Array ())

		For _x:= 1 to Len(_aZX5)
			_sX3_ARQUIVO := _aZX5[_x, 1]
			_sX3_CAMPO   := _aZX5[_x, 2]

			If left (_sX3_CAMPO, 6) == "ZX5_" + ::CodTabela
				aadd (::Campos, _sX3_CAMPO)
			Endif
		Next
	endif
	U_ML_SRArea (_aAreaAnt)
Return ::self
//
// --------------------------------------------------------------------------
// Verifica se a chave informada existe na tabela.
METHOD ExistChav (_sChave) Class ClsTabGen
	local _lRet     := .T.
	local _nCpo     := 0
	local _sCpoChav := ""
	local _oSQL     := NIL
	local _aAreaAnt := U_ML_SRArea ()
	
	if ! ::ExistTab
		_lRet = .F.
	else
		for _nCpo = 1 to len (::CposChave)
			_sCpoChav += ::CposChave [_nCpo] + iif (_nCpo < len (::CposChave), '+', '')
		next
		if ! empty (_sCpoChav)
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " select count (ZX5_FILIAL)"
			_oSQL:_sQuery += "   from " + RetSQLName ("ZX5")
			_oSQL:_sQuery += "  where D_E_L_E_T_ = ''"
			_oSQL:_sQuery += "    and ZX5_FILIAL = '" + iif (::ModoAcesso == 'E', xfilial ("ZX5"), '  ') + "'"
			_oSQL:_sQuery += "    and ZX5_TABELA = '" + ::CodTabela + "'"
			_oSQL:_sQuery +=    " AND " + _sCpoChav + " = '" + _sChave + "'"
			if _oSQL:RetQry () == 0
				::UltMsg = "Nao existe registro relacionado: Chave '" + _sChave + "' nao cadastrada na tabela '" + ::CodTabela + "' do arquivo ZX5."
				_lRet = .F.
			endif
		endif
	endif
	U_ML_SRArea (_aAreaAnt)
return _lRet
//
// --------------------------------------------------------------------------
// Insere novos registros na tabela.
METHOD Insere (_aDados) Class ClsTabGen
	local _lContinua := .T.
	local _nCampo    := 0
	local _nDado     := 0
	local _oSQL      := NIL
	local _sChave    := ""

	u_logIni (GetClassName (::Self) + '.' + procname ())

	if _lContinua .and. empty (::CodTabela)
		::UltMsg += "Codigo da tabela nao definido;"
		_lContinua = .F.
	endif

	// Verifica campos invalidos.
	if _lContinua
		for _nDado = 1 to len (_aDados)
			if ascan (::Campos, _aDados [_nDado, 1]) == 0
				::UltMsg += "Campo '" + _aDados [_nDado, 1] + "' nao consta na tabela " + ::CodTabela + ";"
				_lContinua = .F.
			endif
		next
	endif

	// Verifica campos chave (obrigatorios).
	if _lContinua
		for _nCampo = 1 to len (::CposChave)
			if ascan (_aDados, {|_aVal| _aVal [1] == ::CposChave [_nCampo]}) == 0
				::UltMsg += "Campo '" + ::CposChave [_nCampo] + "' eh chave e deve ser informado para a tabela " + ::CodTabela + ";"
				_lContinua = .F.
			endif
		next
	endif

	// Verifica chaves repetidas.
	if _lContinua .and. len (::CposChave) > 0
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT COUNT (*)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZX5")
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZX5_FILIAL = '" + iif (::ModoAcesso == 'E', cFilAnt, '  ') + "'"
		for _nCampo = 1 to len (::CposChave)
			_nDado = ascan (_aDados, {|_aVal| _aVal [1] == ::CposChave [_nCampo]})
			_oSQL:_sQuery += " AND " + ::CposChave [_nCampo] + " = "
			do case
				case valtype (_aDados [_nDado, 2]) == 'C'
					_oSQL:_sQuery += "'" + _aDados [_nDado, 2] + "'"
				case valtype (_aDados [_nDado, 2]) == 'N'
					_oSQL:_sQuery += cvaltochar (_aDados [_nDado, 2])
				case valtype (_aDados [_nDado, 2]) == 'D'
					_oSQL:_sQuery += "'" + dtos (_aDados [_nDado, 2]) + "'"
				otherwise
					::UltMsg += "Sem tratamento para campo chave '" + ::CposChave [_nCampo] + "' contendo tipo de dado '" + valtype (_aDados [_nDado, 2]) + "' no metodo " + GetClassName (::Self) + '.' + procname ()
					_lContinua = .F.
			endcase
		next
		if _lContinua
			_oSQL:Log ()
			if _oSQL:RetQry (1, .F.) > 0
				::UltMsg = "Chave duplicada;"
				_lContinua = .F.
			endif
		endif
	endif

	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery += " select MAX (ZX5_CHAVE)"
		_oSQL:_sQuery += "   from " + RetSQLName ("ZX5")
		_oSQL:_sQuery += "  where D_E_L_E_T_ = ''"
		_oSQL:_sQuery += "    and ZX5_FILIAL = '" + iif (::ModoAcesso == 'E', cFilAnt, '  ') + "'"
		_oSQL:_sQuery += "    and ZX5_TABELA = '" + ::CodTabela + "'"
		_oSQL:Log ()
		_sChave = _oSQL:RetQry (1, .F.)
		_sChave = iif (empty (_sChave), '01', soma1 (_sChave))

		reclock ("ZX5", .T.)
		zx5 -> zx5_filial = iif (::ModoAcesso == 'E', cFilAnt, '  ')
		zx5 -> zx5_tabela = ::CodTabela
		zx5 -> zx5_chave  = _sChave
		for _nDado = 1 to len (_aDados)
			zx5 -> &(_aDados [_nDado, 1]) = _aDados [_nDado, 2]
		next
		msunlock ()
	endif

	u_logFim (GetClassName (::Self) + '.' + procname ())
return _lContinua
//
// --------------------------------------------------------------------------
// Verifica se pode excluir a chave informada.
METHOD PodeExcl (_sChave) Class ClsTabGen
	local _aAreaAnt := U_ML_SRArea ()
	local _lRet     := .T.
	local _oSQL     := NIL

	CursorWait ()
	do case
		case ::CodTabela == '39'
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT COUNT (*)"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SB1") + " SB1"
			_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND B1_FILIAL  = '" + xfilial ("SB1") + "'"
			_oSQL:_sQuery +=    " AND B1_CODLIN  = '" + _sChave + "'"
			if _oSQL:RetQry () > 0
				u_help ("Registro encontra-se amarrado ao cadastro de produtos e nao pode ser excluido.")
				_lRet = .F.
			endif
		case ::CodTabela == '41'
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT COUNT (*)"
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SN1") + " SN1"
			_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND N1_FILIAL  = '" + xfilial ("SN1") + "'"
			_oSQL:_sQuery +=    " AND N1_VAZX541 = '" + _sChave + "'"
			if _oSQL:RetQry () > 0
				u_help ("Registro encontra-se amarrado ao cadastro de Ativos / Maquinas e nao pode ser excluido.")
				_lRet = .F.
			endif
	endcase

	CursorArrow ()
	U_ML_SRArea (_aAreaAnt)
return _lRet
