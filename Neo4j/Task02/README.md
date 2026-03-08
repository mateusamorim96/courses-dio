# Task02 — Recomendação com PageRank (Neo4j + GDS)

Este diretório contém a documentação do **projeto de recomendação com PageRank** usando dados de faixas musicais do Spotify.

## Sobre o dataset

**About Dataset**  
🎹What is the 'recipe' for winning tracks?🤔  
We sometimes wonder what makes a track successful these days?  
With this question in mind, I gathered various information and audio features – danceability, speechiness or liveness – of the top tracks in the last 5 years.

### Audio Features
- **Mood:** Danceability, Valence, Energy, Tempo
- **Properties:** Loudness, Speechiness, Instrumentalness
- **Context:** Liveness, Acousticness

### Descrição das colunas
- `track_uri`: identificador único da faixa no Spotify
- `track`: nome da faixa
- `artist`: nome do artista
- `artist_popularity`: popularidade do artista (0 a 100)
- `followers`: total de seguidores do artista no Spotify
- `artist_genre`: gênero do artista
- `track_popularity`: popularidade da faixa (0 a 100)
- `album`: nome do álbum
- `year`: ano
- `danceability`: quão adequada é a música para dança
- `valence`: valor de 0.0 a 1.0; quanto maior, mais positiva/feliz a música
- `energy`: medida perceptiva de intensidade e atividade
- `tempo`: tempo estimado da faixa em BPM
- `loudness`: volume geral em decibéis (dB), entre -60 e 0
- `speechiness`: quanto maior, mais conteúdo falado
- `instrumentalness`: quanto maior, menos vocais falados
- `liveness`: probabilidade de gravação com audiência ao vivo
- `acousticness`: medida de 0.0 a 1.0 do quão acústica é a faixa

## Consultas Cypher

### 1) Carga dos dados e modelagem inicial

```cypher
CALL apoc.load.jsonArray("https://drive.google.com/uc?export=download&id=1xo4cHi5u1kAH4ZlX-cfsbBHyINVUUsw9") YIELD value AS row

// 1. Criar/Atualizar Nó Track com Audio Features
MERGE (t:Track {uri: row.track_uri})
SET t.name = row.track,
      t.popularity = toInteger(row.track_popularity),
      t.year = toInteger(row.year),
      // Mood
      t.danceability = toFloat(row.danceability),
      t.valence = toFloat(row.valence),
      t.energy = toFloat(row.energy),
      t.tempo = toFloat(row.tempo),
      // Properties
      t.loudness = toFloat(row.loudness),
      t.speechiness = toFloat(row.speechiness),
      t.instrumentalness = toFloat(row.instrumentalness),
      t.key = toInteger(row.key),
      // Context
      t.liveness = toFloat(row.liveness),
      t.acousticness = toFloat(row.acousticness)

// 2. Criar/Atualizar Nó Artist
MERGE (ar:Artist {name: row.artist})
SET ar.popularity = toInteger(row.artist_popularity),
      ar.followers = toInteger(row.followers)

// 3. Criar/Atualizar Nó Album
MERGE (al:Album {name: row.album})

// 4. Criar Relacionamentos
MERGE (ar)-[:PERFORMED]->(t)
MERGE (t)-[:IN_ALBUM]->(al)

// 5. Tratar Gêneros (Limpando a string que simula lista)
WITH row, ar
// A string vem como "['genre1', 'genre2']", vamos limpar os colchetes e aspas
WITH ar, split(replace(replace(replace(row.artist_genre, "[", ""), "]", ""), "'", ""), ",") AS genres
UNWIND genres AS genreName
WITH ar, trim(genreName) AS finalGenreName
WHERE finalGenreName <> ""
MERGE (g:Genre {name: finalGenreName})
MERGE (ar)-[:PLAYS_GENRE]->(g);
```

### 2) Salvar score de PageRank

```cypher
CALL gds.pageRank.write('similaridade-artistas', {
   writeProperty: 'pagerank_score'
})
```

### 3) Consultar ranking de entidades

```cypher
CALL gds.pageRank.stream('similaridade-artistas')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name AS Entidade, score
ORDER BY score DESC
LIMIT 10;
```

## Como rodar o projeto (obrigatoriamente local)

> Este projeto precisa rodar em **instância local do Neo4j**, pois o algoritmo PageRank via **Graph Data Science (GDS)** pode não estar disponível em ambientes não locais ou com restrições de plugins.

### Pré-requisitos
- Neo4j local (Desktop ou Server local)
- Plugin **Graph Data Science (GDS)** habilitado
- Plugin **APOC** habilitado

### Passo a passo
1. Inicie sua instância local do Neo4j.
2. Garanta que os plugins GDS e APOC estejam instalados e ativos.
3. Crie/seleciona um banco de dados local (ex.: `neo4j`).
4. Execute a query de carga/modelagem para criar nós e relacionamentos.
5. Garanta que a projeção GDS `similaridade-artistas` exista no seu banco.
6. Execute as queries de PageRank em sequência no Neo4j Browser para:
   - preparação/modelagem do grafo,
   - execução do PageRank,
   - geração das recomendações.

## Objetivo da recomendação com PageRank

Usar o PageRank para identificar nós/faixas com maior relevância no grafo musical e, a partir disso, apoiar recomendações com base em popularidade estrutural e similaridades representadas pelas relações do grafo.
