// Programa:  Modulos
// Autor:     Robert Koch
// Data:      22/06/2016
// Descricao: Define pontos de entrada genericos de todos os modulos.
//            Criado inicialmente para registrar entradas e saidas das telas.
//
// Historico de alteracoes:
// 06/08/2020 - Robert - Faltavam alguns modulos, entao gerei a lista toda e mudei para
//                       que chamassem uma mesma funcao generica.
//                     - Inclusao de tags para catalogacao de fontes.

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada
// #Descricao         #Define pontos de entrada genericos de todos os modulos.
// #PalavasChave      #auxiliar #uso_generico
// #TabelasPrincipais 
// #Modulos           #todos_modulos

// Sugestao para obter a lista de modulos: select * from CW0010 where CW0_TABELA = '01'
// OUTRA SUGESTAO: SELECT 'user function SIGA' + SIGLA + ' () ; _GeraLog () ; return' FROM VA_USR_MODULOS
// --------------------------------------------------------------------------
/*
user function sigaacd ()
	if procname (2) == 'FWSETENVIRONMENT'
		U_UsoRot ('I', '', procname ())  // Ainda nao tenho o nome do programa.
	endif
	if empty (procname (4))
		U_UsoRot ('F', FunName ())  // Somente na saida da tela consigo o nome do programa.
	endif
return

// --------------------------------------------------------------------------
user function sigawms ()
	if procname (2) == 'FWSETENVIRONMENT'
		U_UsoRot ('I', '', procname ())  // Ainda nao tenho o nome do programa.
	endif
	if empty (procname (4))
		U_UsoRot ('F', FunName ())  // Somente na saida da tela consigo o nome do programa.
	endif
return

// --------------------------------------------------------------------------
user function sigaoms ()
	if procname (2) == 'FWSETENVIRONMENT'
		U_UsoRot ('I', '', procname ())  // Ainda nao tenho o nome do programa.
	endif
	if empty (procname (4))
		U_UsoRot ('F', FunName ())  // Somente na saida da tela consigo o nome do programa.
	endif
return

// --------------------------------------------------------------------------
user function sigasga ()
	if procname (2) == 'FWSETENVIRONMENT'
		U_UsoRot ('I', '', procname ())  // Ainda nao tenho o nome do programa.
	endif
	if empty (procname (4))
		U_UsoRot ('F', FunName ())  // Somente na saida da tela consigo o nome do programa.
	endif
return

// --------------------------------------------------------------------------
user function sigamnt ()
	if procname (2) == 'FWSETENVIRONMENT'
		U_UsoRot ('I', '', procname ())  // Ainda nao tenho o nome do programa.
	endif
	if empty (procname (4))
		U_UsoRot ('F', FunName ())  // Somente na saida da tela consigo o nome do programa.
	endif
return

// --------------------------------------------------------------------------
user function sigapcp ()
	if procname (2) == 'FWSETENVIRONMENT'
		U_UsoRot ('I', '', procname ())  // Ainda nao tenho o nome do programa.
	endif
	if empty (procname (4))
		U_UsoRot ('F', FunName ())  // Somente na saida da tela consigo o nome do programa.
	endif
return

// --------------------------------------------------------------------------
user function sigaloj ()
	if procname (2) == 'FWSETENVIRONMENT'
		U_UsoRot ('I', '', procname ())  // Ainda nao tenho o nome do programa.
	endif
	if empty (procname (4))
		U_UsoRot ('F', FunName ())  // Somente na saida da tela consigo o nome do programa.
	endif
return

// --------------------------------------------------------------------------
user function sigaatf ()
	if procname (2) == 'FWSETENVIRONMENT'
		U_UsoRot ('I', '', procname ())  // Ainda nao tenho o nome do programa.
	endif
	if empty (procname (4))
		U_UsoRot ('F', FunName ())  // Somente na saida da tela consigo o nome do programa.
	endif
return

// --------------------------------------------------------------------------
user function sigactb ()
	if procname (2) == 'FWSETENVIRONMENT'
		U_UsoRot ('I', '', procname ())  // Ainda nao tenho o nome do programa.
	endif
	if empty (procname (4))
		U_UsoRot ('F', FunName ())  // Somente na saida da tela consigo o nome do programa.
	endif
return

// --------------------------------------------------------------------------
user function sigafin ()
	if procname (2) == 'FWSETENVIRONMENT'
		U_UsoRot ('I', '', procname ())  // Ainda nao tenho o nome do programa.
	endif
	if empty (procname (4))
		U_UsoRot ('F', FunName ())  // Somente na saida da tela consigo o nome do programa.
	endif
return

// --------------------------------------------------------------------------
user function sigagpe ()
	if procname (2) == 'FWSETENVIRONMENT'
		U_UsoRot ('I', '', procname ())  // Ainda nao tenho o nome do programa.
	endif
	if empty (procname (4))
		U_UsoRot ('F', FunName ())  // Somente na saida da tela consigo o nome do programa.
	endif
return

// --------------------------------------------------------------------------
user function sigafat ()
	if procname (2) == 'FWSETENVIRONMENT'
		U_UsoRot ('I', '', procname ())  // Ainda nao tenho o nome do programa.
	endif
	if empty (procname (4))
		U_UsoRot ('F', FunName ())  // Somente na saida da tela consigo o nome do programa.
	endif
return

// --------------------------------------------------------------------------
user function sigacom ()
	if procname (2) == 'FWSETENVIRONMENT'
		U_UsoRot ('I', '', procname ())  // Ainda nao tenho o nome do programa.
	endif
	if empty (procname (4))
		U_UsoRot ('F', FunName ())  // Somente na saida da tela consigo o nome do programa.
	endif
return

// --------------------------------------------------------------------------
user function sigaest ()
	if procname (2) == 'FWSETENVIRONMENT'
		U_UsoRot ('I', '', procname ())  // Ainda nao tenho o nome do programa.
	endif
	if empty (procname (4))
		U_UsoRot ('F', FunName ())  // Somente na saida da tela consigo o nome do programa.
	endif
return

// --------------------------------------------------------------------------
user function sigaesp ()
	if procname (2) == 'FWSETENVIRONMENT'
		U_UsoRot ('I', '', procname ())  // Ainda nao tenho o nome do programa.
	endif
	if empty (procname (4))
		U_UsoRot ('F', FunName ())  // Somente na saida da tela consigo o nome do programa.
	endif
return
*/

