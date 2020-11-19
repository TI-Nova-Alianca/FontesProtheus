// Programa...: VA_MAQUINA
// Autor......: Júlio Pedroni
// Data.......: 16/03/2017
// Descricao..: Função para mostrar somente os Ativos utilizados pelo Industrial.
//
// Historico de alteracoes:
// 09/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 -  SX3 e SXA
//
// --------------------------------------------------------------------------
#include "VA_Inclu.prw"

User Function VA_MAQUINA()
	Private cCadastro := "Cadastro de Ativos / Máquinas"
	Private cDelFunc := ".F."
	Private cString := "SN1"
	private aRotina := {}
	aadd (aRotina, {"Pesquisar",  "AxPesqui", 0, 1})
	aadd (aRotina, {"Visualizar", "AxVisual", 0, 2})
	aadd (aRotina, {"Visualizar", "AxVisual", 0, 3})
	aadd (aRotina, {"Alterar"   , "U_MAQUIALT ()", 0, 4})
		                       
	dbSelectArea("SN1")
	dbSetOrder(1)	 
	                                
	cExprFilTop := " EXISTS (SELECT * FROM " + RetSQLName ("SNG") + " WHERE D_E_L_E_T_ = '' AND NG_GRUPO = N1_GRUPO AND NG_INDUSTR = 'S')"
	
	mBrowse(6,1,22,75,"SN1",,,,,,,,,,,,,,cExprFilTop)
Return
// --------------------------------------------------------------------------
// Função para alteração do cadastro de associados
User Function MAQUIALT() 
	local aCpos    := {}
	local _aCampos := {}
	local _sFolder := ''
	local i        := 0
	//private aCpos  := {}   
	
	// Alguns campos que nao estao na aba dos associados tambem ficam disponiveis para alteracao.
	//aadd (_aCampos, "<NOME_CAMPO>")

//	sxa -> (dbseek ('SN1', .T.))
//	do while ! sxa -> (eof ()) .and. sxa -> xa_alias == 'SN1'
//		if upper (alltrim (sxa -> xa_descric)) == upper ('Industrial')
//			_sFolder = sxa -> xa_ordem
//			exit
//		endif
//		sxa -> (dbskip ())
//	enddo
//	
//	DbSelectArea("SX3")
//	DbSetOrder(1)
//	DbSeek("SN1")
//	While !Eof() .and. SX3->X3_ARQUIVO == "SN1"
//		If X3Uso(SX3->X3_USADO) .and. (ascan (_aCampos, alltrim (sx3 -> x3_campo)) > 0 .or. SX3->X3_FOLDER == _sFolder) // para ver se está na Aba com informações do industrial
//			if ! alltrim (upper (sx3 -> x3_campo)) $ '<NOME_CAMPO>/<NOME_CAMPO>'  // Estes nao quero deixar alterar
//				aadd(aCpos,alltrim(SX3->X3_CAMPO))
//				aadd(aCpos,'')
//			endif
//		EndIf
//		DbSkip()
//	End 
	
	_sFolder := 'B' // Adicionado valor SXA fixo pois não será mais permitida a leitura do SXA na release 25, apenas em telas MVC possuímos funções
	_aCpoSX3 := FwSX3Util():GetAllFields('SN1')
		
	For i := 1 To Len(_aCpoSX3)
	    If(X3Uso(GetSx3Cache(_aCpoSX3[i], 'X3_USADO')) .and. (ascan (_aCampos, GetSx3Cache(_aCpoSX3[i],'X3_CAMPO')) > 0  .or. GetSx3Cache(_aCpoSX3[i], 'X3_FOLDER')== _sFolder))
	        aadd (aCpos, GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO'))
	        aadd(aCpos,'')
	    Endif
	Next i   
		
	AxAltera ("SN1",SN1->(recno()),4,NIL,aCpos,,,"U_RepMaq()")
Return
//
