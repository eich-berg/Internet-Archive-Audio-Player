import app/router 
import app/web.{Context}
import gleam/erlang/process
import mist
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()
  
  let secret_key_base = wisp.random_string(64)

  let ctx = Context(static_directory: static_directory(), items: []) 

  // Wrap router with middleware 
  let handler = router.handle_request(_, ctx)

  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.bind("0.0.0.0")
    |> mist.start()

  process.sleep_forever()
}

pub fn static_directory() -> String {
  case wisp.priv_directory(".") {
    Ok(priv_directory) -> priv_directory <> "/static"
    Error(_) -> "./static"
  }
}