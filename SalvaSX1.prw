// Programa.: SalvaSX1
// Autor....: Robert Koch
// Data.....: 02/08/2011
// Descricao: Utilitario para salvar e restaurar backup de parametros no SX1 e profile do usuario.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #generico
// #PalavasChave      #parametros #perguntas #automacao #auxiliar #uso_generico
// #TabelasPrincipais #SX1 #PROFILE
// #Modulos           #todos
//
// Utilizacao: Para salvar, informar o grupo de perguntas.
//             Para restaurar, informar o grupo de perguntas e a array gerada pelo backup.
//             Ex.:
//             user function teste ()
//                local _aAnt := U_SalvaSX1 (cPerg)
//                // ... procedimentos ...
//                U_SalvaSX1 (cPerg, _aAnt)
//             return
//
// Historico de alteracoes:
// 14/05/2021 - Cláudia - Ajuste SX1 para R27. GLPI: 8825
//
// -----------------------------------------------------------------------------------------------

user function SalvaSX1 (_sPerg, _aRest)
	local _aAreaAtu := getarea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _aBak     := {}
	local _nRest    := 0
	local _x        := 0

	// Se nao recebi a array a restaurar, entao presumo que seja para salvar.
	if valtype (_aRest) == "U"
		
		// Busca parametros atuais, inclusive do profile do usuario, se for o caso.
		Pergunte (_sPerg, .F.)
		
		// Salva somente as perguntas existentes no SX1 (o sistema tem pelo menos 40 variaveis private e nem todas sao usadas).
		_oSQL  := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT"
		_oSQL:_sQuery += " 	   X1_GRUPO"
		_oSQL:_sQuery += "    ,X1_ORDEM"
		_oSQL:_sQuery += " FROM SX1010 "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND X1_GRUPO     = '" + alltrim(_sPerg) + "'"
		_aSX1 := aclone (_oSQL:Qry2Array ())	

		_aBak := {}
		for _x:= 1 to Len(_aSX1)
			_sOrd := _aSX1[_x, 2]
			aadd (_aBak, {_sOrd, &("mv_par" + _sOrd)})
		next

	elseif valtype (_aRest) == "A"
		for _nRest = 1 to len (_aRest)
			U_GravaSX1 (_sPerg, _aRest [_nRest, 1], _aRest [_nRest, 2])
		next
	endif
	
	U_SalvaAmb (_aAmbAnt)
	restarea (_aAreaAtu)
return _aBak
