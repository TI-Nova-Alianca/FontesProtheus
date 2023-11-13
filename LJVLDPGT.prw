// Programa.:  LJVLDPGT
// Autor....:  Cláudia Lionço
// Data.....:  08/10/2019
// Cliente..:  Alianca
// Descricao:  P.E. "Valida forma de pagamento" na tela de venda assistida.
// 			   https://tdn.totvs.com/pages/releaseview.action?pageId=201720179
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. "Valida forma de pagamento" na tela de venda assistida.
// #PalavasChave      #valida_forma_de_pagamento
// #TabelasPrincipais #SA2 
// #Modulos   		  #LOJA 
//
// Historico de alteracoes:
// 08/01/2020 - Claudia - Alterada validação de associado, pesquisando pelo código e loja base. GLPI 7305
// 05/04/2021 - Robert  - Incluidas chamadas da funcao PerfMon para monitoramento de tempos de validacao de 
//                        funcionarios e associados (GLPI 9573)
//                      - Nao salvava / restaurava a area de trabalho.
// 01/09/2022 - Robert  - Eliminadas chamadas da funcao U_PerfMon().
// 13/11/2023 - Claudia - Incluido parametro "VA_LOJASSO". GLPI: 14505
//
// --------------------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include 'rwmake.ch' 

User Function LJVLDPGT()
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	Local _lRet 	:= .T.
	//Local dData 	:= PARAMIXB[01]
	//Local nValor 	:= PARAMIXB[02]
	Local cFPgto	:= PARAMIXB[03]
	//Local nQdeParc 	:= PARAMIXB[04]
	Local sCGC      := M -> LQ_VACGC
	Local cPosProd  := AScan(aHeader,{|x| Alltrim(x[2]) == "LR_PRODUTO"})  // retorna conteudo do campo
	Local lVale     := .F.
	Local nJ		:= 0
	
	If Alltrim(UPPER(cFPgto)) == 'CONVENIO' 
		For nJ:= 1 To Len(aCols) 
			cProd := aCols[nJ,cPosProd] 
			
			If alltrim(cProd) == 'VALE'
				lVale := .T.
			EndIf
		Next 

		If empty(sCGC) .and. lVale == .F. // se não tiver CFP e não for vale
	  		u_help('Cliente sem CPF informado! Não é permitida a utilização dessa forma de pagamento.')
	  		_lRet := .F.
	  	Else
	  		If lVale == .F.
	  			_lRet = _VerFunc(sCGC,_lRet)
	  		EndIf
		EndIf
	EndIf
	
	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
Return _lRet

//-----------------------------------------------------------------------------------------
Static Function _VerFunc(sCGC,_lRet)
	local _sQuery2  	:= ""
	local _aFun			:= {}
	local _lRFun		:= .T.
	local _lRAssoc	    := .T.
	
	_sQuery2 += " SELECT" 
	_sQuery2 += " 	NOME"
	_sQuery2 += "    ,SITUACAO"
	_sQuery2 += "    ,CPF"
	_sQuery2 += " FROM LKSRV_SIRH.SIRH.dbo.VA_VFUNCIONARIOS"
	_sQuery2 += " WHERE CPF = '"+ alltrim(sCGC) +"'"
	_aFun 	 := U_Qry2Array(_sQuery2)  
	//
	If len(_aFun) <= 0 // verifica se eh socio jah que não eh funcionario
		if GETMV("VA_LOJASSO") == .T.
			_lRet := .T.
		else
			_lRet = _VerAssoc(sCGC,_lRet)
		endif
	Else
		_EhFun  := IIf(!empty(_aFun[1,1]),'S','N')
		_SitFun := alltrim(_aFun[1,2])
		
		If !empty(_aFun[1,2])
			If _EhFun == 'S' .and. (_SitFun == '3' .or. _SitFun == '4' )
				_lRFun := .F.
				_lRAssoc := _VerAssoc(sCGC,_lRet)  // não é mais funcionário mas pode ser associado
				
				If _lRFun == .F. .and. _lRAssoc == .F.
					u_help('Este cliente não faz mais parte do quadro de funcionários e/ou não é associado!')
					_lRet := .F.
				Else
					_lRet := .T.
				EndIf	
			EndIf
		Else
			if GETMV("VA_LOJASSO") == .T.
				_lRet := .T.
			else
				_lRet = _VerAssoc(sCGC,_lRet)
			endif
		EndIf
	EndIf
	
Return _lRet

//-----------------------------------------------------------------------------------------
Static Function _VerAssoc(sCGC,_lRet)
	local _dUltDiaMes := lastday ( Date() )
	local _sQuery1 	  := " "
	local _aFornece   := {}
	local x			  := 0
	
	_sQuery1 += " SELECT"
	_sQuery1 += " 	A2_VACBASE,"
	_sQuery1 += " 	A2_VALBASE"
	_sQuery1 += " FROM SA2010"
	_sQuery1 += " WHERE D_E_L_E_T_ = ''"
	_sQuery1 += " AND A2_CGC = '"+alltrim(sCGC)+"'"
	_sQuery1 += " AND A2_VACBASE = A2_COD "
	_sQuery1 += " AND A2_VALBASE = A2_LOJA "
	_aFornece := U_Qry2Array(_sQuery1) 
	
	If len(_aFornece) <= 0
		u_help(" Não encontrado CPF no cadastro como associado!")
		_lRet := .F.
	Else
		For x := 1 to len(_aFornece)
			sCliente := alltrim(_aFornece[x,1])
			sLoja    := alltrim(_aFornece[x,2])
		Next
		//
		If !empty(sCliente) .and. !empty(sLoja)
			// Instancia classe para verificacao dos dados do associado.
			_oAssoc := ClsAssoc():New (sCliente,sLoja)
			incproc (_oAssoc:Nome)
		
			If _oAssoc:EhSocio (_dUltDiaMes)
				_EhSocio := 'S'
				
				If _oAssoc:Ativo (_dUltDiaMes)
					_SocioAtivo := 'S'
				Else
					_SocioAtivo := 'N'
				Endif
			Else
				_EhSocio := 'N'
			Endif
			//
			If _EhSocio == 'S' .and. _SocioAtivo == 'S' 
				_lRet := .T.
			Else
				u_help('Não é permitida a forma de pagamento CONVENIO para este cliente! Apenas clientes e sócios ativos são permitidos.')
				_lRet := .F.
			EndIf
		EndIf
	EndIf
Return _lRet
