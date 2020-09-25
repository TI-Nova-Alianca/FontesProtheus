// Programa:   VA_ORX
// Autor:      Robert Koch
// Data:       14/03/2008
// Cliente:    Alianca
// Descricao:  Exporta itens da planilha orcamentaria para Excel
// 
// Historico de alteracoes:
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
user function VA_ORX (_lAutomat)
	
	cPerg    := "VA_POS"
	_ValidPerg ()
	if pergunte (cPerg, .T.)
		processa ({|| _Gera ()})
	endif
return




// --------------------------------------------------------------------------
// Geracao do arquivo no Excel
static function _Gera ()
	local _aDados := {}
	private aCols := {}
	private aHeader := {}
	private N := 0
	_aDados = U_BrwItOrc ("", NIL, "zzzzzzzzzzzzzzzzzzzz", .T.)
	aHeader := aclone (_aDados [1])
	aCols := aclone (_aDados [2])

	// Remove linhas que nao interessam.
	// Faz isso "de tras para frente" para nao tentar acessar uma linha jah deletada
	N = len (aCols)
	do while N > 0
		if GDFieldGet ("Cta_Orc") < mv_par01 .or. GDFieldGet ("Cta_Orc") > mv_par02 .or. GDFieldGet ("CCusto") < mv_par03 .or. GDFieldGet ("CCusto") > mv_par04
			aCols = aclone (U_ADel (aCols, N))
		endif
		N --
	enddo

	if len (aCols) == 0
		msgalert ("Nao foram encontrados dados com os parametros informados.")
	else
		U_aColsXLS ()
	endif
return



// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Conta orcamentaria de         ", "C", 12, 0,  "",   "AK5", {},    ""})
	aadd (_aRegsPerg, {02, "Conta orcamentaria ate        ", "C", 12, 0,  "",   "AK5", {},    ""})
	aadd (_aRegsPerg, {03, "Centro de custo de            ", "C", 9,  0,  "",   "CTT", {},    ""})
	aadd (_aRegsPerg, {04, "Centro de custo ate           ", "C", 9,  0,  "",   "CTT", {},    ""})
	
	U_ValPerg (cPerg, _aRegsPerg)
Return
