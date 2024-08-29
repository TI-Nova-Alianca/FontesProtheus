// Programa..: ImpParTRep
// Autor.....: Cláudia Lionço
// Data......: 28/08/2024
// Descricao.: Imprime parametros no corpo do relatorio tipo TREPORT

// #TipoDePrograma    #generico
// #Descricao         #Imprime parametros no corpo do relatorio tipo TREPORT
// #PalavasChave      #parametros #relatorio #TREPORT
// #TabelasPrincipais #SX1
// #Modulos 		  #todos 

// Historico de alteracoes:
// 28/08/2024 - Claudia - Baseado no programa ImpParam.prw
//
// -------------------------------------------------------------------------------------
User Function ImpParTRep()
	local _aAreaAnt  := U_ML_SRArea()
	local _sPerg     := iif(type("cPerg") == "C", cPerg, "")
	local _aLinhas   := {}
	local _sLinha    := ""
	local _aSX1      := {}
	local _x         := 0

	// Monta array com cada pergunta e sua resposta em uma linha.
	_oSQL:= ClsSQL():New()
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
	_aSX1  = aclone(_oSQL:Qry2Array(.f., .f.))

	For _x:= 1 to Len(_aSX1)
		_sX1_GRUPO	 := _aSX1[_x, 1]
		_sX1_ORDEM   := _aSX1[_x, 2]
		_sX1_GSC	 := _aSX1[_x, 3]
		_nX1_TAMANHO := _aSX1[_x, 4]
		_nX1_DECIMAL := _aSX1[_x, 5]
		_sX1_PERGUNT := _aSX1[_x, 6]

		_sLinha := ""
		cVar    := "MV_PAR" + StrZero(val(_sX1_ORDEM),2,0)
		_sLinha += _sX1_ORDEM + "-" + U_TamFixo(alltrim(_sX1_PERGUNT), 30, '.') + ': '

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
				If(_nX1_DECIMAL>0 )
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
		aadd(_aLinhas, alltrim(_sLinha))
	Next

	U_ML_SRArea(_aAreaAnt)
Return _aLinhas
