// Programa:  PrcUva21
// Autor:     Robert Koch
// Data:      16/10/2020
// Descricao: Retorna os diferentes precos da uva para safra 2021.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Calcula precos de uvas para a safra 2021
// #PalavasChave      #preco_uva_safra
// #TabelasPrincipais #ZX5 #SB1
// #Modulos           #COOP

// Historico de alteracoes:
// 16/10/2020 - Robert - Copiado do PrcUva20 para uma simulacao inicial como se fosse 2021.
//

#include "VA_INCLU.prw"

// --------------------------------------------------------------------------
user function PrcUva21 (_sFilial, _sProduto, _nGrau, _sClassif, _sConducao, _lRetArray)
	local _aAreaAnt  := U_ML_SRArea ()
	local _aRet      := {}
	local _nPrcRec   := 0
	local _nPrcCom   := 0
	local _lContinua := .T.
	local _lIsabel   := .F.
	local _sComent   := ""
	local _oSQL      := NIL
	local _aGrupo    := {}
	local _nGBaseAli := 0
	local _nGBaseMOC := 0
	local _nPBasEntr := 0
	local _nPBasComp := 0
	local _nPBasAgiE := 0
	local _nPBasAgiC := 0
	local _nPerAgAli := 0
	local _nPerAgMOC := 0
	local _nVlrAgioE := 0
	local _nVlrAgioC := 0
	local _nVlrAgioM := 0
	local _aGraus    := {}
	local _nAux      := 0
	local _nPosGBase := 0
	local _nPosGrau  := 0
	local _nArredEnt := 4  // Arredondar o preco para no maximo X decimais.
	local _nArredCom := 4  // Arredondar o preco para no maximo X decimais.
	local _nArredMOC := 4  // Arredondar o preco para no maximo X decimais.
	local _aGrausInt := {}
	local _nAgioOrg  := 0
	local _sProdBase := ""
	local _sGrpZX513 := ""
	local _sGrpZX5MO := ""
	local _nPBaseMOC := 0
	local _nVlrMenor := 0
	local _nVlrMaior := 0
	local _nContador := 0

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
//		u_log2 ('info', 'Variedade solicitada: ' + _sProduto + ' ' + alltrim (sb1 -> b1_desc))
		if sb1 -> b1_varuva == 'F'
			if _sFilial $ '01/09'
				_lIsabel = .T.
				_sComent += "Viniferas F01/F09: precifica como isabel(ttas) ou niagara(bcas)."
			elseif _sFilial == '07'
				if sb1 -> b1_vaFCUva == 'C'  // Forma de classificacao: classificar 'como comum'.
					_lIsabel = .T.
					_sComent += "Viniferas SC na F07: precifica como isabel(ttas) ou niagara(bcas)."
				else
					if sb1 -> b1_vacor == 'T' .and. _nGrau < 14 .and. ! alltrim (sb1 -> b1_cod) $ '9969/9969A' // Alicante nao deve ser tratada como Isabel.
						_lIsabel = .T.
						_sComent += "Viniferas ttas na F07 abaixo 14 graus: precifica como isabel."
					endif
					if (sb1 -> b1_vacor != 'T' .or. alltrim (sb1 -> b1_cod) $ '9969/9969A') .and. _nGrau < 11  // Alicante abaixo de 11 trata como Niagara.
						_lIsabel = .T.
						_sComent += "Viniferas bcas na F07 abaixo 11 graus: precifica como niagara."
					endif
					if _sConducao == 'L' .and. alltrim (_sClassif) == 'DS'  //'D'
						_lIsabel = .T.
						_sComent += "Viniferas latadas clas. " + _sClassif + ": precifica como niagara/isabel."
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
					u_log2 ('info', 'Variedade considerada: ' + _sProduto + ' ' + alltrim (sb1 -> b1_desc) + '(' + _sComent + ')')
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
				// 2019 --> _nAgioOrg = iif (sb1 -> b1_vaorgan == 'E', 15, iif (sb1 -> b1_vaorgan == 'O', 60, 0))
				_nAgioOrg = 0
				if sb1 -> b1_vaorgan == 'E'
					_nAgioOrg = 15
				elseif sb1 -> b1_vaorgan == 'O'
					if sb1 -> b1_vacor == 'T' .and. sb1 -> b1_vattr == 'S'  // Tintorias
						_nAgioOrg = 55
					else
						_nAgioOrg = 70
					endif
				endif
				
				_sProdBase = sb1 -> b1_codpai
				if empty (_sProdBase)
					_sComent += "Uva '" + alltrim (_sProduto) + "': por tratar-se de organica/em conversao (ou para espumante), preciso ter o codigo base (convencional) informada no campo '" + alltrim (RetTitle ('B1_CODPAI')) + "' para calculo de preco."
					_lContinua = .F.
				endif
			endif

			if _lContinua .and. ! empty (_sProdBase)
				sb1 -> (dbsetorder (1))
				if ! sb1 -> (dbseek (xfilial ("SB1") + _sProdBase, .F.))
					_sComent += "Uva '" + alltrim (_sProduto) + "': o codigo base '" + alltrim (_sProdPai) + "' (convencional) informado no campo '" + alltrim (RetTitle ('B1_CODPAI')) + "' nao foi encontrado no cadastro."
					_lContinua = .F.
				else
					_sComent += 'Calculando prc.uva pelo prod.base (' + alltrim (_sProdBase) + ' ' + ALLTRIM (sb1 -> b1_desc) + ') + agio ' + cvaltochar (_nAgioOrg) + '%'
					//u_log2 ('info', _sComent)
					_sProduto = _sProdBase
				endif
			endif
		endif
	endif


	if _lContinua

		// Busca precos base (de entrada e de compra) desta variedade.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT ZX5_13.ZX5_13GBAS, ZX5_13.ZX5_13PBEN, ZX5_13.ZX5_13PBCO, ZX5_13.ZX5_13BAGE, ZX5_13.ZX5_13GRUP, ZX5_13.ZX5_13BAGC"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZX5") + " ZX5_13, "
		_oSQL:_sQuery +=             RetSQLName ("ZX5") + " ZX5_14 "
		_oSQL:_sQuery += " WHERE ZX5_13.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZX5_13.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=   " AND ZX5_13.ZX5_TABELA = '13'"
		_oSQL:_sQuery +=   " AND ZX5_13.ZX5_13GRUP NOT LIKE 'M%'"  // Ignorar tabela 'MOC'
		_oSQL:_sQuery +=   " AND ZX5_13.ZX5_13SAFR = '2021'"
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
		_oSQL:Log ()
		_aGrupo := aclone (_oSQL:Qry2Array (.F., .F.))
	//	U_log2 ('debug', _aGrupo)
		if len (_aGrupo) == 0
			_sComent += "Produto '" + alltrim (sb1 -> b1_cod) + ' - ' + alltrim (sb1 -> b1_desc) + "' nao encontrado na tabela 14 (uvas X grupos) do arquivo ZX5, ou respectivo grupo nao cadastrado na tabela 13 para esta safra."
			_lContinua = .F.
		elseif len (_aGrupo) > 1
			_sComent += "Produto '" + alltrim (sb1 -> b1_cod) + ' - ' + alltrim (sb1 -> b1_desc) + "' encontrado MAIS DE UMA VEZ na tabela 14 (uvas X grupos) do arquivo ZX5, ou respectivo grupo cadastrado MAIS DE UMA VEZ na tabela 13 para esta safra."
			_lContinua = .F.
		else
			_nGBaseAli = _aGrupo [1, 1]  // ZX5_13GBAS
			_nPBasEntr = _aGrupo [1, 2]  // ZX5_13PBEN
			_nPBasComp = _aGrupo [1, 3]  // ZX5_13PBCO
			_nPBasAgiE = _aGrupo [1, 4]  // ZX5_13BAGE
			_sGrpZX513 = _aGrupo [1, 5]  // ZX5_13GRUP
			_nPBasAgiC = _aGrupo [1, 6]  // ZX5_13BAGC
			if _nGBaseAli <= 0
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


		// Busca preco base (para tabela MOC) desta variedade.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT ZX5_13.ZX5_13GBAS, ZX5_13.ZX5_13PBAG, ZX5_13.ZX5_13GRUP"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZX5") + " ZX5_13, "
		_oSQL:_sQuery +=             RetSQLName ("ZX5") + " ZX5_14 "
		_oSQL:_sQuery += " WHERE ZX5_13.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZX5_13.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=   " AND ZX5_13.ZX5_TABELA = '13'"
		_oSQL:_sQuery +=   " AND ZX5_13.ZX5_13GRUP LIKE 'M%'"  // Indica tabela 'MOC'
		_oSQL:_sQuery +=   " AND ZX5_13.ZX5_13SAFR = '2021'"
		_oSQL:_sQuery +=   " AND ZX5_14.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZX5_14.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=   " AND ZX5_14.ZX5_TABELA = '14'"
		_oSQL:_sQuery +=   " AND ZX5_14.ZX5_14SAFR = ZX5_13.ZX5_13SAFR"
		_oSQL:_sQuery +=   " AND ZX5_14.ZX5_14GRUP = ZX5_13.ZX5_13GRUP"
		_oSQL:_sQuery +=   " AND ZX5_14.ZX5_14PROD = '" + sb1 -> b1_cod + "'"
	//	_oSQL:Log ()
		_aGrupo := aclone (_oSQL:Qry2Array (.F., .F.))
		//U_log (_aGrupo)
		if len (_aGrupo) == 0
			_sComent += "Produto '" + alltrim (sb1 -> b1_cod) + ' - ' + alltrim (sb1 -> b1_desc) + "' nao encontrado na tabela 14 (uvas X grupos) do arquivo ZX5, ou respectivo grupo 'M' (ref.tabela MOC) nao cadastrado na tabela 13 do arquivo ZX5 para esta safra."
			_lContinua = .F.
		elseif len (_aGrupo) > 1
			_sComent += "Produto '" + alltrim (sb1 -> b1_cod) + ' - ' + alltrim (sb1 -> b1_desc) + "' encontrado MAIS DE UMA VEZ na tabela 14 (uvas X grupos) do arquivo ZX5, ou respectivo grupo 'M' (ref.tabela MOC) cadastrado MAIS DE UMA VEZ na tabela 13 do arquivo ZX5 para esta safra."
			_lContinua = .F.
		else
			_nGBaseMOC = _aGrupo [1, 1]
			_nPBaseMOC = _aGrupo [1, 2]
			_sGrpZX5MO = _aGrupo [1, 3]
			if _nGBaseMOC <= 0
				_sComent += "Grau base vazio ou invalido para o produto '" + alltrim (sb1 -> b1_cod) + ' - ' + alltrim (sb1 -> b1_desc) + "' na tabela 13 (grupos de uvas 'M') do arquivo ZX5 para esta safra."
				_lContinua = .F.
			endif
			if _nPBaseMOC <= 0
				_sComent += "Valor base para composicao do % de agio na tabela MOC encontra-se vazio ou invalido para o grupo '" + _sGrpZX5MO + "' na tabela 13 (grupos de uvas) do arquivo ZX5 para esta safra."
				_lContinua = .F.
			endif
		endif

	endif

	// Gera lista com todos os graus e agios a aplicar, para facilitar o calculo.
	// Gera sempre uma tabela com todos os graus e, no final, 'pesca' dela apenas o grau solicitado.
	if _lContinua
	//	u_log2 ('debug', 'Grau: ' + cvaltochar (_nGrau) + '  grau base alianca: ' + cvaltochar (_nGBaseAli) + '  Prc.grau base: ' + cvaltochar (_nPBasEntr) + ' (entr)   ' + cvaltochar (_nPBasComp) + ' (compra)   ' + cvaltochar (_nPBasAgiE) + ' (base p/agio)   grupo ZX513: ' + cvaltochar (_sGrpZX513))
	//	u_log2 ('debug', 'Grau base MOC: ' + cvaltochar (_nGBaseMOC) + '  Prc.grau base MOC: ' + cvaltochar (_nPBaseMOC) + '   grupo ZX5_MOC: ' + cvaltochar (_sGrpZX5MO))

		// A cada mudanca (valores inteiros) de grau, o percentual de agio pode mudar.
		_aGraus = {}
		_nAux = 6  // Caso precise um grau menor, pode-se alterar aqui
		do while _nAux <= 26  // Caso precise um grau maior, pode-se alterar aqui
			
			// Define o agio da Alianca (costuma ser diferente da MOC)
			if _nAux == _nGBaseAli
				_nPerAgAli = 0
			elseif _nAux < _nGBaseAli  // Verifica quantos graus encontra-se abaixo do grau base
				if int (_nGBaseAli) - int (_nAux) <= 1
					_nPerAgAli = 5
				elseif int (_nGBaseAli) - int (_nAux) <= 2
					_nPerAgAli = 10
				else //if int (_nGBaseAli) - int (_nAux) <= 3
					_nPerAgAli = 15
				endif
			elseif _nAux > _nGBaseAli  // Verifica quantos graus encontra-se acima do grau base
				if _nAux - _nGBaseAli <= 1
					_nPerAgAli = 5
				elseif _nAux - _nGBaseAli <= 2
					_nPerAgAli = 10
				else //if _nAux - _nGBaseAli <= 3
					_nPerAgAli = 15
				endif
			//	u_log2 ('debug', 'para grau ' + cvaltochar (_nAux) +  ' definiu _nPerAgAli=' + cvaltochar (_nPerAgAli))
			endif


			// Define o agio da MOC (costuma ser diferente da Alianca)
			if _nAux == _nGBaseMOC
				_nPerAgMOC = 0
			elseif _nAux < _nGBaseMOC  // Verifica quantos graus encontra-se abaixo do grau base
				if int (_nGBaseMOC) - _nAux <= 1
					_nPerAgMOC = 5
				elseif int (_nGBaseMOC) - _nAux <= 2
					_nPerAgMOC = 15
				elseif int (_nGBaseMOC) - _nAux <= 3
					_nPerAgMOC = 30  // Ateh 14/05/2020 estava com 25
				elseif int (_nGBaseMOC) - _nAux <= 4
					_nPerAgMOC = 50  // Ateh 14/05/2020 estava com 30
				elseif int (_nGBaseMOC) - _nAux <= 5
					_nPerAgMOC = 55  // Ateh 14/05/2020 estava com 50

				// Os percentuais abaixo nao constam no MOC por que a CONAB nao considera graus aceitaveis para vinificacao,
				// mas eu preciso ter tratamento para receber uva fora dessa faixa de graus. Robert, 22/01/2020.
				elseif int (_nGBaseMOC) - _nAux <= 6
					_nPerAgMOC = 60
				elseif int (_nGBaseMOC) - _nAux <= 7
					_nPerAgMOC = 70
				elseif int (_nGBaseMOC) - _nAux <= 8
					_nPerAgMOC = 80
				elseif int (_nGBaseMOC) - _nAux <= 9
					_nPerAgMOC = 85
				elseif int (_nGBaseMOC) - _nAux <= 10
					_nPerAgMOC = 90
				elseif int (_nGBaseMOC) - _nAux <= 11
					_nPerAgMOC = 95

				endif
			elseif _nAux > _nGBaseMOC  // Verifica quantos graus encontra-se acima do grau base
				if _nAux - _nGBaseMOC <= 1
					_nPerAgMOC = 5
				elseif _nAux - _nGBaseMOC <= 2
					_nPerAgMOC = 15
				elseif _nAux - _nGBaseMOC <= 3
					_nPerAgMOC = 25
				elseif _nAux - _nGBaseMOC <= 4
					_nPerAgMOC = 35
				elseif _nAux - _nGBaseMOC <= 5
					_nPerAgMOC = 45

				// Os percentuais abaixo nao constam no MOC por que a CONAB nao especificou,
				// mas eu preciso ter tratamento para receber uva fora dessa faixa de graus. Robert, 22/01/2020.
				elseif _nAux - _nGBaseMOC <= 6
					_nPerAgMOC = 50
				elseif _nAux - _nGBaseMOC <= 7
					_nPerAgMOC = 55
				elseif _nAux - _nGBaseMOC <= 8
					_nPerAgMOC = 60
				elseif _nAux - _nGBaseMOC <= 9
					_nPerAgMOC = 65
				elseif _nAux - _nGBaseMOC <= 10
					_nPerAgMOC = 70
				elseif _nAux - _nGBaseMOC <= 11
					_nPerAgMOC = 75
				elseif _nAux - _nGBaseMOC <= 12
					_nPerAgMOC = 80

				endif
			endif
		//	u_log ('para grau', _nAux, 'definiu _nPerAgMOC=', _nPerAgMOC)

			aadd (_aGraus, afill (array (.PrcUvaQtColunas), 0))
			_aGraus [len (_aGraus), .PrcUvaColGrau]            = _nAux
			_aGraus [len (_aGraus), .PrcUvaColPercAgioAlianca] = _nPerAgAli
			_aGraus [len (_aGraus), .PrcUvaColPercAgioMOC]     = _nPerAgMOC
			_nAux += 0.1
		enddo
