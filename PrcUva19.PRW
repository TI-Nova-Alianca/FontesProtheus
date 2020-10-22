// Programa:  PrcUva19
// Autor:     Robert Koch
// Data:      01/12/2018
// Descricao: Retorna os diferentes precos da uva para safra 2019.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Calcula precos de uvas para a safra 2019
// #PalavasChave      #preco_uva_safra
// #TabelasPrincipais #ZX5 #SB1
// #Modulos           #COOP

// Historico de alteracoes:
// 01/12/2018 - Robert - Criado com base no PrecoUva.prw pois vamos comecar a ter precos com decimais e fica
//                       inviavel cadastrar grau a grau na tabela SZ1.
// 26/02/2019 - Robert - Soh gera valores se tiver preco base (antes aplicava agio sobre zero e retornava valores).
// 18/06/2019 - Robert - Ajuste preço alicante bouschet (GLPI 6132).
//
// ----------------------------------------------------------------------------------------------------------

#include "VA_INCLU.prw"

user function PrcUva19 (_sFilial, _sProduto, _nGrau, _sClassif, _sConducao, _lRetArray)
	local _aAreaAnt  := U_ML_SRArea ()
	local _aRet      := {0,0,''}
	local _nPrcRec   := 0
	local _nPrcCom   := 0
	local _lContinua := .T.
	local _lIsabel   := .F.
	local _sComent   := ""
	local _oSQL      := NIL
	local _aGrupo    := {}
	local _nGrauBase := 0
	local _nPBasEntr := 0
	local _nPBasComp := 0
	local _nPBasAgiE := 0
	local _nPBasAgiC := 0
	local _nPerAgio  := 0
	local _nVlrAgioE := 0
	local _nVlrAgioC := 0
	local _aGraus    := {}
	local _nAux      := 0
	local _nPosGBase := 0
	local _nPosGrau  := 0
	local _nArred    := 4  // Arredondar o preco para no maximo X decimais.
	local _aGrausInt := {}
	local _nAgioOrg  := 0
	//local _nAgioEsp  := 0
	local _sProdBase := ""
	local _sGrpZX513 := ""

	//u_logIni ()
	if _lContinua
		_nGrau = round (_nGrau, 1)  // Por enquanto trabalhamos apenas com 1 decimal.
	endif

	if _lContinua
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
			_sComent += "Produto '" + _sProduto + "' nao encontrado no cadastro."
			_lContinua = .F.
		endif
	endif

	// Viniferas tem tratamento diferenciado conforme a filial onde sao recebidas, podendo inclusive
	// ser precificadas como outra variedade.
	if _lContinua
		//u_log ('Variedade solicitada: ', _sProduto, sb1 -> b1_desc)
		if sb1 -> b1_varuva == 'F'
			if _sFilial $ '01/09'
				_lIsabel = .T.
				_sComent += "Viniferas F01/F09: precifica como isabel(ttas) ou niagara(bcas)."
			elseif _sFilial == '07'
				if sb1 -> b1_vaFCUva == 'C'  // Forma de classificacao: classificar 'como comum'.
					_lIsabel = .T.
					_sComent += "Viniferas SC na F07: precifica como isabel(ttas) ou niagara(bcas)."
				else
				//	if sb1 -> b1_vacor == 'T' .and. _nGrau < 13
// ateh 18/06/2019					if sb1 -> b1_vacor == 'T' .and. _nGrau < 14
					if sb1 -> b1_vacor == 'T' .and. _nGrau < 14 .and. ! alltrim (sb1 -> b1_cod) $ '9969/9969A' // Alicante nao deve ser tratada como Isabel.
						_lIsabel = .T.
						_sComent += "Viniferas ttas na F07 abaixo 14 graus: precifica como isabel."
					endif
				//	elseif sb1 -> b1_vacor != 'T' .and. _nGrau < 11
