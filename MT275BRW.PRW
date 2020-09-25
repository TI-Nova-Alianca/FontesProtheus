// Programa...: MT275Brw
// Autor......: Bruno (DWT)
// Data.......: 25/07/2014
// Descricao..: P.E. na montagem do browse na tela de liberacao de lotes.
//
// Historico de alteracoes:
//

User Function MT275BRW()

Local aButUsr := {}
//aAdd(aButUsr, {'PRODUTO',U_VA_ALTDAT(),'Botao 01','Botao 01' }  )
	aAdd(aButUsr,{ "Alt.prev.Liber.", "U_VA_ALTDAT()", 0 , 2, 0, .F.})
Return aButUsr