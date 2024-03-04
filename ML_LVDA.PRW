// Programa..: ML_LVDA.PRX
// Autor.....: Ricardo
// Data......: 20/04/1999 
// Nota......: ExecBlock Lancto Padrao Vendas
//
// #TipoDePrograma    #processamento
// #Descricao         #ExecBlock Lancto Padrao Vendas
// #PalavasChave      #LPAD #lancamento_padrao 
// #TabelasPrincipais #SD2 #SF4
// #Modulos           #CTB 
//
// Parametros: _nEcomm
// 1 - Retorna valor 0 para notas e-commerce
// 2 - Retorna valor para notas e-commerce
// 3 - Retorna conta contabil por bandeira
// 4 - Retorna valor credito
//
// Historico de alteracoes:
// 16/06/2008 - Robert  - Passa a validar o parametro VA_SERIECF
// 29/07/2009 - Robert  - Passa a somar d2_icmsret no valor retornado
// 18/03/2010 - Robert  - TES 603 (venda sucata) retorna valor zerado.
// 20/11/2020 - Claudia - Incluida validações para notas do e-commerce 
// 05/04/2021 - Claudia - Acrescentado valor de frete para LPAD 610 000 e 610 001. GLPI: 9753
// 02/12/2021 - Claudia - Incluida validação para produtos 7209/7210. GLPI: 11136
// 19/07/2022 - Robert  - Incluido TES 727 para nao contabilizar.
// 21/09/2022 - Robert  - Descontar VALIRRF para _nEcomm='1'
// 01/12/2022 - Claudia - Incluida regra conforme GLPI: 12854	
// 09/12/2022 - Robert  - Soma ICMSRET somente quando F4_CREDST=2 nas opcoes '1' e '4' (GLPI 12883)
// 06/01/2023 - Claudia - Aplicada regra conforme GLPI: 12854	
// 25/01/2023 - Claudia - Voltada a versão do programa. GLPI: 13087
// 24/02/2023 - Claudia - Ajustado o lançamento padrão 610 000 (parametro 1). GLPI: 13218
// 20/02/2024 - Robert  - Opcao 4 alterada temporariamente para recontabilizacao de 2023 onde queremos apenas IPI e ST ---> _wVAL := SD2->D2_TOTAL + SD2->D2_VALIPI + sd2->d2_icmsret + SD2->D2_VALFRE - iif (_nEcomm == '1', sd2->d2_VALIRRF, 0) // Volta a ser como era em 31/12/2022
// 28/02/2024 - RObert  - Chamadas de metodos da classe ClsSQL nao recebiam parametros.
// 20/02/2024 - Robert  - Opcao 4 volta para contabilizacao normal (apos recontab.de 2023 feita dia 20/02/24)
//

// -------------------------------------------------------------------------------------------------
User Function ML_LVDA(_nEcomm)
	Local _aDados := {}
	Local _lEcomm := .F.
	Local _sADM   := ""
	Local _oSQL   := ClsSQL ():New ()

	SetPrvt("_WVAL,")

	// Verifica se é nota do ecommerce
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DISTINCT E1_ADM "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1")
	_oSQL:_sQuery += " WHERE E1_FILIAL = '" + SD2->D2_FILIAL + "'"
	_oSQL:_sQuery += " AND E1_NUM      = '" + SD2->D2_DOC    + "'"
	_oSQL:_sQuery += " AND E1_PREFIXO  = '10'"
	_oSQL:_sQuery += " AND E1_TIPO IN('CC','CD') "
	_oSQL:_sQuery += " AND E1_ADM <> ''"
	_aDados := _oSQL:Qry2Array (.f., .f.)

	If Len(_aDados) > 0
		_lEcomm := .T.
		_sADM   := _aDados[1,1]
	EndIf

	// Se notas ecommerce 610 029
	If _lEcomm == .T.
		Do Case
			Case _nEcomm == '2'      // Nota ecommerce que retorna valor
					_wVAL := SD2->D2_TOTAL + SD2->D2_VALIPI + SD2->D2_ICMSRET + SD2->D2_VALFRE

			Case _nEcomm == '3'      // Retorna conta contabil
				Do Case
					Case _sADM == "100" .or. _sADM == "101"
						_wVAL:= "101021101002"
					Case _sADM == "200" .or. _sADM == "201"
						_wVAL:= "101021101001"
					Case _sADM == "300" .or. _sADM == "301"
						_wVAL:= "101021101003"
					Case _sADM == "400" .or. _sADM == "401"
						_wVAL:= "101021101004"
					otherwise
						_wVAL:= "101021101005"
				EndCase  
			Case _nEcomm == '4'
				If  SF4->F4_DUPLIC<>"S" .or. SD2->D2_TIPO=="D" .or. SD2->D2_TES$"518/510/603/727" .or. SD2->D2_SERIE $ GetMV ("VA_SERIECF") .or. SF4->F4_TOCON$('15/16')
					_wVAL := 0
				Else
					_wVAL := SD2->D2_TOTAL + SD2->D2_VALIPI + SD2->D2_ICMSRET + SD2->D2_VALFRE // até 31/12/2022
				//	_wVAL := SD2->D2_TOTAL +                                    SD2->D2_VALFRE // a partir de 01/01/2023
				EndIf
		EndCase

	Else // Não é notas ecommerce 
		If _nEcomm == '1'  // 610 000 e 610 001
			If  SF4->F4_DUPLIC<>"S" .or. SD2->D2_TIPO=="D" .or. SD2->D2_TES$"518/510/603/727" .or. SD2->D2_SERIE $ GetMV ("VA_SERIECF") .or. SF4->F4_TOCON$('15/16') .or. alltrim(SD2->D2_COD) $ ('7209/7210')
				_wVAL := 0
			Else
				If SD2->D2_TES=="918" // ST MG
					_wVAL := SD2->D2_TOTAL + SD2->D2_VALIPI + SD2->D2_VALFRE - iif (_nEcomm == '1', sd2->d2_VALIRRF, 0) 
				Else
					_wVAL := SD2->D2_TOTAL + SD2->D2_VALIPI + sd2->d2_icmsret + SD2->D2_VALFRE - iif (_nEcomm == '1', sd2->d2_VALIRRF, 0)
				EndIf
			EndIf
		Else 
			If _nEcomm == '4' // 610 000 e 610 001
				If  SF4->F4_DUPLIC<>"S" .or. SD2->D2_TIPO=="D" .or. SD2->D2_TES$"518/510/603/727" .or. SD2->D2_SERIE $ GetMV ("VA_SERIECF") .or. SF4->F4_TOCON$('15/16') .or. alltrim(SD2->D2_COD) $ ('7209/7210')
					_wVAL := 0
				Else
					if SD2->D2_TES=="918" // ST MG
						_wVAL := SD2->D2_TOTAL + SD2->D2_VALIPI +                   SD2->D2_VALFRE - iif (_nEcomm == '1', sd2->d2_VALIRRF, 0) // Volta a ser como era em 31/12/2022
					else
						_wVAL := SD2->D2_TOTAL + SD2->D2_VALIPI + sd2->d2_icmsret + SD2->D2_VALFRE - iif (_nEcomm == '1', sd2->d2_VALIRRF, 0) // Volta a ser como era em 31/12/2022
					endif
				EndIf
			EndIf
		EndIf
	EndIf
Return (_wVAL)