// ateh 18/06/2019					if sb1 -> b1_vacor != 'T' .and. _nGrau < 11
					if (sb1 -> b1_vacor != 'T' .or. alltrim (sb1 -> b1_cod) $ '9969/9969A') .and. _nGrau < 11  // Alicante abaixo de 11 trata como Niagara.
						_lIsabel = .T.
						_sComent += "Viniferas bcas na F07 abaixo 11 graus: precifica como niagara."
					endif
					if _sConducao == 'L' .and. alltrim (_sClassif) == 'D'
						_lIsabel = .T.
						_sComent += "Viniferas latadas clas. " + _sClassif + ": precifica como isabel."
					endif
				endif
			endif
			if _lIsabel
				_sClassif = ''
				if sb1 -> b1_vacor == 'T' .and. ! alltrim (sb1 -> b1_cod) $ '9969/9969A' // Alicante vai ser tratada como uva branca.
					_sProduto = '9901           '  // Isabel
				else
					_sProduto = '9904           '  // Niagara branca
				endif
				if ! sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
					_sComent += "Produto '" + _sProduto + "' nao encontrado no cadastro."
					_lContinua = .F.
				else
					//u_log ('Variedade considerada:', _sProduto, alltrim (sb1 -> b1_desc), '(' + _sComent + ')')
				endif
			endif
		endif
	endif


	// Se for para espumante, organica ou em conversao, preciso buscar o produto base (uva convencional)
	// para depois aplicar % em cima desta.
	if _lContinua
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
			_sComent += "Produto '" + _sProduto + "' nao encontrado no cadastro."
			_lContinua = .F.
		else

			// Define o % a ser aplicado sobre o preco do produto base
			if sb1 -> b1_vaorgan $ 'BEO'  // [B]ordadura, [E]m conversao ou [O]rganica
				_nAgioOrg = iif (sb1 -> b1_vaorgan == 'E', 15, iif (sb1 -> b1_vaorgan == 'O', 60, 0))
				_sProdBase = sb1 -> b1_codpai
				if empty (_sProdBase)
					_sComent += "Uva '" + alltrim (_sProduto) + "': por tratar-se de organica/em conversao (ou para espumante), preciso ter o codigo base (convencional) informada no campo '" + alltrim (RetTitle ('B1_CODPAI')) + "' para calculo de preco."
					_lContinua = .F.
				endif
			endif
			/*
			if sb1 -> b1_vaUvaEsp == 'S'  // Para espumante
				_nAgioEsp = 20
				_sProdBase = sb1 -> b1_codpai
				if empty (_sProdBase)
					_sComent += "Uva '" + alltrim (_sProduto) + "': por tratar-se de organica/em conversao (ou para espumante), preciso ter o codigo base (convencional) informada no campo '" + alltrim (RetTitle ('B1_CODPAI')) + "' para calculo de preco."
					_lContinua = .F.
				endif
			endif
			*/
			if _lContinua .and. ! empty (_sProdBase)
				sb1 -> (dbsetorder (1))
				if ! sb1 -> (dbseek (xfilial ("SB1") + _sProdBase, .F.))
					_sComent += "Uva '" + alltrim (_sProduto) + "': o codigo base '" + alltrim (_sProdPai) + "' (convencional) informado no campo '" + alltrim (RetTitle ('B1_CODPAI')) + "' nao foi encontrado no cadastro."
					_lContinua = .F.
				else
