// Programa:   MATR941
// Autor:      Robert Koch
// Data:       12/03/2008
// Cliente:    Alianca
// Descricao:  P.E. para customizar a impressao do registro de apuracao de ICMS.
// 
// Historico de alteracoes:
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
user function matr941 ()

	// Como nao desejamos customizar toda a impressao, mas simplesmente gerar
	// um acumulado de mais de um periodo, este ponto de entrada apenas 
	// altera as variaveis de data inicial e final, que serao usadas depois
	// pelo programa padrao.
	define MSDialog _oDlgGet from 0, 0 to 250, 600 of oMainWnd pixel title "ALIANCA - Alteracao de datas para impressao"
		@ 10, 10 say "Neste ponto eh possivel alterar as datas de inicio e fim para impressao"
		@ 20, 10 say "do registro de apuracao. Isto se destina apenas a fazer uma conferencia"
		@ 30, 10 say "de valores e NAO deve ser usado como livro oficial, inclusive por que"
		@ 40, 10 say "as datas informadas aqui serao consideradas somente para a primeira parte"
		@ 50, 10 say "do relatorio ('Registro de apuracao') e nao para a segunda ('Resumo da apuracao')"
		@ 70, 10 get dDtIni
		@ 85, 10 get dDtFim
		@ 100, 10 bmpbutton type 1 action _oDlgGet:End ()
	activate MSDialog _oDlgGet centered

	matr941 ()
return
