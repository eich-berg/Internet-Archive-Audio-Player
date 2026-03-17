import app/pages
import app/pages/layout.{layout}
import app/web.{type Context}
import rss_reader
import lustre/element
import gleam/http.{Get}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use _req <- web.middleware(req, ctx) 

  case wisp.path_segments(req) {
    // Homepage
    [] -> {
      home_page(req, ctx)
    }
    // Everything else -> 404
    _ -> {
      wisp.not_found()
    }
  }
}

fn home_page(req: Request, _ctx: Context) -> Response {
  use <- wisp.require_method(req, Get)

  let tracks = rss_reader.parse_feed()

  [pages.home(tracks)]
  |> layout
  |> element.to_document_string
  |> wisp.html_response(200)
}