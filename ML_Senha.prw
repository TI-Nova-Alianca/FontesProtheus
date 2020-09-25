// Programa...: ML_Senha
// Autor......: Robert Koch
// Data.......: 15/12/2004
// Descricao..: Abre tela pedindo senha de usuario para liberacao.
// Cliente....: Generico
// 
// Historico de alteracoes:
// 17/10/2005 - Robert - Melhorias gerais (mensagens, fechamento de dialogos, etc)
// 24/10/2005 - Robert - Alteracao chamada funcao ML_SRAREA

#include "rwmake.ch"

// --------------------------------------------------------------------------
// Abre tela para liberacao de processos por usuario autorizado.
// Recebe os seguintes parametros:
// Param.1: descricao do titulo da janela
// Param.2: mensagem para o usuario
// Param.3: lista (formato string) de usuarios que podem ser aceitos
// Param.4: .T. = exige justificativa; .F. = nao pede justificativa.
// Retorna array com 3 posicoes, sendo:
// pos.1:  .T.=senha aceita; .F.=senha rejeitada / digitacao cancelada pelo usuario.
// pos.2:  Nome do usuario informado para liberacao
// pos.3:  Justificativa informada para liberacao
user function ML_Senha (_sTitulo, _sMsg, _sUsersOK, _lQuerJust)
   local _oDlgSenha := NIL
   local _aAreaAnt  := U_ML_SRArea ()
   private _sSenha    := space (20)
   private _sUser     := space (25)
   private _lOk       := .F.
   private _lFechaDlg := .F.
   private _sJustLib  := ""

   do while ! _lFechaDlg
      define MSDialog _oDlgSenha from 0, 0 to 180, 500 of oMainWnd pixel title _sTitulo
         @ 10, 10 say _sMsg
         @ 20, 10 say "Liberacao somente pelo(s) usuario(s): " + _sUsersOK
         @ 35, 10 say "Usuario"
         @ 45, 10 say "Senha"
         @ 35, 60 get _sUser  size 70, 11
         @ 45, 60 get _sSenha size 70, 11 password
         @ 65, 10 bmpbutton type 1 action (iif (_ConfSenha (_sUsersOK, _lQuerJust), _oDlgSenha:End (), NIL))
         @ 65, 80 bmpbutton type 2 action (_lOK := .F., _lFechaDlg := .T., _sUser := "", _sJustLib := "", _oDlgSenha:End ())
      activate MSDialog _oDlgSenha centered
   enddo

   U_ML_SRArea (_aAreaAnt)
return {_lOK, _sUser, _sJustLib}



// --------------------------------------------------------------------------
// Verifica a senha informada
static function _ConfSenha (_sUsersOK, _lQuerJust)
   local _nUser    := 0
   local _aSenhas  := {}
   local _oDlgJust := NIL

   _lFechaDlg = .F.
   _lOK = .F.

   // Busca usuario
   psworder (2)
   if ! pswseek (_sUser)
      msgalert ("Usuario nao cadastrado")
      return .F.
   endif
   if ! PswName (_sSenha)
      msgalert ("Usuario / Senha invalidos")
      return .F.
   endif

   if upper (alltrim (_sUser)) $ upper (_sUsersOK)
      if _lQuerJust
         do while empty (_sJustLib)
            _sJustLib := space (255)  // Mais que isso eh pra matar...
            define MSDialog _oDlgJust from 0, 0 to 150, 500 of oMainWnd pixel title "Justificativa"
               @ 10, 10 say "Justifique a liberacao"
               @ 30, 10 get _sJustLib size 200, 11
               @ 45, 10 bmpbutton type 1 action (_oDlgJust:End ())
            activate MSDialog _oDlgJust centered
         enddo
      endif
      _lFechaDlg = .T.
      _lOK = .T.
   else
      msgalert ("Usuario nao autorizado a fazer esta liberacao.")
   endif
return _lOK