//		u_log2 ('debug', 'tabela de graus com os percentuais de agio:')
//		u_log2 ('debug', _aGraus)
	endif


	// Calcula tabela de precos a partir de aplicacao de agio / desagio sobre o preco do grau base.
	if _lContinua

		// PARTE I: gera valores de 'entrada' e 'compra' usando criterios de agio da Alianca
		// Encontra a linha e atualiza preco do grau base Alianca na lista de graus.
		_nPosGBase = ascan (_aGraus, {|_x| _x [.PrcUvaColGrau] == _nGBaseAli})
		if _nPosGBase == 0
			_sComent += "Grau base Alianca " + cvaltochar (_nGBaseAli) + " nao se encontra na array de graus. Revise o programa " + procname ()
			_lContinua = .F.
		else
			_aGraus [_nPosGBase, .PrcUvaColPrcEntrada] = _nPBasEntr
			_aGraus [_nPosGBase, .PrcUvaColPrcCompra]  = _nPBasComp

			// Aplica percentual de agio 'do grau base para os graus menores'
			for _nAux = _nPosGBase - 1 to 1 step -1
//				u_log2 ('debug', 'Aplicando agio abaixo para o grau ' + cvaltochar (_aGraus [_nAux, .PrcUvaColGrau]))
				_nVlrAgioE = round (_nPBasAgiE * _aGraus [_nAux, .PrcUvaColPercAgioAlianca] / 100 / 10, 5)
				_nVlrAgioC = round (_nPBasAgiC * _aGraus [_nAux, .PrcUvaColPercAgioAlianca] / 100 / 10, 5)
