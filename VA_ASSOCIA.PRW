// Programa...: VA_ASSOCIA
// Autor......: DWT
// Data.......: 22/11/2013
// Descricao..: Função para mostrar somente os Associados do cadastro de fornecedores, além de só permitir alteração nos campos da aba Associados
//
// Historico de alteracoes:
// 02/12/2013 - Robert - Habilitados campos adicionais.
//                     - Criada consulta de capital social.
// 26/01/2014 - Robert - Criada consulta de cadastros viticolas.
// 18/01/2018 - Robert - Criadas consultas de grupos familiares e agenda safra.
// 21/10/2019 - Robert - Consulta de capital social passa a retornar (opcional) ano da ultima safra.
// 20/12/2019 - Robert - Passa a permitir tambem a alteracao do A2_NOME.
// 09/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 -  SX3 e SXA
// 01/12/2020 - Robert - Passa a buscar dados de cadastro viticola na view GX0001_AGENDA_SAFRA e nao mais na VA_VASSOC_CAD_VITIC2
//
// --------------------------------------------------------------------------------------------------
#include "VA_Inclu.prw"

User Function VA_ASSOCIA()
	Private cCadastro 	:= "Cadastro de Associados"
	Private cDelFunc 	:= ".F."
	Private cString 	:= "SA2"
	private aRotina 	:= {}
	
	aadd (aRotina, {"Pesquisar"				,  "AxPesqui"		, 0, 1})
	aadd (aRotina, {"Visualizar"			, "AxVisual"		, 0, 2})
	aadd (aRotina, {"Visualizar"			, "AxVisual"		, 0, 3})
	aadd (aRotina, {"Alterar"   			, "U_ASSOCALT ()"	, 0, 4})
	aadd (aRotina, {"Capital social"		, "U_ASSOCOut (1)"	, 0, 4})
	aadd (aRotina, {"Cad.viticolas"			, "U_ASSOCOut (2)"	, 0, 4})
	aadd (aRotina, {"Grupos familiares"		, "U_ASSOCOut (3)"	, 0, 4})
	aadd (aRotina, {"Variedades x safra"	, "U_ASSOCOut (4)"	, 0, 4})
		                       
	dbSelectArea("SA2")
	dbSetOrder(1)	 
	                                
	cExprFilTop := " EXISTS (SELECT * FROM " + RetSQLName ("SZI") + " WHERE D_E_L_E_T_ = '' AND ZI_ASSOC = A2_COD AND ZI_LOJASSO = A2_LOJA)"
	
	mBrowse(6,1,22,75,"SA2",,,,,,,,,,,,,,cExprFilTop)
Return
// --------------------------------------------------------------------------
// Função para alteração do cadastro de associados
User Function ASSOCALT() 
	local i        := 0
	local _aCampos := {}
	local _sFolder := ''
	private aCpos  := {}   
	
	// Alguns campos que nao estao na aba dos associados tambem ficam disponiveis para alteracao.
	aadd (_aCampos, "A2_END")
	aadd (_aCampos, "A2_BAIRRO")
	aadd (_aCampos, "A2_CEP")
	aadd (_aCampos, "A2_TEL")
	aadd (_aCampos, "A2_CELUL")
	aadd (_aCampos, "A2_CX_POST")
	aadd (_aCampos, "A2_FAX")
	aadd (_aCampos, "A2_HPAGE")
	aadd (_aCampos, "A2_EMAIL")
	aadd (_aCampos, "A2_VAMDANF")
	aadd (_aCampos, "A2_DDD")
	aadd (_aCampos, "A2_ENDCOMP")
	aadd (_aCampos, "A2_COMPLEM")
	aadd (_aCampos, "A2_NOME")

