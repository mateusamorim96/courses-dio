CREATE CONSTRAINT user_id_unique IF NOT EXISTS FOR (u:User) REQUIRE u.id IS UNIQUE;
CREATE CONSTRAINT movie_id_unique IF NOT EXISTS FOR (m:Movie) REQUIRE m.id IS UNIQUE;
CREATE CONSTRAINT series_id_unique IF NOT EXISTS FOR (s:Series) REQUIRE s.id IS UNIQUE;
CREATE CONSTRAINT genre_name_unique IF NOT EXISTS FOR (g:Genre) REQUIRE g.name IS UNIQUE;
CREATE CONSTRAINT actor_id_unique IF NOT EXISTS FOR (a:Actor) REQUIRE a.id IS UNIQUE;
CREATE CONSTRAINT director_id_unique IF NOT EXISTS FOR (d:Director) REQUIRE d.id IS UNIQUE;

// 1. Definição da lista de conteúdos com Atores e Diretores contendo IDs explícitos
UNWIND [
  {
    type: "Movie", id: "m01", title: "Inception", year: 2010, genre: "Sci-Fi", 
    director: {id: "d01", name: "Christopher Nolan"}, 
    actors: [{id: "a01", name: "Leonardo DiCaprio"}, {id: "a02", name: "Cillian Murphy"}]
  },
  {
    type: "Movie", id: "m02", title: "The Dark Knight", year: 2008, genre: "Action", 
    director: {id: "d01", name: "Christopher Nolan"}, // Mesmo ID d01
    actors: [{id: "a03", name: "Christian Bale"}, {id: "a04", name: "Heath Ledger"}]
  },
  {
    type: "Movie", id: "m03", title: "Pulp Fiction", year: 1994, genre: "Crime", 
    director: {id: "d02", name: "Quentin Tarantino"}, 
    actors: [{id: "a05", name: "John Travolta"}, {id: "a06", name: "Samuel L. Jackson"}]
  },
  {
    type: "Movie", id: "m04", title: "The Matrix", year: 1999, genre: "Sci-Fi", 
    director: {id: "d03", name: "Lana Wachowski"}, 
    actors: [{id: "a07", name: "Keanu Reeves"}, {id: "a08", name: "Laurence Fishburne"}]
  },
  {
    type: "Movie", id: "m05", title: "Forrest Gump", year: 1994, genre: "Drama", 
    director: {id: "d04", name: "Robert Zemeckis"}, 
    actors: [{id: "a09", name: "Tom Hanks"}, {id: "a10", name: "Robin Wright"}]
  },
  {
    type: "Movie", id: "m06", title: "Parasite", year: 2019, genre: "Thriller", 
    director: {id: "d05", name: "Bong Joon-ho"}, 
    actors: [{id: "a11", name: "Song Kang-ho"}, {id: "a12", name: "Lee Sun-kyun"}]
  },
  {
    type: "Series", id: "s01", title: "Breaking Bad", seasons: 5, genre: "Drama", 
    director: {id: "d06", name: "Vince Gilligan"}, 
    actors: [{id: "a13", name: "Bryan Cranston"}, {id: "a14", name: "Aaron Paul"}]
  },
  {
    type: "Series", id: "s02", title: "Stranger Things", seasons: 4, genre: "Sci-Fi", 
    director: {id: "d07", name: "Duffer Brothers"}, 
    actors: [{id: "a15", name: "Millie Bobby Brown"}, {id: "a16", name: "Winona Ryder"}]
  },
  {
    type: "Series", id: "s03", title: "The Office", seasons: 9, genre: "Comedy", 
    director: {id: "d08", name: "Greg Daniels"}, 
    actors: [{id: "a17", name: "Steve Carell"}, {id: "a18", name: "John Krasinski"}]
  },
  {
    type: "Series", id: "s04", title: "Game of Thrones", seasons: 8, genre: "Fantasy", 
    director: {id: "d09", name: "David Benioff"}, 
    actors: [{id: "a19", name: "Emilia Clarke"}, {id: "a20", name: "Kit Harington"}]
  }
] AS row

// 2. Criar ou Encontrar o Gênero
MERGE (g:Genre {name: row.genre})

// 3. Criar ou Encontrar o Diretor pelo ID
MERGE (d:Director {id: row.director.id})
SET d.name = row.director.name

// 4. Lógica Condicional para criar Filme ou Série
FOREACH (_ IN CASE WHEN row.type = 'Movie' THEN [1] ELSE [] END |
    MERGE (m:Movie {id: row.id})
    SET m.title = row.title, m.releaseYear = row.year
    MERGE (m)-[:IN_GENRE]->(g)
    MERGE (d)-[:DIRECTED]->(m)
)

FOREACH (_ IN CASE WHEN row.type = 'Series' THEN [1] ELSE [] END |
    MERGE (s:Series {id: row.id})
    SET s.title = row.title, s.seasons = row.seasons
    MERGE (s)-[:IN_GENRE]->(g)
    MERGE (d)-[:DIRECTED]->(s)
)

// 5. Reconectar ao nó de conteúdo recém-criado para processar os atores
WITH row
MATCH (content) WHERE content.id = row.id

// 6. Processar Atores
FOREACH (actorData IN row.actors | 
    MERGE (a:Actor {id: actorData.id})
    SET a.name = actorData.name
    MERGE (a)-[:ACTED_IN]->(content)
);

// 7. Criar Usuários e Histórico
WITH 1 as dummy
UNWIND range(1, 10) AS i
MERGE (u:User {id: "u" + i})
SET u.name = "User " + i

// Para cada usuário, selecionar 5 conteúdos aleatórios
WITH u
MATCH (c) WHERE (c:Movie OR c:Series)
WITH u, c, rand() AS random_sort
ORDER BY random_sort
WITH u, collect(c)[0..5] AS watched_content

UNWIND watched_content AS content
  // Nota aleatória (Ex: 3.5, 4.2)
  WITH u, content, toFloat(round(rand() * 40 + 10)) / 10 AS random_rating
  MERGE (u)-[:WATCHED {rating: random_rating}]->(content);