//  Programa...: PROCCARTOES
//  Autor......: Catia Cardoso
//  Data.......: 10/07/2019
//  Descricao..: baixa titulos referente a vendas com cartao de credito 
//               e gerar movimento bancario a receber com o valor total recebido
// 
//  Historico de alteracoes:
//
// ------------------------------------------------------------------------------------

#include "totvs.ch"
#include "protheus.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"
#INCLUDE "tbiconn.ch"
#include "colors.ch"

user function PROCCARTOES()

_caminho := ""

// tela para selecionar o arquivo texto no disco local para ser lido/atualizado
DEFINE DIALOG oDlg TITLE "Usar Arquivo (.CSV)" FROM 180,180 TO 370,640 PIXEL
@ 005, 005 To 090, 228 //linha, coluna TO linha, coluna
@ 020, 025 Say "Selecione o arquivo base:"
@ 045, 025 Say "Caminho:"
@ 045, 055 Get _caminho  SIZE 140,20
oTButton1 := TButton():New(045,195,"...",oDlg,{||diretorio()},10,10,,,.F.,.T.,.F.,,.F.,,,.F.)
oTButton2 := TButton():New(070,078,"Importar",oDlg,{||processa(importar(_caminho))},35,10,,,.F.,.T.,.F.,,.F.,,,.F.)
oTButton3 := TButton():New(070,138,"Sair",oDlg,{||close(oDlg)},35,10,,,.F.,.T.,.F.,,.F.,,,.F.)
ACTIVATE DIALOG oDlg CENTERED

return

Static Function close()
Return

Static Function diretorio()

_caminho := cGetFile('*.*','Arquivos (Todos)',1,,.T.,GETF_LOCALHARD + GETF_NETWORKDRIVE)
Return

Static Function importar(_caminho)

Local cArq    	:= _caminho
Local cLinha  	:= ""
Local aDados  	:= {}
Local aJaTem  	:= {}
Local aCab    	:= {}   
Local aItens  	:= {}
Local i			:= 0

Private lMsErroAuto := .F. // Determina se houve alguma inconsistencia na execucao da rotina 

Close(oDlg)

If !File(cArq)
	MsgStop("O arquivo '" + cArq + "' não foi encontrado. Atualização não realizada!","ATENCAO")
	Return
EndIf

FT_FUSE(cArq)
ProcRegua(FT_FLASTREC())
FT_FGOTOP()
While !FT_FEOF()
	cLinha := FT_FREADLN()
	AADD(aDados,Separa(cLinha,";",.T.))
	FT_FSKIP()
EndDo   

// limpa tabela temporaria
_sSQL := ""
_sSQL += " DELETE AUX_CARTOES"

if TCSQLExec (_sSQL) < 0
    u_showmemo(_sSQL)
    return
endif
     
_wcont :=0
if Len (aDados) > 0
	// GRAVA TABELA AUXILIAR DE CARTOES
	u_help("Le arquivo")
	_warquivo    := cArq
	for i=1 to len(aDados)-1
		if i=1 // ao validar o header le o proximo registro
			_wheader := SUBSTR(aDados[i,1],43,8)
			if _wheader != 'BJRVCMB'
				u_help("Arquivo invalido para importação da conciliação de cartoes")
				return
			endif
			loop
		endif 
		_wtipo	     := SUBSTR(aDados[i,1],1,2)
		if _wtipo == '10'
			_wcnpj       := SUBSTR(aDados[i,1],43,14)
			_wtipolan    := SUBSTR(aDados[i,1],37,4)
			_wfilial     := SUBSTR(_wcnpj,11,2)
		elseif _wtipo == '20'
			_wnsumov     := SUBSTR(aDados[i,1],51,8)
			_wdtlan      := SUBSTR(aDados[i,1],29,8)
			_wparcela    := SUBSTR(aDados[i,1],59,2)
			_wvlrparc    := VAL(SUBSTR(aDados[i,1],61,15))/100
			_wtaxaadm    := VAL(SUBSTR(aDados[i,1],82,6))/10000
			_wtarifadmc  := VAL(SUBSTR(aDados[i,1],88,10))/100
			_wtarifcomc  := VAL(SUBSTR(aDados[i,1],98,6))/100
			_wvlrparcliq := VAL(SUBSTR(aDados[i,1],108,15))/100
			_wrede       := SUBSTR(aDados[i,1],3,11)
			_westab      := SUBSTR(aDados[i,1],14,15)
			_wdtmov      := SUBSTR(aDados[i,1],43,8)
			if _wtipolan = '0202' .or. _wtipolan = '0203' .or. _wtipolan = '0206' .or. _wtipolan = '0207' .or. _wtipolan = '0208'   
				_winddb      := 'DEB'
				/*	0202 - credito a vista
					0203 - credito parcelado lojista
					0206 - credito a vista lojista
					0207 - credito parcelado emissor
					0208 - credito a vista internacional */
			else		
				_winddb      := 'CRED'
				/*	0214 - debito internacional
					0021 - debito alimentacao
					0022 - debito refeicao
					0023 - debito vouches
					0024 - debito auto */
			endif		
			_sSQL := ""
	        _sSQL += " INSERT INTO AUX_CARTOES (ARQUIVO, CNPJ, DTLAN, NSUMOV, PARCELA, VLRPARC, TAXAADM, TARIFADMC, TARIFCOMC, VLRPARCLIQ"
	        _sSQL += "                        , FILIAL, REDE, ESTAB, TIPOLAN, INDDC, DTMOV)"
	        _sSQL += " VALUES ( '" + _warquivo    + "'"
	        _sSQL += "        , '" + _wcnpj + "'"
	        _sSQL += "        , '" + _wdtlan + "'"
	        _sSQL += "        , '" + _wnsumov  + "'"
	        _sSQL += "        , '" + _wparcela + "'"
	        _sSQL += "        ,  " + cvaltochar(_wvlrparc)
	        _sSQL += "        ,  " + cvaltochar(_wtaxaadm)
	        _sSQL += "        ,  " + cvaltochar(_wtarifadmc)
	        _sSQL += "        ,  " + cvaltochar(_wtarifcomc)
	        _sSQL += "        ,  " + cvaltochar(_wvlrparcliq)
	        _sSQL += "        , '" + _wfilial + "'"
	        _sSQL += "        , '" + _wrede + "'"
	        _sSQL += "        , '" + _westab + "'"
	        _sSQL += "        , '" + _wtipolan + "'"
	        _sSQL += "        , '" + _winddb + "'"
	        _sSQL += "        , '" + _wdtmov + "')"
	        
	        if TCSQLExec (_sSQL) < 0
	           u_showmemo(_sSQL)
	           return
	        endif
        endif 
	next
