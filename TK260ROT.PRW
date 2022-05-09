// Programa...: TK260ROT
// Autor......: Andre Alves
// Data.......: 27/03/2019
// Descricao..: P.E.  para inclusão de opções de rotinas de submenu.
//              Criado inicialmente para incluir um botão para transformar um prospect em cliente.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. para inclusão de opções de rotinas de submenu.
// #PalavasChave      #prospect #prospect_em_cliente 
// #TabelasPrincipais #SA1 #SUS
// #Modulos           #FAT
//
// Historico de alteracoes:
// 06/05/2022 - Claudia - Manda para a rotina AtuMerc para atualizar o cliente no mercanet. GLPI: 11987
//
// ---------------------------------------------------------------------------------------------------------
User Function TK260ROT()
   local aRotina := {}
                     
   aadd( aRotina, { "Tornar Cliente"      , "U_MPROSP" , 0, 3} )

return aRotina
//
//---------------------------------------------------------------------------------------
// Torna prospect em cliente
User Function MPROSP()
   Local aParam := {}
   Local cProsp:= SUS->US_COD 
   Local cLoja:= SUS->US_LOJA

   nReg := Recno()
   SUS->(dbGoTo(nReg))
                     
   //adiciona codeblock a ser executado no inicio, meio e fim
   aAdd( aParam, {|| U_MPROSP1() } )
   aAdd( aParam, {|| U_MPROSP2() } ) //ao fim da transação

   if SUS->US_STATUS == "6"     // Status não pode ser = CLIENTE
      u_help("Este Prospect já se tornou cliente!")
      return .F.
   endif

   nOpc := AxInclui("SA1",,3,,"U_MPROSP1",,,,"U_MPROSP2")
   If nOpc = 1
      // mudo o US_STATUS para cliente (6) e faço as amarrações de contatos com o novo cliente.
      DbselectArea("SUS")
      Posicione("SUS",1,xFilial("SUS")+cProsp+cLoja,"US_LOJA")
      RecLock("SUS",.f.)
               SUS->US_STATUS := "6"
               SUS->US_CODCLI := SA1->A1_COD
               SUS->US_LOJACLI := SA1->A1_LOJA
               SUS->US_DTCONV := dDatabase //database do sistema
      MsUnlock()

      // Manda registro para Mercanet
      U_AtuMerc ('SA1',sa1 -> (recno()))
   Endif 
Return .T.
//
//---------------------------------------------------------------------------------------
// Executa antes da transação
User Function MPROSP1()
   //todos os campos que quero que retorne no cadastro
   M->A1_FILIAL := SUS->US_FILIAL
   M->A1_LOJA   := SUS->US_LOJA
   M->A1_NOME   := SUS->US_NOME
   M->A1_NREDUZ := SUS->US_NREDUZ 
   M->A1_TIPO   := SUS->US_TIPO
   M->A1_END    := SUS->US_END
   M->A1_EST    := SUS->US_EST
   M->A1_BAIRRO := SUS->US_BAIRRO
   M->A1_CEP    := SUS->US_CEP
   M->A1_DDI    := SUS->US_DDI
   M->A1_DDD    := SUS->US_DDD
   M->A1_TEL    := SUS->US_TEL
   M->A1_MUN    := SUS->US_MUN
   M->A1_CGC    := SUS->US_CGC
   M->A1_EMAIL  := SUS->US_EMAIL 
   M->A1_SATIV1 := SUS->US_SATIV

Return .T.           
//
//---------------------------------------------------------------------------------------
//
User Function MPROSP2()
   Alert("Cliente migrado com sucesso!")
Return .T.
