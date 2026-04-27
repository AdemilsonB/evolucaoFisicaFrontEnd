class ApiPaths {
  static const authLogin = '/api/auth/login';
  static const authCadastro = '/api/auth/cadastro';
  static const authGoogle = '/api/auth/google';
  static const usuarios = '/api/usuarios';
  static const treinos = '/api/treinos';
  static const exercicios = '/api/exercicios';
  static const registrosTreino = '/api/registros-treino';
  static const alimentos = '/api/alimentos';
  static const planosAlimentares = '/api/planos-alimentares';
  static const refeicoes = '/api/refeicoes';
  static const registrosDiarios = '/api/gamificacao/registros-diarios';
  static const rankingGeral = '/api/gamificacao/ranking/geral';
  static const social = '/api/social';

  static String onboarding(int usuarioId) => '/api/usuarios/$usuarioId/onboarding';

  static String metasAtleta(int usuarioId) => '/api/usuarios/$usuarioId/metas';

  static String dashboardGamificacao(int usuarioId) =>
      '/api/gamificacao/dashboard/$usuarioId';

  static String rankingSeguindo(int usuarioId) =>
      '/api/gamificacao/ranking/seguindo/$usuarioId';

  static String rankingGrupo(int grupoId) =>
      '/api/gamificacao/ranking/grupo/$grupoId';
}
