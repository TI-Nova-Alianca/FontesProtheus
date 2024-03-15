// Programa..: ImpParam
// Autor.....: Robert Koch - TCX021
// Data......: 03/2007
// Descricao.: Imprime parametros no corpo do relatorio, quando solicitado.

// #TipoDePrograma    #generico
// #Descricao         #ros no corpo do relatorio, quando solicitado.
// #PalavasChave      #parametros #relatorio 
// #TabelasPrincipais #SX1
// #Modulos 		  #todos 

// Historico de alteracoes:
// 02/05/2007 - Robert  - Busca largura para filtro cfe. tamanho do relatorio.
// 20/10/2008 - Robert  - Controla qt. linhas para gerar novo cabecalho.
// 30/12/2008 - Robert  - Cria valores default para variaveis private, caso nao existam.
// 22/01/2009 - Robert  - Imprime tambem a opcao de ordenacao, caso tenha sido selecionada.
// 21/07/2011 - Robert  - Imprime em colunas para reduzir numero de linhas impressas.
// 28/05/2013 - Robert  - desconsiderava nome completo das perguntas no While 
//                        (ex.: SZI_REL e SZI_REL2)
// 07/05/2021 - Claudia - Ajustado retirando SX1 conforme R27. GLPI: 8825
// 11/05/2021 - Claudia - Ajuste retirando o DbSkip. GLPI: 10008
// 31/03/2023 - Robert  - Nao trazia a descricao atualizada da pergunta.
// 14/03/2024 - Robert  - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//

// -------------------------------------------------------------------------------------
user function ImpParam (_nMaxLin)
	local _aAreaAnt  := U_ML_SRArea ()
	local _sTitulo   := iif (type ("cTitulo")  == "C", cTitulo,  "")
	local _sCabec1   := iif (type ("cCabec1")  == "C", cCabec1,  "")
	local _sCabec2   := iif (type ("cCabec2")  == "C", cCabec2,  "")
	local _sNomeProg := iif (type ("NomeProg") == "C", NomeProg, "")
	local _sTamanho  := iif (type ("Tamanho")  == "C", Tamanho,  "M")
	local _nLargura  := iif (_sTamanho         == "M", 132, iif (_sTamanho == "G", 220, 80))
	local _nTipo     := iif (type ("nTipo")    == "N", nTipo,    15)
	local _sPerg     := iif (type ("cPerg")    == "C", cPerg,    "")
	local _aReturn   := iif (type ("aReturn")  == "A", aclone (aReturn), {"", 0, "", 1, 1, "", "", 0})
	local _aOrd      := iif (type ("aOrd")     == "A", aclone (aOrd), {})
	local _aLinhas   := {}
	local _sLinha    := ""
	local _nCol		 := 0
	local _nLinha	 := 0
	local _aSX1      := {}
	local _x         := 0

	// Monta array com cada pergunta e sua resposta em uma linha.
	_oSQL  := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += " 	   X1_GRUPO"
	_oSQL:_sQuery += "    ,X1_ORDEM"
	_oSQL:_sQuery += "    ,X1_GSC"
	_oSQL:_sQuery += "    ,X1_TAMANHO"
	_oSQL:_sQuery += "    ,X1_DECIMAL"
	_oSQL:_sQuery += "    ,X1_PERGUNT"
	_oSQL:_sQuery += " FROM SX1010 "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND X1_GRUPO     = '" + alltrim(_sPerg) +"'"
	_aSX1  = aclone (_oSQL:Qry2Array (.f., .f.))

	For _x:= 1 to Len(_aSX1)
		_sX1_GRUPO	 := _aSX1[_x, 1]
		_sX1_ORDEM   := _aSX1[_x, 2]
		_sX1_GSC	 := _aSX1[_x, 3]
		_nX1_TAMANHO := _aSX1[_x, 4]
		_nX1_DECIMAL := _aSX1[_x, 5]
		_sX1_PERGUNT := _aSX1[_x, 6]

		_sLinha := ""
		cVar    := "MV_PAR"+StrZero(Val(_sX1_ORDEM),2,0)
	//	_sLinha += _sX1_ORDEM + "-"+ U_TamFixo (alltrim (X1Pergunt()), 30, '.') + ': '
		_sLinha += _sX1_ORDEM + "-"+ U_TamFixo (alltrim (_sX1_PERGUNT), 30, '.') + ': '

		If _sX1_GSC == "C"
			xStr:=StrZero(&cVar,2)
			If ( &(cVar)==1 )
				_sLinha += X1Def01()
			ElseIf ( &(cVar)==2 )
				_sLinha += X1Def02()
			ElseIf ( &(cVar)==3 )
				_sLinha += X1Def03()
			ElseIf ( &(cVar)==4 )
				_sLinha += X1Def04()
			ElseIf ( &(cVar)==5 )
				_sLinha += X1Def05()
			Else
				_sLinha += ''
			EndIf
		Else

			uVar := &(cVar)
			If ValType(uVar) == "N"
				cPicture:= "@E "+Replicate("9",_nX1_TAMANHO-_nX1_DECIMAL-1)
				If( _nX1_DECIMAL>0 )
					cPicture+="."+Replicate("9",_nX1_DECIMAL)
				Else
					cPicture+="9"
				EndIf
				_sLinha += Transform(uVar,cPicture)
			Elseif ValType(uVar) == "D"
				_sLinha += DTOC(uVar)
			Else
				_sLinha += uVar
			EndIf
		EndIf
		aadd (_aLinhas, alltrim (_sLinha))
	Next

	if len (_aLinhas) > 0
		_oAUtil:= ClsAUtil():New (_aLinhas)
		_aLinhas2 = _OAUtil:QuebraCol (_nLargura - 12, 3)
		
		// Impressao dos parametros.
		if li > _nMaxLin - 2
			cabec(_sTitulo, _sCabec1, _sCabec2, _sNomeProg, _sTamanho, _nTipo)
		endif
		@ li, 0 psay __PrtFatLine ()
		li ++
		@ li, 0 psay "Parametros: "
		for _nLinha = 1 to len (_aLinhas2)
			if li > _nMaxLin
				cabec(_sTitulo, _sCabec1, _sCabec2, _sNomeProg, _sTamanho, _nTipo)
			endif
			_sLinha = ''
			for _nCol = 1 to len (_aLinhas2 [_nLinha])
				_sLinha += _aLinhas2 [_nLinha, _nCol] + '  '
			next
			@li, 12 psay _sLinha
			li ++
		next
	endif

	// Busca filtro
	cFiltro := Iif (!Empty(_aReturn[7]),MontDescr(cString,_aReturn[7]),"")
	nCont := 1
	If !Empty(cFiltro)
		li+=2
		@ li, 0 PSAY "Filtro....: " + Substr(cFiltro,nCont,_nLargura-19)
		While Len(AllTrim(Substr(cFiltro,nCont))) > (_nLargura-12)
			if li > _nMaxLin
				cabec(_sTitulo, _sCabec1, _sCabec2, _sNomeProg, _sTamanho, _nTipo)
			endif
			nCont += _nLargura - 12
			li+=1
			@ li,12	PSAY Substr(cFiltro,nCont,_nLargura-19)
		Enddo
		li++
	EndIf
	
	// Busca ordenacao
	if _aReturn [8] > 0 .and. _aReturn [8] <= len (_aOrd)
		@ li, 0 psay "Ordenacao.: " + cvaltochar (_aReturn [8]) + " - " + _aOrd [_aReturn [8]]
		li ++
	endif
	li += 2

	U_ML_SRArea (_aAreaAnt)
return
