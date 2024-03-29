// Programa.: Mta103Mnu
// Autor....: Robert Koch
// Data.....: 18/09/2013
// Descricao: P.E. antes de montar MBrowse na tela de NF de entrada.
//   
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. antes de montar MBrowse na tela de NF de entrada.
// #PalavasChave      #documento_de_entrada #menu_documento_de_entrada
// #TabelasPrincipais #SD1 #SF1 #SE2 
// #Modulos 		  #COM         
//
// Historico de alteracoes:
// 23/08/2017 - Catia   - Botao para liberar NF de importa��o
// 11/10/2019 - Cl�udia - Botao para gerar etiqueta de NF entrada"
// 08/06/2021 - Cl�udia - Incluido o botao para alterar a natureza. GLPI: 10083
// 02/08/2022 - Robert  - Inclu�da chamada para manifesto da TRS (GLPI 12418)
//                      - Inclu�da consulta de enderecamentos (GLPI 12421)
// 31/03/2023 - Robert  - Novos parametros chamada U_VA_SZNC()
//

// ---------------------------------------------------------------------------------
user function Mta103Mnu ()
	local _aRotAdic := {}

	aadd (_aRotAdic, {"Eventos Alianca" 	, "U_VA_SZNC  ('NFENTRADA', sf1 -> f1_doc, sf1 -> f1_serie, sf1 -> f1_fornece, sf1 -> f1_loja, sf1 -> f1_chvnfe)", 0, 6, 0, NIL})
	aadd (_aRotAdic, {"Eventos NF-e(SEFAZ)"	, "U_EvtNFe   ('E', sf1 -> f1_doc, sf1 -> f1_serie, sf1 -> f1_fornece, sf1 -> f1_loja)", 0, 6, 0, NIL})
	aadd (_aRotAdic, {"Dados adicionais"	, "U_NFDAdicC ('E', sf1 -> f1_doc, sf1 -> f1_serie, sf1 -> f1_fornece, sf1 -> f1_loja)", 0, 6, 0, NIL})
	aadd (_aRotAdic, {"NF Import.FLAG"  	, "U_NFImpFlag( sf1 -> f1_doc, sf1 -> f1_serie, sf1 -> f1_fornece, sf1 -> f1_loja)", 0, 6, 0, NIL})
	aadd (_aRotAdic, {"Gera Etq NF entrada"	, "U_EtqPllGN ()", 0, 6, 0, NIL})
	aadd (_aRotAdic, {"Altera Natureza"	    , "U_VA_ALTNAT(sf1->f1_filial, sf1 -> f1_doc, sf1 -> f1_serie, sf1 -> f1_fornece, sf1 -> f1_loja)", 0, 6, 0, NIL})
	aadd (_aRotAdic, {"Manifesto SEFAZ(TRS)", "U_FBTRS102(.T.)", 0, 6, 0, NIL})
	aadd (_aRotAdic, {"Enderecamentos"      , "processa ({||U_ConsSDB (sf1->f1_doc, sf1->f1_serie)})", 0, 6, 0, NIL})
	
	aadd (aRotina, {"Especificos"           , _aRotAdic, 0, 6, 0, NIL})
return
//
// --------------------------------------------------------------------------
// Seta flag da nota de importacao permtindo que seja excluida a nota
user function NFImpFlag ( _wdoc, _wserie, _wfornece, _wloja)

	_sSQL := ""
	_sSQL += " UPDATE SD1010"
   	_sSQL += "    SET D1_TIPO_NF = ''"  
 	_sSQL += "  WHERE D1_FILIAL  = '" + xfilial('SD1') + "'"
   	_sSQL += "    AND D1_DOC     = '" + _wdoc 	  + "'"
   	_sSQL += "    AND D1_SERIE   = '" + _wserie   + "'"
   	_sSQL += "    AND D1_FORNECE = '" + _wfornece + "'"
   	_sSQL += "    AND D1_LOJA    = '" + _wloja    + "'"
   	_sSQL += "    AND D_E_L_E_T_ = '' "
   	
   	if TCSQLExec (_sSQL) < 0
       U_AvisaTI ("Erro - Nao foi possivel alterar FLAG na NF de importa��o (NF/SERIE/CLIENTE): " + _wdoc + '/' + _wserie + '/' + _wfornece)
    endif   
	    	
return
