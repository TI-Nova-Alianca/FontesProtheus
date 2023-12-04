// Programa:  PrcUvaS1
// Autor:     Robert Koch
// Data:      07/12/2022
// Descricao: Retorna os diferentes precos da uva para safra 2023- simulacao especifica GLPI 14200

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Calcula precos de uvas para a safra 2023 simulacao GLPI14200
// #PalavasChave      #preco_uva_safra
// #TabelasPrincipais #ZX5 #SB1
// #Modulos           #COOP

// Historico de alteracoes:
// 09/11/2023 - Robert - Passa a usar tabela S23A para atender consad de nov/23 (GLPI 14483)
//

#include "VA_INCLU.prw"

// --------------------------------------------------------------------------
user function PrcUvaS1 (_sFilial, _sProduto, _nGrau, _sClassif, _sConducao, _lRetArray, _lMostrMsg)
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
	local _aGraus    := {}
	local _nAux      := 0
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
	local _nGMinAgio := 0
	local _nPrMinimo := 0
//	local _sSafraPrc := 'S123'  // Ajustar caso seja copiado para o proximo ano!
	local _sSafraPrc := 'S23A'  // Ajustar caso seja copiado para o proximo ano!
	local _nAgAliAnt := 0
	local _nAgMOCAnt := 0
	local _nAgAliPos := 0
	local _nAgMOCPos := 0
	local _nGrIniTab := 6   // Grau inicial a ser gerado
	local _nGrFimTab := 26  // Grau final a ser gerado

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
	//	u_log2 ('debug', '[' + procname () + '] Calculando preco uva ' + alltrim (_sProduto) + '-' + alltrim (sb1 -> b1_desc) + ' gr: ' + cvaltochar (_nGrau) + ' entregue na filial ' + _sFilial)
		if sb1 -> b1_varuva == 'F'
			if _sFilial $ '01/09'
				_lIsabel = .T.
				_sComent += "Viniferas F01/F09: precifica como isabel(ttas) ou niagara(bcas)."
			elseif _sFilial == '07'
				if sb1 -> b1_vaFCUva == 'C'  // Forma de classificacao: classificar 'como comum'.
					_lIsabel = .T.
					_sComent += "Viniferas SC na F07: precifica como isabel(ttas) ou niagara(bcas)."
				else
				//	if sb1 -> b1_vacor == 'T' .and. _nGrau < 14
					if sb1 -> b1_vacor == 'T' .and. _nGrau < 14 .and. ! alltrim (sb1 -> b1_cod) $ '9911/9969'  // Nao se aplica ao moscato branco e alicante
						_lIsabel = .T.
						_sComent += "Viniferas ttas na F07 abaixo 14 graus: precifica como isabel."
					endif
				//	if sb1 -> b1_vacor != 'T' .and. _nGrau < 11
				//	if sb1 -> b1_vacor != 'T' .and. _nGrau < 11 .and. alltrim (sb1 -> b1_cod) != '9911'  // Nao se aplica ao moscato branco
					if sb1 -> b1_vacor != 'T' .and. _nGrau < 11 .and. ! alltrim (sb1 -> b1_cod) $ '9911/9969'  // Nao se aplica ao moscato branco e alicante
						_lIsabel = .T.
						_sComent += "Viniferas bcas na F07 abaixo 11 graus: precifica como niagara."
					endif