//					_sComent += 'Calculando pelo produto base (' + alltrim (_sProdBase) + ' ' + ALLTRIM (sb1 -> b1_desc) + ') + agio ' + cvaltochar (_nAgioOrg + _nAgioEsp) + '%'
					_sComent += 'Calculando pelo produto base (' + alltrim (_sProdBase) + ' ' + ALLTRIM (sb1 -> b1_desc) + ') + agio ' + cvaltochar (_nAgioOrg) + '%'
					u_log (_sComent)
					_sProduto = _sProdBase
				endif
			endif
		endif
	endif


	// Busca preco base desta variedade.
	if _lContinua
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT ZX5_13.ZX5_13GBAS, ZX5_13.ZX5_13PBEN, ZX5_13.ZX5_13PBCO, ZX5_13.ZX5_13BAGE, ZX5_13.ZX5_13GRUP, ZX5_13.ZX5_13BAGC"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZX5") + " ZX5_13, "
		_oSQL:_sQuery +=             RetSQLName ("ZX5") + " ZX5_14 "
		_oSQL:_sQuery += " WHERE ZX5_13.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZX5_13.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=   " AND ZX5_13.ZX5_TABELA = '13'"
		_oSQL:_sQuery +=   " AND ZX5_13.ZX5_13SAFR = '2019'"
		_oSQL:_sQuery +=   " AND ZX5_14.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZX5_14.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=   " AND ZX5_14.ZX5_TABELA = '14'"
		_oSQL:_sQuery +=   " AND ZX5_14.ZX5_14SAFR = ZX5_13.ZX5_13SAFR"
		_oSQL:_sQuery +=   " AND ZX5_14.ZX5_14GRUP = ZX5_13.ZX5_13GRUP"
		_oSQL:_sQuery +=   " AND ZX5_14.ZX5_14PROD = '" + sb1 -> b1_cod + "'"
		
		// Uvas finas/viniferas: o sistema de conducao determina qual grupo de preco vai ser usado.
		if sb1 -> b1_varuva == 'F'
			if _sConducao == 'L'
				_oSQL:_sQuery += " AND ZX5_13.ZX5_13GRUP like '3%'"
			elseif _sConducao == 'E'
				_oSQL:_sQuery += " AND ZX5_13.ZX5_13GRUP like '2%'"
			endif
		endif

		//_oSQL:Log ()
		_aGrupo := aclone (_oSQL:Qry2Array (.F., .F.))
		//U_log (_aGrupo)
		if len (_aGrupo) == 0
			_sComent += "Produto '" + alltrim (sb1 -> b1_cod) + ' - ' + alltrim (sb1 -> b1_desc) + "' nao encontrado na tabela 14 (uvas X grupos) do arquivo ZX5, ou respectivo grupo nao cadastrado na tabela 13 para esta safra."
			_lContinua = .F.
		elseif len (_aGrupo) > 1
			_sComent += "Produto '" + alltrim (sb1 -> b1_cod) + ' - ' + alltrim (sb1 -> b1_desc) + "' encontrado MAIS DE UMA VEZ na tabela 14 (uvas X grupos) do arquivo ZX5, ou respectivo grupo cadastrado MAIS DE UMA VEZ na tabela 13 para esta safra."
			_lContinua = .F.
		else
			_nGrauBase = _aGrupo [1, 1]
			_nPBasEntr = _aGrupo [1, 2]
			_nPBasComp = _aGrupo [1, 3]
			_nPBasAgiE = _aGrupo [1, 4]
			_sGrpZX513 = _aGrupo [1, 5]
			_nPBasAgiC = _aGrupo [1, 6]
			if _nGrauBase <= 0
				_sComent += "Grau base vazio ou invalido para o produto '" + alltrim (sb1 -> b1_cod) + ' - ' + alltrim (sb1 -> b1_desc) + "' na tabela 13 (grupos de uvas) do arquivo ZX5 para esta safra."
				_lContinua = .F.
			endif
			if _nPBasAgiE <= 0
				_sComent += "Valor base para composicao do % de agio nas entradas encontra-se vazio ou invalido para o grupo '" + _sGrpZX513 + "' na tabela 13 (grupos de uvas) do arquivo ZX5 para esta safra."
				_lContinua = .F.
			endif
			if _nPBasAgiC <= 0
				_sComent += "Valor base para composicao do % de agio nas compras encontra-se vazio ou invalido para o grupo '" + _sGrpZX513 + "' na tabela 13 (grupos de uvas) do arquivo ZX5 para esta safra."
				_lContinua = .F.
			endif
		endif
	endif

	// Calcula preco a partir de aplicacao de agio / desagio sobre o preco do grau base.
	if _lContinua
		//u_log ('Grau:', _nGrau, '  grau base:', _nGrauBase, '  Prc.grau base:', _nPBasEntr, '(entr)   ', _nPBasComp, '(compra)   ', _nPBasAgiE, '(base p/agio)   grupo ZX513:', _sGrpZX513)

		// Gera lista com todos os graus e agios a aplicar, para facilitar o calculo.
		_aGraus = {}
		_nAux = 6  // Caso precise um grau menor, pode-se alterar aqui
		do while _nAux <= 26  // Caso precise um grau maior, pode-se alterar aqui
			if _nAux == _nGrauBase
				_nPerAgio = 0
			elseif _nAux < _nGrauBase
				if int (_nGrauBase) - int (_nAux) <= 1
					_nPerAgio = 5
				elseif int (_nGrauBase) - int (_nAux) <= 2
					_nPerAgio = 10
				else
					_nPerAgio = 15
				endif
			elseif _nAux > _nGrauBase
				if _nAux == _nGrauBase
					_nPerAgio = 0
				elseif _nAux - _nGrauBase <= 1
					_nPerAgio = 5
				elseif _nAux - _nGrauBase <= 2
					_nPerAgio = 10
				else
					_nPerAgio = 15
				endif
			endif
			//aadd (_aGraus, {_nAux, _nPerAgio, 0, 0})
			aadd (_aGraus, {0,0,0,0,0,0})
			_aGraus [len (_aGraus), .PrcUvaColGrau] = _nAux
