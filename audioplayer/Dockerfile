FROM ghcr.io/gleam-lang/gleam:v1.15.0-rc2-elixir

WORKDIR /app
COPY . .

RUN gleam deps download
RUN gleam build

CMD ["gleam", "run"]
