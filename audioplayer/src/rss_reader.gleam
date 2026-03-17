import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/string
import gleam/list
import gleam/int
import gleam/json
import gleam/dynamic/decode
import gleam/erlang/process

pub type Track {
  Track(
  title: String,
  artist: String,
  album: String,
  url: String,
  )
}

pub fn parse_feed() -> List(Track) {
  let assert Ok(rss_url) = request.to("https://archive.org/services/collection-rss.php?collection=fav-kat_ia717")

  let req = request.prepend_header(rss_url, "accept", "application/xml")

  case load_tracks(req) {
    Ok(tracks) -> {
      io.println("[debug] Tracks fetched: " <> int.to_string(list.length(tracks)))
      // tracks |> list.each(fn(t) { io.println(t.title <> " - " <> t.artist <> " (" <> t.album <> ")") })
      tracks
    }
   Error(e) -> {
      io.println(e)
      []
    }
  }
}

pub fn load_tracks(req: request.Request(String)) -> Result(List(Track), String) {
  case httpc.send(req) {
    Ok(resp) ->
      case resp.status {
        200 ->
          Ok(
            resp.body
            |> parse_rss_identifiers
            |> list.sized_chunk(5)
            |> list.flat_map(fetch_track_metadata)
          )
        status ->
          Error("status: " <> int.to_string(status))
      }
    Error(_) ->
      Error("Request failed")
  }
}

fn parse_rss_identifiers(xml: String) -> List(String) {
  xml
  |> string.split("<link>")
  |> list.drop(3)
  |> list.filter_map(fn(chunk) { // filter_map to transform values + remove failures
    case string.split_once(chunk, "</link>") { // returns Ok(#(before, after)) or Error(_)
      Ok(#(link, _)) ->
        link
        |> string.replace("https://archive.org/details/", "")
        |> string.trim()
        |> Ok
      Error(_) ->
        Error(Nil)
    }
  })
}

// fn fetch_track_metadata(identifier: String) -> List(Track) {
//   let assert Ok(url) = request.to("https://archive.org/metadata/" <> identifier)
//   let req = request.prepend_header(url, "accept", "application/json")
//   case httpc.send(req) {
//     Ok(resp) ->
//       case json.parse(resp.body, using: metadata_decoder(identifier)) {
//         Ok(tracks) -> tracks
//         Error(_) -> []
//       }
//     Error(_) -> []
//   }
// }

fn fetch_track_metadata(identifiers: List(String)) -> List(Track) {
  let subject = process.new_subject()
  let count = list.length(identifiers)

  list.each(identifiers, fn(identifier) {
    process.spawn_unlinked(fn() {
      let assert Ok(url) = request.to("https://archive.org/metadata/" <> identifier)
      let req = request.prepend_header(url, "accept", "application/json")
      let tracks =
        case httpc.send(req) {
          Ok(resp) ->
            case json.parse(resp.body, using: metadata_decoder(identifier)) {
              Ok(tracks) -> tracks
              Error(_) -> []
            }
          Error(_) -> []
        }
      process.send(subject, tracks)
    })
  })
  list.repeat(Nil, count)
  |> list.flat_map(fn(_) {
    case process.receive(subject, 10_0000) {
      Ok(tracks) -> tracks
      Error(_) -> []
    }
  })
}

fn metadata_decoder(identifier: String) -> decode.Decoder(List(Track)) {
  use files <- decode.field("files", decode.list(file_decoder(identifier)))
  decode.success(list.flatten(files))
}

fn file_decoder(identifier: String) -> decode.Decoder(List(Track)) {
  use format <- decode.optional_field("format", "", decode.string)
  use name <- decode.optional_field("name", "", decode.string)
  use title <- decode.optional_field("title", "", decode.string)
  use album <- decode.optional_field("album", "", decode.string)
  use artist_field <- decode.optional_field("artist", "", decode.string)
  use creator_field <- decode.optional_field("creator", "", decode.string)
  let artist = case artist_field {
      "" -> creator_field
      a -> a
    }
  case format {
    "VBR MP3" -> {
      let url = "https://archive.org/download/" <> identifier <> "/" <> name
      decode.success([Track(title: title, artist: artist, album: album, url: url,),])
    }
    _ ->
      decode.success([])
  }
}