//			_aGraus [len (_aGraus), .PrcUvaColPercentualAgio] = _nPerAgio
			_aGraus [len (_aGraus), .PrcUvaColPercAgioAlianca] = _nPerAgio
			_nAux += 0.1
		enddo

		// Atualiza preco do grau base na lista de graus.
//		_nPosGBase = ascan (_aGraus, {|_x| _x [1] == _nGrauBase})
//		_aGraus [_nPosGBase, 3] = _nPBasEntr
//		_aGraus [_nPosGBase, 4] = _nPBasComp
		_nPosGBase = ascan (_aGraus, {|_x| _x [.PrcUvaColGrau] == _nGrauBase})
		if _nPosGBase == 0
			_sComent += "Grau base " + cvaltochar (_nGrauBase) + " nao se encontra na array de graus. Revise o programa " + procname ()
			_lContinua = .F.
		else
			_aGraus [_nPosGBase, .PrcUvaColPrcEntrada] = _nPBasEntr
			_aGraus [_nPosGBase, .PrcUvaColPrcCompra]  = _nPBasComp
		endif
	endif

	if _lContinua
		// Aplica percentual de agio 'do grau base para os graus menores'
		for _nAux = _nPosGBase - 1 to 1 step -1
//			_nVlrAgioE = round (_nPBasAgiE * _aGraus [_nAux, .PrcUvaColPercentualAgio] / 100 / 10, 5)
			_nVlrAgioE = round (_nPBasAgiE * _aGraus [_nAux, .PrcUvaColPercAgioAlianca] / 100 / 10, 5)
//			_nVlrAgioC = round (_nPBasAgiC * _aGraus [_nAux, .PrcUvaColPercentualAgio] / 100 / 10, 5)
			_nVlrAgioC = round (_nPBasAgiC * _aGraus [_nAux, .PrcUvaColPercAgioAlianca] / 100 / 10, 5)
			_aGraus [_nAux, .PrcUvaColVlrAgioEntrada] = _nVlrAgioE
			_aGraus [_nAux, .PrcUvaColVlrAgioCompra]  = _nVlrAgioC
//			_aGraus [_nAux, 3] = round (_aGraus [_nAux + 1, 3] - _nPBasAgiE * _aGraus [_nAux, 2] / 1000, _nArred)
			_aGraus [_nAux, .PrcUvaColPrcEntrada] = _aGraus [_nAux + 1, .PrcUvaColPrcEntrada] - _nVlrAgioE
//			_aGraus [_nAux, 4] = round (_aGraus [_nAux + 1, 4] - _nPBasAgiE * _aGraus [_nAux, 2] / 1000, _nArred)
			_aGraus [_nAux, .PrcUvaColPrcCompra] = _aGraus [_nAux + 1, .PrcUvaColPrcCompra] - _nVlrAgioC
		next

		// Aplica percentual de agio 'do grau base para os maiores'
		for _nAux = _nPosGBase + 1 to len (_aGraus)
