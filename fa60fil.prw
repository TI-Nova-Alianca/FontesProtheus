// Programa...: FA60FIL
// Autor......: Jeferson Rech
// Data.......: 06/2002
// Descricao..: Filtro Geracao do Bordero - Financeiro 
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Filtro Geracao do Bordero - Financeiro 
// #PalavasChave      #bordero #banco
// #TabelasPrincipais #SE1 #SA1
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
// 08/06/2015 - Robert  - Passa a validar o campo A1_VAEBOL.
//                      - Passa a salvar area de trabalho e usar variavel para retorno.
// 05/01/2021 - Claudia - Retirada a inclusão de portador vazio da tela. GLPI: 8962
//
// ------------------------------------------------------------------------------------------
#include "rwmake.ch"

User Function fa60fil()
	local _sRet     := ""
	local _aAreaAnt := U_ML_SRArea ()
	//IF SE1->E1_CLIENTE $ getmv('ML_CLIC19')
	IF fBuscaCpo ("SA1", 1, xfilial ("SA1") + SE1->E1_CLIENTE + se1 -> e1_loja, "A1_VAEBOL") == "B"
	   _sRet = "Empty(SE1->E1_PORT2)"
	ELSE 
	   //_sRet = "(SE1->E1_PORT2==cPort060 .And. !Empty(SE1->E1_NUMBCO)) .Or. Empty(SE1->E1_PORT2)"
	   _sRet = "(SE1->E1_PORT2==cPort060 .And. !Empty(SE1->E1_NUMBCO))"
	ENDIF   
   	U_ML_SRArea (_aAreaAnt)
return _sRet