//				u_log2 ('debug', '_nVlrAgioC = ' + cvaltochar (_nVlrAgioC))
				_aGraus [_nAux, .PrcUvaColVlrAgioEntrada] = _nVlrAgioE  // Guarda apenas para auxiliar nas conferencias
				_aGraus [_nAux, .PrcUvaColVlrAgioCompra]  = _nVlrAgioC  // Guarda apenas para auxiliar nas conferencias
				_aGraus [_nAux, .PrcUvaColPrcEntrada]     = _aGraus [_nAux + 1, .PrcUvaColPrcEntrada] - _nVlrAgioE
				_aGraus [_nAux, .PrcUvaColPrcCompra]      = _aGraus [_nAux + 1, .PrcUvaColPrcCompra]  - _nVlrAgioC
			next

			// Aplica percentual de agio 'do grau base para os maiores'
			for _nAux = _nPosGBase + 1 to len (_aGraus)
				_nVlrAgioE = round (_nPBasAgiE * _aGraus [_nAux, .PrcUvaColPercAgioAlianca] / 100 / 10, 5)
				_nVlrAgioC = round (_nPBasAgiC * _aGraus [_nAux, .PrcUvaColPercAgioAlianca] / 100 / 10, 5)
				_aGraus [_nAux, .PrcUvaColVlrAgioEntrada] = _nVlrAgioE  // Guarda apenas para auxiliar nas conferencias
				_aGraus [_nAux, .PrcUvaColVlrAgioCompra]  = _nVlrAgioC  // Guarda apenas para auxiliar nas conferencias
				_aGraus [_nAux, .PrcUvaColPrcEntrada]     = _aGraus [_nAux - 1, .PrcUvaColPrcEntrada] + _nVlrAgioE
				_aGraus [_nAux, .PrcUvaColPrcCompra]      = _aGraus [_nAux - 1, .PrcUvaColPrcCompra]  + _nVlrAgioC
			next
		endif


		// PARTE II: gera valores da MOC usando criterios de agio da CONAB
		// Atualiza preco do grau base MOC na lista de graus.
		_nPosGBase = ascan (_aGraus, {|_x| _x [.PrcUvaColGrau] == _nGBaseMOC})
		if _nPosGBase == 0
			_sComent += "Grau base MOC " + cvaltochar (_nGBaseMOC) + " nao se encontra na array de graus. Revise o programa " + procname ()
			_lContinua = .F.
		else
			_aGraus [_nPosGBase, .PrcUvaColPrcMOC] = _nPBaseMOC

			// Apenas para os graus inteiros
			// Aplica percentual de agio 'do grau base para os graus menores'
			for _nAux = _nPosGBase - 10 to 1 step -10
				_nVlrAgioM = round (_nPBaseMOC * _aGraus [_nAux, .PrcUvaColPercAgioMOC] / 100, 5)
				_aGraus [_nAux, .PrcUvaColPrcMOC] = _nPBaseMOC - _nVlrAgioM  // Aplicado ao preco do grau base e nao do grau anterior/posterior.
				//u_log ('calculando grau', _aGraus [_nAux, .PrcUvaColGrau], 'perc.agio:', _aGraus [_nAux, .PrcUvaColPercAgioMOC], 'vlg.agio:', _nVlrAgioM, 'prc.base:', _nPBaseMOC, 'resultou:', _aGraus [_nAux, .PrcUvaColPrcMOC])
			next
			//
			// Aplica percentual de agio 'do grau base para os maiores'
			for _nAux = _nPosGBase + 10 to len (_aGraus) step 10
				_nVlrAgioM = round (_nPBaseMOC * _aGraus [_nAux, .PrcUvaColPercAgioMOC] / 100, 5)
				_aGraus [_nAux, .PrcUvaColPrcMOC] = _nPBaseMOC + _nVlrAgioM  // Aplicado ao preco do grau base e nao do grau anterior/posterior.
			next

			// Calcula valores dos graus decimais pela diferenca entre o grau anterior e posterior (inteiros)
			// Calcula 'do grau base para os graus menores'
			for _nAux = _nPosGBase to 10 step -10
				_nVlrMaior = _aGraus [_nAux, .PrcUvaColPrcMOC]
				_nVlrMenor = _aGraus [_nAux - 10, .PrcUvaColPrcMOC]
				//u_log ('Valores entre', _nVlrMenor, 'e', _nVlrMaior)
				for _nContador = 1 to 9
					_aGraus [_nAux - _nContador, .PrcUvaColPrcMOC] = _nVlrMaior - (_nVlrMaior - _nVlrMenor) / 10 * _nContador
				next
			next
			//
			// Calcula 'do grau base para os graus maiores'
			for _nAux = _nPosGBase to len (_aGraus) - 10 step 10
				_nVlrMaior = _aGraus [_nAux + 10, .PrcUvaColPrcMOC]
				_nVlrMenor = _aGraus [_nAux, .PrcUvaColPrcMOC]
				//u_log ('Valores entre', _nVlrMenor, 'e', _nVlrMaior)
				for _nContador = 1 to 9
					_aGraus [_nAux + _nContador, .PrcUvaColPrcMOC] = _nVlrMenor + (_nVlrMaior - _nVlrMenor) / 10 * _nContador
				next
			next
			
		endif


		// PARTE III: aplica % de agio das organicas, se for o caso.
		// Estamos fazendo as entradas a valor de CONAB neste ano, mas jah vamos aplicar o agio nas organicas. 
		if _nAgioOrg > 0
		//	u_log2 ('debug', 'Aplicando agio (organica/em conversao) de ' + cvaltochar (_nAgioOrg))
			for _nAux = 1 to len (_aGraus)
				_aGraus [_nAux, .PrcUvaColPrcEntrada] = _aGraus [_nAux, .PrcUvaColPrcEntrada] + _aGraus [_nAux, .PrcUvaColPrcEntrada] * _nAgioOrg / 100
				_aGraus [_nAux, .PrcUvaColPrcCompra]  = _aGraus [_nAux, .PrcUvaColPrcCompra]  + _aGraus [_nAux, .PrcUvaColPrcCompra]  * _nAgioOrg / 100
				_aGraus [_nAux, .PrcUvaColPrcMOC]     = _aGraus [_nAux, .PrcUvaColPrcMOC]     + _aGraus [_nAux, .PrcUvaColPrcMOC]     * _nAgioOrg / 100
			next
		endif

	endif


	if _lContinua
		// Encontra, na array de graus gerada, o grau solicitado e prepara variaveis para retorno.
		_nPosGrau = ascan (_aGraus, {|_x| _x [.PrcUvaColGrau] == _nGrau})
		if _nPosGrau == 0
			_sComent += "Grau solicitado (" + cvaltochar (_nGrau) + ") fora da faixa de calculo."
			_lContinua = .F.
		else
			_nPrcRec = iif (_nPBasEntr > 0, _aGraus [_nPosGrau, .PrcUvaColPrcEntrada], 0)  // Para nao devolver sujeira caso falte o preco do grau base.
			_nPrcCom = iif (_nPBasComp > 0, _aGraus [_nPosGrau, .PrcUvaColPrcCompra], 0)   // Para nao devolver sujeira caso falte o preco do grau base.
			_nPrcMOC = iif (_nPBaseMOC > 0, _aGraus [_nPosGrau, .PrcUvaColPrcMOC], 0)      // Para nao devolver sujeira caso falte o preco do grau base.
		endif
	endif