//			_nVlrAgioE = round (_nPBasAgiE * _aGraus [_nAux, .PrcUvaColPercentualAgio] / 100 / 10, 5)
			_nVlrAgioE = round (_nPBasAgiE * _aGraus [_nAux, .PrcUvaColPercAgioAlianca] / 100 / 10, 5)
//			_nVlrAgioC = round (_nPBasAgiC * _aGraus [_nAux, .PrcUvaColPercentualAgio] / 100 / 10, 5)
			_nVlrAgioC = round (_nPBasAgiC * _aGraus [_nAux, .PrcUvaColPercAgioAlianca] / 100 / 10, 5)
			_aGraus [_nAux, .PrcUvaColVlrAgioEntrada] = _nVlrAgioE
			_aGraus [_nAux, .PrcUvaColVlrAgioCompra]  = _nVlrAgioC
//			_aGraus [_nAux, 3] = round (_aGraus [_nAux - 1, 3] + _nPBasAgiE * _aGraus [_nAux, 2] / 1000, _nArred)
			_aGraus [_nAux, .PrcUvaColPrcEntrada] = _aGraus [_nAux - 1, .PrcUvaColPrcEntrada] + _nVlrAgioE
//			_aGraus [_nAux, 4] = round (_aGraus [_nAux - 1, 4] + _nPBasAgiE * _aGraus [_nAux, 2] / 1000, _nArred)
			_aGraus [_nAux, .PrcUvaColPrcCompra] = _aGraus [_nAux - 1, .PrcUvaColPrcCompra] + _nVlrAgioC
		next

		// Aplica % de agio das organicas, se for o caso
		if _nAgioOrg > 0
			//u_log ('Aplicando agio (organica/em conversao) de', _nAgioOrg)
			for _nAux = 1 to len (_aGraus)
//				_aGraus [_nAux, 3] = _aGraus [_nAux, 3] + _aGraus [_nAux, 3] * _nAgioOrg / 100
				_aGraus [_nAux, .PrcUvaColPrcEntrada] = _aGraus [_nAux, .PrcUvaColPrcEntrada] + _aGraus [_nAux, .PrcUvaColPrcEntrada] * _nAgioOrg / 100
//				_aGraus [_nAux, 4] = _aGraus [_nAux, 4] + _aGraus [_nAux, 4] * _nAgioOrg / 100
				_aGraus [_nAux, .PrcUvaColPrcCompra] = _aGraus [_nAux, .PrcUvaColPrcCompra] + _aGraus [_nAux, .PrcUvaColPrcCompra] * _nAgioOrg / 100
			next
		endif
		
		// Aplica % de agio de uva para espumante, se for o caso
		/*
		if _nAgioEsp > 0
			u_log ('Aplicando agio (espumantes) de', _nAgioEsp)
			for _nAux = 1 to len (_aGraus)
//				_aGraus [_nAux, 3] = _aGraus [_nAux, 3] + _aGraus [_nAux, 3] * _nAgioEsp / 100
				_aGraus [_nAux, .PrcUvaColPrcEntrada] = _aGraus [_nAux, .PrcUvaColPrcEntrada] + _aGraus [_nAux, .PrcUvaColPrcEntrada] * _nAgioEsp / 100
//				_aGraus [_nAux, 4] = _aGraus [_nAux, 4] + _aGraus [_nAux, 4] * _nAgioEsp / 100
				_aGraus [_nAux, .PrcUvaColPrcCompra] = _aGraus [_nAux, .PrcUvaColPrcCompra] + _aGraus [_nAux, .PrcUvaColPrcCompra] * _nAgioEsp / 100
			next
		endif
		*/


		// Encontra, na array de graus gerada, o grau solicitado e prepara variaveis para retorno.
//		_nPosGrau = ascan (_aGraus, {|_x| _x [1] == _nGrau})
		_nPosGrau = ascan (_aGraus, {|_x| _x [.PrcUvaColGrau] == _nGrau})
		if _nPosGrau == 0
			_sComent += "Grau solicitado (" + cvaltochar (_nGrau) + ") fora da faixa de calculo."
			_lContinua = .F.
		else
