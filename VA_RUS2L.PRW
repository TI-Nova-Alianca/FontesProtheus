// Programa...: VA_RUS2L
// Autor......: Robert Koch
// Data.......: 03/01/2020
// Descricao..: Validacao 'linha OK' da tela VA_RUS2 (recebimento safra)
//              Desmembrada do programa VA_RUS2.PRW
//
// Historico de alteracoes:
// 29/01/2020 - Robert - Bloqueia cadastro viticula nao recebido fisicamente apos outubro do ano anterior.
// 20/02/2020 - Robert - Desabilitada validacao de chave duplicada no ZF_IDSZ9 (cadastros estao desatualizados, nao ajuda em nada. Vai ser passado para NaWeb)
// 05/01/2022 - Robert - Eliminados campos ZF_NCONF03 e ZF_NCONF04.
//

#include "totvs.ch"
#include "VA_Inclu.prw"

// --------------------------------------------------------------------------
user function VA_RUS2L ()
	local _lRet      := .T.
	local _sVarUva   := ""
	local _nVarPeso  := 0
	local _aCampos   := {}
	local _nVitic    := 0
	local _sFormClas := ""
	local _lParaEsp  := .F.
	local _oSQL      := NIL
	local _aLimEspum := {}
	local _sUvaBase  := ''

	if _lRet .and. m->ze_aglutin == "D" .and. GDDeleted ()
		u_help ("Nao eh permitido alterar itens de cargas aglutinadas",, .T.)
		_lRet = .F.
	endif

	if _lRet .and. altera .and. ! GDDeleted ()
		if GDFieldGet ("ZF_PRREAL") == GDFieldGet ("ZF_PRODUTO")
			u_help (alltrim (RetTitle ("ZF_PRREAL")) + ' nao pode ser a mesma informado no campo ' + alltrim (RetTitle ("ZF_PRODUTO")),, .T.)
			_lRet = .F.
		endif
	endif

	_sVarUva   = fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("ZF_PRODUTO"), "B1_VARUVA")
	_sFormClas = fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("ZF_PRODUTO"), "B1_VAFCUVA")
	_lParaEsp  = (fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("ZF_PRODUTO"), "B1_VAUVAES") == 'S')

	// Verifica campos obrigatorios
	if _lRet .and. (inclui .or. altera) .and. ! GDDeleted ()
		_lRet = MaCheckCols (aHeader, aCols, N, {})

		// Gera retorno de erro em caso de chamada via web service
		if ! _lRet
			u_help ('Falta informar algum campo obrigatorio nos itens',, .t.)
		endif
	endif

	if _lRet .and. altera .and. ! GDDeleted () .and. ! empty (GDFieldGet ("ZF_GRAU"))
		if ! IsDigit (substr (GDFieldGet ("ZF_GRAU"), 1, 1)) .or. ! IsDigit (substr (GDFieldGet ("ZF_GRAU"), 2, 1)) .or. substr (GDFieldGet ("ZF_GRAU"), 3, 1) != '.' .or. ! IsDigit (substr (GDFieldGet ("ZF_GRAU"), 4, 1))
			u_help ("Valor do grau deve ser informado no formato 99.9",, .T.)
			_lRet = .F.
		endif
	endif

	if _lRet .and. altera .and. ! GDDeleted ()
		if GDFieldGet ("ZF_QTEMBAL") == 0 .or. GDFieldGet ("ZF_PESO") == 0 .or. empty (GDFieldGet ("ZF_EMBALAG")) .or. val (GDFieldGet ("ZF_GRAU")) == 0
			u_help ("Quantidades, embalagens e graus devem ser informados.",, .t.)
			_lRet = .F.
		endif
	endif

	if _lRet .and. (inclui .or. altera) .and. ! GDDeleted () .and. ! _sVarUva $ "CF"
		u_help ("Tipo da uva (Comum/Fina) e' invalida. Verifique cadastro do produto.",, .t.)
		_lRet = .F.
  	endif

   	// Verifica preenchimento das classificacoes de uvas.
   	if _lRet .and. altera .and. ! GDDeleted ()
		if GDFieldGet ("ZF_CONDUC") == 'E'
			if empty (GDFieldGet ("ZF_PRM02"))
				u_help ("Uva em espaldeira: campo '" + alltrim (RetTitle ("ZF_PRM02")) + "' deve ser informado.",, .t.)
				_lRet = .F.
			endif
			if empty (GDFieldGet ("ZF_PRM03"))
				u_help ("Uva em espaldeira: campo '" + alltrim (RetTitle ("ZF_PRM03")) + "' deve ser informado.",, .t.)
				_lRet = .F.
			endif
			if empty (GDFieldGet ("ZF_PRM04"))
				u_help ("Uva em espaldeira: campo '" + alltrim (RetTitle ("ZF_PRM04")) + "' deve ser informado.",, .t.)
				_lRet = .F.
			endif
			if empty (GDFieldGet ("ZF_PRM05"))
				u_help ("Uva em espaldeira: campo '" + alltrim (RetTitle ("ZF_PRM05")) + "' deve ser informado.",, .t.)
				_lRet = .F.
			endif
			if empty (GDFieldGet ("ZF_PRM99"))
				u_help ("Uvas em espaldeira: classificacao final deve ser informada no campo '" + alltrim (RetTitle ("ZF_PRM99")) + "'.",, .t.)
				_lRet = .F.
			endif
			if ! empty (GDFieldGet ("ZF_CLASABD"))
				u_help ("Uvas em espaldeira: classificacao final NAO deve ser informada no campo '" + alltrim (RetTitle ("ZF_CLASABD")) + "'.",, .t.)
				_lRet = .F.
			endif
		elseif GDFieldGet ("ZF_CONDUC") == 'L'
			if empty (GDFieldGet ("ZF_CLASABD"))
				u_help ("Uvas latadas: classificacao final deve ser informada no campo '" + alltrim (RetTitle ("ZF_CLASABD")) + "'.",, .t.)
				_lRet = .F.
			endif
   			if ! empty (GDFieldGet ("ZF_PRM99"))
				u_help ("Uvas latadas: classificacao final NAO deve ser informada no campo '" + alltrim (RetTitle ("ZF_PRM99")) + "'.",, .t.)
				_lRet = .F.
			endif
		endif
	endif

	// Verifica linhas duplicadas
	if _lRet .and. (inclui .or. altera) .and. ! GDDeleted ()
	//	_lRet = GDCheckKey ({"ZF_CADVITI", "ZF_PRODUTO", "ZF_GRAU", "ZF_PRM02", "ZF_PRM03", "ZF_PRM04", "ZF_PRM05", "ZF_PRM99", "ZF_CLASABD", "ZF_NCONF01", "ZF_NCONF02", "ZF_NCONF03", "ZF_NCONF04", "ZF_IDZA8"}, 4)
		_lRet = GDCheckKey ({"ZF_CADVITI", "ZF_PRODUTO", "ZF_GRAU", "ZF_PRM02", "ZF_PRM03", "ZF_PRM04", "ZF_PRM05", "ZF_PRM99", "ZF_CLASABD", "ZF_NCONF01", "ZF_NCONF02", "ZF_IDZA8"}, 4)

		// Gera retorno de erro em caso de chamada via web service
		if ! _lRet
			u_help ('Linha duplicada',, .t.)
		endif

	endif

	// Verifica se o produto consta no cadastro viticola.
	if _lRet .and. (inclui .or. altera) .and. ! GDDeleted () .and. m->ze_coop $ '00136901/00002101'

		// Se for uva para espumante, o que vai estar no cadastro viticola vai ser o a vriedade base (para vinho)
		if _lParaEsp
			_sUvaBase = fBuscaCpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("ZF_PRODUTO"), "B1_CODPAI")
			_nVitic = ascan (_aCadVitic, {|_aVal| alltrim (_aVal [.CadVitCodigo]) == alltrim (GDFieldGet ("ZF_CADVITI")) .and. alltrim (_aVal [.CadVitProduto]) == alltrim (_sUvaBase)})
		else
			_nVitic = ascan (_aCadVitic, {|_aVal| alltrim (_aVal [.CadVitCodigo]) == alltrim (GDFieldGet ("ZF_CADVITI")) .and. alltrim (_aVal [.CadVitProduto]) == alltrim (GDFieldGet ("ZF_PRODUTO"))})
		endif

		if _nVitic == 0
			_lRet = .F.

			// Se estiver rodando via web service jah retorna erro
			if IsInCallStack ("U_GERASZE")
				u_help ('Produto ' + GDFieldGet ("ZF_PRODUTO") + ' nao encontrado no cadastro viticola ' + GDFieldGet ("ZF_CADVITI"),, .t.)
			else
				_aCampos = {}
				aadd (_aCampos, {.CadVitCodigo,  "Cad.viticola",  50,  ""})
				aadd (_aCampos, {.CadVitDescMun, "Municipio",     80,  ""})
				aadd (_aCampos, {.CadVitProduto, "Variedade",     60,  ""})
				aadd (_aCampos, {.CadVitDescPro, "Descricao",    100,  ""})
				U_F3Array (_aCadVitic, "Variedade nao ligada ao cadastro viticola.", _aCampos, 700, 400, "As combinacoes de cadastro viticola X variedades para este associado sao:", "Verifique cadastro viticola e patriarca.", .F.)
			endif
		else
		//	if _aCadVitic [_nVitic, .CadVitSafrVit] < m->ze_safra
			if val (_aCadVitic [_nVitic, .CadVitSafrVit]) < (val (m->ze_safra) - 1)  // A partir de 2021 consideramos que "foi revisado durante o ano de 2020 para a safra 2021"
				u_help ("ATENCAO: Cadastro viticola nao renovado para esta safra! Verifique no NaWeb as datas dos mapeamentos da propriedade rural " + _aCadVitic [_nVitic, .CadVitCodigo],, .T.)
			endif

			if _aCadVitic [_nVitic, .CadVitOrganico] == "O" .and. _zx509orga != 'S'
				u_help ("Nao ha previsao de recebimento de uvas organicas nesta balanca.",, .t.)
				_lRet = .F.
			endif
		endif
	Endif

	// Exige quantidades zeradas em linhas deletadas por causa da distribuicao de peso por embalagem
	if _lRet .and. (inclui .or. altera) .and. GDDeleted () .and. (GDFieldGet ("ZF_QTEMBAL") != 0 .or. GDFieldGet ("ZF_PESO") != 0)
		u_help ("Quando excluir uma linha, deixe as quantidades zeradas.",, .t.)
		_lRet = .F.
	endif
 
	// Verifica peso por caixa
	if _lRet .and. (inclui .or. altera) .and. ! GDDeleted () .and. GDFieldGet ("ZF_EMBALAG") == "CAIXAS"
		_nVarPeso = GDFieldGet ("ZF_PESO") / GDFieldGet ("ZF_QTEMBAL") * 100 / _nPesoEmb
		if _nVarPeso < 80 .or. _nVarPeso > 120  // Ateh 20% de tolerancia.
			_lRet = u_msgnoyes ("Peso por caixa fora da tolerancia." + chr (13) + chr (10) + chr (13) + chr (10) + ;
								"Peso calculado: " + cvaltochar (GDFieldGet ("ZF_PESO") / GDFieldGet ("ZF_QTEMBAL")) + ' Kg' + chr (13) + chr (10) + ;
								"Peso padrao: " + cvaltochar (_nPesoEmb) + ' Kg' + chr (13) + chr (10) + chr (13) + chr (10) + ;
								"Confirma assim mesmo?")
		endif
	endif

	if _lRet .and. (inclui .or. altera) .and. _sVarUva == "F" .and. _zx509fina == '1'
		u_help ("Balanca nao autorizada a receber uvas finas, mesmo que 'classificadas como comuns'.",, .T.)
		_lRet = .F.
	endif
	if _lRet .and. (inclui .or. altera) .and. _sVarUva == "F" .and. _sFormClas == 'F' .and. _zx509fina == '4'
		u_help ("Nao ha previsao de entrada de uvas finas com classificacao nesta balanca. Para receber uvas finas aqui, as mesmas devem ser 'sem classificacao'",, .T.)
		_lRet = .F.
	endif
	if _lRet .and. (inclui .or. altera) .and. ! GDDeleted ()