endif
// CONSISTE ARQUIVO VERIFICANDO SE IDENTIFICOU TODOS OS TITULOS
u_help("Verifica inconsistencias por filial")
_sSQL := ""
_sSQL += " WITH C AS ( SELECT DISTINCT AUX.FILIAL, E1_NUM" 
_sSQL += "   			 FROM AUX_CARTOES AS AUX"
_sSQL += "     				LEFT JOIN SE1010 AS SE1"
_sSQL += " 						ON (SE1.D_E_L_E_T_     = ''"
_sSQL += " 							AND SE1.E1_FILIAL  = AUX.FILIAL"
_sSQL += "							AND SE1.E1_VALOR   = AUX.VLRPARC"
_sSQL += "							AND SE1.E1_EMISSAO = AUX.DTMOV"
_sSQL += "                          AND SE1.E1_SALDO >0"
_sSQL += " 							AND SUBSTRING('00000000'+E1_NSUTEF,LEN('00000000'+E1_NSUTEF)-7,8) = AUX.NSUMOV"
_sSQL += " 							AND SE1.E1_PARCELA = CASE WHEN AUX.PARCELA='01' THEN 'A'"
_sSQL += " 			                          				  WHEN AUX.PARCELA='02' THEN 'B'" 
_sSQL += " 									  				  WHEN AUX.PARCELA='03' THEN 'C'" 
_sSQL += " 									  				  WHEN AUX.PARCELA='04' THEN 'D'" 
_sSQL += " 									  				  WHEN AUX.PARCELA='05' THEN 'E'" 
_sSQL += " 									  				  WHEN AUX.PARCELA='06' THEN 'F'" 
_sSQL += " 								 				 END )"	  
_sSQL += " 			)"
_sSQL += " SELECT *"
_sSQL += "   FROM C "
_sSQL += "  WHERE C.E1_NUM IS NULL"
//u_showmemo(_sSQL)
_aErros  := U_Qry2Array(_sSQL)
//u_showarray(_aErros)
_wfilDESC := ''
if len(_aErros) > 0
	for i=1 to len(_aErros)
		u_help("Encontrado erro na FILIAL: " + _aErros [i,1] + " Esta filial será desconsiderada na conciliacao dos cartoes")
		if _wfilDESC = ''
			_wfilDESC += _aErros [i,1]
		else
			_wfilDESC += + '/' + _aErros [i,1]  
		endif		
	next
endif
// RELATORIO PARA CONFERENCIA E ARQUIVO
u_help("Relatorio")
U_ML_CARTOES(_wfilDESC) // imprime relatorio
// CRIA BATS NO ZZ6 PARA QUE SEJA RODADO DEPOIS JA QUE NAO CONSIGO SETAR A FILIAL POR ROTINA AUTOMATICA
for I=1 to 3 	
	// 3 filiais apenas 08/10/13
	do case
		case i=1
			_wfilial = '08'
		case i=2
			_wfilial = '10'
		case i=3
			_wfilial = '13'
	endcase
	if ! _wfilial $ _wfilDESC
	    _sSeq = soma1 (fBuscaCpo ("ZZ6", 1, _wfilial, "ZZ6_SEQ"))
		reclock ("ZZ6", .t.)
			zz6 -> zz6_filial = _wfilial
			zz6 -> ZZ6_ATIVO  = 'N'   /// mudar para tivo sim
			zz6 -> ZZ6_SEQ    = _sSeq
			zz6 -> ZZ6_EMPINC = '01'
			zz6 -> ZZ6_FILINC = _wfilial
			zz6 -> ZZ6_EMPDES = '01'
			zz6 -> ZZ6_FILDES = _wfilial
			zz6 -> ZZ6_DTINC  = date ()
			zz6 -> ZZ6_HRINC  = time ()
			zz6 -> ZZ6_DADOS  = 'Conciliacao cartoes'
			zz6 -> ZZ6_MAXTEN = 5
			zz6 -> ZZ6_DIASEM = '1234567'
			zz6 -> ZZ6_DTINI  = date ()
			zz6 -> ZZ6_HRINI  = '00:00'
			zz6 -> ZZ6_HRFIM  = '06:30'
			zz6 -> ZZ6_PERIOD = 'R'
			zz6 -> ZZ6_ACADA  = 1
			zz6 -> ZZ6_ACADAU = 'D'
			zz6 -> ZZ6_CMD    = "U_BATCARTOES('')"
			zz6 -> ZZ6_PRIOR  = '5'
		msunlock ()
	endif	
next
return