//			_nPrcRec = _aGraus [_nPosGrau, 3]
//			_nPrcCom = _aGraus [_nPosGrau, 3]
			_nPrcRec = iif (_nPBasEntr > 0, _aGraus [_nPosGrau, .PrcUvaColPrcEntrada], 0)  // Para nao devolver suujeira caso falte o preco do grau base.
			_nPrcCom = iif (_nPBasComp > 0, _aGraus [_nPosGrau, .PrcUvaColPrcCompra], 0)  // Para nao devolver suujeira caso falte o preco do grau base.
		endif
	endif

//	u_log (_aGraus)

	// Gera array de precos para uso em rotina externa.
	if _lRetArray != NIL .and. _lRetArray
		_aGrausInt = {}
		for _nAux = 1 to len (_aGraus)
			aadd (_aGrausInt, aclone (_aGraus [_nAux]))
		next
	endif
//	u_log (_aGrausInt)

	// Aplica acrescimos ou decrescimos conforme a classificacao da uva.
	if _lContinua
	
		// O preco de compra, para uvas finas, varia conforme a sua classificacao final.
//		if sb1 -> B1_VARUVA == "F" .and. sb1 -> B1_VAFCUVA == "F"
		if sb1 -> B1_VARUVA == "F" .and. sb1 -> B1_VAFCUVA == "F" .and. ! _lIsabel
			//u_log ('Forma de conducao....:', _sConducao)
			//u_log ('Classificacao........:', _sClassif)
			if _sConducao == 'E'  // Espaldeira
				do case
				case alltrim (_sClassif) == "PR"
					_nPrcRec *= 1.4  // Ainda nao tenho certeza deste percentual
					_nPrcCom *= 1.4  // Ainda nao tenho certeza deste percentual
				case alltrim (_sClassif) == "AA"
					_nPrcRec *= 1.4
					_nPrcCom *= 1.4
				case alltrim (_sClassif) == "A"
					_nPrcRec *= 1.2
					_nPrcCom *= 1.2
				case alltrim (_sClassif) == "B"
					_nPrcRec *= 1
					_nPrcCom *= 1
				case alltrim (_sClassif) == "C"
					_nPrcRec *= 0.8
					_nPrcCom *= 0.8
				case alltrim (_sClassif) == "D"
					_nPrcRec *= 0.6
					_nPrcCom *= 0.6
				case alltrim (_sClassif) == "DS"
					_nPrcRec *= 0.5
					_nPrcCom *= 0.5
				otherwise
					u_help ('[' + procname () + '] Sem tratamento para classificacao ' + _sClassif + ' e sistema de conducao ' + _sConducao)
					_nPrcRec = 0
					_nPrcCom = 0
				endcase
			elseif _sConducao == 'L'  // Latada
				do case
				case alltrim (_sClassif) == "A"
					_nPrcRec *= 1.1
					_nPrcCom *= 1.1
				case alltrim (_sClassif) == "B"
					_nPrcRec *= 1
					_nPrcCom *= 1
// Jah caiu como isabel				case alltrim (_sClassif) == "D"
// Jah caiu como isabel					_nPrcRec *= 0.9
// Jah caiu como isabel					_nPrcCom *= 0.9
				otherwise
					u_help ('[' + procname () + '] Sem tratamento para classificacao ' + _sClassif + ' e sistema de conducao ' + _sConducao)
					_nPrcRec = 0
					_nPrcCom = 0
				endcase
			else
				_sComent += "Sem tratamento para o sistema de conducao '" + _sConducao + "'."
				_nPrcRec = 0
				_nPrcCom = 0
			endif
		endif
	endif

	// Monta array para retorno dos dados.
	if _lContinua
		_aRet = {round (_nPrcRec, _nArred), round (_nPrcCom, _nArred), _sComent, _aGrausInt}
	else
		u_help (_sComent)
		_aRet = {0, 0, _sComent, _aGrausInt}
	endif

	//u_log ('Preco entrada:', _aRet [1], '   compra:', _aRet [2], '   coment: ' + _aRet [3])
	U_ML_SRArea (_aAreaAnt)
	//u_logFim ()
return _aRet
