// Programa...: LJ7043
// Autor......: Cláudia Lionço
// Data.......: 04/10/2019
// Cliente....: Alianca
// Descricao..: P.E. "Valida tabela de preço" na tela de venda assistida.
// 				https://tdn.totvs.com/pages/releaseview.action?pageId=6790911
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. "Valida tabela de preço" na tela de venda assistida.
// #PalavasChave      #valida_tabela_de_preco #tabela_de_preco
// #TabelasPrincipais #SLQ #SA2 
// #Modulos   		  #LOJA 
//
// Historico de alteracoes:
// 08/10/2019 - Claudia - Alteradas regras de bloqueio de tabela conforme descrito no chamado GLPI 6657
// 07/11/2019 - Claudia - Alterada a mensagem quando CPF não informado para tabela 003
// 02/12/2019 - Robert  - Declaradas variaveis locais para for...next - tratamento para mensagem [For variable is not Local]
// 08/01/2020 - Claudia - Alterada validação de associado, pesquisando pelo código e loja base. GLPI 7305
// 11/01/2020 - Robert  - Variaveis _sCliente e _sLoja nao inicializadas
//                      - Renomeadas funcoes com nomes maiores que 10 caracteres
//                      - Gera aviso quando associado tiver mais de 1 codigo base.
// 19/02/2021 - Claudia - Incluidas tags de pesquisa
// 05/04/2021 - Robert  - Incluidas chamadas da funcao PerfMon para monitoramento de tempos de validacao de funcionarios e associados (GLPI 9573)
//                      - Nao salvava / restaurava a area de trabalho.
//

// ---------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User function LJ7043()
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _lRet     := .T.

	_sCGC     := M -> LQ_VACGC
	_sTabela  := PADL(alltrim(str(paramixb [1])),3,'0')
	
	If _sTabela == '003' 
	  	If empty(_sCGC)
	  		u_help('Para uso da tabela 003 o CPF deve estar informado. Verifique!')
	  		_lRet := .F.
	  	Else
	  		_lRet = _VerFunc(_sCGC,_sTabela,_lRet)
		EndIf
	EndIf

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return _lRet
//
//-----------------------------------------------------------------------------------------
// Verificar funcionario
Static Function _VerFunc(_sCGC,_sTabela,_lRet)
	local _sQuery2  	:= ""
	local _aFun			:= {}
	local _lRAssoc      := .T.
	
	U_PerfMon ('I', 'ValidarFuncOuAssocLJ7043')  // Deixa variavel pronta para posterior medicao de tempos de execucao

	_sQuery2 := " SELECT" 
	_sQuery2 += " 	  NOME"
	_sQuery2 += "    ,SITUACAO"
	_sQuery2 += "    ,CPF"
	_sQuery2 += " FROM LKSRV_SIRH.SIRH.dbo.VA_VFUNCIONARIOS"
	_sQuery2 += " WHERE CPF = '"+ alltrim(_sCGC) +"'"
	_aFun 	 := U_Qry2Array(_sQuery2)  

	If len(_aFun) <= 0 // verifica se eh socio jah que não eh funcionario
		_lRet   := _VerAssoc(_sCGC,_sTabela,'1',_lRet)
	Else
		_EhFun  := IIf(!empty(_aFun[1,1]),'S','N')
		_SitFun := alltrim(_aFun[1,2])
		
		If !empty(_aFun[1,2])
			If _EhFun == 'S' .and. (_SitFun == '3' .or. _SitFun == '4' )
				_lRFun := .F.
				_lRAssoc := _VerAssoc(_sCGC,_sTabela,'2',_lRet)// não é mais funcionário mas pode ser associado
				
				If _lRFun == .F. .and. _lRAssoc == .F.
					u_help('Este cliente não faz mais parte do quadro de funcionários e/ou não é associado! Não é permitida a utilização da tabela de preço '+_sTabela+'.')
					_lRet := .F.
				Else
					_lRet := .T.
				EndIf				
			EndIf
		Else
			_lRet := _VerAssoc(_sCGC,_sTabela,'1',_lRet)
		EndIf
	EndIf
	U_PerfMon ('F', 'ValidarFuncOuAssocLJ7043')
Return _lRet
//
//-----------------------------------------------------------------------------------------
// Verificar associados
Static Function _VerAssoc(_sCGC,_sTabela,_sTP,_lRet)
	local _dUltDiaMes := lastday ( Date() )
	local _sQuery1 	  := " "
	local _aFornece   := {}
	local x           := 0
	local _sCLiente   := ''
	local _sLoja      := ''
	local _oAviso     := NIL
	
	_sQuery1 += " SELECT"
	_sQuery1 += " 	A2_VACBASE,"
	_sQuery1 += " 	A2_VALBASE"
	_sQuery1 += " FROM SA2010"
	_sQuery1 += " WHERE D_E_L_E_T_ = ''"
	_sQuery1 += " AND A2_CGC = '"+alltrim(_sCGC)+"'"
	_sQuery1 += " AND A2_VACBASE = A2_COD "
	_sQuery1 += " AND A2_VALBASE = A2_LOJA "
	_aFornece := U_Qry2Array(_sQuery1) 
				
	if len (_aFornece) > 1
		_oAviso := ClsAviso ():New ()
		_oAviso:Tipo       = 'A'
		_oAviso:Destinatar = 'robert'
		_oAviso:Texto      = 'Associado com mais de 1 codigo base. CPF: ' + _sCGC
		_oAviso:Origem     = procname ()
		_oAviso:DiasDeVida = 90
		_oAviso:CodAviso   = '010'
		_oAviso:Grava ()
	endif

	For x := 1 to len(_aFornece)
		_sCliente := alltrim(_aFornece[x,1])
		_sLoja    := alltrim(_aFornece[x,2])
	Next
	//
	If !empty(_sCliente) .and. !empty(_sLoja)
		// Instancia classe para verificacao dos dados do associado.
		_oAssoc := ClsAssoc():New (_sCliente,_sLoja)
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
		Do Case
			Case _EhSocio == 'S' .and. _SocioAtivo == 'S' .and. _sTabela == '003' 
				_lRet := .T.
			Case _EhSocio == 'S' .and. _SocioAtivo == 'N'
				If _sTP == '1'
					u_help('Este cliente é sócio mas não está ativo! Não é permitida a utilização da tabela de preço '+_sTabela+'.')
				EndIf
				_lRet := .F.
			Case _EhSocio == 'N' .and. _sTabela == '003' 
				If _sTP == '1'
					u_help('Este cliente não é sócio! Não é permitida a utilização da tabela de preço '+_sTabela+'.')
				EndIf
				_lRet := .F.
		EndCase
	Else
		_lRet := .F.
	EndIf
Return _lRet