//		if (! empty (GDFieldGet ("ZF_NCONF01")) .and. GDFieldGet ("ZF_NCONF01") == GDFieldGet ("ZF_NCONF02")) ;
//			.or. (! empty (GDFieldGet ("ZF_NCONF01")) .and. GDFieldGet ("ZF_NCONF01") == GDFieldGet ("ZF_NCONF03")) ;
//			.or. (! empty (GDFieldGet ("ZF_NCONF01")) .and. GDFieldGet ("ZF_NCONF01") == GDFieldGet ("ZF_NCONF04")) ;
//			.or. (! empty (GDFieldGet ("ZF_NCONF02")) .and. GDFieldGet ("ZF_NCONF02") == GDFieldGet ("ZF_NCONF03")) ;
//			.or. (! empty (GDFieldGet ("ZF_NCONF02")) .and. GDFieldGet ("ZF_NCONF02") == GDFieldGet ("ZF_NCONF04")) ;
//			.or. (! empty (GDFieldGet ("ZF_NCONF03")) .and. GDFieldGet ("ZF_NCONF03") == GDFieldGet ("ZF_NCONF04"))
//			u_help ("Nao conformidades repetidas.",, .t.)
//			_lRet = .F.
//		endif
		if ! empty (GDFieldGet ("ZF_NCONF01")) .and. GDFieldGet ("ZF_NCONF01") == GDFieldGet ("ZF_NCONF02")
			u_help ("Nao conformidades repetidas.",, .t.)
			_lRet = .F.
		endif
	endif

	// Verifica faixas de graus permitidas para uvas para espumante.
	if _lRet .and. ! GDDeleted () .and. val (GDFieldGet ("ZF_GRAU")) > 0 .and. _lParaEsp
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT ZX5_17GIES, ZX5_17GFES"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZX5") + " ZX5_17 "
		_oSQL:_sQuery += " WHERE ZX5_17.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZX5_17.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=   " AND ZX5_17.ZX5_TABELA = '17'"
		_oSQL:_sQuery +=   " AND ZX5_17.ZX5_17SAFR = '" + m->ze_safra + "'"
		_oSQL:_sQuery +=   " AND ZX5_17.ZX5_17PROD = '" + GDFieldGet ("ZF_PRODUTO") + "'"
		_oSQL:Log ()
		_aLimEspum = aclone (_oSQL:Qry2Array (.F., .F.))
		if len (_aLimEspum) == 0
			u_help ("Variedade '" + alltrim (GDFieldGet ("ZF_PRODUTO")) + "': Nao foi possivel verificar na tabela 17 os limites de grau para uvas destinadas a espumantes nesta safra.",, .t.)
			_lRet = .F.
		elseif len (_aLimEspum) > 1
			u_help ("Variedade '" + alltrim (GDFieldGet ("ZF_PRODUTO")) + "': Encontrei mais de um registro na tabela 17 (limites de grau para uvas destinadas a espumantes) para esta safra.",, .t.)
			_lRet = .F.
		else
			if val (GDFieldGet ("ZF_GRAU")) < val (_aLimEspum [1, 1]) .or. val (GDFieldGet ("ZF_GRAU")) > val (_aLimEspum [1, 2])
				u_help ("Para que esta variedade seja aceita como 'para espumante' o grau deve ficar entre " + cvaltochar (val (_aLimEspum [1, 1])) + " e " + cvaltochar (val (_aLimEspum [1, 2])) + " (restricao conforme tabela 17 do arquivo ZX5)",, .t.)
				_lRet = .F.
			endif
		endif
	endif

	if _lRet .and. inclui .and. m->ze_aglutin != 'D' .and. ! GDDeleted ()
		if GDFieldGet ("ZF_PESO") != 0 ;
			.or. ! empty (GDFieldGet ("ZF_GRAU")) ;
			.or. ! empty (GDFieldGet ("ZF_PRM02")) ;
			.or. ! empty (GDFieldGet ("ZF_PRM03")) ;
			.or. ! empty (GDFieldGet ("ZF_PRM04")) ;
			.or. ! empty (GDFieldGet ("ZF_PRM05")) ;
			.or. ! empty (GDFieldGet ("ZF_PRM99")) ;
			.or. ! empty (GDFieldGet ("ZF_CLASABD"))
			u_help ("Quantidades, graus e classificacoes so devem ser informadas na segunda pesagem.",, .T.)
			_lRet = .F.
		endif
	endif
return _lRet