user function SIGAATF () ; _GeraLog () ; return
user function SIGACOM () ; _GeraLog () ; return
user function SIGACON () ; _GeraLog () ; return
user function SIGAEST () ; _GeraLog () ; return
user function SIGAFAT () ; _GeraLog () ; return
user function SIGAFIN () ; _GeraLog () ; return
user function SIGAGPE () ; _GeraLog () ; return
user function SIGAFAS () ; _GeraLog () ; return
user function SIGAFIS () ; _GeraLog () ; return
user function SIGAPCP () ; _GeraLog () ; return
user function SIGAVEI () ; _GeraLog () ; return
user function SIGALOJ () ; _GeraLog () ; return
user function SIGATMK () ; _GeraLog () ; return
user function SIGAOFI () ; _GeraLog () ; return
user function SIGARPM () ; _GeraLog () ; return
user function SIGAPON () ; _GeraLog () ; return
user function SIGAEIC () ; _GeraLog () ; return
user function SIGATCF () ; _GeraLog () ; return
user function SIGAMNT () ; _GeraLog () ; return
user function SIGARSP () ; _GeraLog () ; return
user function SIGAQIE () ; _GeraLog () ; return
user function SIGAQMT () ; _GeraLog () ; return
user function SIGAFRT () ; _GeraLog () ; return
user function SIGAQDO () ; _GeraLog () ; return
user function SIGAQIP () ; _GeraLog () ; return
user function SIGATRM () ; _GeraLog () ; return
user function SIGAEIF () ; _GeraLog () ; return
user function SIGATEC () ; _GeraLog () ; return
user function SIGAEEC () ; _GeraLog () ; return
user function SIGAEFF () ; _GeraLog () ; return
user function SIGAECO () ; _GeraLog () ; return
user function SIGAAFV () ; _GeraLog () ; return
user function SIGAPLS () ; _GeraLog () ; return
user function SIGACTB () ; _GeraLog () ; return
user function SIGAMDT () ; _GeraLog () ; return
user function SIGAQNC () ; _GeraLog () ; return
user function SIGAQAD () ; _GeraLog () ; return
user function SIGAQCP () ; _GeraLog () ; return
user function SIGAOMS () ; _GeraLog () ; return
user function SIGACSA () ; _GeraLog () ; return
user function SIGAPEC () ; _GeraLog () ; return
user function SIGAWMS () ; _GeraLog () ; return
user function SIGATMS () ; _GeraLog () ; return
user function SIGAPMS () ; _GeraLog () ; return
user function SIGACDA () ; _GeraLog () ; return
user function SIGAACD () ; _GeraLog () ; return
user function SIGAPPA () ; _GeraLog () ; return  // Na entrada da tela chama esta user function
user function SIGAPPAP () ; _GeraLog () ; return  // Na saida da tela chama esta user function
user function SIGAREP () ; _GeraLog () ; return
user function SIGAAGE () ; _GeraLog () ; return
user function SIGAEDC () ; _GeraLog () ; return
user function SIGAHSP () ; _GeraLog () ; return
user function SIGAVDOC () ; _GeraLog () ; return
user function SIGAAPD () ; _GeraLog () ; return
user function SIGAGSP () ; _GeraLog () ; return
user function SIGACRD () ; _GeraLog () ; return
user function SIGASGA () ; _GeraLog () ; return
user function SIGAPCO () ; _GeraLog () ; return
user function SIGAGPR () ; _GeraLog () ; return
user function SIGAGAC () ; _GeraLog () ; return
user function SIGAPRA () ; _GeraLog () ; return
user function SIGAHGP () ; _GeraLog () ; return
user function SIGAHHG () ; _GeraLog () ; return
user function SIGAHPL () ; _GeraLog () ; return
user function SIGAAPT () ; _GeraLog () ; return
user function SIGAGAV () ; _GeraLog () ; return
user function SIGAICE () ; _GeraLog () ; return
user function SIGAAGR () ; _GeraLog () ; return
user function SIGAARM () ; _GeraLog () ; return
user function SIGAGCT () ; _GeraLog () ; return
user function SIGAORG () ; _GeraLog () ; return
user function SIGALVE () ; _GeraLog () ; return
user function SIGAPHOTO () ; _GeraLog () ; return
user function SIGACRM () ; _GeraLog () ; return
user function SIGABPM () ; _GeraLog () ; return
user function SIGAAPON () ; _GeraLog () ; return
user function SIGAJURI () ; _GeraLog () ; return
user function SIGAPFS () ; _GeraLog () ; return
user function SIGAGFE () ; _GeraLog () ; return
user function SIGASFC () ; _GeraLog () ; return
user function SIGAACV () ; _GeraLog () ; return
user function SIGALOG () ; _GeraLog () ; return
user function SIGADPR () ; _GeraLog () ; return
user function SIGAVPON () ; _GeraLog () ; return
user function SIGATAF () ; _GeraLog () ; return
user function SIGAESS () ; _GeraLog () ; return
user function SIGAVDF () ; _GeraLog () ; return
user function SIGAGCP () ; _GeraLog () ; return
user function SIGAGTP () ; _GeraLog () ; return
user function SIGAPDS () ; _GeraLog () ; return
user function SIGAGCV () ; _GeraLog () ; return
user function SIGAESP2 () ; _GeraLog () ; return
user function SIGAESP () ; _GeraLog () ; return
user function SIGAESP1 () ; _GeraLog () ; return
user function SIGACFG () ; _GeraLog () ; return

// --------------------------------------------------------------------------
static function _GeraLog ()
	if procname (3) == 'FWSETENVIRONMENT'
		U_UsoRot ('I', '', procname (1))  // Ainda nao tenho o nome do programa.
	endif
	if empty (procname (5))
		U_UsoRot ('F', FunName ())  // Somente na saida da tela consigo o nome do programa.
	endif
return