//					if _sConducao == 'L' .and. alltrim (_sClassif) == 'DS'  //'D'
				//	if _sConducao == 'L' .and. alltrim (_sClassif) == 'DS' .and. alltrim (sb1 -> b1_cod) != '9911'  // Nao se aplica ao moscato branco
					if _sConducao == 'L' .and. alltrim (_sClassif) == 'DS' .and. ! alltrim (sb1 -> b1_cod) $ '9911/9969'  // Nao se aplica ao moscato branco e alicante
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
			//		u_log2 ('debug', 'Variedade considerada: ' + _sProduto + ' ' + alltrim (sb1 -> b1_desc) + '(' + _sComent + ')')
				endif
			endif
		endif
	endif


	// Se for organica ou em conversao, preciso buscar o produto base (uva convencional)
	// para depois aplicar % em cima desta.
	if _lContinua
		sb1 -> (dbsetorder (1))
		if ! sb1 -> (dbseek (xfilial ("SB1") + _sProduto, .F.))
			_sComent += "Produto '" + _sProduto + "' nao encontrado no cadastro."
			_lContinua = .F.
		else

			// Define o % a ser aplicado sobre o preco do produto base
			if sb1 -> b1_vaorgan $ 'BEO'  // [B]ordadura, [E]m conversao ou [O]rganica
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
					_sComent += "Uva '" + alltrim (_sProduto) + "': por tratar-se de organica/em conversao, preciso ter o codigo base (convencional) informada no campo '" + alltrim (RetTitle ('B1_CODPAI')) + "' para calculo de preco."
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
			//		u_log2 ('info', _sComent)
					_sProduto = _sProdBase
				endif
			endif
		endif
	endif


	if _lContinua

		// Busca precos base (de entrada e de compra) desta variedade.
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT ZX5_13.ZX5_13GBAS, ZX5_13.ZX5_13PBEN, ZX5_13.ZX5_13PBCO"
		_oSQL:_sQuery +=      " ,ZX5_13.ZX5_13BAGE, ZX5_13.ZX5_13GRUP, ZX5_13.ZX5_13BAGC"
		_oSQL:_sQuery +=      " ,ZX5_13.ZX5_13GMAG, ZX5_13.ZX5_13PMIN"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZX5") + " ZX5_13, "
		_oSQL:_sQuery +=             RetSQLName ("ZX5") + " ZX5_14 "
		_oSQL:_sQuery += " WHERE ZX5_13.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZX5_13.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=   " AND ZX5_13.ZX5_TABELA = '13'"
		_oSQL:_sQuery +=   " AND ZX5_13.ZX5_13GRUP NOT LIKE 'M%'"  // Ignorar tabela 'MOC'
		_oSQL:_sQuery +=   " AND ZX5_13.ZX5_13SAFR = '" + _sSafraPrc + "'"
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
	//	_oSQL:Log ('[' + procname () + ']')

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
			_nGMinAgio = _aGrupo [1, 7]  // ZX5_13GMAG
			_nPrMinimo = _aGrupo [1, 8]  // ZX5_13PMIN

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
		_oSQL:_sQuery +=   " AND ZX5_13.ZX5_13SAFR = '" + _sSafraPrc + "'"
		_oSQL:_sQuery +=   " AND ZX5_14.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZX5_14.ZX5_FILIAL = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=   " AND ZX5_14.ZX5_TABELA = '14'"
		_oSQL:_sQuery +=   " AND ZX5_14.ZX5_14SAFR = ZX5_13.ZX5_13SAFR"
		_oSQL:_sQuery +=   " AND ZX5_14.ZX5_14GRUP = ZX5_13.ZX5_13GRUP"
		_oSQL:_sQuery +=   " AND ZX5_14.ZX5_14PROD = '" + sb1 -> b1_cod + "'"
	//	_oSQL:Log ('[' + procname () + ']')
		_aGrupo := aclone (_oSQL:Qry2Array (.F., .F.))
	//	U_log (_aGrupo)
		if len (_aGrupo) == 0
			_sComent += "Produto '" + alltrim (sb1 -> b1_cod) + ' - ' + alltrim (sb1 -> b1_desc) + "' nao encontrado nos grupos 'M' (MOC) na tabela 14 (uvas X grupos) do arquivo ZX5, ou respectivo grupo nao cadastrado na tabela 13 do arquivo ZX5 para esta safra."
			_lContinua = .F.
		elseif len (_aGrupo) > 1
			_sComent += "Produto '" + alltrim (sb1 -> b1_cod) + ' - ' + alltrim (sb1 -> b1_desc) + "' encontrado MAIS DE UMA VEZ nos grupos 'M' (MOC) na tabela 14 (uvas X grupos) do arquivo ZX5, ou respectivo grupo cadastrado MAIS DE UMA VEZ na tabela 13 do arquivo ZX5 para esta safra."
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