//	u_log2 ('debug', 'Tabela de precos gerada:')
//	u_log2 ('debug', _aGraus)

	// Gera array de precos para uso em rotina externa (ex: consulta de tabelas de precos).
	if _lRetArray != NIL .and. _lRetArray
		_aGrausInt = {}
		for _nAux = 1 to len (_aGraus)
			aadd (_aGrausInt, aclone (_aGraus [_nAux]))
		next
		//u_log (_aGrausInt)
	endif

	// Aplica acrescimos ou decrescimos conforme a classificacao da uva.
	if _lContinua
	
		// O preco varia conforme a sua classificacao final. Nao se aplica ao preco da tabela MOC.
		if sb1 -> B1_VARUVA == "F" .and. sb1 -> B1_VAFCUVA == "F" .and. ! _lIsabel
//			u_log2 ('info', 'Forma de conducao....: ' + _sConducao)
//			u_log2 ('info', 'Classificacao........: ' + _sClassif)
			if _sConducao == 'E'  // Espaldeira
				do case
				case alltrim (_sClassif) == "PR" .or. alltrim (_sClassif) == "AA"// Nao testar alltrim (_sClassif) $ "PR/AA" por que vai abocanhar a classe 'A' junto!
					_nPrcRec *= 1.4
					_nPrcCom *= 1.4
				case alltrim (_sClassif) == "A"
					_nPrcRec *= 1.2
					_nPrcCom *= 1.2
				case alltrim (_sClassif) $ "B/C"
					_nPrcRec *= 1
					_nPrcCom *= 1
				otherwise
					_sComent += '[' + procname () + '] Sem calculo de agio para classificacao ' + _sClassif + ' e sistema de conducao ' + _sConducao
					_lContinua = .F.
				endcase

			elseif _sConducao == 'L'  // Latada

				if _sGrpZX513 == '302'  // Este ano nao pagaremos agio para cabernet e outras com clas.A latada
					do case
					case alltrim (_sClassif) $ "A/B/DS"  // A=nao tem agio; B=jah era 0%; DS=jah caiu na regra de pagar como isabel
						_nPrcRec *= 1.0
						_nPrcCom *= 1.0
					otherwise
						_sComent += '[' + procname () + '] Sem definicao de agio para o grupo ' + _sGrpZX513 + ' da tabela 14 do ZX5 com classificacao ' + _sClassif + ' e sistema de conducao ' + _sConducao
						_lContinua = .F.
					endcase

				elseif _sGrpZX513 == '304'  // Este ano pagaremos agio de apenas 5% para malvasias e outras com clas.A latada

					do case
					case alltrim (_sClassif) == "A"
						_nPrcRec *= 1.05
						_nPrcCom *= 1.05
					case alltrim (_sClassif) $ "B/C/DS"  // B=jah era 0%; DS=jah caiu na regra de pagar como isabel
						_nPrcRec *= 1.0
						_nPrcCom *= 1.0
					otherwise
						_sComent += '[' + procname () + '] Sem definicao de agio para o grupo ' + _sGrpZX513 + ' da tabela 14 do ZX5 com classificacao ' + _sClassif + ' e sistema de conducao ' + _sConducao
						_lContinua = .F.
					endcase

				elseif _sGrpZX513 == '305'  // Este ano pagaremos agio de 10% para moscato e alicante com clas.A latada

					do case
					case alltrim (_sClassif) == "A"
						_nPrcRec *= 1.1
						_nPrcCom *= 1.1
					case alltrim (_sClassif) $ "B/C/DS"  // B=jah era 0%; DS=jah caiu na regra de pagar como isabel
						_nPrcRec *= 1.0
						_nPrcCom *= 1.0
					otherwise
						_sComent += '[' + procname () + '] Sem definicao de agio para o grupo ' + _sGrpZX513 + ' da tabela 14 do ZX5 com classificacao ' + _sClassif + ' e sistema de conducao ' + _sConducao
						_lContinua = .F.
					endcase
				endif
			else
				_sComent += "Sem tratamento para o sistema de conducao '" + _sConducao + "'."
				_lContinua = .F.
			endif
		endif
	endif

	// Monta array para retorno dos dados.
	if _lContinua
//		_aRet = {round (_nPrcRec, _nArred), round (_nPrcCom, _nArred), _sComent, _aGrausInt, round (_nPrcMOC, _nArred)}
		_aRet = {round (_nPrcRec, _nArredEnt), round (_nPrcCom, _nArredCom), _sComent, _aGrausInt, round (_nPrcMOC, _nArredMOC)}
	else
		u_help (_sComent,, .t.)
		_aRet = {0, 0, _sComent, _aGrausInt, 0}
	endif

//	u_log ('Preco entrada:', _aRet [1])
//	u_log ('Preco compra :', _aRet [2])
//	u_log ('Preco MOC    :', _aRet [5])
//	u_log ('Comentarios  :', _aRet [3])
	U_ML_SRArea (_aAreaAnt)
return _aRet
