# Estado da entrega - OpenMovie

## Itens da documentação técnica v3

- [x] Busca, resultados com pôster/ano/tipo e total de títulos.
- [x] Filtros de tipo e ano e paginação até 100 páginas.
- [x] Detalhes por IMDb ID com sinopse, avaliações e campos adicionais disponíveis.
- [x] Consulta de temporada e episódios dentro da tela de detalhes existente.
- [x] Estados de carregamento, resultado vazio, erro e nova tentativa.
- [x] README com execução local e configuração de chave por tempo de execução.
- [x] Testes do serviço para busca/filtros, detalhes, temporada/episódios, erros e chave ausente.
- [x] Captura da Home atualizada com a imagem enviada; capturas de resultados e detalhes mantidas em screenshots/.

## Verificação feita neste checkout

- [x] `flutter pub get` concluído.
- [x] `flutter analyze` sem problemas.
- [x] `flutter test` aprovado: seis testes.
- [x] `flutter build web --release` concluído.
- [ ] Executar uma busca real com uma chave OMDb ativa no dispositivo de apresentação.

O checkout não tinha `OMDB_API_KEY` configurada. A chave deve ser fornecida localmente com `--dart-define`; nenhum valor de chave foi gravado no código ou neste documento.

## Decisões de escopo

- A documentação v3 descrevia uma consulta fixa por Batman ao iniciar. A versão atual mantém a busca geral, por decisão do usuário, e registra essa evolução no README; Batman continua como sugestão na Home.
- Temporadas e episódios ficam na tela de detalhes; nenhuma tela nova foi criada.
- Favoritos, compartilhamento, ordenação e cache offline não foram implementados nesta entrega.

## Para depois da entrega

- Revisar acessibilidade e navegação por leitor de tela.
- Criar um backend intermediário antes de publicar o app; a chave de uma compilação cliente pode ser extraída.