//	u_log2 ('debug', 'Grau: ' + cvaltochar (_nGrau) + '  grau base alianca: ' + cvaltochar (_nGBaseAli) + '  Prc.grau base: ' + cvaltochar (_nPBasEntr) + ' (entr)   ' + cvaltochar (_nPBasComp) + ' (compra)   ' + cvaltochar (_nPBasAgiE) + ' (base p/agio)   grupo ZX513: ' + cvaltochar (_sGrpZX513))
//	u_log2 ('debug', 'Grau base MOC: ' + cvaltochar (_nGBaseMOC) + '  Prc.grau base MOC: ' + cvaltochar (_nPBaseMOC) + '   grupo ZX5_MOC: ' + cvaltochar (_sGrpZX5MO))

	// Gera lista com todos os graus possiveis (no final, 'pesca' dela apenas o grau solicitado).
	if _lContinua
		_aGraus = {}
		_nAux = _nGrIniTab // 6  // Caso precise um grau menor, pode-se alterar aqui
		do while _nAux <= _nGrFimTab // 26  // Caso precise um grau maior, pode-se alterar aqui
			aadd (_aGraus, afill (array (.PrcUvaQtColunas), 0))
			_aGraus [len (_aGraus), .PrcUvaColGrau] = _nAux
			_nAux += 0.1
		enddo
	endif

	// Define percentuais de agio (% acrescido ou diminuido cf. muda o grau) para os graus inteiros.
	if _lContinua
		for _nAux = 1 to len (_aGraus)
			if _aGraus [_nAux, .PrcUvaColGrau] = int (_aGraus [_nAux, .PrcUvaColGrau])
			
				// Define o agio da Alianca (costuma ser diferente da MOC)
				do case
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli - 12 ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = -165
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli - 11 ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = -150
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli - 10 ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = -135
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli - 9  ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = -120
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli - 8  ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = -105
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli - 7  ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = -90
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli - 6  ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = -75
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli - 5  ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = -60
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli - 4  ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = -45
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli - 3  ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = -30
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli - 2  ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = -15
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli - 1  ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = -5
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli - 0  ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = 0
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli + 1  ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = 5
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli + 2  ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = 15
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli + 3  ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = 25
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli + 4  ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = 35
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli + 5  ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = 45
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli + 6  ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = 55
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli + 7  ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = 65
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli + 8  ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = 75
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli + 9  ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = 85
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli + 10 ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = 95
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli + 11 ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = 105
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli + 12 ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = 115
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli + 13 ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = 125
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli + 14 ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = 135
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli + 15 ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = 145
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseAli + 16 ; _aGraus [_nAux, .PrcUvaColPercAgioAlianca] = 155
				otherwise
					u_help ("Sem definicao de percentual de AGIO ALIANCA para grau " + cvaltochar (_aGraus [_nAux, .PrcUvaColGrau]),, .t.)
					_lContinua = .F.
				endcase

				// Define o agio da MOC (costuma ser diferente da Alianca)
				do case
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC - 12 ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = -100  // Este % nao constam no MOC por que a CONAB nao considera graus aceitaveis para vinificacao, mas eu preciso ter tratamento para receber uva fora dessa faixa de graus. Robert, 22/01/2020.
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC - 11 ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = -95   // Este % nao constam no MOC por que a CONAB nao considera graus aceitaveis para vinificacao, mas eu preciso ter tratamento para receber uva fora dessa faixa de graus. Robert, 22/01/2020.
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC - 10 ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = -90   // Este % nao constam no MOC por que a CONAB nao considera graus aceitaveis para vinificacao, mas eu preciso ter tratamento para receber uva fora dessa faixa de graus. Robert, 22/01/2020.
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC - 9  ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = -85   // Este % nao constam no MOC por que a CONAB nao considera graus aceitaveis para vinificacao, mas eu preciso ter tratamento para receber uva fora dessa faixa de graus. Robert, 22/01/2020.
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC - 8  ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = -80   // Este % nao constam no MOC por que a CONAB nao considera graus aceitaveis para vinificacao, mas eu preciso ter tratamento para receber uva fora dessa faixa de graus. Robert, 22/01/2020.
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC - 7  ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = -70   // Este % nao constam no MOC por que a CONAB nao considera graus aceitaveis para vinificacao, mas eu preciso ter tratamento para receber uva fora dessa faixa de graus. Robert, 22/01/2020.
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC - 6  ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = -60   // Este % nao constam no MOC por que a CONAB nao considera graus aceitaveis para vinificacao, mas eu preciso ter tratamento para receber uva fora dessa faixa de graus. Robert, 22/01/2020.
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC - 5  ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = -55   // Este % nao constam no MOC por que a CONAB nao considera graus aceitaveis para vinificacao, mas eu preciso ter tratamento para receber uva fora dessa faixa de graus. Robert, 22/01/2020.
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC - 4  ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = -50   // Este % nao constam no MOC por que a CONAB nao considera graus aceitaveis para vinificacao, mas eu preciso ter tratamento para receber uva fora dessa faixa de graus. Robert, 22/01/2020.
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC - 3  ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = -30
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC - 2  ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = -15
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC - 1  ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = -5
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC - 0  ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = 0
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC + 1  ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = 5
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC + 2  ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = 15
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC + 3  ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = 25
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC + 4  ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = 35
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC + 5  ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = 45
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC + 6  ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = 55
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC + 7  ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = 65
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC + 8  ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = 75
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC + 9  ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = 85
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC + 10 ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = 95
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC + 11 ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = 105  // Este % nao constam no MOC, mas eu preciso ter tratamento para receber uva fora dessa faixa de graus. Robert, 22/01/2020.
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC + 12 ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = 115  // Este % nao constam no MOC, mas eu preciso ter tratamento para receber uva fora dessa faixa de graus. Robert, 22/01/2020.
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC + 13 ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = 125  // Este % nao constam no MOC, mas eu preciso ter tratamento para receber uva fora dessa faixa de graus. Robert, 22/01/2020.
				case _aGraus [_nAux, .PrcUvaColGrau] == _nGBaseMOC + 14 ; _aGraus [_nAux, .PrcUvaColPercAgioMOC] = 135  // Este % nao constam no MOC, mas eu preciso ter tratamento para receber uva fora dessa faixa de graus. Robert, 22/01/2020.
				otherwise
					u_help ("Sem definicao de percentual de AGIO CONAB para grau " + cvaltochar (_aGraus [_nAux, .PrcUvaColGrau]),, .t.)
					_lContinua = .F.
				endcase
			endif
		next
	endif

	// Como preciso gerar os graus com decimais e os agios sao definidos apenas
	// para os graus inteiros, tenho que calcular eles para os decimais.
	if _lContinua
		for _nAux = 1 to len (_aGraus)

			// Para os inteiros, jah ficou fixo anteriormente.
			if _aGraus [_nAux, .PrcUvaColGrau] != int (_aGraus [_nAux, .PrcUvaColGrau])

				// Encontra o agio do 'grau inteiro' anterior
				_nPosGrInt = _nAux
				do while _nPosGrInt > 0 .and. _aGraus [_nPosGrInt, .PrcUvaColGrau] != int (_aGraus [_nPosGrInt, .PrcUvaColGrau])
					_nPosGrInt --
				enddo
				if _nPosGrInt > 0
					_nAgAliAnt = _aGraus [_nPosGrInt, .PrcUvaColPercAgioAlianca]  // Agora tenho o % de agio do grau inteiro
					_nAgMOCAnt = _aGraus [_nPosGrInt, .PrcUvaColPercAgioMOC]  // Agora tenho o % de agio do grau inteiro
				else
					u_help ("Nao consegui encontrar grau inteiro (menor que " + cvaltochar (_aGraus [_nAux, .PrcUvaColGrau]) + ") para ler agio e calcular decimais.",, .t.)
					_lContinua = .F.
				endif

				// Encontra o agio do 'grau inteiro' posterior
				_nPosGrInt = _nAux
				do while _nPosGrInt <= len (_aGraus) .and. _aGraus [_nPosGrInt, .PrcUvaColGrau] != int (_aGraus [_nPosGrInt, .PrcUvaColGrau])
					_nPosGrInt ++
				enddo
				if _nPosGrInt <= len (_aGraus)
					_nAgAliPos = _aGraus [_nPosGrInt, .PrcUvaColPercAgioAlianca]  // Agora tenho o % de agio do grau inteiro
					_nAgMOCPos = _aGraus [_nPosGrInt, .PrcUvaColPercAgioMOC]  // Agora tenho o % de agio do grau inteiro
				else
					u_help ("Nao consegui encontrar grau inteiro (maior que " + cvaltochar (_aGraus [_nAux, .PrcUvaColGrau]) + ") para ler agio e calcular decimais.",, .t.)
					_lContinua = .F.
				endif

		//		U_Log2 ('debug', 'Gr ' + transform (_aGraus [_nAux, .PrcUvaColGrau], '@E 99.9') + ' _nAgAliAnt=' + cvaltochar (_nAgAliAnt) + ' _nAgAliPos=' + cvaltochar (_nAgAliPos))
				_aGraus [_nAux, .PrcUvaColPercAgioAlianca] = _nAgAliAnt - (_nAgAliAnt - _nAgAliPos) * (_aGraus [_nAux, .PrcUvaColGrau] - int (_aGraus [_nAux, .PrcUvaColGrau]))
				_aGraus [_nAux, .PrcUvaColPercAgioMOC]     = _nAgMOCAnt - (_nAgMOCAnt - _nAgMOCPos) * (_aGraus [_nAux, .PrcUvaColGrau] - int (_aGraus [_nAux, .PrcUvaColGrau]))
			endif
		next
	//	u_log2 ('debug', 'tabela de graus com agios dos graus decimais:')
	//	u_log2 ('debug', _aGraus)
	endif


	// Gera precos a partir de aplicacao de agio / desagio sobre o preco do grau base.
	if _lContinua
		for _nAux = 1 to len (_aGraus)
			_aGraus [_nAux, .PrcUvaColPrcEntrada] = _nPBasEntr + _nPBasEntr * _aGraus [_nAux, .PrcUvaColPercAgioAlianca] / 100
			_aGraus [_nAux, .PrcUvaColPrcCompra]  = _nPBasComp + _nPBasComp * _aGraus [_nAux, .PrcUvaColPercAgioAlianca] / 100
			_aGraus [_nAux, .PrcUvaColPrcMOC]     = _nPBaseMOC + _nPBaseMOC * _aGraus [_nAux, .PrcUvaColPercAgioMOC] / 100

			// Abaixo de determinado grau, usa preco minimo.
			if _aGraus [_nAux, .PrcUvaColGrau] < _nGMinAgio
				_aGraus [_nAux, .PrcUvaColPrcEntrada] = _nPrMinimo
				_aGraus [_nAux, .PrcUvaColPrcCompra]  = _nPrMinimo
			endif
		next
	//	u_log2 ('debug', 'tabela de graus com os agios aplicados sobre o grau base:')
	//	u_log2 ('debug', _aGraus)
	endif


	// PARTE III: aplica % de agio das organicas, se for o caso.
	// Estamos fazendo as entradas a valor de CONAB neste ano, mas jah vamos aplicar o agio nas organicas. 
	if _lContinua
		if _nAgioOrg > 0
		//	u_log2 ('debug', 'Aplicando agio (organica/em conversao) de ' + cvaltochar (_nAgioOrg) + "% (tintorea=" + sb1 -> b1_vattr + ")")
			for _nAux = 1 to len (_aGraus)
				// Somente para os graus que estiverem acima do minimo (abaixo disso, eh preco minimo pra tudo)
				if _aGraus [_nAux, .PrcUvaColGrau] >= _nGMinAgio
			//		U_Log2 ('debug', '[' + procname () + ']Grau ' + cvaltochar (_aGraus [_nAux, .PrcUvaColGrau]) + ': Vou aplicar ' + cvaltochar (_nAgioOrg) + '% sobre ' + cvaltochar (_aGraus [_nAux, .PrcUvaColPrcCompra]))
					_aGraus [_nAux, .PrcUvaColPrcEntrada] = _aGraus [_nAux, .PrcUvaColPrcEntrada] + _aGraus [_nAux, .PrcUvaColPrcEntrada] * _nAgioOrg / 100
					_aGraus [_nAux, .PrcUvaColPrcCompra]  = _aGraus [_nAux, .PrcUvaColPrcCompra]  + _aGraus [_nAux, .PrcUvaColPrcCompra]  * _nAgioOrg / 100
					_aGraus [_nAux, .PrcUvaColPrcMOC]     = _aGraus [_nAux, .PrcUvaColPrcMOC]     + _aGraus [_nAux, .PrcUvaColPrcMOC]     * _nAgioOrg / 100
			//		U_Log2 ('debug', '[' + procname () + ']Grau ' + cvaltochar (_aGraus [_nAux, .PrcUvaColGrau]) + ': Fiquei com valor = ' + cvaltochar (_aGraus [_nAux, .PrcUvaColPrcCompra]))
				endif
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
			if _nGrau < _nGMinAgio
				_sComent += "Abaixo gr.min.(" + cvaltochar (_nGMinAgio) + "): preco minimo ($" + cvaltochar (_nPrMinimo) + ")"
			endif
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
	//		u_log2 ('debug', 'Forma de conducao....: ' + _sConducao)
	//		u_log2 ('debug', 'Classificacao........: ' + _sClassif)
			if _sConducao == 'E'  // Espaldeira
				do case
				case alltrim (_sClassif) == "PR" .or. alltrim (_sClassif) == "AA"// Nao testar alltrim (_sClassif) $ "PR/AA" por que vai abocanhar a classe 'A' junto!
					_nPrcRec *= 1.2
					_nPrcCom *= 1.2
				case alltrim (_sClassif) == "A"
					_nPrcRec *= 1.2
					_nPrcCom *= 1.2
				case alltrim (_sClassif) $ "B/C"
					_nPrcRec *= 1
					_nPrcCom *= 1
				case alltrim (_sClassif) == "D"
					_nPrcRec *= 0.8
					_nPrcCom *= 0.8
				case alltrim (_sClassif) == "DS"
					_nPrcRec *= 0.5
					_nPrcCom *= 0.5
				otherwise
					_sComent += '[' + procname () + '] Sem calculo de agio para classificacao ' + _sClassif + ' e sistema de conducao ' + _sConducao
					_lContinua = .F.
				endcase

			elseif _sConducao == 'L'  // Latada\

				if _sGrpZX513 == '302'  // Este ano nao pagaremos agio para cabernet e outras com clas.A latada
					do case
					case alltrim (_sClassif) $ "A/B/C/DS"  // A=nao tem agio; B=jah era 0%; DS=jah caiu na regra de pagar como isabel
						_nPrcRec *= 1.0
						_nPrcCom *= 1.0
					otherwise
						_sComent += '[' + procname () + '] Sem definicao de agio para o grupo ' + _sGrpZX513 + ' da tabela 14 do ZX5 com classificacao ' + _sClassif + ' e sistema de conducao ' + _sConducao
						_lContinua = .F.
					endcase

	//			elseif _sGrpZX513 == '304'  // Este ano pagaremos agio de apenas 5% para malvasias e outras com clas.A latada
				elseif _sGrpZX513 $ '304/308'  // Grupo 304 foi aberto em 304 e 308 - Este ano pagaremos agio de apenas 5% para malvasias e outras com clas.A latada

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

				elseif _sGrpZX513 $ '305/306'  // Este ano pagaremos agio de 10% para moscato e alicante com clas.A latada + trebiano (GLPI 9891)

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
		_aRet = {round (_nPrcRec, _nArredEnt), round (_nPrcCom, _nArredCom), _sComent, _aGrausInt, round (_nPrcMOC, _nArredMOC)}
	else
		if _lMostrMsg
			u_help (_sComent,, .t.)
		else
			U_help (_sComent,, .t.)
		endif

		_aRet = {0, 0, _sComent, _aGrausInt, 0}
	endif

//	u_log2 ('debug', 'Preco entrada: ' + cvaltochar (_aRet [1]))
//	u_log2 ('debug', 'Preco compra : ' + cvaltochar (_aRet [2]))
//	u_log2 ('debug', 'Preco MOC    : ' + cvaltochar (_aRet [5]))
// comentarios -->	u_log2 ('info', _aRet [3])
	U_ML_SRArea (_aAreaAnt)
return _aRet