//	sxa -> (dbseek ('SA2', .T.))
//	do while ! sxa -> (eof ()) .and. sxa -> xa_alias == 'SA2'
//		if upper (alltrim (sxa -> xa_descric)) == upper ('Especificos')
//			_sFolder = sxa -> xa_ordem
//			exit
//		endif
//		sxa -> (dbskip ())
//	enddo
//	
//	DbSelectArea("SX3")
//	DbSetOrder(1)
//	DbSeek("SA2")
//	While !Eof() .and. SX3->X3_ARQUIVO == "SA2"
//		If X3Uso(SX3->X3_USADO) .and. (ascan (_aCampos, alltrim (sx3 -> x3_campo)) > 0 .or. SX3->X3_FOLDER == _sFolder) // para ver se está na Aba com informações dos associados
//			if ! alltrim (upper (sx3 -> x3_campo)) $ 'A2_VACBASE/A2_VALBASE'  // Estes nao quero deixar alterar
//				aadd(aCpos,alltrim(SX3->X3_CAMPO))
//			endif
//		EndIf
//		DbSkip()
//	End 
	
	_sFolder := '9' // Adicionado valor SXA fixo pois não será mais permitida a leitura do SXA na release 25, apenas em telas MVC possuímos funções
	_aCpoSX3 := FwSX3Util():GetAllFields('SA2')
		
	For i := 1 To Len(_aCpoSX3)
	    If(X3Uso(GetSx3Cache(_aCpoSX3[i], 'X3_USADO')) .and. (ascan (_aCampos, GetSx3Cache(_aCpoSX3[i],'X3_CAMPO')) > 0  .or. GetSx3Cache(_aCpoSX3[i], 'X3_FOLDER')== _sFolder))
	        aadd (aCpos, GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO'))
	    Endif
	Next i   
	
	AxAltera ("SA2",SA2->(recno()),4,NIL,aCpos)
Return
// --------------------------------------------------------------------------
// Chama consultas, relatorios e outras rotinas associadas (devem estar preparados para isso).
User Function AssocOut (_nQual)
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _oAssoc   := NIL
	local _aCadVit  := {}
	local _oSQL     := NIL
	local _sCapSoc  := ""

	_oAssoc := ClsAssoc():New (sa2 -> a2_cod, sa2 -> a2_loja)
	
	if valtype (_oAssoc) != "O"
		u_help ("Erro ao instanciar classe")
	else
		do case
		case _nQual == 1  // Saldo cota capital
			_sCapSoc = _oAssoc:SldQuotCap (dDataBase, .T.) [.QtCapRetTXT]
			u_log ('**************************************************')
			u_log (_sCapSoc)
			u_log ('**************************************************')
			U_ShowMemo (_sCapSoc, "DADOS DE CAPITAL")

		case _nQual == 2  // Cadastros viticolas
			_aCadVit = aclone (_oAssoc:CadVitic ())
			aadd (_aCadVit, {})
			ains (_aCadVit, 1)
			_aCadVit [1] = array (.CadVitQtColunas)
			_aCadVit [1, .CadVitCodigo]      = 'Cad.vitic.'
			_aCadVit [1, .CadVitCodGrpFam]   = 'Grupo familiar'
			_aCadVit [1, .CadVitNomeGrpFam]  = 'Nome grupo familiar'
			_aCadVit [1, .CadVitProduto]     = 'Produto'
			_aCadVit [1, .CadVitDescPro]     = 'Descricao'
			_aCadVit [1, .CadVitOrganico]    = 'Organico'
			_aCadVit [1, .CadVitSafrVit]     = 'Renovado p/'
			_aCadVit [1, .CadVitVarUva]      = 'Fina/comum'
		//	_aCadVit [1, .CadVitDescMun]     = 'Municipio'
		//	_aCadVit [1, .CadVitAmostra]     = 'Precisa amostra'
			_aCadVit [1, .CadVitRecebFisico] = 'Recebto.fisico'
			U_ShowArray (_aCadVit, "Cadastro(s) viticola(s) relacionados ao associado")

		case _nQual == 3  // Grupos familiares 
			U_ShowArray (_oAssoc:GrpFam ())

		case _nQual == 4  // Variedades esperadas / liberadas para recebimento na safra
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery += "SELECT *"
			_oSQL:_sQuery +=  " FROM GX0001_AGENDA_SAFRA"
			_oSQL:_sQuery += " WHERE GX0001_ASSOCIADO_CODIGO = '" + _oAssoc:Codigo + "'"
			_oSQL:_sQuery +=   " AND GX0001_ASSOCIADO_LOJA   = '" + _oAssoc:Loja   + "'"
			_oSQL:_sQuery += " ORDER BY GX0001_GRUPO_CODIGO, GX0001_SIVIBE_CODIGO, GX0001_PRODUTO_CODIGO"
			_oSQL:F3Array ("Cadastros viticolas e variedades esperados na safra", .T.)
		otherwise
			u_help ("Consulta / relatorio nao previsto.")
		endcase
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
return

